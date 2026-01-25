//
//  SignInBottomSheet.swift
//  MeetMemento
//
//  Bottom sheet component for user sign in (UI boilerplate).
//

import SwiftUI

public struct SignInBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToOTP: Bool = false

    public var onSignInSuccess: (() -> Void)?

    public init(onSignInSuccess: (() -> Void)? = nil) {
        self.onSignInSuccess = onSignInSuccess
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(theme.mutedForeground.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in")
                        .font(type.h3)
                        .headerGradient()

                    Text("Make sure to use your same login credentials.")
                        .font(type.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)

                // Content
                VStack(spacing: 24) {
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(type.bodyBold)
                            .foregroundStyle(theme.foreground)

                        AppTextField(
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textInputAutocapitalization: .never
                        )
                    }

                    // Continue button
                    Button(action: {
                        sendOTP()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(type.button)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity((email.isEmpty || isLoading) ? 0.6 : 1.0)

                    // Divider
                    HStack {
                        Rectangle().fill(theme.border).frame(height: 1)
                        Text("or").font(type.body).foregroundStyle(theme.mutedForeground).padding(.horizontal, 16)
                        Rectangle().fill(theme.border).frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Social auth buttons (stubs)
                    VStack(spacing: 12) {
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
                    }

                    // Status message
                    if !status.isEmpty {
                        Text(status)
                            .font(type.body)
                            .foregroundStyle(status.contains("✅") ? .green : theme.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(theme.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPVerificationView(email: email, isSignUp: false)
                    .environmentObject(authViewModel)
            }
        }
        .presentationDetents([.height(540)])
        .presentationDragIndicator(.hidden)
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                onSignInSuccess?()
            }
        }
    }

    // MARK: - Helpers

    private func sendOTP() {
        guard !email.isEmpty else { return }
        guard email.contains("@") else {
            status = "Please enter a valid email address"
            return
        }

        isLoading = true
        status = ""

        Task {
            do {
                try await authViewModel.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    navigateToOTP = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    status = "Failed to send code. Please try again."
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Sign In Bottom Sheet") {
    SignInBottomSheet()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
