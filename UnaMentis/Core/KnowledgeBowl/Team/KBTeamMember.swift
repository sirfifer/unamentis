//
//  KBTeamMember.swift
//  UnaMentis
//
//  Team member model for Knowledge Bowl team management
//

import Foundation

// MARK: - Team Member

/// Represents a member of a Knowledge Bowl team
struct KBTeamMember: Codable, Identifiable, Sendable, Equatable {
    /// Unique identifier for this team member
    let id: UUID

    /// Member's display name
    var name: String

    /// 1-3 character initials for avatar display
    var initials: String

    /// Hex color string for avatar background (e.g., "#3B82F6")
    var avatarColorHex: String

    /// Primary domain assignment (strongest subject)
    var primaryDomain: KBDomain?

    /// Secondary domain assignment (backup subject)
    var secondaryDomain: KBDomain?

    /// Whether the member is currently active on the team
    var isActive: Bool

    /// When the member was added to the team
    let createdAt: Date

    /// Device identifier for syncing (optional, for identifying which device is theirs)
    var deviceId: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        initials: String? = nil,
        avatarColorHex: String = "#3B82F6",
        primaryDomain: KBDomain? = nil,
        secondaryDomain: KBDomain? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        deviceId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.initials = initials ?? Self.generateInitials(from: name)
        self.avatarColorHex = avatarColorHex
        self.primaryDomain = primaryDomain
        self.secondaryDomain = secondaryDomain
        self.isActive = isActive
        self.createdAt = createdAt
        self.deviceId = deviceId
    }

    // MARK: - Helpers

    /// Generate initials from a name (up to 2 characters)
    static func generateInitials(from name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1).uppercased()
            let last = words[1].prefix(1).uppercased()
            return first + last
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    /// Check if this member has any domain assignments
    var hasAssignments: Bool {
        primaryDomain != nil || secondaryDomain != nil
    }

    /// Get all assigned domains
    var assignedDomains: [KBDomain] {
        var domains: [KBDomain] = []
        if let primary = primaryDomain {
            domains.append(primary)
        }
        if let secondary = secondaryDomain {
            domains.append(secondary)
        }
        return domains
    }
}

// MARK: - Preset Colors

extension KBTeamMember {
    /// Preset avatar colors for team members
    static let presetColors: [String] = [
        "#3B82F6", // Blue
        "#EF4444", // Red
        "#22C55E", // Green
        "#F59E0B", // Amber
        "#8B5CF6", // Purple
        "#EC4899", // Pink
        "#06B6D4", // Cyan
        "#F97316", // Orange
        "#6366F1", // Indigo
        "#14B8A6", // Teal
    ]

    /// Get a random preset color
    static func randomColor() -> String {
        presetColors.randomElement() ?? "#3B82F6"
    }
}
