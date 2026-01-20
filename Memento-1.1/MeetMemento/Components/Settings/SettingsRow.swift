//
//  SettingsRow.swift
//  MeetMemento
//
//  Reusable settings row component with icon, title, subtitle, and optional chevron.
//

import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let isDestructive: Bool
    let showProgress: Bool
    let action: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false,
        isDestructive: Bool = false,
        showProgress: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.isDestructive = isDestructive
        self.showProgress = showProgress
        self.action = action
    }

    var body: some View {
        // Only wrap in Button if there's an action (not when used with NavigationLink)
        if let action = action {
            Button {
                action()
            } label: {
                rowContent
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(showProgress)
        } else {
            // No button wrapper - used when wrapped in NavigationLink
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isDestructive ? theme.destructive : theme.primary)
                .frame(width: 28, height: 28)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDestructive ? theme.destructive : theme.foreground)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.mutedForeground)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Trailing element
            if showProgress {
                ProgressView()
                    .tint(theme.primary)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.foreground.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

#Preview("Settings Row") {
    VStack(spacing: 0) {
        SettingsRow(
            icon: "person.circle.fill",
            title: "Profile",
            subtitle: "Edit your name and info",
            showChevron: true,
            action: {}
        )

        Divider()

        SettingsRow(
            icon: "paintbrush.fill",
            title: "Appearance",
            subtitle: "Theme and display settings",
            showChevron: true,
            action: {}
        )

        Divider()

        SettingsRow(
            icon: "trash.fill",
            title: "Delete Account",
            subtitle: "Permanently delete all data",
            isDestructive: true,
            action: {}
        )
    }
    .background(Color(hex: "#FFFFFF"))
    .cornerRadius(12)
    .padding()
    .useTheme()
    .useTypography()
}
