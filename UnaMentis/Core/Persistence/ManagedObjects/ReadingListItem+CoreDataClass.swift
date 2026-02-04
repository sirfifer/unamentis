// UnaMentis - ReadingListItem Core Data Class
// Manual NSManagedObject subclass for SPM compatibility
//
// This file enables Core Data entities to work with Swift Package Manager builds.
// The .xcdatamodeld must have codeGenerationType set to "Manual/None".

import Foundation
import CoreData

@objc(ReadingListItem)
public class ReadingListItem: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingListItem> {
        return NSFetchRequest<ReadingListItem>(entityName: "ReadingListItem")
    }

    // MARK: - Core Attributes

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var sourceTypeRaw: String?
    @NSManaged public var statusRaw: String?

    // MARK: - File Attributes

    @NSManaged public var fileURL: URL?
    @NSManaged public var fileHash: String?
    @NSManaged public var fileSizeBytes: Int64

    // MARK: - Progress Attributes

    @NSManaged public var currentChunkIndex: Int32
    @NSManaged public var percentComplete: Float

    // MARK: - Timestamp Attributes

    @NSManaged public var addedAt: Date?
    @NSManaged public var lastReadAt: Date?
    @NSManaged public var completedAt: Date?

    // MARK: - Relationships

    @NSManaged public var chunks: NSOrderedSet?
    @NSManaged public var bookmarks: NSSet?

    // MARK: - Computed Properties

    /// Source type (defaults to pdf if not set)
    public var sourceType: ReadingListSourceType {
        get {
            guard let raw = sourceTypeRaw else { return .pdf }
            return ReadingListSourceType(rawValue: raw) ?? .pdf
        }
        set {
            sourceTypeRaw = newValue.rawValue
        }
    }

    /// Status (defaults to unread if not set)
    public var status: ReadingListStatus {
        get {
            guard let raw = statusRaw else { return .unread }
            return ReadingListStatus(rawValue: raw) ?? .unread
        }
        set {
            statusRaw = newValue.rawValue
            if newValue == .completed && completedAt == nil {
                completedAt = Date()
            }
        }
    }

    /// Array of chunks for easier access
    public var chunksArray: [ReadingChunk] {
        chunks?.array as? [ReadingChunk] ?? []
    }

    /// Array of bookmarks for easier access
    public var bookmarksArray: [ReadingBookmark] {
        (bookmarks?.allObjects as? [ReadingBookmark] ?? []).sorted {
            $0.chunkIndex < $1.chunkIndex
        }
    }

    /// Total number of chunks
    public var totalChunks: Int {
        chunksArray.count
    }

    /// Current chunk being read (if any)
    public var currentChunk: ReadingChunk? {
        let index = Int(currentChunkIndex)
        guard index >= 0, index < chunksArray.count else { return nil }
        return chunksArray[index]
    }

    /// Whether reading has started
    public var hasStartedReading: Bool {
        currentChunkIndex > 0 || status == .inProgress
    }

    /// Estimated total reading time in seconds
    public var estimatedTotalDuration: Float {
        chunksArray.reduce(0) { $0 + $1.estimatedDurationSeconds }
    }

    /// Estimated remaining reading time in seconds
    public var estimatedRemainingDuration: Float {
        guard currentChunkIndex < totalChunks else { return 0 }
        return chunksArray[Int(currentChunkIndex)...].reduce(0) { $0 + $1.estimatedDurationSeconds }
    }

    // MARK: - Initialization Helpers

    /// Configure a new ReadingListItem with required fields
    public func configure(
        title: String,
        sourceType: ReadingListSourceType,
        fileURL: URL? = nil,
        author: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.sourceType = sourceType
        self.fileURL = fileURL
        self.author = author
        self.status = .unread
        self.currentChunkIndex = 0
        self.percentComplete = 0.0
        self.addedAt = Date()
    }

    // MARK: - Progress Management

    /// Update reading position
    public func updatePosition(chunkIndex: Int32) {
        self.currentChunkIndex = chunkIndex
        self.lastReadAt = Date()

        // Update percent complete
        if totalChunks > 0 {
            self.percentComplete = Float(chunkIndex) / Float(totalChunks)
        }

        // Update status if needed
        if status == .unread && chunkIndex > 0 {
            status = .inProgress
        } else if chunkIndex >= Int32(totalChunks) {
            status = .completed
        }
    }

    /// Mark as completed
    public func markCompleted() {
        self.status = .completed
        self.percentComplete = 1.0
        self.completedAt = Date()
    }

    /// Archive the item
    public func archive() {
        self.status = .archived
    }

    /// Reset reading progress
    public func resetProgress() {
        self.currentChunkIndex = 0
        self.percentComplete = 0.0
        self.status = .unread
        self.completedAt = nil
    }
}

// MARK: - Identifiable Conformance

extension ReadingListItem: Identifiable { }

// MARK: - Chunk Management

extension ReadingListItem {

    /// Add a chunk to this reading item
    @objc(addChunksObject:)
    @NSManaged public func addToChunks(_ value: ReadingChunk)

    @objc(removeChunksObject:)
    @NSManaged public func removeFromChunks(_ value: ReadingChunk)

    @objc(addChunks:)
    @NSManaged public func addToChunks(_ values: NSOrderedSet)

    @objc(removeChunks:)
    @NSManaged public func removeFromChunks(_ values: NSOrderedSet)

    /// Add a bookmark to this reading item
    @objc(addBookmarksObject:)
    @NSManaged public func addToBookmarks(_ value: ReadingBookmark)

    @objc(removeBookmarksObject:)
    @NSManaged public func removeFromBookmarks(_ value: ReadingBookmark)
}

// NOTE: Do NOT override hash/isEqual on NSManagedObject subclasses!
// Core Data uses these internally for object tracking and faulting.
