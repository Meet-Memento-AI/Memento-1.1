import SwiftUI

public struct InsightCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    let title: String
    let emoji: String
    let text: String
    var footer: String? = nil

    public init(title: String, emoji: String, text: String, footer: String? = nil) {
        self.title = title
        self.emoji = emoji
        self.text = text
        self.footer = footer
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(type.h3)
                    .headerGradient()
                Spacer()
                Text(emoji)
                    .font(type.h3)
            }
            Text(text).bodyText(.init())
                .foregroundStyle(theme.cardForeground)
            if let footer {
                Divider().opacity(0.2)
                Text(footer)
                    .foregroundStyle(theme.mutedForeground)
                    .font(.system(size: type.bodyL))
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.lg)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    InsightCard(
        title: "This Week",
        emoji: "💭",
        text: "Early-week stress followed by calmer evenings. Short walks and social time appear helpful.",
        footer: "Optional nudge: If helpful, schedule a 10-minute break mid-day."
    )
    .padding().useTheme().useTypography()
    .background(Environment(\.theme).wrappedValue.background)
}
