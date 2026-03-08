//
//  LockScreenViewModel.swift
//  MeetMemento
//
//  Manages app lock/unlock state separate from authentication state.
//

import Foundation
import SwiftUI

/// Notification posted when the app is unlocked with PIN (for encryption operations)
extension Notification.Name {
    static let didUnlockWithPIN = Notification.Name("didUnlockWithPIN")
}

@MainActor
class LockScreenViewModel: ObservableObject {
    @Published var isLocked: Bool = true
    @Published var isAuthenticating: Bool = false
    @Published var showPINFallback: Bool = false
    @Published var biometricFailureCount: Int = 0

    private let securityService = SecurityService.shared

    /// Whether the lock screen should be shown based on security mode and lock state.
    var shouldShowLockScreen: Bool {
        guard securityService.currentMode != .none else {
            return false
        }
        return isLocked
    }

    /// Whether PIN fallback is available (PIN is set up).
    var hasPINFallback: Bool {
        securityService.getPIN() != nil
    }

    /// The biometric type name for display ("Face ID", "Touch ID", etc.).
    var biometricTypeName: String {
        securityService.biometricType ?? "Face ID"
    }

    /// Whether biometric authentication is available on this device.
    var isBiometricAvailable: Bool {
        securityService.isBiometricAvailable
    }

    /// The current security mode.
    var currentSecurityMode: SecurityService.SecurityMode {
        securityService.currentMode
    }

    // MARK: - Authentication

    /// Triggers biometric authentication (Face ID / Touch ID).
    func authenticateWithBiometrics() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true

        let success = await securityService.authenticateWithBiometrics(
            reason: "Unlock Memento"
        )

        isAuthenticating = false

        if success {
            // After biometric success, retrieve PIN from Keychain for encryption
            if let storedPIN = securityService.getPIN() {
                NotificationCenter.default.post(
                    name: .didUnlockWithPIN,
                    object: nil,
                    userInfo: ["pin": storedPIN]
                )
            }
            unlock()
        } else {
            biometricFailureCount += 1
            // After 3 failures, automatically show PIN fallback if available
            if biometricFailureCount >= 3 && hasPINFallback {
                showPINFallback = true
            }
        }
    }

    /// Validates the entered PIN and posts notification on success for encryption operations.
    func validatePIN(_ pin: String) -> Bool {
        let isValid = securityService.validatePIN(pin)
        if isValid {
            // Post notification with PIN for encryption operations
            NotificationCenter.default.post(
                name: .didUnlockWithPIN,
                object: nil,
                userInfo: ["pin": pin]
            )
            unlock()
        }
        return isValid
    }

    /// Unlocks the app.
    func unlock() {
        isLocked = false
        showPINFallback = false
        biometricFailureCount = 0
    }

    /// Locks the app (called when app backgrounds).
    func lock() {
        guard securityService.currentMode != .none else { return }
        isLocked = true
        showPINFallback = false
        biometricFailureCount = 0  // Reset for clean state on return
    }

    /// Switches to PIN fallback mode.
    func switchToPINFallback() {
        showPINFallback = true
    }

    /// Switches back to biometric mode.
    func switchToBiometric() {
        showPINFallback = false
    }
}
