
import Foundation

/// Represents a follow-up question from the `followup_questions` table.
public struct FollowupQuestion: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let insightId: UUID
    public var text: String
    public var orderIndex: Int
    public var isAnswered: Bool
    public var answeredEntryId: UUID?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case insightId = "insight_id"
        case text
        case orderIndex = "order_index"
        case isAnswered = "is_answered"
        case answeredEntryId = "answered_entry_id"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        insightId: UUID,
        text: String,
        orderIndex: Int = 0,
        isAnswered: Bool = false,
        answeredEntryId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.insightId = insightId
        self.text = text
        self.orderIndex = orderIndex
        self.isAnswered = isAnswered
        self.answeredEntryId = answeredEntryId
        self.createdAt = createdAt
    }
}

// MARK: - Mocks
extension FollowupQuestion {
    public static let mock = FollowupQuestion(
        userId: UUID(),
        insightId: UUID(),
        text: "How did that make you feel?",
        orderIndex: 0
    )
}
