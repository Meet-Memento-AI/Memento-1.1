//
//  ChatEmptyState.swift
//  MeetMemento
//
//  Empty state component for AI Chat interface
//

import SwiftUI

public struct ChatEmptyState: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Memento Logo from Assets
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            // Heading
            Text("What's on your mind?")
                .font(type.h3)
                .foregroundStyle(GrayScale.gray900)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Empty State") {
    ChatEmptyState()
        .padding()
        .useTheme()
        .useTypography()
        .background(Color.gray.opacity(0.1))
}

#Preview("Empty State • Dark") {
    ChatEmptyState()
        .padding()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
        .background(Color.gray.opacity(0.1))
}
