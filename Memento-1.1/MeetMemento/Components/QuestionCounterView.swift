//
//  QuestionCounterView.swift
//  MeetMemento
//
//  Reusable counter component for displaying completed/total questions
//

import SwiftUI

struct QuestionCounterView: View {
    let completed: Int
    let total: Int

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    private var isAllComplete: Bool {
        completed == total && total > 0
    }

    private var iconName: String {
        isAllComplete ? "checkmark.circle.fill" : "circle.dashed"
    }

    private var foregroundColor: Color {
        isAllComplete ? theme.primary : theme.mutedForeground
    }

    private var backgroundColor: Color {
        isAllComplete ? theme.accent.opacity(0.15) : theme.secondary
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .animation(.easeInOut(duration: 0.3), value: isAllComplete)

            Text("\(completed)/\(total)")
                .font(type.bodyBold)
                .foregroundStyle(foregroundColor)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
                .animation(.easeInOut(duration: 0.3), value: isAllComplete)
        )
        .animation(.easeInOut(duration: 0.3), value: completed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(completed) of \(total) questions completed")
    }
}

// MARK: - Previews

#Preview("Not Complete - 0/3") {
    QuestionCounterView(completed: 0, total: 3)
        .padding()
        .useTheme()
        .useTypography()
}

#Preview("Partial - 1/3") {
    QuestionCounterView(completed: 1, total: 3)
        .padding()
        .useTheme()
        .useTypography()
}

#Preview("Almost Done - 2/3") {
    QuestionCounterView(completed: 2, total: 3)
        .padding()
        .useTheme()
        .useTypography()
}

#Preview("All Complete - 3/3") {
    QuestionCounterView(completed: 3, total: 3)
        .padding()
        .useTheme()
        .useTypography()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        QuestionCounterView(completed: 0, total: 3)
        QuestionCounterView(completed: 1, total: 3)
        QuestionCounterView(completed: 2, total: 3)
        QuestionCounterView(completed: 3, total: 3)
    }
    .padding()
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
