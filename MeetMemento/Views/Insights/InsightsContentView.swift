//
//  InsightsContentView.swift
//  MeetMemento
//
//  Extracted content view from InsightsView - displays AI-generated insights
//

import SwiftUI

struct InsightsContentView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.tabBarHidden) private var tabBarHidden

    // Data
    let insight: InsightContent?
    let entriesCount: Int
    let totalEntries: Int
    let currentMonthDisplay: String
    let entriesForSelectedMonth: [Entry]

    // Loading/Animation State
    let isLoadingInsight: Bool
    let isShowingHeadlineSkeleton: Bool
    let displayedHeadline: String
    let loadingStep: Int
    let insightError: String?

    // Scroll tracking
    @Binding var lastScrollOffset: CGFloat
    let scrollDebouncer: ScrollDebouncer
    let scrollThreshold: CGFloat

    // Actions
    let onNavigateToEntry: (EntryRoute) -> Void
    let onRefresh: () async -> Void

    private let totalSteps = 5

    // Computed properties for display content
    private var displayHeadline: String {
        insight?.headline ?? "Analyzing your journal entries..."
    }

    private var displayObservation: String {
        insight?.observation ?? "Your insights will appear here once we've analyzed your recent entries."
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
        insight?.questions ?? [
            "What patterns do you notice in your recent entries?",
            "How have your feelings evolved over time?",
            "What would you like to explore further?"
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 32) {
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
                        } else {
                            Text(displayedHeadline)
                                .font(type.h3)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.overlayText)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    EntriesTag(count: entriesCount > 0 ? entriesCount : totalEntries)
                        .padding(.top, 8)
                        .opacity(loadingStep > 0 ? 1 : 0)
                        .scaleEffect(loadingStep > 0 ? 1 : 0.98)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Group 2: Core Observation
                Text(displayObservation)
                    .font(type.body1)
                    .foregroundStyle(theme.overlayText.opacity(0.6))
                    .lineSpacing(6)
                    .opacity(loadingStep > 1 ? 1 : 0)
                    .scaleEffect(loadingStep > 1 ? 1 : 0.99)

                // Group 3: Emotion Deep Dive (only show if sentiments available)
                if !displaySentiments.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        SentimentAnalysisCard(
                            emotionLabels: displaySentiments.map { $0.label },
                            emotionValues: displaySentiments.map { Double($0.score) }
                        )

                        if let extendedObservation = displayObservationExtended {
                            Text(extendedObservation)
                                .font(type.body1)
                                .foregroundStyle(theme.overlayText.opacity(0.6))
                                .lineSpacing(6)
                        }
                    }
                    .opacity(loadingStep > 2 ? 1 : 0)
                    .scaleEffect(loadingStep > 2 ? 1 : 0.98)
                }

                // Group 4: Keyword Landscapes (only show if keywords available)
                if !displayKeywords.isEmpty {
                    KeywordsCard(keywords: displayKeywords)
                        .opacity(loadingStep > 3 ? 1 : 0)
                        .scaleEffect(loadingStep > 3 ? 1 : 0.98)
                }

                // Group 5: The Path Forward
                FollowUpQuestionGroup(
                    questions: displayQuestions,
                    onQuestionTap: { _, question in
                        onNavigateToEntry(EntryRoute.createWithTitle(question))
                    }
                )
                .padding(.top, 10)
                .padding(.horizontal, -20)
                .opacity(loadingStep > 4 ? 1 : 0)
                .scaleEffect(loadingStep > 4 ? 1 : 0.99)

                // Error message if insight generation failed
                if let error = insightError {
                    Text("Unable to generate insights: \(error)")
                        .font(type.body2)
                        .foregroundStyle(theme.overlayText.opacity(0.5))
                        .padding(.top, 16)
                }

                // Hint when no insight yet and not loading
                if insight == nil, !isLoadingInsight, totalEntries > 0, entriesForSelectedMonth.isEmpty {
                    Text("No entries this month. Select another month or pull to refresh.")
                        .font(type.body2)
                        .foregroundStyle(theme.overlayText.opacity(0.5))
                        .padding(.top, 24)
                } else if insight == nil, !isLoadingInsight {
                    Text("Pull down to load insights for \(currentMonthDisplay)")
                        .font(type.body2)
                        .foregroundStyle(theme.overlayText.opacity(0.5))
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: UIScreen.main.bounds.height)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .scrollIndicators(.hidden)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            // Only apply tracking on iOS 18, not iOS 26+
            if #available(iOS 26.0, *) {
                // Native behavior - do nothing
            } else if let binding = tabBarHidden {
                scrollDebouncer.debounce {
                    updateTabBarVisibility(scrollOffset: value, binding: binding)
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func updateTabBarVisibility(scrollOffset: CGFloat, binding: Binding<Bool>) {
        let delta = scrollOffset - lastScrollOffset

        // Scrolling down (negative delta) - hide tab bar
        if delta < -scrollThreshold && !binding.wrappedValue {
            binding.wrappedValue = true
        }
        // Scrolling up (positive delta) - show tab bar
        else if delta > scrollThreshold && binding.wrappedValue {
            binding.wrappedValue = false
        }

        lastScrollOffset = scrollOffset
    }
}
