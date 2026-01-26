//
//  KBDomainAssignmentTests.swift
//  UnaMentisTests
//
//  Tests for KBDomainAssignment and related types.
//

import XCTest
@testable import UnaMentis

// MARK: - KBAssignmentType Tests

final class KBAssignmentTypeTests: XCTestCase {

    func testAllCases_hasThreeTypes() {
        XCTAssertEqual(KBAssignmentType.allCases.count, 3)
    }

    func testRawValues() {
        XCTAssertEqual(KBAssignmentType.primary.rawValue, "primary")
        XCTAssertEqual(KBAssignmentType.secondary.rawValue, "secondary")
        XCTAssertEqual(KBAssignmentType.suggested.rawValue, "suggested")
    }

    func testDisplayName() {
        XCTAssertEqual(KBAssignmentType.primary.displayName, "Primary")
        XCTAssertEqual(KBAssignmentType.secondary.displayName, "Secondary")
        XCTAssertEqual(KBAssignmentType.suggested.displayName, "Suggested")
    }

    func testPriority_primaryIsHighest() {
        XCTAssertLessThan(
            KBAssignmentType.primary.priority,
            KBAssignmentType.secondary.priority
        )
        XCTAssertLessThan(
            KBAssignmentType.secondary.priority,
            KBAssignmentType.suggested.priority
        )
    }

    func testCodable_roundTrip() throws {
        for type in KBAssignmentType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(KBAssignmentType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
}

// MARK: - KBDomainAssignment Tests

final class KBDomainAssignmentTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsAllProperties() {
        let memberId = UUID()
        let assignedAt = Date()

        let assignment = KBDomainAssignment(
            memberId: memberId,
            domain: .science,
            type: .primary,
            confidence: 0.95,
            assignedAt: assignedAt,
            reason: "Test reason"
        )

        XCTAssertEqual(assignment.memberId, memberId)
        XCTAssertEqual(assignment.domain, .science)
        XCTAssertEqual(assignment.type, .primary)
        XCTAssertEqual(assignment.confidence, 0.95)
        XCTAssertEqual(assignment.assignedAt, assignedAt)
        XCTAssertEqual(assignment.reason, "Test reason")
    }

    func testInit_clampsConfidenceToMax() {
        let assignment = KBDomainAssignment(
            memberId: UUID(),
            domain: .science,
            type: .primary,
            confidence: 1.5
        )

        XCTAssertEqual(assignment.confidence, 1.0)
    }

    func testInit_clampsConfidenceToMin() {
        let assignment = KBDomainAssignment(
            memberId: UUID(),
            domain: .science,
            type: .primary,
            confidence: -0.5
        )

        XCTAssertEqual(assignment.confidence, 0.0)
    }

    func testInit_defaultValues() {
        let assignment = KBDomainAssignment(
            memberId: UUID(),
            domain: .mathematics,
            type: .secondary
        )

        XCTAssertEqual(assignment.confidence, 1.0)
        XCTAssertNotNil(assignment.assignedAt)
        XCTAssertNil(assignment.reason)
    }

    // MARK: - ID Tests

    func testId_combinesMemberIdAndDomain() {
        let memberId = UUID()
        let assignment = KBDomainAssignment(
            memberId: memberId,
            domain: .science,
            type: .primary
        )

        let expectedId = "\(memberId.uuidString)-science"
        XCTAssertEqual(assignment.id, expectedId)
    }

    // MARK: - Factory Method Tests

    func testPrimary_createsCorrectAssignment() {
        let memberId = UUID()
        let assignment = KBDomainAssignment.primary(memberId: memberId, domain: .history)

        XCTAssertEqual(assignment.memberId, memberId)
        XCTAssertEqual(assignment.domain, .history)
        XCTAssertEqual(assignment.type, .primary)
        XCTAssertEqual(assignment.confidence, 1.0)
    }

    func testSecondary_createsCorrectAssignment() {
        let memberId = UUID()
        let assignment = KBDomainAssignment.secondary(memberId: memberId, domain: .arts)

        XCTAssertEqual(assignment.memberId, memberId)
        XCTAssertEqual(assignment.domain, .arts)
        XCTAssertEqual(assignment.type, .secondary)
        XCTAssertEqual(assignment.confidence, 1.0)
    }

    func testSuggested_createsCorrectAssignment() {
        let memberId = UUID()
        let assignment = KBDomainAssignment.suggested(
            memberId: memberId,
            domain: .literature,
            confidence: 0.75,
            reason: "High accuracy in recent sessions"
        )

        XCTAssertEqual(assignment.memberId, memberId)
        XCTAssertEqual(assignment.domain, .literature)
        XCTAssertEqual(assignment.type, .suggested)
        XCTAssertEqual(assignment.confidence, 0.75)
        XCTAssertEqual(assignment.reason, "High accuracy in recent sessions")
    }

    // MARK: - Equatable Tests

    func testEquatable_equal() {
        let memberId = UUID()
        let date = Date()

        let assignment1 = KBDomainAssignment(
            memberId: memberId,
            domain: .science,
            type: .primary,
            confidence: 1.0,
            assignedAt: date
        )
        let assignment2 = KBDomainAssignment(
            memberId: memberId,
            domain: .science,
            type: .primary,
            confidence: 1.0,
            assignedAt: date
        )

        XCTAssertEqual(assignment1, assignment2)
    }

    func testEquatable_differentMemberId() {
        let assignment1 = KBDomainAssignment(
            memberId: UUID(),
            domain: .science,
            type: .primary
        )
        let assignment2 = KBDomainAssignment(
            memberId: UUID(),
            domain: .science,
            type: .primary
        )

        XCTAssertNotEqual(assignment1, assignment2)
    }

    func testEquatable_differentDomain() {
        let memberId = UUID()
        let assignment1 = KBDomainAssignment(
            memberId: memberId,
            domain: .science,
            type: .primary
        )
        let assignment2 = KBDomainAssignment(
            memberId: memberId,
            domain: .mathematics,
            type: .primary
        )

        XCTAssertNotEqual(assignment1, assignment2)
    }

    // MARK: - Codable Tests

    func testCodable_roundTrip() throws {
        let original = KBDomainAssignment(
            memberId: UUID(),
            domain: .technology,
            type: .secondary,
            confidence: 0.8,
            reason: "Backup for tech questions"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KBDomainAssignment.self, from: data)

        XCTAssertEqual(decoded.memberId, original.memberId)
        XCTAssertEqual(decoded.domain, original.domain)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.confidence, original.confidence)
        XCTAssertEqual(decoded.reason, original.reason)
    }
}

