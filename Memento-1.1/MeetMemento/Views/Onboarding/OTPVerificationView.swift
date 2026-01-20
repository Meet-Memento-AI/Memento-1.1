
//
//  OTPVerificationView.swift
//  MeetMemento
//
//  Sign up view with Supabase authentication
//

import SwiftUI

public struct OTPVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    // Required parameters
    let email: String
    let isSignUp: Bool // true for create account, false for sign in

    // State variables
    @State private var otpCode: String = ""
    @State private var isVerifying: Bool = false
    @State private var showThinkingLoader: Bool = false
    @State private var errorMessage: String = ""
    @State private var resendMessage: String = ""
    @FocusState private var isCodeFieldFocused: Bool

    public init(email: String, isSignUp: Bool = true) {
        self.email = email
        self.isSignUp = isSignUp
    }
    
    public var body: some View {
        ZStack {
            // Main content (hidden when thinking)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 16)

                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(type.h2)
                            .headerGradient()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("We sent a 6-digit code to")
                                .font(type.body)
                                .foregroundStyle(theme.mutedForeground)

                            Text(email)
                                .font(type.bodyBold)
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                
                // Input fields
                VStack(spacing: 20) {
                    // OTP Code Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification code")
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                            .fontWeight(.medium)

                        OTPTextField(code: $otpCode)
                            .focused($isCodeFieldFocused)
                    }

                    // Resend code button
                    HStack {
                        Spacer()
                        Button {
                            resendCode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                Text("Resend code")
                                    .font(type.bodySmall)
                            }
                            .foregroundStyle(theme.primary)
                        }
                        .disabled(isVerifying)
                    }
                    .padding(.top, 4)

                    // Resend success message
                    if !resendMessage.isEmpty {
                        Text(resendMessage)
                            .font(type.bodySmall)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                // Error message
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 14))
                        Text(errorMessage)
                            .font(type.bodySmall)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                    .padding(.top, 8)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 32)
            }
            .background(theme.background.ignoresSafeArea())

            // FAB positioned at bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IconButton(systemImage: "chevron.right", size: 64) {
                        verifyCode()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                    .opacity((isVerifying || otpCode.count != 6) ? 0.5 : 1.0)
                    .disabled(isVerifying || otpCode.count != 6)
                }
            }
            .opacity(showThinkingLoader ? 0 : 1)

            // Thinking loader overlay
            if showThinkingLoader {
                ZStack {
                    theme.background.ignoresSafeArea()

                    VStack(spacing: 20) {
                        // Animated progress indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(theme.primary)

                        Text("Thinking...")
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                IconButtonNav(
                    icon: "chevron.left",
                    iconSize: 18,
                    buttonSize: 40,
                    enableHaptic: true,
                    onTap: { dismiss() }
                )
            }
        }
        .onAppear {
            // Auto-focus the OTP input when view appears
            isCodeFieldFocused = true
        }
    }
    
    // MARK: - Actions

    private func verifyCode() {
        guard otpCode.count == 6 else {
            errorMessage = "Please enter a 6-digit code"
            return
        }

        isVerifying = true
        errorMessage = ""

        Task {
            do {
                // Use the explicit email + code verification to be safe
                try await authViewModel.verifyOTP(email: email, code: otpCode)

                await MainActor.run {
                    isVerifying = false

                    if authViewModel.isAuthenticated {
                        // Show thinking loader
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showThinkingLoader = true
                        }

                        NSLog("✅ OTP verified, showing thinking loader")

                        // Dismissal will be handled by CreateAccountBottomSheet
                        // Keep loader visible during transition
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = "Invalid code. Please try again."

                    // Clear the code so user can re-enter
                    otpCode = ""
                }
            }
        }
    }

    private func resendCode() {
        resendMessage = ""
        errorMessage = ""

        Task {
            do {
                try await authViewModel.sendOTP(email: email)
                await MainActor.run {
                    resendMessage = "✓ Code sent"

                    // Clear message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        resendMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to resend code. Please try again."
                }
            }
        }
    }
}

#Preview("Light - Sign Up") {
    NavigationStack {
        OTPVerificationView(email: "user@example.com", isSignUp: true)
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark - Sign In") {
    NavigationStack {
        OTPVerificationView(email: "user@example.com", isSignUp: false)
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}

