
import Foundation

/// Represents a journal entry in the `journal_entries` table.
/// This is the rich entry model containing sentiment, word counts, and soft-delete flags.
public struct JournalEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public var title: String
    public var content: String
    public var wordCount: Int?
    public var sentimentScore: Double? // numeric
    public var isDeleted: Bool
    public var deletedAt: Date?
    public var contentHash: String?
    public let createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case wordCount = "word_count"
        case sentimentScore = "sentiment_score"
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
        case contentHash = "content_hash"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String,
        wordCount: Int? = nil,
        sentimentScore: Double? = nil,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        contentHash: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.wordCount = wordCount
        self.sentimentScore = sentimentScore
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mocks
extension JournalEntry {
    public static let mock = JournalEntry(
        userId: UUID(),
        title: "A Day to Remember",
        content: "Today was absolutely wonderful. I felt so productive and calm.",
        wordCount: 12,
        sentimentScore: 0.85,
        isDeleted: false
    )
}
