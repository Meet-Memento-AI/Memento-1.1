//
//  AuthStatusViewModel.swift
//  MeetMemento
//
//  Minimal stub for auth status (UI boilerplate).
//

import Foundation
import SwiftUI

@MainActor
final class AuthStatusViewModel: ObservableObject {
    @Published var statusText: String = "Signed in"
    @Published var isSignedIn: Bool = true

    init() {
        // Stub: No-op for boilerplate
    }
}
