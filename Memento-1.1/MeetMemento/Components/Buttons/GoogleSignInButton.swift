import SwiftUI

/// Google-branded Sign in with Google button (merged + robust)
/// - Uses official "G" glyph on the left (asset name: `google_g_logo`)
/// - Height: 56px for consistent button sizing
/// - Light (white) and Dark (black) variants
/// - Pressed/hover overlays, disabled styling, centered label
public struct GoogleSignInButton: View {
    public enum Scheme { case light, dark }

    // MARK: – Public API
    public let title: String
    public var scheme: Scheme = .light
    public var isEnabled: Bool = true
    public var action: () -> Void

    // MARK: – Internal state
    @State private var isHovered: Bool = false

    // MARK: – Sizing & spacing
    private let height: CGFloat = 56
    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 1
    private let iconSize: CGFloat = 20
    private let horizontalPadding: CGFloat = 12
    private let labelFontSize: CGFloat = 16 // Google spec uses 14 in the 40pt HTML; 16 is fine on iOS
    private let labelWeight: Font.Weight = .medium

    // MARK: – Colors (from Google specs / your CSS)
    private var backgroundColor: Color {
        switch scheme {
        case .light: return .white
        case .dark:  return .black
        }
    }
    private var textColor: Color {
        switch scheme {
        case .light: return Color(hex: "#3C4043") // Google text gray
        case .dark:  return .white
        }
    }
    private var borderColor: Color {
        switch scheme {
        case .light: return Color(hex: "#DADCE0")
        case .dark:  return .clear
        }
    }
    // Overlays
    private var hoverOverlay: Color {
        switch scheme {
        case .light: return Color.black.opacity(0.08) // 8%
        case .dark:  return Color.white.opacity(0.10) // close to 8–12% for dark
        }
    }
    private var pressedOverlay: Color {
        switch scheme {
        case .light: return Color.black.opacity(0.12) // 12%
        case .dark:  return Color.white.opacity(0.12) // 12%
        }
    }
    // Disabled
    private var disabledBackground: Color {
        switch scheme {
        case .light: return Color.white.opacity(0.38) // #ffffff61 (~38%)
        case .dark:  return Color.black.opacity(0.38)
        }
    }
    private var disabledBorder: Color {
        // #1f1f1f1f (~12% opacity) for light; transparent for dark
        switch scheme {
        case .light: return Color(hex: "#1F1F1F").opacity(0.12)
        case .dark:  return .clear
        }
    }
    private var disabledTextOpacity: Double { 0.38 }

    // MARK: – Init
    public init(title: String = "Sign in with Google",
                scheme: Scheme = .light,
                isEnabled: Bool = true,
                action: @escaping () -> Void) {
        self.title = title
        self.scheme = scheme
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: – Body
    public var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            ZStack {
                // Content wrapper – keep text visually centered with left icon
                HStack(spacing: 12) {
                    Image("GoogleIcon")
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.system(size: labelFontSize, weight: labelWeight))
                        .foregroundStyle(isEnabled ? textColor : textColor.opacity(disabledTextOpacity))
                        .lineLimit(1)
                        .truncationMode(.tail)

                }
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: 400) // CSS had max-width: 400px
                .frame(height: height)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(MergedGoogleStyle(
            height: height,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderColor: borderColor,
            hoverOverlay: hoverOverlay,
            pressedOverlay: pressedOverlay,
            disabledBackground: disabledBackground,
            disabledBorder: disabledBorder,
            isEnabled: isEnabled,
            isHovered: isHovered
        ))
        .onHover { hovering in
            // iPhone ignores; iPad trackpad & macCatalyst will use this
            withAnimation(.easeInOut(duration: 0.18)) { isHovered = hovering }
        }
        .disabled(!isEnabled)
        .accessibilityLabel(Text(title))
    }
}

// MARK: – ButtonStyle (hover/pressed/disabled states + shadow on hover for light)
private struct MergedGoogleStyle: ButtonStyle {
    let height: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color

    let hoverOverlay: Color
    let pressedOverlay: Color

    let disabledBackground: Color
    let disabledBorder: Color

    let isEnabled: Bool
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    (isEnabled ? backgroundColor : disabledBackground)
                    if isEnabled {
                        if configuration.isPressed {
                            pressedOverlay.transition(.opacity)
                        } else if isHovered {
                            hoverOverlay.transition(.opacity)
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isEnabled ? borderColor : disabledBorder, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: isEnabled && isHovered ? Color(red: 60/255, green: 64/255, blue: 67/255).opacity(0.30) : .clear,
                    radius: isEnabled && isHovered ? 3 : 0, x: 0, y: 1)
            .overlay(
                Group {
                    if isEnabled && isHovered {
                        // Secondary hover shadow (approx of 0 1px 3px 1px rgba(60,64,67,.15))
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.clear)
                            .shadow(color: Color(red: 60/255, green: 64/255, blue: 67/255).opacity(0.15),
                                    radius: 3, x: 0, y: 1)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            )
            .frame(height: height)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.18), value: isHovered)
    }
}

// Hex helper exists globally in Theme. Removed local redeclaration to avoid collision.

// MARK: – Previews
#Preview("Light") {
    VStack(spacing: 16) {
        GoogleSignInButton(title: "Sign in with Google") { }
        GoogleSignInButton(title: "Sign in with Google", isEnabled: false) { }
    }
    .padding()
    .background(Color(white: 0.96))
}

#Preview("Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            GoogleSignInButton(title: "Sign in with Google", scheme: .dark) { }
            GoogleSignInButton(title: "Sign in with Google", scheme: .dark, isEnabled: false) { }
        }
        .padding()
    }
}
