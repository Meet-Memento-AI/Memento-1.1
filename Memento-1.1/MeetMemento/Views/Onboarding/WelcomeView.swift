//
//  WelcomeView.swift
//  MeetMemento
//
//  Welcome screen (UI boilerplate).
//

import SwiftUI

public struct WelcomeView: View {
    public var onNext: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showCreateAccountSheet = false
    @State private var showSignInSheet = false
    @State private var showOnboardingFlow = false

    public init(onNext: (() -> Void)? = nil) {
        self.onNext = onNext
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()

                // App logo
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                // Headline
                Text("MeetMemento")
                    .font(type.h1)
                    .headerGradient()

                // Description
                Text("Your AI journaling partner.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)

                Spacer()

                // Authentication buttons
                VStack(spacing: 16) {
                    // Sign In button
                    PrimaryButton(title: "Sign In") {
                        showSignInSheet = true
                    }

                    // Create Account button
                    SecondaryButton(title: "Create Account") {
                        showCreateAccountSheet = true
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding()
            .background(theme.background.ignoresSafeArea())
        }
        .onAppear {
            checkAndShowOnboarding()
        }
        .sheet(isPresented: $showCreateAccountSheet) {
            CreateAccountBottomSheet(onSignUpSuccess: {
                showCreateAccountSheet = false
            })
            .useTheme()
            .useTypography()
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInBottomSheet(onSignInSuccess: {
                showSignInSheet = false
            })
            .useTheme()
            .useTypography()
            .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showOnboardingFlow) {
            OnboardingCoordinatorView()
                .useTheme()
                .useTypography()
                .environmentObject(authViewModel)
        }
        .onChange(of: authViewModel.hasCompletedOnboarding) { _, newValue in
            if newValue {
                showOnboardingFlow = false
            }
        }
    }

    // MARK: - Helper Methods

    private func checkAndShowOnboarding() {
        // Stub: In boilerplate, auth is always true, onboarding always complete
        // This is kept for structure
    }
}

// MARK: - Previews
#Preview("Welcome • Light") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Welcome • Dark") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
