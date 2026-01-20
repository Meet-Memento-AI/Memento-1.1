//
//  Color+Theme.swift
//  MeetMemento
//

import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let primary = Color.blue
    let secondary = Color.gray
    let accent = Color.orange
    let background = Color(.systemBackground)
    let secondaryBackground = Color(.secondarySystemBackground)
    let text = Color(.label)
    let secondaryText = Color(.secondaryLabel)
}

