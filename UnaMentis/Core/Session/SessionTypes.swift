// UnaMentis - Session Types
// Enhanced session tracking data types for comprehensive history
//
// Part of Core Components (TDD Section 3.2)

import Foundation

// MARK: - Session Type

/// The type of learning session
public enum SessionType: String, Codable, Sendable, CaseIterable {
    case chat = "chat"
    case module = "module"
    case curriculum = "curriculum"

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .module: return "Module"
        case .curriculum: return "Curriculum"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .module: return "square.stack.3d.up"
        case .curriculum: return "book.closed"
        }
    }

    /// Description for help text
    public var description: String {
        switch self {
        case .chat: return "Free-form conversation with the AI tutor"
        case .module: return "Structured learning module with specific objectives"
        case .curriculum: return "Curriculum-based learning following a study plan"
        }
    }
}

// MARK: - Provider Location

/// Where a provider is running
public enum ProviderLocation: String, Codable, Sendable {
    case cloud = "cloud"
    case selfHosted = "self_hosted"
    case onDevice = "on_device"

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .cloud: return "Cloud"
        case .selfHosted: return "Self-Hosted"
        case .onDevice: return "On-Device"
        }
    }

    /// Short label for badges
    public var shortLabel: String {
        switch self {
        case .cloud: return "Cloud"
        case .selfHosted: return "Server"
        case .onDevice: return "Local"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .cloud: return "cloud"
        case .selfHosted: return "server.rack"
        case .onDevice: return "iphone"
        }
    }

    /// Whether this location incurs API costs
    public var hasCost: Bool {
        self == .cloud
    }
}

// MARK: - Provider Info

/// Information about a specific provider used in a session
public struct SessionProviderInfo: Codable, Sendable, Equatable {
    /// Provider identifier (e.g., "deepgram", "openai", "apple")
    public let providerId: String

    /// Human-readable provider name (e.g., "Deepgram Nova-3", "GPT-4o")
    public let providerName: String

    /// Model identifier if applicable (e.g., "gpt-4o", "nova-3")
    public let modelId: String?

    /// Where the provider is running
    public let location: ProviderLocation

    /// Server hostname if self-hosted
    public let serverHost: String?

    public init(
        providerId: String,
        providerName: String,
        modelId: String? = nil,
        location: ProviderLocation,
        serverHost: String? = nil
    ) {
        self.providerId = providerId
        self.providerName = providerName
        self.modelId = modelId
        self.location = location
        self.serverHost = serverHost
    }

    /// Display string for the provider
    public var displayString: String {
        if let modelId = modelId, !modelId.isEmpty {
            return "\(providerName) (\(modelId))"
        }
        return providerName
    }

    /// Short display string
    public var shortDisplayString: String {
        modelId ?? providerName
    }
}

/// Collection of all providers used in a session
public struct SessionProviders: Codable, Sendable {
    public let stt: SessionProviderInfo?
    public let llm: SessionProviderInfo?
    public let tts: SessionProviderInfo?

    public init(
        stt: SessionProviderInfo? = nil,
        llm: SessionProviderInfo? = nil,
        tts: SessionProviderInfo? = nil
    ) {
        self.stt = stt
        self.llm = llm
        self.tts = tts
    }

    /// Whether any provider has associated costs
    public var hasCosts: Bool {
        [stt, llm, tts].compactMap { $0 }.contains { $0.location.hasCost }
    }

    /// Get all unique locations used
    public var locations: Set<ProviderLocation> {
        Set([stt?.location, llm?.location, tts?.location].compactMap { $0 })
    }
}

// MARK: - Curriculum Session Info

/// Information about curriculum-based learning in a session
public struct CurriculumSessionInfo: Codable, Sendable {
    /// Source of the curriculum (e.g., "Khan Academy", "Custom")
    public let source: String?

    /// Curriculum name
    public let curriculumName: String

    /// Curriculum ID for linking
    public let curriculumId: UUID?

    /// Topics covered in this session
    public let topicsCovered: [TopicSummary]

    public init(
        source: String? = nil,
        curriculumName: String,
        curriculumId: UUID? = nil,
        topicsCovered: [TopicSummary] = []
    ) {
        self.source = source
        self.curriculumName = curriculumName
        self.curriculumId = curriculumId
        self.topicsCovered = topicsCovered
    }

    /// Summary of a topic covered
    public struct TopicSummary: Codable, Sendable, Identifiable {
        public let id: UUID
        public let title: String
        public let masteryBefore: Float?
        public let masteryAfter: Float?
        public let timeSpent: TimeInterval

        public init(
            id: UUID,
            title: String,
            masteryBefore: Float? = nil,
            masteryAfter: Float? = nil,
            timeSpent: TimeInterval = 0
        ) {
            self.id = id
            self.title = title
            self.masteryBefore = masteryBefore
            self.masteryAfter = masteryAfter
            self.timeSpent = timeSpent
        }

        /// Mastery improvement if both values available
        public var masteryImprovement: Float? {
            guard let before = masteryBefore, let after = masteryAfter else { return nil }
            return after - before
        }
    }
}

// MARK: - Validation Result

/// Results from validation, testing, or confirmation during a session
public struct SessionValidationResult: Codable, Sendable, Identifiable {
    public let id: UUID

    /// Type of validation
    public let type: ValidationType

    /// Whether validation passed
    public let passed: Bool

