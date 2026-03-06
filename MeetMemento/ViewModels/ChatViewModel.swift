import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false

    private let chatService = ChatService.shared
    private let maxMessagesInMemory = 100

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
                let response = try await chatService.sendMessage(text)

                let citations = mapSourcesToCitations(response.sources)
                let aiMessage = ChatMessage.aiMessage(
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
        Task {
            try? await chatService.clearHistory()
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
