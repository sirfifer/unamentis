// UnaMentis - Todo List View Model
// Manages to-do list state for the UI
//
// Part of Todo System

import SwiftUI
import CoreData
import Logging

/// View model for the to-do list view
@MainActor
public class TodoListViewModel: ObservableObject {
    // MARK: - Published State

    @Published var activeItems: [TodoItem] = []
    @Published var completedItems: [TodoItem] = []
    @Published var archivedItems: [TodoItem] = []

    @Published var showAddSheet = false
    @Published var showClearCompletedConfirmation = false
    @Published var selectedFilter: TodoFilter = .active
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let persistence = PersistenceController.shared
    private let logger = Logger(label: "com.unamentis.ui.todolist")
    private var hasLoaded = false
    private var todoManager: TodoManager?

    // MARK: - Initialization

    public init() {
        // Data loading is deferred to loadAsync() called from the view's .task modifier
    }

    // MARK: - Load Operations

    /// Load data asynchronously (call from view's .task modifier)
    public func loadAsync() async {
        logger.info("TodoListViewModel.loadAsync() START")
        guard !hasLoaded else {
            logger.info("TodoListViewModel.loadAsync() SKIPPED - already loaded")
            return
        }
        hasLoaded = true

        // Initialize TodoManager if needed
        if todoManager == nil {
            todoManager = TodoManager(persistenceController: persistence)
            TodoManager.shared = todoManager
        }

        await loadFromCoreDataAsync()
        logger.info("TodoListViewModel.loadAsync() COMPLETE")
    }

    /// Refresh the list (pull-to-refresh)
    public func refresh() async {
        await loadItemsOnMainContext()
    }

    /// Load to-do items from Core Data on the main context
    /// Note: Using main context for UI binding to avoid Sendable issues with NSManagedObject
    private func loadFromCoreDataAsync() async {
        logger.info("loadFromCoreDataAsync() START")
        await loadItemsOnMainContext()
        logger.info("loadFromCoreDataAsync() COMPLETE")
    }

    /// Load items using the main context for proper UI binding
    private func loadItemsOnMainContext() async {
        let context = persistence.viewContext

        do {
            // Fetch active items
            let activeRequest = TodoItem.fetchRequest()
            activeRequest.predicate = NSPredicate(
                format: "statusRaw != %@ AND statusRaw != %@",
                TodoItemStatus.archived.rawValue,
                TodoItemStatus.completed.rawValue
            )
            activeRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true)]
            self.activeItems = try context.fetch(activeRequest)

            // Fetch completed items
            let completedRequest = TodoItem.fetchRequest()
            completedRequest.predicate = NSPredicate(format: "statusRaw == %@", TodoItemStatus.completed.rawValue)
            completedRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            completedRequest.fetchLimit = 50
            self.completedItems = try context.fetch(completedRequest)

            // Fetch archived items
            let archivedRequest = TodoItem.fetchRequest()
            archivedRequest.predicate = NSPredicate(format: "statusRaw == %@", TodoItemStatus.archived.rawValue)
            archivedRequest.sortDescriptors = [NSSortDescriptor(key: "archivedAt", ascending: false)]
            archivedRequest.fetchLimit = 100
            self.archivedItems = try context.fetch(archivedRequest)

            logger.info("loadItemsOnMainContext() loaded \(activeItems.count) active, \(completedItems.count) completed, \(archivedItems.count) archived")
        } catch {
            logger.error("loadItemsOnMainContext() ERROR: \(error)")
            errorMessage = "Failed to load to-do items"
        }
    }

    // MARK: - CRUD Operations

    /// Create a new to-do item
    public func createItem(title: String, type: TodoItemType, notes: String?) async {
        guard let manager = todoManager else {
            errorMessage = "To-do manager not initialized"
            return
        }

        do {
            _ = try await manager.createItem(title: title, type: type, source: .manual, notes: notes)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to create item: \(error)")
            errorMessage = "Failed to create item"
        }
    }

    /// Complete an item
    public func completeItem(_ item: TodoItem) async {
        guard let manager = todoManager else { return }

        do {
            try await manager.completeItem(item)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to complete item: \(error)")
            errorMessage = "Failed to complete item"
        }
    }

    /// Archive an item
    public func archiveItem(_ item: TodoItem) async {
        guard let manager = todoManager else { return }

        do {
            try await manager.archiveItem(item)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to archive item: \(error)")
            errorMessage = "Failed to archive item"
        }
    }

    /// Restore an archived item
    public func restoreItem(_ item: TodoItem) async {
        guard let manager = todoManager else { return }

        do {
            try await manager.restoreItem(item)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to restore item: \(error)")
            errorMessage = "Failed to restore item"
        }
    }

    /// Delete an item permanently
    public func deleteItem(_ item: TodoItem) async {
        guard let manager = todoManager else { return }

        do {
            try await manager.deleteItem(item)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to delete item: \(error)")
            errorMessage = "Failed to delete item"
        }
    }

    /// Delete all completed items
    public func deleteAllCompleted() async {
        guard let manager = todoManager else { return }

        do {
            try await manager.deleteAllCompleted()
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to delete completed items: \(error)")
            errorMessage = "Failed to delete completed items"
        }
    }

    // MARK: - Reordering

    /// Move an item to a new position
    public func moveItem(_ item: TodoItem, to newIndex: Int) async {
        guard let manager = todoManager else { return }

        do {
            try await manager.moveItem(item, to: newIndex)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to move item: \(error)")
        }
    }

    /// Handle drag-and-drop reorder
    public func moveItems(from source: IndexSet, to destination: Int) {
        var items = activeItems
        items.move(fromOffsets: source, toOffset: destination)

        // Update priorities
        Task {
            let orderedIds = items.compactMap { $0.id }
            guard let manager = todoManager else { return }
            do {
                try await manager.reorderItems(orderedIds: orderedIds)
                await loadItemsOnMainContext()
            } catch {
                logger.error("Failed to reorder items: \(error)")
            }
        }
    }

    // MARK: - Status Updates

    /// Toggle item status between pending and in-progress
    public func toggleInProgress(_ item: TodoItem) async {
        guard let manager = todoManager else { return }

        let newStatus: TodoItemStatus = item.status == .inProgress ? .pending : .inProgress

        do {
            try await manager.updateStatus(item: item, status: newStatus)
            await loadItemsOnMainContext()
        } catch {
            logger.error("Failed to update status: \(error)")
        }
    }
}

// MARK: - Filter Enum

public enum TodoFilter: String, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"

    public var iconName: String {
        switch self {
        case .active: return "checklist"
        case .completed: return "checkmark.circle"
        case .archived: return "archivebox"
        }
    }
}
