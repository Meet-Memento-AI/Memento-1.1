//
//  TopNavHeader.swift
//  MeetMemento
//
//  Custom floating header with hamburger menu, top nav pills, and context-aware action button.
//  Replaces the native toolbar for the top-level navigation when using TopTabNavContainer.
//

import SwiftUI

public struct TopNavHeader: View {
    @Binding var selection: JournalTopTab
    var onMenuTapped: () -> Void
    var onActionTapped: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(
        selection: Binding<JournalTopTab>,
        onMenuTapped: @escaping () -> Void,
        onActionTapped: @escaping () -> Void
    ) {
        self._selection = selection
        self.onMenuTapped = onMenuTapped
        self.onActionTapped = onActionTapped
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Hamburger menu (placeholder for future features)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onMenuTapped()
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.foreground)
                    .frame(width: 44, height: 44)
                    .background(iconButtonBackground)
            }
            .accessibilityLabel("Menu")

            Spacer()

            // Center pills (synced with swipe gestures)
            TopNav(variant: .tabs, selection: $selection)

            Spacer()

            // Right action (context-aware: search for Journal, write entry for Insights)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onActionTapped()
            }) {
                Image(systemName: selection == .yourEntries ? "magnifyingglass" : "square.and.pencil")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.foreground)
                    .frame(width: 44, height: 44)
                    .contentTransition(.symbolEffect(.replace))
                    .background(iconButtonBackground)
            }
            .accessibilityLabel(selection == .yourEntries ? "Search" : "New Entry")
            .animation(.smooth(duration: 0.3), value: selection)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Icon Button Background
    @ViewBuilder
    private var iconButtonBackground: some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Liquid glass with interactive feedback
            Circle()
                .fill(Color.clear)
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            // iOS 18+: Ultra thin material fallback
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Previews

#Preview("TopNavHeader - Journal Tab") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        VStack {
            TopNavHeader(
                selection: .constant(.yourEntries),
                onMenuTapped: { print("Menu tapped") },
                onActionTapped: { print("Search tapped") }
            )
            .padding(.top, 60)

            Spacer()
        }
    }
    .environment(\.theme, Theme.light)
    .environment(\.typography, Typography())
}

#Preview("TopNavHeader - Insights Tab") {
    ZStack {
        Color.purple.opacity(0.3).ignoresSafeArea()

        VStack {
            TopNavHeader(
                selection: .constant(.digDeeper),
                onMenuTapped: { print("Menu tapped") },
                onActionTapped: { print("New Entry tapped") }
            )
            .padding(.top, 60)

            Spacer()
        }
    }
    .environment(\.theme, Theme.light)
    .environment(\.typography, Typography())
}
