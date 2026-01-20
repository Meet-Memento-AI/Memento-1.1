//
//  CitationsBottomSheet.swift
//  MeetMemento
//
//  Bottom sheet showing journal citations referenced in AI responses
//

import SwiftUI

public struct CitationsBottomSheet: View {
    let citations: [JournalCitation]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init(citations: [JournalCitation]) {
        self.citations = citations
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(theme.mutedForeground.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Journal Citations")
                        .font(type.h3)
                        .headerGradient()
                    
                    Text("These journal entries were referenced in the AI response")
                        .font(type.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Citations list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(citations) { citation in
                            CitationCard(citation: citation)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Citation Card

private struct CitationCard: View {
    let citation: JournalCitation
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Entry title and date
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.primary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(citation.entryTitle)
                        .font(type.bodyBold)
                        .foregroundStyle(theme.foreground)
                    
                    Text(formatDate(citation.entryDate))
                        .font(type.captionText)
                        .foregroundStyle(theme.mutedForeground)
                }
            }
            
            // Excerpt
            Text(citation.excerpt)
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
                .lineSpacing(type.bodyLineSpacing)
                .padding(.leading, 32)
        }
        .padding(16)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Citations Bottom Sheet") {
    CitationsBottomSheet(
        citations: [
            JournalCitation(
                entryId: UUID(),
                entryTitle: "Morning Thoughts",
                entryDate: Date().addingTimeInterval(-86400 * 2),
                excerpt: "Work has been stressful this week. I've been feeling overwhelmed with deadlines and meetings. Taking a walk helped clear my mind."
            ),
            JournalCitation(
                entryId: UUID(),
                entryTitle: "Evening Reflection",
                entryDate: Date().addingTimeInterval(-86400 * 5),
                excerpt: "I noticed I feel more balanced after spending time outside. The fresh air and movement seem to reset my perspective on things."
            )
        ]
    )
    .useTheme()
    .useTypography()
}
