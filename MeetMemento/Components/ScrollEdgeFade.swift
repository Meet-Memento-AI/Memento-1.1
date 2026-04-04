//
//  ScrollEdgeFade.swift
//  MeetMemento
//
//  A gradient overlay for scroll view edges
//  Fades content at the edge (fully opaque) to ensure header visibility
//

import SwiftUI

struct ScrollEdgeFade: View {
    enum Edge { case top, bottom }

    let edge: Edge
    let height: CGFloat

    @Environment(\.theme) private var theme

    var body: some View {
        LinearGradient(
            stops: edge == .top
                ? [
                    // Harsh top fade: solid behind header (~75%), then sharp visible fade
                    .init(color: theme.background.opacity(1.0), location: 0.0),
                    .init(color: theme.background.opacity(1.0), location: 0.75),
                    .init(color: theme.background.opacity(0.6), location: 0.85),
                    .init(color: theme.background.opacity(0), location: 1.0)
                ]
                : [
                    // Bottom fade: gentle transition for scroll content
                    .init(color: theme.background.opacity(0), location: 0.0),
                    .init(color: theme.background.opacity(0.5), location: 0.4),
                    .init(color: theme.background.opacity(0.85), location: 0.7),
                    .init(color: theme.background.opacity(1.0), location: 1.0)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

#Preview("Top Edge") {
    ZStack {
        Color.blue
        VStack {
            ForEach(0..<10) { i in
                Text("Content Row \(i)")
                    .padding()
                    .background(Color.red.opacity(0.3))
            }
        }
        ScrollEdgeFade(edge: .top, height: 60)
            .frame(maxHeight: .infinity, alignment: .top)
    }
    .useTheme()
}

#Preview("Bottom Edge") {
    ZStack {
        Color.blue
        VStack {
            ForEach(0..<10) { i in
                Text("Content Row \(i)")
                    .padding()
                    .background(Color.red.opacity(0.3))
            }
        }
        ScrollEdgeFade(edge: .bottom, height: 60)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    .useTheme()
}
