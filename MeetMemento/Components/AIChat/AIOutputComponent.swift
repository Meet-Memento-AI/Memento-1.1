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

    enum CodingKeys: String, CodingKey {
        case heading1
        case heading2
        case body
        case citations
    }

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
    var animate: Bool
    var onCitationsTapped: (() -> Void)?

    @Environment(\.typography) private var type

    @State private var displayedHeading1 = ""
    @State private var displayedHeading2 = ""
    @State private var displayedBody = ""
    @State private var showCitation = false
    @State private var isAnimating = false
    @State private var hasAnimated = false

    // Fast typing speed like ChatGPT (characters per second)
    private let charactersPerSecond: Double = 120

    /// Stable value that changes when content changes; used with onChange to avoid relying on AIOutputContent Equatable synthesis.
    private var contentIdentity: String {
        [
            content.heading1 ?? "",
            content.heading2 ?? "",
            content.body,
            String(content.citations?.count ?? 0)
        ].joined(separator: "\u{0}")
    }

    public init(
        content: AIOutputContent,
        animate: Bool = true,
        onCitationsTapped: (() -> Void)? = nil
    ) {
        self.content = content
        self.animate = animate
        self.onCitationsTapped = onCitationsTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
        
            // Citation link: appears first with a quick, sudden appearance
            if let citations = content.citations, !citations.isEmpty {
                CitationLink(count: citations.count, onTap: onCitationsTapped)
                    .opacity(showCitation ? 1 : 0)
                    .animation(.easeOut(duration: 0.12), value: showCitation)
            }
            
            // Heading 1 (if provided)
            if let heading1 = content.heading1, !heading1.isEmpty {
                if !displayedHeading1.isEmpty || !animate {
                    Text(animate ? displayedHeading1 : heading1)
                        .font(type.h3)
                        .foregroundStyle(GrayScale.gray900)
                        .modifier(type.headingLineSpacingModifier(for: type.size2XL))
                }
            }

            // Heading 2 (if provided)
            if let heading2 = content.heading2, !heading2.isEmpty {
                if !displayedHeading2.isEmpty || !animate {
                    Text(animate ? displayedHeading2 : heading2)
                        .font(type.h4)
                        .foregroundStyle(GrayScale.gray900)
                        .modifier(type.headingLineSpacingModifier(for: type.sizeXL))
                        .padding(.top, (content.heading1?.isEmpty == false) ? 4 : 0)
                }
            }

            // Body text with typewriter effect
            if !displayedBody.isEmpty || !animate {
                Text(LocalizedStringKey(animate ? displayedBody : content.body))
                    .font(type.body1)
                    .foregroundStyle(GrayScale.gray700)
                    .lineSpacing(type.bodyLineSpacing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if animate && !hasAnimated {
                startTypewriterSequence()
            } else if !animate {
                showAllContent()
            }
        }
        .onChange(of: contentIdentity) { _, _ in
            if animate {
                resetAnimation()
                startTypewriterSequence()
            } else {
                showAllContent()
            }
        }
    }

    // MARK: - Animation Helpers

    private func showAllContent() {
        displayedHeading1 = content.heading1 ?? ""
        displayedHeading2 = content.heading2 ?? ""
        displayedBody = content.body
        showCitation = true
        hasAnimated = true
    }

    private func resetAnimation() {
        displayedHeading1 = ""
        displayedHeading2 = ""
        displayedBody = ""
        showCitation = false
        hasAnimated = false
        isAnimating = false
    }

    // MARK: - Typewriter Animation Sequence

    private func startTypewriterSequence() {
        guard !isAnimating else { return }
        isAnimating = true

        // Citation appears first, quick and sudden
        if content.citations != nil, !(content.citations?.isEmpty ?? true) {
            showCitation = true
        }

        let interval = 1.0 / charactersPerSecond
        var totalDelay: Double = 0

        // Phase 1: Heading 1
        if let heading1 = content.heading1, !heading1.isEmpty {
            let characters = Array(heading1)
            for (index, character) in characters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + Double(index) * interval) {
                    displayedHeading1.append(character)
                }
            }
            totalDelay += Double(characters.count) * interval + 0.05
        }

        // Phase 2: Heading 2
        if let heading2 = content.heading2, !heading2.isEmpty {
            let characters = Array(heading2)
            for (index, character) in characters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + Double(index) * interval) {
                    displayedHeading2.append(character)
                }
            }
            totalDelay += Double(characters.count) * interval + 0.05
        }

        // Phase 3: Body
        let bodyCharacters = Array(content.body)
        for (index, character) in bodyCharacters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + Double(index) * interval) {
                displayedBody.append(character)
            }
        }
        totalDelay += Double(bodyCharacters.count) * interval

        // Typewriter complete
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.05) {
            isAnimating = false
            hasAnimated = true
        }
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
