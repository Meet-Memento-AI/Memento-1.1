//
//  JournalPageView.swift
//  MeetMemento
//
//  View for reading and editing individual journal entries.
//

import SwiftUI

struct JournalPageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @EnvironmentObject var entryViewModel: EntryViewModel

    let entry: Entry
    @State private var editedTitle: String
    @State private var editedText: String
    @State private var isEditing: Bool = false
    @State private var isSaving: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title
        case text
    }
    
    init(entry: Entry) {
        self.entry = entry
        _editedTitle = State(initialValue: entry.title)
        _editedText = State(initialValue: entry.text)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title field
                    titleSection
                    
                    // Text editor
                    textSection
                    
                    // Metadata
                    metadataSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Entry" : "Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            // Revert changes
                            editedTitle = entry.title
                            editedText = entry.text
                            isEditing = false
                            focusedField = nil
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button {
                            saveChanges()
                        } label: {
                            if isSaving {
                                ProgressView().tint(theme.primary)
                            } else {
                                Text("Save").fontWeight(.medium)
                            }
                        }
                        .disabled(isSaving || editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button("Edit") {
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .title
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isEditing {
                // Display mode
                Text(editedTitle.isEmpty ? "Untitled" : editedTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(editedTitle.isEmpty ? theme.mutedForeground : theme.foreground)
            } else {
                // Edit mode
                TextField("", text: $editedTitle, axis: .vertical)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.foreground)
                    .focused($focusedField, equals: .title)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .text
                    }
                    .placeholder(when: editedTitle.isEmpty) {
                        Text("Add a title...")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(theme.mutedForeground.opacity(0.4))
                    }
            }
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isEditing {
                // Display mode
                Text(editedText)
                    .font(.system(size: 17))
                    .lineSpacing(4)
                    .foregroundStyle(theme.foreground)
                    .textSelection(.enabled)
            } else {
                // Edit mode
                ZStack(alignment: .topLeading) {
                    if editedText.isEmpty {
                        Text("Write your thoughts...")
                            .font(.system(size: 17))
                            .lineSpacing(4)
                            .foregroundStyle(theme.mutedForeground.opacity(0.5))
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $editedText)
                        .font(.system(size: 17))
                        .lineSpacing(4)
                        .foregroundStyle(theme.foreground)
                        .focused($focusedField, equals: .text)
                        .textInputAutocapitalization(.sentences)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 300)
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .imageScale(.small)
                    .foregroundStyle(theme.mutedForeground)
                Text("Created: \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.mutedForeground)
            }
            
            if entry.updatedAt != entry.createdAt {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .imageScale(.small)
                        .foregroundStyle(theme.mutedForeground)
                    Text("Updated: \(entry.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.mutedForeground)
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        isSaving = true

        var updatedEntry = entry
        updatedEntry.title = editedTitle
        updatedEntry.text = editedText

        entryViewModel.updateEntry(updatedEntry)

        // Update UI immediately after initiating save
        isSaving = false
        isEditing = false
        focusedField = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Placeholder Helper

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Previews

#Preview("View Mode") {
    JournalPageView(entry: Entry.sampleEntries[0])
        .environmentObject(EntryViewModel())
        .useTheme()
        .useTypography()
}

#Preview("Untitled Entry") {
    JournalPageView(entry: Entry.sampleEntries[2])
        .environmentObject(EntryViewModel())
        .useTheme()
        .useTypography()
}
