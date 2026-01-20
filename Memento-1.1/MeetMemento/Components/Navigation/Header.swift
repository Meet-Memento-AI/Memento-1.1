//
//  Header.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 12/15/24.
//

import SwiftUI

// MARK: - Header Variant

/// Defines the type of header to display
public enum HeaderVariant {
    /// Primary header with menu button, tab navigation, and AI chat button
    case primary
    /// Secondary header with back button and optional title (for sub-screens like Settings)
    case secondary
}

// MARK: - Header Component

/// A reusable header component supporting multiple variants
/// - Primary: Full navigation with tabs and action buttons (Journal/Insights)
/// - Secondary: Back navigation with optional title (Settings and sub-screens)
public struct Header: View {

    // MARK: - Properties
    private let headerVariant: HeaderVariant

    // Primary variant properties
    private let topNavVariant: TopNavVariant?
    private var selection: Binding<JournalTopTab>?
    private let onSettingsTapped: (() -> Void)?
    private let onAIChatTapped: (() -> Void)?

    // Secondary variant properties
    private let title: String?
    private let showTitle: Bool
    private let onBackTapped: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let topPadding: CGFloat = 12
    private let bottomPadding: CGFloat = 16
    private let spacing: CGFloat = 12

    // MARK: - Primary Initializer

    /// Creates a Primary header with tab navigation and action buttons
    public init(
        variant: TopNavVariant,
        selection: Binding<JournalTopTab>,
        onSettingsTapped: @escaping () -> Void,
        onAIChatTapped: @escaping () -> Void
    ) {
        self.headerVariant = .primary
        self.topNavVariant = variant
        self.selection = selection
        self.onSettingsTapped = onSettingsTapped
        self.onAIChatTapped = onAIChatTapped

        // Secondary properties not used
        self.title = nil
        self.showTitle = false
        self.onBackTapped = nil
    }

    // MARK: - Secondary Initializer

    /// Creates a Secondary header with back button and optional title
    /// - Parameters:
    ///   - title: The title to display (optional)
    ///   - showTitle: Whether to show the title (default: true if title provided)
    ///   - onBackTapped: Action when back button is tapped
    public init(
        title: String? = nil,
        showTitle: Bool = true,
        onBackTapped: @escaping () -> Void
    ) {
        self.headerVariant = .secondary
        self.title = title
        self.showTitle = showTitle && title != nil
        self.onBackTapped = onBackTapped

        // Primary properties not used
        self.topNavVariant = nil
        self.selection = nil
        self.onSettingsTapped = nil
        self.onAIChatTapped = nil
    }

    // MARK: - Body

    public var body: some View {
        switch headerVariant {
        case .primary:
            primaryHeader
        case .secondary:
            secondaryHeader
        }
    }

    // MARK: - Primary Header

    private var primaryHeader: some View {
        HStack(alignment: .center, spacing: spacing) {
            // Menu button (left)
            IconButtonNav(
                icon: "line.3.horizontal",
                iconSize: 20,
                buttonSize: 40,
                foregroundColor: selectionValue == .digDeeper ? .white : theme.foreground,
                useDarkBackground: selectionValue == .digDeeper,
                enableHaptic: true,
                onTap: onSettingsTapped
            )
            .accessibilityLabel("Settings")
            .animation(.easeInOut(duration: 0.35), value: selectionValue)

            Spacer()

            // Top navigation with tabs
            if let variant = topNavVariant, let binding = selection {
                TopNav(variant: variant, selection: binding)
                    .useTheme()
                    .useTypography()
            }

            Spacer()

            // AI Chat button (right)
            IconButtonNav(
                icon: "sparkles",
                iconSize: 22,
                buttonSize: 40,
                foregroundColor: selectionValue == .digDeeper ? .white : theme.foreground,
                useDarkBackground: selectionValue == .digDeeper,
                enableHaptic: true,
                onTap: onAIChatTapped
            )
            .accessibilityLabel("AI Chat")
            .animation(.easeInOut(duration: 0.35), value: selectionValue)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }

    // Helper to safely unwrap selection binding
    private var selectionValue: JournalTopTab {
        selection?.wrappedValue ?? .yourEntries
    }

    // MARK: - Secondary Header


    private var secondaryHeader: some View {
        ZStack(alignment: .top) {
            // Background Layer (Gradient matching Journal implementation)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.background, location: 0),
                    .init(color: theme.background.opacity(0), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .frame(height: 64) // Same height as used in JournalView gradient

            // Foreground Content (Exactly Primary Header structure)
            HStack(alignment: .center, spacing: spacing) {
                // Back Button (replaces Menu button)
                IconButtonNav(
                    icon: "chevron.left",
                    iconSize: 20,
                    buttonSize: 40,
                    foregroundColor: theme.foreground, // Standard foreground (light mode style)
                    useDarkBackground: false,
                    enableHaptic: true,
                    onTap: onBackTapped
                )
                .accessibilityLabel("Back")

                Spacer()

                // Center Title (replaces TopNav tabs) - if desired, kept simple or centered
                if showTitle, let title = title {
                    Text(title)
                        .font(type.bodyBold)
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
                
                // Balance right side (replaces AI Chat button)
                // Use a clear rectangle of same size as IconButtonNav to ensure perfect center alignment
                Color.clear
                    .frame(width: 40, height: 40)
            }
            // Ensure the HStack has a minimum height of 44 to matching Primary's TopNav height (44) if needed for exact pixel match
            // However, Primary's button is 40. TopNav is 44.
            // If we want exact height match to 44, we can pad the secondary header vertically or force frame.
            // But visually, matching the BUTTON alignment is priority.
            // The structure is already correct.
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
    }

}

// MARK: - Previews

#Preview("Header • Primary (Tabs)") {
    @Previewable @State var selectedTab: JournalTopTab = .yourEntries

    VStack {
        Header(
            variant: .tabs,
            selection: $selectedTab,
            onSettingsTapped: { print("Settings tapped") },
            onAIChatTapped: { print("AI Chat tapped") }
        )

        Spacer()
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Header • Primary (Single Selected)") {
    @Previewable @State var selectedTab: JournalTopTab = .yourEntries

    VStack {
        Header(
            variant: .singleSelected,
            selection: $selectedTab,
            onSettingsTapped: { print("Settings tapped") },
            onAIChatTapped: { print("AI Chat tapped") }
        )

        Spacer()
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

#Preview("Header • Secondary (With Title)") {
    VStack {
        Header(
            title: "Settings",
            onBackTapped: { print("Back tapped") }
        )
        .background(Color(UIColor.systemBackground))

        Spacer()
    }
    .useTheme()
    .useTypography()
}

#Preview("Header • Secondary (No Title)") {
    VStack {
        Header(
            title: nil,
            showTitle: false,
            onBackTapped: { print("Back tapped") }
        )
        .background(Color(UIColor.systemBackground))

        Spacer()
    }
    .useTheme()
    .useTypography()
}

#Preview("Header • Secondary (Title Hidden)") {
    VStack {
        Header(
            title: "Settings",
            showTitle: false,
            onBackTapped: { print("Back tapped") }
        )
        .background(Color(UIColor.systemBackground))

        Spacer()
    }
    .useTheme()
    .useTypography()
}
