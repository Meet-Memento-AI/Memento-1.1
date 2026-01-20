import SwiftUI

/// A tiny, self-contained UI component with **pure inputs** so it can preview instantly
/// without booting your app, networking, or hitting storage.
struct JournalCard: View {
    // MARK: - Inputs (pure data only)
    let title: String
    let excerpt: String
    let date: Date

    /// Optional actions (no-op by default so previews never depend on app state)
    var onTap: (() -> Void)? = nil
    var onEditTapped: (() -> Void)? = nil
    var onDeleteTapped: (() -> Void)? = nil
    
    // MARK: - Environment
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
     
    // MARK: - State
    @State private var isPressed = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                header

                Text(excerpt)
                    .font(type.bodySmall)
                    .foregroundStyle(theme.mutedForeground)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                footer
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.cardBackground)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            // Add haptic feedback for better user experience
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .contextMenu {
            Button(action: { onEditTapped?() }) {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive, action: { onDeleteTapped?() }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews
    private var header: some View {
        Text(title)
            .font(type.h4) // Recoleta heading font for prominence
            .foregroundStyle(theme.foreground)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .imageScale(.small)
                .foregroundStyle(theme.mutedForeground)
            Text(formattedDate)
                .font(type.bodySmall)
                .foregroundStyle(theme.mutedForeground)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Journal entry date \(formattedDate)")
    }

    // MARK: - Date Formatting
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        // Add ordinal suffix (st, nd, rd, th)
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }

        let year = Calendar.current.component(.year, from: date)
        let month = formatter.string(from: date)

        return "\(month)\(suffix), \(year)"
    }

    private var accessibilityLabel: String {
        "Journal card, \(title). Dated \(formattedDate). \(excerpt)"
    }
}

// MARK: - Sample Data (for previews & local playgrounds)
extension JournalCard {
    static let sampleTitle = "Morning Reflection"
    static let sampleExcerpt = "I woke up feeling a bit groggy and not entirely refreshed. The alarm felt a bit harsh, and I struggled to get out of bed. Once I did, I noticed that the sky .."
}

// MARK: - SIDE-CAR PREVIEW HARNESS
// Keep previews in the same file for convenience, or move into `JournalCard+Preview.swift`.
// Import NOTHING from your app target here besides SwiftUI and this view file.
private struct JournalCardHarness: View {
    // Create Oct 3rd, 2025 date for preview
    private var previewDate: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 3
        return Calendar.current.date(from: components) ?? .now
    }

    var body: some View {
        JournalCard(
            title: JournalCard.sampleTitle,
            excerpt: JournalCard.sampleExcerpt,
            date: previewDate,
            onTap: { /* no-op for harness */ },
            onEditTapped: { /* no-op for harness */ },
            onDeleteTapped: { /* no-op for harness */ }
        )
        .previewLayout(.sizeThatFits)
        .frame(maxWidth: .infinity) // allow card to stretch
        .background(Color(uiColor: .systemBackground))
        .useTheme()
        .useTypography()
    }
}



#Preview("JournalCard · light") {
    JournalCardHarness()
}


#Preview("JournalCard · long text") {
    JournalCard(
        title: "Weekly review and planning checklist for Q4",
        excerpt: "What went well: shipped UI preview harnesses, stabilized Xcode canvas. What to improve: fewer side effects in initializers, mock services end-to-end. Next: connect Supabase after UI is final.",
        date: .now.addingTimeInterval(-36_00)
    )
    //.previewLayout(.sizeThatFits)
    .padding()
}
