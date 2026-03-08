//
//  WelcomeView.swift
//  MeetMemento
//
//  Welcome screen with carousel and unified auth buttons.
//

import SwiftUI

public struct WelcomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var carouselPage = 0
    @State private var isAppleLoading = false
    @State private var isGoogleLoading = false
    @State private var authError: String = ""

    public init() {}

    public var body: some View {
        let isDarkBackground = carouselPage == 1

        NavigationStack {
            VStack(spacing: 12) {

                // Centered Carousel
                VStack(spacing: 32) {
                    TabView(selection: $carouselPage) {
                        VStack(spacing: 0) {
                            carouselHeader(
                                title: carouselItems[0].title,
                                description: carouselItems[0].description,
                                isDark: isDarkBackground
                            )
                            OnboardingStackedCards()
                        }
                        .tag(0)

                        VStack(spacing: 0) {
                            carouselHeader(
                                title: carouselItems[1].title,
                                description: carouselItems[1].description,
                                isDark: isDarkBackground
                            )
                            OnboardingSentimentCard()
                        }
                        .tag(1)

                        VStack(spacing: 0) {
                            carouselHeader(
                                title: carouselItems[2].title,
                                description: carouselItems[2].description,
                                isDark: isDarkBackground
                            )
                            OnboardingValueBanner()
                                .padding(.top, 16)
                        }
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 520)
                    .padding(.horizontal, -16)

                    HStack(spacing: 8) {
                        ForEach(0..<carouselItems.count, id: \.self) { index in
                            Circle()
                                .fill(carouselPage == index
                                      ? (isDarkBackground ? .white : theme.primary)
                                      : (isDarkBackground ? .white.opacity(0.2) : theme.primary.opacity(0.2)))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: carouselPage)
                        }
                    }
                }

                Spacer()

                // Authentication buttons
                VStack(spacing: 12) {
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    }
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
                            .foregroundStyle(theme.destructive)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.top)
            .padding(.horizontal)
            .background(
                ZStack {
                    if isDarkBackground {
                        theme.backgroundGradient
                            .transition(.opacity)
                    } else {
                        theme.background
                            .transition(.opacity)
                    }
                }
                .ignoresSafeArea()
            )
            .animation(.easeInOut(duration: 0.6), value: carouselPage)
        }
        .useTypography()
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

    // MARK: - Helpers

    @ViewBuilder
    private func carouselHeader(title: String, description: String, isDark: Bool) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .typographyH2()
                .foregroundStyle(isDark ? .white : theme.foreground)
                .multilineTextAlignment(.center)

            Text(description)
                .typographyBody1()
                .foregroundStyle(isDark ? .white.opacity(0.8) : theme.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 16)
    }

    private let carouselItems = [
        CarouselItem(title: "Journal safely and securely", description: "Write or voice your journal entires."),
        CarouselItem(title: "Track Your Growth", description: "Visualize your emotional journey and personal evolution over time."),
        CarouselItem(title: "Reflect with AI", description: "Get personalized insights and identify patterns in your thoughts.")
    ]
}

private struct CarouselItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
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
