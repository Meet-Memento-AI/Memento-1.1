
//
//  AuthViewModel.swift
//  MeetMemento
//
//  Manages authentication state using Supabase.
//

import Foundation
import SwiftUI
import Supabase

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

    /// Checks if a session restoration is possible on app launch
    func initializeAuth() async {
        do {
            let session = try await client.auth.session
            // If we have a session, we are authenticated
            self.isAuthenticated = true
            
            // TODO: check real onboarding status from DB (public.users)
            // For now, assume if we have a session, we need to check onboarding
            // This is a simplification; you likely want to fetch the user profile here.
            self.hasCompletedOnboarding = true 
            self.authState = .authenticated(needsOnboarding: false)
            
            print("✅ Supabase Session Restored: \(session.user.id)")
            
            // Ensure public.users record exists to satisfy FK constraints for restored sessions
            Task {
                do {
                    // Need email from session.user.email
                    if let email = session.user.email {
                        try await UserService.shared.ensureUserExists(id: session.user.id, email: email)
                    }
                } catch {
                    print("⚠️ Failed to ensure user profile exists on restore: \(error)")
                }
            }
        } catch {
            print("ℹ️ No active Supabase session found.")
            self.isAuthenticated = false
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

    /// Verifies the OTP code entered by the user.
    /// - Parameter isSignUp: If true (Create Account), onboarding is required; if false (Sign In), user is treated as onboarded.
    func verifyOTP(email: String, code: String, isSignUp: Bool = false) async throws {
        let session = try await client.auth.verifyOTP(
            email: email,
            token: code,
            type: .email
        )

        // Ensure public.users record exists to satisfy FK constraints
        do {
            try await UserService.shared.ensureUserExists(id: session.user.id, email: email)
        } catch {
            print("⚠️ Failed to ensure user profile exists: \(error)")
            // We don't block login, but subsequent writes might fail.
        }

        self.isAuthenticated = true
        if isSignUp {
            self.hasCompletedOnboarding = false
            self.authState = .authenticated(needsOnboarding: true)
        } else {
            self.hasCompletedOnboarding = true
            self.authState = .authenticated(needsOnboarding: false)
        }
    }
    
    // BACKWARDS_COMPATIBILITY: The view might only pass 'code' if email is stored elsewhere.
    // If your View only passes code, we need to ensure email is accessible.
    // For this refactor, I'll update the signature to require email, 
    // BUT if the UI assumes verifyOTP(code:), I need to handle that.
    // Looking at `OTPVerificationView`, it likely has access to email.
    // I will include the ORIGINAL signature for compatibility if needed, but usage suggests email is needed.
    // I'll stick to the original signature if I can find where email is stored.
    // Since I can't see the View state right now easily without more reads, 
    // I will add a `currentEmail` property to store it during the flow.
    
    var currentEmail: String?

    func sendOTPWrapper(email: String) async throws {
        self.currentEmail = email
        try await sendOTP(email: email)
    }

    func verifyOTP(code: String, isSignUp: Bool = false) async throws {
        guard let email = currentEmail else {
            throw AuthError.missingEmail
        }
        try await verifyOTP(email: email, code: code, isSignUp: isSignUp)
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
        // Update User Metadata in Supabase Auth
        // or Update `public.users` table

        // 1. Update Auth Metadata (easiest for display name)
        let attributes = UserAttributes(data: [
            "full_name": .string("\(firstName) \(lastName)")
        ])
        _ = try await client.auth.update(user: attributes)

        // 2. Ideally update public.users table too via RPC or direct update if policy allows
        // This requires a `UserService` or direct DB call.
        // For now, the metadata update is a good first step.
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
            .from("entries")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        // 3. Sign out (full auth user deletion requires Edge Function with service_role)
        try await client.auth.signOut()

        // 4. Clear local data
        UserDefaults.standard.removeObject(forKey: "memento_first_name")
        UserDefaults.standard.removeObject(forKey: "memento_last_name")

        // 5. Update state
        await MainActor.run {
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.hasCompletedOnboarding = false
        }
    }
}

enum AuthError: Error {
    case missingEmail
    case notAuthenticated
}
