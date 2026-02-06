
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
    @Published var entries: [Entry] = [] {
        didSet { updateEntriesByMonth() }
    }
    @Published private(set) var entriesByMonth: [MonthGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userFirstName: String = ""

    // MARK: - Month Grouping (for UI display)

    private func updateEntriesByMonth() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.createdAt)?.start ?? entry.createdAt
        }
        self.entriesByMonth = grouped.map { (monthStart, entries) in
            MonthGroup(monthStart: monthStart, entries: entries.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.monthStart > $1.monthStart }
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
        // Production Mode - Use Supabase
        do {
            let userEntries = try await JournalService.shared.fetchEntries()
            self.entries = userEntries.map { mapToEntry($0) }

            // Load user profile to get first name
            await loadUserProfile()
        } catch {
            print("Error loading entries: \(error)")
            self.errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        #endif

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
                let created = try await JournalService.shared.createEntry(newJournalEntry)
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
                try await JournalService.shared.updateEntry(updatedJournalEntry)
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
