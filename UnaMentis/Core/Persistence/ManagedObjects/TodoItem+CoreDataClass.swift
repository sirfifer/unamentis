// UnaMentis - TodoItem Core Data Class
// Manual NSManagedObject subclass for SPM compatibility
//
// This file enables Core Data entities to work with Swift Package Manager builds.
// The .xcdatamodeld must have codeGenerationType set to "Manual/None".

import Foundation
import CoreData

@objc(TodoItem)
public class TodoItem: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodoItem> {
        return NSFetchRequest<TodoItem>(entityName: "TodoItem")
    }

    // MARK: - Core Attributes

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var typeRaw: String?
    @NSManaged public var statusRaw: String?
    @NSManaged public var priority: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var archivedAt: Date?
    @NSManaged public var dueDate: Date?

    // MARK: - Curriculum Reference Attributes

    @NSManaged public var curriculumId: UUID?
    @NSManaged public var topicId: UUID?
    @NSManaged public var granularity: String?

    // MARK: - Auto-Resume Context Attributes

    @NSManaged public var resumeTopicId: UUID?
    @NSManaged public var resumeSegmentIndex: Int32
    @NSManaged public var resumeConversationContext: Data?

    // MARK: - Learning Target Attributes

    @NSManaged public var suggestedCurriculumIds: [String]?

    // MARK: - Source Tracking Attributes

    @NSManaged public var sourceRaw: String?
    @NSManaged public var sourceSessionId: UUID?

    // MARK: - Computed Properties

    /// Item type (defaults to learningTarget if not set)
    public var itemType: TodoItemType {
        get {
            guard let raw = typeRaw else { return .learningTarget }
            return TodoItemType(rawValue: raw) ?? .learningTarget
        }
        set {
            typeRaw = newValue.rawValue
        }
    }

    /// Item status (defaults to pending if not set)
    public var status: TodoItemStatus {
        get {
            guard let raw = statusRaw else { return .pending }
            return TodoItemStatus(rawValue: raw) ?? .pending
        }
        set {
            statusRaw = newValue.rawValue
            if newValue == .archived && archivedAt == nil {
                archivedAt = Date()
            }
        }
    }

    /// Item source (defaults to manual if not set)
    public var source: TodoItemSource {
        get {
            guard let raw = sourceRaw else { return .manual }
            return TodoItemSource(rawValue: raw) ?? .manual
        }
        set {
            sourceRaw = newValue.rawValue
        }
    }

    /// Whether this item has resume context
    public var hasResumeContext: Bool {
        resumeTopicId != nil && resumeSegmentIndex >= 0
    }

    /// Whether this item is linked to curriculum content
    public var isLinkedToCurriculum: Bool {
        curriculumId != nil || topicId != nil || hasResumeContext
    }

    /// Whether the item is active (not completed or archived)
    public var isActive: Bool {
        status.isActive
    }

    // MARK: - Initialization Helpers

    /// Configure a new TodoItem with required fields
    public func configure(
        title: String,
        type: TodoItemType,
        source: TodoItemSource = .manual,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.itemType = type
        self.source = source
        self.notes = notes
        self.status = .pending
        self.priority = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.resumeSegmentIndex = -1
    }

    /// Configure as a curriculum-linked item
    public func configureCurriculumLink(
        curriculumId: UUID?,
        topicId: UUID? = nil,
        granularity: String? = nil
    ) {
        self.curriculumId = curriculumId
        self.topicId = topicId
        self.granularity = granularity
    }

    /// Configure as an auto-resume item
    public func configureAutoResume(
        topicId: UUID,
        segmentIndex: Int32,
        conversationContext: Data?
    ) {
        self.itemType = .autoResume
        self.source = .autoResume
        self.resumeTopicId = topicId
        self.resumeSegmentIndex = segmentIndex
        self.resumeConversationContext = conversationContext
    }

    /// Update the timestamp when modified
    public func markUpdated() {
        self.updatedAt = Date()
    }
}

// MARK: - Identifiable Conformance

extension TodoItem: Identifiable { }

// NOTE: Do NOT override hash/isEqual on NSManagedObject subclasses!
// Core Data uses these internally for object tracking and faulting.
