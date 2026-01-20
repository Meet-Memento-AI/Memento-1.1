//
//  IconButton.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 9/30/25.
//

import SwiftUI

public struct IconButton: View {
    @Environment(\.theme) private var theme
    let systemImage: String
    var size: CGFloat = 64
    var action: () -> Void

    public init(systemImage: String, size: CGFloat = 64, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.45, height: size * 0.45) // balanced icon size
                .foregroundStyle(Color.white)                  // icon stays white
                .padding(size * 0.25)                          // breathing room inside FAB
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())                           // true circular FAB
                .shadow(color: theme.primary.opacity(0.3), radius: 6, x: 0, y: 4) // subtle FAB shadow
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    HStack(spacing: 16) {
        IconButton(systemImage: "mic.fill") {}
        IconButton(systemImage: "plus") {}
    }
    .padding()
    .useTheme()
}

#Preview("Dark") {
    HStack(spacing: 16) {
        IconButton(systemImage: "mic.fill") {}
        IconButton(systemImage: "plus") {}
    }
    .padding()
    .useTheme()
    .preferredColorScheme(.dark)
}
