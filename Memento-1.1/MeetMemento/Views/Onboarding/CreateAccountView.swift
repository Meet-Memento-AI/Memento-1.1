//
//  CreateAccountView.swift
//  MeetMemento
//
//  Profile creation view (UI boilerplate).
//

import SwiftUI

public struct CreateAccountView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false

    public var onComplete: (() -> Void)?

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 16)

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Memento")
                            .font(type.h2)
                            .headerGradient()

                        Text("Create your account to get started.")
                            .font(type.body)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .padding(.bottom, 16)

                    // Input fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First name")
                                .font(type.body)
                                .foregroundStyle(theme.foreground)
                                .fontWeight(.medium)

                            AppTextField(
                                placeholder: "Enter your first name",
                                text: $firstName,
                                textInputAutocapitalization: .words
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last name")
                                .font(type.body)
                                .foregroundStyle(theme.foreground)
                                .fontWeight(.medium)

                            AppTextField(
                                placeholder: "Enter your last name",
                                text: $lastName,
                                textInputAutocapitalization: .words
                            )
                        }
                    }

                    // Status message
                    if !status.isEmpty {
                        Text(status)
                            .font(type.body)
                            .foregroundStyle(status.contains("✅") ? .green : .red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
            }
            .background(theme.background.ignoresSafeArea())

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IconButton(systemImage: "chevron.right", size: 64) {
                        signUp()
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 32)
                    .opacity(isLoading ? 0.5 : 1.0)
                    .disabled(isLoading)
                }
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
    }

    private func signUp() {
        guard !firstName.isEmpty else {
            status = "Error: Please enter your first name"
            return
        }
        guard !lastName.isEmpty else {
            status = "Error: Please enter your last name"
            return
        }

        isLoading = true
        status = ""

        // Stub: Just complete immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            status = "✅ Profile saved!"
            onComplete?()
        }
    }
}

#Preview("Light") {
    NavigationStack {
        CreateAccountView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CreateAccountView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
