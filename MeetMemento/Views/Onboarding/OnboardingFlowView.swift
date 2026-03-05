//
//  OnboardingFlowView.swift
//  MeetMemento
//
//  Combines all onboarding views into a cohesive page-by-page flow
//  Uses TabView with PageTabViewStyle for smooth horizontal navigation
//

import SwiftUI

// MARK: - Onboarding Page

enum OnboardingPage: Int, CaseIterable {
    case yourName = 0
    case learnAboutYourself = 1
    case yourGoals = 2
    case faceID = 3
    case setupPin = 4
    case confirmPin = 5
    case loading = 6

    var title: String {
        switch self {
        case .yourName: return "Your Name"
        case .learnAboutYourself: return "Learn About Yourself"
        case .yourGoals: return "Your Goals"
        case .faceID: return "Security"
        case .setupPin: return "Setup PIN"
        case .confirmPin: return "Confirm PIN"
        case .loading: return "Setting Up"
        }
    }
}

// MARK: - Onboarding Flow View

public struct OnboardingFlowView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    @State private var currentPage: Int = 0
    @State private var hasLoadedState = false
    @State private var hasMetMinimumLoadTime = false
    @State private var setupPin: String = ""
    @State private var shouldShowPinFlow = false

    // Track completed pages for validation
    @State private var completedPages: Set<Int> = []
    @State private var transitionTask: Task<Void, Never>?

    private var totalPages: Int {
        shouldShowPinFlow ? 7 : 5  // Include or exclude PIN pages
    }

    public init() {}

    public var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            if !hasLoadedState || onboardingViewModel.isLoadingState || !hasMetMinimumLoadTime {
                OnboardingLoadingPlaceholder()
            } else {
                mainContent
            }
        }
        .useTheme()
        .useTypography()
        .task {
            guard !hasLoadedState else { return }

            // Start minimum load timer (fires independently)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                hasMetMinimumLoadTime = true
            }

            // Load state (does not block the timer above)
            await onboardingViewModel.loadCurrentState()
            hasLoadedState = true

            // Set initial page based on loaded state
            if onboardingViewModel.shouldStartAtProfile {
                currentPage = OnboardingPage.yourName.rawValue
            } else if onboardingViewModel.shouldStartAtPersonalization {
                currentPage = OnboardingPage.learnAboutYourself.rawValue
            } else {
                currentPage = OnboardingPage.loading.rawValue
            }
        }
        .onDisappear {
            transitionTask?.cancel()
            transitionTask = nil
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Page indicator
            pageIndicator
                .padding(.top, 8)

            // Page content
            TabView(selection: $currentPage) {
                // Page 0: Your Name
                YourNameView {
                    handleYourNameComplete()
                }
                .environmentObject(authViewModel)
                .tag(OnboardingPage.yourName.rawValue)

                // Page 1: Learn About Yourself
                LearnAboutYourselfView { userInput in
                    handleLearnAboutYourselfComplete(userInput)
                }
                .environmentObject(authViewModel)
                .tag(OnboardingPage.learnAboutYourself.rawValue)

                // Page 2: Your Goals
                YourGoalsView {
                    handleYourGoalsComplete()
                }
                .environmentObject(authViewModel)
                .tag(OnboardingPage.yourGoals.rawValue)

                // Page 3: Face ID
                FaceIDView(
                    onUseFaceID: {
                        handleUseFaceID()
                    },
                    onCreatePIN: {
                        handleCreatePIN()
                    }
                )
                .environmentObject(authViewModel)
                .tag(OnboardingPage.faceID.rawValue)

                // Page 4: Setup PIN (conditional)
                if shouldShowPinFlow {
                    SetupPinView(
                        onComplete: { pin in
                            handleSetupPinComplete(pin)
                        },
                        onCancel: {
                            handlePinCancel()
                        }
                    )
                    .environmentObject(authViewModel)
                    .tag(OnboardingPage.setupPin.rawValue)

                    // Page 5: Confirm PIN (conditional)
                    ConfirmPinView(
                        originalPin: setupPin,
                        onComplete: {
                            handleConfirmPinComplete()
                        },
                        onCancel: {
                            handlePinCancel()
                        }
                    )
                    .environmentObject(authViewModel)
                    .tag(OnboardingPage.confirmPin.rawValue)
                }

                // Page 6 (or 4): Loading
                LoadingStateView {
                    handleOnboardingComplete()
                }
                .environmentObject(authViewModel)
                .tag(OnboardingPage.loading.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .disabled(true)  // Disable swipe gesture - navigation controlled programmatically
        }
        .environmentObject(onboardingViewModel)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<effectivePageCount, id: \.self) { index in
                Circle()
                    .fill(pageColor(for: index))
                    .frame(width: pageSize(for: index), height: pageSize(for: index))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var effectivePageCount: Int {
        // Don't show loading page in indicator
        shouldShowPinFlow ? 6 : 4
    }

    private func pageColor(for index: Int) -> Color {
        if index < currentPageForIndicator {
            return theme.primary  // Completed
        } else if index == currentPageForIndicator {
            return theme.primary  // Current
        } else {
            return theme.border.opacity(0.5)  // Upcoming
        }
    }

    private func pageSize(for index: Int) -> CGFloat {
        index == currentPageForIndicator ? 10 : 8
    }

    private var currentPageForIndicator: Int {
        // Map actual page to indicator position
        if shouldShowPinFlow {
            return min(currentPage, 5)
        } else {
            // Skip PIN pages in count
            if currentPage >= OnboardingPage.loading.rawValue {
                return 3
            }
            return currentPage
        }
    }

    // MARK: - Navigation Handlers

    private func handleYourNameComplete() {
        onboardingViewModel.hasProfile = true
        completedPages.insert(OnboardingPage.yourName.rawValue)
        withAnimation {
            currentPage = OnboardingPage.learnAboutYourself.rawValue
        }
    }

    private func handleLearnAboutYourselfComplete(_ userInput: String) {
        onboardingViewModel.personalizationText = userInput
        completedPages.insert(OnboardingPage.learnAboutYourself.rawValue)
        withAnimation {
            currentPage = OnboardingPage.yourGoals.rawValue
        }
    }

    private func handleYourGoalsComplete() {
        completedPages.insert(OnboardingPage.yourGoals.rawValue)
        withAnimation {
            currentPage = OnboardingPage.faceID.rawValue
        }
    }

    private func handleUseFaceID() {
        onboardingViewModel.useFaceID = true
        completedPages.insert(OnboardingPage.faceID.rawValue)
        // Skip PIN setup, go straight to loading/completion
        finishSecuritySetup()
    }

    private func handleCreatePIN() {
        onboardingViewModel.useFaceID = false
        shouldShowPinFlow = true
        completedPages.insert(OnboardingPage.faceID.rawValue)

        // Small delay to allow TabView to update with new pages using Task
        transitionTask?.cancel()
        transitionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            withAnimation {
                currentPage = OnboardingPage.setupPin.rawValue
            }
        }
    }

    private func handleSetupPinComplete(_ pin: String) {
        setupPin = pin
        completedPages.insert(OnboardingPage.setupPin.rawValue)
        withAnimation {
            currentPage = OnboardingPage.confirmPin.rawValue
        }
    }

    private func handleConfirmPinComplete() {
        completedPages.insert(OnboardingPage.confirmPin.rawValue)
        finishSecuritySetup()
    }

    private func handlePinCancel() {
        shouldShowPinFlow = false
        setupPin = ""

        withAnimation {
            currentPage = OnboardingPage.faceID.rawValue
        }
    }

    private func finishSecuritySetup() {
        // Create journal entry and complete onboarding
        Task {
            do {
                if !onboardingViewModel.personalizationText.isEmpty {
                    try await onboardingViewModel.createFirstJournalEntry(
                        text: onboardingViewModel.personalizationText
                    )
                }
                await MainActor.run {
                    onboardingViewModel.hasPersonalization = true
                    withAnimation {
                        currentPage = OnboardingPage.loading.rawValue
                    }
                }
            } catch {
                await MainActor.run {
                    onboardingViewModel.errorMessage = error.localizedDescription
                    // Still navigate to loading on error for now
                    withAnimation {
                        currentPage = OnboardingPage.loading.rawValue
                    }
                }
            }
        }
    }

    private func handleOnboardingComplete() {
        Task {
            do {
                try await onboardingViewModel.completeOnboarding()
                await MainActor.run {
                    authViewModel.hasCompletedOnboarding = true
                }
            } catch {
                // Log error but continue
                print("Onboarding completion error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Loading View Placeholder

private struct OnboardingLoadingPlaceholder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(theme.primary)
                    .scaleEffect(1.5)

                Text("Loading...")
                    .typographyBody1()
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingFlowView()
        .environmentObject(AuthViewModel())
}
