//
//  AISuggestionCard.swift
//  MeetMemento
//
//  AI prompt suggestion card inspired by design: rounded card, light purple background,
//  dark purple text, circular arrow button. Uses Theme and Typography tokens only.
//

import SwiftUI

/// A tappable card that displays an AI prompt suggestion with a circular arrow action.
public struct AISuggestionCard: View {
    let suggestion: String
    var onTap: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(suggestion: String, onTap: (() -> Void)? = nil) {
        self.suggestion = suggestion
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(suggestion)
                .font(type.body1Bold)
                .foregroundStyle(theme.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(type.body1Bold)
                    .foregroundStyle(theme.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.primary.opacity(0.2)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(minWidth: 164, maxWidth: 164, minHeight: 180, maxHeight: 200)
        .background(theme.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(suggestion)
        .accessibilityHint("Sends this suggestion to AI")
    }
}

// MARK: - Previews

#Preview("AISuggestionCard") {
    AISuggestionCard(
        suggestion: "What patterns do you see in my recent entries?",
        onTap: { }
    )
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("AISuggestionCard • Long") {
    AISuggestionCard(
        suggestion: "Summarize my week in one sentence and suggest one intention for next week.",
        onTap: { }
    )
    .padding()
    .useTheme()
    .useTypography()
}
