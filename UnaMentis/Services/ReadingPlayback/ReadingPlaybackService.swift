// UnaMentis - Reading Playback Service
// Low-latency TTS playback for reading list items with pre-buffering
//
// Part of Services/ReadingPlayback
//
// Architecture:
// - Pre-generates audio for 2-3 chunks ahead while current chunk plays
// - Seamless transitions between chunks with no gaps
// - Auto-saves position on pause/stop
// - Supports barge-in via AudioEngine.pausePlayback()

import Foundation
import AVFoundation
import Logging

// MARK: - Playback State

/// Current state of reading playback
public enum ReadingPlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case buffering
    case completed
    case error(String)
}

// MARK: - Pre-buffered Chunk

/// A chunk with its pre-generated audio data
private struct PreBufferedChunk: Sendable {
    let chunk: ReadingChunkData
    let audioChunks: [TTSAudioChunk]
}

/// Lightweight data transfer object for chunk info
public struct ReadingChunkData: Sendable {
    public let index: Int32
    public let text: String
    public let characterOffset: Int64
    public let estimatedDurationSeconds: Float

    public init(index: Int32, text: String, characterOffset: Int64, estimatedDurationSeconds: Float) {
        self.index = index
        self.text = text
        self.characterOffset = characterOffset
        self.estimatedDurationSeconds = estimatedDurationSeconds
    }
}

// MARK: - Playback Callbacks

/// Sendable callbacks for playback events (replaces delegate for actor safety)
public struct ReadingPlaybackCallbacks: Sendable {
    public let onStart: @Sendable @MainActor () -> Void
    public let onPause: @Sendable @MainActor () -> Void
    public let onResume: @Sendable @MainActor () -> Void
    public let onStop: @Sendable @MainActor () -> Void
    public let onComplete: @Sendable @MainActor () -> Void
    public let onChunkChange: @Sendable @MainActor (Int32, Int) -> Void
    public let onError: @Sendable @MainActor (Error) -> Void

    public init(
        onStart: @escaping @Sendable @MainActor () -> Void = {},
        onPause: @escaping @Sendable @MainActor () -> Void = {},
        onResume: @escaping @Sendable @MainActor () -> Void = {},
        onStop: @escaping @Sendable @MainActor () -> Void = {},
        onComplete: @escaping @Sendable @MainActor () -> Void = {},
        onChunkChange: @escaping @Sendable @MainActor (Int32, Int) -> Void = { _, _ in },
        onError: @escaping @Sendable @MainActor (Error) -> Void = { _ in }
    ) {
        self.onStart = onStart
        self.onPause = onPause
        self.onResume = onResume
        self.onStop = onStop
        self.onComplete = onComplete
        self.onChunkChange = onChunkChange
        self.onError = onError
    }
}

// MARK: - Reading Playback Service

