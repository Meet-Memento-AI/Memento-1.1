//
//  AppleSignInButton.swift
//  MeetMemento
//
//  Styled to align with Sign in with Apple HIG.
//  Ref: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
//

import SwiftUI

public struct AppleSignInButton: View {
    public enum Style { case black, white, whiteOutline }

    let title: String
    let style: Style
    var action: () -> Void

    public init(title: String = "Sign in with Apple", style: Style = .black, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(foreground)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(foreground)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(border, lineWidth: style == .whiteOutline ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch style {
        case .black: return .black
        case .white: return .white
        case .whiteOutline: return .white
        }
    }
    private var foreground: Color {
        switch style {
        case .black: return .white
        case .white, .whiteOutline: return .black
        }
    }
    private var border: Color {
        switch style {
        case .black, .white: return .clear
        case .whiteOutline: return Color(.separator)
        }
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        AppleSignInButton(style: .black) {}
        AppleSignInButton(style: .white) {}
        AppleSignInButton(style: .whiteOutline) {}
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 12) {
        AppleSignInButton(style: .black) {}
        AppleSignInButton(style: .white) {}
        AppleSignInButton(style: .whiteOutline) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}


