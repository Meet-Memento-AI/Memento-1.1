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
    @State private var showOTP: Bool = false

    public var onSignInSuccess: (() -> Void)?

    public init(onSignInSuccess: (() -> Void)? = nil) {
        self.onSignInSuccess = onSignInSuccess
    }

    public var body: some View {
        NavigationStack {
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
                ScrollView {
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
                            Task {
                                 isLoading = true
                                 status = ""
                                 do {
                                     try await authViewModel.sendOTP(email: email)
                                     // Trigger navigation
                                     showOTP = true
                                 } catch {
                                     status = "Error: \(error.localizedDescription)"
                                 }
                                 isLoading = false
                            }
                        }) {
                            if isLoading {
                                ProgressView().tint(.white)
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
                        .disabled(email.isEmpty || isLoading)
                        .opacity(email.isEmpty || isLoading ? 0.6 : 1.0)
                        
                        // Divider
                        HStack {
                            Rectangle().fill(theme.border).frame(height: 1)
                            Text("or").font(type.body).foregroundStyle(theme.mutedForeground).padding(.horizontal, 16)
                            Rectangle().fill(theme.border).frame(height: 1)
                        }
                        .padding(.vertical, 8)

                        // Social auth buttons (stubs - disabled actions for now)
                        VStack(spacing: 12) {
                            Button(action: { /* TODO: Implement Apple Auth */ }) {
                                Text("Continue with Apple")
                                    .font(type.button)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(.black)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                            }

                            Button(action: { /* TODO: Implement Google Auth */ }) {
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
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: status.contains("✅") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(status.contains("✅") ? .green : .red)
                                    .font(.system(size: 16))
                                
                                Text(status)
                                    .font(type.bodySmall)
                                    .foregroundStyle(theme.foreground)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radius.md)
                                    .fill(status.contains("✅") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
            .background(theme.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView(email: email, isSignUp: false)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview
#Preview("Sign In Bottom Sheet") {
    SignInBottomSheet()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
