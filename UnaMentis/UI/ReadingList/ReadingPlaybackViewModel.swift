// UnaMentis - Reading Playback View Model
// State management for reading playback UI
//
// Part of UI/ReadingList

import Foundation
import SwiftUI
import Combine
import Logging

// MARK: - Reading Playback View Model

/// View model for the reading playback interface
@MainActor
public final class ReadingPlaybackViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var state: ReadingPlaybackState = .idle
    @Published public var currentChunkIndex: Int32 = 0
    @Published public var totalChunks: Int = 0
    @Published public var currentChunkText: String?
    @Published public var bookmarks: [ReadingBookmarkData] = []
    @Published public var showError: Bool = false
    @Published public var errorMessage: String?

    // MARK: - Computed Properties

    /// Current playback progress (0.0 to 1.0)
    public var progress: Double {
        guard totalChunks > 0 else { return 0 }
        return Double(currentChunkIndex) / Double(totalChunks)
    }

    /// Whether currently playing
    public var isPlaying: Bool {
        state == .playing
    }

    /// Whether can skip backward
    public var canSkipBackward: Bool {
        currentChunkIndex > 0 && state != .loading
    }

    /// Whether can skip forward
    public var canSkipForward: Bool {
        currentChunkIndex < Int32(totalChunks - 1) && state != .loading
    }

    // MARK: - Properties

    private let logger = Logger(label: "com.unamentis.reading.playback.viewmodel")
    private let item: ReadingListItem
    private var chunks: [ReadingChunkData] = []
    private var playbackService: ReadingPlaybackService?

    // MARK: - Initialization

    public init(item: ReadingListItem) {
        self.item = item
        self.totalChunks = item.totalChunks
        self.currentChunkIndex = item.currentChunkIndex
    }

    // MARK: - Setup

    /// Load chunks and prepare for playback
    public func loadAndPrepare() async {
        state = .loading

        do {
            // Load chunks from Core Data
            chunks = loadChunksFromItem()
            totalChunks = chunks.count

            // Set current chunk text
            if !chunks.isEmpty && Int(currentChunkIndex) < chunks.count {
                currentChunkText = chunks[Int(currentChunkIndex)].text
            }

            // Load bookmarks
            loadBookmarks()

            // Create and configure playback service
            // Note: In production, these would be injected via dependency injection
            // For now, we'll get them from the app's service locator pattern
            let service = ReadingPlaybackService()

            // Get dependencies from app state (simplified for now)
            // In a real implementation, use proper DI
            if let audioEngine = await getAudioEngine(),
               let ttsService = await getTTSService(),
               let manager = ReadingListManager.shared {

                let callbacks = makeCallbacks()
                await service.configure(
                    ttsService: ttsService,
                    audioEngine: audioEngine,
                    readingListManager: manager,
                    callbacks: callbacks
                )

                playbackService = service
                state = .idle
                logger.info("Playback prepared with \(chunks.count) chunks")
            } else {
                state = .error("Services not available")
                errorMessage = "Audio services not available"
                showError = true
            }

        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Load chunks from the reading item
    private func loadChunksFromItem() -> [ReadingChunkData] {
        guard let chunksSet = item.chunks as? Set<ReadingChunk> else { return [] }

        return chunksSet
            .sorted { $0.index < $1.index }
            .map { chunk in
                ReadingChunkData(
                    index: chunk.index,
                    text: chunk.text ?? "",
                    characterOffset: chunk.characterOffset,
                    estimatedDurationSeconds: chunk.estimatedDurationSeconds
                )
            }
    }

    /// Load bookmarks from the reading item
    private func loadBookmarks() {
        guard let bookmarksSet = item.bookmarks as? Set<ReadingBookmark> else { return }

        bookmarks = bookmarksSet
            .sorted { $0.createdAt ?? Date.distantPast < $1.createdAt ?? Date.distantPast }
            .compactMap { bookmark in
                guard let id = bookmark.id else { return nil }
                return ReadingBookmarkData(
                    id: id,
                    chunkIndex: bookmark.chunkIndex,
                    note: bookmark.note
                )
            }
    }

    // MARK: - Playback Control

    /// Toggle between play and pause
    public func togglePlayPause() async {
        guard let service = playbackService else { return }

        switch state {
        case .idle, .paused:
            await startOrResume()
        case .playing:
            await service.pause()
        case .completed:
            // Restart from beginning
            currentChunkIndex = 0
            await startOrResume()
        default:
            break
        }
    }

    /// Start or resume playback
    private func startOrResume() async {
        guard let service = playbackService else { return }

        if state == .paused {
            await service.resume()
        } else {
            do {
                try await service.startPlayback(
                    itemId: item.id ?? UUID(),
                    chunks: chunks,
                    startIndex: currentChunkIndex
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Stop playback
    public func stopPlayback() async {
        guard let service = playbackService else { return }
        await service.stopPlayback()
    }

    /// Skip forward
    public func skipForward() async {
        guard let service = playbackService else { return }

        do {
            try await service.skipForward()
        } catch {
            logger.error("Skip forward failed: \(error.localizedDescription)")
        }
    }

    /// Skip backward
    public func skipBackward() async {
        guard let service = playbackService else { return }

        do {
            try await service.skipBackward()
        } catch {
            logger.error("Skip backward failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Bookmarks

    /// Add bookmark at current position
    public func addBookmark(note: String? = nil) async {
        guard let service = playbackService else { return }

        do {
            try await service.addBookmark(note: note)
            loadBookmarks() // Refresh bookmarks list
        } catch {
            errorMessage = "Failed to add bookmark"
            showError = true
        }
    }

    /// Jump to a bookmark
    public func jumpToBookmark(_ bookmark: ReadingBookmarkData) async {
        guard let service = playbackService else { return }

        do {
            try await service.jumpToBookmark(bookmark)
        } catch {
            logger.error("Jump to bookmark failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Callback Factory

    /// Create Sendable callbacks that update this view model on the main actor
    private func makeCallbacks() -> ReadingPlaybackCallbacks {
        // Capture weak self to avoid retain cycles
        let weakChunks = chunks

        return ReadingPlaybackCallbacks(
            onStart: { [weak self] in
                self?.state = .playing
            },
            onPause: { [weak self] in
                self?.state = .paused
            },
            onResume: { [weak self] in
                self?.state = .playing
            },
            onStop: { [weak self] in
                self?.state = .idle
            },
            onComplete: { [weak self] in
                self?.state = .completed
            },
            onChunkChange: { [weak self] index, total in
                self?.currentChunkIndex = index
                self?.totalChunks = total
                if Int(index) < weakChunks.count {
                    self?.currentChunkText = weakChunks[Int(index)].text
                }
            },
            onError: { [weak self] error in
                self?.state = .error(error.localizedDescription)
                self?.errorMessage = error.localizedDescription
                self?.showError = true
            }
        )
    }

    // MARK: - Service Access (Simplified)

    /// Get the audio engine from app services
    /// Note: In production, use proper dependency injection
    private func getAudioEngine() async -> AudioEngine? {
        // This would typically come from a service locator or DI container
        // For now, return nil and let the UI handle it gracefully
        // The actual integration will be done when wiring up the full app
        return nil
    }

    /// Get the TTS service from app services
    /// Note: In production, use proper dependency injection
    private func getTTSService() async -> (any TTSService)? {
        // This would typically come from a service locator or DI container
        // For now, return nil and let the UI handle it gracefully
        return nil
    }
}