// MARK: - KBAssignmentSuggestion Tests

final class KBAssignmentSuggestionTests: XCTestCase {

    func testInit_setsAllProperties() {
        let memberId = UUID()

        let suggestion = KBAssignmentSuggestion(
            memberId: memberId,
            memberName: "Test Member",
            domain: .science,
            suggestedType: .primary,
            confidence: 0.85,
            reasoning: "Strong performance",
            hasConflict: true,
            conflictDescription: "Already assigned to another member"
        )

        XCTAssertEqual(suggestion.memberId, memberId)
        XCTAssertEqual(suggestion.memberName, "Test Member")
        XCTAssertEqual(suggestion.domain, .science)
        XCTAssertEqual(suggestion.suggestedType, .primary)
        XCTAssertEqual(suggestion.confidence, 0.85)
        XCTAssertEqual(suggestion.reasoning, "Strong performance")
        XCTAssertTrue(suggestion.hasConflict)
        XCTAssertEqual(suggestion.conflictDescription, "Already assigned to another member")
    }

    func testId_combinesMemberIdAndDomain() {
        let memberId = UUID()

        let suggestion = KBAssignmentSuggestion(
            memberId: memberId,
            memberName: "Test",
            domain: .mathematics,
            suggestedType: .secondary,
            confidence: 0.7,
            reasoning: "Test"
        )

        let expectedId = "\(memberId.uuidString)-mathematics"
        XCTAssertEqual(suggestion.id, expectedId)
    }

    func testHasConflict_defaultsFalse() {
        let suggestion = KBAssignmentSuggestion(
            memberId: UUID(),
            memberName: "Test",
            domain: .history,
            suggestedType: .primary,
            confidence: 0.9,
            reasoning: "Test"
        )

        XCTAssertFalse(suggestion.hasConflict)
        XCTAssertNil(suggestion.conflictDescription)
    }
}
