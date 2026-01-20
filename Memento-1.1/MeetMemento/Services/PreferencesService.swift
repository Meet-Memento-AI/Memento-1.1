//
//  PreferencesService.swift
//  MeetMemento
//
//  Minimal preferences stub (UI boilerplate).
//

import Foundation

/// Stub preferences service for theme management
class PreferencesService {
    static let shared = PreferencesService()

    var themePreference: AppThemePreference {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "themePreference") ?? "system"
            return AppThemePreference(rawValue: rawValue) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "themePreference")
        }
    }

    private init() {}
}
