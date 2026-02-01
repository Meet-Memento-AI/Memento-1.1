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
    @FocusState private var isInputFocused: Bool

    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            messagesScrollView

            // Input area
            inputArea
        }
        .background(theme.background.ignoresSafeArea())
        .background(SwipeBackEnabler().frame(width: 1, height: 1))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                }
                .accessibilityLabel("Back")
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
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
                        ChatEmptyState()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 160)
                            .id("empty")
                    } else {
                        ForEach(messages) { message in
                            ChatMessageBubble(
                                message: message,
                                onCitationsTapped: {
                                    if let citations = message.citations, !citations.isEmpty {
                                        selectedCitations = citations
                                        showCitationsSheet = true
                                    }
                                }
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
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

    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Gradient Overlay
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            // Input container
            ChatInputField(
                text: $inputText,
                isSending: isSending,
                onSend: sendMessage
            )
            .background(theme.background)
        }
    }
    
    // MARK: - Actions
    
    private func loadInitialState() {
        // Mock initial messages for UI preview (remove when backend is ready)
        // For now, start with empty state
        messages = []
        reviewedJournalCount = 5 // Mock data
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isSending else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            content: trimmedText,
            isFromUser: true
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        isInputFocused = false
        
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

// MARK: - Swipe Back Enabler
// Helper to re-enable the interactive pop gesture when the navigation bar is hidden
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Re-enable the interactive pop gesture recognizer
        DispatchQueue.main.async {
            uiViewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
