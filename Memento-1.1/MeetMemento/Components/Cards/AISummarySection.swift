import SwiftUI

/// AI Summary section for Insights view
/// Displays a title (max 4 lines, Recoleta h3) and body paragraph (max 300 words)
public struct AISummarySection: View {
    public let title: String
    public let bodyText: String

    @Environment(\.typography) private var type

    public init(title: String, body: String) {
        self.title = title
        self.bodyText = body
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with icon
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)

                Text("YOUR AI SUMMARY")
                    .font(type.h6)
                    .foregroundStyle(.white)
            }

            // Main content
            VStack(alignment: .leading, spacing: 24) {
                // Title (max 4 lines, Recoleta h3)
                Text(title)
                    .font(type.h2)
                    .foregroundStyle(.white)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)

                // Body paragraph (max 300 words)
                Text(bodyText)
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Purple gradient background to match Insights view
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#411976"),
                Color(hex: "#57219C")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
            AISummarySection(
                title: "Your emotional landscape reveals a blend of reflection, frustration, and growth.",
                body: "You've been processing heavy emotions around work, identity, and control, yet your tone has steadily shifted toward acceptance and purpose. Despite moments of doubt, there's an emerging sense of trust in your own process. You're beginning to see growth not as a finish line, but as an ongoing practice of alignment and awareness."
            )
            .padding(20)
        }
    }
    .useTheme()
    .useTypography()
}
