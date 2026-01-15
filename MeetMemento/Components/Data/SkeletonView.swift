import SwiftUI

public struct SkeletonView: View {
    @State private var isAnimating = false
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    public init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    @State private var phase = 0.0

    public var body: some View {
        ZStack {
            // Base layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.05))
            
            // Breathing wave layer
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.08))
                .opacity(0.3 + 0.7 * (0.5 + 0.5 * sin(phase)))
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                phase = .pi
            }
        }
    }
}

public extension View {
    @ViewBuilder
    func skeleton(if condition: Bool, width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 8) -> some View {
        if condition {
            SkeletonView(width: width, height: height ?? 20, cornerRadius: cornerRadius)
        } else {
            self
        }
    }
}
