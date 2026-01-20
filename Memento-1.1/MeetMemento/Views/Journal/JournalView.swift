//
//  JournalView.swift
//  MeetMemento
//
//  Main journal view with tabs for "Journal" and "Insights"
//

import SwiftUI

public struct JournalView: View {
    @State private var topSelection: JournalTopTab
    @EnvironmentObject var entryViewModel: EntryViewModel

    let onSettingsTapped: () -> Void
    let onAIChatTapped: () -> Void
    let onNavigateToEntry: (EntryRoute) -> Void

    @Environment(\.theme) private var theme

    public init(
        initialTab: JournalTopTab = .yourEntries,
        onSettingsTapped: @escaping () -> Void = {},
        onAIChatTapped: @escaping () -> Void = {},
        onNavigateToEntry: @escaping (EntryRoute) -> Void = { _ in }
    ) {
        _topSelection = State(initialValue: initialTab)
        self.onSettingsTapped = onSettingsTapped
        self.onAIChatTapped = onAIChatTapped
        self.onNavigateToEntry = onNavigateToEntry
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Content area - swipeable between tabs with lazy loading
            TabView(selection: $topSelection) {
                YourEntriesView(
                    entryViewModel: entryViewModel,
                    onNavigateToEntry: onNavigateToEntry
                )
                .tag(JournalTopTab.yourEntries)

                InsightsView()
                    .environmentObject(entryViewModel)
                    .tag(JournalTopTab.digDeeper)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(
                Group {
                    if topSelection == .digDeeper {
                        theme.insightsBackground
                    } else {
                        Color.clear
                    }
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: topSelection)
            )

            // Gradient background (only on Journal tab)
            gradientBackground
                .frame(height: 104)
                .allowsHitTesting(false)
                .opacity(topSelection == .yourEntries ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: topSelection)
                .zIndex(5)

            // Header with tabs and settings button (fixed position)
            Header(
                variant: .tabs,
                selection: $topSelection,
                onSettingsTapped: onSettingsTapped,
                onAIChatTapped: onAIChatTapped
            )
            .background(Color.clear)
            .zIndex(10) // Ensure header stays on top
        }
        .background(
            Group {
                if topSelection == .digDeeper {
                    Color.clear
                } else {
                    theme.background
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: topSelection)
        )
        .onAppear {
            // Load entries when JournalView appears (deferred from app launch for better performance)
            Task {
                await entryViewModel.loadEntriesIfNeeded()
            }
        }
    }

    // MARK: - Gradient Background

    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#EFEFEF"), location: 0),
                .init(color: Color(hex: "#EFEFEF"), location: 0.5388),
                .init(color: Color(hex: "#EFEFEF").opacity(0), location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Previews

#Preview("Journal • Empty") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    JournalView(
        onSettingsTapped: {},
        onNavigateToEntry: { _ in }
    )
    .environmentObject(viewModel)
    .onAppear {
        viewModel.entries = [] // Empty state
    }
    .useTheme()
    .useTypography()
}

#Preview("Journal • With Entries") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    JournalView(
        onSettingsTapped: {},
        onNavigateToEntry: { _ in }
    )
    .environmentObject(viewModel)
    .onAppear {
        viewModel.loadMockEntries() // Load sample data for preview only
    }
    .useTheme()
    .useTypography()
}

#Preview("Insights • With Content") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    JournalView(
        initialTab: .digDeeper,
        onSettingsTapped: {},
        onNavigateToEntry: { _ in }
    )
    .environmentObject(viewModel)
    .onAppear {
        viewModel.loadMockEntries() // Load sample data to show insights content
    }
    .useTheme()
    .useTypography()
}
