
import Foundation
import Supabase

/// Singleton service for Supabase client interaction.
/// Ensure you have added the 'supabase-swift' package dependency to your project.
class SupabaseService {
    static let shared = SupabaseService()

    // Configuration from git-ignored Secrets.swift
    private let supabaseUrl = URL(string: Secrets.supabaseUrl)!
    private let supabaseKey = Secrets.supabaseAnonKey

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }
}
