
import Foundation
import Supabase

/// Singleton service for Supabase client interaction.
/// Ensure you have added the 'supabase-swift' package dependency to your project.
class SupabaseService {
    static let shared = SupabaseService()

    // Configuration from git-ignored Secrets.swift
    private let supabaseUrl: URL
    private let supabaseKey = Secrets.supabaseAnonKey

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: Secrets.supabaseUrl) else {
            fatalError("Invalid Supabase URL. Please update Secrets.swift with your project URL.")
        }
        self.supabaseUrl = url
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
            options: .init(
                auth: .init(
                    redirectToURL: URL(string: "memento://auth/callback")
                )
            )
        )
    }
}
