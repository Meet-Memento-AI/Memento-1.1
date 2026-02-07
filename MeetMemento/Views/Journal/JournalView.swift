//
//  JournalView.swift
//  MeetMemento
//
//  Main journal view with integrated navigation stack and toolbar
//

import SwiftUI

// MARK: - Month Header Position Tracking

struct MonthHeaderPositionEntry: Equatable {
    let monthStart: Date
    let y: CGFloat
}

struct MonthHeaderPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [MonthHeaderPositionEntry] { [] }
    static func reduce(value: inout [MonthHeaderPositionEntry], nextValue: () -> [MonthHeaderPositionEntry]) {
        value.append(contentsOf: nextValue())
    }
}

public struct JournalView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var navigationPath = NavigationPath()

    // Month picker state
    @State private var showMonthPicker = false
    @State private var selectedDate = Date()
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Scroll-based month detection
    @State private var visibleMonthStart: Date? = nil

    // Task for loading data
    @State private var loadingTask: Task<Void, Never>?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.showAccessory) private var showAccessory
    @Environment(\.selectedTab) private var selectedTab

    // MARK: - Computed Properties

    private let monthNames = Calendar.current.monthSymbols

    private var availableMonths: [Date] {
        entryViewModel.entriesByMonth.map { $0.monthStart }.sorted(by: >)
    }

    private var availableYears: [Int] {
        let years = Set(availableMonths.map { Calendar.current.component(.year, from: $0) })
        return Array(years).sorted(by: >)
    }

    private var currentMonthDisplay: String {
        // Since scroll syncs with picker, we always use selectedDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var filteredEntriesByMonth: [MonthGroup] {
        let calendar = Calendar.current
        return entryViewModel.entriesByMonth.filter { monthGroup in
            calendar.isDate(monthGroup.monthStart, equalTo: selectedDate, toGranularity: .month)
        }
    }

    private var availableMonthsForYear: [Int] {
        let calendar = Calendar.current
        let monthsForYear = availableMonths
            .filter { calendar.component(.year, from: $0) == selectedYear }
            .map { calendar.component(.month, from: $0) }
        return Array(Set(monthsForYear)).sorted()
    }

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            YourEntriesView(
                entryViewModel: entryViewModel,
                monthGroups: filteredEntriesByMonth,
                onMonthVisibilityChanged: { monthStart in
                    // Sync scroll position with picker selection
                    selectedDate = monthStart
                    selectedMonth = Calendar.current.component(.month, from: monthStart)
                    selectedYear = Calendar.current.component(.year, from: monthStart)
                    visibleMonthStart = monthStart
                },
                onNavigateToEntry: { route in
                    navigationPath.append(route)
                }
            )
            .background(theme.background.ignoresSafeArea())
            .toolbar {
                // Leading: Calendar/Month button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showMonthPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(type.h5)
                            Text(currentMonthDisplay)
                                .font(type.body2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(theme.foreground)
                    }
                    .accessibilityLabel("Select Month - \(currentMonthDisplay)")
                }
                
                // Leading: Settings button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        navigationPath.append(SettingsRoute.main)
                    } label: {
                        Image(systemName: "person.fill")
                            .font(type.body1)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.foreground)
                    }
                    .accessibilityLabel("person")
                }

                // Trailing: New Entry button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        navigationPath.append(EntryRoute.create)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(type.body1)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.foreground)
                    }
                    .accessibilityLabel("New Journal Entry")
                }
            }
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
                case .detail(let monthLabel, _):
                    InsightsView()
                        .environmentObject(entryViewModel)
                        .navigationTitle(monthLabel)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar(.hidden, for: .tabBar)
                        .environment(\.fabVisible, false)
                }
            }
            .sheet(isPresented: $showMonthPicker) {
                monthPickerSheet
            }
        }
        .onChange(of: navigationPath.count) { _, count in
            // Only update if Journal tab (0) is selected to avoid race condition
            if selectedTab?.wrappedValue == 0 {
                showAccessory?.wrappedValue = (count == 0)
            }
        }
        .onAppear {
            // Only update if Journal tab (0) is selected to avoid race condition
            if selectedTab?.wrappedValue == 0 {
                showAccessory?.wrappedValue = (navigationPath.count == 0)
            }
            loadingTask = Task {
                await entryViewModel.loadEntriesIfNeeded()
                guard !Task.isCancelled else { return }

                let calendar = Calendar.current
                let hasEntriesForCurrentMonth = entryViewModel.entriesByMonth.contains { monthGroup in
                    calendar.isDate(monthGroup.monthStart, equalTo: Date(), toGranularity: .month)
                }

                if !hasEntriesForCurrentMonth, let mostRecent = entryViewModel.entriesByMonth.first {
                    selectedDate = mostRecent.monthStart
                    selectedMonth = calendar.component(.month, from: mostRecent.monthStart)
                    selectedYear = calendar.component(.year, from: mostRecent.monthStart)
                }
            }
        }
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }

    // MARK: - Month Picker Sheet

    private var monthPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(availableMonthsForYear, id: \.self) { month in
                            Text(monthNames[month - 1])
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 200)
                .padding(.vertical, 20)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showMonthPicker = false
                    }
                    .foregroundStyle(theme.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        updateSelectedDate()
                        showMonthPicker = false
                    }
                    .foregroundStyle(theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
        .onAppear {
            selectedMonth = Calendar.current.component(.month, from: selectedDate)
            selectedYear = Calendar.current.component(.year, from: selectedDate)
        }
    }

    private func updateSelectedDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
            visibleMonthStart = newDate  // Keep in sync
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
