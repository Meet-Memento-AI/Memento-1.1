# Entry Statistics Usage Guide

## Overview

SupabaseService.swift now includes two new methods to track journal entries:

1. **`getUserEntryCount()`** - Returns total count (integer)
2. **`getUserEntryStats()`** - Returns detailed statistics

---

## 📊 New Methods

### **1. Get Entry Count (Simple)**

Returns the total number of entries for the current user.

```swift
// Get simple count
let count = try await SupabaseService.shared.getUserEntryCount()
print("User has \(count) journal entries")
```

**Use Cases:**
- Show entry count in settings
- Display progress badges
- Check if user has minimum entries for features
- Show "You've written X entries!" messages

---

### **2. Get Entry Statistics (Detailed)**

Returns detailed statistics about the user's journal entries.

```swift
// Get detailed stats
let stats = try await SupabaseService.shared.getUserEntryStats()

print("Total entries: \(stats.totalEntries)")
print("This week: \(stats.entriesThisWeek)")
print("This month: \(stats.entriesThisMonth)")
print("First entry: \(stats.firstEntryDate ?? "None")")
print("Last entry: \(stats.lastEntryDate ?? "None")")

// Use convenience properties for Date objects
if let firstDate = stats.firstEntryAsDate {
    print("Journaling since: \(firstDate.formatted())")
}
```

**Use Cases:**
- Show weekly/monthly progress
- Display "streak" information
- Show "journaling since" date
- Analytics and insights view

---

## 📱 Example Usage in Views

### **Example 1: Settings View Badge**

Show entry count in settings:

```swift
// In SettingsView.swift
struct SettingsView: View {
    @State private var entryCount: Int = 0

    var body: some View {
        VStack {
            HStack {
                Text("Journal Entries")
                    .font(.headline)
                Spacer()
                Text("\(entryCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(theme.card)
            .cornerRadius(12)
        }
        .task {
            await loadEntryCount()
        }
    }

    private func loadEntryCount() async {
        do {
            entryCount = try await SupabaseService.shared.getUserEntryCount()
        } catch {
            print("Failed to load entry count: \(error)")
        }
    }
}
```

---

### **Example 2: Insights Dashboard**

Show detailed statistics:

```swift
// In InsightsView.swift
struct InsightsStatsCard: View {
    @State private var stats: EntryStats?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)

            if let stats = stats {
                HStack(spacing: 20) {
                    StatItem(
                        label: "Total",
                        value: "\(stats.totalEntries)",
                        icon: "book.fill"
                    )

                    StatItem(
                        label: "This Week",
                        value: "\(stats.entriesThisWeek)",
                        icon: "calendar"
                    )

                    StatItem(
                        label: "This Month",
                        value: "\(stats.entriesThisMonth)",
                        icon: "chart.bar.fill"
                    )
                }

                if let firstDate = stats.firstEntryAsDate {
                    Text("Journaling since \(firstDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(theme.card)
        .cornerRadius(12)
        .task {
            await loadStats()
        }
    }

    private func loadStats() async {
        do {
            stats = try await SupabaseService.shared.getUserEntryStats()
        } catch {
            print("Failed to load stats: \(error)")
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

### **Example 3: Conditional Feature Unlock**

Check if user has enough entries for a feature:

```swift
// In JournalView.swift - "Dig Deeper" tab
@ViewBuilder
private var digDeeperContent: some View {
    if entryViewModel.entries.isEmpty {
        emptyState(
            icon: "lightbulb.fill",
            title: "No entries yet",
            message: "Start writing to unlock reflection questions."
        )
    } else {
        // Use the count from service instead of local array
        Task {
            let count = try await SupabaseService.shared.getUserEntryCount()
            if count < 3 {
                VStack {
                    Text("Keep writing!")
                    Text("Write \(3 - count) more \(3 - count == 1 ? "entry" : "entries")")
                }
            } else {
                // Show reflection questions
                ScrollView {
                    // ... FollowUpCard components
                }
            }
        }
    }
}
```

---

### **Example 4: Welcome Message**

Show personalized welcome based on entry count:

```swift
// In JournalView.swift header
struct WelcomeHeader: View {
    @State private var entryCount: Int = 0

