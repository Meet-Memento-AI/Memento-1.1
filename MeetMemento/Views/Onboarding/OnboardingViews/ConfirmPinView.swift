//
//  ConfirmPinView.swift
//
//  Onboarding screen for confirming the 4-digit PIN
//

import SwiftUI

public struct ConfirmPinView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    @State private var pin: String = ""
    @State private var showError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isPinFieldFocused: Bool

    let originalPin: String

    /// Whether this PIN is being set as a backup for FaceID users
    public var isFaceIDBackup: Bool

    public var onComplete: (() -> Void)?
    public var onCancel: (() -> Void)?

    /// Title changes based on context
    private var titleText: String {
        isFaceIDBackup ? "Confirm Backup PIN" : "Confirm Your PIN"
    }

    public init(
        originalPin: String,
        isFaceIDBackup: Bool = false,
        onComplete: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.originalPin = originalPin
        self.isFaceIDBackup = isFaceIDBackup
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                headerSection

                // Main content area
                VStack(spacing: 0) {
                    // Title
                    Text(titleText)
                        .font(type.h3)
                        .foregroundStyle(theme.foreground)
                        .padding(.top, 40)
                        .padding(.bottom, 60)

                    // PIN input fields with shake animation
                    pinInputFields
                        .offset(x: shakeOffset)
                        .padding(.bottom, 40)

                    // Error message
                    if showError {
                        Text("PINs don't match. Please try again.")
                            .font(type.body2)
                            .foregroundStyle(Color.red)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    }

                    Spacer()

                    // Confirm PIN button
                    PrimaryButton(title: "Confirm PIN") {
                        handlePinComplete()
                    }
                    .opacity(pin.count == 4 ? 1.0 : 0.5)
                    .disabled(pin.count != 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            
            // Hidden TextField for iOS keyboard
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .focused($isPinFieldFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .onChange(of: pin) { oldValue, newValue in
                    // Filter to only allow digits
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        pin = filtered
                        return
                    }
                    
                    // Limit to 4 digits
                    if filtered.count > 4 {
                        pin = String(filtered.prefix(4))
                    } else {
                        pin = filtered
                    }
                    
                    // Auto-validate when 4 digits are entered
                    if pin.count == 4 {
                        validatePin(pin)
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.background, location: 0),
                    .init(color: theme.background.opacity(0), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .frame(height: 64)

            // Header content
            HStack(alignment: .center, spacing: 12) {
                // Back button (calls coordinator onCancel, or dismiss when used standalone)
                IconButtonNav(
                    icon: "chevron.left",
                    iconSize: 20,
                    buttonSize: 40,
                    foregroundColor: theme.foreground,
                    useDarkBackground: false,
                    enableHaptic: true,
                    onTap: { onCancel?() ?? dismiss() }
                )
                .accessibilityLabel("Back")

                Spacer()

                Color.clear
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    private var pinInputFields: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { index in
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
                                if index < pin.count {
                                    Text(String(pin[pin.index(pin.startIndex, offsetBy: index)]))
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

    // MARK: - Actions

    private func handlePinComplete() {
        guard pin.count == 4 else { return }
        validatePin(pin)
    }

    private func validatePin(_ enteredPin: String) {
        if enteredPin == originalPin {
            // PIN matches - success
            // Dismiss keyboard
            isPinFieldFocused = false
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onboardingViewModel.confirmedPin = enteredPin
            onComplete?()
        } else {
            // PIN doesn't match - show error
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showError = true

            // Shake animation using async/await
            Task { @MainActor in
                withAnimation(.default) {
                    shakeOffset = 10
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.default) {
                    shakeOffset = -10
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.default) {
                    shakeOffset = 10
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.default) {
                    shakeOffset = 0
                }
                // Clear PIN after shake
                try? await Task.sleep(nanoseconds: 100_000_000)
                pin = ""
                showError = false
            }
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    ConfirmPinView(originalPin: "1234")
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ConfirmPinView(originalPin: "1234")
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.dark)
}
