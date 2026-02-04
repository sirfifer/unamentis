// UnaMentis - ReadingTextChunker
// Import-time text segmentation for low-latency TTS playback
//
// Chunks are created during document import, NOT at playback time.
// This enables instant playback and pre-buffering of audio.
//
// Part of Core/ReadingList

import Foundation
import PDFKit
import Logging

// MARK: - Chunking Configuration

/// Configuration for text chunking
public struct ChunkingConfig: Sendable {
    /// Target words per chunk (TTS optimized)
    /// At ~150 WPM speaking rate, 30-50 words = 12-20 seconds per chunk
    public let targetWordsPerChunk: Int

    /// Maximum words per chunk (hard limit)
    public let maxWordsPerChunk: Int

    /// Minimum words per chunk (avoid tiny chunks)
    public let minWordsPerChunk: Int

    /// Default configuration optimized for TTS playback
    public static let `default` = ChunkingConfig(
        targetWordsPerChunk: 40,
        maxWordsPerChunk: 60,
        minWordsPerChunk: 15
    )

    /// Shorter chunks for faster response time
    public static let shortChunks = ChunkingConfig(
        targetWordsPerChunk: 25,
        maxWordsPerChunk: 40,
        minWordsPerChunk: 10
    )

    /// Longer chunks for smoother listening
    public static let longChunks = ChunkingConfig(
        targetWordsPerChunk: 60,
        maxWordsPerChunk: 80,
        minWordsPerChunk: 20
    )

    public init(targetWordsPerChunk: Int, maxWordsPerChunk: Int, minWordsPerChunk: Int) {
        self.targetWordsPerChunk = targetWordsPerChunk
        self.maxWordsPerChunk = maxWordsPerChunk
        self.minWordsPerChunk = minWordsPerChunk
    }
}

// MARK: - Chunk Result

/// A pre-segmented text chunk ready for TTS
public struct TextChunkResult: Sendable {
    public let index: Int
    public let text: String
    public let characterOffset: Int64
    public let estimatedDurationSeconds: Float

    public init(index: Int, text: String, characterOffset: Int64, estimatedDurationSeconds: Float) {
        self.index = index
        self.text = text
        self.characterOffset = characterOffset
        self.estimatedDurationSeconds = estimatedDurationSeconds
    }
}

// MARK: - Reading Text Chunker

