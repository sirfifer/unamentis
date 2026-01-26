//
//  KBTeamProfileTests.swift
//  UnaMentisTests
//
//  Tests for KBTeamProfile model.
//

import XCTest
@testable import UnaMentis

final class KBTeamProfileTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsAllProperties() {
        let id = UUID()
        let createdAt = Date()
        let lastUpdatedAt = Date()

        let profile = KBTeamProfile(
            id: id,
            teamCode: "ABC123",
            name: "Test Team",
            region: .colorado,
            members: [],
            domainAssignments: [],
            createdAt: createdAt,
            lastUpdatedAt: lastUpdatedAt,
            isCaptain: true
        )

        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.teamCode, "ABC123")
        XCTAssertEqual(profile.name, "Test Team")
        XCTAssertEqual(profile.region, .colorado)
        XCTAssertTrue(profile.members.isEmpty)
        XCTAssertTrue(profile.domainAssignments.isEmpty)
        XCTAssertEqual(profile.createdAt, createdAt)
        XCTAssertEqual(profile.lastUpdatedAt, lastUpdatedAt)
        XCTAssertTrue(profile.isCaptain)
    }

    func testInit_generatesTeamCode() {
        let profile = KBTeamProfile(name: "Test Team")
        XCTAssertEqual(profile.teamCode.count, 6)
    }

    func testInit_defaultValues() {
        let profile = KBTeamProfile(name: "Test")
        XCTAssertEqual(profile.region, .colorado)
        XCTAssertTrue(profile.members.isEmpty)
        XCTAssertTrue(profile.domainAssignments.isEmpty)
        XCTAssertTrue(profile.isCaptain)
    }

    // MARK: - Team Code Generation Tests

    func testGenerateTeamCode_hasSixCharacters() {
        let code = KBTeamProfile.generateTeamCode()
        XCTAssertEqual(code.count, 6)
    }

    func testGenerateTeamCode_allUppercaseOrDigits() {
        let code = KBTeamProfile.generateTeamCode()
        let validChars = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        for char in code.unicodeScalars {
            XCTAssertTrue(validChars.contains(char))
        }
    }

    func testGenerateTeamCode_excludesConfusingCharacters() {
        // Run multiple times to increase confidence
        for _ in 0..<100 {
            let code = KBTeamProfile.generateTeamCode()
            XCTAssertFalse(code.contains("I"))
            XCTAssertFalse(code.contains("O"))
            XCTAssertFalse(code.contains("0"))
            XCTAssertFalse(code.contains("1"))
        }
    }

    // MARK: - Member Management Tests

    func testActiveMembers_filtersInactive() {
        var profile = KBTeamProfile(name: "Test")
        let active = KBTeamMember(name: "Active", isActive: true)
        let inactive = KBTeamMember(name: "Inactive", isActive: false)

        profile.addMember(active)
        profile.addMember(inactive)

        XCTAssertEqual(profile.activeMembers.count, 1)
        XCTAssertEqual(profile.activeMembers.first?.name, "Active")
    }

    func testAddMember_appendsMember() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "New Member")

        profile.addMember(member)

        XCTAssertEqual(profile.members.count, 1)
        XCTAssertEqual(profile.members.first?.name, "New Member")
    }

    func testAddMember_updatesLastUpdatedAt() {
        var profile = KBTeamProfile(name: "Test")
        let originalDate = profile.lastUpdatedAt

        profile.addMember(KBTeamMember(name: "Member"))

        XCTAssertGreaterThanOrEqual(profile.lastUpdatedAt, originalDate)
    }

    func testRemoveMember_removesMemberById() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "To Remove")
        profile.addMember(member)

        profile.removeMember(id: member.id)

        XCTAssertTrue(profile.members.isEmpty)
    }

    func testRemoveMember_alsoRemovesAssignments() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        XCTAssertEqual(profile.domainAssignments.count, 1)

        profile.removeMember(id: member.id)

        XCTAssertTrue(profile.domainAssignments.isEmpty)
    }

    func testUpdateMember_updatesExisting() {
        var profile = KBTeamProfile(name: "Test")
        var member = KBTeamMember(name: "Original")
        profile.addMember(member)

        member.name = "Updated"
        profile.updateMember(member)

        XCTAssertEqual(profile.members.first?.name, "Updated")
    }

    func testMemberById_findsCorrectMember() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Find Me")
        profile.addMember(member)

        let found = profile.member(id: member.id)
        XCTAssertEqual(found?.name, "Find Me")
    }

    func testMemberById_returnsNilForNonexistent() {
        let profile = KBTeamProfile(name: "Test")
        XCTAssertNil(profile.member(id: UUID()))
    }

    // MARK: - Assignment Tests

    func testAssignmentsForMember_returnsCorrectAssignments() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))
        profile.setAssignment(KBDomainAssignment.secondary(memberId: member.id, domain: .history))

        let assignments = profile.assignments(for: member.id)
        XCTAssertEqual(assignments.count, 2)
    }

    func testAssignmentsForDomain_returnsCorrectAssignments() {
        var profile = KBTeamProfile(name: "Test")
        let member1 = KBTeamMember(name: "Member 1")
        let member2 = KBTeamMember(name: "Member 2")
        profile.addMember(member1)
        profile.addMember(member2)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member1.id, domain: .science))
        profile.setAssignment(KBDomainAssignment.secondary(memberId: member2.id, domain: .science))

        let assignments = profile.assignments(for: .science)
        XCTAssertEqual(assignments.count, 2)
    }

    func testPrimaryAssignee_returnsCorrectMember() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Primary")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        let primary = profile.primaryAssignee(for: .science)
        XCTAssertEqual(primary?.name, "Primary")
    }

    func testSecondaryAssignees_returnsCorrectMembers() {
        var profile = KBTeamProfile(name: "Test")
        let member1 = KBTeamMember(name: "Secondary 1")
        let member2 = KBTeamMember(name: "Secondary 2")
        profile.addMember(member1)
        profile.addMember(member2)
        profile.setAssignment(KBDomainAssignment.secondary(memberId: member1.id, domain: .science))
        profile.setAssignment(KBDomainAssignment.secondary(memberId: member2.id, domain: .science))

        let secondaries = profile.secondaryAssignees(for: .science)
        XCTAssertEqual(secondaries.count, 2)
    }

    func testSetAssignment_updatesMemberDomains() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)

        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        XCTAssertEqual(profile.members.first?.primaryDomain, .science)
    }

    func testRemoveAssignment_removesByMemberAndDomain() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        profile.removeAssignment(memberId: member.id, domain: .science)

        XCTAssertTrue(profile.domainAssignments.isEmpty)
        XCTAssertNil(profile.members.first?.primaryDomain)
    }

    // MARK: - Coverage Analysis Tests

    func testUncoveredDomains_returnsUnassigned() {
        let profile = KBTeamProfile(name: "Test")
        XCTAssertEqual(profile.uncoveredDomains.count, KBDomain.allCases.count)
    }

    func testUncoveredDomains_excludesCovered() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        XCTAssertEqual(profile.uncoveredDomains.count, KBDomain.allCases.count - 1)
        XCTAssertFalse(profile.uncoveredDomains.contains(.science))
    }

    func testCoveredDomains_returnsCovered() {
        var profile = KBTeamProfile(name: "Test")
        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))
        profile.setAssignment(KBDomainAssignment.secondary(memberId: member.id, domain: .mathematics))

        XCTAssertEqual(profile.coveredDomains.count, 2)
        XCTAssertTrue(profile.coveredDomains.contains(.science))
        XCTAssertTrue(profile.coveredDomains.contains(.mathematics))
    }

    func testCoveragePercentage_calculatesCorrectly() {
        var profile = KBTeamProfile(name: "Test")
        XCTAssertEqual(profile.coveragePercentage, 0)

        let member = KBTeamMember(name: "Member")
        profile.addMember(member)
        profile.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        let expected = (1.0 / Double(KBDomain.allCases.count)) * 100
        XCTAssertEqual(profile.coveragePercentage, expected, accuracy: 0.001)
    }

    // MARK: - Codable Tests

    func testCodable_roundTrip() throws {
        var original = KBTeamProfile(name: "Test Team")
        let member = KBTeamMember(name: "Member")
        original.addMember(member)
        original.setAssignment(KBDomainAssignment.primary(memberId: member.id, domain: .science))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KBTeamProfile.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.members.count, 1)
        XCTAssertEqual(decoded.domainAssignments.count, 1)
    }

    // MARK: - Export Package Tests

    func testExportPackage_initialization() {
        let profile = KBTeamProfile(name: "Test")
        let stats = [KBMemberStats(memberId: UUID())]

        let package = KBTeamProfile.ExportPackage(team: profile, memberStats: stats)

        XCTAssertEqual(package.team.name, "Test")
        XCTAssertEqual(package.memberStats?.count, 1)
        XCTAssertNotNil(package.exportedAt)
    }
}
