// UnaMentis - Todo List View
// Main view for managing to-do items
//
// Part of Todo System

import SwiftUI
import Logging

/// Main to-do list view showing active items with options to view completed/archived
public struct TodoListView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var showingHelp = false
    @State private var editingItem: TodoItem?

    private static let logger = Logger(label: "com.unamentis.ui.todolist.view")

    public init() { }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.selectedFilter {
                case .active:
                    if viewModel.activeItems.isEmpty {
                        EmptyTodoView(filter: .active, onAddTapped: { viewModel.showAddSheet = true })
                    } else {
                        ActiveTodoListView(viewModel: viewModel, onEdit: { editingItem = $0 })
                    }
                case .completed:
                    if viewModel.completedItems.isEmpty {
                        EmptyTodoView(filter: .completed, onAddTapped: nil)
                    } else {
                        CompletedTodoListView(viewModel: viewModel)
                    }
                case .archived:
                    if viewModel.archivedItems.isEmpty {
                        EmptyTodoView(filter: .archived, onAddTapped: nil)
                    } else {
                        ArchivedTodoListView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("To-Do")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BrandLogo(size: .compact)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .accessibilityLabel("To-do help")
                        .accessibilityHint("Learn about managing your learning to-do list")

                        Menu {
                            Picker("Filter", selection: $viewModel.selectedFilter) {
                                ForEach(TodoFilter.allCases, id: \.self) { filter in
                                    Label(filter.rawValue, systemImage: filter.iconName)
                                        .tag(filter)
                                }
                            }

                            if viewModel.selectedFilter == .completed && !viewModel.completedItems.isEmpty {
                                Divider()
                                Button("Clear Completed", role: .destructive) {
                                    viewModel.showClearCompletedConfirmation = true
                                }
                            }
                        } label: {
                            Image(systemName: viewModel.selectedFilter.iconName)
                        }
                        .accessibilityLabel("Filter options")

                        Button {
                            viewModel.showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add to-do item")
                        .accessibilityHint("Add a new learning goal or task")
                    }
                }
            }
            #endif
            .sheet(isPresented: $showingHelp) {
                TodoHelpSheet()
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                AddTodoSheet(viewModel: viewModel)
            }
            .sheet(item: $editingItem) { item in
                TodoItemDetailView(item: item, viewModel: viewModel)
            }
            .confirmationDialog(
                "Clear Completed",
                isPresented: $viewModel.showClearCompletedConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Completed", role: .destructive) {
                    Task {
                        await viewModel.deleteAllCompleted()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all completed items.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                Self.logger.info("TodoListView .task STARTED")
                await viewModel.loadAsync()
                Self.logger.info("TodoListView .task COMPLETED")
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - Active Todo List

struct ActiveTodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    let onEdit: (TodoItem) -> Void

    var body: some View {
        List {
            ForEach(viewModel.activeItems) { item in
                TodoItemRow(item: item, onComplete: {
                    Task { await viewModel.completeItem(item) }
                }, onToggleProgress: {
                    Task { await viewModel.toggleInProgress(item) }
                })
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit(item)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.archiveItem(item) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }

                    Button {
                        Task { await viewModel.completeItem(item) }
                    } label: {
                        Label("Complete", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
            }
            .onMove(perform: viewModel.moveItems)
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .environment(\.editMode, .constant(.active))
    }
}

// MARK: - Completed Todo List

struct CompletedTodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        List {
            ForEach(viewModel.completedItems) { item in
                TodoItemRow(item: item, onComplete: nil, onToggleProgress: nil)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            Task { await viewModel.archiveItem(item) }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.purple)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await viewModel.restoreItem(item) }
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
}

// MARK: - Archived Todo List

struct ArchivedTodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel

    var body: some View {
        List {
            ForEach(viewModel.archivedItems) { item in
                TodoItemRow(item: item, onComplete: nil, onToggleProgress: nil)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await viewModel.restoreItem(item) }
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
}

// MARK: - Empty State

struct EmptyTodoView: View {
    let filter: TodoFilter
    let onAddTapped: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: emptyIcon)
        } description: {
            Text(emptyDescription)
        } actions: {
            if let onAddTapped = onAddTapped {
                Button {
                    onAddTapped()
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .active: return "No To-Do Items"
        case .completed: return "No Completed Items"
        case .archived: return "No Archived Items"
        }
    }

    private var emptyIcon: String {
        switch filter {
        case .active: return "checklist"
        case .completed: return "checkmark.circle"
        case .archived: return "archivebox"
        }
    }

    private var emptyDescription: String {
        switch filter {
        case .active: return "Add learning goals, curricula, or topics to track your progress."
        case .completed: return "Completed items will appear here."
        case .archived: return "Archived items are stored here permanently."
        }
    }
}

// MARK: - Preview

#Preview {
    TodoListView()
}
