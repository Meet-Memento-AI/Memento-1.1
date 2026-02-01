//
//  ContentView.swift
//  MeetMemento
//

//  Main content view that displays the journal with top navigation tabs.
//  - Journal tab: displays user's journal entries
//  - Insights tab: displays AI-generated insights and themes
//

import SwiftUI

private struct PreviewEntryViewModelKey: EnvironmentKey {
    static let defaultValue: EntryViewModel? = nil
}
private struct PreviewInitialTabKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}
extension EnvironmentValues {
    var previewEntryViewModel: EntryViewModel? {
        get { self[PreviewEntryViewModelKey.self] }
        set { self[PreviewEntryViewModelKey.self] = newValue }
    }
    var previewInitialTab: Int? {
        get { self[PreviewInitialTabKey.self] }
        set { self[PreviewInitialTabKey.self] = newValue }
    }
}

public struct ContentView: View {
    /// Single source of truth for tab selection; @State avoids @SceneStorage persistence causing repeated/conflicting updates when switching tabs.
    @State private var selectedTab = 0
    @State private var didSetPreviewTab = false

    @StateObject private var defaultEntryViewModel = EntryViewModel()
    @Environment(\.previewEntryViewModel) private var previewEntryViewModel: EntryViewModel?
    @Environment(\.previewInitialTab) private var previewInitialTab: Int?

    private var entryViewModel: EntryViewModel {
        previewEntryViewModel ?? defaultEntryViewModel
    }

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Tab bar tint: selection-aware for visibility. When Insights is selected, white for contrast on dark purple background; when Journal is selected, follows light/dark behavior.
    private var tabBarTint: Color {
        if selectedTab == 1 {
            return .white
        }
        return colorScheme == .dark ? .white : PrimaryScale.primary900
    }

    public init() {}

    public var body: some View {
        tabViewContent
            .environmentObject(entryViewModel)
            .environment(\.selectedTab, $selectedTab)
            .useTheme()
            .useTypography()
            .onAppear {
                if let tab = previewInitialTab, !didSetPreviewTab {
                    selectedTab = tab
                    didSetPreviewTab = true
                }
            }
    }

    @ViewBuilder
    private var tabViewContent: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                JournalView()
                    .id(0)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }
                    .tag(0)

                insightsTab
                    .id(1)
                    .tabItem {
                        Label("Insights", systemImage: "sparkles")
                    }
                    .tag(1)
            }
            .tint(tabBarTint)
            .tabViewStyle(.sidebarAdaptable)
            .tabBarMinimizeBehavior(.onScrollDown)
        } else if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                JournalView()
                    .id(0)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }
                    .tag(0)

                insightsTab
                    .id(1)
                    .tabItem {
                        Label("Insights", systemImage: "sparkles")
                    }
                    .tag(1)
            }
            .tint(tabBarTint)
            .tabViewStyle(.sidebarAdaptable)
        } else {
            TabView(selection: $selectedTab) {
                JournalView()
                    .id(0)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }
                    .tag(0)

                insightsTab
                    .id(1)
                    .tabItem {
                        Label("Insights", systemImage: "sparkles")
                    }
                    .tag(1)
            }
            .tint(tabBarTint)
        }
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        InsightsView()
    }
}

// MARK: - Previews
#Preview("Light • iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark • iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Insights tab with entries") {
    @Previewable @StateObject var entryViewModel = EntryViewModel.withPreviewEntries()
    ContentView()
        .environment(\.previewEntryViewModel, entryViewModel)
        .environment(\.previewInitialTab, 1)
        .environment(\.previewSkipLoadEntries, true)
        .environmentObject(AuthViewModel())
        .useTheme()
        .useTypography()
}
