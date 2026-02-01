//
//  ThemesIdentifiedView.swift
//  MeetMemento
//
//  Onboarding view for selecting identified themes from user's journal entry
//  Uses TabView with full-screen swipeable cards
//

import SwiftUI

public struct ThemesIdentifiedView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var uiTheme
    @Environment(\.typography) private var type

    // Props
    let themes: [IdentifiedTheme]
    let recommendedCount: Int

    // State
    @State private var selectedThemes: Set<String> = []
    @State private var currentTab: Int = 0
    @State private var isProcessing: Bool = false

    // Callback for when user completes this step
    public var onComplete: (([String]) -> Void)?

    public init(
        themes: [IdentifiedTheme],
        recommendedCount: Int = 3,
        onComplete: (([String]) -> Void)? = nil
    ) {
        self.themes = themes
        self.recommendedCount = recommendedCount
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // TabView with full-screen swipeable cards
            TabView(selection: $currentTab) {
                ForEach(Array(themes.enumerated()), id: \.offset) { index, themeData in
                    ThemeCardFullScreen(
                        themeData: themeData,
                        isSelected: Binding(
                            get: { selectedThemes.contains(themeData.name) },
                            set: { isSelected in
                                if isSelected {
                                    selectedThemes.insert(themeData.name)
                                } else {
                                    selectedThemes.remove(themeData.name)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .background(uiTheme.background.ignoresSafeArea())

            // Bottom UI overlay
            VStack {
                Spacer()

                // Selection counter + continue button
                HStack(spacing: 16) {
                    // Counter
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected \(selectedThemes.count) of \(themes.count)")
                            .font(type.body1Bold)
                            .foregroundStyle(uiTheme.foreground)

                        Text("Select at least \(recommendedCount)")
                            .font(type.caption)
                            .foregroundStyle(uiTheme.mutedForeground)
                    }

                    Spacer()

                    // Continue button
                    IconButton(systemImage: "chevron.right", size: 64) {
                        completeStep()
                    }
                    .opacity(canProceed ? 1.0 : 0.5)
                    .disabled(!canProceed)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                IconButtonNav(
                    icon: "chevron.left",
                    iconSize: 18,
                    buttonSize: 40,
                    enableHaptic: true,
                    onTap: { dismiss() }
                )
            }

            ToolbarItem(placement: .principal) {
                Text("Choose Your Themes")
                    .font(type.body2)
                    .foregroundStyle(uiTheme.mutedForeground)
            }
        }
    }

    // MARK: - Computed Properties

    private var canProceed: Bool {
        !isProcessing && selectedThemes.count >= 3
    }

    // MARK: - Actions

    private func completeStep() {
        guard canProceed else { return }

        isProcessing = true

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Call completion handler with selected themes
        onComplete?(Array(selectedThemes))

        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isProcessing = false
        }
    }
}

// MARK: - Progress Indicator Component

private struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? theme.primary : theme.primary.opacity(0.2))
                    .frame(width: 40, height: 8)
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ThemesIdentifiedView(
            themes: [
                IdentifiedTheme(
                    name: "stress-energy",
                    title: "Stress & Energy",
                    summary: "Understanding how stress affects your energy levels and finding balance in demanding times.",
                    keywords: ["stress", "tired", "overwhelmed"],
                    emoji: "⚡",
                    category: "wellness"
                ),
                IdentifiedTheme(
                    name: "career-purpose",
                    title: "Career & Purpose",
                    summary: "Exploring your professional path and finding meaning in your work.",
                    keywords: ["career", "work", "purpose"],
                    emoji: "🎯",
                    category: "growth"
                ),
                IdentifiedTheme(
                    name: "relationships-connection",
                    title: "Relationships & Connection",
                    summary: "Strengthening bonds with others and building meaningful connections.",
                    keywords: ["relationships", "connection", "social"],
                    emoji: "💝",
                    category: "social"
                )
            ],
            recommendedCount: 3
        ) { selectedThemes in
            print("Selected themes: \(selectedThemes)")
        }
        .useTheme()
        .useTypography()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ThemesIdentifiedView(
            themes: [
                IdentifiedTheme(
                    name: "anxiety-worry",
                    title: "Anxiety & Worry",
                    summary: "Managing anxious thoughts and finding calm in uncertain moments.",
                    keywords: ["anxiety", "worry", "nervous"],
                    emoji: "🌊",
                    category: "wellness"
                ),
                IdentifiedTheme(
                    name: "self-compassion",
                    title: "Self-Compassion",
                    summary: "Being kinder to yourself and embracing imperfection.",
                    keywords: ["self-love", "compassion", "kindness"],
                    emoji: "🤗",
                    category: "mindset"
                )
            ],
            recommendedCount: 2
        ) { selectedThemes in
            print("Selected themes: \(selectedThemes)")
        }
        .useTheme()
        .useTypography()
    }
    .preferredColorScheme(.dark)
}
