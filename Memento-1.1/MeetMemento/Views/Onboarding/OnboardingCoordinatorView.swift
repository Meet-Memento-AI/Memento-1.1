//
//  OnboardingCoordinatorView.swift
//  MeetMemento
//
//  Coordinates navigation flow for onboarding steps (UI boilerplate).
//

import SwiftUI

// MARK: - Onboarding Routes

enum OnboardingRoute: Hashable {
    case learnAboutYourself
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
                switch route {
                case .learnAboutYourself:
                    LearnAboutYourselfView { userInput in
                        handlePersonalizationComplete(userInput)
                    }
                    .environmentObject(authViewModel)

                case .loading:
                    LoadingStateView {
                        handleOnboardingComplete()
                    }
                    .environmentObject(authViewModel)
                }
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

    // MARK: - Initial View Logic

    @ViewBuilder
    private var initialView: some View {
        if onboardingViewModel.shouldStartAtProfile {
            CreateAccountView(
                onComplete: {
                    handleProfileComplete()
                }
            )
            .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtPersonalization {
            LearnAboutYourselfView { userInput in
                handlePersonalizationComplete(userInput)
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

    private func handleProfileComplete() {
        onboardingViewModel.hasProfile = true
        navigationPath.append(OnboardingRoute.learnAboutYourself)
    }

    private func handlePersonalizationComplete(_ userInput: String) {
        onboardingViewModel.personalizationText = userInput

        Task {
            do {
                try await onboardingViewModel.createFirstJournalEntry(text: userInput)
                await MainActor.run {
                    onboardingViewModel.hasPersonalization = true
                    navigationPath.append(OnboardingRoute.loading)
                }
            } catch {
                await MainActor.run {
                    onboardingViewModel.errorMessage = error.localizedDescription
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
