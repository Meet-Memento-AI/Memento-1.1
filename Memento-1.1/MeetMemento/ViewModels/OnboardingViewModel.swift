//
//  OnboardingViewModel.swift
//  MeetMemento
//
//  Minimal stub for onboarding state (UI boilerplate).
//

import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var personalizationText = ""
    @Published var hasProfile = false
    @Published var hasPersonalization = false
    @Published var isLoadingState = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    var shouldStartAtProfile: Bool { !hasProfile }
    var shouldStartAtPersonalization: Bool { hasProfile && !hasPersonalization }

    func loadCurrentState() async {
        // Stub: No-op for boilerplate
    }

    func saveProfileData() async throws {
        hasProfile = true
    }

    func createFirstJournalEntry(text: String) async throws {
        // Stub: No-op for boilerplate
    }

    func completeOnboarding() async throws {
        // Stub: No-op for boilerplate
    }
}
