//
//  KBDomainAssignment.swift
//  UnaMentis
//
//  Domain assignment model for Knowledge Bowl team management
//

import Foundation

// MARK: - Assignment Type

/// Type of domain assignment
enum KBAssignmentType: String, Codable, CaseIterable, Sendable {
    /// Primary responsibility for this domain
    case primary

    /// Secondary/backup responsibility
    case secondary

    /// System-suggested based on performance data
    case suggested

    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .secondary: return "Secondary"
        case .suggested: return "Suggested"
        }
    }

    var priority: Int {
        switch self {
        case .primary: return 1
        case .secondary: return 2
        case .suggested: return 3
        }
    }
}

// MARK: - Domain Assignment

/// Represents a team member's assignment to a specific domain
struct KBDomainAssignment: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this assignment
    var id: String { "\(memberId.uuidString)-\(domain.rawValue)" }

    /// The team member this assignment belongs to
    let memberId: UUID

    /// The assigned domain
    let domain: KBDomain

    /// Type of assignment (primary, secondary, suggested)
    var type: KBAssignmentType

    /// Confidence score for suggested assignments (0.0-1.0)
    /// For manual assignments, this is typically 1.0
    var confidence: Double

    /// When this assignment was created or last updated
    var assignedAt: Date

    /// Reason for the assignment (for suggested assignments)
    var reason: String?

    // MARK: - Initialization

    init(
        memberId: UUID,
        domain: KBDomain,
        type: KBAssignmentType,
        confidence: Double = 1.0,
        assignedAt: Date = Date(),
        reason: String? = nil
    ) {
        self.memberId = memberId
        self.domain = domain
        self.type = type
        self.confidence = min(1.0, max(0.0, confidence))
        self.assignedAt = assignedAt
        self.reason = reason
    }

    // MARK: - Factory Methods

    /// Create a primary assignment
    static func primary(memberId: UUID, domain: KBDomain) -> KBDomainAssignment {
        KBDomainAssignment(memberId: memberId, domain: domain, type: .primary)
    }

    /// Create a secondary assignment
    static func secondary(memberId: UUID, domain: KBDomain) -> KBDomainAssignment {
        KBDomainAssignment(memberId: memberId, domain: domain, type: .secondary)
    }

    /// Create a suggested assignment based on performance
    static func suggested(
        memberId: UUID,
        domain: KBDomain,
        confidence: Double,
        reason: String
    ) -> KBDomainAssignment {
        KBDomainAssignment(
            memberId: memberId,
            domain: domain,
            type: .suggested,
            confidence: confidence,
            reason: reason
        )
    }
}

// MARK: - Assignment Suggestion

/// A suggestion for domain assignment with explanation
struct KBAssignmentSuggestion: Sendable, Identifiable {
    var id: String { "\(memberId.uuidString)-\(domain.rawValue)" }

    let memberId: UUID
    let memberName: String
    let domain: KBDomain
    let suggestedType: KBAssignmentType
    let confidence: Double
    let reasoning: String

    /// Whether this suggestion conflicts with an existing assignment
    var hasConflict: Bool = false
    var conflictDescription: String?
}
