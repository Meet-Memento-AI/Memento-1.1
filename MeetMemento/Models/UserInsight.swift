
import Foundation

/// Represents a user insight from the `user_insights` table.
/// Note: This captures generated insights like "weekly_recap" or "theme_summary".
public struct UserInsight: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public var insightType: String // e.g., 'theme_summary', 'monthly_insights'
    public var content: [String: AnyCodable] // JSONB content, using flexible dictionary wrapper
    public var entriesAnalyzedCount: Int
    public var dateRangeStart: Date?
    public var dateRangeEnd: Date?
    public var isValid: Bool
    public var expiresAt: Date?
    public let generatedAt: Date
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case insightType = "insight_type"
        case content
        case entriesAnalyzedCount = "entries_analyzed_count"
        case dateRangeStart = "date_range_start"
        case dateRangeEnd = "date_range_end"
        case isValid = "is_valid"
        case expiresAt = "expires_at"
        case generatedAt = "generated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        insightType: String,
        content: [String: AnyCodable],
        entriesAnalyzedCount: Int,
        dateRangeStart: Date? = nil,
        dateRangeEnd: Date? = nil,
        isValid: Bool = true,
        expiresAt: Date? = nil,
        generatedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.insightType = insightType
        self.content = content
        self.entriesAnalyzedCount = entriesAnalyzedCount
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.isValid = isValid
        self.expiresAt = expiresAt
        self.generatedAt = generatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var structuredContent: InsightContent? {
        guard let data = try? JSONEncoder().encode(content),
              let decoded = try? JSONDecoder().decode(InsightContent.self, from: data) else {
            return nil
        }
        return decoded
    }
}

/// Strongly typed content for the JSONB payload
/// Maps API field names to Swift property names via CodingKeys
public struct InsightContent: Codable, Hashable {
    public let headline: String           // API: "summary"
    public let observation: String        // API: "description"
    public let observationExtended: String? // API: "descriptionExtended"
    public let themes: [String]?
    public let suggestions: [String]?
    public let sentiment: [InsightSentiment]? // API: "sentiments"
    public let keywords: [String]?
    public let questions: [String]?

    enum CodingKeys: String, CodingKey {
        case headline = "summary"
        case observation = "description"
        case observationExtended = "descriptionExtended"
        case themes
        case suggestions
        case sentiment = "sentiments"
        case keywords
        case questions
    }

    public init(
        headline: String,
        observation: String,
        observationExtended: String? = nil,
        themes: [String]? = nil,
        suggestions: [String]? = nil,
        sentiment: [InsightSentiment]? = nil,
        keywords: [String]? = nil,
        questions: [String]? = nil
    ) {
        self.headline = headline
        self.observation = observation
        self.observationExtended = observationExtended
        self.themes = themes
        self.suggestions = suggestions
        self.sentiment = sentiment
        self.keywords = keywords
        self.questions = questions
    }
}

public struct InsightSentiment: Codable, Hashable {
    public let label: String
    public let score: Int // 0-100 or relative weight
    
    public init(label: String, score: Int) {
        self.label = label
        self.score = score
    }
}

// MARK: - Helper for JSONB
// Simple wrapper to allow decoding mixed JSON types
public struct AnyCodable: Codable, Hashable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x }
        else if let x = try? container.decode([AnyCodable].self) { value = x }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded") }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let x as String: try container.encode(x)
        case let x as Int: try container.encode(x)
        case let x as Double: try container.encode(x)
        case let x as Bool: try container.encode(x)
        case let x as [String: AnyCodable]: try container.encode(x)
        case let x as [AnyCodable]: try container.encode(x)
        default: throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Hashable/Equatable conformance is approximate for 'Any' content
        return String(describing: lhs.value) == String(describing: rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}

// MARK: - Mocks
extension UserInsight {
    public static let mock = UserInsight(
        userId: UUID(),
        insightType: "weekly_recap",
        content: ["summary": AnyCodable("You wrote a lot about work this week.")],
        entriesAnalyzedCount: 5
    )
}
