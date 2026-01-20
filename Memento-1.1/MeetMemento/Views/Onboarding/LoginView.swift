//
//  LoginView.swift
//  MeetMemento
//
//  Minimal login placeholder (UI boilerplate).
//

import SwiftUI

public struct LoginView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @State private var status: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Sign in to MeetMemento")
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                // Placeholder buttons
                Button(action: { status = "Google sign-in (stub)" }) {
                    Text("Continue with Google")
                        .font(type.button)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.card)
                        .foregroundStyle(theme.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                }

                Button(action: { status = "Apple sign-in (stub)" }) {
                    Text("Continue with Apple")
                        .font(type.button)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                }
            }
            .padding(.horizontal, 24)

            if !status.isEmpty {
                Text(status)
                    .font(type.body)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(24)
        .background(theme.background)
    }
}

#Preview("Light") {
    LoginView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