    var welcomeMessage: String {
        switch entryCount {
        case 0:
            return "Start your journaling journey"
        case 1:
            return "Great start! Keep going"
        case 2...5:
            return "You're building momentum!"
        case 6...10:
            return "Excellent progress!"
        default:
            return "You're a journaling pro!"
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(welcomeMessage)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(entryCount) \(entryCount == 1 ? "entry" : "entries")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .task {
            entryCount = (try? await SupabaseService.shared.getUserEntryCount()) ?? 0
        }
    }
}
```

---

## 🔄 Refreshing Stats

### **Manual Refresh**

```swift
Button("Refresh Stats") {
    Task {
        await loadStats()
    }
}

func loadStats() async {
    do {
        let stats = try await SupabaseService.shared.getUserEntryStats()
        // Update UI
    } catch {
        print("Error: \(error)")
    }
}
```

### **Auto-Refresh After Creating Entry**

```swift
// In EntryViewModel or after creating entry
func createEntry(title: String, text: String) async {
    do {
        let entry = try await SupabaseService.shared.createEntry(title: title, text: text)

        // Refresh stats after creation
        let newCount = try await SupabaseService.shared.getUserEntryCount()
        print("Entry created! Total: \(newCount)")

    } catch {
        print("Error: \(error)")
    }
}
```

---

## 🧪 Testing the Functions

### **Test in Console/Xcode Debug**

```swift
// Add this to a button action or .onAppear for testing

Task {
    print("🧪 Testing entry statistics...")

    // Test 1: Get count
    do {
        let count = try await SupabaseService.shared.getUserEntryCount()
        print("✅ Entry count: \(count)")
    } catch {
        print("❌ Count failed: \(error)")
    }

    // Test 2: Get stats
    do {
        let stats = try await SupabaseService.shared.getUserEntryStats()
        print("✅ Stats loaded:")
        print("   Total: \(stats.totalEntries)")
        print("   This week: \(stats.entriesThisWeek)")
        print("   This month: \(stats.entriesThisMonth)")
        print("   First: \(stats.firstEntryDate ?? "None")")
        print("   Last: \(stats.lastEntryDate ?? "None")")
    } catch {
        print("❌ Stats failed: \(error)")
    }
}
```

---

## 📊 EntryStats Data Model

```swift
struct EntryStats: Codable {
    let totalEntries: Int           // Total number of entries
    let entriesThisWeek: Int        // Entries in last 7 days
    let entriesThisMonth: Int       // Entries in last 30 days
    let firstEntryDate: String?     // ISO8601 date string
    let lastEntryDate: String?      // ISO8601 date string

    // Convenience properties
    var firstEntryAsDate: Date?     // Converts string to Date
    var lastEntryAsDate: Date?      // Converts string to Date
}
```

---

## ⚡ Performance Notes

### **Caching**

Consider caching stats to avoid repeated queries:

```swift
class StatsCache: ObservableObject {
    @Published var stats: EntryStats?
    private var lastRefresh: Date?
    private let cacheTimeout: TimeInterval = 60 // 1 minute

    func getStats() async throws -> EntryStats {
        // Return cached if fresh
        if let stats = stats,
           let lastRefresh = lastRefresh,
           Date().timeIntervalSince(lastRefresh) < cacheTimeout {
            return stats
        }

        // Fetch fresh stats
        let fresh = try await SupabaseService.shared.getUserEntryStats()

        await MainActor.run {
            self.stats = fresh
            self.lastRefresh = Date()
        }

        return fresh
    }

    func invalidate() {
        stats = nil
        lastRefresh = nil
    }
}
```

### **When to Refresh**

Refresh stats when:
- ✅ User creates new entry
- ✅ User deletes entry
- ✅ User navigates to stats/insights view
- ✅ App comes to foreground
- ❌ Don't refresh on every view appear (use caching)

---

## 🎯 Summary

### **Added to SupabaseService.swift:**

1. ✅ `getUserEntryCount()` - Returns Int
2. ✅ `getUserEntryStats()` - Returns EntryStats
3. ✅ `EntryStats` struct - Data model

### **SQL Functions Created:**

1. ✅ `get_user_entry_count()` - Counts entries for current user
2. ✅ `get_user_entry_stats()` - Returns detailed statistics

### **Ready to Use:**

```swift
// Simple count
let count = try await SupabaseService.shared.getUserEntryCount()

// Detailed stats
let stats = try await SupabaseService.shared.getUserEntryStats()
print("Total: \(stats.totalEntries)")
print("This week: \(stats.entriesThisWeek)")
```

---

**Date:** October 16, 2025
**Status:** ✅ Implemented and ready to use
**Files Modified:** SupabaseService.swift
**New Methods:** 2
**New Models:** 1
