//
//  PinEntryView.swift
//  MeetMemento
//
//  Reusable PIN entry component with dots indicator and number pad
//

import SwiftUI

public struct PinEntryView: View {
    @Binding var pin: String
    let maxDigits: Int
    let onComplete: ((String) -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(
        pin: Binding<String>,
        maxDigits: Int = 4,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._pin = pin
        self.maxDigits = maxDigits
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 32) {
            // PIN dots indicator
            pinDotsView

            // Separator line
            Rectangle()
                .fill(GrayScale.gray300)
                .frame(height: 1)
                .padding(.horizontal, 40)

            // Number pad
            numberPadView
        }
    }

    // MARK: - PIN Dots

    private var pinDotsView: some View {
        HStack(spacing: 16) {
            ForEach(0..<maxDigits, id: \.self) { index in
                Circle()
                    .fill(index < pin.count ? GrayScale.gray400 : Color.clear)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                index < pin.count ? Color.clear : GrayScale.gray300,
                                lineWidth: 1.5
                            )
                    )
            }
        }
    }

    // MARK: - Number Pad

    private var numberPadView: some View {
        VStack(spacing: 16) {
            // Row 1: 1, 2, 3
            HStack(spacing: 24) {
                numberButton("1")
                numberButton("2")
                numberButton("3")
            }

            // Row 2: 4, 5, 6
            HStack(spacing: 24) {
                numberButton("4")
                numberButton("5")
                numberButton("6")
            }

            // Row 3: 7, 8, 9
            HStack(spacing: 24) {
                numberButton("7")
                numberButton("8")
                numberButton("9")
            }

            // Row 4: empty, 0, delete
            HStack(spacing: 24) {
                // Empty placeholder for alignment
                Color.clear
                    .frame(width: 72, height: 72)

                numberButton("0")

                deleteButton
            }
        }
    }

    private func numberButton(_ digit: String) -> some View {
        Button {
            appendDigit(digit)
        } label: {
            Text(digit)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    private var deleteButton: some View {
        Button {
            deleteLastDigit()
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard pin.count < maxDigits else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pin += digit

        if pin.count == maxDigits {
            onComplete?(pin)
        }
    }

    private func deleteLastDigit() {
        guard !pin.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pin.removeLast()
    }
}

// MARK: - Number Pad Button Style

private struct NumberPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("PIN Entry") {
    PinEntryPreview()
        .useTheme()
        .useTypography()
}

private struct PinEntryPreview: View {
    @State private var pin = ""

    var body: some View {
        VStack(spacing: 40) {
            Text("Enter PIN")
                .font(.title2)
                .fontWeight(.semibold)

            PinEntryView(pin: $pin) { completedPin in
                print("PIN entered: \(completedPin)")
            }

            Text("Current: \(pin)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}
