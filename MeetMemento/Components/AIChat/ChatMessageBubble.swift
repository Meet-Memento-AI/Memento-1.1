//
//  ChatMessageBubble.swift
//  MeetMemento
//
//  Message bubble component for AI Chat interface
//

import SwiftUI

public struct ChatMessageBubble: View {
    let message: ChatMessage
    var onCitationsTapped: (() -> Void)?
    var onRedo: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init(
        message: ChatMessage,
        onCitationsTapped: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil
    ) {
        self.message = message
        self.onCitationsTapped = onCitationsTapped
        self.onRedo = onRedo
    }
    
    public var body: some View {
        if message.isFromUser {
            // User messages: right-aligned with bubble background
            HStack(alignment: .top, spacing: 12) {
                Spacer(minLength: 60)

                VStack(alignment: .trailing, spacing: 4) {
                    messageContent
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                }
            }
        } else {
            // AI messages: full-width, no background container (Claude/ChatGPT style)
            messageContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }    
    // MARK: - Message Content
    
    @ViewBuilder
    private var messageContent: some View {
        if message.isFromUser {
            // User messages: plain text
            Text(message.content)
                .font(type.body1)
                .foregroundStyle(BaseColors.white)
                .lineSpacing(type.bodyLineSpacing)
        } else if let aiContent = message.aiOutputContent {
            // AI messages with structured content (headings, body, citations)
            AIOutputComponent(
                content: aiContent,
                onCitationsTapped: onCitationsTapped,
                onRedo: onRedo
            )
        } else {
            // AI messages: support markdown/rich text (fallback)
            // Using LocalizedStringKey to enable automatic markdown parsing
            Text(LocalizedStringKey(message.content))
                .font(type.body1)
                .foregroundStyle(theme.foreground)
                .lineSpacing(type.bodyLineSpacing)
        }
    }
}

// MARK: - Previews

#Preview("User Message") {
    ChatMessageBubble(
        message: ChatMessage(
            content: "Enter an AI user input here. This will be used as part of component design",
            isFromUser: true
        )
    )
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("AI Message") {
    ChatMessageBubble(
        message: ChatMessage(
            content: "Users can keep submitting responses here and engage directly with the AI.",
            isFromUser: false
        )
    )
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("AI Message with Markdown") {
    ChatMessageBubble(
        message: ChatMessage(
            content: "This is **bold text** and this is *italic text*. You can also include `code` snippets.",
            isFromUser: false
        )
    )
    .padding()
    .useTheme()
    .useTypography()
}
