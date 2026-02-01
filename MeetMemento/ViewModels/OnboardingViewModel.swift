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
    // User profile
    @Published var firstName = ""
    @Published var lastName = ""

    // Personalization
    @Published var personalizationText = ""

    // Goals
    @Published var selectedGoals: [String] = []

    // Security
    @Published var useFaceID = false
    @Published var setupPin = ""
    @Published var confirmedPin = ""

    // State tracking
    @Published var hasProfile = false
    @Published var hasPersonalization = false
    @Published var isLoadingState = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    var shouldStartAtProfile: Bool { !hasProfile }
    var shouldStartAtPersonalization: Bool { hasProfile && !hasPersonalization }

    func loadCurrentState() async {
        // TODO: Load user profile state from Supabase
        // Stub: No-op for boilerplate
    }

    func saveProfileData() async throws {
        // TODO: Save firstName and lastName to Supabase user profile
        hasProfile = true
    }

    func createFirstJournalEntry(text: String) async throws {
        // TODO: Create initial journal entry with personalizationText
        // Stub: No-op for boilerplate
    }

    func completeOnboarding() async throws {
        // TODO: Mark onboarding as complete in Supabase user profile
        // Stub: No-op for boilerplate
    }
}
