//
//  AIChatView.swift
//  MeetMemento
//
//  AI Chat interface for conversing with journal insights AI
//

import SwiftUI

public struct AIChatView: View {
    /// When true, hides the back button and adjusts layout for inline display in TopTabNavContainer
    var isEmbedded: Bool = false

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entryViewModel: EntryViewModel

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var userContext: UserContext?
    @State private var chatError: String?
    @State private var showChatError = false

    // Memory optimization: cap message history to prevent unbounded growth
    private let maxMessagesInMemory = 100
    @State private var reviewedJournalCount: Int = 5 // Mock data
    @State private var selectedCitations: [JournalCitation]? = nil
    @State private var showCitationsSheet = false
    @State private var showChatHistorySheet = false
    @State private var chatSessions: [ChatSession] = ChatSession.mockSessions // Mock data for now
    @State private var scrollTask: Task<Void, Never>?
    @State private var scrollProxy: ScrollViewProxy?
    @StateObject private var keyboardObserver = KeyboardObserver()

    private static let defaultSuggestions: [String] = [
        "Analyze my current mindset from my journal activity in the past week",
        "Explore the themes we've talked about from my journals about my friendships.",
        "Summarize my journal entries in the last month"
    ]

    public init(isEmbedded: Bool = false) {
        self.isEmbedded = isEmbedded
    }
    
    /// Height reserved for floating header when embedded
    private var topContentInset: CGFloat {
        isEmbedded ? 100 : 16
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Messages list - fills available space with bottom inset for input
                messagesScrollView
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        // Reserve space for input field (input height + padding + keyboard offset)
                        Color.clear.frame(height: 88 + keyboardBottomPadding(geometry: geometry))
                    }

                // Input area - floats at bottom with no background
                VStack {
                    Spacer()
                    floatingInputArea
                        .padding(.bottom, keyboardBottomPadding(geometry: geometry))
                }
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent double-adjustment
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Only show back button when NOT embedded (modal presentation)
            if !isEmbedded {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(type.body1Bold)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
                    .accessibilityLabel("Back")
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadInitialState()
        }
        .alert("Chat Error", isPresented: $showChatError) {
            Button("OK") { showChatError = false }
        } message: {
            Text(chatError ?? "Something went wrong. Please try again.")
        }
        .onDisappear {
            scrollTask?.cancel()
            scrollTask = nil
        }
        .sheet(isPresented: $showCitationsSheet) {
            if let citations = selectedCitations {
                CitationsBottomSheet(citations: citations)
            }
        }
        .sheet(isPresented: $showChatHistorySheet) {
            ChatHistorySheet(
                sessions: chatSessions,
                onSessionSelect: { session in
                    loadSession(session)
                },
                onNewChat: {
                    startNewChat()
                }
            )
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty && !isSending {
                        VStack(alignment: .leading, spacing: 24) {
                            // Extra top padding when embedded to account for floating header
                            Spacer().frame(height: topContentInset + 20)

                            // Memento icon — left 32/132 of logo SVG rendered at 44pt height
                            Image("Memento-Logo")
                                .resizable()
                                .frame(width: 176, height: 44)
                                .frame(width: 44, alignment: .leading)
                                .clipped()
                                .padding(.leading, 20)

                            // Welcome message
                            Text("Welcome John, let's dive deeper into your journal")
                                .font(type.h3)
                                .foregroundStyle(theme.foreground)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 20)

                            // Suggestion cards — horizontal scroll
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Self.defaultSuggestions, id: \.self) { suggestion in
                                        AISuggestionCard(suggestion: suggestion) {
                                            sendMessage(prompt: suggestion)
                                        }
                                    }
                                }
                                .padding(.leading, 20)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .id("empty")
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(messages) { message in
                                ChatMessageBubble(
                                    message: message,
                                    onCitationsTapped: {
                                        if let citations = message.citations, !citations.isEmpty {
                                            selectedCitations = citations
                                            showCitationsSheet = true
                                        }
                                    },
                                    onRedo: message.isFromUser ? nil : { regenerateResponse(for: message.id) }
                                )
                                .id(message.id)
                            }

                            // Loading State Indicator
                            if isSending {
                                AILoadingState()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .transition(.opacity)
                                    .id("loading-state")
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(.bottom, 16)
                .padding(.top, topContentInset)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: messages.count) { oldCount, newCount in
                scrollToBottom(proxy: proxy, count: newCount)
            }
            .onChange(of: isSending) { _, newValue in
                if newValue {
                     // Scroll to bottom when loading starts using Task
                     scrollTask?.cancel()
                     scrollTask = Task { @MainActor in
                         try? await Task.sleep(nanoseconds: 100_000_000)
                         guard !Task.isCancelled else { return }
                         withAnimation {
                             proxy.scrollTo("loading-state", anchor: .bottom)
                         }
                     }
                }
            }
            .onChange(of: keyboardObserver.isKeyboardVisible) { _, isVisible in
                if isVisible {
                    scrollToLatestMessage()
                }
            }
            .onTapGesture {
                dismissKeyboard()
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, count: Int) {
         if let lastMessage = messages.last {
             withAnimation(.easeOut(duration: 0.3)) {
                 proxy.scrollTo(lastMessage.id, anchor: .bottom)
             }
         }
    }

