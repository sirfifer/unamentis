// VoiceLearn - Curriculum Models
// Supporting types for the Curriculum Management System
//
// Part of Curriculum Layer (TDD Section 4)

import Foundation
import CoreData

// MARK: - Topic Status

/// Status of a topic in the learning progression
public enum TopicStatus: String, Codable, Sendable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case reviewing = "reviewing"

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .reviewing: return "Reviewing"
        }
    }
}

// MARK: - Document Type

/// Type of document in the curriculum
public enum DocumentType: String, Codable, Sendable, CaseIterable {
    case pdf = "pdf"
    case text = "text"
    case markdown = "markdown"
    case transcript = "transcript"

    /// File extensions associated with this type
    public var fileExtensions: [String] {
        switch self {
        case .pdf: return ["pdf"]
        case .text: return ["txt"]
        case .markdown: return ["md", "markdown"]
        case .transcript: return ["json"]
        }
    }

    /// Detect type from file extension
    public static func from(fileExtension: String) -> DocumentType? {
        let ext = fileExtension.lowercased()
        for type in DocumentType.allCases {
            if type.fileExtensions.contains(ext) {
                return type
            }
        }
        return nil
    }
}

// MARK: - Document Chunk

/// A chunk of document text with embedding for semantic search
public struct DocumentChunk: Codable, Sendable, Identifiable {
    /// Unique identifier for this chunk
    public let id: UUID

    /// ID of the source document
    public let documentId: UUID

    /// Text content of this chunk
    public let text: String

    /// Vector embedding for semantic search
    public let embedding: [Float]

    /// Page number if from PDF (1-indexed)
    public let pageNumber: Int?

    /// Index of this chunk within the document (0-indexed)
    public let chunkIndex: Int

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        text: String,
        embedding: [Float],
        pageNumber: Int? = nil,
        chunkIndex: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.text = text
        self.embedding = embedding
        self.pageNumber = pageNumber
        self.chunkIndex = chunkIndex
    }
}

// MARK: - Learning Objective

/// A learning objective for a topic
public struct LearningObjective: Codable, Sendable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Description of the objective
    public let description: String

    /// Whether the objective has been met
    public var isMet: Bool

    /// Evidence of meeting the objective (e.g., transcript excerpts)
    public var evidence: [String]?

    public init(
        id: UUID = UUID(),
        description: String,
        isMet: Bool = false,
        evidence: [String]? = nil
    ) {
        self.id = id
        self.description = description
        self.isMet = isMet
        self.evidence = evidence
    }
}

// MARK: - Transcript Turn

/// A single turn in a conversation transcript
public struct TranscriptTurn: Codable, Sendable {
    /// Speaker identifier ("user" or "assistant")
    public let speaker: String

    /// Transcribed text
    public let transcript: String

    /// Timestamp
    public let timestamp: Date

    public init(speaker: String, transcript: String, timestamp: Date = Date()) {
        self.speaker = speaker
        self.transcript = transcript
        self.timestamp = timestamp
    }
}

// MARK: - Curriculum Error

/// Errors that can occur in curriculum operations
public enum CurriculumError: Error, Sendable {
    case curriculumNotFound(UUID)
    case topicNotFound(UUID)
    case documentNotFound(UUID)
    case progressNotFound(UUID)
    case invalidTopicOrder
    case saveFailed(String)
    case loadFailed(String)
    case contextGenerationFailed(String)
}

extension CurriculumError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .curriculumNotFound(let id):
            return "Curriculum not found: \(id)"
        case .topicNotFound(let id):
            return "Topic not found: \(id)"
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .progressNotFound(let id):
            return "Progress not found for topic: \(id)"
        case .invalidTopicOrder:
            return "Invalid topic order"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .loadFailed(let message):
            return "Failed to load: \(message)"
        case .contextGenerationFailed(let message):
            return "Failed to generate context: \(message)"
        }
    }
}

// MARK: - Document Error

/// Errors that can occur during document processing
public enum DocumentError: Error, Sendable {
    case unsupportedType(String)
    case fileNotFound(URL)
    case pdfLoadFailed(URL)
    case extractionFailed(String)
    case encodingFailed
    case embeddingFailed(String)
    case summaryGenerationFailed(String)
}

extension DocumentError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported document type: \(type)"
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .pdfLoadFailed(let url):
            return "Failed to load PDF: \(url.lastPathComponent)"
        case .extractionFailed(let message):
            return "Text extraction failed: \(message)"
        case .encodingFailed:
            return "Failed to encode document data"
        case .embeddingFailed(let message):
            return "Embedding generation failed: \(message)"
        case .summaryGenerationFailed(let message):
            return "Summary generation failed: \(message)"
        }
    }
}

// MARK: - Embedding Service Protocol

/// Protocol for embedding generation services
public protocol EmbeddingService: Actor {
    /// Generate embeddings for text
    /// - Parameter text: Text to embed
    /// - Returns: Vector embedding as array of floats
    func embed(text: String) async -> [Float]

    /// Embedding dimension (e.g., 1536 for OpenAI ada-002)
    var embeddingDimension: Int { get }
}

// MARK: - Cosine Similarity

/// Calculate cosine similarity between two vectors
/// - Parameters:
///   - a: First vector
///   - b: Second vector
/// - Returns: Similarity score between -1 and 1
public func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count, !a.isEmpty else { return 0 }

    let dotProduct = zip(a, b).reduce(Float(0)) { $0 + ($1.0 * $1.1) }
    let magnitudeA = sqrt(a.reduce(Float(0)) { $0 + ($1 * $1) })
    let magnitudeB = sqrt(b.reduce(Float(0)) { $0 + ($1 * $1) })

    guard magnitudeA > 0, magnitudeB > 0 else { return 0 }

    return dotProduct / (magnitudeA * magnitudeB)
}

// MARK: - Core Data Extensions

extension Topic {
    /// Get the topic status from progress
    public var status: TopicStatus {
        guard let progress = progress else {
            return .notStarted
        }

        // If we have time spent and mastery > 0.8, consider completed
        if mastery >= 0.8 && progress.timeSpent > 0 {
            return .completed
        }

        // If we have time spent, in progress
        if progress.timeSpent > 0 {
            return .inProgress
        }

        return .notStarted
    }

    /// Get objectives as typed array
    public var learningObjectives: [String] {
        objectives ?? []
    }

    /// Get documents as typed set
    public var documentSet: Set<Document> {
        documents as? Set<Document> ?? []
    }
}

extension Document {
    /// Get the document type enum
    public var documentType: DocumentType {
        DocumentType(rawValue: type ?? "text") ?? .text
    }

    /// Get decoded document chunks from embedding data
    public func decodedChunks() -> [DocumentChunk]? {
        guard let data = embedding else { return nil }
        return try? JSONDecoder().decode([DocumentChunk].self, from: data)
    }
}
