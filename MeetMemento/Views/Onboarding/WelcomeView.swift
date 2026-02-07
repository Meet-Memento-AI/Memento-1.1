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
    @State private var carouselPage = 0

    public init(onNext: (() -> Void)? = nil) {
        self.onNext = onNext
    }

    public var body: some View {
        let isDarkBackground = carouselPage == 1

        NavigationStack {
            VStack(spacing: 12) {

                // Centered Carousel
                VStack(spacing: 32) {
                    TabView(selection: $carouselPage) {
                        // Page 0: Stacked Cards
                        VStack(spacing: 0) {
                            carouselHeader(
                                title: carouselItems[0].title,
                                description: carouselItems[0].description,
                                isDark: isDarkBackground
                            )
                            OnboardingStackedCards()
                        }
                        .tag(0)

                        // Page 1: Sentiment Analysis
                        VStack(spacing: 0) {
                            carouselHeader(
                                title: carouselItems[1].title,
                                description: carouselItems[1].description,
                                isDark: isDarkBackground
                            )
                            OnboardingSentimentCard()
                        }
                        .tag(1)

                        // Page 2: Value Banner
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
                    .padding(.horizontal, -16) // Extend to edges, counteract parent padding

                    // Custom Page Indicator
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
        .onAppear {
            checkAndShowOnboarding()
        }
        .sheet(isPresented: $showCreateAccountSheet) {
            AuthBottomSheet(mode: .signUp, onSuccess: {
                showCreateAccountSheet = false
            })
            .useTheme()
            .useTypography()
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showSignInSheet) {
            AuthBottomSheet(mode: .signIn, onSuccess: {
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
