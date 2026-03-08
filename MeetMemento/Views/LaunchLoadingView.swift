//
//  LaunchLoadingView.swift
//  MeetMemento
//
//  Minimal loading view displayed during auth initialization.
//  Matches the app's launch screen for a seamless transition.
//

import SwiftUI

struct LaunchLoadingView: View {
    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 24) {

                // Subtle loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Light") {
    LaunchLoadingView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LaunchLoadingView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
