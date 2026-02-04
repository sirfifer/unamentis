// UnaMentis - ReadingBookmark Core Data Class
// Manual NSManagedObject subclass for SPM compatibility
//
// Bookmarks allow users to mark and return to specific positions
// in reading list items.

import Foundation
import CoreData

@objc(ReadingBookmark)
public class ReadingBookmark: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingBookmark> {
        return NSFetchRequest<ReadingBookmark>(entityName: "ReadingBookmark")
    }

    // MARK: - Core Attributes

    @NSManaged public var id: UUID?
    @NSManaged public var chunkIndex: Int32
    @NSManaged public var note: String?
    @NSManaged public var snippetPreview: String?
    @NSManaged public var createdAt: Date?

    // MARK: - Relationships

    @NSManaged public var readingItem: ReadingListItem?

    // MARK: - Computed Properties

    /// Whether this bookmark has a user note
    public var hasNote: Bool {
        guard let note = note else { return false }
        return !note.isEmpty
    }

    /// Display text (note if available, otherwise snippet preview)
    public var displayText: String {
        if let note = note, !note.isEmpty {
            return note
        }
        return snippetPreview ?? "Bookmark"
    }

    /// The chunk this bookmark points to (if still valid)
    public var chunk: ReadingChunk? {
        guard let item = readingItem else { return nil }
        let chunks = item.chunksArray
        let index = Int(chunkIndex)
        guard index >= 0, index < chunks.count else { return nil }
        return chunks[index]
    }

    // MARK: - Initialization Helper

    /// Configure a new ReadingBookmark with required fields
    public func configure(
        chunkIndex: Int32,
        note: String? = nil,
        snippetPreview: String? = nil
    ) {
        self.id = UUID()
        self.chunkIndex = chunkIndex
        self.note = note
        self.snippetPreview = snippetPreview
        self.createdAt = Date()
    }

    /// Create bookmark from a chunk
    public func configure(from chunk: ReadingChunk, note: String? = nil) {
        self.id = UUID()
        self.chunkIndex = chunk.index
        self.note = note
        self.snippetPreview = chunk.preview(maxLength: 80)
        self.createdAt = Date()
    }
}

// MARK: - Identifiable Conformance

extension ReadingBookmark: Identifiable { }

// MARK: - Comparable for Sorting

extension ReadingBookmark: Comparable {
    public static func < (lhs: ReadingBookmark, rhs: ReadingBookmark) -> Bool {
        // Sort by chunk index first, then by creation date
        if lhs.chunkIndex != rhs.chunkIndex {
            return lhs.chunkIndex < rhs.chunkIndex
        }
        guard let lhsDate = lhs.createdAt, let rhsDate = rhs.createdAt else {
            return false
        }
        return lhsDate < rhsDate
    }
}

// NOTE: Do NOT override hash/isEqual on NSManagedObject subclasses!
// Core Data uses these internally for object tracking and faulting.
