//
//  AIChatView.swift
//  MeetMemento
//
//  AI Chat interface for conversing with journal insights AI
//

import SwiftUI

public struct AIChatView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var reviewedJournalCount: Int = 5 // Mock data
    @State private var selectedCitations: [JournalCitation]? = nil
    @State private var showCitationsSheet = false
    @State private var inputAreaHeight: CGFloat = 104

    private static let defaultSuggestions: [String] = [
        "Analyze my current mindset from my journal activity in the past week",
        "Explore the themes we've talked about from my journals about my friendships.",
        "Summarize my journal entries in the last month"
    ]

    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Messages list - extends full screen
            messagesScrollView
                .padding(.bottom, inputAreaHeight) // Exact padding to prevent overlap
            
            // Floating input area with glass-like effect
            floatingInputArea
        }
        .background(.white)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Top navigation with glass-like effect
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar) // Hide default toolbar background
        .onAppear {
            loadInitialState()
        }
        .sheet(isPresented: $showCitationsSheet) {
            if let citations = selectedCitations {
                CitationsBottomSheet(citations: citations)
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty && !isSending {
                        VStack(alignment: .leading, spacing: 24) {
                            Spacer().frame(height: 80)

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
                                .foregroundStyle(GrayScale.gray900)
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
                .padding(.bottom, 16) // Standard bottom padding
                .padding(.top, 16) // Standard top padding with native navigation
            }
            .onChange(of: messages.count) { oldCount, newCount in
                scrollToBottom(proxy: proxy, count: newCount)
            }
            .onChange(of: isSending) { _, newValue in
                if newValue {
                     // Scroll to bottom when loading starts
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         withAnimation {
                             proxy.scrollTo("loading-state", anchor: .bottom)
                         }
                     }
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
        VStack(spacing: 0) {
            ChatInputField(text: $inputText, isSending: isSending, onSend: { sendMessage() })
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
        // Mock initial messages for UI preview (remove when backend is ready)
        // For now, start with empty state
        messages = []
        reviewedJournalCount = 5 // Mock data
    }
    
    private func sendMessage(prompt: String? = nil) {
        let text: String
        if let prompt = prompt {
            text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !text.isEmpty, !isSending else { return }

        // Add user message
        let userMessage = ChatMessage(
            content: text,
            isFromUser: true
        )
        messages.append(userMessage)

        if prompt == nil {
            inputText = ""
        }

        // Simulate AI response (remove when backend is ready)
        withAnimation {
            isSending = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Simulate delay for AI response
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0 seconds
            
            await MainActor.run {
                // Mock AI response with structured content (replace with actual API call)
                let mockCitations: [JournalCitation]? = [
                    JournalCitation(
                        entryId: UUID(),
                        entryTitle: "Reflection on Balance",
                        entryDate: Date().addingTimeInterval(-86400 * 2),
                        excerpt: "I notice that when I take time to pause in the morning, my entire day feels more structured and less chaotic."
                    ),
                    JournalCitation(
                        entryId: UUID(),
                        entryTitle: "Work Stress",
                        entryDate: Date().addingTimeInterval(-86400 * 5),
                        excerpt: "Deadlines are piling up and I feel the pressure mounting. Need to find a way to disconnect."
                    )
                ]
                
                let aiResponse = ChatMessage.aiMessage(
                    heading1: "Patterns in Your Resilience",
                    heading2: "Key Observations",
                    body: "I've analyzed your recent journal entries and found some interesting connections. **Mindfulness seems to be a key driver** for your productivity.\n\nWhen you mention *taking morning pauses*, your subsequent entries tend to be more positive and focused. Conversely, days without this routine often correlate with higher reported stress levels regarding deadlines.\n\nHere is a breakdown of what I found:\n1. **Morning Routine**: Highly effective for mood regulation.\n2. **Workload Management**: Needs more separation from personal time.\n\nConsider trying to maintain that morning pause even on successful days.",
                    citations: mockCitations
                )
                
                withAnimation {
                    isSending = false
                    messages.append(aiResponse)
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