    // ... (skipping JournalReviewIndicator as it is unchanged)

    // MARK: - Floating Input Area

    private var floatingInputArea: some View {
        ChatInputField(
            text: $inputText,
            isSending: isSending,
            hasChatHistory: !messages.isEmpty,
            onSend: { sendMessage() },
            onJournalTap: { showChatHistorySheet = true }
        )
    }

    // MARK: - Keyboard Padding Calculation

    private func keyboardBottomPadding(geometry: GeometryProxy) -> CGFloat {
        if keyboardObserver.isKeyboardVisible {
            // Keyboard is visible - position input above keyboard
            let safeArea = geometry.safeAreaInsets.bottom
            return max(keyboardObserver.keyboardHeight - safeArea, 0)
        } else {
            // Keyboard hidden - fixed 32px from bottom of screen
            return 32
        }
    }

    // MARK: - Scroll Helpers

    private func scrollToLatestMessage() {
        guard let proxy = scrollProxy else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                } else if isSending {
                    proxy.scrollTo("loading-state", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Actions

    private func regenerateResponse(for messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }), index > 0 else { return }
        let precedingUserMessage = messages[index - 1]
        guard precedingUserMessage.isFromUser else { return }
        let userContent = precedingUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userContent.isEmpty else { return }
        messages.removeSubrange((index - 1)...index)
        sendMessage(prompt: userContent)
    }
    
    private func loadInitialState() {
        messages = []
        reviewedJournalCount = max(1, entryViewModel.entries.count)
        Task {
            do {
                userContext = try await UserContextService.shared.fetchUserContext()
            } catch {
                #if DEBUG
                print("AIChatView: Failed to fetch UserContext: \(error)")
                #endif
            }
        }
    }
    
    private func sendMessage(prompt: String? = nil) {
        let text: String
        if let prompt = prompt {
            text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !text.isEmpty, !isSending else { return }

        let userMessage = ChatMessage(content: text, isFromUser: true)
        addMessage(userMessage)

        if prompt == nil {
            inputText = ""
        }

        withAnimation { isSending = true }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            #if DISABLE_SUPABASE
            // UI/testing mode: use mock response
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                let aiResponse = ChatMessage.aiMessage(
                    heading1: "Patterns in Your Resilience",
                    heading2: "Key Observations",
                    body: "I've analyzed your recent journal entries and found some interesting connections. **Mindfulness seems to be a key driver** for your productivity.\n\nWhen you mention *taking morning pauses*, your subsequent entries tend to be more positive and focused.",
                    citations: nil
                )
                withAnimation { isSending = false }
                addMessage(aiResponse)
            }
            #else
            do {
                let entries = entryViewModel.entries.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let content = try await InsightsService.shared.chat(
                    messages: messages,
                    entries: entries.isEmpty ? Entry.sampleEntries : entries,
                    userContext: userContext
                )
                let aiResponse = ChatMessage.aiMessage(
                    heading1: content.heading1,
                    heading2: content.heading2,
                    body: content.body,
                    citations: nil
                )
                await MainActor.run {
                    withAnimation { isSending = false }
                    addMessage(aiResponse)
                }
            } catch {
                await MainActor.run {
                    withAnimation { isSending = false }
                    chatError = error.localizedDescription
                    showChatError = true
                }
            }
            #endif
        }
    }

    /// Adds a message while enforcing memory limit to prevent unbounded growth
    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        // Keep only recent messages in memory to prevent OOM
        if messages.count > maxMessagesInMemory {
            messages.removeFirst(messages.count - maxMessagesInMemory)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Chat History Actions

    private func loadSession(_ session: ChatSession) {
        // TODO: Load actual session messages from backend
        // For now, show a mock loaded state using the session title (first message)
        messages = [
            ChatMessage(
                content: session.title,
                isFromUser: true
            ),
            ChatMessage.aiMessage(
                heading1: "Restored Session",
                heading2: nil,
                body: "This is a restored conversation from your chat history. The original AI response would appear here.",
                citations: nil
            )
        ]
    }

    private func startNewChat() {
        withAnimation {
            messages = []
            inputText = ""
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NavigationStack {
        AIChatView()
            .environmentObject(EntryViewModel())
    }
    .useTheme()
    .useTypography()
}

#Preview("With Messages") {
    NavigationStack {
        AIChatView()
            .environmentObject(EntryViewModel())
    }
    .useTheme()
    .useTypography()
}

#Preview("Chat History Sheet") {
    ChatHistorySheet(
        sessions: ChatSession.mockSessions,
        onSessionSelect: { session in
            print("Selected: \(session.title)")
        },
        onNewChat: {
            print("New chat started")
        }
    )
    .useTheme()
    .useTypography()
}

#Preview("Dark Mode") {
    NavigationStack {
        AIChatView()
            .environmentObject(EntryViewModel())
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

// MARK: - Glass-like Effect Extension
// Fallback for iOS versions that don't support glassEffect

extension View {
    @ViewBuilder
    func glassLikeEffect(in shape: some Shape = Capsule()) -> some View {
        self.background(.regularMaterial, in: shape)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    func glassLikeEffect(cornerRadius: CGFloat) -> some View {
        self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
