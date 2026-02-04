// UnaMentis - ReadingChunk Core Data Class
// Manual NSManagedObject subclass for SPM compatibility
//
// Pre-segmented text chunks for low-latency reading playback.
// Chunks are created at import time, not playback time.

import Foundation
import CoreData

@objc(ReadingChunk)
public class ReadingChunk: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingChunk> {
        return NSFetchRequest<ReadingChunk>(entityName: "ReadingChunk")
    }

    // MARK: - Core Attributes

    @NSManaged public var id: UUID?
    @NSManaged public var index: Int32
    @NSManaged public var text: String?
    @NSManaged public var characterOffset: Int64
    @NSManaged public var estimatedDurationSeconds: Float

    // MARK: - Relationships

    @NSManaged public var readingItem: ReadingListItem?

    // MARK: - Computed Properties

    /// Word count for this chunk
    public var wordCount: Int {
        guard let text = text else { return 0 }
        return text.split(separator: " ").count
    }

    /// Character count for this chunk
    public var characterCount: Int {
        text?.count ?? 0
    }

    /// Preview text (first N characters)
    public func preview(maxLength: Int = 100) -> String {
        guard let text = text else { return "" }
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }

    // MARK: - Initialization Helper

    /// Configure a new ReadingChunk with required fields
    public func configure(
        index: Int32,
        text: String,
        characterOffset: Int64,
        estimatedDuration: Float? = nil
    ) {
        self.id = UUID()
        self.index = index
        self.text = text
        self.characterOffset = characterOffset

        // Estimate duration based on word count if not provided
        // Average speaking rate: ~150 words per minute = 2.5 words per second
        if let duration = estimatedDuration {
            self.estimatedDurationSeconds = duration
        } else {
            let words = text.split(separator: " ").count
            self.estimatedDurationSeconds = Float(words) / 2.5
        }
    }
}

// MARK: - Identifiable Conformance

extension ReadingChunk: Identifiable { }

// MARK: - Comparable for Sorting

extension ReadingChunk: Comparable {
    public static func < (lhs: ReadingChunk, rhs: ReadingChunk) -> Bool {
        lhs.index < rhs.index
    }
}

// NOTE: Do NOT override hash/isEqual on NSManagedObject subclasses!
// Core Data uses these internally for object tracking and faulting.
