//
//  KBTeamStoreTests.swift
//  UnaMentisTests
//
//  Tests for KBTeamStore - local persistence for team data.
//

import XCTest
@testable import UnaMentis

@MainActor
final class KBTeamStoreTests: XCTestCase {

    // MARK: - Profile Operations Tests

    func testHasTeamProfile_returnsFalseWhenEmpty() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let hasProfile = try await store.hasTeamProfile()
        XCTAssertFalse(hasProfile)
    }

    func testSaveAndLoadProfile_roundTrip() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let profile = createTestProfile()
        try await store.saveProfile(profile)

        let loaded = try await store.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, profile.id)
        XCTAssertEqual(loaded?.name, profile.name)
        XCTAssertEqual(loaded?.teamCode, profile.teamCode)
    }

    func testHasTeamProfile_returnsTrueAfterSave() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let profile = createTestProfile()
        try await store.saveProfile(profile)

        let hasProfile = try await store.hasTeamProfile()
        XCTAssertTrue(hasProfile)
    }

    func testDeleteProfile_removesProfile() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let profile = createTestProfile()
        try await store.saveProfile(profile)

        let hasProfileBefore = try await store.hasTeamProfile()
        XCTAssertTrue(hasProfileBefore)

        try await store.deleteProfile()

        let hasProfileAfter = try await store.hasTeamProfile()
        XCTAssertFalse(hasProfileAfter)
    }

    func testLoadProfile_returnsNilWhenNoProfile() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let profile = try await store.loadProfile()
        XCTAssertNil(profile)
    }

    func testSaveProfile_preservesMembers() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let member = KBTeamMember(name: "Test Member", primaryDomain: .science)
        var profile = createTestProfile()
        profile.addMember(member)

        try await store.saveProfile(profile)

        let loaded = try await store.loadProfile()
        XCTAssertEqual(loaded?.members.count, 1)
        XCTAssertEqual(loaded?.members.first?.name, "Test Member")
        XCTAssertEqual(loaded?.members.first?.primaryDomain, .science)
    }

    // MARK: - Stats Operations Tests

    func testSaveAndLoadStats_roundTrip() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let memberId = UUID()
        let stats = createTestStats(memberId: memberId)

        try await store.saveStats(stats)

        let loaded = try await store.loadStats(memberId: memberId)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.memberId, memberId)
        XCTAssertEqual(loaded?.totalSessions, stats.totalSessions)
    }

    func testLoadStats_returnsNilForNonexistentMember() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let stats = try await store.loadStats(memberId: UUID())
        XCTAssertNil(stats)
    }

    func testLoadAllStats_returnsAllSavedStats() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let stats1 = createTestStats(memberId: UUID(), sessions: 5)
        let stats2 = createTestStats(memberId: UUID(), sessions: 10)
        let stats3 = createTestStats(memberId: UUID(), sessions: 15)

        try await store.saveStats(stats1)
        try await store.saveStats(stats2)
        try await store.saveStats(stats3)

        let allStats = try await store.loadAllStats()
        XCTAssertEqual(allStats.count, 3)
    }

    func testDeleteStats_removesSpecificMemberStats() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let memberId1 = UUID()
        let memberId2 = UUID()

        try await store.saveStats(createTestStats(memberId: memberId1))
        try await store.saveStats(createTestStats(memberId: memberId2))

        try await store.deleteStats(memberId: memberId1)

        let stats1 = try await store.loadStats(memberId: memberId1)
        let stats2 = try await store.loadStats(memberId: memberId2)
        XCTAssertNil(stats1)
        XCTAssertNotNil(stats2)
    }

    // MARK: - Export/Import Tests

    func testExportPackage_returnsNilWithNoProfile() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let package = try await store.exportPackage()
        XCTAssertNil(package)
    }

    func testExportPackage_includesProfileAndStats() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let member = KBTeamMember(name: "Test Member")
        var profile = createTestProfile()
        profile.addMember(member)

        try await store.saveProfile(profile)

        let stats = createTestStats(memberId: member.id, sessions: 10)
        try await store.saveStats(stats)

        let package = try await store.exportPackage()
        XCTAssertNotNil(package)
        XCTAssertEqual(package?.team.name, profile.name)
        XCTAssertEqual(package?.memberStats?.count, 1)
    }

    func testExportToFile_throwsErrorWithNoProfile() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_export.kbteam")

        do {
            try await store.exportToFile(url: tempURL)
            XCTFail("Expected error to be thrown")
        } catch let error as KBTeamStoreError {
            switch error {
            case .noTeamProfile:
                break // Expected
            default:
                XCTFail("Expected noTeamProfile error")
            }
        }
    }

    func testImportFromFile_loadsProfileAndStats() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        // Create and save a profile to export
        let member = KBTeamMember(name: "Export Member")
        var profile = createTestProfile()
        profile.addMember(member)
        try await store.saveProfile(profile)

        let stats = createTestStats(memberId: member.id, sessions: 5)
        try await store.saveStats(stats)

        // Export to file
        let tempURL = await store.temporaryExportURL(teamName: profile.name)
        try await store.exportToFile(url: tempURL)

        // Clear data and re-import
        try await store.deleteAllData()
        let hasProfileBefore = try await store.hasTeamProfile()
        XCTAssertFalse(hasProfileBefore)

        let imported = try await store.importFromFile(url: tempURL)
        XCTAssertEqual(imported.name, profile.name)

        // Verify profile was imported
        let hasProfileAfter = try await store.hasTeamProfile()
        XCTAssertTrue(hasProfileAfter)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testTemporaryExportURL_sanitizesTeamName() async {
        let store = KBTeamStore()

        let url = await store.temporaryExportURL(teamName: "My Team Name")
        XCTAssertTrue(url.lastPathComponent.contains("My_Team_Name"))
        XCTAssertTrue(url.pathExtension == "kbteam")
    }

    // MARK: - Cleanup Tests

    func testDeleteAllData_removesEverything() async throws {
        let store = KBTeamStore()

        // Create profile and stats
        let profile = createTestProfile()
        try await store.saveProfile(profile)
        try await store.saveStats(createTestStats(memberId: UUID()))

        try await store.deleteAllData()

        let hasProfile = try await store.hasTeamProfile()
        XCTAssertFalse(hasProfile)
        let allStats = try await store.loadAllStats()
        XCTAssertTrue(allStats.isEmpty)
    }

    func testCleanupOrphanedStats_removesStatsForNonMembers() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        // Create profile with one member
        let member = KBTeamMember(name: "Active Member")
        var profile = createTestProfile()
        profile.addMember(member)
        try await store.saveProfile(profile)

        // Create stats for member and an orphaned member
        let orphanId = UUID()
        try await store.saveStats(createTestStats(memberId: member.id))
        try await store.saveStats(createTestStats(memberId: orphanId))

        // Verify both stats exist
        let allStatsBefore = try await store.loadAllStats()
        XCTAssertEqual(allStatsBefore.count, 2)

        // Cleanup orphaned stats
        try await store.cleanupOrphanedStats()

        // Only the active member's stats should remain
        let remainingStats = try await store.loadAllStats()
        XCTAssertEqual(remainingStats.count, 1)
        XCTAssertEqual(remainingStats.first?.memberId, member.id)
    }

    // MARK: - Convenience Tests

    func testLoadTeamStats_returnsEmptyWhenNoProfile() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        let stats = try await store.loadTeamStats()
        XCTAssertTrue(stats.isEmpty)
    }

    func testLoadTeamStats_returnsStatsForAllMembers() async throws {
        let store = KBTeamStore()
        try await store.deleteAllData()

        // Create profile with two members
        let member1 = KBTeamMember(name: "Member 1")
        let member2 = KBTeamMember(name: "Member 2")
        var profile = createTestProfile()
        profile.addMember(member1)
        profile.addMember(member2)
        try await store.saveProfile(profile)

        // Save stats for member1 only
        try await store.saveStats(createTestStats(memberId: member1.id, sessions: 10))

        let teamStats = try await store.loadTeamStats()

        XCTAssertEqual(teamStats.count, 2)
        XCTAssertNotNil(teamStats[member1.id])
        XCTAssertNotNil(teamStats[member2.id])
        XCTAssertEqual(teamStats[member1.id]?.totalSessions, 10)
        XCTAssertEqual(teamStats[member2.id]?.totalSessions, 0) // Empty stats
    }

    // MARK: - Helper Methods

    private func createTestProfile(name: String = "Test Team") -> KBTeamProfile {
        KBTeamProfile(
            name: name,
            region: .colorado,
            isCaptain: true
        )
    }

    private func createTestStats(
        memberId: UUID,
        sessions: Int = 5
    ) -> KBMemberStats {
        var stats = KBMemberStats(memberId: memberId)
        stats.totalSessions = sessions
        stats.totalQuestions = sessions * 10
        stats.lastPracticeDate = Date()
        return stats
    }
}

// MARK: - Error Tests

final class KBTeamStoreErrorTests: XCTestCase {

    func testNoTeamProfile_errorDescription() {
        let error = KBTeamStoreError.noTeamProfile
        XCTAssertEqual(error.errorDescription, "No team profile exists to export")
    }

    func testImportFailed_errorDescription() {
        let error = KBTeamStoreError.importFailed(reason: "Invalid format")
        XCTAssertEqual(error.errorDescription, "Failed to import team data: Invalid format")
    }

    func testError_isLocalizedError() {
        let error: LocalizedError = KBTeamStoreError.noTeamProfile
        XCTAssertNotNil(error.errorDescription)
    }
}
