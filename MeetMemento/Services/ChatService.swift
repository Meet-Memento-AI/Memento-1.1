import Foundation
import Supabase

// MARK: - Response Types

struct ChatResponse: Codable {
    let reply: String
    let heading1: String?
    let heading2: String?
    let sources: [ChatSource]
    let sessionId: String
}

struct ChatSource: Codable, Equatable {
    let id: String
    let createdAt: String
    let preview: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case preview
    }
}

// MARK: - Request Types

private struct ChatRequestBody: Codable {
    let message: String
    let sessionId: String?
}

// MARK: - Service

class ChatService {
    static let shared = ChatService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    func sendMessage(_ text: String, sessionId: UUID? = nil) async throws -> ChatResponse {
        let requestBody = ChatRequestBody(message: text, sessionId: sessionId?.uuidString)

        #if DEBUG
        print("💬 [ChatService] Sending message to chat Edge Function (session: \(sessionId?.uuidString.prefix(8) ?? "new"))...")
        #endif

        let response: ChatResponse = try await client.functions.invoke(
            "chat",
            options: FunctionInvokeOptions(body: requestBody)
        )

        #if DEBUG
        print("✅ [ChatService] Received reply (\(response.reply.count) chars), \(response.sources.count) sources, session: \(response.sessionId.prefix(8))...")
        #endif

        return response
    }

    // MARK: - Embedding Trigger

    /// Triggers embedding generation for a specific journal entry
    /// Called after saving entries to ensure embeddings are generated
    func triggerEmbedding(entryId: UUID) async throws {
        #if DEBUG
        print("🔄 [ChatService] Triggering embedding for entry \(entryId.uuidString.prefix(8))...")
        #endif

        struct EmbedRequest: Codable {
            let entryId: String
        }

        let request = EmbedRequest(entryId: entryId.uuidString)

        try await client.functions.invoke(
            "sync-embedding",
            options: FunctionInvokeOptions(body: request)
        )

        #if DEBUG
        print("✅ [ChatService] Embedding triggered for entry \(entryId.uuidString.prefix(8))")
        #endif
    }

    // MARK: - History Management

    func clearHistory() async throws {
        guard let userId = client.auth.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ChatService] Cannot clear history — no authenticated user")
            #endif
            return
        }

        try await client
            .from("chat_messages")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        #if DEBUG
        print("🗑️ [ChatService] Chat history cleared for user \(userId.uuidString.prefix(8))...")
        #endif
    }

    // MARK: - Session Management

    /// Fetches all chat sessions for the current user, sorted by most recent first
    func fetchSessions() async throws -> [ChatSession] {
        guard let userId = client.auth.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ChatService] Cannot fetch sessions — no authenticated user")
            #endif
            return []
        }

        #if DEBUG
        print("📋 [ChatService] Fetching chat sessions...")
        #endif

        let response: [ChatSession] = try await client
            .from("chat_sessions")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value

        #if DEBUG
        print("✅ [ChatService] Fetched \(response.count) sessions")
        #endif

        return response
    }

    /// Loads all messages for a specific session
    func loadSessionMessages(sessionId: UUID) async throws -> [ChatMessageDTO] {
        guard let userId = client.auth.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ChatService] Cannot load session messages — no authenticated user")
            #endif
            return []
        }

        #if DEBUG
        print("📖 [ChatService] Loading messages for session \(sessionId.uuidString.prefix(8))...")
        #endif

        let response: [ChatMessageDTO] = try await client
            .from("chat_messages")
            .select("id, role, content, created_at")
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .order("created_at", ascending: true)
            .execute()
            .value

        #if DEBUG
        print("✅ [ChatService] Loaded \(response.count) messages")
        #endif

        return response
    }

    /// Deletes a chat session and all its messages (cascade delete via FK)
    func deleteSession(sessionId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            #if DEBUG
            print("⚠️ [ChatService] Cannot delete session — no authenticated user")
            #endif
            return
        }

        #if DEBUG
        print("🗑️ [ChatService] Deleting session \(sessionId.uuidString.prefix(8))...")
        #endif

        try await client
            .from("chat_sessions")
            .delete()
            .eq("id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()

        #if DEBUG
        print("✅ [ChatService] Session deleted")
        #endif
    }
}
