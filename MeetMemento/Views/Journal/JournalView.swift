//
//  JournalView.swift
//  MeetMemento
//
//  Main journal view with integrated navigation stack and toolbar
//

import SwiftUI

public struct JournalView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var navigationPath = NavigationPath()

    @Environment(\.theme) private var theme

    // Current month for calendar button
    private var currentMonthShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    private var currentMonthFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            YourEntriesView(
                entryViewModel: entryViewModel,
                onNavigateToEntry: { route in
                    navigationPath.append(route)
                }
            )
            .background(theme.background.ignoresSafeArea())
            .toolbar {
                // Leading: Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        navigationPath.append(SettingsRoute.main)
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(theme.foreground)
                    }
                    .accessibilityLabel("Settings")
                }

                // Trailing: AI Chat button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        navigationPath.append(AIChatRoute.main)
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(theme.foreground)
                }
                .accessibilityLabel("AI Chat")
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard navigationPath.isEmpty else { return }
                        guard value.translation.width > 60,
                              value.translation.width > abs(value.translation.height),
                              value.startLocation.x < 80 else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        navigationPath.append(AIChatRoute.main)
                    }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: EntryRoute.self) { route in
                entryDestination(for: route)
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                settingsDestination(for: route)
            }
            .navigationDestination(for: AIChatRoute.self) { route in
                switch route {
                case .main:
                    AIChatView()
                        .toolbar(.hidden, for: .tabBar)
                        .environment(\.fabVisible, false)
                }
            }
            .navigationDestination(for: MonthInsightRoute.self) { route in
                switch route {
                case .detail(let monthLabel, let entryCount):
                    InsightsView()
                        .environmentObject(entryViewModel)
                        .navigationTitle(monthLabel)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar(.hidden, for: .tabBar)
                        .environment(\.fabVisible, false)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if navigationPath.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    createEntry()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background { Circle().fill(theme.primary) }
                        .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .accessibilityLabel("New Journal Entry")
                .accessibilityHint("Create a new journal entry")
                .padding(.trailing, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                await entryViewModel.loadEntriesIfNeeded()
            }
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func entryDestination(for route: EntryRoute) -> some View {
        switch route {
        case .create:
            AddEntryView(state: .create) { title, text in
                entryViewModel.createEntry(title: title, text: text)
                navigationPath.removeLast()
            }
            .toolbar(.hidden, for: .tabBar)
            .environment(\.fabVisible, false)
        case .createWithTitle(let prefillTitle):
            AddEntryView(state: .createWithTitle(prefillTitle)) { title, text in
                entryViewModel.createEntry(title: title, text: text)
                navigationPath.removeLast()
            }
            .toolbar(.hidden, for: .tabBar)
            .environment(\.fabVisible, false)
        case .edit(let entry):
            AddEntryView(state: .edit(entry)) { title, text in
                var updated = entry
                updated.title = title
                updated.text = text
                entryViewModel.updateEntry(updated)
                navigationPath.removeLast()
            }
            .toolbar(.hidden, for: .tabBar)
            .environment(\.fabVisible, false)
        }
    }

    @ViewBuilder
    private func settingsDestination(for route: SettingsRoute) -> some View {
        switch route {
        case .main:
            SettingsView()
                .environmentObject(entryViewModel)
                .environmentObject(authViewModel)
                .toolbar(.hidden, for: .tabBar)
                .environment(\.fabVisible, false)
        case .profile:
            ProfileSettingsView()
                .toolbar(.hidden, for: .tabBar)
                .environment(\.fabVisible, false)
        case .appearance:
            AppearanceSettingsView()
                .toolbar(.hidden, for: .tabBar)
                .environment(\.fabVisible, false)
        case .about:
            AboutSettingsView()
                .toolbar(.hidden, for: .tabBar)
                .environment(\.fabVisible, false)
        }
    }

    // MARK: - Actions

    private func createEntry() {
        navigationPath.append(EntryRoute.create)
    }
}

// MARK: - Previews

#Preview("Journal • Empty") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @StateObject var authViewModel = AuthViewModel()

    JournalView()
        .environmentObject(entryViewModel)
        .environmentObject(authViewModel)
        .onAppear {
            entryViewModel.entries = []
        }
        .useTheme()
        .useTypography()
}

#Preview("Journal • With Entries") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @StateObject var authViewModel = AuthViewModel()

    JournalView()
        .environmentObject(entryViewModel)
        .environmentObject(authViewModel)
        .onAppear {
            entryViewModel.loadMockEntries()
        }
        .useTheme()
        .useTypography()
}
