//
//  OTPTextField.swift
//  MeetMemento
//
//  6-digit OTP input component with individual boxes
//

import SwiftUI

public struct OTPTextField: View {
    @Binding var code: String
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(code: Binding<String>) {
        self._code = code
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                SingleDigitBox(
                    digit: digitAt(index),
                    isFilled: index < code.count,
                    isCurrent: index == code.count
                )
            }
        }
        .overlay {
            // Hidden TextField to capture input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode) // iOS autocomplete from email
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .blendMode(.screen)
                .onChange(of: code) { _, newValue in
                    // Filter to only numeric and limit to 6 digits
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 6 {
                        code = String(filtered.prefix(6))
                    } else {
                        code = filtered
                    }
                }
        }
    }

    private func digitAt(_ index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

// MARK: - Single Digit Box

struct SingleDigitBox: View {
    let digit: String
    let isFilled: Bool
    let isCurrent: Bool

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    var body: some View {
        ZStack {
            Text(digit)
                .font(type.h2)
                .foregroundStyle(theme.foreground)
        }
        .frame(width: 48, height: 56)
        .background(theme.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                .stroke(
                    isFilled ? theme.primary : (isCurrent ? theme.primary.opacity(0.5) : theme.border),
                    lineWidth: isFilled ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFilled)
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
}

// MARK: - Preview

#Preview("Empty State") {
    VStack(spacing: 32) {
        Text("Empty")
            .font(.caption)
        OTPTextField(code: .constant(""))

        Text("Partial Entry")
            .font(.caption)
        OTPTextField(code: .constant("123"))

        Text("Complete Entry")
            .font(.caption)
        OTPTextField(code: .constant("123456"))
    }
    .padding()
    .useTheme()
    .useTypography()
}
