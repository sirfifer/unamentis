// UnaMentis - Reading List View Model
// ViewModel for the Reading List UI
//
// Part of UI/ReadingList

import Foundation
import SwiftUI
import Combine
import Logging

// MARK: - Reading List Filter

/// Filter options for the reading list
public enum ReadingListFilter: String, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"

    public var displayName: String { rawValue }
}

// MARK: - Reading List View Model

/// View model for the reading list UI
@MainActor
public final class ReadingListViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var activeItems: [ReadingListItem] = []
    @Published public var completedItems: [ReadingListItem] = []
    @Published public var archivedItems: [ReadingListItem] = []
    @Published public var selectedFilter: ReadingListFilter = .active
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showImportSheet: Bool = false
    @Published public var statistics: ReadingListStatistics?

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.readinglist.viewmodel")
    private var readingListManager: ReadingListManager? {
        ReadingListManager.shared
    }

    // MARK: - Initialization

    public init() { }

    // MARK: - Data Loading

    /// Load all reading list items
    public func loadItems() async {
        guard let manager = readingListManager else {
            logger.warning("ReadingListManager not initialized")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Load items by status
            activeItems = try await manager.fetchActiveItems()
            completedItems = try await manager.fetchItems(status: .completed)
            archivedItems = try await manager.fetchItems(status: .archived)
            statistics = try await manager.getStatistics()

            logger.debug("Loaded \(activeItems.count) active, \(completedItems.count) completed, \(archivedItems.count) archived items")
        } catch {
            logger.error("Failed to load reading list items: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh data
    public func refresh() async {
        await loadItems()
    }

    // MARK: - Import Operations

    /// Import a document from a URL
    public func importDocument(from url: URL, title: String? = nil, author: String? = nil) async {
        guard let manager = readingListManager else {
            errorMessage = "Reading list manager not available"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let item = try await manager.importDocument(from: url, title: title, author: author)
            logger.info("Imported document: \(item.title ?? "Unknown")")

            // Reload items
            await loadItems()
        } catch let error as ReadingListError {
            errorMessage = error.localizedDescription
            logger.error("Import failed: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to import document: \(error.localizedDescription)"
            logger.error("Import failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Item Actions

    /// Update reading position for an item
    public func updatePosition(item: ReadingListItem, chunkIndex: Int32) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.updatePosition(item: item, chunkIndex: chunkIndex)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Mark item as completed
    public func completeItem(_ item: ReadingListItem) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.completeItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Archive an item
    public func archiveItem(_ item: ReadingListItem) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.archiveItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reset progress for an item
    public func resetProgress(item: ReadingListItem) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.resetProgress(item: item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Delete an item
    public func deleteItem(_ item: ReadingListItem) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.deleteItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Bookmark Operations

    /// Add a bookmark to an item
    public func addBookmark(to item: ReadingListItem, note: String? = nil) async {
        guard let manager = readingListManager else { return }

        do {
            _ = try await manager.addBookmark(to: item, note: note)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Remove a bookmark
    public func removeBookmark(_ bookmark: ReadingBookmark) async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.removeBookmark(bookmark)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Bulk Operations

    /// Delete all archived items
    public func deleteAllArchived() async {
        guard let manager = readingListManager else { return }

        do {
            try await manager.deleteAllArchived()
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
