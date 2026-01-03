// UnaMentis - Todo Item Source
// Tracks how a to-do item was created
//
// Part of Todo System

import Foundation

/// Source of how a to-do item was created
public enum TodoItemSource: String, Codable, Sendable, CaseIterable {
    case manual = "manual"               // User manually added via UI
    case voice = "voice"                 // Created via voice command/LLM tool call
    case autoResume = "auto_resume"      // Auto-created when stopping mid-session
    case reinforcement = "reinforcement" // Captured during voice session as review item

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .manual: return "Added Manually"
        case .voice: return "Voice Command"
        case .autoResume: return "Auto-Resume"
        case .reinforcement: return "Session Review"
        }
    }

    /// Accessibility-friendly description
    public var accessibilityDescription: String {
        switch self {
        case .manual: return "added manually"
        case .voice: return "added by voice command"
        case .autoResume: return "added automatically when session stopped"
        case .reinforcement: return "added as review item during session"
        }
    }

    /// SF Symbol icon
    public var iconName: String {
        switch self {
        case .manual: return "hand.tap"
        case .voice: return "waveform"
        case .autoResume: return "arrow.clockwise"
        case .reinforcement: return "quote.bubble"
        }
    }
}
