//
//  KBPackTests.swift
//  UnaMentisTests
//
//  Tests for KBPack model and related types.
//

import XCTest
@testable import UnaMentis

final class KBPackTests: XCTestCase {

    // MARK: - KBPack Initialization Tests

    func testInit_setsAllProperties() {
        let domainDistribution = ["science": 10, "mathematics": 5]
        let difficultyDistribution = [1: 5, 2: 7, 3: 3]
        let createdAt = Date()

        let pack = KBPack(
            id: "test-pack-1",
            name: "Test Pack",
            description: "A test pack",
            questionCount: 15,
            domainDistribution: domainDistribution,
            difficultyDistribution: difficultyDistribution,
            packType: .custom,
            isLocal: true,
            questionIds: ["q1", "q2", "q3"],
            createdAt: createdAt,
            updatedAt: nil
        )

        XCTAssertEqual(pack.id, "test-pack-1")
        XCTAssertEqual(pack.name, "Test Pack")
        XCTAssertEqual(pack.description, "A test pack")
        XCTAssertEqual(pack.questionCount, 15)
        XCTAssertEqual(pack.domainDistribution, domainDistribution)
        XCTAssertEqual(pack.difficultyDistribution, difficultyDistribution)
        XCTAssertEqual(pack.packType, .custom)
        XCTAssertTrue(pack.isLocal)
        XCTAssertEqual(pack.questionIds, ["q1", "q2", "q3"])
        XCTAssertEqual(pack.createdAt, createdAt)
        XCTAssertNil(pack.updatedAt)
    }

    func testInit_defaultValues() {
        let pack = KBPack(
            id: "test-pack",
            name: "Test",
            description: nil,
            questionCount: 0,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        XCTAssertEqual(pack.packType, .custom)
        XCTAssertTrue(pack.isLocal)
        XCTAssertNil(pack.questionIds)
        XCTAssertNotNil(pack.createdAt)
        XCTAssertNil(pack.updatedAt)
    }

    // MARK: - PackType Tests

    func testPackType_rawValues() {
        XCTAssertEqual(KBPack.PackType.system.rawValue, "system")
        XCTAssertEqual(KBPack.PackType.custom.rawValue, "custom")
        XCTAssertEqual(KBPack.PackType.bundle.rawValue, "bundle")
    }

    func testPackType_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for packType in [KBPack.PackType.system, .custom, .bundle] {
            let data = try encoder.encode(packType)
            let decoded = try decoder.decode(KBPack.PackType.self, from: data)
            XCTAssertEqual(decoded, packType)
        }
    }

    // MARK: - Top Domains Tests

    func testTopDomains_returnsUpToFourDomains() {
        let domainDistribution = [
            "science": 30,
            "mathematics": 25,
            "history": 20,
            "literature": 15,
            "arts": 10,
            "technology": 5
        ]

        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 105,
            domainDistribution: domainDistribution,
            difficultyDistribution: [:]
        )

        let topDomains = pack.topDomains
        XCTAssertLessThanOrEqual(topDomains.count, 4)
    }

    func testTopDomains_sortedByCount() {
        let domainDistribution = [
            "science": 30,
            "mathematics": 25,
            "history": 20,
            "literature": 15
        ]

        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 90,
            domainDistribution: domainDistribution,
            difficultyDistribution: [:]
        )

        let topDomains = pack.topDomains
        XCTAssertEqual(topDomains.first, .science)
    }

    func testTopDomains_filtersInvalidDomains() {
        let domainDistribution = [
            "science": 30,
            "invalid_domain": 25,
            "mathematics": 20
        ]

        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 75,
            domainDistribution: domainDistribution,
            difficultyDistribution: [:]
        )

        let topDomains = pack.topDomains
        XCTAssertFalse(topDomains.contains { $0.rawValue == "invalid_domain" })
    }

    // MARK: - Question Count Display Tests

    func testQuestionCountDisplay_singular() {
        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 1,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        XCTAssertEqual(pack.questionCountDisplay, "1 question")
    }

    func testQuestionCountDisplay_plural() {
        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 50,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        XCTAssertEqual(pack.questionCountDisplay, "50 questions")
    }

    func testQuestionCountDisplay_zero() {
        let pack = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 0,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        XCTAssertEqual(pack.questionCountDisplay, "0 questions")
    }

    // MARK: - Codable Tests

    func testCodable_roundTrip() throws {
        let original = KBPack(
            id: "test-pack-1",
            name: "Test Pack",
            description: "Description",
            questionCount: 25,
            domainDistribution: ["science": 15, "history": 10],
            difficultyDistribution: [1: 5, 2: 10, 3: 10],
            packType: .system,
            isLocal: false,
            questionIds: ["q1", "q2"],
            createdAt: Date(timeIntervalSince1970: 1700000000),
            updatedAt: Date(timeIntervalSince1970: 1700001000)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KBPack.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.questionCount, original.questionCount)
        XCTAssertEqual(decoded.packType, original.packType)
        XCTAssertEqual(decoded.isLocal, original.isLocal)
        XCTAssertEqual(decoded.questionIds, original.questionIds)
    }

    // MARK: - Equatable Tests

    func testEquatable_equalPacks() {
        let pack1 = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 10,
            domainDistribution: [:],
            difficultyDistribution: [:],
            packType: .custom,
            isLocal: true,
            questionIds: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let pack2 = KBPack(
            id: "test",
            name: "Test",
            description: nil,
            questionCount: 10,
            domainDistribution: [:],
            difficultyDistribution: [:],
            packType: .custom,
            isLocal: true,
            questionIds: nil,
            createdAt: nil,
            updatedAt: nil
        )

        XCTAssertEqual(pack1, pack2)
    }

    func testEquatable_differentPacks() {
        let pack1 = KBPack(
            id: "test-1",
            name: "Test",
            description: nil,
            questionCount: 10,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        let pack2 = KBPack(
            id: "test-2",
            name: "Test",
            description: nil,
            questionCount: 10,
            domainDistribution: [:],
            difficultyDistribution: [:]
        )

        XCTAssertNotEqual(pack1, pack2)
    }
}

