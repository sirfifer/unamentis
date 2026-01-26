//
//  KBTeamMemberTests.swift
//  UnaMentisTests
//
//  Tests for KBTeamMember model.
//

import XCTest
@testable import UnaMentis

final class KBTeamMemberTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsAllProperties() {
        let id = UUID()
        let createdAt = Date()

        let member = KBTeamMember(
            id: id,
            name: "Test Member",
            initials: "TM",
            avatarColorHex: "#FF5733",
            primaryDomain: .science,
            secondaryDomain: .mathematics,
            isActive: true,
            createdAt: createdAt,
            deviceId: "device-123"
        )

        XCTAssertEqual(member.id, id)
        XCTAssertEqual(member.name, "Test Member")
        XCTAssertEqual(member.initials, "TM")
        XCTAssertEqual(member.avatarColorHex, "#FF5733")
        XCTAssertEqual(member.primaryDomain, .science)
        XCTAssertEqual(member.secondaryDomain, .mathematics)
        XCTAssertTrue(member.isActive)
        XCTAssertEqual(member.createdAt, createdAt)
        XCTAssertEqual(member.deviceId, "device-123")
    }

    func testInit_defaultValues() {
        let member = KBTeamMember(name: "Simple Member")

        XCTAssertNotNil(member.id)
        XCTAssertEqual(member.name, "Simple Member")
        XCTAssertEqual(member.initials, "SM") // First letter of each word
        XCTAssertEqual(member.avatarColorHex, "#3B82F6") // Default blue
        XCTAssertNil(member.primaryDomain)
        XCTAssertNil(member.secondaryDomain)
        XCTAssertTrue(member.isActive)
        XCTAssertNil(member.deviceId)
    }

    // MARK: - Initials Generation Tests

    func testGenerateInitials_twoWords() {
        let initials = KBTeamMember.generateInitials(from: "John Doe")
        XCTAssertEqual(initials, "JD")
    }

    func testGenerateInitials_threeWords() {
        let initials = KBTeamMember.generateInitials(from: "Mary Jane Watson")
        XCTAssertEqual(initials, "MJ")
    }

    func testGenerateInitials_singleWord() {
        let initials = KBTeamMember.generateInitials(from: "Alice")
        XCTAssertEqual(initials, "AL")
    }

    func testGenerateInitials_singleChar() {
        let initials = KBTeamMember.generateInitials(from: "A")
        XCTAssertEqual(initials, "A")
    }

    func testGenerateInitials_empty() {
        let initials = KBTeamMember.generateInitials(from: "")
        XCTAssertEqual(initials, "?")
    }

    func testGenerateInitials_lowercase() {
        let initials = KBTeamMember.generateInitials(from: "john smith")
        XCTAssertEqual(initials, "JS")
    }

    // MARK: - Computed Properties Tests

    func testHasAssignments_true() {
        let member = KBTeamMember(name: "Test", primaryDomain: .science)
        XCTAssertTrue(member.hasAssignments)
    }

    func testHasAssignments_trueWithSecondary() {
        var member = KBTeamMember(name: "Test")
        member.secondaryDomain = .history
        XCTAssertTrue(member.hasAssignments)
    }

    func testHasAssignments_false() {
        let member = KBTeamMember(name: "Test")
        XCTAssertFalse(member.hasAssignments)
    }

    func testAssignedDomains_both() {
        let member = KBTeamMember(
            name: "Test",
            primaryDomain: .science,
            secondaryDomain: .mathematics
        )
        XCTAssertEqual(member.assignedDomains.count, 2)
        XCTAssertEqual(member.assignedDomains[0], .science)
        XCTAssertEqual(member.assignedDomains[1], .mathematics)
    }

    func testAssignedDomains_primaryOnly() {
        let member = KBTeamMember(name: "Test", primaryDomain: .history)
        XCTAssertEqual(member.assignedDomains, [.history])
    }

    func testAssignedDomains_none() {
        let member = KBTeamMember(name: "Test")
        XCTAssertTrue(member.assignedDomains.isEmpty)
    }

    // MARK: - Preset Colors Tests

    func testPresetColors_hasExpectedCount() {
        XCTAssertEqual(KBTeamMember.presetColors.count, 10)
    }

    func testPresetColors_allAreValidHex() {
        let hexPattern = #"^#[0-9A-Fa-f]{6}$"#
        for color in KBTeamMember.presetColors {
            XCTAssertNotNil(color.range(of: hexPattern, options: .regularExpression))
        }
    }

    func testRandomColor_returnsValidColor() {
        let color = KBTeamMember.randomColor()
        XCTAssertTrue(KBTeamMember.presetColors.contains(color))
    }

    // MARK: - Codable Tests

    func testCodable_roundTrip() throws {
        let original = KBTeamMember(
            name: "Test Member",
            primaryDomain: .science,
            secondaryDomain: .mathematics
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KBTeamMember.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.primaryDomain, original.primaryDomain)
        XCTAssertEqual(decoded.secondaryDomain, original.secondaryDomain)
    }

    // MARK: - Equatable Tests

    func testEquatable_equal() {
        let id = UUID()
        let createdAt = Date()
        let member1 = KBTeamMember(id: id, name: "Test", createdAt: createdAt)
        let member2 = KBTeamMember(id: id, name: "Test", createdAt: createdAt)
        XCTAssertEqual(member1, member2)
    }

    func testEquatable_notEqual() {
        let member1 = KBTeamMember(name: "Test 1")
        let member2 = KBTeamMember(name: "Test 2")
        XCTAssertNotEqual(member1, member2)
    }
}
