//
//  OnboardingCoordinatorView.swift
//  MeetMemento
//
//  Coordinates navigation flow for onboarding steps (UI boilerplate).
//

import SwiftUI

// MARK: - Onboarding Routes
// Create Account flow order: YourName → LearnAboutYourself → YourGoals → FaceID → (Use Face ID → Loading) or (SetupPin → ConfirmPin → Loading).

enum OnboardingRoute: Hashable {
    case yourName
    case learnAboutYourself
    case yourGoals
    case faceID
    case setupPin
    case confirmPin(originalPin: String)
    case loading
}

// MARK: - Onboarding Coordinator View

public struct OnboardingCoordinatorView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    @State private var navigationPath = NavigationPath()
    @State private var hasLoadedState = false
    @State private var hasMetMinimumLoadTime = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if !hasLoadedState || onboardingViewModel.isLoadingState || !hasMetMinimumLoadTime {
                    LoadingView()
                } else {
                    initialView
                }
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(onboardingViewModel)
        .useTheme()
        .useTypography()
        .task {
            if !hasLoadedState {
                let minimumLoadTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        hasMetMinimumLoadTime = true
                    }
                }

                await onboardingViewModel.loadCurrentState()
                hasLoadedState = true
                await minimumLoadTask.value
            }
        }
    }

    // MARK: - Destination View Builder

    @ViewBuilder
    private func destinationView(for route: OnboardingRoute) -> some View {
        switch route {
        case .yourName:
            YourNameView {
                handleYourNameComplete()
            }
            .environmentObject(authViewModel)

        case .learnAboutYourself:
            LearnAboutYourselfView { userInput in
                handleLearnAboutYourselfComplete(userInput)
            }
            .environmentObject(authViewModel)

        case .yourGoals:
            YourGoalsView {
                handleYourGoalsComplete()
            }
            .environmentObject(authViewModel)

        case .faceID:
            FaceIDView(
                onUseFaceID: {
                    handleUseFaceID()
                },
                onCreatePIN: {
                    handleCreatePIN()
                }
            )
            .environmentObject(authViewModel)

        case .setupPin:
            SetupPinView(
                onComplete: { pin in
                    handleSetupPinComplete(pin)
                },
                onCancel: {
                    handlePinCancel()
                }
            )
            .environmentObject(authViewModel)

        case .confirmPin(let originalPin):
            ConfirmPinView(
                originalPin: originalPin,
                onComplete: {
                    handleConfirmPinComplete()
                },
                onCancel: {
                    handlePinCancel()
                }
            )
            .environmentObject(authViewModel)

        case .loading:
            LoadingStateView {
                handleOnboardingComplete()
            }
            .environmentObject(authViewModel)
        }
    }

    // MARK: - Initial View Logic

    @ViewBuilder
    private var initialView: some View {
        if onboardingViewModel.shouldStartAtProfile {
            // New flow starts with YourNameView
            YourNameView {
                handleYourNameComplete()
            }
            .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtPersonalization {
            LearnAboutYourselfView { userInput in
                handleLearnAboutYourselfComplete(userInput)
            }
            .environmentObject(authViewModel)
        } else {
            LoadingStateView {
                handleOnboardingComplete()
            }
            .environmentObject(authViewModel)
        }
    }

    // MARK: - Navigation Handlers

    private func handleYourNameComplete() {
        onboardingViewModel.hasProfile = true
        navigationPath.append(OnboardingRoute.learnAboutYourself)
    }

    private func handleLearnAboutYourselfComplete(_ userInput: String) {
        onboardingViewModel.personalizationText = userInput
        navigationPath.append(OnboardingRoute.yourGoals)
    }

    private func handleYourGoalsComplete() {
        navigationPath.append(OnboardingRoute.faceID)
    }

    private func handleUseFaceID() {
        onboardingViewModel.useFaceID = true
        // Skip PIN setup, go straight to loading/completion
        finishSecuritySetup()
    }

    private func handleCreatePIN() {
        onboardingViewModel.useFaceID = false
        navigationPath.append(OnboardingRoute.setupPin)
    }

    private func handleSetupPinComplete(_ pin: String) {
        navigationPath.append(OnboardingRoute.confirmPin(originalPin: pin))
    }

    private func handleConfirmPinComplete() {
        finishSecuritySetup()
    }

    private func handlePinCancel() {
        // Go back to FaceID view
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
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
                    navigationPath.append(OnboardingRoute.loading)
                }
            } catch {
                await MainActor.run {
                    onboardingViewModel.errorMessage = error.localizedDescription
                    // Still navigate to loading on error for now
                    navigationPath.append(OnboardingRoute.loading)
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
                // Stub: Log error
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingCoordinatorView()
        .environmentObject(AuthViewModel())
}
