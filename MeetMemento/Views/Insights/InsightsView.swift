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

    let onNavigateToEntry: (EntryRoute) -> Void

    // Animation state
    @State private var loadingStep = 0
    @State private var isShowingHeadlineSkeleton = true
    @State private var displayedHeadline = ""
    @State private var hasAnimated = false

    // Data state - fetched from API
    @State private var insight: InsightContent?
    @State private var entriesCount: Int = 0
    @State private var isLoadingInsight = false
    @State private var insightError: String?

    // Fallback content for when API hasn't loaded yet
    private let fallbackHeadline = "Analyzing your journal entries..."
    private let fallbackObservation = "Your insights will appear here once we've analyzed your recent entries."
    private let totalSteps = 5 // Tag, Observation, Sentiments, Keywords, Questions

    // Computed properties for display content
    private var displayHeadline: String {
        insight?.headline ?? fallbackHeadline
    }

    private var displayObservation: String {
        insight?.observation ?? fallbackObservation
    }

    private var displayObservationExtended: String? {
        insight?.observationExtended
    }

    private var displaySentiments: [InsightSentiment] {
        insight?.sentiment ?? []
    }

    private var displayKeywords: [String] {
        insight?.keywords ?? []
    }

    private var displayQuestions: [String] {
        // Generate follow-up questions based on keywords or use defaults
        insight?.questions ?? [
            "What patterns do you notice in your recent entries?",
            "How have your feelings evolved over time?",
            "What would you like to explore further?"
        ]
    }

    public init(onNavigateToEntry: @escaping (EntryRoute) -> Void = { _ in }) {
        self.onNavigateToEntry = onNavigateToEntry
    }

    public var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                emptyState(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Your insights will appear here after journaling."
                )
            } else {
                placeholderContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            if insight == nil && !isLoadingInsight {
                Task {
                    await fetchInsights()
                }
            } else if !hasAnimated {
                startLoadingSequence()
            } else {
                showInstantContent()
            }
        }
    }

    // MARK: - Data Fetching

    private func fetchInsights() async {
        guard !entryViewModel.entries.isEmpty else { return }

        isLoadingInsight = true
        insightError = nil

        do {
            let result = try await InsightsService.shared.generateInsight(
                entries: entryViewModel.entries
            )
            await MainActor.run {
                self.insight = result.structuredContent
                self.entriesCount = result.entriesAnalyzedCount
                self.isLoadingInsight = false
                startLoadingSequence()
            }
        } catch {
            await MainActor.run {
                self.insightError = error.localizedDescription
                self.isLoadingInsight = false
                // Still show animation with fallback content
                startLoadingSequence()
            }
            print("❌ [InsightsView] Failed to fetch insights: \(error)")
        }
    }

    private func showInstantContent() {
        isShowingHeadlineSkeleton = false
        displayedHeadline = displayHeadline
        loadingStep = totalSteps
        hasAnimated = true
    }

    private func startLoadingSequence() {
        // Phase 1: Show headline skeleton
        isShowingHeadlineSkeleton = true
        displayedHeadline = ""
        loadingStep = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Phase 2: Dissolve skeleton and start typewriter for headline
            withAnimation(.easeInOut(duration: 0.6)) {
                isShowingHeadlineSkeleton = false
            }
            
            typewriteHeadline()
        }
    }

    private func typewriteHeadline() {
        let headlineText = displayHeadline
        let characters = Array(headlineText)
        for index in 0..<characters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03) {
                displayedHeadline.append(characters[index])

                // When finished, trigger the subsequent fade-ins
                if index == characters.count - 1 {
                    startStaggeredReveal()
                }
            }
        }
    }

    private func startStaggeredReveal() {
        // Phase 3: Fade in remaining sections sequentially
        for i in 1...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    loadingStep = i
                    if i == totalSteps {
                        hasAnimated = true
                    }
                }
            }
        }
    }

    /// Content when entries exist - displays AI-generated insights
    private var placeholderContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) { // Standardized spacing

                // Group 1: The Lead (Heading + Tag)
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        // Reserved space for the full headline to prevent layout jumps/reflow
                        Text(displayHeadline)
                            .font(type.h3)
                            .fontWeight(.bold)
                            .foregroundStyle(.clear)
                            .accessibilityHidden(true)

                        if isShowingHeadlineSkeleton || isLoadingInsight {
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

                    EntriesTag(count: entriesCount > 0 ? entriesCount : entryViewModel.entries.count)
                        .padding(.top, 8)
                        .opacity(loadingStep > 0 ? 1 : 0)
                        .scaleEffect(loadingStep > 0 ? 1 : 0.98)
                        .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Group 2: Core Observation
                Text(displayObservation)
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(6)
                    .opacity(loadingStep > 1 ? 1 : 0)
                    .scaleEffect(loadingStep > 1 ? 1 : 0.99)
                    .animation(.easeInOut(duration: 1.5), value: loadingStep)

                // Group 3: Emotion Deep Dive (only show if sentiments available)
                if !displaySentiments.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        SentimentAnalysisCard(
                            emotionLabels: displaySentiments.map { $0.label },
                            emotionValues: displaySentiments.map { Double($0.score) }
                        )

                        if let extendedObservation = displayObservationExtended {
                            Text(extendedObservation)
                                .font(type.body)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(6)
                        }
                    }
                    .opacity(loadingStep > 2 ? 1 : 0)
                    .scaleEffect(loadingStep > 2 ? 1 : 0.98)
                    .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }

                // Group 4: Keyword Landscapes (only show if keywords available)
                if !displayKeywords.isEmpty {
                    KeywordsCard(keywords: displayKeywords)
                        .opacity(loadingStep > 3 ? 1 : 0)
                        .scaleEffect(loadingStep > 3 ? 1 : 0.98)
                        .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }

                // Group 5: The Path Forward
                FollowUpQuestionGroup(
                    questions: displayQuestions,
                    onQuestionTap: { _, question in
                        onNavigateToEntry(.createWithTitle(question))
                    }
                )
                .padding(.top, 10)
                .padding(.horizontal, -20)
                .opacity(loadingStep > 4 ? 1 : 0)
                .scaleEffect(loadingStep > 4 ? 1 : 0.99)
                .animation(.easeInOut(duration: 1.5), value: loadingStep)

                // Error message if insight generation failed
                if let error = insightError {
                    Text("Unable to generate insights: \(error)")
                        .font(type.bodySmall)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            // Re-fetch data and reset animation sequence
            await entryViewModel.refreshEntries()
            resetAnimation()
            await fetchInsights()
        }
    }

    private func resetAnimation() {
        loadingStep = 0
        isShowingHeadlineSkeleton = true
        displayedHeadline = ""
        hasAnimated = false
        insight = nil
        insightError = nil
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
