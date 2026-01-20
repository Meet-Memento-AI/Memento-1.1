//
//  BottomNavigation.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 12/15/24.
//

import SwiftUI

// MARK: - Bottom Navigation Component
/// A fixed bottom navigation component with FAB button
/// - Positioned at the bottom right with proper padding
/// - Handles journal entry creation
public struct BottomNavigation: View {

    // MARK: - Properties
    public let onJournalCreate: () -> Void
    public let isDisabled: Bool

    @Environment(\.theme) private var theme

    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 32

    // MARK: - Initializer
    public init(
        onJournalCreate: @escaping () -> Void,
        isDisabled: Bool = false
    ) {
        self.onJournalCreate = onJournalCreate
        self.isDisabled = isDisabled
    }

    // MARK: - Body
    public var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                // FAB - 16px from right, 32px from bottom
                IconButton(systemImage: "plus") {
                    onJournalCreate()
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
                .padding(.trailing, horizontalPadding)
                .accessibilityLabel("Create new journal entry")
            }
            .padding(.bottom, bottomPadding)
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Previews
#Preview("Bottom Navigation • Light") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        BottomNavigation(
            onJournalCreate: {
                print("Create journal entry tapped")
            }
        )
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Bottom Navigation • Dark") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        BottomNavigation(
            onJournalCreate: {
                print("Create journal entry tapped")
            }
        )
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
