//
//  KBPackServiceTests.swift
//  UnaMentisTests
//
//  Tests for KBPackService - fetching packs from management API.
//

import XCTest
@testable import UnaMentis

@MainActor
final class KBPackServiceTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_startsWithEmptyPacks() {
        let service = KBPackService()
        XCTAssertTrue(service.packs.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    func testInit_usesCustomBaseURL() {
        let customURL = URL(string: "https://api.example.com")!
        let service = KBPackService(baseURL: customURL)

        // Service should be created without error
        XCTAssertNotNil(service)
    }

    // MARK: - Error Type Tests

    func testKBPackServiceError_invalidResponseDescription() {
        let error = KBPackServiceError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid response from server")
    }

    func testKBPackServiceError_serverErrorDescription() {
        let error = KBPackServiceError.serverError(statusCode: 404)
        XCTAssertEqual(error.errorDescription, "Server error (status code: 404)")
    }

    func testKBPackServiceError_serverErrorVariousStatusCodes() {
        let error400 = KBPackServiceError.serverError(statusCode: 400)
        XCTAssertTrue(error400.errorDescription?.contains("400") ?? false)

        let error500 = KBPackServiceError.serverError(statusCode: 500)
        XCTAssertTrue(error500.errorDescription?.contains("500") ?? false)

        let error503 = KBPackServiceError.serverError(statusCode: 503)
        XCTAssertTrue(error503.errorDescription?.contains("503") ?? false)
    }

    func testKBPackServiceError_networkErrorDescription() {
        let underlying = NSError(domain: "test", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        let error = KBPackServiceError.networkError(underlying: underlying)

        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
    }

    func testKBPackServiceError_decodingErrorDescription() {
        let underlying = NSError(domain: "test", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Invalid JSON"
        ])
        let error = KBPackServiceError.decodingError(underlying: underlying)

        XCTAssertTrue(error.errorDescription?.contains("Failed to parse") ?? false)
    }

    // MARK: - Error Conformance Tests

    func testKBPackServiceError_conformsToLocalizedError() {
        let error: LocalizedError = KBPackServiceError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
    }

    func testKBPackServiceError_allCasesHaveDescriptions() {
        let errors: [KBPackServiceError] = [
            .invalidResponse,
            .serverError(statusCode: 500),
            .networkError(underlying: NSError(domain: "test", code: 0)),
            .decodingError(underlying: NSError(domain: "test", code: 0))
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error \(error) description should not be empty")
        }
    }
}

// MARK: - KBPackService State Tests

@MainActor
final class KBPackServiceStateTests: XCTestCase {

    func testIsLoading_initiallyFalse() {
        let service = KBPackService()
        XCTAssertFalse(service.isLoading)
    }

    func testError_initiallyNil() {
        let service = KBPackService()
        XCTAssertNil(service.error)
    }

    func testPacks_initiallyEmpty() {
        let service = KBPackService()
        XCTAssertTrue(service.packs.isEmpty)
    }
}

// MARK: - Integration Tests (require server)

// These tests require the management API to be running.
// They are commented out for unit test suite but can be enabled for integration testing.
/*
@MainActor
final class KBPackServiceIntegrationTests: XCTestCase {

    var service: KBPackService!

    override func setUp() {
        super.setUp()
        service = KBPackService()
    }

    func testFetchPacks_whenServerAvailable_loadsPacks() async {
        await service.fetchPacks()

        // If server is available, should have loaded packs
        // If not available, error should be set
        XCTAssertTrue(service.packs.count > 0 || service.error != nil)
        XCTAssertFalse(service.isLoading)
    }

    func testFetchPack_whenPackExists_returnsPack() async throws {
        // First fetch all packs
        await service.fetchPacks()

        guard let firstPack = service.packs.first else {
            throw XCTSkip("No packs available on server")
        }

        // Fetch specific pack
        let pack = try await service.fetchPack(id: firstPack.id)
        XCTAssertEqual(pack.id, firstPack.id)
    }

    func testFetchPackQuestions_whenPackExists_returnsQuestions() async throws {
        // First fetch all packs
        await service.fetchPacks()

        guard let firstPack = service.packs.first else {
            throw XCTSkip("No packs available on server")
        }

        // Fetch questions for pack
        let questions = try await service.fetchPackQuestions(packId: firstPack.id)
        XCTAssertFalse(questions.isEmpty)
    }
}
*/
