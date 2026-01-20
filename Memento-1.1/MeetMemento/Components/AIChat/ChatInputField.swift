//
//  ChatInputField.swift
//  MeetMemento
//
//  Input field component for AI Chat interface with send button
//  Matches Claude/ChatGPT style with send button positioned inside input field
//

import SwiftUI

public struct ChatInputField: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        isSending: Bool = false,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.isSending = isSending
        self.onSend = onSend
    }

    @State private var isRecording = false
    
    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // TextField container with white background and fixed 120px min height
            ZStack(alignment: .center) { // Changed to center for wave alignment
                
                if isRecording {
                    // Voice Wave Animation View
                    VoiceWaveView()
                        .frame(height: 24) // Match roughly the line height of text input
                        .padding(.leading, 16)
                        .padding(.trailing, 56)
                        .padding(.vertical, 16)
                        .transition(.opacity)
                } else {
                    // Default Text Input State
                    ZStack(alignment: .topLeading) {
                        // Placeholder Text
                        if text.isEmpty {
                            Text("Chat with Memento")
                                .font(type.input)
                                .foregroundStyle(GrayScale.gray500)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        }
                        
                        // TextField with top-aligned text
                        TextField("", text: $text, axis: .vertical)
                            .font(type.input)
                            .foregroundStyle(theme.foreground)
                            .focused($isFocused)
                            .lineLimit(1...5)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.send)
                            .onSubmit {
                                if isSendButtonEnabled {
                                    onSend()
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.trailing, 100) // Space for mic + send button
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56) // Ensure full width and minimum height consistency
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                    .stroke(theme.border.opacity(0.2), lineWidth: 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isRecording)
            
            // Buttons positioned at bottom right
            HStack(spacing: 16) {
                if isRecording {
                    stopButton
                        .transition(.scale.combined(with: .opacity))
                } else {
                    microphoneButton
                    sendButton
                }
            }
            .padding(.trailing, 8)
            .padding(.bottom, 10) // Align center with single-line text (56/2 - 36/2 = 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Microphone Button
    
    private var microphoneButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isRecording = true
            }
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(GrayScale.gray500)
                .frame(width: 36, height: 36)
                .background(Color.clear)
        }
    }
    
    // MARK: - Stop Button
    
    private var stopButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isRecording = false
            }
        } label: {
            ZStack {
                Image(systemName: "square.fill") // Stop icon
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color.red) // iOS Red style
            )
        }
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            onSend()
        } label: {
            ZStack {
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(
                        isSendButtonEnabled
                            ? PrimaryScale.primary600
                            : theme.muted
                    )
            )
        }
        .disabled(!isSendButtonEnabled || isSending)
        .animation(.easeInOut(duration: 0.2), value: isSendButtonEnabled)
    }
    
    private var isSendButtonEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Voice Wave View (Animation)
private struct VoiceWaveView: View {
    let barCount = 30
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(GrayScale.gray400)
                    .frame(width: 4, height: isAnimating ? CGFloat.random(in: 4...20) : 4) // Reduced max height to fit container
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 0.5...1.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...0.5)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Previews

#Preview("Input Field") {
    @Previewable @State var text = ""
    
    VStack {
        Spacer()
        ChatInputField(text: $text, onSend: {
            print("Send: \(text)")
        })
    }
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1))
}

#Preview("Input Field Recording") {
    @Previewable @State var text = ""
    
    VStack {
        Spacer()
        // Note: Preview won't auto-trigger recording state unless we expose it,
        // but user can interact in preview
        ChatInputField(text: $text, onSend: {})
    }
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1))
}
