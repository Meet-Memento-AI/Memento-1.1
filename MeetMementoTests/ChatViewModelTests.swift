import XCTest
@testable import MeetMemento

@MainActor
final class ChatViewModelTests: XCTestCase {
    private func waitForLoadingFalse(_ vm: ChatViewModel, timeout: TimeInterval = 3.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !vm.isLoading { return }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    func test_ChatViewModel_sendMessage_appendsUserAndAssistant() async throws {
        let sessionId = UUID()
        let mock = MockChatService()
        mock.sendMessageImpl = { _, _ in
            ChatResponse(
                reply: "Assistant reply",
                heading1: nil,
                heading2: nil,
                citedEntryIds: nil,
                sources: [],
                sessionId: sessionId.uuidString
            )
        }
        mock.fetchSessionsImpl = { [] }

        let vm = ChatViewModel(chatService: mock)
        vm.sendMessage(prompt: "hello")

        await waitForLoadingFalse(vm)
        XCTAssertFalse(vm.showingError)
        XCTAssertEqual(vm.currentSessionId, sessionId)
        XCTAssertEqual(vm.messages.count, 2)
        XCTAssertTrue(vm.messages[0].isFromUser)
        XCTAssertFalse(vm.messages[1].isFromUser)
    }

    func test_ChatViewModel_sendMessage_mapsErrorToUserMessage() async throws {
        final class FNError: Error {
            let httpError = (404, "Not Found")
        }

        let mock = MockChatService()
        mock.sendMessageImpl = { _, _ in throw FNError() }

        let vm = ChatViewModel(chatService: mock)
        vm.sendMessage(prompt: "x")

        await waitForLoadingFalse(vm)
        XCTAssertTrue(vm.showingError)
        XCTAssertEqual(vm.errorMessage, "Chat service is not set up yet. Please ensure Edge Functions are deployed.")
    }

    func test_ChatViewModel_sendMessage_genericError() async throws {
        let mock = MockChatService()
        mock.sendMessageImpl = { _, _ in
            throw NSError(domain: "t", code: 0, userInfo: [NSLocalizedDescriptionKey: "x"])
        }

        let vm = ChatViewModel(chatService: mock)
        vm.sendMessage(prompt: "x")

        await waitForLoadingFalse(vm)
        XCTAssertTrue(vm.showingError)
        XCTAssertEqual(vm.errorMessage, "Unable to get a response. Please check your connection and try again.")
    }

    func test_ChatViewModel_generateChatSummary_returnsMockSummary() async throws {
        let mock = MockChatService()
        mock.summarizeChatImpl = { _, _ in
            ChatSummaryResponse(title: "T", content: "C")
        }
        let vm = ChatViewModel(chatService: mock)
        vm.messages = [ChatMessage(content: "u", isFromUser: true)]
        vm.currentSessionId = UUID()

        let result = try await vm.generateChatSummary()
        XCTAssertEqual(result.title, "T")
        XCTAssertEqual(result.content, "C")
    }
}
