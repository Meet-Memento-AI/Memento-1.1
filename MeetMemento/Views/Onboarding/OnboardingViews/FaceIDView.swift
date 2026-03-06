//
//  FaceIDView.swift
//  MeetMemento
//
//  Onboarding screen for biometric authentication setup
//

import SwiftUI

public struct FaceIDView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    public var onUseFaceID: (() -> Void)?
    public var onCreatePIN: (() -> Void)?
    public var isFirstStep: Bool = false
    public var onBack: (() -> Void)?

    public init(
        onUseFaceID: (() -> Void)? = nil,
        onCreatePIN: (() -> Void)? = nil,
        isFirstStep: Bool = false,
        onBack: (() -> Void)? = nil
    ) {
        self.onUseFaceID = onUseFaceID
        self.onCreatePIN = onCreatePIN
        self.isFirstStep = isFirstStep
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header with back button
                headerSection

                // Centered content
                VStack(spacing: 24) {
                    Spacer()

                    // Face ID icon
                    Image(systemName: "faceid")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundStyle(theme.primary)

                    // Title
                    Text("Set up Face ID")
                        .font(type.h3)
                        .foregroundStyle(theme.foreground)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("You can use Face ID to encrypt your journals so you won't need to type in your PIN every time.")
                        .font(.system(size: 17))
                        .lineSpacing(3.4)
                        .foregroundStyle(theme.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.horizontal, 20)
            }

            // Bottom buttons
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    PrimaryButton(title: "Use Face ID") {
                        handleUseFaceID()
                    }

                    SecondaryButton(title: "Create a PIN instead") {
                        handleCreatePIN()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.background, location: 0),
                    .init(color: theme.background.opacity(0), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .frame(height: 64)

            // Header content
            HStack(alignment: .center, spacing: 12) {
                // Back button (hidden on first step)
                if !isFirstStep {
                    IconButtonNav(
                        icon: "chevron.left",
                        iconSize: 20,
                        buttonSize: 40,
                        foregroundColor: theme.foreground,
                        useDarkBackground: false,
                        enableHaptic: true,
                        onTap: { onBack?() ?? dismiss() }
                    )
                    .accessibilityLabel("Back")
                }

                Spacer()

                // Placeholder for alignment
                Color.clear
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Actions

    private func handleUseFaceID() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onboardingViewModel.useFaceID = true
        onUseFaceID?()
    }

    private func handleCreatePIN() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onboardingViewModel.useFaceID = false
        onCreatePIN?()
    }
}

// MARK: - Previews

#Preview("Light") {
    FaceIDView()
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FaceIDView()
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.dark)
}
