// UnaMentis - Kyutai Pocket TTS Model Manager
// Manages Kyutai Pocket TTS model information and server-side inference
//
// Part of Services/TTS
//
// Note: Kyutai Pocket TTS uses stateful streaming transformers that require
// PyTorch/Python for inference. Native iOS CoreML conversion is not yet
// available. Model files are bundled for future offline support, but current
// inference uses server-side processing via the /api/tts/kyutai-pocket endpoint.

import Foundation
import OSLog

// MARK: - Model Manager

/// Manager for Kyutai Pocket TTS model information
///
/// Model files (CC-BY-4.0 licensed, ~230MB total) are bundled for future
/// offline support. Current inference uses server-side processing.
///
/// Bundled Components:
/// - Model Weights (model.safetensors) - 225MB
/// - Tokenizer (tokenizer.model) - 60KB
/// - Voice Embeddings (voices/*.safetensors) - 4.2MB total
actor KyutaiPocketModelManager {
    private let logger = Logger(subsystem: "com.unamentis", category: "KyutaiPocketModelManager")

    // MARK: - Model State

    /// Current state of the model
    enum ModelState: Sendable, Equatable {
        case notBundled         // Models not found in app bundle
        case available          // Models bundled, server inference ready
        case loading(Float)     // Checking model files
        case loaded             // Ready for server-side inference
        case error(String)      // Error occurred

        static func == (lhs: ModelState, rhs: ModelState) -> Bool {
            switch (lhs, rhs) {
            case (.notBundled, .notBundled),
                 (.available, .available),
                 (.loaded, .loaded):
                return true
            case let (.loading(p1), .loading(p2)):
                return abs(p1 - p2) < 0.01
            case let (.error(e1), .error(e2)):
                return e1 == e2
            default:
                return false
            }
        }

        var isReady: Bool {
            self == .loaded
        }

        var displayText: String {
            switch self {
            case .notBundled: return "Models Not Bundled"
            case .available: return "Ready"
            case .loading(let progress): return "Loading \(Int(progress * 100))%"
            case .loaded: return "Ready (Server)"
            case .error(let message): return "Error: \(message)"
            }
        }
    }

    private(set) var state: ModelState = .notBundled

    // MARK: - Model Information

    /// Information about bundled model files
    struct ModelInfo: Sendable {
        let modelPath: URL?
        let tokenizerPath: URL?
        let voicesDirectory: URL?
        let totalSizeMB: Float

        var hasAllFiles: Bool {
            modelPath != nil && tokenizerPath != nil && voicesDirectory != nil
        }
    }

    private var modelInfo: ModelInfo?

    // MARK: - Configuration

    /// Model component paths relative to bundle
    private enum ModelComponent: String, CaseIterable {
        case model = "kyutai-pocket-ios/model"
        case tokenizer = "kyutai-pocket-ios/tokenizer"
        case voices = "kyutai-pocket-ios/voices"

        /// Bundle resource name (directory path)
        var bundleResourceName: String {
            rawValue
        }

        /// Bundle resource extension
        var bundleExtension: String {
            switch self {
            case .model:
                return "safetensors"
            case .tokenizer:
                return "model"
            case .voices:
                return ""  // Directory
            }
        }

        /// Approximate size in MB
        var approximateSizeMB: Float {
            switch self {
            case .model: return 225.0
            case .tokenizer: return 0.06
            case .voices: return 4.2
            }
        }
    }

    // MARK: - Initialization

    init() {
        // Check model availability on init
        Task {
            await checkModelAvailability()
        }
    }

    // MARK: - Public API

    /// Get current model state
    nonisolated func currentState() async -> ModelState {
        await state
    }

    /// Check if models are available (bundled with the app)
    func isAvailable() -> Bool {
        modelInfo?.hasAllFiles ?? false
    }

    /// Legacy method for backwards compatibility
    func isDownloaded() -> Bool {
        isAvailable()
    }

    /// Get total model size in MB
    func totalSizeMB() -> Float {
        ModelComponent.allCases.reduce(0) { $0 + $1.approximateSizeMB }
    }

    /// Legacy method - models are bundled, no download needed
    func totalDownloadSizeMB() -> Float {
        totalSizeMB()
    }

    /// Load model configuration (validates bundled files)
    /// - Parameter config: Configuration (used for logging only, inference is server-side)
    func loadModels(config: KyutaiPocketTTSConfig) async throws {
        logger.info("Validating Kyutai Pocket TTS model files")
        state = .loading(0.0)

        // For now, models are available but inference happens server-side
        // This validates that the bundled files are present for future offline support
        guard isAvailable() else {
            // Models not bundled, but server inference still works
            logger.warning("Model files not bundled - server inference only")
            state = .loaded  // Still usable via server
            return
        }

        state = .loading(0.5)

        // Validate model files exist
        if let info = modelInfo {
            logger.info("Model file: \(info.modelPath?.path ?? "not found")")
            logger.info("Tokenizer: \(info.tokenizerPath?.path ?? "not found")")
            logger.info("Voices: \(info.voicesDirectory?.path ?? "not found")")
        }

        state = .loaded
        logger.info("Model validation complete - ready for server-side inference")
    }

    /// Unload models from memory (currently no-op since inference is server-side)
    func unloadModels() {
        logger.info("Resetting Kyutai Pocket TTS state")
        state = .available
    }

    /// Get model info for server-side inference
    func getModelInfo() -> ModelInfo? {
        modelInfo
    }

    /// Get available voice names
    func getAvailableVoices() -> [String] {
        KyutaiPocketVoice.allCases.map { $0.displayName }
    }

    // MARK: - Private Helpers

    private func checkModelAvailability() {
        // Check for bundled model files
        let modelPath = findBundledFile(name: "model", extension: "safetensors", inDirectory: "kyutai-pocket-ios")
        let tokenizerPath = findBundledFile(name: "tokenizer", extension: "model", inDirectory: "kyutai-pocket-ios")
        let voicesDir = findBundledDirectory(name: "voices", inDirectory: "kyutai-pocket-ios")

        modelInfo = ModelInfo(
            modelPath: modelPath,
            tokenizerPath: tokenizerPath,
            voicesDirectory: voicesDir,
            totalSizeMB: totalSizeMB()
        )

        if modelInfo?.hasAllFiles == true {
            state = .available
            logger.info("Bundled model files found")
        } else {
            // Not an error - server inference still works without bundled models
            state = .available
            logger.info("Model files not bundled - using server-side inference")
        }
    }

    private func findBundledFile(name: String, extension ext: String, inDirectory directory: String) -> URL? {
        // Try finding in models subdirectory first
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: directory) {
            return url
        }
        // Try at top level
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    private func findBundledDirectory(name: String, inDirectory directory: String) -> URL? {
        guard let baseURL = Bundle.main.resourceURL else { return nil }
        let dirURL = baseURL.appendingPathComponent(directory).appendingPathComponent(name)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return dirURL
        }
        return nil
    }
}

