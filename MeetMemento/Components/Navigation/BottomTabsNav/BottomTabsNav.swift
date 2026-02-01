//
//  BottomTabsNav.swift
//  MeetMemento
//
//  Native SwiftUI TabView following Apple HIG
//  Automatically gets Liquid Glass styling in iOS 26+
//

import SwiftUI

/// Root tab view with native TabView implementation
/// Follows Apple's recommended pattern for tab bars
public struct RootTabView: View {
    @State private var selectedTab: BottomTabType = .journal
    
    // Entry view model for managing journal entries
    @StateObject private var entryViewModel = EntryViewModel()
    
    // Navigation paths for each tab
    @State private var journalNavigationPath = NavigationPath()
    @State private var insightsNavigationPath = NavigationPath()
    
    // Callbacks
    let onSettingsTapped: () -> Void
    let onAIChatTapped: () -> Void
    let onNavigateToEntry: (EntryRoute) -> Void
    let onJournalCreate: () -> Void
    
    @Environment(\.theme) private var theme
    @EnvironmentObject var authViewModel: AuthViewModel
    
    public init(
        onSettingsTapped: @escaping () -> Void = {},
        onAIChatTapped: @escaping () -> Void = {},
        onNavigateToEntry: @escaping (EntryRoute) -> Void = { _ in },
        onJournalCreate: @escaping () -> Void = {}
    ) {
        self.onSettingsTapped = onSettingsTapped
        self.onAIChatTapped = onAIChatTapped
        self.onNavigateToEntry = onNavigateToEntry
        self.onJournalCreate = onJournalCreate
    }
    
