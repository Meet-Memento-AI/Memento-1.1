//
//  SecurityService.swift
//  MeetMemento
//
//  Keychain PIN storage and Face ID / Touch ID biometric authentication.
//

import Foundation
import LocalAuthentication
import Security

class SecurityService {
    static let shared = SecurityService()

    private let pinKeychainKey = "com.sebastianmendo.MeetMemento.userPIN"
    private let securityModeKey = "com.sebastianmendo.MeetMemento.securityMode"
    private let lastActivityKey = "com.sebastianmendo.MeetMemento.lastActivityTimestamp"
    private let inactivityTimeoutDays: Double = 14

    enum SecurityMode: String {
        case faceID
        case pin
        case none
    }

    // MARK: - Activity Tracking

    /// Returns the last recorded activity timestamp, or nil if never set.
    var lastActivityTimestamp: Date? {
        get {
            guard let timestamp = UserDefaults.standard.object(forKey: lastActivityKey) as? Date else {
                return nil
            }
            return timestamp
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastActivityKey)
        }
    }

    /// Updates the last activity timestamp to the current time.
    func updateActivityTimestamp() {
        lastActivityTimestamp = Date()
    }

    /// Checks if the user should be auto-logged out due to inactivity (14+ days).
    func shouldAutoLogout() -> Bool {
        guard let lastActivity = lastActivityTimestamp else {
            // No previous activity recorded - user is new or data was cleared
            return false
        }

        let daysSinceActivity = Date().timeIntervalSince(lastActivity) / (60 * 60 * 24)
        return daysSinceActivity >= inactivityTimeoutDays
    }

    /// Clears the activity timestamp (called on sign out).
    func clearActivityTimestamp() {
        UserDefaults.standard.removeObject(forKey: lastActivityKey)
    }

    // MARK: - Security Mode

    /// Returns the stored security mode preference.
    var currentMode: SecurityMode {
        guard let raw = UserDefaults.standard.string(forKey: securityModeKey) else {
            return .none
        }
        return SecurityMode(rawValue: raw) ?? .none
    }

    func setSecurityMode(_ mode: SecurityMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: securityModeKey)
    }

    // MARK: - Biometric Authentication

    /// Checks if biometric authentication (Face ID / Touch ID) is available.
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// The type of biometric available ("Face ID", "Touch ID", or nil).
    var biometricType: String? {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return nil
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return nil
        }
    }

    /// Authenticates the user with biometrics. Returns true on success.
    func authenticateWithBiometrics(reason: String = "Unlock Memento") async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use PIN"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            print("⚠️ [SecurityService] Biometric auth failed: \(error)")
            return false
        }
    }

    // MARK: - Keychain PIN Storage

    /// Saves a PIN to the Keychain. Overwrites any existing PIN.
    func savePIN(_ pin: String) -> Bool {
        let data = Data(pin.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ [SecurityService] Failed to save PIN: \(status)")
        }
        return status == errSecSuccess
    }

    /// Retrieves the stored PIN from the Keychain. Returns nil if not set.
    func getPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Validates a PIN against the stored value.
    func validatePIN(_ pin: String) -> Bool {
        guard let stored = getPIN() else { return false }
        return stored == pin
    }

    /// Removes the stored PIN from the Keychain.
    func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Clears all security settings (PIN + mode + activity timestamp). Used on account deletion.
    func clearAll() {
        deletePIN()
        UserDefaults.standard.removeObject(forKey: securityModeKey)
        clearActivityTimestamp()
    }
}