// MARK: - Model Error

/// Errors for Kyutai Pocket model operations
enum KyutaiPocketModelError: Error, LocalizedError {
    case modelsNotBundled
    case serverUnavailable
    case networkError(Error)
    case invalidVoice
    case inferenceError(String)

    var errorDescription: String? {
        switch self {
        case .modelsNotBundled:
            return "Kyutai Pocket TTS models are not bundled with the app."
        case .serverUnavailable:
            return "TTS server is not available. Check your network connection."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidVoice:
            return "Invalid voice specified."
        case .inferenceError(let reason):
            return "Speech synthesis failed: \(reason)"
        }
    }
}

// MARK: - Model State Publisher

/// Observable wrapper for model state
@MainActor
final class KyutaiPocketModelStateObserver: ObservableObject {
    @Published var state: KyutaiPocketModelManager.ModelState = .notBundled

    private let manager: KyutaiPocketModelManager

    init(manager: KyutaiPocketModelManager) {
        self.manager = manager
        Task {
            await refreshState()
        }
    }

    func refreshState() async {
        state = await manager.currentState()
    }
}

// MARK: - Preview Support

#if DEBUG
extension KyutaiPocketModelManager {
    static func preview() -> KyutaiPocketModelManager {
        KyutaiPocketModelManager()
    }
}
#endif
