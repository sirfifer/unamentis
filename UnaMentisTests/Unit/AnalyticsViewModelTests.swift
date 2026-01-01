// UnaMentis - AnalyticsViewModelTests
// Unit tests for AnalyticsViewModel
//
// Tests cover:
// - Data refreshing from TelemetryEngine
// - Export generation
//
// Architecture Note:
// AnalyticsViewModel no longer holds metrics directly. The view observes
// TelemetryPublisher (via TelemetryEngine.publisher) for reactive updates.
// The ViewModel only handles export and refresh operations.

import XCTest
import Combine
@testable import UnaMentis

@MainActor
final class AnalyticsViewModelTests: XCTestCase {

    var viewModel: AnalyticsViewModel!
    var telemetry: TelemetryEngine!

    override func setUp() async throws {
        viewModel = AnalyticsViewModel()
        telemetry = TelemetryEngine()
    }

    override func tearDown() async throws {
        viewModel = nil
        telemetry = nil
    }

    func testRefresh_updatesPublisher() async {
        guard let telemetry = telemetry else {
            XCTFail("Telemetry not initialized")
            return
        }

        // Given initialized telemetry with data
        await telemetry.startSession()
        await telemetry.recordEvent(.userFinishedSpeaking(transcript: "Test"))

        // When refreshing view model
        await viewModel.refresh(telemetry: telemetry)

        // Allow time for fire-and-forget Task to update publisher
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then metrics should be updated in the publisher
        // Access publisher (nonisolated let property of actor)
        let publisher = telemetry.publisher
        XCTAssertEqual(publisher.metrics.turnsTotal, 1)
    }

    func testGenerateExport_createsURL() async {
        // Given telemetry data
        await telemetry.recordEvent(.sessionStarted)

        // When generating export
        await viewModel.generateExport(telemetry: telemetry)

        // Then exportURL should be set and file should exist
        XCTAssertNotNil(viewModel.exportURL)
        if let url = viewModel.exportURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }
}
