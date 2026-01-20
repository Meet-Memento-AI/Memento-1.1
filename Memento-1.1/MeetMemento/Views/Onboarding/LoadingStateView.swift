//
//  LoadingStateView.swift
//  MeetMemento
//
//  Onboarding completion loading screen with animation
//

import SwiftUI

public struct LoadingStateView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var showProgress = false
    @State private var loadingPhase: LoadingPhase = .initial
    @State private var currentTipIndex = 0
    @State private var showTip = false

    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Modern gradient background
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Modern loading indicator
                if showProgress {
                    VStack(spacing: 24) {
                        // Animated progress ring
                        ModernProgressRing()
                            .frame(width: 48, height: 48)
                            .padding(.top, 40)

                        // Status message with modern styling
                        Text(loadingPhase.message)
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .id(loadingPhase)
                    }
                    .transition(.opacity)
                }

                Spacer()
                Spacer()

                // Modern tip card
                if showTip {
                    TipCard(
                        icon: loadingTips[currentTipIndex].icon,
                        title: loadingTips[currentTipIndex].title,
                        message: loadingTips[currentTipIndex].message
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(currentTipIndex)
                }
            }
        }
        .accessibilityLabel("Loading MeetMemento. \(loadingPhase.message)")
        .onAppear {
            startLoadingSequence()
        }
    }

    // MARK: - Loading Sequence

    private func startLoadingSequence() {
        if reduceMotion {
            // Show everything immediately for reduced motion
            showProgress = true
            startProgressiveLoading()
        } else {
            // Modern fluid entrance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.4)) {
                    showProgress = true
                }
                startProgressiveLoading()
            }
        }

        // Show tips after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTip = true
            }
            startTipRotation()
        }

        // Complete after content loads (simulated with 5 second delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            onComplete?()
        }
    }

    private func startProgressiveLoading() {
        // Phase 1: Preparing space (0-2s)
        loadingPhase = .authenticating

        // Phase 2: Loading data (2-4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                loadingPhase = .loadingData
            }
        }

        // Phase 3: Almost ready (4s+)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation {
                loadingPhase = .finalizing
            }
        }
    }

    private func startTipRotation() {
        // Rotate tips every 6 seconds with smooth transition
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                currentTipIndex = (currentTipIndex + 1) % loadingTips.count
            }
        }
    }
}

// MARK: - Modern Progress Ring

private struct ModernProgressRing: View {
    @Environment(\.theme) private var theme
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Subtle background ring
            Circle()
                .stroke(theme.border.opacity(0.3), lineWidth: 2.5)

            // Animated gradient arc
            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: theme.primary, location: 0.0),
                            .init(color: theme.accent, location: 0.5),
                            .init(color: theme.primary.opacity(0.3), location: 1.0)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))
                .animation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: rotation
                )
        }
        .onAppear {
            rotation = 360
        }
    }
}

// MARK: - Modern Tip Card

private struct TipCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.primary)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(type.bodyBold)
                    .foregroundStyle(theme.foreground)

                Text(message)
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.card)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

// MARK: - Loading Phases

private enum LoadingPhase {
    case initial
    case authenticating
    case loadingData
    case finalizing

    var message: String {
        switch self {
        case .initial:
            return ""
        case .authenticating:
            return "Preparing your space..."
        case .loadingData:
            return "Loading your memories..."
        case .finalizing:
            return "Almost there..."
        }
    }
}

// MARK: - Loading Tips

private struct LoadingTip {
    let icon: String
    let title: String
    let message: String
}

private let loadingTips = [
    LoadingTip(
        icon: "heart.fill",
        title: "Daily practice",
        message: "Journaling for just 5 minutes a day can improve mental clarity and reduce stress."
    ),
    LoadingTip(
        icon: "wind",
        title: "Breathe mindfully",
        message: "Take three slow, deep breaths. Notice how your body feels right now."
    ),
    LoadingTip(
        icon: "brain.head.profile",
        title: "Spot patterns",
        message: "Regular reflection helps you understand recurring thoughts and behaviors."
    ),
    LoadingTip(
        icon: "target",
        title: "Set intentions",
        message: "Writing down your goals makes you 42% more likely to achieve them."
    ),
    LoadingTip(
        icon: "lock.shield.fill",
        title: "Safe space",
        message: "Your journal is private. Write honestly without judgment or fear."
    ),
    LoadingTip(
        icon: "sparkles",
        title: "Find joy",
        message: "Small moments of mindfulness can transform your entire day."
    )
]

// MARK: - Previews

#Preview("Light") {
    LoadingStateView {
        print("Onboarding complete!")
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoadingStateView {
        print("Onboarding complete!")
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
