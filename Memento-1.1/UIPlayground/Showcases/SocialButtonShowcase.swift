//
//  SocialButtonShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct SocialButtonShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Google Button
                VStack(alignment: .leading, spacing: 12) {
                    Text("Google Sign-In")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    GoogleSignInButton(title: "Sign in with Google") {
                        print("Google sign-in tapped")
                    }
                }
                
                // Apple Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Apple Sign-In")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Different styles for light/dark backgrounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        AppleSignInButton(style: .black) {
                            print("Apple black tapped")
                        }
                        
                        AppleSignInButton(style: .white) {
                            print("Apple white tapped")
                        }
                        
                        AppleSignInButton(style: .whiteOutline) {
                            print("Apple outline tapped")
                        }
                    }
                }
                
                // Social Button (Generic)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generic Social Button")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    SocialButton(title: "Continue with GitHub", systemImage: "chevron.left.forwardslash.chevron.right") {
                        print("GitHub tapped")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Social Buttons")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        SocialButtonShowcase()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SocialButtonShowcase()
    }
    .preferredColorScheme(.dark)
}

