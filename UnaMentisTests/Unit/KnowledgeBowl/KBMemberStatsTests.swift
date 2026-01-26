//
//  KBMemberStatsTests.swift
//  UnaMentisTests
//
//  Tests for KBMemberStats and related types.
//

import XCTest
@testable import UnaMentis

final class KBMemberStatsTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsAllProperties() {
        let memberId = UUID()
        let domainStats = ["science": KBDomainStats(accuracy: 0.85, avgResponseTime: 2.0, questionCount: 20)]
        let lastPractice = Date()
        let lastSynced = Date()

        let stats = KBMemberStats(
            memberId: memberId,
            domainStats: domainStats,
            lastPracticeDate: lastPractice,
            totalSessions: 10,
            totalQuestions: 100,
            lastSyncedAt: lastSynced
        )

        XCTAssertEqual(stats.memberId, memberId)
        XCTAssertEqual(stats.domainStats.count, 1)
        XCTAssertEqual(stats.lastPracticeDate, lastPractice)
        XCTAssertEqual(stats.totalSessions, 10)
        XCTAssertEqual(stats.totalQuestions, 100)
        XCTAssertEqual(stats.lastSyncedAt, lastSynced)
    }

    func testInit_defaultValues() {
        let memberId = UUID()
        let stats = KBMemberStats(memberId: memberId)

        XCTAssertTrue(stats.domainStats.isEmpty)
        XCTAssertNil(stats.lastPracticeDate)
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalQuestions, 0)
    }

    func testId_returnsMemberId() {
        let memberId = UUID()
        let stats = KBMemberStats(memberId: memberId)
        XCTAssertEqual(stats.id, memberId)
    }

    // MARK: - Domain Stats Access Tests

    func testStatsForDomain_returnsCorrectStats() {
        var stats = KBMemberStats(memberId: UUID())
        let domainStats = KBDomainStats(accuracy: 0.9, avgResponseTime: 1.5, questionCount: 30)
        stats.domainStats["science"] = domainStats

        let retrieved = stats.stats(for: .science)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.accuracy, 0.9)
    }

    func testStatsForDomain_returnsNilForMissing() {
        let stats = KBMemberStats(memberId: UUID())
        XCTAssertNil(stats.stats(for: .science))
    }

    func testUpdateStatsForDomain_updatesCorrectly() {
        var stats = KBMemberStats(memberId: UUID())
        let domainStats = KBDomainStats(accuracy: 0.8, avgResponseTime: 2.0, questionCount: 25)

        stats.updateStats(for: .mathematics, stats: domainStats)

        XCTAssertEqual(stats.stats(for: .mathematics)?.accuracy, 0.8)
    }

    // MARK: - Strongest/Weakest Domains Tests

    func testStrongestDomains_sortedByAccuracy() {
        var stats = KBMemberStats(memberId: UUID())
        stats.domainStats["science"] = KBDomainStats(accuracy: 0.9, questionCount: 20)
        stats.domainStats["mathematics"] = KBDomainStats(accuracy: 0.7, questionCount: 20)
        stats.domainStats["history"] = KBDomainStats(accuracy: 0.8, questionCount: 20)

        let strongest = stats.strongestDomains
        XCTAssertEqual(strongest.count, 3)
        XCTAssertEqual(strongest.first?.domain, .science)
        XCTAssertEqual(strongest.last?.domain, .mathematics)
    }

    func testStrongestDomains_requiresMinimumQuestions() {
        var stats = KBMemberStats(memberId: UUID())
        stats.domainStats["science"] = KBDomainStats(accuracy: 0.9, questionCount: 3) // Below minimum
        stats.domainStats["mathematics"] = KBDomainStats(accuracy: 0.7, questionCount: 10)

        let strongest = stats.strongestDomains
        XCTAssertEqual(strongest.count, 1)
        XCTAssertEqual(strongest.first?.domain, .mathematics)
    }

    func testWeakestDomains_sortedByAccuracyAscending() {
        var stats = KBMemberStats(memberId: UUID())
        stats.domainStats["science"] = KBDomainStats(accuracy: 0.9, questionCount: 20)
        stats.domainStats["mathematics"] = KBDomainStats(accuracy: 0.5, questionCount: 20)
        stats.domainStats["history"] = KBDomainStats(accuracy: 0.7, questionCount: 20)

        let weakest = stats.weakestDomains
        XCTAssertEqual(weakest.first?.domain, .mathematics)
        XCTAssertEqual(weakest.last?.domain, .science)
    }

    // MARK: - Aggregate Stats Tests

    func testOverallAccuracy_calculatesCorrectly() {
        var stats = KBMemberStats(memberId: UUID())
        stats.domainStats["science"] = KBDomainStats(accuracy: 0.8, questionCount: 50)
        stats.domainStats["mathematics"] = KBDomainStats(accuracy: 0.6, questionCount: 50)

        // (0.8 * 50 + 0.6 * 50) / 100 = 0.7
        XCTAssertEqual(stats.overallAccuracy, 0.7, accuracy: 0.01)
    }

    func testOverallAccuracy_returnsZeroWhenEmpty() {
        let stats = KBMemberStats(memberId: UUID())
        XCTAssertEqual(stats.overallAccuracy, 0)
    }

    func testAverageResponseTime_calculatesCorrectly() {
        var stats = KBMemberStats(memberId: UUID())
        stats.domainStats["science"] = KBDomainStats(avgResponseTime: 2.0, questionCount: 50)
        stats.domainStats["mathematics"] = KBDomainStats(avgResponseTime: 4.0, questionCount: 50)

        // (2.0 * 50 + 4.0 * 50) / 100 = 3.0
        XCTAssertEqual(stats.averageResponseTime, 3.0, accuracy: 0.01)
    }

    func testAverageResponseTime_returnsZeroWhenEmpty() {
        let stats = KBMemberStats(memberId: UUID())
        XCTAssertEqual(stats.averageResponseTime, 0)
    }

    // MARK: - Session Recording Tests

    func testRecordSession_updatesStats() {
        var stats = KBMemberStats(memberId: UUID())

        stats.recordSession(
            domain: .science,
            questionsAnswered: 20,
            correctAnswers: 16,
            avgResponseTime: 2.5
        )

        XCTAssertEqual(stats.totalSessions, 1)
        XCTAssertEqual(stats.totalQuestions, 20)
        XCTAssertNotNil(stats.lastPracticeDate)

        let domainStats = stats.stats(for: .science)
        XCTAssertNotNil(domainStats)
        XCTAssertEqual(domainStats?.questionCount, 20)
        XCTAssertEqual(domainStats!.accuracy, 0.8, accuracy: 0.01)
    }

    func testRecordSession_mergesWithExisting() {
        var stats = KBMemberStats(memberId: UUID())

        // First session: 10 questions, 8 correct (80%)
        stats.recordSession(
            domain: .science,
            questionsAnswered: 10,
            correctAnswers: 8,
            avgResponseTime: 2.0
        )

        // Second session: 10 questions, 6 correct (60%)
        stats.recordSession(
            domain: .science,
            questionsAnswered: 10,
            correctAnswers: 6,
            avgResponseTime: 3.0
        )

        let domainStats = stats.stats(for: .science)
        XCTAssertNotNil(domainStats)
        XCTAssertEqual(domainStats?.questionCount, 20)
        // Weighted average: (8 + 6) / 20 = 0.7
        XCTAssertEqual(domainStats!.accuracy, 0.7, accuracy: 0.01)
        // Weighted average: (2.0 * 10 + 3.0 * 10) / 20 = 2.5
        XCTAssertEqual(domainStats!.avgResponseTime, 2.5, accuracy: 0.01)
    }

    // MARK: - Merge Tests

    func testMerge_takesMoreRecentSyncTime() {
        let memberId = UUID()
        var stats1 = KBMemberStats(memberId: memberId, lastSyncedAt: Date(timeIntervalSince1970: 1000))
        let stats2 = KBMemberStats(memberId: memberId, lastSyncedAt: Date(timeIntervalSince1970: 2000))

        stats1.merge(with: stats2)

        // Should merge because stats2 has more recent sync time
        XCTAssertGreaterThan(stats1.lastSyncedAt.timeIntervalSince1970, 2000)
    }

    func testMerge_ignoresOlderData() {
        let memberId = UUID()
        var stats1 = KBMemberStats(memberId: memberId, totalSessions: 10, lastSyncedAt: Date(timeIntervalSince1970: 2000))
        let stats2 = KBMemberStats(memberId: memberId, totalSessions: 5, lastSyncedAt: Date(timeIntervalSince1970: 1000))

        stats1.merge(with: stats2)

        // Should not merge because stats2 has older sync time
        XCTAssertEqual(stats1.totalSessions, 10)
    }

    func testMerge_takesHigherQuestionCount() {
        let memberId = UUID()
        var stats1 = KBMemberStats(memberId: memberId, lastSyncedAt: Date(timeIntervalSince1970: 1000))
        stats1.domainStats["science"] = KBDomainStats(accuracy: 0.7, questionCount: 10)

        var stats2 = KBMemberStats(memberId: memberId, lastSyncedAt: Date(timeIntervalSince1970: 2000))
        stats2.domainStats["science"] = KBDomainStats(accuracy: 0.9, questionCount: 20)

        stats1.merge(with: stats2)

        XCTAssertEqual(stats1.domainStats["science"]?.questionCount, 20)
        XCTAssertEqual(stats1.domainStats["science"]?.accuracy, 0.9)
    }

    func testEmpty_createsEmptyStats() {
        let memberId = UUID()
        let stats = KBMemberStats.empty(for: memberId)

        XCTAssertEqual(stats.memberId, memberId)
        XCTAssertTrue(stats.domainStats.isEmpty)
        XCTAssertEqual(stats.totalSessions, 0)
    }

    // MARK: - Codable Tests

    func testCodable_roundTrip() throws {
        var original = KBMemberStats(memberId: UUID())
        original.totalSessions = 5
        original.domainStats["science"] = KBDomainStats(accuracy: 0.85, questionCount: 30)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KBMemberStats.self, from: data)

        XCTAssertEqual(decoded.memberId, original.memberId)
        XCTAssertEqual(decoded.totalSessions, original.totalSessions)
        XCTAssertEqual(decoded.domainStats["science"]?.accuracy, 0.85)
    }
}

