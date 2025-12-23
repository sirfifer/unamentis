// UnaMentis - Visual Asset Cache
// Caching service for visual assets (images, diagrams, etc.)
//
// Part of Curriculum Layer (TDD Section 4)

import Foundation
import CoreData
import Logging

/// Service for caching visual assets for offline access
public actor VisualAssetCache {
    private let logger = Logger(label: "com.unamentis.visualassetcache")
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var memoryCache: [String: Data] = [:]
    private let maxMemoryCacheSize = 50 * 1024 * 1024 // 50MB
    private var currentMemoryCacheSize = 0

    /// Shared instance
    public static let shared = VisualAssetCache()

    private init() {
        // Create cache directory in app's caches folder
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("VisualAssets", isDirectory: true)

        // Ensure cache directory exists
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        logger.info("Visual asset cache initialized at: \(cacheDirectory.path)")
    }

    // MARK: - Public API

    /// Cache visual asset data
    /// - Parameters:
    ///   - assetId: Unique identifier for the asset
    ///   - data: Image/asset data to cache
    public func cache(assetId: String, data: Data) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(sanitizeFilename(assetId))

        // Write to disk
        try data.write(to: fileURL)

        // Add to memory cache if room
        if data.count + currentMemoryCacheSize <= maxMemoryCacheSize {
            memoryCache[assetId] = data
            currentMemoryCacheSize += data.count
        }

        logger.debug("Cached asset \(assetId) (\(data.count) bytes)")
    }

    /// Retrieve cached asset data
    /// - Parameter assetId: Unique identifier for the asset
    /// - Returns: Cached data if available, nil otherwise
    public func retrieve(assetId: String) async -> Data? {
        // Check memory cache first
        if let data = memoryCache[assetId] {
            logger.debug("Memory cache hit for \(assetId)")
            return data
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(sanitizeFilename(assetId))
        if let data = try? Data(contentsOf: fileURL) {
            // Promote to memory cache if room
            if data.count + currentMemoryCacheSize <= maxMemoryCacheSize {
                memoryCache[assetId] = data
                currentMemoryCacheSize += data.count
            }
            logger.debug("Disk cache hit for \(assetId)")
            return data
        }

        logger.debug("Cache miss for \(assetId)")
        return nil
    }

    /// Check if asset is cached
    /// - Parameter assetId: Unique identifier for the asset
    /// - Returns: true if asset is cached (memory or disk)
    public func isCached(assetId: String) async -> Bool {
        if memoryCache[assetId] != nil {
            return true
        }

        let fileURL = cacheDirectory.appendingPathComponent(sanitizeFilename(assetId))
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Download and cache an asset from a remote URL
    /// - Parameters:
    ///   - assetId: Unique identifier for the asset
    ///   - url: Remote URL to download from
    /// - Returns: Downloaded data
    public func downloadAndCache(assetId: String, from url: URL) async throws -> Data {
        // Check if already cached
        if let cached = await retrieve(assetId: assetId) {
            return cached
        }

        // Download
        let (data, response) = try await URLSession.shared.data(from: url)

        // Verify response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VisualAssetCacheError.downloadFailed(url)
        }

        // Cache the data
        try await cache(assetId: assetId, data: data)

        return data
    }

    /// Preload all visual assets for a topic
    /// - Parameter topic: Topic to preload assets for
    public func preloadAssets(for topic: Topic) async {
        let assets = topic.visualAssetSet

        logger.info("Preloading \(assets.count) visual assets for topic: \(topic.title ?? "unknown")")

        for asset in assets {
            guard let assetId = asset.assetId else { continue }

            // Skip if already cached
            if await isCached(assetId: assetId) {
                continue
            }

            // Skip if no remote URL
            guard let remoteURL = asset.remoteURL else { continue }

            do {
                let data = try await downloadAndCache(assetId: assetId, from: remoteURL)

                // Also update the Core Data entity's cached data
                await MainActor.run {
                    asset.cachedData = data
                }

                logger.debug("Preloaded asset: \(assetId)")
            } catch {
                logger.warning("Failed to preload asset \(assetId): \(error)")
            }
        }
    }

    /// Preload all visual assets for a curriculum
    /// - Parameter curriculum: Curriculum to preload assets for
    public func preloadAssets(for curriculum: Curriculum) async {
        guard let topics = curriculum.topics as? Set<Topic> else { return }

        logger.info("Preloading assets for curriculum: \(curriculum.name ?? "unknown") (\(topics.count) topics)")

        for topic in topics {
            await preloadAssets(for: topic)
        }
    }

    /// Clear memory cache
    public func clearMemoryCache() async {
        memoryCache.removeAll()
        currentMemoryCacheSize = 0
        logger.info("Memory cache cleared")
    }

    /// Clear all cached data (memory and disk)
    public func clearAllCache() async throws {
        // Clear memory
        memoryCache.removeAll()
        currentMemoryCacheSize = 0

        // Clear disk
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }

        logger.info("All cache cleared")
    }

    /// Get current cache size
    /// - Returns: Total size in bytes (memory + disk)
    public func cacheSize() async -> Int {
        var diskSize = 0

        if let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in contents {
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    diskSize += size
                }
            }
        }

        return currentMemoryCacheSize + diskSize
    }

    /// Get cache statistics
    /// - Returns: Dictionary with cache statistics
    public func cacheStats() async -> [String: Any] {
        let diskContents = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        let totalSize = await cacheSize()

        return [
            "memoryItemCount": memoryCache.count,
            "memorySizeBytes": currentMemoryCacheSize,
            "diskItemCount": diskContents.count,
            "totalSizeBytes": totalSize,
            "maxMemorySizeBytes": maxMemoryCacheSize
        ]
    }

    // MARK: - Private Helpers

    private func sanitizeFilename(_ assetId: String) -> String {
        // Replace unsafe characters with underscores
        let unsafe = CharacterSet.alphanumerics.inverted
        return assetId.components(separatedBy: unsafe).joined(separator: "_")
    }
}

// MARK: - Errors

public enum VisualAssetCacheError: Error, LocalizedError {
    case downloadFailed(URL)
    case cacheWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let url):
            return "Failed to download asset from: \(url)"
        case .cacheWriteFailed(let message):
            return "Failed to write to cache: \(message)"
        }
    }
}

// MARK: - Topic Extension for Preloading

extension Topic {
    /// Preload all visual assets for offline access
    public func preloadVisualAssets() async {
        await VisualAssetCache.shared.preloadAssets(for: self)
    }
}

// MARK: - Curriculum Extension for Preloading

extension Curriculum {
    /// Preload all visual assets for offline access
    public func preloadVisualAssets() async {
        await VisualAssetCache.shared.preloadAssets(for: self)
    }
}
