//
//  TopNavShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct TopNavShowcase: View {
    @State private var selection: JournalTopTab = .yourEntries
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tabs Variant")
                    .font(.headline)
                
                TopNav(variant: .tabs, selection: $selection)
                    .frame(width: 320)
                
                Text("Selected: \(selection.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Single Variant")
                    .font(.headline)
                
                TopNav(variant: .single, selection: .constant(.yourEntries))
                    .frame(width: 320)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Single Selected Variant")
                    .font(.headline)
                
                TopNav(variant: .singleSelected, selection: .constant(.yourEntries))
                    .frame(width: 320)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Top Navigation")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        TopNavShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        TopNavShowcase()
    }
    .preferredColorScheme(.dark)
}

