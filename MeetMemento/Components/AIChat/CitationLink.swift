//
//  CitationLink.swift
//  MeetMemento
//
//  Citation link button styled as a tag for AI chat responses
//

import SwiftUI

public struct CitationLink: View {
    let count: Int
    var onTap: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(
        count: Int,
        onTap: (() -> Void)? = nil
    ) {
        self.count = count
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 6) {
                Text("Reviewed \(count) journal\(count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .semibold))
                    .fontWeight(.semibold)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Single Citation") {
    CitationLink(count: 1) {
        print("Citation tapped")
    }
    .useTheme()
    .useTypography()
}

#Preview("Multiple Citations") {
    CitationLink(count: 5) {
        print("Citations tapped")
    }
    .useTheme()
    .useTypography()
}

#Preview("Many Citations") {
    CitationLink(count: 12) {
        print("Citations tapped")
    }
    .useTheme()
    .useTypography()
}
