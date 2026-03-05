//
//  FABActionKey.swift
//  MeetMemento
//
//  Environment key for FAB (Floating Action Button) actions
//

import SwiftUI

struct FABActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

struct FABVisibilityKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<JournalTopTab>? = nil
}

extension EnvironmentValues {
    var fabAction: (() -> Void)? {
        get { self[FABActionKey.self] }
        set { self[FABActionKey.self] = newValue }
    }

    var fabVisible: Bool {
        get { self[FABVisibilityKey.self] }
        set { self[FABVisibilityKey.self] = newValue }
    }

    var selectedTab: Binding<JournalTopTab>? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}