// MARK: - KBPackDTO Tests

final class KBPackDTOTests: XCTestCase {

    func testToPack_basicConversion() {
        let dto = KBPackDTO(
            id: "pack-123",
            name: "Test Pack",
            description: "Description",
            packType: "system",
            questionIds: ["q1", "q2"],
            stats: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let pack = dto.toPack()

        XCTAssertEqual(pack.id, "pack-123")
        XCTAssertEqual(pack.name, "Test Pack")
        XCTAssertEqual(pack.description, "Description")
        XCTAssertEqual(pack.packType, .system)
        XCTAssertFalse(pack.isLocal)
        XCTAssertEqual(pack.questionIds, ["q1", "q2"])
    }

    func testToPack_withStats() {
        let stats = KBPackStats(
            questionCount: 50,
            domainCount: 5,
            domainDistribution: ["science": 20, "mathematics": 15, "history": 15],
            difficultyDistribution: [1: 10, 2: 20, 3: 15, 4: 5],
            audioCoveragePercent: 85.5,
            missingAudioCount: 7
        )

        let dto = KBPackDTO(
            id: "pack-456",
            name: "Stats Pack",
            description: nil,
            packType: "custom",
            questionIds: nil,
            stats: stats,
            createdAt: nil,
            updatedAt: nil
        )

        let pack = dto.toPack()

        XCTAssertEqual(pack.questionCount, 50)
        XCTAssertEqual(pack.domainDistribution["science"], 20)
        XCTAssertEqual(pack.difficultyDistribution[2], 20)
        XCTAssertEqual(pack.packType, .custom)
    }

    func testToPack_questionCountFromQuestionIds() {
        let dto = KBPackDTO(
            id: "pack",
            name: "Pack",
            description: nil,
            packType: nil,
            questionIds: ["q1", "q2", "q3", "q4", "q5"],
            stats: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let pack = dto.toPack()
        XCTAssertEqual(pack.questionCount, 5)
    }

    func testToPack_defaultPackType() {
        let dto = KBPackDTO(
            id: "pack",
            name: "Pack",
            description: nil,
            packType: nil,
            questionIds: nil,
            stats: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let pack = dto.toPack()
        XCTAssertEqual(pack.packType, .system)
    }

    func testToPack_invalidPackTypeFallsBackToSystem() {
        let dto = KBPackDTO(
            id: "pack",
            name: "Pack",
            description: nil,
            packType: "invalid_type",
            questionIds: nil,
            stats: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let pack = dto.toPack()
        XCTAssertEqual(pack.packType, .system)
    }

    func testToPack_parsesISO8601Dates() {
        let dto = KBPackDTO(
            id: "pack",
            name: "Pack",
            description: nil,
            packType: nil,
            questionIds: nil,
            stats: nil,
            createdAt: "2024-01-15T10:30:00Z",
            updatedAt: "2024-01-20T14:45:00Z"
        )

        let pack = dto.toPack()

        XCTAssertNotNil(pack.createdAt)
        XCTAssertNotNil(pack.updatedAt)
    }

    func testToPack_invalidDateReturnsNil() {
        let dto = KBPackDTO(
            id: "pack",
            name: "Pack",
            description: nil,
            packType: nil,
            questionIds: nil,
            stats: nil,
            createdAt: "not-a-date",
            updatedAt: nil
        )

        let pack = dto.toPack()
        XCTAssertNil(pack.createdAt)
    }

    // MARK: - Codable Tests

    func testCodable_snakeCaseKeys() throws {
        let json = """
        {
            "id": "pack-1",
            "name": "Test Pack",
            "description": "A test",
            "pack_type": "bundle",
            "question_ids": ["q1", "q2"],
            "stats": {
                "question_count": 25,
                "domain_count": 3,
                "domain_distribution": {"science": 15, "mathematics": 10},
                "difficulty_distribution": {"1": 5, "2": 10, "3": 10},
                "audio_coverage_percent": 90.0,
                "missing_audio_count": 3
            },
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let dto = try decoder.decode(KBPackDTO.self, from: json)

        XCTAssertEqual(dto.id, "pack-1")
        XCTAssertEqual(dto.name, "Test Pack")
        XCTAssertEqual(dto.packType, "bundle")
        XCTAssertEqual(dto.questionIds, ["q1", "q2"])
        XCTAssertNotNil(dto.stats)
        XCTAssertEqual(dto.stats?.questionCount, 25)
    }
}

// MARK: - KBPacksResponse Tests

final class KBPacksResponseTests: XCTestCase {

    func testCodable_decodesResponse() throws {
        let json = """
        {
            "packs": [
                {
                    "id": "pack-1",
                    "name": "Pack One",
                    "description": null,
                    "pack_type": "system",
                    "question_ids": null,
                    "stats": null,
                    "created_at": null,
                    "updated_at": null
                }
            ],
            "total": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(KBPacksResponse.self, from: json)

        XCTAssertEqual(response.packs.count, 1)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.packs.first?.id, "pack-1")
    }

    func testCodable_totalIsOptional() throws {
        let json = """
        {
            "packs": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(KBPacksResponse.self, from: json)

        XCTAssertNil(response.total)
    }
}
