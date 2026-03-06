//
//  AuthBottomSheet.swift
//  MeetMemento
//
//  Email-only authentication sheet. Social auth (Apple/Google) lives on WelcomeView.
//

import SwiftUI

public struct AuthBottomSheet: View {
    // MARK: - Properties

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

    public init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
    }

    // MARK: - Body

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(theme.mutedForeground.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Continue with email")
                        .font(type.h5)
                        .foregroundStyle(theme.foreground)

                    Text("Enter your email and we'll send you a verification code.")
                        .font(type.body1)
                        .lineSpacing(type.bodyLineSpacing)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(type.body1)
                            .foregroundStyle(theme.foreground)

                        AppTextField(
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textInputAutocapitalization: .never
                        )
                    }

                    PrimaryButton(title: "Continue", isLoading: isLoading) {
                        sendOTP()
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity((email.isEmpty || isLoading) ? 0.6 : 1.0)

                    if !status.isEmpty {
                        Text(status)
                            .font(type.body2)
                            .foregroundStyle(status.contains("✅") ? .green : theme.destructive)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                Spacer()
            }
            .background(theme.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPVerificationView(email: email)
                    .environmentObject(authViewModel)
            }
        }
        .presentationDetents([.height(420)])
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

#Preview("Email Auth") {
    AuthBottomSheet()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
