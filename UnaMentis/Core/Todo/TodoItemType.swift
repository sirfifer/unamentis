// UnaMentis - Todo Item Type
// Types of items that can be added to the to-do list
//
// Part of Todo System

import Foundation

/// Type of item in the to-do list
public enum TodoItemType: String, Codable, Sendable, CaseIterable {
    case curriculum = "curriculum"           // Full curriculum to study
    case module = "module"                   // Module within a curriculum
    case topic = "topic"                     // Specific topic
    case learningTarget = "learning_target"  // User-defined learning goal
    case reinforcement = "reinforcement"     // Captured during voice session for review
    case autoResume = "auto_resume"          // Mid-session resume point

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .curriculum: return "Curriculum"
        case .module: return "Module"
        case .topic: return "Topic"
        case .learningTarget: return "Learning Goal"
        case .reinforcement: return "Review Item"
        case .autoResume: return "Continue Session"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .curriculum: return "book.fill"
        case .module: return "folder.fill"
        case .topic: return "doc.text.fill"
        case .learningTarget: return "target"
        case .reinforcement: return "arrow.triangle.2.circlepath"
        case .autoResume: return "play.circle.fill"
        }
    }

    /// Accessibility-friendly description
    public var accessibilityDescription: String {
        switch self {
        case .curriculum: return "curriculum item"
        case .module: return "module item"
        case .topic: return "topic item"
        case .learningTarget: return "learning goal"
        case .reinforcement: return "review item"
        case .autoResume: return "resume session"
        }
    }

    /// Whether this type links to curriculum content
    public var isLinkedToCurriculum: Bool {
        switch self {
        case .curriculum, .module, .topic, .autoResume:
            return true
        case .learningTarget, .reinforcement:
            return false
        }
    }

    /// Color tint for the item type
    public var colorName: String {
        switch self {
        case .curriculum: return "blue"
        case .module: return "purple"
        case .topic: return "indigo"
        case .learningTarget: return "orange"
        case .reinforcement: return "yellow"
        case .autoResume: return "green"
        }
    }
}
