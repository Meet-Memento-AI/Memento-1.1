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
    
    // Time frame selection
    enum ChatTimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { rawValue }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    @State private var selectedTimeFrame: ChatTimeFrame = .month
    
    // Context - all entries from parent
    @State private var allEntries: [Entry] = []
    var initialTimeFrameLabel: String = "Month"
    
    // Computed filtered entries based on selected time frame
    private var contextEntries: [Entry] {
        print("🔍 [AIChatView] Computing contextEntries - allEntries.count: \(allEntries.count), selectedTimeFrame: \(selectedTimeFrame.rawValue)")
        guard let days = selectedTimeFrame.days else { return allEntries }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let filtered = allEntries.filter { $0.createdAt >= cutoffDate }
        print("🔍 [AIChatView] Filtered to \(filtered.count) entries for \(selectedTimeFrame.rawValue)")
        return filtered
    }
    
    public init(allEntries: [Entry] = [], initialTimeFrameLabel: String = "Month") {
        self._allEntries = State(initialValue: allEntries)
        self.initialTimeFrameLabel = initialTimeFrameLabel
        
        // Debug logging
        print("🔍 [AIChatView] Initialized with \(allEntries.count) entries")
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Background
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages list
                messagesScrollView
                
                // Input area
                inputArea
            }
            
            // Secondary Header with back button (Layered on top)
            Header(
                onBackTapped: { dismiss() }
            )
            
            // Time Frame Selector - positioned below header
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100) // Header height
                
                VStack(spacing: 12) {
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(ChatTimeFrame.allCases) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Analyzing \(contextEntries.count) entries")
                            .font(type.bodySmall)
                    }
                    .foregroundStyle(theme.mutedForeground)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(theme.background)
                
                Spacer()
            }
            .allowsHitTesting(true)
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(SwipeBackEnabler())
        .onAppear {
            loadInitialState()
            print("🔍 [AIChatView] onAppear - allEntries.count: \(allEntries.count)")
            print("🔍 [AIChatView] onAppear - contextEntries.count: \(contextEntries.count)")
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
                    if messages.isEmpty {
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
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 100) // Clear the header height (Safe area + 44 + gradient)
            }
            .onChange(of: messages.count) { oldCount, newCount in
                // Auto-scroll to bottom when new message arrives
                if newCount > oldCount, let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Journal Review Indicator
    
    private var journalReviewIndicator: some View {
        JournalReviewIndicator(reviewedCount: reviewedJournalCount)
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            
            // Input container
            ChatInputField(
                text: $inputText,
                isSending: isSending,
                onSend: sendMessage
            )
        }
    }
    
    // MARK: - Actions
    
    private func loadInitialState() {
        // Start with empty state or load history if persistence is added later
        // messages = []
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
        isSending = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        Task {
            do {
                // Call API with full history (including the new user message)
                let responseContent = try await InsightsService.shared.chat(
                    messages: messages,
                    entries: contextEntries
                )
                
                await MainActor.run {
                    let aiMessage = ChatMessage(
                        content: responseContent.body, // Fallback content
                        isFromUser: false,
                        citations: responseContent.citations,
                        aiOutputContent: responseContent
                    )
                    messages.append(aiMessage)
                    isSending = false
                }
            } catch {
                print("Chat Error: \(error)")
                await MainActor.run {
                    isSending = false
                    // Optional: Add error message to chat
                }
            }
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
}
