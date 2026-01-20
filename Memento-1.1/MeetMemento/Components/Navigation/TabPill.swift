//
//  BottomTab.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/1/25.
//

import SwiftUI

/// A single tab with icon + label that can render selected/unselected states.
public struct TabPill: View {
    public let title: String
    public let systemImage: String
    public let isSelected: Bool
    public var onTap: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(
        title: String,
        systemImage: String,
        isSelected: Bool,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? theme.accent : theme.foreground)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : theme.foreground)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.round))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("TabPill • Light") {
    HStack(spacing: 16) {
        TabPill(title: "Journal", systemImage: "book.closed.fill", isSelected: true)
        TabPill(title: "Insights", systemImage: "sparkles", isSelected: false)
    }
    .padding()
    .background(Theme.light.background)
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("TabPill • Dark") {
    VStack(spacing: 16) {
        TabPill(title: "Journal", systemImage: "book.closed.fill", isSelected: false)
        TabPill(title: "Insights", systemImage: "sparkles", isSelected: true)
    }
    .padding()
    .background(Theme.dark.background)
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
