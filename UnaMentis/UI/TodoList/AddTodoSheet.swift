// UnaMentis - Add Todo Sheet
// Sheet for adding new to-do items
//
// Part of Todo System

import SwiftUI

/// Sheet for adding a new to-do item
struct AddTodoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodoListViewModel

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedType: TodoItemType = .learningTarget
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you want to learn?", text: $title)
                        .textContentType(.none)
                        .autocorrectionDisabled(false)
                        .accessibilityLabel("Title")
                        .accessibilityHint("Enter the title of your learning goal")
                } header: {
                    Text("Title")
                } footer: {
                    Text("Be specific about what you want to learn or accomplish.")
                }

                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(creatableTypes, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Item type")
                    .accessibilityHint("Select the type of to-do item")
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Optional additional details")
                } header: {
                    Text("Notes (Optional)")
                }

                // Type description
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedType.iconName)
                            .font(.title2)
                            .foregroundStyle(typeColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedType.displayName)
                                .font(.headline)
                            Text(typeDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About This Type")
                }
            }
            .navigationTitle("Add To-Do")
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
                    Button("Add") {
                        createItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }

    // MARK: - Creatable Types

    /// Types that can be manually created (excludes auto-resume)
    private var creatableTypes: [TodoItemType] {
        [.learningTarget, .reinforcement, .curriculum, .topic]
    }

    // MARK: - Type Properties

    private var typeColor: Color {
        switch selectedType.colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "indigo": return .indigo
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }

    private var typeDescription: String {
        switch selectedType {
        case .learningTarget:
            return "A general learning goal. The app will suggest matching curricula if available."
        case .reinforcement:
            return "Something you want to review or practice again later."
        case .curriculum:
            return "A full curriculum to study. You can also add curricula from the Curriculum tab."
        case .topic:
            return "A specific topic to learn. You can also add topics from the Curriculum tab."
        case .module:
            return "A module or section within a curriculum."
        case .autoResume:
            return "Resume point created automatically when stopping mid-session."
        }
    }

    // MARK: - Actions

    private func createItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isCreating = true
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await viewModel.createItem(
                title: trimmedTitle,
                type: selectedType,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddTodoSheet(viewModel: TodoListViewModel())
}