// MARK: - KBDomainStats Tests

final class KBDomainStatsTests: XCTestCase {

    func testInit_defaultValues() {
        let stats = KBDomainStats()
        XCTAssertEqual(stats.accuracy, 0)
        XCTAssertEqual(stats.avgResponseTime, 0)
        XCTAssertEqual(stats.questionCount, 0)
        XCTAssertEqual(stats.masteryLevel, .beginner)
    }

    func testInit_setsAllValues() {
        let stats = KBDomainStats(
            accuracy: 0.85,
            avgResponseTime: 2.5,
            questionCount: 50,
            masteryLevel: .proficient
        )

        XCTAssertEqual(stats.accuracy, 0.85)
        XCTAssertEqual(stats.avgResponseTime, 2.5)
        XCTAssertEqual(stats.questionCount, 50)
        XCTAssertEqual(stats.masteryLevel, .proficient)
    }

    func testCodable_roundTrip() throws {
        let original = KBDomainStats(
            accuracy: 0.9,
            avgResponseTime: 1.8,
            questionCount: 100,
            masteryLevel: .expert
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KBDomainStats.self, from: data)

        XCTAssertEqual(decoded.accuracy, original.accuracy)
        XCTAssertEqual(decoded.avgResponseTime, original.avgResponseTime)
        XCTAssertEqual(decoded.questionCount, original.questionCount)
        XCTAssertEqual(decoded.masteryLevel, original.masteryLevel)
    }
}

