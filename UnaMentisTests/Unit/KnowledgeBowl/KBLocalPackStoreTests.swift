//
//  KBLocalPackStoreTests.swift
//  UnaMentisTests
//
//  Tests for KBLocalPackStore - local pack persistence and management.
//

import XCTest
@testable import UnaMentis

@MainActor
final class KBLocalPackStoreTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_startsWithEmptyPacks() {
        let store = KBLocalPackStore()
        XCTAssertTrue(store.localPacks.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    // MARK: - Create Pack Tests

    func testCreatePack_addsPackToList() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(
            name: "Test Pack",
            description: "A test pack",
            questions: questions
        )

        XCTAssertEqual(store.localPacks.count, 1)
        XCTAssertEqual(store.localPacks.first?.id, pack.id)
    }

    func testCreatePack_setsCorrectProperties() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 10)
        let pack = store.createPack(
            name: "My Custom Pack",
            description: "Custom description",
            questions: questions
        )

        XCTAssertEqual(pack.name, "My Custom Pack")
        XCTAssertEqual(pack.description, "Custom description")
        XCTAssertEqual(pack.questionCount, 10)
        XCTAssertEqual(pack.packType, .custom)
        XCTAssertTrue(pack.isLocal)
        XCTAssertNotNil(pack.createdAt)
    }

    func testCreatePack_generatesLocalId() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 1)
        let pack = store.createPack(name: "Test", questions: questions)

        XCTAssertTrue(pack.id.hasPrefix("local-"))
    }

    func testCreatePack_calculatesDistributions() {
        let store = KBLocalPackStore()

        // Create questions with specific domains and difficulties
        let questions = [
            createQuestion(domain: .science, difficulty: 2),
            createQuestion(domain: .science, difficulty: 2),
            createQuestion(domain: .mathematics, difficulty: 3),
            createQuestion(domain: .history, difficulty: 1)
        ]

        let pack = store.createPack(name: "Test", questions: questions)

        // Domain distribution
        XCTAssertEqual(pack.domainDistribution["science"], 2)
        XCTAssertEqual(pack.domainDistribution["mathematics"], 1)
        XCTAssertEqual(pack.domainDistribution["history"], 1)

        // Difficulty distribution
        XCTAssertEqual(pack.difficultyDistribution[1], 1)
        XCTAssertEqual(pack.difficultyDistribution[2], 2)
        XCTAssertEqual(pack.difficultyDistribution[3], 1)
    }

    func testCreatePack_storesQuestionIds() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 3)
        let pack = store.createPack(name: "Test", questions: questions)

        XCTAssertEqual(pack.questionIds?.count, 3)
        for question in questions {
            XCTAssertTrue(pack.questionIds?.contains(question.id.uuidString) ?? false)
        }
    }

    func testCreatePack_usesDefaultDescriptionWhenNil() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 1)
        let pack = store.createPack(name: "Test", description: nil, questions: questions)

        XCTAssertEqual(pack.description, "Custom pack created on device")
    }

    // MARK: - Update Pack Tests

    func testUpdatePack_updatesName() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Original", questions: questions)

        store.updatePack(id: pack.id, name: "Updated Name")

        let updated = store.pack(withId: pack.id)
        XCTAssertEqual(updated?.name, "Updated Name")
    }

    func testUpdatePack_updatesDescription() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Test", description: "Original", questions: questions)

        store.updatePack(id: pack.id, description: "New description")

        let updated = store.pack(withId: pack.id)
        XCTAssertEqual(updated?.description, "New description")
    }

    func testUpdatePack_updatesQuestions() {
        let store = KBLocalPackStore()

        let originalQuestions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Test", questions: originalQuestions)

        let newQuestions = createTestQuestions(count: 10)
        store.updatePack(id: pack.id, questions: newQuestions)

        let updated = store.pack(withId: pack.id)
        XCTAssertEqual(updated?.questionCount, 10)
        XCTAssertEqual(updated?.questionIds?.count, 10)
    }

    func testUpdatePack_setsUpdatedAt() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Test", questions: questions)
        XCTAssertNil(pack.updatedAt)

        store.updatePack(id: pack.id, name: "Updated")

        let updated = store.pack(withId: pack.id)
        XCTAssertNotNil(updated?.updatedAt)
    }

    func testUpdatePack_nonexistentIdDoesNothing() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        _ = store.createPack(name: "Test", questions: questions)

        // Update nonexistent pack
        store.updatePack(id: "nonexistent-id", name: "New Name")

        // Original should be unchanged
        XCTAssertEqual(store.localPacks.count, 1)
        XCTAssertEqual(store.localPacks.first?.name, "Test")
    }

    // MARK: - Delete Pack Tests

    func testDeletePack_removesPackFromList() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Test", questions: questions)
        XCTAssertEqual(store.localPacks.count, 1)

        store.deletePack(id: pack.id)
        XCTAssertTrue(store.localPacks.isEmpty)
    }

    func testDeletePack_nonexistentIdDoesNothing() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        _ = store.createPack(name: "Test", questions: questions)

        store.deletePack(id: "nonexistent-id")
        XCTAssertEqual(store.localPacks.count, 1)
    }

    func testDeletePack_removesCorrectPack() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack1 = store.createPack(name: "Pack 1", questions: questions)
        let pack2 = store.createPack(name: "Pack 2", questions: questions)
        let pack3 = store.createPack(name: "Pack 3", questions: questions)

        store.deletePack(id: pack2.id)

        XCTAssertEqual(store.localPacks.count, 2)
        XCTAssertNotNil(store.pack(withId: pack1.id))
        XCTAssertNil(store.pack(withId: pack2.id))
        XCTAssertNotNil(store.pack(withId: pack3.id))
    }

    // MARK: - Pack Lookup Tests

    func testPackWithId_findsExistingPack() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack = store.createPack(name: "Test", questions: questions)

        let found = store.pack(withId: pack.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Test")
    }

    func testPackWithId_returnsNilForNonexistent() {
        let store = KBLocalPackStore()

        let found = store.pack(withId: "nonexistent")
        XCTAssertNil(found)
    }

    // MARK: - Multiple Packs Tests

    func testCreateMultiplePacks_allStored() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        _ = store.createPack(name: "Pack 1", questions: questions)
        _ = store.createPack(name: "Pack 2", questions: questions)
        _ = store.createPack(name: "Pack 3", questions: questions)

        XCTAssertEqual(store.localPacks.count, 3)
    }

    func testCreateMultiplePacks_haveUniqueIds() {
        let store = KBLocalPackStore()

        let questions = createTestQuestions(count: 5)
        let pack1 = store.createPack(name: "Pack 1", questions: questions)
        let pack2 = store.createPack(name: "Pack 2", questions: questions)
        let pack3 = store.createPack(name: "Pack 3", questions: questions)

        let ids = [pack1.id, pack2.id, pack3.id]
        let uniqueIds = Set(ids)
        XCTAssertEqual(uniqueIds.count, 3, "All pack IDs should be unique")
    }

    // MARK: - Helper Methods

    private func createTestQuestions(count: Int) -> [KBQuestion] {
        (0..<count).map { index in
            createQuestion(
                domain: KBDomain.allCases[index % KBDomain.allCases.count],
                difficulty: (index % 5) + 1
            )
        }
    }

    private func createQuestion(domain: KBDomain, difficulty: Int) -> KBQuestion {
        KBQuestion(
            id: UUID(),
            text: "Test question?",
            answer: KBAnswer(
                primary: "Test answer",
                acceptable: nil,
                answerType: .text
            ),
            domain: domain,
            subdomain: nil,
            difficulty: KBDifficulty.from(level: difficulty),
            source: nil
        )
    }
}
