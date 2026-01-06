// UnaMentis - Latency Metrics Collector
// High-precision metrics collection for latency tests
//
// Part of the Audio Latency Test Harness

import Foundation
import Darwin

// MARK: - Mach Time Utilities

/// Convert mach absolute time to milliseconds
private func machTimeToMs(_ machTime: UInt64) -> Double {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let nanoseconds = Double(machTime) * Double(timebase.numer) / Double(timebase.denom)
    return nanoseconds / 1_000_000.0
}

/// Get current time in mach absolute units
private func currentMachTime() -> UInt64 {
    mach_absolute_time()
}

// MARK: - Latency Metrics Collector

/// High-precision metrics collection for latency tests
///
/// Uses mach_absolute_time for sub-millisecond precision timing.
/// Collects CPU, memory, and thermal metrics during test execution.
public actor LatencyMetricsCollector {

    // MARK: - Test Context

    private var testId: UUID = UUID()
    private var configId: String = ""
    private var scenarioName: String = ""
    private var repetition: Int = 0
    private var testStartTime: UInt64 = 0

    // MARK: - Configuration Snapshot

    private var sttConfig: STTTestConfig?
    private var llmConfig: LLMTestConfig?
    private var ttsConfig: TTSTestConfig?
    private var audioConfig: AudioEngineTestConfig?
    private var networkProfile: NetworkProfile = .localhost

    // MARK: - Stage Latencies (milliseconds)

    private var sttLatencyMs: Double?
    private var llmTTFBMs: Double = 0
    private var llmCompletionMs: Double = 0
    private var ttsTTFBMs: Double = 0
    private var ttsCompletionMs: Double = 0
    private var e2eLatencyMs: Double = 0

    // MARK: - Quality Metrics

    private var sttConfidence: Float?
    private var ttsAudioDurationMs: Double?
    private var llmInputTokens: Int?
    private var llmOutputTokens: Int?

    // MARK: - Resource Samples

    private var cpuSamples: [Double] = []
    private var memorySamples: [UInt64] = []
    private var thermalStates: [ProcessInfo.ThermalState] = []

    // MARK: - Errors

    private var errors: [String] = []

    // MARK: - Sampling Task

    private var samplingTask: Task<Void, Never>?
    private let samplingIntervalMs: UInt64 = 100

    // MARK: - Initialization

    public init() {}

    // MARK: - Test Lifecycle

    /// Start a new test measurement
    public func startTest(
        configId: String,
        scenarioName: String,
        repetition: Int,
        sttConfig: STTTestConfig,
        llmConfig: LLMTestConfig,
        ttsConfig: TTSTestConfig,
        audioConfig: AudioEngineTestConfig,
        networkProfile: NetworkProfile
    ) {
        // Reset state
        testId = UUID()
        self.configId = configId
        self.scenarioName = scenarioName
        self.repetition = repetition
        self.sttConfig = sttConfig
        self.llmConfig = llmConfig
        self.ttsConfig = ttsConfig
        self.audioConfig = audioConfig
        self.networkProfile = networkProfile

        // Reset metrics
        sttLatencyMs = nil
        llmTTFBMs = 0
        llmCompletionMs = 0
        ttsTTFBMs = 0
        ttsCompletionMs = 0
        e2eLatencyMs = 0

        sttConfidence = nil
        ttsAudioDurationMs = nil
        llmInputTokens = nil
        llmOutputTokens = nil

        cpuSamples = []
        memorySamples = []
        thermalStates = []
        errors = []

        // Record start time
        testStartTime = currentMachTime()

        // Start resource sampling
        startResourceSampling()
    }

    /// Finalize test and return result
    public func finalizeTest() -> TestResult {
        // Stop sampling
        stopResourceSampling()

        // Calculate E2E if not explicitly set
        if e2eLatencyMs == 0 {
            e2eLatencyMs = machTimeToMs(currentMachTime() - testStartTime)
        }

        // Build result
        var result = TestResult(
            id: testId,
            configId: configId,
            scenarioName: scenarioName,
            repetition: repetition,
            timestamp: Date(),
            sttLatencyMs: sttLatencyMs,
            llmTTFBMs: llmTTFBMs,
            llmCompletionMs: llmCompletionMs,
            ttsTTFBMs: ttsTTFBMs,
            ttsCompletionMs: ttsCompletionMs,
            e2eLatencyMs: e2eLatencyMs,
            networkProfile: networkProfile,
            sttConfidence: sttConfidence,
            ttsAudioDurationMs: ttsAudioDurationMs,
            llmOutputTokens: llmOutputTokens,
            llmInputTokens: llmInputTokens,
            peakCPUPercent: cpuSamples.max() ?? 0,
            peakMemoryMB: Double(memorySamples.max() ?? 0) / 1_000_000.0,
            thermalState: mostSevereThermalState().rawValue,
            sttConfig: sttConfig ?? .defaultDeepgram,
            llmConfig: llmConfig ?? .defaultClaude,
            ttsConfig: ttsConfig ?? .defaultChatterbox,
            audioConfig: audioConfig ?? .default,
            errors: errors
        )

        // Add network projections
        result = result.withNetworkProjections()

        return result
    }

    // MARK: - Latency Recording

    /// Record STT latency
    public func recordSTTLatency(_ ms: Double) {
        sttLatencyMs = ms
    }

    /// Record STT latency from mach time
    public func recordSTTLatencyFromStart(_ startTime: UInt64) {
        sttLatencyMs = machTimeToMs(currentMachTime() - startTime)
    }

    /// Record LLM time to first token
    public func recordLLMTTFB(_ ms: Double) {
        llmTTFBMs = ms
    }

    /// Record LLM TTFB from mach time
    public func recordLLMTTFBFromStart(_ startTime: UInt64) {
        llmTTFBMs = machTimeToMs(currentMachTime() - startTime)
    }

    /// Record LLM completion time
    public func recordLLMCompletion(_ ms: Double) {
        llmCompletionMs = ms
    }

    /// Record LLM completion from mach time
    public func recordLLMCompletionFromStart(_ startTime: UInt64) {
        llmCompletionMs = machTimeToMs(currentMachTime() - startTime)
    }

    /// Record TTS time to first byte
    public func recordTTSTTFB(_ ms: Double) {
        ttsTTFBMs = ms
    }

    /// Record TTS TTFB from mach time
    public func recordTTSTTFBFromStart(_ startTime: UInt64) {
        ttsTTFBMs = machTimeToMs(currentMachTime() - startTime)
    }

    /// Record TTS completion time
    public func recordTTSCompletion(_ ms: Double) {
        ttsCompletionMs = ms
    }

    /// Record TTS completion from mach time
    public func recordTTSCompletionFromStart(_ startTime: UInt64) {
        ttsCompletionMs = machTimeToMs(currentMachTime() - startTime)
    }

    /// Record E2E latency
    public func recordE2ELatency(_ ms: Double) {
        e2eLatencyMs = ms
    }

    /// Record E2E latency from test start
    public func recordE2ELatencyFromTestStart() {
        e2eLatencyMs = machTimeToMs(currentMachTime() - testStartTime)
    }

    // MARK: - Quality Metrics Recording

    /// Record STT confidence
    public func recordSTTConfidence(_ confidence: Float) {
        sttConfidence = confidence
    }

    /// Record TTS audio duration
    public func recordTTSAudioDuration(_ ms: Double) {
        ttsAudioDurationMs = ms
    }

    /// Record LLM token counts
    public func recordLLMTokenCounts(input: Int, output: Int) {
        llmInputTokens = input
        llmOutputTokens = output
    }

    // MARK: - Error Recording

    /// Record an error during test execution
    public func recordError(_ error: Error) {
        errors.append(error.localizedDescription)
    }

    /// Record an error message
    public func recordErrorMessage(_ message: String) {
        errors.append(message)
    }

    // MARK: - Resource Sampling

    private func startResourceSampling() {
        samplingTask = Task { [samplingIntervalMs] in
            while !Task.isCancelled {
                await self.sampleResources()
                try? await Task.sleep(nanoseconds: samplingIntervalMs * 1_000_000)
            }
        }
    }

    private func stopResourceSampling() {
        samplingTask?.cancel()
        samplingTask = nil
    }

    private func sampleResources() {
        cpuSamples.append(getCurrentCPUUsage())
        memorySamples.append(getCurrentMemoryUsage())
        thermalStates.append(ProcessInfo.processInfo.thermalState)
    }

    private func mostSevereThermalState() -> ThermalStateValue {
        let severityOrder: [ProcessInfo.ThermalState] = [
            .nominal, .fair, .serious, .critical
        ]

        var maxIndex = 0
        for state in thermalStates {
            if let index = severityOrder.firstIndex(of: state), index > maxIndex {
                maxIndex = index
            }
        }

        switch severityOrder[maxIndex] {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .unknown
        }
    }

    // MARK: - System Metrics

    private func getCurrentCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount = mach_msg_type_number_t()

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else {
            return 0
        }

        var totalCPU: Double = 0

        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }

            if infoResult == KERN_SUCCESS {
                if info.flags != TH_FLAGS_IDLE {
                    totalCPU += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
        }

        // Deallocate thread list
        let threadListSize = vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), threadListSize)

        return totalCPU
    }

    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    // MARK: - Timing Utilities (Public)

    /// Get current mach time for external timing
    public func getCurrentTime() -> UInt64 {
        currentMachTime()
    }

    /// Convert mach time difference to milliseconds
    public func machTimeToMilliseconds(_ machTime: UInt64) -> Double {
        machTimeToMs(machTime)
    }
}

// MARK: - Thermal State Value

private enum ThermalStateValue: String {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
    case unknown = "unknown"
}

// MARK: - Test Phase Timer

/// Helper for timing individual test phases
public struct TestPhaseTimer: Sendable {
    private let startTime: UInt64

    public init() {
        self.startTime = mach_absolute_time()
    }

    /// Get elapsed time in milliseconds
    public var elapsedMs: Double {
        machTimeToMs(mach_absolute_time() - startTime)
    }

    /// Get elapsed time and return mach time for chaining
    public var currentMachTime: UInt64 {
        mach_absolute_time()
    }

    public var startMachTime: UInt64 {
        startTime
    }
}
