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

    @StateObject private var viewModel = ChatViewModel()

    @State private var selectedCitations: [JournalCitation]? = nil
    @State private var showCitationsSheet = false
    @State private var showChatHistorySheet = false
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
                sessions: viewModel.sessions,
                isLoading: viewModel.isLoadingSessions,
                onSessionSelect: { session in
                    loadSession(session)
                },
                onNewChat: {
                    startNewChat()
                },
                onDeleteSession: { session in
                    Task {
                        await viewModel.deleteSession(session)
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.fetchSessions()
            }
        }
        .alert("Something went wrong", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 32) {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
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
                                            viewModel.sendMessage(prompt: suggestion)
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
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(viewModel.messages) { message in
                                ChatMessageBubble(
                                    message: message,
                                    onCitationsTapped: {
                                        if let citations = message.citations, !citations.isEmpty {
                                            selectedCitations = citations
                                            showCitationsSheet = true
                                        }
                                    },
                                    onRedo: message.isFromUser ? nil : { viewModel.regenerateResponse(for: message.id) }
                                )
                                .id(message.id)
                            }

                            // Loading State Indicator
                            if viewModel.isLoading {
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
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                scrollToBottom(proxy: proxy, count: newCount)
            }
            .onChange(of: viewModel.isLoading) { _, newValue in
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
         if let lastMessage = viewModel.messages.last {
             withAnimation(.easeOut(duration: 0.3)) {
                 proxy.scrollTo(lastMessage.id, anchor: .bottom)
             }
         }
    }

    // ... (skipping JournalReviewIndicator as it is unchanged)

    // MARK: - Floating Input Area

    private var floatingInputArea: some View {
        ChatInputField(
            text: $viewModel.inputText,
            isSending: viewModel.isLoading,
            hasChatHistory: !viewModel.messages.isEmpty,
            onSend: { viewModel.sendMessage() },
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
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                } else if viewModel.isLoading {
                    proxy.scrollTo("loading-state", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Actions

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Chat History Actions

    private func loadSession(_ session: ChatSession) {
        Task {
            await viewModel.loadSession(session)
        }
    }

    private func startNewChat() {
        withAnimation {
            viewModel.startNewChat()
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NavigationStack {
        AIChatView()
    }
    .useTheme()
    .useTypography()
}

#Preview("With Messages") {
    NavigationStack {
        AIChatView()
            .onAppear {
                // Mock messages for preview
            }
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
