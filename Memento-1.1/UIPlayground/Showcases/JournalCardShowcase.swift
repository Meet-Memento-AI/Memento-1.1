//
//  JournalCardShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct JournalCardShowcase: View {
    @State private var pinnedStates: [Int: Bool] = [0: true, 2: true]
    
    let sampleEntries: [(String, String, Date)] = [
        ("Monday Morning Reflection", "Started the day with a walk around the neighborhood. Felt refreshed and ready to tackle new challenges. The weather was perfect.", Date()),
        ("Weekly Review", "Reviewed my goals for Q4. Made good progress on project milestones. Need to focus more on self-care next week.", Date().addingTimeInterval(-86400)),
        ("Evening Thoughts", "Grateful for the support from the team today. Challenging meeting but we found a path forward. Tomorrow will be even better.", Date().addingTimeInterval(-172800)),
        ("Quick Note", "Sometimes the smallest wins feel the biggest.", Date().addingTimeInterval(-259200)),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Tap to select, toggle pin icon to pin/unpin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                ForEach(Array(sampleEntries.enumerated()), id: \.offset) { index, entry in
                    JournalCard(
                        title: entry.0,
                        excerpt: entry.1,
                        date: entry.2,
                        pinned: pinnedStates[index] ?? false,
                        onTap: {
                            print("Tapped: \(entry.0)")
                        },
                        onPinToggle: {
                            pinnedStates[index] = !(pinnedStates[index] ?? false)
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Journal Cards")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        JournalCardShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        JournalCardShowcase()
    }
    .preferredColorScheme(.dark)
}

