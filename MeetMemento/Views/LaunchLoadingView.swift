//
//  LaunchLoadingView.swift
//  MeetMemento
//
//  Minimal loading view displayed during auth initialization.
//  Matches the app's launch screen (white + centered logo) for a seamless transition.
//

import SwiftUI

struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            // White background matching launch screen
            Color.white.ignoresSafeArea()

            // Centered logo matching launch screen dimensions
            Image("Memento-Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240, height: 128)
        }
    }
}

#Preview("Light") {
    LaunchLoadingView()
}

#Preview("Dark") {
    LaunchLoadingView()
}
