//
//  Entry.swift
//  MeetMemento
//
//  Simple journal entry model for UI boilerplate.
//

import Foundation

public struct Entry: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String = "", text: String = "", createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

// MARK: - UI Helpers

extension Entry {
    public var displayTitle: String {
        title.isEmpty ? "Untitled Entry" : title
    }

    public var excerpt: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "No text" }
        return String(trimmed.prefix(100))
    }
}

// MARK: - Sample Data for Previews

extension Entry {
    public static let sampleEntries: [Entry] = [
        Entry(title: "Morning Thoughts", text: "Today was a productive day..."),
        Entry(title: "Evening Reflection", text: "I learned something new today...")
    ]
}
