//
//  InsightsView.swift
//  MeetMemento
//
//  Shows a placeholder insights view (UI boilerplate).
//

import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @State private var currentInsight: UserInsight?
    @State private var currentInsightContent: InsightContent?
    @State private var isLoading = false
    @State private var isShowingChat = false
    
    @State private var loadingStep = 0
    @State private var isShowingHeadlineSkeleton = true
    @State private var displayedHeadline = ""
    
    private let totalSteps = 5 // Tag, Observation, Sentiments, Keywords, Questions

    public init() {}

    public var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                emptyState(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Write some journal entries first."
                )
            } else if let insight = currentInsightContent {
                // Show Content
                contentView(insight: insight)
            } else if isLoading {
                // Loading / Generating state using the skeleton UI
                contentView(insight: .skeletonMock) // Use mock for skeleton layout
                contentView(insight: .skeletonMock) // Use mock for skeleton layout
            } else {
                // Initial loading state (before generateInsight triggers)
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
        .ignoresSafeArea()
        .onAppear {
             // Check if we need to load or refresh
             if currentInsight == nil {
                 loadInsight()
             } else if let insight = currentInsight {
                 // Check for staleness: If entry count differs, regenerate
                 let currentCount = filteredEntries.count
                 if insight.entriesAnalyzedCount != currentCount {
                     print("♻️ [InsightsView] Insight stale (Count: \(insight.entriesAnalyzedCount) vs \(currentCount)). Regenerating...")
                     generateInsight()
                 }
             }
        }
        .onChange(of: customStartDate) { _ in
            if selectedTimeFrame == .custom { generateInsight() }
        }
        .onChange(of: customEndDate) { _ in
            if selectedTimeFrame == .custom { generateInsight() }
        }
    }
    
    // MARK: - Time Frame Logic
    
    enum InsightTimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case custom = "Custom"
        
        var id: String { rawValue }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .custom: return nil
            }
        }
    }
    
    @State private var selectedTimeFrame: InsightTimeFrame = .month
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    /// Filters entries based on the selected time frame
    private var filteredEntries: [Entry] {
        if selectedTimeFrame == .custom {
            // Include full days for start and end
            let start = Calendar.current.startOfDay(for: customStartDate)
            let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
            
            return entryViewModel.entries.filter {
                $0.createdAt >= start && $0.createdAt <= end
            }
        }
        
        guard let days = selectedTimeFrame.days else {
            return entryViewModel.entries
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entryViewModel.entries.filter { $0.createdAt >= cutoffDate }
    }
    
    private func loadInsight() {
        isLoading = true
        Task {
            // 0. Load Default Configuration (if not already set by user interaction)
            // We only override if it's the very first load and no insight is present
            let defaultFrameName = await RemoteConfigService.shared.fetchDefaultTimeFrame()
            if let frame = InsightTimeFrame(rawValue: defaultFrameName), frame != .custom { // Don't default to custom without dates
                print("⚙️ [InsightsView] Applying remote default time frame: \(frame.rawValue)")
                await MainActor.run {
                    self.selectedTimeFrame = frame
                }
            }
            
            // 1. Try fetch existing
            if let existing = try? await InsightsService.shared.fetchLatestInsight() {
                self.currentInsight = existing
                self.currentInsightContent = existing.structuredContent
                isLoading = false
                runLoadingAnimation()
            } else {
                // If no existing insight, generate one immediately
                await MainActor.run {
                    generateInsight()
                }
            }
        }
    }
    
    @State private var animationTask: Task<Void, Never>?
    @State private var generationTask: Task<Void, Never>?

    private func generateInsight() {
        isLoading = true
        // isShowingHeadlineSkeleton and loadingStep will be reset in runLoadingAnimation()
        
        // Use filtered entries for specific time frame
        let entriesToAnalyze = filteredEntries
        
        // Cancel previous generation to avoid race conditions (e.g. spinning date picker)
        generationTask?.cancel()
        
        generationTask = Task {
            do {
                // Check if cancelled before starting expensive network call
                if Task.isCancelled { return }
                
                let newInsight = try await InsightsService.shared.generateInsight(entries: entriesToAnalyze)
                
                // Check if cancelled before updating UI
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.currentInsight = newInsight
                    self.currentInsightContent = newInsight.structuredContent
                    isLoading = false
                    runLoadingAnimation()
                }
            } catch {
                if !Task.isCancelled {
                    print("Error generating: \(error)")
                    isLoading = false
                }
            }
        }
    }

    private func runLoadingAnimation() {
        // Cancel any existing animation task to prevent interleaved text/animations
        animationTask?.cancel()
        
        animationTask = Task { @MainActor in
            // Check for cancellation at each step
            if Task.isCancelled { return }
            
            // Phase 1: Reset state
            isShowingHeadlineSkeleton = true
            displayedHeadline = ""
            loadingStep = 0
            
            // Wait 1.2s
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if Task.isCancelled { return }
            
            // Phase 2: Dissolve skeleton
            withAnimation(.easeInOut(duration: 0.6)) {
                isShowingHeadlineSkeleton = false
            }
            
            // Typewriter Effect
            let fullHeadline = currentInsightContent?.headline ?? ""
            for char in fullHeadline {
                if Task.isCancelled { return }
                displayedHeadline.append(char)
                try? await Task.sleep(nanoseconds: 30_000_000) // 0.03s per char
            }
            
            // Phase 3: Staggered Reveal
            if Task.isCancelled { return }
            for i in 1...totalSteps {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s stagger
                
                withAnimation(.easeInOut(duration: 1.2)) {
                    loadingStep = i
                }
            }
        }
    }

    private func refreshLogic() async {
        do {
            // Refresh uses the current filter context
            let entriesToAnalyze = filteredEntries
            let newInsight = try await InsightsService.shared.generateInsight(entries: entriesToAnalyze)
            
            await MainActor.run {
                self.currentInsight = newInsight
                self.currentInsightContent = newInsight.structuredContent
                // Restart the animation sequence to present the new insight
                runLoadingAnimation()
            }
        } catch {
            print("Refresh error: \(error)")
        }
    }

    /// Content view rendering the insight
    private func contentView(insight: InsightContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { // Standardized spacing
                
                // Time Frame Selector
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(InsightTimeFrame.allCases) { frame in
                        Text(frame.rawValue).tag(frame)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                .onChange(of: selectedTimeFrame) { _ in
                    // Automatically regenerate when filter changes, UNLESS it's custom (wait for date edits)
                    if selectedTimeFrame != .custom {
                        Task { await refreshLogic() }
                    }
                }
                
                if selectedTimeFrame == .custom {
                    VStack(spacing: 12) {
                        HStack {
                            DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                                .labelsHidden()
                            Text("-")
                                .foregroundStyle(.white)
                            DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Group 1: The Lead (Heading + Tag)
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        // Reserved space for the full headline to prevent layout jumps/reflow
                        Text(currentInsightContent?.headline ?? "")
                            .font(type.h3)
                            .fontWeight(.bold)
                            .foregroundStyle(.clear)
                            .accessibilityHidden(true)

                        if isShowingHeadlineSkeleton {
                            VStack(alignment: .leading, spacing: 12) {
                                SkeletonView(height: 28)
                                SkeletonView(width: 200, height: 28)
                            }
                            .transition(.opacity)
                        } else {
                            Text(displayedHeadline)
                                .font(type.h3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    // Show count based on current filter or result
                    EntriesTag(count: filteredEntries.count)
                        .padding(.top, 8)
                        .opacity(loadingStep > 0 ? 1 : 0)
                        .scaleEffect(loadingStep > 0 ? 1 : 0.98)
                        .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Group 2: Core Observation
                Text(insight.observation)
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(6)
                    .opacity(loadingStep > 1 ? 1 : 0)
                    .scaleEffect(loadingStep > 1 ? 1 : 0.99)
                    .animation(.easeInOut(duration: 1.5), value: loadingStep)
                    .padding(.vertical, 8)

                // Group 3: Emotion Deep Dive
                if let sentiments = insight.sentiment, !sentiments.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        SentimentAnalysisCard(
                            emotionLabels: sentiments.map { $0.label },
                            emotionValues: sentiments.map { Double($0.score) }
                        )
                        
                        Text("Analysis based on \(filteredEntries.count) entries from \(selectedTimeFrame.rawValue).")
                             .font(type.bodySmall)
                             .foregroundStyle(theme.mutedForeground)
                    }
                    .opacity(loadingStep > 2 ? 1 : 0)
                    .scaleEffect(loadingStep > 2 ? 1 : 0.98)
                    .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }
                
                // Group 4: Keyword Landscapes
                KeywordsCard(
                    keywords: [
                        "Stress",
                        "Keeping an image",
                        "Growing from within",
                        "New starts",
                        "Acceptance",
                        "Realizing the truth",
                        "Choosing better",
                    ]
                )
                .opacity(loadingStep > 3 ? 1 : 0)
                .scaleEffect(loadingStep > 3 ? 1 : 0.98)
                .animation(.easeInOut(duration: 1.5), value: loadingStep)

                // Group 5: The Path Forward
                FollowUpQuestionGroup(
                    questions: [
                        "What would happen if you let go of the need to control everything?",
                        "How does your past shape the way you see your future?",
                        "What are you afraid to admit to yourself?"
                    ],
                    onQuestionTap: { index, question in
                        print("Follow-up question \(index + 1) tapped: \(question)")
                    }
                )
                .padding(.top, 10)
                .padding(.horizontal, -20)
                .scaleEffect(loadingStep > 4 ? 1 : 0.99)
                .animation(.easeInOut(duration: 1.5), value: loadingStep)
                
                // Chat Entry Point
                Button {
                    print("🔍 [InsightsView] Chat button tapped - entryViewModel.entries.count: \(entryViewModel.entries.count)")
                    print("🔍 [InsightsView] filteredEntries.count: \(filteredEntries.count)")
                    isShowingChat = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 20))
                        Text("Chat about these insights")
                            .font(type.bodyBold)
                    }
                    .foregroundStyle(theme.primaryForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.primary)
                    )
                    .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.top, 24)
                .opacity(loadingStep > 4 ? 1 : 0) // Show with last group
                .animation(.easeInOut(duration: 1.5).delay(0.2), value: loadingStep)
            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 60)
        }
        .refreshable {
            await refreshLogic()
        }
        .fullScreenCover(isPresented: $isShowingChat) {
            let entries = entryViewModel.entries
            let _ = print("🔍 [InsightsView] Presenting chat with \(entries.count) entries")
            return AIChatView(
                allEntries: entries,
                initialTimeFrameLabel: selectedTimeFrame.rawValue
            )
        }
    }

    /// Reusable empty state view
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.white)

            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(message)
                .font(type.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }

    

}

// MARK: - Mocks for Skeleton
extension InsightContent {
    static var skeletonMock: InsightContent {
        InsightContent(
            headline: "Your emotional landscape reveals a blend of reflection...",
            observation: "You've been processing heavy emotions around work, identity, and control, yet your tone has steadily shifted...",
            sentiment: [
                InsightSentiment(label: "Anxiety", score: 50),
                InsightSentiment(label: "Hope", score: 20)
            ],
            keywords: ["Stress", "Growth", "Acceptance"],
            questions: ["What would happen if you let go?"]
        )
    }
}

// MARK: - Previews
#Preview("Empty State") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        PrimaryScale.primary900
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(viewModel)
    }
    .useTheme()
    .useTypography()
}

#Preview("With Entries") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        PrimaryScale.primary900
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.loadMockEntries()
            }
    }
    .useTheme()
    .useTypography()
}
