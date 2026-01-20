
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
    @Published var errorMessage: String?

    // MARK: - Month Grouping (for UI display)

    var entriesByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.createdAt)?.start ?? entry.createdAt
        }
        return grouped.map { (monthStart, entries) in
            MonthGroup(monthStart: monthStart, entries: entries.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.monthStart > $1.monthStart }
    }

    // MARK: - CRUD Operations

    func loadEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            let userEntries = try await JournalService.shared.fetchEntries()
            self.entries = userEntries.map { mapToEntry($0) }
        } catch {
            print("Error loading entries: \(error)")
            self.errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func loadEntriesIfNeeded() async {
        await loadEntries()
    }
    
    func refreshEntries() async {
        await loadEntries()
    }

    func createEntry(title: String, text: String) {
        Task {
            isLoading = true
            guard let userId = SupabaseService.shared.client.auth.currentUser?.id else {
                print("Error: No authenticated user found.")
                errorMessage = "You must be signed in to save entries."
                isLoading = false
                return
            }

            let newJournalEntry = JournalEntry(
                userId: userId,
                title: title.isEmpty ? "Untitled" : title,
                content: text
            )

            do {
                try await JournalService.shared.createEntry(newJournalEntry)
                await loadEntries() // Refresh list
            } catch {
                print("Error creating entry: \(error)")
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func updateEntry(_ entry: Entry) {
        Task {
            isLoading = true
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
            isLoading = false
        }
    }

    func deleteEntry(id: UUID) {
        Task {
            do {
                try await JournalService.shared.deleteEntry(id: id)
                entries.removeAll { $0.id == id }
            } catch {
                print("Error deleting entry: \(error)")
                errorMessage = "Failed to delete entry."
            }
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

struct MonthGroup: Identifiable {
    let id = UUID()
    let monthStart: Date
    let entries: [Entry]

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthStart)
    }

    var entryCount: Int { entries.count }
}

// MARK: - Mock Data Support
extension EntryViewModel {
    func loadMockEntries() {
        self.entries = Entry.sampleEntries
    }
}
