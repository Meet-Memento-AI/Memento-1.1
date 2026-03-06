//
//  SetupPinView.swift
//
//  Onboarding screen for creating a 4-digit PIN
//

import SwiftUI

public struct SetupPinView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    @State private var pin: String = ""
    @FocusState private var isPinFieldFocused: Bool

    public var onComplete: ((String) -> Void)?
    public var onCancel: (() -> Void)?

    public init(
        onComplete: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
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
                    Text("Please, Set PIN-Code")
                        .font(type.h3)
                        .foregroundStyle(theme.foreground)
                        .padding(.top, 40)
                        .padding(.bottom, 60)

                    // PIN input fields
                    pinInputFields
                        .padding(.bottom, 40)

                    Spacer()

                    // Set PIN button
                    PrimaryButton(title: "Set PIN") {
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
                }
        }
        .navigationBarHidden(true)
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

        // Dismiss keyboard
        isPinFieldFocused = false
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onboardingViewModel.setupPin = pin
        onComplete?(pin)
    }
}

// MARK: - Previews

#Preview("Light") {
    SetupPinView()
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SetupPinView()
        .useTheme()
        .useTypography()
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.dark)
}
