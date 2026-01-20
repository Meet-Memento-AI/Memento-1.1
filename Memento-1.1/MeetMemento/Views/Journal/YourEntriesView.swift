//
//  YourEntriesView.swift
//  MeetMemento
//
//  "Your Entries" tab - displays journal entries grouped by month
//

import SwiftUI

struct YourEntriesView: View {
    @ObservedObject var entryViewModel: EntryViewModel
    @State private var showDeleteConfirmation: Bool = false
    @State private var entryToDelete: Entry?

    let onNavigateToEntry: (EntryRoute) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    init(
        entryViewModel: EntryViewModel,
        onNavigateToEntry: @escaping (EntryRoute) -> Void
    ) {
        self.entryViewModel = entryViewModel
        self.onNavigateToEntry = onNavigateToEntry
    }

    var body: some View {
        Group {
            if entryViewModel.isLoading && entryViewModel.entries.isEmpty {
                // Loading state (only show spinner if no cached entries)
                loadingState
            } else if let errorMessage = entryViewModel.errorMessage, entryViewModel.entries.isEmpty {
                // Error state (only show if no cached entries)
                errorState(message: errorMessage)
            } else if entryViewModel.entries.isEmpty {
                // Empty state
                emptyState
            } else {
                // Content with entries grouped by month
                entriesList
            }
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showDeleteConfirmation,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                entryViewModel.deleteEntry(id: entry.id)
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Subviews

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(theme.primary)
                .scaleEffect(1.2)
            Text("Loading your entries...")
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
            Spacer()
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .headerGradient()
            Text("Failed to load entries")
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(GrayScale.gray900)
            Text(message)
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task {
                    await entryViewModel.loadEntries()
                }
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 36))
                .foregroundStyle(PrimaryScale.primary700)

            Text("No journal entries yet")
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(GrayScale.gray900)

            Text("Start writing your first entry to see it here.")
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 32, pinnedViews: []) {
                // Show error banner if there's an error (but we have cached entries)
                if let errorMessage = entryViewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(theme.destructive)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sync Error")
                                .font(type.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(theme.foreground)
                            Text(errorMessage)
                                .font(type.body)
                                .foregroundStyle(theme.mutedForeground)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(theme.destructive.opacity(0.1))
                    .cornerRadius(8)
                }

                // Month groups - entries organized by month
                ForEach(entryViewModel.entriesByMonth) { monthGroup in
                    VStack(alignment: .leading, spacing: 8) {
                        // Month header
                        HStack {
                            Text(monthGroup.monthLabel)
                                .font(type.h4)
                                .foregroundStyle(theme.foreground)

                            Spacer()

                            Text("\(monthGroup.entryCount) \(monthGroup.entryCount == 1 ? "entry" : "entries")")
                                .font(type.body)
                                .foregroundStyle(theme.mutedForeground)
                        }
                        .padding(.horizontal, 4)

                        // Entries for this month
                        VStack(spacing: 16) {
                            ForEach(monthGroup.entries) { entry in
                                JournalCard(
                                    title: entry.displayTitle,
                                    excerpt: entry.excerpt,
                                    date: entry.createdAt,
                                    onTap: {
                                        onNavigateToEntry(.edit(entry))
                                    },
                                    onEditTapped: {
                                        onNavigateToEntry(.edit(entry))
                                    },
                                    onDeleteTapped: {
                                        entryToDelete = entry
                                        showDeleteConfirmation = true
                                    }
                                )
                                .frame(maxWidth: .infinity) // Stretch to full width
                                .id(entry.id) // Explicit ID for better diffing
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 108) // 80px header + 28px spacing
            .padding(.bottom, 20) // Bottom padding for scrolling
        }
        .refreshable {
            // Pull-to-refresh - force reload even if already loaded
            await entryViewModel.refreshEntries()
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    YourEntriesView(
        entryViewModel: viewModel,
        onNavigateToEntry: { _ in }
    )
    .onAppear {
        viewModel.entries = []
    }
    .useTheme()
    .useTypography()
}

#Preview("With Entries") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    YourEntriesView(
        entryViewModel: viewModel,
        onNavigateToEntry: { _ in }
    )
    .onAppear {
        viewModel.loadMockEntries()
    }
    .useTheme()
    .useTypography()
}
