//
//  ViewModifiers.swift
//  MeetMemento
//
//  Created by Claude Code
//  Reusable view modifiers for consistent UI patterns
//

import SwiftUI
import UIKit

// MARK: - Card Styling

extension View {
    /// Apply standard card styling with rounded corners, background, optional border, and shadow
    /// - Parameters:
    ///   - radius: Corner radius (default: 24)
    ///   - border: Whether to show border (default: false)
    ///   - shadow: Whether to show shadow (default: true)
    /// - Returns: Styled view with card appearance
    func cardStyle(radius: CGFloat = 24, border: Bool = false, shadow: Bool = true) -> some View {
        modifier(CardStyleModifier(cornerRadius: radius, showBorder: border, showShadow: shadow))
    }
}

private struct CardStyleModifier: ViewModifier {
    @Environment(\.theme) private var theme

    let cornerRadius: CGFloat
    let showBorder: Bool
    let showShadow: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.cardBackground)
            )
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    }
                }
            )
            .shadow(
                radius: showShadow ? 8 : 0,
                x: 0,
                y: showShadow ? 4 : 0
            )
    }
}

// MARK: - Press Effects

extension View {
    /// Apply press/scale animation effect
    /// - Parameters:
    ///   - isPressed: Binding to pressed state
    ///   - scale: Scale factor when pressed (default: 0.98)
    ///   - duration: Animation duration (default: Spacing.Duration.fast)
    /// - Returns: View with press animation
    func pressEffect(isPressed: Binding<Bool>, scale: CGFloat = 0.98, duration: CGFloat = Spacing.Duration.fast) -> some View {
        modifier(PressEffectModifier(isPressed: isPressed, scale: scale, duration: duration))
    }
}

private struct PressEffectModifier: ViewModifier {
    @Binding var isPressed: Bool
    let scale: CGFloat
    let duration: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: duration), value: isPressed)
    }
}

// MARK: - Haptic Feedback

extension View {
    /// Add haptic feedback to tap gesture
    /// - Parameters:
    ///   - style: Haptic feedback style (default: .light)
    ///   - action: Action to perform on tap
    /// - Returns: View with haptic tap gesture
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, action: @escaping () -> Void) -> some View {
        modifier(HapticTapModifier(style: style, action: action))
    }
}

private struct HapticTapModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.impactOccurred()
                action()
            }
    }
}

// MARK: - Spacing Shortcuts

extension View {
    /// Apply horizontal padding using semantic spacing
    /// - Parameter value: Spacing value (default: Spacing.md)
    /// - Returns: View with horizontal padding
    func hPadding(_ value: CGFloat = Spacing.md) -> some View {
        padding(.horizontal, value)
    }

    /// Apply vertical padding using semantic spacing
    /// - Parameter value: Spacing value (default: Spacing.md)
    /// - Returns: View with vertical padding
    func vPadding(_ value: CGFloat = Spacing.md) -> some View {
        padding(.vertical, value)
    }
}
