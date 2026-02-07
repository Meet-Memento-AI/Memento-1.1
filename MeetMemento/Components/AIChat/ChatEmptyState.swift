//
//  ChatEmptyState.swift
//  MeetMemento
//
//  Empty state component for AI Chat interface
//

import SwiftUI

public struct ChatEmptyState: View {
    var suggestions: [String]?
    var onSuggestionTap: ((String) -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(suggestions: [String]? = nil, onSuggestionTap: ((String) -> Void)? = nil) {
        self.suggestions = suggestions
        self.onSuggestionTap = onSuggestionTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Memento Logo from Assets
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            // Heading
            Text("Welcome John, let's dive deeper into your journal")
                .font(type.h3)
                .foregroundStyle(theme.foreground)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let suggestions = suggestions, !suggestions.isEmpty, onSuggestionTap != nil {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        AISuggestionCard(suggestion: suggestion) {
                            onSuggestionTap?(suggestion)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)

    }
}

// MARK: - Previews

#Preview("Empty State") {
    ChatEmptyState()
        .padding()
        .useTheme()
        .useTypography()
}

#Preview("Empty State • Dark") {
    ChatEmptyState()
        .padding()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}

#Preview("Empty State • With suggestions") {
    ChatEmptyState(
        suggestions: [
            "What patterns do you see in my recent entries?",
            "Summarize my week in one sentence."
        ],
        onSuggestionTap: { _ in }
    )
    .padding()
    .useTheme()
    .useTypography()
}
