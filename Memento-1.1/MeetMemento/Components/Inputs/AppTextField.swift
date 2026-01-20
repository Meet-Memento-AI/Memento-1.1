//
//  AppTextField.swift
//  MeetMemento
//
//  Reusable text field component following app design system
//

import SwiftUI

public struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    var icon: String? = nil
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @FocusState private var isFocused: Bool
    
    public init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization = .sentences,
        icon: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textInputAutocapitalization = textInputAutocapitalization
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.mutedForeground)
                    .frame(width: 20)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(type.input)
            .foregroundStyle(theme.foreground)
            .textInputAutocapitalization(textInputAutocapitalization)
            .keyboardType(keyboardType)
            .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                .stroke(isFocused ? theme.primary : theme.border, lineWidth: isFocused ? 2 : 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AppTextField(
            placeholder: "Email",
            text: .constant(""),
            keyboardType: .emailAddress,
            textInputAutocapitalization: .never,
            icon: "envelope"
        )
        
        AppTextField(
            placeholder: "Password",
            text: .constant(""),
            isSecure: true,
            icon: "lock"
        )
    }
    .padding()
    .useTheme()
    .useTypography()
    .background(Environment(\.theme).wrappedValue.background)
}

