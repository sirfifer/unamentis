// UnaMentis - Todo Item Status
// Status states for to-do items
//
// Part of Todo System

import Foundation

/// Status of a to-do item
public enum TodoItemStatus: String, Codable, Sendable, CaseIterable {
    case pending = "pending"           // Not yet started
    case inProgress = "in_progress"    // Currently being worked on
    case completed = "completed"       // Finished
    case archived = "archived"         // Archived (kept permanently)

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    /// Accessibility-friendly description
    public var accessibilityDescription: String {
        switch self {
        case .pending: return "not started"
        case .inProgress: return "in progress"
        case .completed: return "completed"
        case .archived: return "archived"
        }
    }

    /// SF Symbol icon for status
    public var iconName: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }

    /// Whether the item is considered active (visible in main list)
    public var isActive: Bool {
        switch self {
        case .pending, .inProgress:
            return true
        case .completed, .archived:
            return false
        }
    }

    /// Whether the item can be resumed/started
    public var canStart: Bool {
        switch self {
        case .pending, .inProgress:
            return true
        case .completed, .archived:
            return false
        }
    }
}