// MARK: - KBMasteryLevel Tests

final class KBMasteryLevelTests: XCTestCase {

    func testAllCases_hasFiveLevels() {
        XCTAssertEqual(KBMasteryLevel.allCases.count, 5)
    }

    func testDisplayName_isCapitalized() {
        XCTAssertEqual(KBMasteryLevel.beginner.displayName, "Beginner")
        XCTAssertEqual(KBMasteryLevel.developing.displayName, "Developing")
        XCTAssertEqual(KBMasteryLevel.intermediate.displayName, "Intermediate")
        XCTAssertEqual(KBMasteryLevel.proficient.displayName, "Proficient")
        XCTAssertEqual(KBMasteryLevel.expert.displayName, "Expert")
    }

    func testIcon_hasValidSFSymbol() {
        let validSymbols = ["leaf", "arrow.up.right", "chart.bar", "star", "star.fill"]
        for level in KBMasteryLevel.allCases {
            XCTAssertTrue(validSymbols.contains(level.icon))
        }
    }

    func testColorHex_isValidHex() {
        let hexPattern = #"^#[0-9A-Fa-f]{6}$"#
        for level in KBMasteryLevel.allCases {
            XCTAssertNotNil(level.colorHex.range(of: hexPattern, options: .regularExpression))
        }
    }

    func testCalculate_beginner() {
        // Less than 5 questions
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 1.0, questionCount: 4), .beginner)
        // Low accuracy
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 0.4, questionCount: 10), .beginner)
    }

    func testCalculate_developing() {
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 0.6, questionCount: 12), .developing)
    }

    func testCalculate_intermediate() {
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 0.75, questionCount: 20), .intermediate)
    }

    func testCalculate_proficient() {
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 0.85, questionCount: 40), .proficient)
    }

    func testCalculate_expert() {
        XCTAssertEqual(KBMasteryLevel.calculate(accuracy: 0.95, questionCount: 60), .expert)
    }

    func testCodable_roundTrip() throws {
        for level in KBMasteryLevel.allCases {
            let data = try JSONEncoder().encode(level)
            let decoded = try JSONDecoder().decode(KBMasteryLevel.self, from: data)
            XCTAssertEqual(decoded, level)
        }
    }
}
