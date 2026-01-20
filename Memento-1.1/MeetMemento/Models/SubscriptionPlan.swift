
import Foundation

/// Represents a subscription plan from the `subscription_plans` table.
public struct SubscriptionPlan: Identifiable, Codable, Hashable {
    public let id: String // e.g. "pro_monthly"
    public var name: String
    public var description: String?
    public var price: Decimal?
    public var dailyEntryLimit: Int?
    public var dailyAIInsightLimit: Int?
    public var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price = "price_usd"
        case dailyEntryLimit = "daily_entry_limit"
        case dailyAIInsightLimit = "daily_ai_insight_limit"
        case isActive = "is_active"
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        price: Decimal? = nil,
        dailyEntryLimit: Int? = nil,
        dailyAIInsightLimit: Int? = 3,
        isActive: Bool? = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.dailyEntryLimit = dailyEntryLimit
        self.dailyAIInsightLimit = dailyAIInsightLimit
        self.isActive = isActive
    }
}

// MARK: - Mocks
extension SubscriptionPlan {
    public static let mock = SubscriptionPlan(
        id: "pro_monthly",
        name: "Pro Monthly",
        description: "Unlock all features",
        price: 9.99,
        dailyEntryLimit: nil,
        dailyAIInsightLimit: 10
    )
}
