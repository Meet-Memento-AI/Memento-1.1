//
//  UserContextService.swift
//  MeetMemento
//
//  Fetches onboarding/context data from user_profiles for AI personalization.
//  Used by chat-with-entries to tailor the Memento system prompt.
//

import Foundation
import Supabase

class UserContextService {
    static let shared = UserContextService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    /// Fetches UserContext (onboarding_self_reflection, selected_goals) for the current user.
    /// Returns nil if not authenticated or no profile exists.
    func fetchUserContext() async throws -> UserContext? {
        guard let userId = client.auth.currentUser?.id else { return nil }

        let response: [UserProfileRow] = try await client
            .from("user_profiles")
            .select("user_id, onboarding_self_reflection, selected_goals, identified_themes, theme_selection_count, themes_analyzed_at, created_at, updated_at")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        guard let row = response.first else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return UserContext(
            userId: row.user_id,
            onboardingSelfReflection: row.onboarding_self_reflection,
            selectedGoals: row.selected_goals,
            identifiedThemes: row.identified_themes,
            themeSelectionCount: row.theme_selection_count,
            themesAnalyzedAt: row.themes_analyzed_at.flatMap { formatter.date(from: $0) },
            createdAt: row.created_at.flatMap { formatter.date(from: $0) },
            updatedAt: row.updated_at.flatMap { formatter.date(from: $0) }
        )
    }

    /// Saves onboarding data (onboarding_self_reflection, selected_goals) to user_profiles.
    /// Called when user completes onboarding.
    func saveOnboardingContext(
        onboardingSelfReflection: String?,
        selectedGoals: [String]?
    ) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        let payload = UserProfileUpdatePayload(
            user_id: userId,
            onboarding_self_reflection: onboardingSelfReflection?.trimmingCharacters(in: .whitespacesAndNewlines),
            selected_goals: selectedGoals
        )

        try await client
            .from("user_profiles")
            .upsert(payload, onConflict: "user_id")
            .execute()
    }
}

// MARK: - Update Payload

private struct UserProfileUpdatePayload: Encodable {
    let user_id: UUID
    let onboarding_self_reflection: String?
    let selected_goals: [String]?
}

// MARK: - Private DTO

private struct UserProfileRow: Codable {
    let user_id: UUID
    let onboarding_self_reflection: String?
    let selected_goals: [String]?
    let identified_themes: [String]?
    let theme_selection_count: Int?
    let themes_analyzed_at: String?
    let created_at: String?
    let updated_at: String?
}
