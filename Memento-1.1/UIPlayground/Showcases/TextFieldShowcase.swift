//
//  TextFieldShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct TextFieldShowcase: View {
    @State private var email = ""
    @State private var password = ""
    @State private var title = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Email Input")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    AppTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    
                    if !email.isEmpty {
                        Text("Value: \(email)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Password Input")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    AppTextField(
                        title: "Password",
                        text: $password,
                        isSecure: true
                    )
                    
                    if !password.isEmpty {
                        Text("Password entered: \(String(repeating: "•", count: password.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standard Text")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    AppTextField(
                        title: "Entry Title",
                        text: $title
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Text Fields")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        TextFieldShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        TextFieldShowcase()
    }
    .preferredColorScheme(.dark)
}

