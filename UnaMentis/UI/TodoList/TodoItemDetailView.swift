// UnaMentis - Todo Item Detail View
// Detail view for viewing and editing a to-do item
//
// Part of Todo System

import SwiftUI

/// Detail view for viewing and editing a to-do item
struct TodoItemDetailView: View {
    let item: TodoItem
    @ObservedObject var viewModel: TodoListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            Form {
                // Status Section
                Section {
                    HStack {
                        Label(item.status.displayName, systemImage: item.status.iconName)
                            .foregroundStyle(statusColor)
                        Spacer()
                        TypeBadge(type: item.itemType)
                    }
                }

                // Title Section
                Section {
                    TextField("Title", text: $editedTitle)
                        .onChange(of: editedTitle) { _, _ in
                            hasChanges = true
                        }
                } header: {
                    Text("Title")
                }

                // Notes Section
                Section {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 100)
                        .onChange(of: editedNotes) { _, _ in
                            hasChanges = true
                        }
                } header: {
                    Text("Notes")
                }

                // Metadata Section
                Section("Details") {
                    LabeledContent("Created", value: formatDate(item.createdAt))
                    LabeledContent("Updated", value: formatDate(item.updatedAt))
                    LabeledContent("Source", value: item.source.displayName)

                    if item.hasResumeContext {
                        LabeledContent("Resume Segment", value: "\(item.resumeSegmentIndex)")
                    }

                    if let archivedAt = item.archivedAt {
                        LabeledContent("Archived", value: formatDate(archivedAt))
                    }
                }

                // Curriculum Link Section
                if item.isLinkedToCurriculum {
                    Section("Linked Content") {
                        if let curriculumId = item.curriculumId {
                            LabeledContent("Curriculum ID", value: curriculumId.uuidString.prefix(8) + "...")
                        }
                        if let topicId = item.topicId {
                            LabeledContent("Topic ID", value: topicId.uuidString.prefix(8) + "...")
                        }
                        if let granularity = item.granularity {
                            LabeledContent("Level", value: granularity.capitalized)
                        }
                    }
                }

                // Suggested Curricula Section
                if let suggestions = item.suggestedCurriculumIds, !suggestions.isEmpty {
                    Section("Suggested Curricula") {
                        ForEach(suggestions, id: \.self) { id in
                            Text(id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Actions Section
                Section {
                    if item.status == .pending || item.status == .inProgress {
                        Button {
                            Task {
                                await viewModel.completeItem(item)
                                dismiss()
                            }
                        } label: {
                            Label("Mark as Complete", systemImage: "checkmark.circle")
                        }
                        .foregroundStyle(.green)

                        Button {
                            Task {
                                await viewModel.archiveItem(item)
                                dismiss()
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .foregroundStyle(.purple)
                    }

                    if item.status == .completed || item.status == .archived {
                        Button {
                            Task {
                                await viewModel.restoreItem(item)
                                dismiss()
                            }
                        } label: {
                            Label("Restore to Active", systemImage: "arrow.uturn.backward")
                        }
                        .foregroundStyle(.blue)
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteItem(item)
                            dismiss()
                        }
                    } label: {
                        Label("Delete Permanently", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("To-Do Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                editedTitle = item.title ?? ""
                editedNotes = item.notes ?? ""
            }
        }
    }

    // MARK: - Status Color

    private var statusColor: Color {
        switch item.status {
        case .pending: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .purple
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func saveChanges() {
        guard hasChanges else { return }

        let context = item.managedObjectContext
        item.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.markUpdated()

        do {
            try context?.save()
            dismiss()
        } catch {
            // Error handling would go here
        }
    }
}

// MARK: - Preview

#Preview {
    TodoItemDetailView(item: TodoItem(), viewModel: TodoListViewModel())
}
