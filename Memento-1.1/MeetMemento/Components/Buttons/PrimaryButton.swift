import SwiftUI

public struct PrimaryButton: View {
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
                if isLoading { ProgressView().tint(theme.primaryForeground) }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(theme.primaryForeground)
            .background(theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .stroke(theme.ring.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        PrimaryButton(title: "Reflect", systemImage: "sparkles") {}
        PrimaryButton(title: "Save", isLoading: true) {}
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Dark") {
    VStack(spacing: 12) {
        PrimaryButton(title: "Reflect", systemImage: "sparkles") {}
        PrimaryButton(title: "Save", isLoading: true) {}
    }
    .padding()
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
