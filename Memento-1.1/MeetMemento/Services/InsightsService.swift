import Foundation
import Supabase

class InsightsService {
    static let shared = InsightsService()
    
    private var client: SupabaseClient {
        SupabaseService.shared.client
    }
    
    /// Fetches the latest valid insight for the current user.
    func fetchLatestInsight() async throws -> UserInsight? {
        guard let userId = client.auth.currentUser?.id else { return nil }
        
        let response: [UserInsight] = try await client
            .from("user_insights")
            .select() // Select all fields
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
            
        return response.first
    }
    
    /// Generates a new insight by calling the Supabase Edge Function 'generate-insight'.
    /// This keeps the Gemini API key secure on the server.
    func generateInsight(entries: [Entry]) async throws -> UserInsight {
        guard let userId = client.auth.currentUser?.id else {
            throw AuthError.missingEmail
        }
        
        print("🔍 [InsightsService] Starting insight generation for \(entries.count) entries")
        
        // 1. Prepare Payload
        // The View now handles filtering (Time Frame), so we process exactly what is passed.
        // We trust the View to send a reasonable number of entries based on the selected filter.
        let payloadEntries = entries.map { entry in
            return [
                "id": entry.id.uuidString,
                "title": entry.title,
                "content": entry.text,
                "date": ISO8601DateFormatter().string(from: entry.createdAt)
            ]
        }
        
        print("🔍 [InsightsService] Payload prepared: \(payloadEntries.count) entries")
        
        do {
            // 2. Invoke Edge Function
            print("🔍 [InsightsService] Calling Edge Function...")
            
            // The invoke method with a generic type parameter returns the decoded response
            let content: InsightContent = try await client.functions.invoke(
                "generate-insight",
                options: FunctionInvokeOptions(
                    body: ["entries": payloadEntries]
                )
            )
            
            print("✅ [InsightsService] Successfully decoded InsightContent")
            print("   - Headline: \(content.headline)")
            print("   - Themes: \(content.themes ?? [])")
            print("   - Suggestions: \(content.suggestions ?? [])")
            
            // 3. Wrap in UserInsight model for the UI
            let newInsight = UserInsight(
                userId: userId,
                insightType: "ai_generated",
                content: try InsightContent.encodeToJSONMap(content),
                entriesAnalyzedCount: entries.count
            )
            
            print("✅ [InsightsService] UserInsight created successfully")
            return newInsight
            
        } catch let decodingError as DecodingError {
            print("❌ [InsightsService] Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   - Missing key: \(key.stringValue)")
                print("   - Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   - Type mismatch: expected \(type)")
                print("   - Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   - Value not found: \(type)")
                print("   - Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   - Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   - Unknown decoding error")
            }
            throw decodingError
        } catch {
            print("❌ [InsightsService] Error: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            throw error
        }
    }


    /// Sends a chat message history + context entries to the AI and returns the response.
    func chat(messages: [ChatMessage], entries: [Entry]) async throws -> AIOutputContent {
        print("💬 [InsightsService] Sending chat with \(entries.count) entries context")
        
        let payloadEntries = entries.map { entry in
            return [
                "id": entry.id.uuidString,
                "title": entry.title,
                "content": entry.text,
                "date": ISO8601DateFormatter().string(from: entry.createdAt)
            ]
        }
        
        let payloadMessages = messages.map { msg in
            return [
                "content": msg.content,
                "isFromUser": String(msg.isFromUser)
            ]
        }
        
        let content: AIOutputContent = try await client.functions.invoke(
            "chat-with-entries",
            options: FunctionInvokeOptions(
                body: [
                    "messages": payloadMessages,
                    "entries": payloadEntries
                ]
            )
        )
        return content
    }
}

// Helper extension to encode typed content to JSON dictionary for the generic model
extension InsightContent {
    static func encodeToJSONMap(_ content: InsightContent) throws -> [String: AnyCodable] {
        var map: [String: AnyCodable] = [:]
        map["headline"] = AnyCodable(content.headline)
        map["observation"] = AnyCodable(content.observation)
        
        if let themes = content.themes {
            map["themes"] = AnyCodable(themes.map { AnyCodable($0) })
        }
        
        if let suggestions = content.suggestions {
            map["suggestions"] = AnyCodable(suggestions.map { AnyCodable($0) })
        }
        
        if let keywords = content.keywords {
            map["keywords"] = AnyCodable(keywords.map { AnyCodable($0) })
        }
        
        if let questions = content.questions {
            map["questions"] = AnyCodable(questions.map { AnyCodable($0) })
        }
        
        return map
    }
}
