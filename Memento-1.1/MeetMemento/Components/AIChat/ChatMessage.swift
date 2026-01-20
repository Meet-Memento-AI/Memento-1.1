//
//  ChatMessage.swift
//  MeetMemento
//
//  Data model for chat messages in AI Chat interface
//

import Foundation

/// Citation reference to a journal entry (for future use)
public struct JournalCitation: Identifiable, Hashable, Codable {
    public let id: UUID
    public let entryId: UUID
    public let entryTitle: String
    public let entryDate: Date
    public let excerpt: String
    
    public init(
        id: UUID = UUID(),
        entryId: UUID,
        entryTitle: String,
        entryDate: Date,
        excerpt: String
    ) {
        self.id = id
        self.entryId = entryId
        self.entryTitle = entryTitle
        self.entryDate = entryDate
        self.excerpt = excerpt
    }
}

/// Chat message model for AI Chat interface
public struct ChatMessage: Identifiable, Hashable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let citations: [JournalCitation]?
    
    // Structured content for AI messages (optional)
    public let aiOutputContent: AIOutputContent?
    
    public init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        citations: [JournalCitation]? = nil,
        aiOutputContent: AIOutputContent? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.citations = citations
        self.aiOutputContent = aiOutputContent
    }
    
    // Convenience initializer for AI messages with structured content
    public static func aiMessage(
        id: UUID = UUID(),
        heading1: String? = nil,
        heading2: String? = nil,
        body: String,
        citations: [JournalCitation]? = nil,
        timestamp: Date = Date()
    ) -> ChatMessage {
        let outputContent = AIOutputContent(
            heading1: heading1,
            heading2: heading2,
            body: body,
            citations: citations
        )
        return ChatMessage(
            id: id,
            content: body, // Keep content for backwards compatibility
            isFromUser: false,
            timestamp: timestamp,
            citations: citations,
            aiOutputContent: outputContent
        )
    }
}
