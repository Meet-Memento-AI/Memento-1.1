//
//  Spacing.swift
//  MeetMemento
//
//  Created by Claude Code
//  Semantic spacing scale and constants for consistent UI spacing
//

import Foundation
import SwiftUI

/// Semantic spacing scale for consistent padding, margins, and gaps throughout the app
struct Spacing {
    // MARK: - Spacing Scale

    /// Minimal gaps (4pt)
    static let xxs: CGFloat = 4

    /// Tight spacing (8pt)
    static let xs: CGFloat = 8

    /// Compact spacing (12pt)
    static let sm: CGFloat = 12

    /// Standard spacing (16pt) - default for most UI elements
    static let md: CGFloat = 16

    /// Comfortable spacing (20pt)
    static let lg: CGFloat = 20

    /// Spacious (24pt)
    static let xl: CGFloat = 24

    /// Section breaks (32pt)
    static let xxl: CGFloat = 32

    /// Major sections (40pt)
    static let xxxl: CGFloat = 40

    // MARK: - Opacity Constants

    /// Standard opacity values for consistent visual hierarchy
    struct Opacity {
        /// Disabled state (0.6)
        static let disabled: Double = 0.6

        /// Subtle overlays and backgrounds (0.3)
        static let subtle: Double = 0.3

        /// Muted text or UI elements (0.95)
        static let muted: Double = 0.95

        /// Border opacity (0.15)
        static let border: Double = 0.15

        /// Overlay backgrounds (0.2)
        static let overlay: Double = 0.2
    }

    // MARK: - Animation Durations

    /// Standard animation duration constants
    struct Duration {
        /// Fast animations (0.1s) - quick transitions
        static let fast: CGFloat = 0.1

        /// Standard animations (0.15s) - default duration
        static let standard: CGFloat = 0.15

        /// Slow animations (0.3s) - deliberate transitions
        static let slow: CGFloat = 0.3
    }
}
