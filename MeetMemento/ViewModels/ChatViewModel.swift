import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false

    // Session management
    @Published var currentSessionId: UUID?
    @Published var sessions: [ChatSession] = []
    @Published var isLoadingSessions: Bool = false

    private let chatService = ChatService.shared
    private let maxMessagesInMemory = 100

    // MARK: - JSON Content Extraction

    /// Extracts clean body text from potentially JSON-formatted content
    /// Handles: raw JSON strings, legacy plain text, nested JSON
    private func extractBodyContent(from content: String, role: String) -> (body: String, aiContent: AIOutputContent?) {
        guard role == "assistant" else {
            return (content, nil)
        }

        // Try parsing as AIOutputContent JSON
        if let data = content.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AIOutputContent.self, from: data) {
            return (parsed.body, parsed)
        }

        // Try parsing as generic JSON with body field
        if let data = content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let body = json["body"] as? String {
            let heading1 = json["heading1"] as? String
            let heading2 = json["heading2"] as? String
            let aiContent = AIOutputContent(heading1: heading1, heading2: heading2, body: body)
            return (body, aiContent)
        }

        // Check if content looks like JSON but parsing failed - try to extract body
        if content.hasPrefix("{") && content.contains("\"body\"") {
            // Regex fallback to extract body value
            if let range = content.range(of: #""body"\s*:\s*"([^"\\]*(\\.[^"\\]*)*)""#, options: .regularExpression),
               let bodyRange = content.range(of: #":\s*"([^"\\]*(\\.[^"\\]*)*)""#, options: .regularExpression, range: range) {
                let extracted = String(content[bodyRange])
                    .replacingOccurrences(of: #"^\s*:\s*""#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #""$"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\n", with: "\n")
                if !extracted.isEmpty {
                    let aiContent = AIOutputContent(heading1: nil, heading2: nil, body: extracted)
                    return (extracted, aiContent)
                }
            }
        }

        // Not JSON - return as-is (legacy plain text)
        let aiContent = AIOutputContent(heading1: nil, heading2: nil, body: content)
        return (content, aiContent)
    }

    // MARK: - Send Message

    func sendMessage(prompt: String? = nil) {
        let text: String
        if let prompt = prompt {
            text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !text.isEmpty, !isLoading else { return }

        if prompt == nil {
            inputText = ""
        }

        let userMessage = ChatMessage(content: text, isFromUser: true)
        appendMessage(userMessage)

        isLoading = true

        Task {
            do {
                let response = try await chatService.sendMessage(text, sessionId: currentSessionId)

                // Update current session ID from response (handles new session creation)
                if let newSessionId = UUID(uuidString: response.sessionId) {
                    if currentSessionId == nil {
                        currentSessionId = newSessionId
                        // Refresh sessions list when a new session is created
                        await fetchSessions()
                    }
                }

                let citations = mapSourcesToCitations(response.sources)
                let aiMessage = ChatMessage.aiMessage(
                    heading1: response.heading1,
                    heading2: response.heading2,
                    body: response.reply,
                    citations: citations.isEmpty ? nil : citations
                )
                appendMessage(aiMessage)
            } catch {
                #if DEBUG
                print("❌ [ChatViewModel] sendMessage error: \(error)")
                #endif
                errorMessage = chatErrorMessage(for: error)
                showingError = true
            }
            isLoading = false
        }
    }

    // MARK: - Clear Conversation

    func clearConversation() {
        messages = []
        currentSessionId = nil
    }

    // MARK: - Session Management

    /// Fetches all chat sessions from the backend
    func fetchSessions() async {
        isLoadingSessions = true
        do {
            sessions = try await chatService.fetchSessions()
        } catch {
            #if DEBUG
            print("❌ [ChatViewModel] fetchSessions error: \(error)")
            #endif
        }
        isLoadingSessions = false
    }

    /// Loads a specific session's messages
    func loadSession(_ session: ChatSession) async {
        currentSessionId = session.id
        messages = []
        isLoading = true

        do {
            let messageDTOs = try await chatService.loadSessionMessages(sessionId: session.id)
            let loadedMessages = messageDTOs.map { dto -> ChatMessage in
                let (body, aiContent) = extractBodyContent(from: dto.content, role: dto.role)

                if dto.role == "assistant", let aiContent = aiContent {
                    return ChatMessage.aiMessage(
                        heading1: aiContent.heading1,
                        heading2: aiContent.heading2,
                        body: body,
                        citations: nil // Citations are not persisted
                    )
                }

                // User messages
                return ChatMessage(content: dto.content, isFromUser: dto.role == "user")
            }
            messages = loadedMessages
        } catch {
            #if DEBUG
            print("❌ [ChatViewModel] loadSession error: \(error)")
            #endif
            errorMessage = "Failed to load conversation history."
            showingError = true
        }
        isLoading = false
    }

    /// Starts a new chat by clearing state
    func startNewChat() {
        messages = []
        currentSessionId = nil
        inputText = ""
    }

    /// Deletes a session and refreshes the sessions list
    func deleteSession(_ session: ChatSession) async {
        do {
            try await chatService.deleteSession(sessionId: session.id)
            // Remove from local list immediately for responsiveness
            sessions.removeAll { $0.id == session.id }
            // If the deleted session was the current one, clear the chat
            if currentSessionId == session.id {
                startNewChat()
            }
        } catch {
            #if DEBUG
            print("❌ [ChatViewModel] deleteSession error: \(error)")
            #endif
            errorMessage = "Failed to delete conversation."
            showingError = true
        }
    }

    // MARK: - Regenerate

    func regenerateResponse(for messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }), index > 0 else { return }
        let precedingUserMessage = messages[index - 1]
        guard precedingUserMessage.isFromUser else { return }
        let userContent = precedingUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userContent.isEmpty else { return }
        messages.removeSubrange((index - 1)...index)
        sendMessage(prompt: userContent)
    }

    // MARK: - Private Helpers

    private func appendMessage(_ message: ChatMessage) {
        messages.append(message)
        if messages.count > maxMessagesInMemory {
            messages.removeFirst(messages.count - maxMessagesInMemory)
        }
    }

    private func chatErrorMessage(for error: Error) -> String {
        let code = extractHTTPStatusCode(from: error)
        switch code {
        case 404:
            return "Chat service is not set up yet. Please ensure Edge Functions are deployed."
        case 401:
            return "Please sign in again."
        default:
            return "Unable to get a response. Please check your connection and try again."
        }
    }

    private func extractHTTPStatusCode(from error: Error) -> Int? {
        let mirror = Mirror(reflecting: error)
        for child in mirror.children where child.label == "httpError" {
            let tupleMirror = Mirror(reflecting: child.value)
            for tupleChild in tupleMirror.children {
                if let code = tupleChild.value as? Int {
                    return code
                }
            }
            return nil
        }
        return nil
    }

    private func mapSourcesToCitations(_ sources: [ChatSource]) -> [JournalCitation] {
        sources.compactMap { source in
            guard let entryId = UUID(uuidString: source.id) else { return nil }

            let date: Date
            if let parsed = ISO8601DateFormatter().date(from: source.createdAt) {
                date = parsed
            } else {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                date = formatter.date(from: source.createdAt) ?? Date()
            }

            return JournalCitation(
                entryId: entryId,
                entryTitle: "",
                entryDate: date,
                excerpt: source.preview
            )
        }
    }
}