/// Service for playing reading list content with low-latency TTS
///
/// Key Features:
/// - Pre-buffers 2-3 chunks ahead for seamless playback
/// - Works with any TTSService (protocol-based)
/// - Auto-saves position via ReadingListManager
/// - Supports pause/resume for barge-in Q&A
public actor ReadingPlaybackService {

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.reading.playback")

    /// Current playback state
    public private(set) var state: ReadingPlaybackState = .idle

    /// Current reading item (item ID for safety across actor boundaries)
    private var currentItemId: UUID?

    /// All chunks for current item
    private var chunks: [ReadingChunkData] = []

    /// Current chunk index being played
    public private(set) var currentChunkIndex: Int32 = 0

    /// Total number of chunks
    public var totalChunks: Int { chunks.count }

    /// Pre-buffered audio ready for playback
    private var preBufferedChunks: [Int32: PreBufferedChunk] = [:]

    /// Number of chunks to pre-buffer ahead
    private let preBufferCount: Int = 3

    /// TTS service for audio generation
    private var ttsService: (any TTSService)?

    /// Audio engine for playback
    private var audioEngine: AudioEngine?

    /// Reading list manager for position updates
    private var readingListManager: ReadingListManager?

    /// Callbacks for UI updates
    private var callbacks: ReadingPlaybackCallbacks?

    /// Task for pre-buffering
    private var preBufferTask: Task<Void, Never>?

    /// Task for playback loop
    private var playbackTask: Task<Void, Never>?

    /// Whether we're currently pre-buffering
    private var isPreBuffering = false

    // MARK: - Initialization

    public init() { }

    /// Configure the service with required dependencies
    public func configure(
        ttsService: any TTSService,
        audioEngine: AudioEngine,
        readingListManager: ReadingListManager,
        callbacks: ReadingPlaybackCallbacks = ReadingPlaybackCallbacks()
    ) {
        self.ttsService = ttsService
        self.audioEngine = audioEngine
        self.readingListManager = readingListManager
        self.callbacks = callbacks

        logger.info("ReadingPlaybackService configured")
    }

    // MARK: - Playback Control

    /// Start playing a reading item from the beginning or last position
    /// - Parameters:
    ///   - itemId: The reading item ID
    ///   - chunks: Pre-loaded chunk data from the item
    ///   - startIndex: Optional starting chunk index (defaults to 0)
    public func startPlayback(
        itemId: UUID,
        chunks: [ReadingChunkData],
        startIndex: Int32 = 0
    ) async throws {
        guard let ttsService, let audioEngine else {
            throw ReadingPlaybackError.notConfigured
        }

        guard !chunks.isEmpty else {
            throw ReadingPlaybackError.noChunks
        }

        logger.info("Starting playback for item \(itemId), \(chunks.count) chunks, starting at \(startIndex)")

        // Clean up any existing playback
        await stopPlayback()

        // Set up new playback session
        self.currentItemId = itemId
        self.chunks = chunks
        self.currentChunkIndex = min(startIndex, Int32(chunks.count - 1))
        self.preBufferedChunks.removeAll()

        // Update state
        state = .loading
        if let cb = callbacks { await notify(cb.onStart) }

        // Start pre-buffering ahead of current position
        startPreBuffering(from: currentChunkIndex)

        // Wait for first chunk to be ready
        try await waitForChunk(at: currentChunkIndex)

        // Start playback loop
        state = .playing
        startPlaybackLoop()
    }

    /// Pause playback (for barge-in)
    public func pause() async {
        guard state == .playing else { return }

        logger.debug("Pausing playback at chunk \(currentChunkIndex)")

        // Pause audio
        if let audioEngine {
            _ = await audioEngine.pausePlayback()
        }

        state = .paused
        await saveCurrentPosition()
        if let cb = callbacks { await notify(cb.onPause) }
    }

    /// Resume playback after pause
    public func resume() async {
        guard state == .paused else { return }

        logger.debug("Resuming playback from chunk \(currentChunkIndex)")

        // Resume audio
        if let audioEngine {
            _ = await audioEngine.resumePlayback()
        }

        state = .playing
        if let cb = callbacks { await notify(cb.onResume) }

        // Continue playback loop if needed
        if playbackTask == nil {
            startPlaybackLoop()
        }
    }

    /// Stop playback completely
    public func stopPlayback() async {
        guard state != .idle else { return }

        logger.debug("Stopping playback")

        // Cancel tasks
        preBufferTask?.cancel()
        preBufferTask = nil
        playbackTask?.cancel()
        playbackTask = nil

        // Stop audio
        if let audioEngine {
            await audioEngine.stopPlayback()
        }

        // Save position
        await saveCurrentPosition()

        // Clean up
        currentItemId = nil
        chunks.removeAll()
        preBufferedChunks.removeAll()
        state = .idle

        if let cb = callbacks { await notify(cb.onStop) }
    }

    /// Skip to a specific chunk
    public func skipToChunk(_ index: Int32) async throws {
        guard index >= 0 && index < Int32(chunks.count) else {
            throw ReadingPlaybackError.invalidChunkIndex
        }

        logger.debug("Skipping to chunk \(index)")

        // Stop current audio
        if let audioEngine {
            await audioEngine.stopPlayback()
        }

        // Update position
        currentChunkIndex = index

        // Clear pre-buffer and start fresh from new position
        preBufferedChunks.removeAll()
        preBufferTask?.cancel()
        startPreBuffering(from: index)

        // Wait for chunk to be ready and resume
        if state == .playing || state == .paused {
            state = .buffering
            try await waitForChunk(at: index)
            state = .playing
            startPlaybackLoop()
        }

        let total = chunks.count
        if let cb = callbacks {
            let idx = index
            await MainActor.run { cb.onChunkChange(idx, total) }
        }
    }

    /// Skip forward by N chunks
    public func skipForward(chunks count: Int = 1) async throws {
        let newIndex = min(currentChunkIndex + Int32(count), Int32(self.chunks.count - 1))
        try await skipToChunk(newIndex)
    }

    /// Skip backward by N chunks
    public func skipBackward(chunks count: Int = 1) async throws {
        let newIndex = max(currentChunkIndex - Int32(count), 0)
        try await skipToChunk(newIndex)
    }

    // MARK: - Pre-buffering

    /// Start pre-buffering chunks ahead of the given index
    private func startPreBuffering(from startIndex: Int32) {
        preBufferTask?.cancel()

        preBufferTask = Task { [weak self] in
            guard let self else { return }

            await self.runPreBufferLoop(from: startIndex)
        }
    }

    /// Run the pre-buffer loop
    private func runPreBufferLoop(from startIndex: Int32) async {
        guard let ttsService else { return }

        isPreBuffering = true
        var nextIndexToBuffer = startIndex

        while !Task.isCancelled && nextIndexToBuffer < Int32(chunks.count) {
            // Only buffer up to preBufferCount chunks ahead of current playback
            let maxBufferIndex = currentChunkIndex + Int32(preBufferCount)

            if nextIndexToBuffer > maxBufferIndex {
                // Wait a bit before checking again
                try? await Task.sleep(for: .milliseconds(100))
                continue
            }

            // Skip if already buffered
            if preBufferedChunks[nextIndexToBuffer] != nil {
                nextIndexToBuffer += 1
                continue
            }

            // Buffer this chunk
            let chunkIndex = nextIndexToBuffer
            guard Int(chunkIndex) < chunks.count else { break }

            let chunk = chunks[Int(chunkIndex)]

            logger.debug("Pre-buffering chunk \(chunkIndex)")

            do {
                // Generate TTS audio
                let audioStream = try await ttsService.synthesize(text: chunk.text)

                // Collect all audio chunks
                var audioChunks: [TTSAudioChunk] = []
                for await audioChunk in audioStream {
                    audioChunks.append(audioChunk)
                }

                // Store pre-buffered chunk
                let preBuffered = PreBufferedChunk(chunk: chunk, audioChunks: audioChunks)
                preBufferedChunks[chunkIndex] = preBuffered

                logger.debug("Buffered chunk \(chunkIndex) with \(audioChunks.count) audio segments")

            } catch {
                logger.error("Failed to buffer chunk \(chunkIndex): \(error.localizedDescription)")
                // Continue to next chunk on error
            }

            nextIndexToBuffer += 1
        }

        isPreBuffering = false
    }

    /// Wait for a specific chunk to be buffered
    private func waitForChunk(at index: Int32) async throws {
        let timeout: TimeInterval = 30.0
        let startTime = Date()

        while preBufferedChunks[index] == nil {
            if Date().timeIntervalSince(startTime) > timeout {
                throw ReadingPlaybackError.bufferTimeout
            }

            if Task.isCancelled {
                throw CancellationError()
            }

            try await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: - Playback Loop

    /// Start the main playback loop
    private func startPlaybackLoop() {
        playbackTask?.cancel()

        playbackTask = Task { [weak self] in
            guard let self else { return }

            await self.runPlaybackLoop()
        }
    }

    /// Run the main playback loop
    private func runPlaybackLoop() async {
        guard let audioEngine else { return }

        while !Task.isCancelled && state == .playing {
            // Check if we've reached the end
            if currentChunkIndex >= Int32(chunks.count) {
                state = .completed
                await saveCurrentPosition()
                if let cb = callbacks { await notify(cb.onComplete) }
                break
            }

            // Get pre-buffered chunk
            guard let preBuffered = preBufferedChunks[currentChunkIndex] else {
                // Need to wait for buffer
                state = .buffering
                do {
                    try await waitForChunk(at: currentChunkIndex)
                    state = .playing
                } catch {
                    state = .error("Buffering failed")
                    if let cb = callbacks {
                        let errMsg = error.localizedDescription
                        await MainActor.run {
                            cb.onError(ReadingPlaybackError.playbackFailed(errMsg))
                        }
                    }
                    break
                }
                continue
            }

            // Notify chunk change
            let chunkIdx = currentChunkIndex
            let totalCount = chunks.count
            if let cb = callbacks {
                await MainActor.run { cb.onChunkChange(chunkIdx, totalCount) }
            }

            // Play all audio chunks for this text chunk
            do {
                for audioChunk in preBuffered.audioChunks {
                    if Task.isCancelled || state != .playing {
                        break
                    }
                    try await audioEngine.playAudio(audioChunk)
                }
            } catch {
                logger.error("Playback error at chunk \(currentChunkIndex): \(error.localizedDescription)")
                state = .error(error.localizedDescription)
                if let cb = callbacks {
                    let errMsg = error.localizedDescription
                    await MainActor.run {
                        cb.onError(ReadingPlaybackError.playbackFailed(errMsg))
                    }
                }
                break
            }

            // Check if we should continue (might have been paused/stopped)
            guard state == .playing else { break }

            // Move to next chunk
            currentChunkIndex += 1

            // Clean up old buffered chunks to save memory
            let oldIndex = currentChunkIndex - 2
            if oldIndex >= 0 {
                preBufferedChunks.removeValue(forKey: oldIndex)
            }

            // Trigger more pre-buffering if needed
            if !isPreBuffering && currentChunkIndex + Int32(preBufferCount) > Int32(preBufferedChunks.count) {
                startPreBuffering(from: currentChunkIndex + 1)
            }
        }
    }

    // MARK: - Position Management

    /// Save current playback position
    private func saveCurrentPosition() async {
        guard let itemId = currentItemId, let manager = readingListManager else { return }

        let chunkIdx = currentChunkIndex
        do {
            try await MainActor.run {
                try manager.updatePositionById(itemId: itemId, chunkIndex: chunkIdx)
            }
            logger.debug("Saved position: chunk \(chunkIdx)")
        } catch {
            logger.error("Failed to save position: \(error.localizedDescription)")
        }
    }

    // MARK: - Callback Notification

    /// Invoke a callback on the main actor
    private func notify(_ callback: @escaping @Sendable @MainActor () -> Void) async {
        await MainActor.run { callback() }
    }

    // MARK: - Bookmarks

    /// Add a bookmark at the current position
    public func addBookmark(note: String? = nil) async throws {
        guard let itemId = currentItemId, let manager = readingListManager else {
            throw ReadingPlaybackError.notConfigured
        }

        let chunkIdx = currentChunkIndex
        _ = try await MainActor.run {
            try manager.addBookmarkById(itemId: itemId, chunkIndex: chunkIdx, note: note)
        }
        logger.info("Added bookmark at chunk \(chunkIdx)")
    }

    /// Jump to a bookmark position
    public func jumpToBookmark(_ bookmark: ReadingBookmarkData) async throws {
        try await skipToChunk(bookmark.chunkIndex)
    }
}

// MARK: - Bookmark Data Transfer Object

/// Lightweight bookmark data for actor boundary crossing
public struct ReadingBookmarkData: Sendable {
    public let id: UUID
    public let chunkIndex: Int32
    public let note: String?

    public init(id: UUID, chunkIndex: Int32, note: String?) {
        self.id = id
        self.chunkIndex = chunkIndex
        self.note = note
    }
}

// MARK: - Errors

/// Errors specific to reading playback
public enum ReadingPlaybackError: Error, LocalizedError {
    case notConfigured
    case noChunks
    case invalidChunkIndex
    case bufferTimeout
    case playbackFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Reading playback service not configured"
        case .noChunks:
            return "No chunks available for playback"
        case .invalidChunkIndex:
            return "Invalid chunk index"
        case .bufferTimeout:
            return "Timed out waiting for audio buffer"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        }
    }
}
