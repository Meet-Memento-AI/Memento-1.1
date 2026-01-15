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

    @State private var loadingStep = 0
    @State private var isShowingHeadlineSkeleton = true
    @State private var displayedHeadline = ""
    private let fullHeadline = "Your emotional landscape reveals a blend of reflection, frustration, and growth that you’re working towards during this difficult transition period"
    private let fullObservation = "You've been processing heavy emotions around work, identity, and control, yet your tone has steadily shifted toward acceptance and purpose. Despite moments of doubt, there's an emerging sense that you're on the right path forward"
    private let totalSteps = 5 // Tag, Observation, Sentiments, Keywords, Questions

    public init() {}

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
        .ignoresSafeArea()
        .onAppear {
            startLoadingSequence()
        }
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
        let characters = Array(fullHeadline)
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
                }
            }
        }
    }

    /// Placeholder content when entries exist
    private var placeholderContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { // Standardized spacing
                
                // Group 1: The Lead (Heading + Tag)
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        // Reserved space for the full headline to prevent layout jumps/reflow
                        Text(fullHeadline)
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

                    EntriesTag(count: 10)
                        .padding(.top, 8)
                        .opacity(loadingStep > 0 ? 1 : 0)
                        .scaleEffect(loadingStep > 0 ? 1 : 0.98)
                        .animation(.easeInOut(duration: 1.5), value: loadingStep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Group 2: Core Observation
                Text(fullObservation)
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(6)
                    .opacity(loadingStep > 1 ? 1 : 0)
                    .scaleEffect(loadingStep > 1 ? 1 : 0.99)
                    .animation(.easeInOut(duration: 1.5), value: loadingStep)
                    .padding(.vertical, 8)

                // Group 3: Emotion Deep Dive
                VStack(alignment: .leading, spacing: 20) {
                    SentimentAnalysisCard(
                        emotionLabels: ["Anxiety", "Anticipation", "Fear", "Regret"],
                        emotionValues: [50, 20, 18, 12]
                    )
                    
                    Text("Your processing of heavy emotions around work and identity has shifted toward acceptance and purpose.")
                        .font(type.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(6)
                }
                .opacity(loadingStep > 2 ? 1 : 0)
                .scaleEffect(loadingStep > 2 ? 1 : 0.98)
                .animation(.easeInOut(duration: 1.5), value: loadingStep)
                
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
                .opacity(loadingStep > 4 ? 1 : 0)
                .scaleEffect(loadingStep > 4 ? 1 : 0.99)
                .animation(.easeInOut(duration: 1.5), value: loadingStep)
            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 60)
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
