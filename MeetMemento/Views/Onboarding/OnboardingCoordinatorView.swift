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
            YourNameView(onComplete: { handleYourNameComplete() }, isFirstStep: false, onBack: { handleBack() })
                .environmentObject(authViewModel)

        case .learnAboutYourself:
            LearnAboutYourselfView(onComplete: { userInput in handleLearnAboutYourselfComplete(userInput) }, isFirstStep: false, onBack: { handleBack() })
                .environmentObject(authViewModel)

        case .yourGoals:
            YourGoalsView(onComplete: { handleYourGoalsComplete() }, isFirstStep: false, onBack: { handleBack() })
                .environmentObject(authViewModel)

        case .faceID:
            FaceIDView(
                onUseFaceID: { handleUseFaceID() },
                onCreatePIN: { handleCreatePIN() },
                isFirstStep: false,
                onBack: { handleBack() }
            )
            .environmentObject(authViewModel)

        case .setupPin:
            SetupPinView(
                onComplete: { pin in handleSetupPinComplete(pin) },
                onCancel: { handleBack() }
            )
            .environmentObject(authViewModel)

        case .confirmPin(let originalPin):
            ConfirmPinView(
                originalPin: originalPin,
                onComplete: { handleConfirmPinComplete() },
                onCancel: { handleBack() }
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
            YourNameView(onComplete: { handleYourNameComplete() }, isFirstStep: true)
                .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtPersonalization {
            LearnAboutYourselfView(onComplete: { userInput in handleLearnAboutYourselfComplete(userInput) }, isFirstStep: true)
                .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtGoals {
            YourGoalsView(onComplete: { handleYourGoalsComplete() }, isFirstStep: true)
                .environmentObject(authViewModel)
        } else {
            FaceIDView(
                onUseFaceID: { handleUseFaceID() },
                onCreatePIN: { handleCreatePIN() },
                isFirstStep: true
            )
            .environmentObject(authViewModel)
        }
    }

    // MARK: - Navigation Handlers

    private func handleYourNameComplete() {
        Task {
            do {
                try await onboardingViewModel.saveProfileData()
            } catch {
                print("⚠️ Failed to save profile: \(error)")
                onboardingViewModel.hasProfile = true
            }
            await MainActor.run {
                navigationPath.append(OnboardingRoute.learnAboutYourself)
            }
        }
    }

    private func handleLearnAboutYourselfComplete(_ userInput: String) {
        onboardingViewModel.personalizationText = userInput
        Task {
            do {
                try await onboardingViewModel.savePersonalizationText()
            } catch {
                print("⚠️ Failed to save personalization: \(error)")
                onboardingViewModel.hasPersonalization = true
            }
            await MainActor.run {
                navigationPath.append(OnboardingRoute.yourGoals)
            }
        }
    }

    private func handleYourGoalsComplete() {
        Task {
            do {
                try await onboardingViewModel.saveGoals()
            } catch {
                print("⚠️ Failed to save goals: \(error)")
                onboardingViewModel.hasGoals = true
            }
            await MainActor.run {
                navigationPath.append(OnboardingRoute.faceID)
            }
        }
    }

    private func handleUseFaceID() {
        onboardingViewModel.useFaceID = true
        SecurityService.shared.setSecurityMode(.faceID)
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
        // Store confirmed PIN in Keychain
        let pin = onboardingViewModel.confirmedPin
        if !pin.isEmpty {
            _ = SecurityService.shared.savePIN(pin)
            SecurityService.shared.setSecurityMode(.pin)
        }
        finishSecuritySetup()
    }

    private func handleBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    private func finishSecuritySetup() {
        Task {
            do {
                if !onboardingViewModel.personalizationText.isEmpty {
                    try await onboardingViewModel.createFirstJournalEntry(
                        text: onboardingViewModel.personalizationText
                    )
                }
            } catch {
                print("⚠️ Failed to create first journal entry: \(error)")
            }
            await MainActor.run {
                navigationPath.append(OnboardingRoute.loading)
            }
        }
    }

    private func handleOnboardingComplete() {
        Task {
            do {
                try await onboardingViewModel.completeOnboarding()
                await MainActor.run {
                    authViewModel.hasCompletedOnboarding = true
                    authViewModel.clearPendingProfile()
                }
            } catch {
                print("⚠️ Failed to mark onboarding complete: \(error)")
                await MainActor.run {
                    authViewModel.hasCompletedOnboarding = true
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingCoordinatorView()
        .environmentObject(AuthViewModel())
}
