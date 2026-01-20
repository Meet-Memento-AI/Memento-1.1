
import Foundation
import Supabase

/// Service for managing user data in `public.users`.
class UserService {
    static let shared = UserService()
    
    private var client: SupabaseClient {
        SupabaseService.shared.client
    }
    
    /// Fetches the user profile for the current session.
    func getCurrentProfile() async throws -> UserProfile? {
        guard let userId = client.auth.currentUser?.id else { return nil }
        
        // Using DTO pattern similar to JournalService if dates are tricky, 
        // but let's try standard Codable first since UserProfile dates are simpler (createdAt).
        // If it fails, we fall back to DTO.
        let response: [UserProfile] = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
            
        return response.first
    }
    
    /// Ensures that an entry exists in `public.users` for the authenticated user.
    /// If not, it creates one.
    func ensureUserExists(id: UUID, email: String) async throws {
        // 1. Check if exists
        let existing: [UserProfileDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: id)
            .execute()
            .value
            
        if !existing.isEmpty {
            return // Already exists
        }
        
        // 2. Create if missing
        // Use DTO to handle dates safely
        let newProfileDTO = UserProfileDTO(
            id: id,
            email: email,
            full_name: nil,
            avatar_url: nil,
            onboarding_completed: false,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("users")
            .insert(newProfileDTO)
            .execute()
            
        print("✅ Created new user profile for \(email)")
    }
}

// MARK: - DTO
private struct UserProfileDTO: Codable {
    let id: UUID
    let email: String
    let full_name: String?
    let avatar_url: String?
    let onboarding_completed: Bool
    let created_at: String
    let updated_at: String
}
