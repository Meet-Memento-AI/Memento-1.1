//
//  InsightCardShowcase.swift
//  UIPlayground
//
//  Created by Sebastian Mendo
//

import SwiftUI

struct InsightCardShowcase: View {
    let sampleInsights = [
        (title: "This Week", emoji: "💭", text: "Early-week stress followed by calmer evenings. Short walks and social time appear helpful.", footer: "Optional nudge: If helpful, schedule a 10-minute break mid-day."),
        (title: "Mood Pattern", emoji: "📊", text: "Your energy peaks in the morning. Consider tackling creative work before noon.", footer: nil),
        (title: "Progress", emoji: "🎯", text: "You've journaled 5 days in a row! Consistency is building momentum.", footer: "Keep it up!"),
        (title: "Reflection", emoji: "🌟", text: "Gratitude entries correlate with better sleep quality. Notice the connection?", footer: nil),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("AI-generated insights based on journal patterns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                ForEach(Array(sampleInsights.enumerated()), id: \.offset) { _, insight in
                    InsightCard(
                        title: insight.title,
                        emoji: insight.emoji,
                        text: insight.text,
                        footer: insight.footer
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Insight Cards")
        .useTheme()
        .useTypography()
    }
}

#Preview("Light") {
    NavigationStack {
        InsightCardShowcase()
    }
}

#Preview("Dark") {
    NavigationStack {
        InsightCardShowcase()
    }
    .preferredColorScheme(.dark)
}

