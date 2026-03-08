//
//  LockScreenView.swift
//  MeetMemento
//
//  Lock screen that protects app content with FaceID or PIN.
//  Designed to match the LaunchScreen for seamless transition.
//

import SwiftUI

struct LockScreenView: View {
    @ObservedObject var viewModel: LockScreenViewModel
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    // PIN entry state
    @State private var enteredPIN: String = ""
    @State private var showPINError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isPinFieldFocused: Bool

    /// Computed property for retry button visibility - derived from ViewModel state
    private var shouldShowRetryButton: Bool {
        viewModel.biometricFailureCount > 0 && !viewModel.isAuthenticating
    }

    private let pinLength = 4

    var body: some View {
        ZStack {
            // White background matching LaunchScreen
            Color.white
                .ignoresSafeArea()

            VStack {

                // App logo - half size of LaunchScreen
                Image("MeetMemento-AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 64)
                    .padding(.bottom, 16)

                // PIN entry or retry button at bottom
                if viewModel.showPINFallback {
                    pinEntryContent
                        .padding(.bottom, 60)
                } else if shouldShowRetryButton {
                    retryButton
                        .padding(.bottom, 80)
                }
            }

            // Hidden TextField for iOS keyboard (PIN mode only)
            if viewModel.showPINFallback {
                TextField("", text: $enteredPIN)
                    .keyboardType(.numberPad)
                    .focused($isPinFieldFocused)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .onChange(of: enteredPIN) { oldValue, newValue in
                        // Filter to only allow digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            enteredPIN = filtered
                            return
                        }

                        // Limit to 4 digits
                        if filtered.count > 4 {
                            enteredPIN = String(filtered.prefix(4))
                        } else {
                            enteredPIN = filtered
                        }

                        // Auto-validate when 4 digits entered
                        if enteredPIN.count == pinLength {
                            validatePIN()
                        }
                    }
            }
        }
        .onAppear {
            // Reset local state for clean appearance
            enteredPIN = ""
            showPINError = false
            shakeOffset = 0
        }
        .task(id: viewModel.isLocked) {
            // Auto-trigger biometric auth when lock state changes to locked
            guard viewModel.isLocked else { return }
            guard !viewModel.showPINFallback && viewModel.isBiometricAvailable else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await viewModel.authenticateWithBiometrics()
        }
        .onChange(of: viewModel.showPINFallback) { _, showPIN in
            // Auto-focus PIN field when switching to PIN mode
            if showPIN {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPinFieldFocused = true
                }
            }
        }
    }

    // MARK: - Retry Button

    private var retryButton: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await viewModel.authenticateWithBiometrics()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: biometricIconName)
                        .font(.system(size: 20))
                    Text("Try Again")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(theme.primary)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(
                    Capsule()
                        .fill(theme.primary.opacity(0.1))
                )
            }

            // PIN fallback
            if viewModel.hasPINFallback {
                Button {
                    viewModel.switchToPINFallback()
                } label: {
                    Text("Use PIN")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.mutedForeground)
                }
            }
        }
    }

    // MARK: - PIN Entry Content

    private var pinEntryContent: some View {
        VStack(spacing: 24) {
            // PIN input fields (tappable to show keyboard)
            pinInputFields
                .offset(x: shakeOffset)

            // Error message
            if showPINError {
                Text("Incorrect PIN")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.red)
            }

            // Biometric fallback
            if viewModel.isBiometricAvailable {
                Button {
                    isPinFieldFocused = false
                    viewModel.switchToBiometric()
                    enteredPIN = ""
                    showPINError = false
                    Task {
                        await viewModel.authenticateWithBiometrics()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: biometricIconName)
                            .font(.system(size: 16))
                        Text("Use \(viewModel.biometricTypeName)")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(theme.mutedForeground)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - PIN Input Fields

    private var pinInputFields: some View {
        HStack(spacing: 16) {
            ForEach(0..<pinLength, id: \.self) { index in
                Button {
                    // Focus the hidden TextField to show keyboard
                    DispatchQueue.main.async {
                        isPinFieldFocused = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GrayScale.gray200)
                        .frame(width: 60, height: 70)
                        .overlay(
                            Group {
                                if index < enteredPIN.count {
                                    Text(String(enteredPIN[enteredPIN.index(enteredPIN.startIndex, offsetBy: index)]))
                                        .font(type.h2)
                                        .foregroundStyle(theme.foreground)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - PIN Validation

    private func validatePIN() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if viewModel.validatePIN(enteredPIN) {
                // Success - viewModel will unlock
                isPinFieldFocused = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                // Error - shake and reset
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showPINError = true
                shakeAnimation()
                enteredPIN = ""
            }
        }
    }

    private func shakeAnimation() {
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                shakeOffset = 0
            }
        }
    }

    // MARK: - Helpers

    private var biometricIconName: String {
        switch viewModel.biometricTypeName {
        case "Touch ID":
            return "touchid"
        case "Optic ID":
            return "opticid"
        default:
            return "faceid"
        }
    }
}

// MARK: - Previews

#Preview("Face ID Mode") {
    LockScreenView(viewModel: LockScreenViewModel())
        .useTheme()
        .useTypography()
}

#Preview("PIN Mode") {
    let viewModel = LockScreenViewModel()
    viewModel.showPINFallback = true
    return LockScreenView(viewModel: viewModel)
        .useTheme()
        .useTypography()
}
