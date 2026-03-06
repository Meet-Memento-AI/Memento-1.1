
//
//  AuthViewModel.swift
//  MeetMemento
//
//  Manages authentication state using Supabase.
//

import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

/// Auth state enum for onboarding flow
enum AuthState: Equatable {
    case unauthenticated
    case authenticated(needsOnboarding: Bool)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var authState: AuthState = .unauthenticated

    // Pending profile from Apple Sign In (stub/flow)
    var pendingFirstName: String?
    var pendingLastName: String?

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    /// Restores session on app launch and checks onboarding status from DB.
    func initializeAuth() async {
        do {
            let session = try await client.auth.session

            if let email = session.user.email {
                try? await UserService.shared.ensureUserExists(id: session.user.id, email: email)
            }

            let hasOnboarded = try await UserService.shared.hasCompletedOnboarding(userId: session.user.id)

            self.isAuthenticated = true
            self.hasCompletedOnboarding = hasOnboarded
            self.authState = .authenticated(needsOnboarding: !hasOnboarded)

            print("✅ Supabase Session Restored: \(session.user.id), onboarded: \(hasOnboarded)")
        } catch {
            print("ℹ️ No active Supabase session found.")
            self.isAuthenticated = false
            self.hasCompletedOnboarding = false
            self.authState = .unauthenticated
        }
    }

    /// Explicitly check auth state (similar to initializeAuth, can range depending on logic)
    func checkAuthState() async {
        await initializeAuth()
    }

    /// Sends a magic link / OTP to the user's email
    func sendOTP(email: String) async throws {
        self.currentEmail = email
        // Using Email OTP (Magic Link logic can differ, standard is OTP)
        try await client.auth.signInWithOTP(email: email)
        print("✅ OTP sent to \(email)")
    }

    /// Verifies the OTP code and dynamically checks DB for onboarding status.
    func verifyOTP(email: String, code: String) async throws {
        let session = try await client.auth.verifyOTP(
            email: email,
            token: code,
            type: .email
        )

        do {
            try await UserService.shared.ensureUserExists(id: session.user.id, email: email)
        } catch {
            print("⚠️ Failed to ensure user profile exists: \(error)")
        }

        let hasOnboarded = try await UserService.shared.hasCompletedOnboarding(userId: session.user.id)

        try? await Task.sleep(nanoseconds: 300_000_000)

        self.isAuthenticated = true
        self.hasCompletedOnboarding = hasOnboarded
        self.authState = .authenticated(needsOnboarding: !hasOnboarded)
    }

    var currentEmail: String?

    func verifyOTP(code: String) async throws {
        guard let email = currentEmail else {
            throw AuthError.missingEmail
        }
        try await verifyOTP(email: email, code: code)
    }

    func signOut() async {
        try? await client.auth.signOut()
        self.isAuthenticated = false
        self.authState = .unauthenticated
    }

    func storePendingAppleProfile(firstName: String, lastName: String) {
        pendingFirstName = firstName
        pendingLastName = lastName
    }

    func clearPendingProfile() {
        pendingFirstName = nil
        pendingLastName = nil
    }

    /// Bypass authentication for development/testing purposes
    func bypassToMainApp() {
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true
        self.authState = .authenticated(needsOnboarding: false)
    }

    /// Skip to onboarding flow for UI testing (no real auth session).
    func skipToOnboardingForTesting() {
        self.isAuthenticated = true
        self.hasCompletedOnboarding = false
        self.authState = .authenticated(needsOnboarding: true)
    }

    func updateProfile(firstName: String, lastName: String) async throws {
        let attributes = UserAttributes(data: [
            "full_name": .string("\(firstName) \(lastName)")
        ])
        _ = try await client.auth.update(user: attributes)
        try await UserService.shared.updateFullName(firstName: firstName, lastName: lastName)
    }

    // MARK: - Apple Sign In

    /// Signs in with Apple using native AuthenticationServices
    func signInWithApple() async throws {
        let appleResult = try await AppleSignInService.shared.signIn()

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: appleResult.idToken,
                nonce: appleResult.nonce
            )
        )

        let email = appleResult.email ?? session.user.email ?? ""
        try await UserService.shared.ensureUserExistsWithProfile(
            id: session.user.id,
            email: email,
            fullName: appleResult.fullName
        )

        // Preserve Apple-provided name for YourNameView pre-fill (Apple only sends it once)
        if let fullName = appleResult.fullName, !fullName.isEmpty {
            let parts = fullName.split(separator: " ", maxSplits: 1)
            pendingFirstName = String(parts.first ?? "")
            pendingLastName = parts.count > 1 ? String(parts.last ?? "") : nil
        }

        let hasOnboarded = try await UserService.shared.hasCompletedOnboarding(userId: session.user.id)

        try? await Task.sleep(nanoseconds: 300_000_000)

        self.isAuthenticated = true
        self.hasCompletedOnboarding = hasOnboarded
        self.authState = .authenticated(needsOnboarding: !hasOnboarded)

        print("✅ Apple Sign In successful for user: \(session.user.id)")
    }

    // MARK: - Google Sign In

    /// Signs in with Google using the SDK's built-in ASWebAuthenticationSession flow
    func signInWithGoogle() async throws {
        let session = try await client.auth.signInWithOAuth(
            provider: .google
        ) { (session: ASWebAuthenticationSession) in
            session.prefersEphemeralWebBrowserSession = false
        }

        let email = session.user.email ?? ""
        let fullName = session.user.userMetadata["full_name"]?.stringValue

        try await UserService.shared.ensureUserExistsWithProfile(
            id: session.user.id,
            email: email,
            fullName: fullName
        )

        let hasOnboarded = try await UserService.shared.hasCompletedOnboarding(userId: session.user.id)

        try? await Task.sleep(nanoseconds: 300_000_000)

        self.isAuthenticated = true
        self.hasCompletedOnboarding = hasOnboarded
        self.authState = .authenticated(needsOnboarding: !hasOnboarded)

        print("✅ Google Sign In successful for user: \(session.user.id)")
    }

    /// Deletes the user's account and all associated data
    func deleteAccount() async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw AuthError.notAuthenticated
        }

        // 1. Delete user data from public.users table
        try await client
            .from("users")
            .delete()
            .eq("id", value: userId)
            .execute()

        // 2. Delete all journal entries
        try await client
            .from("journal_entries")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        // 3. Sign out (full auth user deletion requires Edge Function with service_role)
        try await client.auth.signOut()

        // 4. Clear local data
        UserDefaults.standard.removeObject(forKey: "memento_first_name")
        UserDefaults.standard.removeObject(forKey: "memento_last_name")
        SecurityService.shared.clearAll()

        // 5. Update state
        await MainActor.run {
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.hasCompletedOnboarding = false
        }
    }
}

enum AuthError: LocalizedError {
    case missingEmail
    case notAuthenticated
    case oauthFailed(String)
    case appleSignInFailed(String)
    case googleSignInFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return "Email is required"
        case .notAuthenticated:
            return "Not authenticated"
        case .oauthFailed(let message):
            return "OAuth failed: \(message)"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google Sign In failed: \(message)"
        }
    }
}
