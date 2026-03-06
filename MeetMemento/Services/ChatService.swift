import Foundation
import Supabase

// MARK: - Response Types

struct ChatResponse: Codable {
    let reply: String
    let sources: [ChatSource]
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
}

// MARK: - Service

class ChatService {
    static let shared = ChatService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    func sendMessage(_ text: String) async throws -> ChatResponse {
        let requestBody = ChatRequestBody(message: text)

        #if DEBUG
        print("💬 [ChatService] Sending message to chat Edge Function...")
        #endif

        let response: ChatResponse = try await client.functions.invoke(
            "chat",
            options: FunctionInvokeOptions(body: requestBody)
        )

        #if DEBUG
        print("✅ [ChatService] Received reply (\(response.reply.count) chars), \(response.sources.count) sources")
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
}
