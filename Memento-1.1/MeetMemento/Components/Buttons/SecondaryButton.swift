import SwiftUI

public struct SecondaryButton: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var action: () -> Void

    public init(title: String,
                systemImage: String? = nil,
                isLoading: Bool = false,
                action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .font(type.button)
                if isLoading { ProgressView().tint(PrimaryScale.primary600) }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(PrimaryScale.primary600)
            .background(Color.clear) // Transparent background
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .stroke(PrimaryScale.primary600, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        SecondaryButton(title: "Reflect", systemImage: "sparkles") {}
        SecondaryButton(title: "Save", isLoading: true) {}
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Dark") {
    VStack(spacing: 12) {
        SecondaryButton(title: "Reflect", systemImage: "sparkles") {}
        SecondaryButton(title: "Save", isLoading: true) {}
    }
    .padding()
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
