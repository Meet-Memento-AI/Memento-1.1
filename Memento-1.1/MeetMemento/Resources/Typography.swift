import SwiftUI

// MARK: - Typography
// Supports dynamic font weight control for headings (Recoleta Black / SemiBold)
// and body text (Manrope Regular / Medium / Bold).

public struct Typography {
    // Spec sizes
    public let micro: CGFloat
    public let caption: CGFloat
    public let bodyS: CGFloat
    public let bodyL: CGFloat
    public let titleXS: CGFloat
    public let titleS: CGFloat
    public let titleM: CGFloat
    public let displayL: CGFloat
    public let displayXL: CGFloat

    public let weightNormal: Font.Weight
    public let weightMedium: Font.Weight

    // MARK: - Font family names
    private let headingFontNameBlack = "Recoleta-Black"
    private let headingFontNameSemiBold = "RecoletaAlt-SemiBold"
    private let bodyFontName = "Manrope-Medium"
    private let bodyMediumFontName = "Manrope-Medium"
    private let bodyBoldFontName = "Manrope-Bold"

    // Configurable heading weight
    public let headingWeight: Font.Weight

    public init(
        micro: CGFloat = 11,
        caption: CGFloat = 13,
        bodyS: CGFloat = 14,
        bodyL: CGFloat = 16,
        titleXS: CGFloat = 16,
        titleS: CGFloat = 20,
        titleM: CGFloat = 24,
        displayL: CGFloat = 32,
        displayXL: CGFloat = 40,
        weightNormal: Font.Weight = .regular,
        weightMedium: Font.Weight = .medium,
        headingWeight: Font.Weight = .black // default Recoleta-Black
    ) {
        self.micro = micro
        self.caption = caption
        self.bodyS = bodyS
        self.bodyL = bodyL
        self.titleXS = titleXS
        self.titleS = titleS
        self.titleM = titleM
        self.displayL = displayL
        self.displayXL = displayXL
        self.weightNormal = weightNormal
        self.weightMedium = weightMedium
        self.headingWeight = headingWeight
    }

    // MARK: - Line Spacing
    private func lineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.5) }
    private func headingLineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.2) }

    // Body text specific line height: 14pt font + 6pt spacing = 20pt line height
    public var bodyLineSpacing: CGFloat { 6 }

    // MARK: - Font helpers
    private func headingFont(size: CGFloat) -> Font {
        // Dynamically pick Recoleta Black or SemiBold based on headingWeight
        let name = (headingWeight == .semibold)
            ? headingFontNameSemiBold
            : headingFontNameBlack

        // Don't apply .weight() modifier to custom fonts - the font file itself defines the weight
        return Font.custom(name, size: size, relativeTo: .title)
    }

    private func bodyFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return Font.custom(bodyBoldFontName, size: size, relativeTo: .body)
        case .medium, .semibold:
            return Font.custom(bodyMediumFontName, size: size, relativeTo: .body)
        default:
            return Font.custom(bodyFontName, size: size, relativeTo: .body)
        }
    }

    // MARK: - Semantic Fonts
    public var h1: Font { headingFont(size: displayXL) }
    public var h2: Font { headingFont(size: displayL) }
    public var h3: Font { Font.custom(headingFontNameSemiBold, size: titleM, relativeTo: .title) }
    public var h4: Font { Font.custom(headingFontNameSemiBold, size: titleS, relativeTo: .title) }
    public var h5: Font { headingFont(size: titleXS) }
    public var h6: Font { bodyFont(size: titleXS, weight: .bold) }

    public var body: Font { bodyFont(size: bodyL, weight: weightNormal) }
    public var bodyBold: Font { bodyFont(size: bodyL, weight: .bold) }
    public var bodySmall: Font { bodyFont(size: bodyS, weight: weightNormal) }
    public var bodySmallBold: Font { bodyFont(size: bodyS, weight: .bold) }
    public var label: Font { bodyFont(size: caption, weight: weightMedium) }
    public var labelBold: Font { bodyFont(size: caption, weight: .bold) }
    public var button: Font { bodyFont(size: bodyL, weight: .bold) }
    public var input: Font { bodyFont(size: bodyL, weight: weightNormal) }
    public var captionText: Font { bodyFont(size: caption, weight: weightNormal) }
    public var captionBold: Font { bodyFont(size: caption, weight: .bold) }
    public var microText: Font { bodyFont(size: micro, weight: weightNormal) }
    public var microBold: Font { bodyFont(size: micro, weight: .bold) }

    // MARK: - Line height modifiers
    public func lineSpacingModifier(for size: CGFloat) -> some ViewModifier {
        LineHeight(spacing: lineSpacing(for: size))
    }

    public func headingLineSpacingModifier(for size: CGFloat) -> some ViewModifier {
        LineHeight(spacing: headingLineSpacing(for: size))
    }

    struct LineHeight: ViewModifier {
        let spacing: CGFloat
        func body(content: Content) -> some View {
            content.lineSpacing(spacing)
        }
    }
}

// MARK: - Environment + Defaults
private struct TypographyKey: EnvironmentKey {
    static let defaultValue = Typography()
}

public extension EnvironmentValues {
    var typography: Typography {
        get { self[TypographyKey.self] }
        set { self[TypographyKey.self] = newValue }
    }
}

public struct TypographyProvider: ViewModifier {
    let typography: Typography
    public init(_ typography: Typography = Typography()) {
        self.typography = typography
    }
    public func body(content: Content) -> some View {
        content.environment(\.typography, typography)
    }
}

public extension View {
    func useTypography(_ typography: Typography = Typography()) -> some View {
        modifier(TypographyProvider(typography))
    }
}

// MARK: - Sugar Extensions
public extension View {
    func h1(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h1)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.displayXL))
    }
    func h2(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h2)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.displayL))
    }
    func h3(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h3)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.titleM))
    }
    func h4(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h4)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.titleS))
    }
    func h5(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h5)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.titleXS))
    }
    func h6(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h6)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.titleXS))
    }
    func bodyText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.body)
            .lineSpacing(env.typography.bodyLineSpacing)
    }
    func labelText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.label)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.caption))
    }
    func buttonText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.button)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.bodyL))
    }
    func inputText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.input)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.bodyL))
    }
}

// MARK: - Header Gradient Extension
struct HeaderGradientModifier: ViewModifier {
    @Environment(\.theme) private var theme
    func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: [theme.headerGradientStart, theme.headerGradientEnd]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

public extension View {
    func headerGradient() -> some View {
        self.modifier(HeaderGradientModifier())
    }
}
