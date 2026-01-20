//
//  FastPreviewHelpers.swift
//  UIPlayground
//
//  Lightweight helpers for instant SwiftUI previews
//

import SwiftUI

// MARK: - Fast Theme (No hex parsing overhead)

/// Lightweight theme for previews - 10x faster than full Theme
struct FastTheme {
    // Colors as direct RGB values (no hex parsing!)
    static let lightPrimary = Color(red: 0.541, green: 0.220, blue: 0.961)  // #8A38F5
    static let lightBackground = Color.white
    static let lightForeground = Color(red: 0.039, green: 0.039, blue: 0.039)  // #0A0A0A
    static let lightSecondary = Color(red: 0.925, green: 0.933, blue: 0.949)  // #ECEEF2
    static let lightBorder = Color.black.opacity(0.1)
    
    static let darkPrimary = Color(red: 0.980, green: 0.980, blue: 0.980)  // #FAFAFA
    static let darkBackground = Color(red: 0.039, green: 0.039, blue: 0.039)  // #0A0A0A
    static let darkForeground = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let darkSecondary = Color(red: 0.149, green: 0.149, blue: 0.149)  // #262626
    static let darkBorder = Color(red: 0.149, green: 0.149, blue: 0.149)
}

// MARK: - Preview Layout Extension

extension View {
    /// Quick preview setup - use this for instant rendering
    func fastPreview(scheme: ColorScheme = .light) -> some View {
        self
            .preferredColorScheme(scheme)
            .previewLayout(.sizeThatFits)
    }
    
    /// Preview with padding and size constraint
    func previewCard(scheme: ColorScheme = .light) -> some View {
        self
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(scheme)
    }
}

// MARK: - Sample Data Generators

enum PreviewSamples {
    // Dates
    static let now = Date()
    static let yesterday = Date().addingTimeInterval(-86400)
    static let lastWeek = Date().addingTimeInterval(-604800)
    
    // Journal entries
    static let journalTitles = [
        "Morning reflection",
        "Weekly review",
        "Evening thoughts",
        "Quick note"
    ]
    
    static let journalExcerpts = [
        "Started the day with a walk. Felt refreshed and ready.",
        "Reviewed my goals. Made good progress this week.",
        "Grateful for the support from the team today.",
        "Sometimes the smallest wins feel the biggest."
    ]
    
    // Insights
    static let insightTitles = [
        "This Week",
        "Mood Pattern",
        "Progress",
        "Reflection"
    ]
    
    static let insightEmojis = ["💭", "📊", "🎯", "🌟"]
    
    static let insightTexts = [
        "Early-week stress followed by calmer evenings.",
        "Your energy peaks in the morning.",
        "You've journaled 5 days in a row!",
        "Gratitude entries correlate with better sleep."
    ]
    
    /// Generate random sample journal entry
    static func randomJournalEntry() -> (String, String, Date) {
        (
            journalTitles.randomElement()!,
            journalExcerpts.randomElement()!,
            [now, yesterday, lastWeek].randomElement()!
        )
    }
    
    /// Generate random insight
    static func randomInsight() -> (title: String, emoji: String, text: String) {
        let index = Int.random(in: 0..<insightTitles.count)
        return (
            insightTitles[index],
            insightEmojis[index],
            insightTexts[index]
        )
    }
}

// MARK: - Preview Macros

/// Use this for button/small component previews
struct SmallPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

/// Use this for card/medium component previews
struct CardPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding()
        .frame(maxWidth: 400)
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Usage Examples

/*
 // EXAMPLE 1: Fast button preview
 #Preview("Button • Light") {
     SmallPreviewContainer {
         PrimaryButton(title: "Tap Me") {}
         PrimaryButton(title: "Loading", isLoading: true) {}
     }
     .useTheme()
 }
 
 // EXAMPLE 2: Card preview with sample data
 #Preview("Card • Dark") {
     CardPreviewContainer {
         let entry = PreviewSamples.randomJournalEntry()
         JournalCard(title: entry.0, excerpt: entry.1, date: entry.2)
     }
     .useTheme()
     .preferredColorScheme(.dark)
 }
 
 // EXAMPLE 3: Minimal preview (fastest)
 #Preview("Icon Button") {
     IconButton(systemImage: "star.fill") {}
         .useTheme()
         .fastPreview()
 }
 */

