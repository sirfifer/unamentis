// UnaMentis - Reading FOV Context Manager
// Builds context windows around the current reading position
// for barge-in Q&A during document playback
//
// Part of Core/Context

import Foundation
import Logging

// MARK: - Reading Context Window

/// Context window around the current reading position
public struct ReadingContextWindow: Sendable {
    /// The system prompt for reading Q&A
    public let systemPrompt: String

    /// Text from chunks before the current position
    public let precedingText: String

    /// Text of the current chunk being read
    public let currentText: String

    /// Text from chunks after the current position
    public let followingText: String

    /// Document metadata
    public let documentTitle: String
    public let documentAuthor: String?

    /// Current position info
    public let currentChunkIndex: Int32
    public let totalChunks: Int

    /// Combined context for LLM
    public var fullContext: String {
        var parts: [String] = []

        parts.append(systemPrompt)
        parts.append("")
        parts.append("## Document: \(documentTitle)")

        if let author = documentAuthor, !author.isEmpty {
            parts.append("Author: \(author)")
        }

        parts.append("Progress: Segment \(currentChunkIndex + 1) of \(totalChunks)")
        parts.append("")

        if !precedingText.isEmpty {
            parts.append("## Previously Read")
            parts.append(precedingText)
            parts.append("")
        }

        parts.append("## Currently Reading")
        parts.append(currentText)
        parts.append("")

        if !followingText.isEmpty {
            parts.append("## Coming Up Next")
            parts.append(followingText)
        }

        return parts.joined(separator: "\n")
    }

    /// Estimated token count (rough approximation: ~4 chars per token)
    public var estimatedTokenCount: Int {
        fullContext.count / 4
    }
}

// MARK: - Reading FOV Context Manager

/// Builds context windows around the current reading position
/// for barge-in Q&A during document playback
///
/// When the user interrupts reading to ask a question, this manager
/// provides the relevant surrounding text as context to the LLM.
public actor ReadingFOVContextManager {

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.reading.fovcontext")

    /// Number of chunks to include before current position
    private let precedingChunkCount: Int

    /// Number of chunks to include after current position
    private let followingChunkCount: Int

    /// Maximum characters per context section
    private let maxSectionCharacters: Int

    /// System prompt for reading Q&A
    private let systemPrompt: String

    // MARK: - Initialization

    /// Initialize the reading context manager
    /// - Parameters:
    ///   - precedingChunkCount: Chunks to include before current (default: 3)
    ///   - followingChunkCount: Chunks to include after current (default: 2)
    ///   - maxSectionCharacters: Max chars per section (default: 4000)
    public init(
        precedingChunkCount: Int = 3,
        followingChunkCount: Int = 2,
        maxSectionCharacters: Int = 4000
    ) {
        self.precedingChunkCount = precedingChunkCount
        self.followingChunkCount = followingChunkCount
        self.maxSectionCharacters = maxSectionCharacters
        self.systemPrompt = Self.defaultSystemPrompt

        logger.info("ReadingFOVContextManager initialized")
    }

    // MARK: - Context Building

    /// Build a context window around the current reading position
    /// - Parameters:
    ///   - chunks: All chunks for the document
    ///   - currentIndex: Current chunk index being read
    ///   - title: Document title
    ///   - author: Document author (optional)
    /// - Returns: Context window ready for LLM
    public func buildContext(
        chunks: [ReadingChunkData],
        currentIndex: Int32,
        title: String,
        author: String? = nil
    ) -> ReadingContextWindow {
        let current = Int(currentIndex)

        // Get current chunk text
        let currentText: String
        if current < chunks.count {
            currentText = chunks[current].text
        } else {
            currentText = ""
        }

        // Get preceding chunks
        let precedingStart = max(0, current - precedingChunkCount)
        let precedingChunks = chunks[precedingStart..<current]
        let precedingText = truncateToLimit(
            precedingChunks.map(\.text).joined(separator: "\n\n")
        )

        // Get following chunks
        let followingEnd = min(chunks.count, current + 1 + followingChunkCount)
        let followingChunks: ArraySlice<ReadingChunkData>
        if current + 1 < chunks.count {
            followingChunks = chunks[(current + 1)..<followingEnd]
        } else {
            followingChunks = []
        }
        let followingText = truncateToLimit(
            followingChunks.map(\.text).joined(separator: "\n\n")
        )

        let window = ReadingContextWindow(
            systemPrompt: systemPrompt,
            precedingText: precedingText,
            currentText: currentText,
            followingText: followingText,
            documentTitle: title,
            documentAuthor: author,
            currentChunkIndex: currentIndex,
            totalChunks: chunks.count
        )

        logger.debug(
            "Built reading context",
            metadata: [
                "chunkIndex": .stringConvertible(currentIndex),
                "precedingChars": .stringConvertible(precedingText.count),
                "currentChars": .stringConvertible(currentText.count),
                "followingChars": .stringConvertible(followingText.count),
                "estimatedTokens": .stringConvertible(window.estimatedTokenCount)
            ]
        )

        return window
    }

    /// Build LLM messages for a barge-in question during reading
    /// - Parameters:
    ///   - question: The user's question
    ///   - chunks: All chunks for the document
    ///   - currentIndex: Current chunk index
    ///   - title: Document title
    ///   - author: Document author
    ///   - conversationHistory: Previous Q&A exchanges during this reading session
    /// - Returns: Array of LLM messages ready for the model
    public func buildBargeInMessages(
        question: String,
        chunks: [ReadingChunkData],
        currentIndex: Int32,
        title: String,
        author: String? = nil,
        conversationHistory: [(question: String, answer: String)] = []
    ) -> [LLMMessage] {
        let context = buildContext(
            chunks: chunks,
            currentIndex: currentIndex,
            title: title,
            author: author
        )

        var messages: [LLMMessage] = []

        // System message with reading context
        messages.append(LLMMessage(
            role: .system,
            content: context.fullContext
        ))

        // Add conversation history from this reading session
        for exchange in conversationHistory {
            messages.append(LLMMessage(role: .user, content: exchange.question))
            messages.append(LLMMessage(role: .assistant, content: exchange.answer))
        }

        // Add current question
        messages.append(LLMMessage(role: .user, content: question))

        return messages
    }

    // MARK: - Private Helpers

    /// Truncate text to the maximum section character limit
    private func truncateToLimit(_ text: String) -> String {
        if text.count <= maxSectionCharacters {
            return text
        }
        return String(text.suffix(maxSectionCharacters))
    }

    // MARK: - Default System Prompt

    private static let defaultSystemPrompt = """
        You are a helpful reading assistant. The user is listening to a document \
        being read aloud and has paused to ask you a question.

        Answer the question based on the document content provided below. \
        Be concise and direct. If the answer is in the document, cite the \
        relevant passage. If the question is about something not in the \
        document, say so clearly.

        Keep responses brief since the user will resume listening after your answer.
        """
}
