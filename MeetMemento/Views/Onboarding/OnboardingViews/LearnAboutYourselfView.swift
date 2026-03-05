//
//  LearnAboutYourselfView.swift
//  MeetMemento
//
//  Onboarding view for collecting initial journal entry about user goals.
//  Styled to match the journalreation experience (AddEntryView).
//

import SwiftUI

public struct LearnAboutYourselfView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    // Use @ObservedObject for singleton to avoid creating duplicate observers
    @ObservedObject private var speechService = SpeechService.shared

    /// Unique identifier for this view's speech session ownership
    private let speechOwnerId = "LearnAboutYourselfView"

    @State private var entryText: String = ""
    @State private var isProcessing: Bool = false
    @State private var showSTTError = false
    @State private var showPermissionDenied = false
    @FocusState private var isFocused: Bool

    // Callback for when user completes this step
    public var onComplete: ((String) -> Void)?

    public init(onComplete: ((String) -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title section — same layout as AddEntryView (title area + body)
                titleSection
                    .padding(.top, 24)

                // Body editor - same style as AddEntryView
                bodyField
                    .padding(.top, 16)

                // Character count indicator
                characterCounter
                    .padding(.top, 12)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(type.body1Bold)
                        .foregroundStyle(theme.foreground)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    completeStep()
                } label: {
                    Image(systemName: "checkmark")
                        .font(type.body1Bold)
                        .foregroundStyle(showCheckmark ? theme.primary : theme.mutedForeground.opacity(0.5))
                }
                .disabled(!showCheckmark)
                .opacity(showCheckmark ? 1.0 : 0.5)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showCheckmark)
                .accessibilityLabel("Save")
                .accessibilityHint(showCheckmark ? "Save and continue" : "Enter at least 100 characters to continue")
            }
        }
        .overlay(alignment: .bottom) {
            microphoneFAB
                .padding(.bottom, 32)
        }
        .onAppear {
            // Auto-focus the text editor after a brief delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                isFocused = true
            }
        }
        .onChange(of: speechService.isRecording) { oldValue, newValue in
            // Only process if this view owns the session
            guard speechService.isOwner(speechOwnerId) else { return }
            if oldValue == true && newValue == false && !speechService.transcribedText.isEmpty {
                insertTranscribedText(speechService.transcribedText)
            }
        }
        .onChange(of: speechService.transcribedText) { _, newText in
            // Only process if this view owns the session
            guard speechService.isOwner(speechOwnerId) else { return }
            if !newText.isEmpty && !speechService.isRecording {
                insertTranscribedText(newText)
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("MeetMemento needs microphone access to transcribe your voice. Enable it in Settings > Privacy > Microphone.")
        }
        .alert("Recording Failed", isPresented: $showSTTError) {
            Button("Try Again") {
                Task {
                    do {
                        try await speechService.startRecording(ownerId: speechOwnerId)
                    } catch {
                        showSTTError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(speechService.errorMessage ?? "Unable to start recording. Please try again.")
        }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What would you like to learn about yourself?")
                .font(type.h3)
                .foregroundStyle(theme.foreground)
        }
    }

    private var bodyField: some View {
        ZStack(alignment: .topLeading) {
            if entryText.isEmpty {
                Text("Share what your goals are with your journals. I'll pay attention to this whenever you journal and we talk.")
                    .font(.system(size: 17))
                    .lineSpacing(3.4)
                    .foregroundStyle(theme.mutedForeground.opacity(0.5))
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $entryText)
                .font(.system(size: 17))
                .lineSpacing(3.4)
                .foregroundStyle(theme.foreground)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 300)
        }
    }

    private var characterCounter: some View {
        HStack {
            Spacer()
            Text("\(characterCount) / 100 min")
                .font(type.caption)
                .foregroundStyle(
                    characterCount >= 100 ? theme.primary :
                    theme.mutedForeground.opacity(0.6)
                )
        }
    }

    // MARK: - Computed Properties

    private var characterCount: Int {
        entryText.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var showCheckmark: Bool {
        characterCount >= 100 && characterCount <= 2000
    }

    private var canProceed: Bool {
        !isProcessing && showCheckmark
    }
    
    private var fabWidth: CGFloat {
        speechService.isRecording ? 120 : 64
    }

    // MARK: - Actions

    private func completeStep() {
        guard canProceed else { return }

        let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Call completion handler
        onComplete?(trimmedText)
    }
    
    private func insertTranscribedText(_ transcribedText: String) {
        let trimmed = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if entryText.isEmpty {
            entryText = trimmed
        } else {
            entryText += "\n\n" + trimmed
        }
        // Clear transcription buffer and release ownership
        speechService.clearTranscription()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isFocused = true
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Microphone FAB
    
    private var microphoneFAB: some View {
        Button {
            // Provide haptic feedback for button tap
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            Task {
                if speechService.isRecording {
                    await speechService.stopRecording()
                } else {
                    do {
                        try await speechService.startRecording(ownerId: speechOwnerId)
                    } catch let error as SpeechService.SpeechError {
                        if case .permissionDenied = error {
                            showPermissionDenied = true
                        } else {
                            showSTTError = true
                        }
                    } catch {
                        showSTTError = true
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)

                // Duration timer appears inside button when recording
                if speechService.isRecording {
                    Text(formatDuration(speechService.currentDuration))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(width: fabWidth, height: 64)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: speechService.isRecording
                                ? [Color.red.opacity(0.8), Color.red]
                                : [theme.fabGradientStart, theme.fabGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: speechService.isRecording)
        .accessibilityLabel(speechService.isRecording ? "Stop recording" : "Start voice recording")
        .accessibilityHint(speechService.isRecording ? "Double-tap to stop and insert text" : "Double-tap to record your voice")
    }
}

// MARK: - Previews

#Preview("Light") {
    LearnAboutYourselfView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LearnAboutYourselfView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
        .preferredColorScheme(.dark)
}

#Preview("With Content") {
    LearnAboutYourselfView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
}
