//
//  ThemeCardFullScreen.swift
//  MeetMemento
//
//  Full-screen swipeable card for displaying mental health themes
//

import SwiftUI

public struct ThemeCardFullScreen: View {
    @Environment(\.theme) private var uiTheme
    @Environment(\.typography) private var type

    let themeData: IdentifiedTheme
    @Binding var isSelected: Bool

    public var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            VStack(spacing: 32) {
                Spacer()

                // Emoji
                Text(themeData.emoji)
                    .font(.system(size: 80))

                // Title
                Text(themeData.title)
                    .font(type.h2)
                    .headerGradient()
                    .multilineTextAlignment(.center)

                // Summary
                Text(themeData.summary)
                    .font(type.body)
                    .foregroundStyle(uiTheme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)

                Spacer()

                // Selection indicator
                if isSelected {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Selected")
                            .font(type.bodyBold)
                    }
                    .foregroundStyle(uiTheme.primary)
                } else {
                    Text("Tap to select")
                        .font(type.bodySmall)
                        .foregroundStyle(uiTheme.mutedForeground.opacity(0.6))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? uiTheme.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                isSelected ? uiTheme.primary : uiTheme.border,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .padding(24)
        }
        .buttonStyle(.plain)
    }
}
