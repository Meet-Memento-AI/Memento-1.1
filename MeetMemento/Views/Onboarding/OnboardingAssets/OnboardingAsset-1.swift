//
//  OnboardingAsset-1.swift
//  MeetMemento
//
//  Stacked journal cards for onboarding carousel.
//

import SwiftUI

/// A stacked display of two JournalCards for the onboarding flow.
struct OnboardingStackedCards: View {
    @State private var isVisible = false

    var body: some View {
        JournalCard(
            title: "Feeling incredible today",
            excerpt: "There's nothing like running through Golden Gate Park on a Saturday morning. I'm incredibly energized...",
            date: Date(),
            isInteractive: false
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 24, x: 0, y: 8)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)
        .padding(.top, 32)
        .onAppear {
            isVisible = true
        }
        .padding(.horizontal, 16)

    }
}

// MARK: - Previews

#Preview("Stacked Cards • Light") {
    OnboardingStackedCards()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Stacked Cards • Dark") {
    OnboardingStackedCards()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
