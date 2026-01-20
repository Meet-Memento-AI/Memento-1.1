//
//  TabSwitcherShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct TabSwitcherShowcase: View {
    @State private var selection: DemoTab = .journal
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Current Selection")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(selection.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Image(systemName: selection.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
            }
            .padding()
            
            TabSwitcher<DemoTab>(selection: $selection)
                .frame(width: 280)
            
            Text("Tap to switch between tabs")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Tab Switcher")
        .useTheme()
        .useTypography()
    }
}

// Sample tab enum for demo
fileprivate enum DemoTab: String, CaseIterable, Identifiable, Hashable, LabeledTab {
    case journal, insights
    var id: String { rawValue }
    var title: String {
        switch self {
        case .journal: return "Journal"
        case .insights: return "Insights"
        }
    }
    var systemImage: String {
        switch self {
        case .journal: return "book.closed.fill"
        case .insights: return "sparkles"
        }
    }
}

#Preview("Light") {
    NavigationStack {
        TabSwitcherShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        TabSwitcherShowcase()
    }
    .preferredColorScheme(.dark)
}

