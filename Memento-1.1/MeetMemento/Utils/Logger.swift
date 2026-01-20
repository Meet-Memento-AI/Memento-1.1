//
//  Logger.swift
//  MeetMemento
//
//  Minimal logging stub (UI boilerplate).
//

import Foundation
import os.log

/// Minimal logger stub for UI boilerplate
struct AppLogger {
    static let general = "general"
    static let network = "network"
    static let persistent = "persistent"

    static func log(_ message: String, category: String = general, type: OSLogType = .default) {
        #if DEBUG
        print("[\(category)] \(message)")
        #endif
    }
}
