//
//  ContentView.swift
//  MeetMemento
//

//  Main content view with top pill-based navigation.
//  - Journal tab: displays user's journal entries
//  - Insights tab: displays AI chat interface (inline)
//

import SwiftUI

private struct PreviewEntryViewModelKey: EnvironmentKey {
    static let defaultValue: EntryViewModel? = nil
}
private struct PreviewInitialTabKey: EnvironmentKey {
    static let defaultValue: JournalTopTab? = nil
}
private struct TabBarHiddenKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
private struct ShowAccessoryKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
extension EnvironmentValues {
    var previewEntryViewModel: EntryViewModel? {
        get { self[PreviewEntryViewModelKey.self] }
        set { self[PreviewEntryViewModelKey.self] = newValue }
    }
    var previewInitialTab: JournalTopTab? {
        get { self[PreviewInitialTabKey.self] }
        set { self[PreviewInitialTabKey.self] = newValue }
    }
    var tabBarHidden: Binding<Bool>? {
        get { self[TabBarHiddenKey.self] }
        set { self[TabBarHiddenKey.self] = newValue }
    }
    var showAccessory: Binding<Bool>? {
        get { self[ShowAccessoryKey.self] }
        set { self[ShowAccessoryKey.self] = newValue }
    }
}

// MARK: - Scroll Direction Tracker

/// ViewModifier that tracks scroll direction and updates the tabBarHidden binding.
/// Used for iOS 18 fallback to manually hide/show the tab bar accessory.
/// IMPORTANT: Only activates on iOS 18.x - does nothing on iOS 26+ to avoid interfering with native behavior.
private struct ScrollOffsetModifier: ViewModifier {
    @Binding var tabBarHidden: Bool
    @State private var lastOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @StateObject private var scrollDebouncer = ScrollDebouncer(delay: 0.1)

    private let threshold: CGFloat = 50 // Minimum scroll distance to trigger state change

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+: Native scroll tracking - don't interfere
            content
        } else {
            // iOS 18-25: Manual scroll tracking with debouncing
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollDebouncer.debounce {
                        let delta = value - lastOffset
                        currentOffset = value

                        // Scrolling down (delta < 0) - hide tab bar
                        if delta < -threshold && !tabBarHidden {
                            tabBarHidden = true
                        }
                        // Scrolling up (delta > 0) - show tab bar
                        else if delta > threshold && tabBarHidden {
                            tabBarHidden = false
                        }

                        lastOffset = value
                    }
                }
        }
    }
}


extension View {
    /// Attach to a ScrollView to track scroll direction and toggle tab bar visibility
    func trackScrollDirection(tabBarHidden: Binding<Bool>) -> some View {
        self.modifier(ScrollOffsetModifier(tabBarHidden: tabBarHidden))
    }

    /// Conditionally applies glassEffect only on iOS 26+
    /// Falls back to unchanged view on earlier iOS versions
    @ViewBuilder
    func iOS26GlassEffect(in shape: some Shape = .rect(cornerRadius: 16)) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self
        }
    }
}

public struct ContentView: View {
    /// Selected tab using JournalTopTab enum for top pill navigation
    @State private var selectedTab: JournalTopTab = .yourEntries
    @State private var swipeProgress: CGFloat = 0
    @State private var didSetPreviewTab = false
    @State private var isTabBarHidden = false
    @State private var showAccessory = true
    @State private var showJournalSearch = false

    /// Consolidated navigation path for all routes
    @State private var navigationPath = NavigationPath()

    @StateObject private var defaultEntryViewModel = EntryViewModel()
    @Environment(\.previewEntryViewModel) private var previewEntryViewModel: EntryViewModel?
    @Environment(\.previewInitialTab) private var previewInitialTab: JournalTopTab?

    private var entryViewModel: EntryViewModel {
        previewEntryViewModel ?? defaultEntryViewModel
    }

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                // Main content with swipeable tabs
                // Note: Views handle their own top padding when isEmbedded == true
                TopTabNavContainer(selection: $selectedTab, swipeProgress: $swipeProgress, showTopNav: false) { tab in
                    switch tab {
                    case .yourEntries:
                        JournalView(isEmbedded: true, externalNavigationPath: $navigationPath)
                    case .digDeeper:
                        AIChatView(isEmbedded: true)
                    }
                }

                // Floating header
                VStack {
                    TopNavHeader(
                        selection: $selectedTab,
                        onMenuTapped: {
                            // Navigate to settings (or future menu)
                            navigationPath.append(SettingsRoute.main)
                        },
                        onActionTapped: {
                            // Context-aware action: search for Journal, new entry for Insights
                            if selectedTab == .yourEntries {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showJournalSearch = true
                                }
                            } else {
                                // Create new journal entry from Insights tab
                                navigationPath.append(EntryRoute.create)
                            }
                        }
                    )
                    .padding(.top, safeAreaTop + 8)
                    Spacer()
                }

                // FAB - Journal tab only, creates new entry
                // Animates interactively with swipe progress
                // Hidden completely when swipe progress > 95% to prevent lingering
                if showAccessory && swipeProgress < 0.95 {
                    PositionedNewEntryFAB(swipeProgress: swipeProgress) {
                        navigationPath.append(EntryRoute.create)
                    }
                }
            }
            .ignoresSafeArea(edges: .all)
            .overlay {
                if showJournalSearch {
                    JournalSearchView(isPresented: $showJournalSearch, navigationPath: $navigationPath)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .navigationDestination(for: EntryRoute.self) { route in
                entryDestination(for: route)
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                settingsDestination(for: route)
            }
        }
        .environmentObject(entryViewModel)
        .environment(\.selectedTab, $selectedTab)
        .environment(\.tabBarHidden, $isTabBarHidden)
        .environment(\.showAccessory, $showAccessory)
        .useTheme()
        .useTypography()
        .onAppear {
            if let tab = previewInitialTab, !didSetPreviewTab {
                selectedTab = tab
                didSetPreviewTab = true
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Sync swipeProgress when tab changes via pill tap (fallback for geometry tracking)
            withAnimation(.smooth(duration: 0.3)) {
                swipeProgress = newTab == .yourEntries ? 0 : 1
            }
        }
    }

    // MARK: - Safe Area Helper

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
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
}

// MARK: - Previews
#Preview("Light - iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark - iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Insights tab with entries") {
    @Previewable @StateObject var entryViewModel = EntryViewModel.withPreviewEntries()
    ContentView()
        .environment(\.previewEntryViewModel, entryViewModel)
        .environment(\.previewInitialTab, .digDeeper)
        .environment(\.previewSkipLoadEntries, true)
        .environmentObject(AuthViewModel())
        .useTheme()
        .useTypography()
}