    public var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26+: Use native Liquid Glass TabView
            TabView(selection: $selectedTab) {
                Tab("Journal", systemImage: "book.closed", value: BottomTabType.journal) {
                    NavigationStack(path: $journalNavigationPath) {
                        JournalTabView(
                            entryViewModel: entryViewModel,
                            onSettingsTapped: onSettingsTapped,
                            onAIChatTapped: onAIChatTapped,
                            onNavigateToEntry: { route in
                                journalNavigationPath.append(route)
                            },
                            onJournalCreate: onJournalCreate
                        )
                        .navigationTitle("Journal")
                        .navigationBarTitleDisplayMode(.large)
                        .navigationDestination(for: EntryRoute.self) { route in
                            entryDestination(for: route)
                        }
                        .toolbar {
                            ToolbarItem(placement: .bottomBar) {
                                Spacer()
                            }
                            ToolbarItem(placement: .bottomBar) {
                                Button {
                                    onJournalCreate()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background {
                                            Circle()
                                                .fill(theme.primary)
                                        }
                                        .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                                }
                                .accessibilityLabel("New Journal")
                                .accessibilityHint("Create a new journal entry")
                            }
                        }
                    }
                }

                Tab("Insights", systemImage: "sparkles", value: BottomTabType.insights) {
                    NavigationStack(path: $insightsNavigationPath) {
                        InsightsTabView(
                            entryViewModel: entryViewModel,
                            onNavigateToEntry: { route in
                                insightsNavigationPath.append(route)
                            },
                            onAIChatTapped: onAIChatTapped
                        )
                        .navigationTitle("Insights")
                        .navigationBarTitleDisplayMode(.large)
                        .navigationDestination(for: EntryRoute.self) { route in
                            entryDestination(for: route)
                        }
                        .toolbar {
                            ToolbarItem(placement: .bottomBar) {
                                Spacer()
                            }
                            ToolbarItem(placement: .bottomBar) {
                                Button {
                                    onJournalCreate()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background {
                                            Circle()
                                                .fill(theme.primary)
                                        }
                                        .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                                }
                                .accessibilityLabel("New Journal")
                                .accessibilityHint("Create a new journal entry")
                            }
                        }
                    }
                }
            }
            .tint(PrimaryScale.primary600)
            .tabViewStyle(.sidebarAdaptable)
            .onChange(of: selectedTab) { oldValue, newValue in
                // Prevent selection of spacer tab
                if newValue == .spacer {
                    selectedTab = oldValue
                }
            }
            .environmentObject(entryViewModel)
            .useTheme()
            .useTypography()
            .onAppear {
                Task {
                    await entryViewModel.loadEntriesIfNeeded()
                }
            }
        } else {
            // iOS 25 and below: Fallback to standard TabView
            TabView(selection: $selectedTab) {
                NavigationStack(path: $journalNavigationPath) {
                    JournalTabView(
                        entryViewModel: entryViewModel,
                        onSettingsTapped: onSettingsTapped,
                        onAIChatTapped: onAIChatTapped,
                        onNavigateToEntry: { route in
                            journalNavigationPath.append(route)
                        },
                        onJournalCreate: onJournalCreate
                    )
                    .navigationTitle("Journal")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: EntryRoute.self) { route in
                        entryDestination(for: route)
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                onJournalCreate()
                            } label: {
                                Label("New Journal", systemImage: "square.and.pencil")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }
                .tag(BottomTabType.journal)

                NavigationStack(path: $insightsNavigationPath) {
                    InsightsTabView(
                        entryViewModel: entryViewModel,
                        onNavigateToEntry: { route in
                            insightsNavigationPath.append(route)
                        },
                        onAIChatTapped: onAIChatTapped
                    )
                    .navigationTitle("Insights")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: EntryRoute.self) { route in
                        entryDestination(for: route)
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                onJournalCreate()
                            } label: {
                                Label("New Journal", systemImage: "square.and.pencil")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(BottomTabType.insights)
            }
            .tint(PrimaryScale.primary600)
            .environmentObject(entryViewModel)
            .useTheme()
            .useTypography()
            .onAppear {
                Task {
                    await entryViewModel.loadEntriesIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    @ViewBuilder
    private func entryDestination(for route: EntryRoute) -> some View {
        switch route {
        case .create:
            AddEntryView(state: .create) { title, text in
                entryViewModel.createEntry(title: title, text: text)
                if selectedTab == .journal {
                    journalNavigationPath.removeLast()
                } else {
                    insightsNavigationPath.removeLast()
                }
            }
        case .createWithTitle(let prefillTitle):
            AddEntryView(state: .createWithTitle(prefillTitle)) { title, text in
                entryViewModel.createEntry(title: title, text: text)
                if selectedTab == .journal {
                    journalNavigationPath.removeLast()
                } else {
                    insightsNavigationPath.removeLast()
                }
            }
        case .edit(let entry):
            AddEntryView(state: .edit(entry)) { title, text in
                var updated = entry
                updated.title = title
                updated.text = text
                entryViewModel.updateEntry(updated)
                if selectedTab == .journal {
                    journalNavigationPath.removeLast()
                } else {
                    insightsNavigationPath.removeLast()
                }
            }
        }
    }
}

// MARK: - Tab Content Views

/// Journal tab content
private struct JournalTabView: View {
    @ObservedObject var entryViewModel: EntryViewModel
    let onSettingsTapped: () -> Void
    let onAIChatTapped: () -> Void
    let onNavigateToEntry: (EntryRoute) -> Void
    let onJournalCreate: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            // Journal entries view
            YourEntriesView(
                entryViewModel: entryViewModel,
                onNavigateToEntry: onNavigateToEntry
            )
            
            // Toolbar buttons for settings and AI chat
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            onAIChatTapped()
                        } label: {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(theme.primary)
                        }
                        
                        Button {
                            onSettingsTapped()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }
                Spacer()
            }
            .zIndex(10)
        }
    }
}

/// Insights tab content
private struct InsightsTabView: View {
    @ObservedObject var entryViewModel: EntryViewModel
    let onNavigateToEntry: (EntryRoute) -> Void
    let onAIChatTapped: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            theme.insightsBackground.ignoresSafeArea()
            
            InsightsView()
                .environmentObject(entryViewModel)
        }
    }
}


// MARK: - Tab Type Enum

public enum BottomTabType: String, CaseIterable, Identifiable, Hashable {
    case journal
    case insights
    case spacer // Invisible spacer tab for layout spacing
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .journal: return "Journal"
        case .insights: return "Insights"
        case .spacer: return "" // Empty title for invisible spacer
        }
    }
    
    public var systemImage: String {
        switch self {
        case .journal: return "book.closed.fill"
        case .insights: return "sparkles"
        case .spacer: return "" // Empty icon for invisible spacer
        }
    }
}

// MARK: - Previews

#Preview("RootTabView • Light") {
    RootTabView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("RootTabView • Dark") {
    RootTabView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}