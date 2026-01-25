import SwiftUI

// MARK: - Typography
// Supports dynamic font weight control for headings (Lora SemiBold for major headings,
// Sora SemiBold for others) and body text (Manrope Regular / Medium / Bold).

public struct Typography {

    // MARK: - Size Scale
    public let sizeXS: CGFloat = 11    // micro
    public let sizeSM: CGFloat = 13    // caption
    public let sizeMD: CGFloat = 14    // body2
    public let sizeLG: CGFloat = 16    // body1, h6, h5
    public let sizeXL: CGFloat = 20    // h4
    public let size2XL: CGFloat = 24   // h3
    public let size3XL: CGFloat = 32   // h2
    public let size4XL: CGFloat = 40   // h1

    // MARK: - Font Families
    private let primaryHeadingFont = "Lora-SemiBold"
    private let secondaryHeadingFont = "Sora-SemiBold"
    private let bodyRegularFontName = "Manrope-Regular"
    private let bodyMediumFontName = "Manrope-Medium"
    private let bodyBoldFontName = "Manrope-Bold"

    // MARK: - Configurable Properties
    public let headingWeight: Font.Weight

    public init(headingWeight: Font.Weight = .semibold) {
        self.headingWeight = headingWeight
    }

    // MARK: - Line Spacing
    private func lineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.5) }
    private func headingLineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.2) }

    // Body text specific line height: 14pt font + 6pt spacing = 20pt line height
    public var bodyLineSpacing: CGFloat { 6 }

    // MARK: - Font Helpers
    private func headingFont(size: CGFloat, isPrimary: Bool = true) -> Font {
        let name = isPrimary ? primaryHeadingFont : secondaryHeadingFont
        return Font.custom(name, size: size, relativeTo: .title)
    }

    private func bodyFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return Font.custom(bodyBoldFontName, size: size, relativeTo: .body)
        case .medium, .semibold:
            return Font.custom(bodyMediumFontName, size: size, relativeTo: .body)
        default:
            return Font.custom(bodyRegularFontName, size: size, relativeTo: .body)
        }
    }

    // MARK: - Headings (h1-h6)
    /// Lora SemiBold @ 40pt (serif) - Major display heading
    public var h1: Font { headingFont(size: size4XL, isPrimary: true) }
    /// Lora SemiBold @ 32pt (serif) - Secondary display heading
    public var h2: Font { headingFont(size: size3XL, isPrimary: true) }
    /// Sora SemiBold @ 24pt - Section heading
    public var h3: Font { headingFont(size: size2XL, isPrimary: false) }
    /// Sora SemiBold @ 20pt - Subsection heading
    public var h4: Font { headingFont(size: sizeXL, isPrimary: false) }
    /// Sora SemiBold @ 16pt - Minor heading
    public var h5: Font { headingFont(size: sizeLG, isPrimary: false) }
    /// Manrope Bold @ 16pt - Smallest heading
    public var h6: Font { bodyFont(size: sizeLG, weight: .bold) }

    // MARK: - Body Text (body1 = 16pt, body2 = 14pt)
    /// 16pt regular - Primary body text
    public var body1: Font { bodyFont(size: sizeLG, weight: .regular) }
    /// 16pt medium - Emphasized body text
    public var body1Medium: Font { bodyFont(size: sizeLG, weight: .medium) }
    /// 16pt bold - Strong body text
    public var body1Bold: Font { bodyFont(size: sizeLG, weight: .bold) }
    /// 14pt regular - Secondary body text
    public var body2: Font { bodyFont(size: sizeMD, weight: .regular) }
    /// 14pt medium - Emphasized secondary text
    public var body2Medium: Font { bodyFont(size: sizeMD, weight: .medium) }
    /// 14pt bold - Strong secondary text
    public var body2Bold: Font { bodyFont(size: sizeMD, weight: .bold) }

    // MARK: - Small Text (caption = 13pt, micro = 11pt)
    /// 13pt regular - Caption text
    public var caption: Font { bodyFont(size: sizeSM, weight: .regular) }
    /// 13pt medium - Emphasized caption
    public var captionMedium: Font { bodyFont(size: sizeSM, weight: .medium) }
    /// 13pt bold - Strong caption
    public var captionBold: Font { bodyFont(size: sizeSM, weight: .bold) }
    /// 11pt regular - Micro/fine print text
    public var micro: Font { bodyFont(size: sizeXS, weight: .regular) }
    /// 11pt medium - Emphasized micro text
    public var microMedium: Font { bodyFont(size: sizeXS, weight: .medium) }
    /// 11pt bold - Strong micro text
    public var microBold: Font { bodyFont(size: sizeXS, weight: .bold) }

    // MARK: - Utility Aliases
    /// Label text - uses captionMedium (13pt medium)
    public var label: Font { captionMedium }
    /// Label bold variant (13pt bold)
    public var labelBold: Font { captionBold }
    /// Button text - uses body1Bold (16pt bold)
    public var button: Font { body1Bold }
    /// Input field text - uses body1 (16pt regular)
    public var input: Font { body1 }

    // MARK: - Deprecated Aliases (for backward compatibility)
    @available(*, deprecated, renamed: "body1")
    public var body: Font { body1 }

    @available(*, deprecated, renamed: "body1Medium")
    public var bodyMedium: Font { body1Medium }

    @available(*, deprecated, renamed: "body1Bold")
    public var bodyBold: Font { body1Bold }

    @available(*, deprecated, renamed: "body2")
    public var bodySmall: Font { body2 }

    @available(*, deprecated, renamed: "body2Bold")
    public var bodySmallBold: Font { body2Bold }

    @available(*, deprecated, renamed: "caption")
    public var captionText: Font { caption }

    @available(*, deprecated, renamed: "micro")
    public var microText: Font { micro }

    // Deprecated size aliases
    @available(*, deprecated, renamed: "sizeXS")
    public var micro_size: CGFloat { sizeXS }

    @available(*, deprecated, renamed: "sizeSM")
    public var caption_size: CGFloat { sizeSM }

    @available(*, deprecated, renamed: "sizeMD")
    public var bodyS: CGFloat { sizeMD }

    @available(*, deprecated, renamed: "sizeLG")
    public var bodyL: CGFloat { sizeLG }

    @available(*, deprecated, renamed: "sizeLG")
    public var titleXS: CGFloat { sizeLG }

    @available(*, deprecated, renamed: "sizeXL")
    public var titleS: CGFloat { sizeXL }

    @available(*, deprecated, renamed: "size2XL")
    public var titleM: CGFloat { size2XL }

    @available(*, deprecated, renamed: "size3XL")
    public var displayL: CGFloat { size3XL }

    @available(*, deprecated, renamed: "size4XL")
    public var displayXL: CGFloat { size4XL }

    // MARK: - Line Height Modifiers
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
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.size4XL))
    }
    func h2(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h2)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.size3XL))
    }
    func h3(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h3)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.size2XL))
    }
    func h4(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h4)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.sizeXL))
    }
    func h5(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h5)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.sizeLG))
    }
    func h6(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h6)
            .modifier(env.typography.headingLineSpacingModifier(for: env.typography.sizeLG))
    }
    func bodyText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.body1)
            .lineSpacing(env.typography.bodyLineSpacing)
    }
    func labelText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.label)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.sizeSM))
    }
    func buttonText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.button)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.sizeLG))
    }
    func inputText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.input)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.sizeLG))
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
