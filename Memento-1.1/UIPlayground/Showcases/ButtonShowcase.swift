//
//  ButtonShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct ButtonShowcase: View {
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Primary Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Buttons")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        PrimaryButton(title: "Save Entry") {
                            print("Save tapped")
                        }
                        
                        PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                            print("Continue tapped")
                        }
                        
                        PrimaryButton(title: "Delete", systemImage: "trash") {
                            print("Delete tapped")
                        }
                    }
                }
                
                // Loading State
                VStack(alignment: .leading, spacing: 12) {
                    Text("Loading State")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    PrimaryButton(title: "Saving...", isLoading: true) {}
                }
                
                // Interactive Demo
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interactive Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    PrimaryButton(
                        title: isLoading ? "Loading..." : "Toggle Loading",
                        isLoading: isLoading
                    ) {
                        isLoading.toggle()
                        if isLoading {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isLoading = false
                            }
                        }
                    }
                }
                
                // Icon Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon Buttons")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 16) {
                        IconButton(systemImage: "plus") {
                            print("Plus tapped")
                        }
                        
                        IconButton(systemImage: "mic.fill") {
                            print("Mic tapped")
                        }
                        
                        IconButton(systemImage: "star.fill") {
                            print("Star tapped")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Buttons")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        ButtonShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        ButtonShowcase()
    }
    .preferredColorScheme(.dark)
}