/// Actor responsible for chunking text at natural TTS boundaries
///
/// Chunking happens at import time to enable:
/// - Instant playback (no parsing delay when pressing play)
/// - Pre-buffering of upcoming audio chunks
/// - Easy position tracking and seeking
public actor ReadingTextChunker {

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.readinglist.chunker")
    private let config: ChunkingConfig

    /// Average speaking rate in words per second (150 WPM = 2.5 WPS)
    private let wordsPerSecond: Float = 2.5

    // MARK: - Initialization

    public init(config: ChunkingConfig = .default) {
        self.config = config
    }

    // MARK: - Text Extraction

    /// Extract text from a file URL based on source type
    /// - Parameters:
    ///   - url: File URL to extract from
    ///   - sourceType: The type of source file
    /// - Returns: Extracted text content
    public func extractText(from url: URL, sourceType: ReadingListSourceType) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ReadingChunkerError.fileNotFound(url)
        }

        switch sourceType {
        case .pdf:
            return try extractPDFText(from: url)
        case .plainText:
            return try extractPlainText(from: url)
        }
    }

    /// Extract text from a PDF file
    private func extractPDFText(from url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ReadingChunkerError.pdfLoadFailed(url)
        }

        var text = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else {
                continue
            }
            text += pageText + "\n\n"
        }

        guard !text.isEmpty else {
            throw ReadingChunkerError.extractionFailed("PDF contains no extractable text")
        }

        return cleanText(text)
    }

    /// Extract text from a plain text file
    private func extractPlainText(from url: URL) throws -> String {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return cleanText(text)
        } catch {
            throw ReadingChunkerError.extractionFailed("Failed to read text file: \(error.localizedDescription)")
        }
    }

    /// Clean and normalize text
    private func cleanText(_ text: String) -> String {
        // Normalize whitespace
        var cleaned = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Collapse multiple newlines to max 2
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        // Collapse multiple spaces to single space
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Chunking

    /// Chunk text into TTS-ready segments
    /// - Parameter text: Full text to chunk
    /// - Returns: Array of chunks with metadata
    public func chunkText(_ text: String) -> [TextChunkResult] {
        guard !text.isEmpty else { return [] }

        // Split into sentences first
        let sentences = splitIntoSentences(text)
        guard !sentences.isEmpty else { return [] }

        logger.debug("Split text into \(sentences.count) sentences")

        // Group sentences into chunks
        var chunks: [TextChunkResult] = []
        var currentChunkSentences: [String] = []
        var currentWordCount = 0
        var characterOffset: Int64 = 0

        for sentence in sentences {
            let sentenceWordCount = sentence.split(separator: " ").count

            // Check if adding this sentence would exceed max
            if currentWordCount + sentenceWordCount > config.maxWordsPerChunk && !currentChunkSentences.isEmpty {
                // Output current chunk
                let chunkText = currentChunkSentences.joined(separator: " ")
                let chunk = TextChunkResult(
                    index: chunks.count,
                    text: chunkText,
                    characterOffset: characterOffset,
                    estimatedDurationSeconds: estimateDuration(wordCount: currentWordCount)
                )
                chunks.append(chunk)

                // Update offset
                characterOffset += Int64(chunkText.count + 1) // +1 for space/newline

                // Start new chunk
                currentChunkSentences = [sentence]
                currentWordCount = sentenceWordCount
            } else {
                // Add to current chunk
                currentChunkSentences.append(sentence)
                currentWordCount += sentenceWordCount

                // If we've reached target size and this is a good break point, output
                if currentWordCount >= config.targetWordsPerChunk {
                    let chunkText = currentChunkSentences.joined(separator: " ")
                    let chunk = TextChunkResult(
                        index: chunks.count,
                        text: chunkText,
                        characterOffset: characterOffset,
                        estimatedDurationSeconds: estimateDuration(wordCount: currentWordCount)
                    )
                    chunks.append(chunk)

                    characterOffset += Int64(chunkText.count + 1)
                    currentChunkSentences = []
                    currentWordCount = 0
                }
            }
        }

        // Output remaining sentences as final chunk
        if !currentChunkSentences.isEmpty {
            let chunkText = currentChunkSentences.joined(separator: " ")
            // Merge with previous chunk if too small
            if currentWordCount < config.minWordsPerChunk && !chunks.isEmpty {
                var lastChunk = chunks.removeLast()
                let mergedText = lastChunk.text + " " + chunkText
                let mergedWordCount = mergedText.split(separator: " ").count
                let mergedChunk = TextChunkResult(
                    index: lastChunk.index,
                    text: mergedText,
                    characterOffset: lastChunk.characterOffset,
                    estimatedDurationSeconds: estimateDuration(wordCount: mergedWordCount)
                )
                chunks.append(mergedChunk)
            } else {
                let chunk = TextChunkResult(
                    index: chunks.count,
                    text: chunkText,
                    characterOffset: characterOffset,
                    estimatedDurationSeconds: estimateDuration(wordCount: currentWordCount)
                )
                chunks.append(chunk)
            }
        }

        logger.info("Created \(chunks.count) chunks from text")
        return chunks
    }

    /// Split text into sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        // Use linguistic tagger for sentence detection
        var sentences: [String] = []

        text.enumerateSubstrings(
            in: text.startIndex..<text.endIndex,
            options: [.bySentences, .localized]
        ) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }

        // Fallback if linguistic tagger returns nothing
        if sentences.isEmpty {
            // Simple fallback: split on sentence-ending punctuation
            let pattern = #"(?<=[.!?])\s+"#
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..., in: text)

            var lastEnd = text.startIndex
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range,
                   let swiftRange = Range(matchRange, in: text) {
                    let sentence = String(text[lastEnd..<swiftRange.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty {
                        sentences.append(sentence)
                    }
                    lastEnd = swiftRange.upperBound
                }
            }

            // Add remaining text as final sentence
            let remaining = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                sentences.append(remaining)
            }
        }

        return sentences
    }

    /// Estimate duration in seconds for a word count
    private func estimateDuration(wordCount: Int) -> Float {
        Float(wordCount) / wordsPerSecond
    }

    // MARK: - Full Import Pipeline

    /// Extract text and chunk in one operation
    /// - Parameters:
    ///   - url: File URL to process
    ///   - sourceType: The type of source file
    /// - Returns: Array of chunks ready for Core Data
    public func processDocument(from url: URL, sourceType: ReadingListSourceType) throws -> [TextChunkResult] {
        logger.info("Processing document: \(url.lastPathComponent)")

        let text = try extractText(from: url, sourceType: sourceType)
        logger.debug("Extracted \(text.count) characters")

        let chunks = chunkText(text)
        logger.info("Document chunked into \(chunks.count) segments")

        return chunks
    }
}

// MARK: - Errors

public enum ReadingChunkerError: LocalizedError {
    case fileNotFound(URL)
    case pdfLoadFailed(URL)
    case extractionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .pdfLoadFailed(let url):
            return "Failed to load PDF: \(url.lastPathComponent)"
        case .extractionFailed(let reason):
            return "Text extraction failed: \(reason)"
        }
    }
}
