//
//  ComponentGallery.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct ComponentGallery: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Buttons") {
                    NavigationLink("Primary Buttons") {
                        ButtonShowcase()
                    }
                    NavigationLink("Social Buttons") {
                        SocialButtonShowcase()
                    }
                }
                
                Section("Cards") {
                    NavigationLink("Journal Cards") {
                        JournalCardShowcase()
                    }
                    NavigationLink("Insight Cards") {
                        InsightCardShowcase()
                    }
                }
                
                Section("Navigation") {
                    NavigationLink("Tab Switcher") {
                        TabSwitcherShowcase()
                    }
                    NavigationLink("Top Nav") {
                        TopNavShowcase()
                    }
                }
                
                Section("Inputs") {
                    NavigationLink("Text Fields") {
                        TextFieldShowcase()
                    }
                }
            }
            .navigationTitle("UI Playground")
        }
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    ComponentGallery()
}

#Preview("Dark") {
    ComponentGallery()
        .preferredColorScheme(.dark)
}

