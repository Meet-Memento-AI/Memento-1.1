//
//  OnboardingAsset-3.swift
//  MeetMemento
//
//  Value proposition banner for onboarding flow.
//

import SwiftUI

/// Chat input field showcase for onboarding flow.
struct OnboardingValueBanner: View {
    @State private var inputText = "Here are some of the stuff happening here. There's a lot going on. Not too sure what to do next up. What do my journals say about these past situations i've been in?"

    var body: some View {
        ChatInputField(text: $inputText, isInteractive: false, onSend: {})
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -4)
            .padding(.top, 32)
    }
}

// MARK: - Previews

#Preview("Value Banner • Light") {
    OnboardingValueBanner()
        .padding()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Value Banner • Dark") {
    OnboardingValueBanner()
        .padding()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
