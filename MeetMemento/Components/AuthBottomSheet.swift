//
//  AuthBottomSheet.swift
//  MeetMemento
//
//  Unified bottom sheet component for user authentication (sign-up and sign-in).
//  Consolidates CreateAccountBottomSheet and SignInBottomSheet to eliminate duplication.
//

import SwiftUI

public struct AuthBottomSheet: View {
    // MARK: - Mode

    public enum Mode {
        case signUp
        case signIn

        var title: String {
            switch self {
            case .signUp: return "Create account"
            case .signIn: return "Sign in"
            }
        }

        var subtitle: String {
            switch self {
            case .signUp: return "Let's learn about you and we'll help you get started"
            case .signIn: return "Make sure to use your same login credentials."
            }
        }

        var isSignUp: Bool {
            switch self {
            case .signUp: return true
            case .signIn: return false
            }
        }

        var statusPrefix: String {
            switch self {
            case .signUp: return "sign-up"
            case .signIn: return "sign-in"
            }
        }
    }

    // MARK: - Properties

    let mode: Mode
    public var onSuccess: (() -> Void)?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - State

    @State private var email: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToOTP: Bool = false

    // MARK: - Initializer

    public init(mode: Mode, onSuccess: (() -> Void)? = nil) {
        self.mode = mode
        self.onSuccess = onSuccess
    }

    // MARK: - Body

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
                VStack(alignment: .leading, spacing: 12) {
                    Text(mode.title)
                        .font(type.h3)
                        .foregroundStyle(theme.foreground)

                    Text(mode.subtitle)
                        .font(.custom("Manrope-Medium", size: 17))
                        .lineSpacing(3.4)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)

                // Content
                VStack(spacing: 24) {
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.custom("Manrope-Medium", size: 17))
                            .foregroundStyle(theme.foreground)

                        AppTextField(
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textInputAutocapitalization: .never
                        )
                    }

                    // Continue button
                    PrimaryButton(title: "Continue", isLoading: isLoading) {
                        sendOTP()
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity((email.isEmpty || isLoading) ? 0.6 : 1.0)

                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(GrayScale.gray300)
                            .frame(height: 1)
                        Text("or")
                            .font(.custom("Manrope-Regular", size: 15))
                            .foregroundStyle(theme.mutedForeground)
                        Rectangle()
                            .fill(GrayScale.gray300)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Social auth buttons
                    VStack(spacing: 12) {
                        Button(action: { status = "Apple \(mode.statusPrefix) (stub)" }) {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.custom("Manrope-Medium", size: 18))
                                Text("Continue with Apple")
                                    .font(.custom("Manrope-SemiBold", size: 17))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.black)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                        }

                        Button(action: { status = "Google \(mode.statusPrefix) (stub)" }) {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                    .font(.custom("Manrope-Medium", size: 18))
                                Text("Continue with Google")
                                    .font(.custom("Manrope-SemiBold", size: 17))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundStyle(theme.foreground)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                                    .strokeBorder(GrayScale.gray300, lineWidth: 1.5)
                            )
                        }
                    }

                    // Status message
                    if !status.isEmpty {
                        Text(status)
                            .font(.custom("Manrope-Regular", size: 15))
                            .foregroundStyle(status.contains("✅") ? .green : theme.mutedForeground)
                            .multilineTextAlignment(.center)
                    }

                    // Skip to onboarding (only for sign-up, for UI testing)
                    if mode == .signUp {
                        SecondaryButton(title: "Skip to onboarding") {
                            onSuccess?()
                            DispatchQueue.main.async {
                                authViewModel.skipToOnboardingForTesting()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                Spacer()
            }
            .background(theme.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPVerificationView(email: email, isSignUp: mode.isSignUp)
                    .environmentObject(authViewModel)
            }
        }
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.hidden)
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                onSuccess?()
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

// MARK: - Previews

#Preview("Sign Up") {
    AuthBottomSheet(mode: .signUp)
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}

#Preview("Sign In") {
    AuthBottomSheet(mode: .signIn)
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