    /// Score if applicable (0.0 - 1.0)
    public let score: Float?

    /// Number of correct answers
    public let correctCount: Int?

    /// Total number of questions/items
    public let totalCount: Int?

    /// Timestamp of validation
    public let timestamp: Date

    /// Details about the validation
    public let details: String?

    public init(
        id: UUID = UUID(),
        type: ValidationType,
        passed: Bool,
        score: Float? = nil,
        correctCount: Int? = nil,
        totalCount: Int? = nil,
        timestamp: Date = Date(),
        details: String? = nil
    ) {
        self.id = id
        self.type = type
        self.passed = passed
        self.score = score
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.timestamp = timestamp
        self.details = details
    }

    /// Type of validation performed
    public enum ValidationType: String, Codable, Sendable {
        case quiz = "quiz"
        case comprehensionCheck = "comprehension_check"
        case practiceExercise = "practice_exercise"
        case knowledgeTest = "knowledge_test"
        case confirmation = "confirmation"

        public var displayName: String {
            switch self {
            case .quiz: return "Quiz"
            case .comprehensionCheck: return "Comprehension Check"
            case .practiceExercise: return "Practice Exercise"
            case .knowledgeTest: return "Knowledge Test"
            case .confirmation: return "Confirmation"
            }
        }

        public var iconName: String {
            switch self {
            case .quiz: return "checkmark.circle"
            case .comprehensionCheck: return "lightbulb"
            case .practiceExercise: return "pencil.and.outline"
            case .knowledgeTest: return "graduationcap"
            case .confirmation: return "hand.thumbsup"
            }
        }
    }

    /// Formatted score string
    public var scoreString: String? {
        if let score = score {
            return String(format: "%.0f%%", score * 100)
        }
        if let correct = correctCount, let total = totalCount, total > 0 {
            return "\(correct)/\(total)"
        }
        return nil
    }
}

// MARK: - Enhanced Session Info

/// Complete enhanced session information for storage
public struct EnhancedSessionInfo: Codable, Sendable {
    /// Type of session
    public let sessionType: SessionType

    /// Providers used
    public let providers: SessionProviders

    /// Curriculum info if this is a curriculum session
    public let curriculumInfo: CurriculumSessionInfo?

    /// Validation results from this session
    public let validationResults: [SessionValidationResult]

    public init(
        sessionType: SessionType = .chat,
        providers: SessionProviders = SessionProviders(),
        curriculumInfo: CurriculumSessionInfo? = nil,
        validationResults: [SessionValidationResult] = []
    ) {
        self.sessionType = sessionType
        self.providers = providers
        self.curriculumInfo = curriculumInfo
        self.validationResults = validationResults
    }

    /// Whether there are any validation results
    public var hasValidation: Bool {
        !validationResults.isEmpty
    }

    /// Overall validation pass rate
    public var validationPassRate: Float? {
        guard !validationResults.isEmpty else { return nil }
        let passedCount = validationResults.filter { $0.passed }.count
        return Float(passedCount) / Float(validationResults.count)
    }
}

// MARK: - Provider Detection Helpers

/// Helper to create SessionProviderInfo from service providers
public enum ProviderDetection {

    /// Create STT provider info from provider enum
    public static func sttInfo(from provider: STTProvider, serverHost: String? = nil) -> SessionProviderInfo {
        SessionProviderInfo(
            providerId: provider.identifier,
            providerName: provider.displayName,
            modelId: modelIdForSTT(provider),
            location: locationForSTT(provider),
            serverHost: provider.isSelfHosted ? serverHost : nil
        )
    }

    /// Create LLM provider info from provider and model
    public static func llmInfo(from provider: LLMProvider, model: String, serverHost: String? = nil) -> SessionProviderInfo {
        SessionProviderInfo(
            providerId: provider.identifier,
            providerName: provider.displayName,
            modelId: model,
            location: locationForLLM(provider),
            serverHost: provider == .selfHosted ? serverHost : nil
        )
    }

    /// Create TTS provider info from provider enum
    public static func ttsInfo(from provider: TTSProvider, voiceId: String? = nil, serverHost: String? = nil) -> SessionProviderInfo {
        SessionProviderInfo(
            providerId: provider.identifier,
            providerName: provider.displayName,
            modelId: voiceId,
            location: locationForTTS(provider),
            serverHost: provider.isSelfHosted ? serverHost : nil
        )
    }

    private static func modelIdForSTT(_ provider: STTProvider) -> String? {
        switch provider {
        case .deepgramNova3: return "nova-3"
        case .groqWhisper: return "whisper-large-v3"
        case .glmASRNano, .glmASROnDevice: return "glm-asr-nano"
        default: return nil
        }
    }

    private static func locationForSTT(_ provider: STTProvider) -> ProviderLocation {
        if provider.isOnDevice { return .onDevice }
        if provider.isSelfHosted { return .selfHosted }
        return .cloud
    }

    private static func locationForLLM(_ provider: LLMProvider) -> ProviderLocation {
        switch provider {
        case .localMLX: return .onDevice
        case .selfHosted: return .selfHosted
        default: return .cloud
        }
    }

    private static func locationForTTS(_ provider: TTSProvider) -> ProviderLocation {
        if provider.isOnDevice { return .onDevice }
        if provider.isSelfHosted { return .selfHosted }
        return .cloud
    }
}
