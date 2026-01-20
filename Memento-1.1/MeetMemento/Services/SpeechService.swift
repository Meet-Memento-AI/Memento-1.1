//
//  SpeechService.swift
//  MeetMemento
//
//  Minimal speech service stub (UI boilerplate).
//

import Foundation

/// Stub speech service for voice input
class SpeechService: ObservableObject {
    static let shared = SpeechService()

    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var currentDuration: TimeInterval = 0
    @Published var authorizationStatus: AuthorizationStatus = .authorized

    enum AuthorizationStatus {
        case notDetermined, denied, authorized
    }

    enum SpeechError: LocalizedError {
        case notAvailable
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Speech recognition not available"
            case .permissionDenied: return "Microphone permission denied"
            }
        }
    }

    private init() {}

    func requestAuthorization() async -> AuthorizationStatus {
        return .authorized
    }

    func startRecording() async throws {
        isRecording = true
        isProcessing = false
        // Stub: No-op
    }

    func stopRecording() async {
        isRecording = false
        currentDuration = 0
    }
}
