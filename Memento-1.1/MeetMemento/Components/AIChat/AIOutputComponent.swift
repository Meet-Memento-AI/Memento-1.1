//
//  AIOutputComponent.swift
//  MeetMemento
//
//  AI output component with markdown support, headings, and citation links
//

import SwiftUI

/// Structured AI output content
public struct AIOutputContent: Hashable, Codable {
    public let heading1: String?
    public let heading2: String?
    public let body: String
    public let citations: [JournalCitation]?
    
    public init(
        heading1: String? = nil,
        heading2: String? = nil,
        body: String,
        citations: [JournalCitation]? = nil
    ) {
        self.heading1 = heading1
        self.heading2 = heading2
        self.body = body
        self.citations = citations
    }
}

public struct AIOutputComponent: View {
    let content: AIOutputContent
    var onCitationsTapped: (() -> Void)?
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init(
        content: AIOutputContent,
        onCitationsTapped: (() -> Void)? = nil
    ) {
        self.content = content
        self.onCitationsTapped = onCitationsTapped
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Citation link (shown if citations exist)
            if let citations = content.citations, !citations.isEmpty {
                citationLink
            }
            
            // Heading 1 (if provided) - Using Manrope
            if let heading1 = content.heading1, !heading1.isEmpty {
                Text(LocalizedStringKey(heading1))
                    .font(.custom("Manrope-Bold", size: 24))
                    .foregroundStyle(GrayScale.gray900)
                    .modifier(type.headingLineSpacingModifier(for: 20))
            }
            
            // Heading 2 (if provided) - Using Manrope
            if let heading2 = content.heading2, !heading2.isEmpty {
                Text(LocalizedStringKey(heading2))
                    .font(.custom("Manrope-Bold", size: 18))
                    .foregroundStyle(GrayScale.gray900)
                    .modifier(type.headingLineSpacingModifier(for: 16))
                    .padding(.top, (content.heading1?.isEmpty == false) ? 4 : 0)
            }
            
            // Body text with full markdown support
            Text(LocalizedStringKey(content.body))
                .font(.custom("Manrope-Regular", size: 14))
                .foregroundStyle(GrayScale.gray700)
                .lineSpacing(4) // 14pt font + 6pt spacing = 20pt line height
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Citation Link
    
    private var citationLink: some View {
        Button {
            onCitationsTapped?()
        } label: {
            HStack(spacing: 6) {
                
                Text("View journal citations")
                    .font(type.bodySmall)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))

            }
            .foregroundStyle(theme.primary)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Previews

#Preview("AI Output with Headings and Citations") {
    AIOutputComponent(
        content: AIOutputContent(
            heading1: "Understanding Your Patterns",
            heading2: "Key Insights",
            body: "Based on your journal entries, I've noticed several patterns. **Work-related stress** appears frequently, especially around deadlines. You've also mentioned *feeling more balanced* after taking walks.",
            citations: [
                JournalCitation(
                    entryId: UUID(),
                    entryTitle: "Morning Thoughts",
                    entryDate: Date(),
                    excerpt: "Work has been stressful this week..."
                )
            ]
        ),
        onCitationsTapped: {
            print("Citations tapped")
        }
    )
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("AI Output with Body Only") {
    AIOutputComponent(
        content: AIOutputContent(
            body: "This is a simple response with **bold text** and *italic text*. You can include `code snippets` and [links](https://example.com)."
        )
    )
    .padding()
    .useTheme()
    .useTypography()
}
