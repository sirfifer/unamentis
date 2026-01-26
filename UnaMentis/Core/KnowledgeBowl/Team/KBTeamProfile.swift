//
//  KBTeamProfile.swift
//  UnaMentis
//
//  Team profile model for Knowledge Bowl team management
//

import Foundation

// MARK: - Team Profile

/// Represents a Knowledge Bowl team with members and assignments
struct KBTeamProfile: Codable, Identifiable, Sendable, Equatable {
    /// Unique identifier for this team
    let id: UUID

    /// Short code for team sharing (6 alphanumeric characters)
    var teamCode: String

    /// Team display name
    var name: String

    /// Regional competition rules this team follows
    var region: KBRegion

    /// Team members
    var members: [KBTeamMember]

    /// Domain assignments for all members
    var domainAssignments: [KBDomainAssignment]

    /// When the team was created
    let createdAt: Date

    /// Last modification timestamp
    var lastUpdatedAt: Date

    /// Whether this device is the team captain (source of truth for local mode)
    var isCaptain: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        teamCode: String? = nil,
        name: String,
        region: KBRegion = .colorado,
        members: [KBTeamMember] = [],
        domainAssignments: [KBDomainAssignment] = [],
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isCaptain: Bool = true
    ) {
        self.id = id
        self.teamCode = teamCode ?? Self.generateTeamCode()
        self.name = name
        self.region = region
        self.members = members
        self.domainAssignments = domainAssignments
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isCaptain = isCaptain
    }

    // MARK: - Team Code Generation

    /// Generate a random 6-character team code
    static func generateTeamCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes confusing chars: I, O, 0, 1
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    // MARK: - Member Management

    /// Get active members only
    var activeMembers: [KBTeamMember] {
        members.filter { $0.isActive }
    }

    /// Add a new member to the team
    mutating func addMember(_ member: KBTeamMember) {
        members.append(member)
        lastUpdatedAt = Date()
    }

    /// Remove a member from the team
    mutating func removeMember(id: UUID) {
        members.removeAll { $0.id == id }
        domainAssignments.removeAll { $0.memberId == id }
        lastUpdatedAt = Date()
    }

    /// Update a member's information
    mutating func updateMember(_ member: KBTeamMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            lastUpdatedAt = Date()
        }
    }

    /// Get a member by ID
    func member(id: UUID) -> KBTeamMember? {
        members.first { $0.id == id }
    }

    // MARK: - Domain Assignment

    /// Get assignments for a specific member
    func assignments(for memberId: UUID) -> [KBDomainAssignment] {
        domainAssignments.filter { $0.memberId == memberId }
    }

    /// Get assignments for a specific domain
    func assignments(for domain: KBDomain) -> [KBDomainAssignment] {
        domainAssignments.filter { $0.domain == domain }
    }

    /// Get the primary assignee for a domain
    func primaryAssignee(for domain: KBDomain) -> KBTeamMember? {
        guard let assignment = domainAssignments.first(where: {
            $0.domain == domain && $0.type == .primary
        }) else { return nil }
        return member(id: assignment.memberId)
    }

    /// Get secondary assignees for a domain
    func secondaryAssignees(for domain: KBDomain) -> [KBTeamMember] {
        let assignments = domainAssignments.filter {
            $0.domain == domain && $0.type == .secondary
        }
        return assignments.compactMap { member(id: $0.memberId) }
    }

    /// Add or update a domain assignment
    mutating func setAssignment(_ assignment: KBDomainAssignment) {
        // Remove existing assignment for same member+domain
        domainAssignments.removeAll {
            $0.memberId == assignment.memberId && $0.domain == assignment.domain
        }
        domainAssignments.append(assignment)

        // Also update the member's domain fields for quick access
        if let memberIndex = members.firstIndex(where: { $0.id == assignment.memberId }) {
            switch assignment.type {
            case .primary:
                members[memberIndex].primaryDomain = assignment.domain
            case .secondary:
                members[memberIndex].secondaryDomain = assignment.domain
            case .suggested:
                break // Don't auto-apply suggestions
            }
        }

        lastUpdatedAt = Date()
    }

    /// Remove an assignment
    mutating func removeAssignment(memberId: UUID, domain: KBDomain) {
        domainAssignments.removeAll {
            $0.memberId == memberId && $0.domain == domain
        }

        // Update member's domain fields
        if let memberIndex = members.firstIndex(where: { $0.id == memberId }) {
            if members[memberIndex].primaryDomain == domain {
                members[memberIndex].primaryDomain = nil
            }
            if members[memberIndex].secondaryDomain == domain {
                members[memberIndex].secondaryDomain = nil
            }
        }

        lastUpdatedAt = Date()
    }

    // MARK: - Coverage Analysis

    /// Domains that have no primary assignee
    var uncoveredDomains: [KBDomain] {
        KBDomain.allCases.filter { domain in
            !domainAssignments.contains { $0.domain == domain && $0.type == .primary }
        }
    }

    /// Domains that are covered (have at least one assignee)
    var coveredDomains: [KBDomain] {
        Set(domainAssignments.map(\.domain)).sorted { $0.weight > $1.weight }
    }

    /// Coverage percentage (0-100)
    var coveragePercentage: Double {
        let covered = Double(coveredDomains.count)
        let total = Double(KBDomain.allCases.count)
        return (covered / total) * 100
    }
}

// MARK: - Export/Import

extension KBTeamProfile {
    /// Export team data for sharing
    struct ExportPackage: Codable {
        let version: Int = 1
        let exportedAt: Date
        let team: KBTeamProfile
        let memberStats: [KBMemberStats]?

        init(team: KBTeamProfile, memberStats: [KBMemberStats]? = nil) {
            self.exportedAt = Date()
            self.team = team
            self.memberStats = memberStats
        }
    }
}
