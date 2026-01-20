
import Foundation

/// Represents a theme from the `themes` table.
/// Renamed to JournalTheme to avoid conflict with UI Theme struct.
public struct JournalTheme: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var title: String
    public var summary: String
    public var keywords: [String]
    public var emoji: String
    public var category: String
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case summary
        case keywords
        case emoji
        case category
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        name: String,
        title: String,
        summary: String,
        keywords: [String],
        emoji: String,
        category: String,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.summary = summary
        self.keywords = keywords
        self.emoji = emoji
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - Mocks
extension JournalTheme {
    public static let mock = JournalTheme(
        name: "anxiety-worry",
        title: "Anxiety & Worry",
        summary: "Exploring anxious thoughts.",
        keywords: ["anxious", "fear"],
        emoji: "🌊",
        category: "emotional"
    )
}
