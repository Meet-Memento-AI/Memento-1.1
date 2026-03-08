
//
//  EntryViewModel.swift
//  MeetMemento
//
//  Manages journal entries using Supabase JournalService.
//  Bridges local 'Entry' model with remote 'JournalEntry' model.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isLoading = false
    @Published var hasInitiallyLoaded = false
    @Published var errorMessage: String?
    @Published var userFirstName: String = ""

    /// Session PIN stored in memory for encryption operations (cleared on lock)
    private var sessionPIN: String?

    /// Whether we have a valid session PIN for encryption
    var hasSessionPIN: Bool { sessionPIN != nil }

    // Computed property for lazy grouping - reduces memory churn vs didSet
    var entriesByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.createdAt)?.start ?? entry.createdAt
        }
        return grouped.map { (monthStart, entries) in
            MonthGroup(monthStart: monthStart, entries: entries.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.monthStart > $1.monthStart }
    }

    // MARK: - Session PIN Management

    /// Sets the session PIN for encryption operations (call after unlock)
    func setSessionPIN(_ pin: String) {
        self.sessionPIN = pin
        #if DEBUG
        print("🔐 [EntryViewModel] Session PIN set")
        #endif
    }

    /// Clears the session PIN (call on app lock)
    func clearSessionPIN() {
        self.sessionPIN = nil
        #if DEBUG
        print("🔐 [EntryViewModel] Session PIN cleared")
        #endif
    }

    // MARK: - Search

    /// Filter entries by title or content text
    /// - Parameter query: Search query string
    /// - Returns: Filtered entries sorted by most recent first
    func searchEntries(query: String) -> [Entry] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return entries
        }
        let searchTerms = query.lowercased()
        return entries.filter { entry in
            entry.title.lowercased().contains(searchTerms) ||
            entry.text.lowercased().contains(searchTerms)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - CRUD Operations

    func loadEntries() async {
        isLoading = true
        errorMessage = nil

        #if DISABLE_SUPABASE
        // UI Testing Mode - Use mock data
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        self.entries = MockDataProvider.shared.mockEntries
        self.userFirstName = MockDataProvider.shared.mockUserFirstName
        print("📱 UI Mode: Loaded \(entries.count) mock entries")
        #else
        // Production Mode - Use Supabase with retry for cancelled requests
        var retryCount = 0
        let maxRetries = 3

        while retryCount < maxRetries {
            do {
                // Use PIN-encrypted fetch if session PIN is available
                let userEntries: [JournalEntry]
                if let pin = sessionPIN {
                    userEntries = try await JournalService.shared.fetchEntries(withPIN: pin)
                } else {
                    userEntries = try await JournalService.shared.fetchEntries()
                }
                self.entries = userEntries.map { mapToEntry($0) }

                // Load user profile to get first name
                await loadUserProfile()
                break // Success, exit retry loop
            } catch let error as NSError where error.code == NSURLErrorCancelled {
                // Request was cancelled (often during auth state transitions)
                retryCount += 1
                print("⚠️ Request cancelled (attempt \(retryCount)/\(maxRetries)), retrying...")

                if retryCount < maxRetries {
                    // Wait briefly for session to stabilize before retrying
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                } else {
                    print("Error loading entries after \(maxRetries) retries: \(error)")
                    self.errorMessage = "Failed to load. Please pull to refresh."
                }
            } catch {
                print("Error loading entries: \(error)")
                self.errorMessage = "Failed to load: \(error.localizedDescription)"
                break // Non-retryable error, exit loop
            }
        }
        #endif

        hasInitiallyLoaded = true
        isLoading = false
    }

    private func loadUserProfile() async {
        do {
            if let profile = try await UserService.shared.getCurrentProfile() {
                // Extract first name from fullName
                if let fullName = profile.fullName {
                    let components = fullName.split(separator: " ")
                    self.userFirstName = String(components.first ?? "")
                }
            }
        } catch {
            print("Error loading user profile: \(error)")
            // Don't set errorMessage - this is non-critical
        }
    }
    
    /// Wrapper for loadEntries() - provides semantic clarity at call sites
    /// where entries should only be loaded if needed (e.g., on first view appear)
    func loadEntriesIfNeeded() async {
        await loadEntries()
    }

    /// Wrapper for loadEntries() - provides semantic clarity at call sites
    /// where entries should be explicitly refreshed (e.g., pull-to-refresh)
    func refreshEntries() async {
        await loadEntries()
    }

    func createEntry(title: String, text: String) {
        let tempId = UUID()
        let newEntry = Entry(
            id: tempId,
            title: title.isEmpty ? "Untitled" : title,
            text: text,
            createdAt: Date()
        )

        // Optimistic insert - UI updates instantly
        entries.insert(newEntry, at: 0)

        Task {
            #if DISABLE_SUPABASE
            // UI Testing Mode - Add to mock data
            MockDataProvider.shared.addMockEntry(newEntry)
            print("📱 UI Mode: Created mock entry")
            #else
            // Production Mode - Use Supabase
            guard let userId = SupabaseService.shared.client.auth.currentUser?.id else {
                // Rollback on failure
                entries.removeAll { $0.id == tempId }
                print("Error: No authenticated user found.")
                errorMessage = "You must be signed in to save entries."
                return
            }

            let newJournalEntry = JournalEntry(
                userId: userId,
                title: title.isEmpty ? "Untitled" : title,
                content: text
            )

            do {
                // Use PIN-encrypted create if session PIN is available
                let created: JournalEntry
                if let pin = sessionPIN {
                    created = try await JournalService.shared.createEntry(newJournalEntry, withPIN: pin)
                } else {
                    created = try await JournalService.shared.createEntry(newJournalEntry)
                }
                // Replace temp entry with server-created entry (with real ID)
                if let index = entries.firstIndex(where: { $0.id == tempId }) {
                    entries[index] = mapToEntry(created)
                }
            } catch {
                // Rollback on failure
                entries.removeAll { $0.id == tempId }
                print("Error creating entry: \(error)")
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            #endif
        }
    }

    func updateEntry(_ entry: Entry) {
        Task {
            isLoading = true

            #if DISABLE_SUPABASE
            // UI Testing Mode - Update mock data
            MockDataProvider.shared.updateMockEntry(entry)
            if let i = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[i] = entry
            }
            print("📱 UI Mode: Updated mock entry")
            #else
            // Production Mode - Use Supabase
            guard let userId = SupabaseService.shared.client.auth.currentUser?.id else {
                errorMessage = "You must be signed in."
                isLoading = false
                return
            }

            // Map back to JournalEntry
            // Note: This relies on Entry.id matching JournalEntry.id which is true (UUID)
            let updatedJournalEntry = JournalEntry(
                id: entry.id,
                userId: userId,
                title: entry.title,
                content: entry.text,
                createdAt: entry.createdAt,
                updatedAt: Date() // Touch updated at
            )

            do {
                // Use PIN-encrypted update if session PIN is available
                if let pin = sessionPIN {
                    try await JournalService.shared.updateEntry(updatedJournalEntry, withPIN: pin)
                } else {
                    try await JournalService.shared.updateEntry(updatedJournalEntry)
                }
                // Optimistic update or refresh
                if let i = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[i] = entry
                }
            } catch {
                print("Error updating entry: \(error)")
                errorMessage = "Failed to update entry."
            }
            #endif

            isLoading = false
        }
    }

    func deleteEntry(id: UUID) {
        // Store for rollback
        guard let deletedEntry = entries.first(where: { $0.id == id }),
              let deletedIndex = entries.firstIndex(where: { $0.id == id }) else { return }

        // Optimistic delete - UI updates instantly
        entries.removeAll { $0.id == id }

        Task {
            #if DISABLE_SUPABASE
            // UI Testing Mode - Remove from mock data
            MockDataProvider.shared.deleteMockEntry(id: id)
            print("📱 UI Mode: Deleted mock entry")
            #else
            // Production Mode - Use Supabase
            do {
                try await JournalService.shared.deleteEntry(id: id)
            } catch {
                // Rollback on failure
                entries.insert(deletedEntry, at: min(deletedIndex, entries.count))
                print("Error deleting entry: \(error)")
                errorMessage = "Failed to delete entry."
            }
            #endif
        }
    }

    // MARK: - Mappers

    private func mapToEntry(_ je: JournalEntry) -> Entry {
        return Entry(
            id: je.id,
            title: je.title,
            text: je.content,
            createdAt: je.createdAt,
            updatedAt: je.updatedAt
        )
    }
}

// MARK: - Month Group Model

public struct MonthGroup: Identifiable {
    public let id = UUID()
    public let monthStart: Date
    public let entries: [Entry]

    public var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthStart)
    }

    public var entryCount: Int { entries.count }
}

// MARK: - Mock Data Support
extension EntryViewModel {
    func loadMockEntries() {
        self.entries = Entry.sampleEntries
    }

    /// Returns a view model with sample entries for previews (e.g. ContentView Insights tab with entries).
    static func withPreviewEntries() -> EntryViewModel {
        let vm = EntryViewModel()
        vm.entries = Entry.sampleEntries
        return vm
    }
}
