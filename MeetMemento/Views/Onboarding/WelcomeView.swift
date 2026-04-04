//
//  WelcomeView.swift
//  MeetMemento
//
//  Welcome screen with video background and unified auth buttons.
//

import SwiftUI

public struct WelcomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isAppleLoading = false
    @State private var isGoogleLoading = false
    @State private var authError: String = ""

    // Video loading and blur states
    @State private var isVideoReady = false
    @State private var playbackProgress: Double = 0
    @State private var hasCompletedFirstLoop = false

    // Staggered animation states
    @State private var showLogo = false
    @State private var showHeadline = false
    @State private var showButtons = false

    public init() {}

    /// Calculate blur amount based on video playback progress
    private var blurAmount: CGFloat {
        if hasCompletedFirstLoop {
            return 40  // Stay at max blur after first loop
        }
        return CGFloat(playbackProgress) * 40  // 0 to 40 during first playback
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // 1. Video background with progressive layer blur
                VideoBackground(
                    videoName: "welcome-bg",
                    videoExtension: "mp4",
                    isVideoReady: $isVideoReady,
                    playbackProgress: $playbackProgress
                )
                .blur(radius: blurAmount)
                .ignoresSafeArea()
                .onChange(of: playbackProgress) { oldValue, newValue in
                    // Detect loop completion (progress resets from ~1 to ~0)
                    if oldValue > 0.9 && newValue < 0.1 {
                        hasCompletedFirstLoop = true
                    }
                }

                // 2. Gradient overlay on video
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.white.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 3. Content - dissolve in when video ready
                if isVideoReady {
                    contentOverlay
                        .transition(.opacity)
                }

                // 4. Launch screen replica while loading
                if !isVideoReady {
                    launchLoadingView
                        .transition(.opacity)
                }
            }
            .animation(.easeIn(duration: 0.6), value: isVideoReady)
            .onChange(of: isVideoReady) { _, ready in
                guard ready else { return }
                withAnimation(.easeOut(duration: 0.5)) { showLogo = true }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { showHeadline = true }
                withAnimation(.easeOut(duration: 0.5).delay(0.4)) { showButtons = true }
            }
        }
        .useTypography()
    }

    // MARK: - Launch Loading View

    /// Matches the launch screen appearance for seamless transition
    private var launchLoadingView: some View {
        ZStack {
            // White background matching LaunchScreen.storyboard
            Color.white
                .ignoresSafeArea()

            // Memento-Logo centered, matching storyboard dimensions
            Image("Memento-Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 128)
        }
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(spacing: 0) {
            // Logo at center-top
            Image("Memento-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .padding(.top, 32)
                .opacity(showLogo ? 1 : 0)

            Spacer()

            // Headline - centered
            Text("Journal with your voice, reflect privately with AI")
                .font(.custom("Lora-SemiBold", size: 32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .accessibilityIdentifier("welcome.headline")
                .opacity(showHeadline ? 1 : 0)

            Spacer()

            // Auth buttons at bottom
            authButtonsSection
                .padding(.horizontal, 24)
                .opacity(showButtons ? 1 : 0)
        }
        .accessibilityIdentifier("welcome.root")
    }

    // MARK: - Auth Buttons Section

    @ViewBuilder
    private var authButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: { signInWithApple() }) {
                HStack(spacing: 8) {
                    if isAppleLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("Continue with Apple")
                        .font(type.body1Bold)
                }
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.button, style: .continuous))
            }
            .accessibilityIdentifier("welcome.continueApple")
            .disabled(isAppleLoading || isGoogleLoading)
            .opacity((isAppleLoading || isGoogleLoading) ? 0.7 : 1.0)

            GoogleSignInButton(
                title: isGoogleLoading ? "Signing in..." : "Continue with Google",
                scheme: .light
            ) {
                signInWithGoogle()
            }
            .disabled(isAppleLoading || isGoogleLoading)
            .opacity((isAppleLoading || isGoogleLoading) ? 0.7 : 1.0)

            if !authError.isEmpty {
                Text(authError)
                    .font(type.body2)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Auth Actions

    private func signInWithApple() {
        isAppleLoading = true
        authError = ""

        Task {
            do {
                try await authViewModel.signInWithApple()
                await MainActor.run {
                    isAppleLoading = false
                }
            } catch let error as AppleSignInError {
                await MainActor.run {
                    isAppleLoading = false
                    if case .canceled = error {
                        authError = ""
                    } else {
                        authError = error.localizedDescription
                    }
                }
            } catch {
                #if DEBUG
                print("🔴 Apple Sign In error: \(error)")
                #endif
                await MainActor.run {
                    isAppleLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func signInWithGoogle() {
        isGoogleLoading = true
        authError = ""

        Task {
            do {
                try await authViewModel.signInWithGoogle()
                await MainActor.run { isGoogleLoading = false }
            } catch {
                #if DEBUG
                print("🔴 Google Sign In error: \(error)")
                #endif
                await MainActor.run {
                    isGoogleLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Welcome • Light") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel.previewAuthReadyForWelcome())
        .preferredColorScheme(.light)
}

#Preview("Welcome • Dark") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel.previewAuthReadyForWelcome())
        .preferredColorScheme(.dark)
}
