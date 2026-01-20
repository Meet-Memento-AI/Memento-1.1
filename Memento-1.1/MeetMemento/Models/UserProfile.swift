
import Foundation

/// Represents a user profile from the `users` table.
/// Note: Matches the `users` table in relevant schema (not `user_profiles` which is onboarding data).
public struct UserProfile: Identifiable, Codable, Hashable {
    public let id: UUID
    public let email: String
    public var fullName: String?
    public var avatarUrl: String?
    // Preferences is stored as JSONB in DB, we can map it to a struct or dictionary
    // For now keeping it generic or using a nested struct if simple.
    // Schema: {"language": "en", "appearance": "system", "notifications": true}
    public var preferences: UserPreferences?
    public var goals: String?
    public var selectedTopics: [String]?
    public var onboardingCompleted: Bool
    public var onboardingCompletedAt: Date?
    public let createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case preferences
        case goals
        case selectedTopics = "selected_topics"
        case onboardingCompleted = "onboarding_completed"
        case onboardingCompletedAt = "onboarding_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct UserPreferences: Codable, Hashable {
    public var language: String?
    public var appearance: String? // "system", "dark", "light"
    public var notifications: Bool?
}

// MARK: - Mocks
extension UserProfile {
    public static let mock = UserProfile(
        id: UUID(),
        email: "demo@example.com",
        fullName: "Alice Smith",
        avatarUrl: nil,
        preferences: UserPreferences(language: "en", appearance: "system", notifications: true),
        goals: "Mindfulness and consistency",
        selectedTopics: ["growth", "wellness"],
        onboardingCompleted: true,
        onboardingCompletedAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
}
