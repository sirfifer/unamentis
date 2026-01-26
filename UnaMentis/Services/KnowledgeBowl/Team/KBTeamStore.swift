//
//  KBTeamStore.swift
//  UnaMentis
//
//  Local persistence for Knowledge Bowl team data
//  Stores team profile and member stats as JSON files
//

import Foundation

// MARK: - Team Store

/// On-device storage for Knowledge Bowl team data
actor KBTeamStore {
    // MARK: - Storage Locations

    private let fileManager = FileManager.default

    private var teamDirectory: URL {
        get throws {
            let documents = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let teamDir = documents.appendingPathComponent("KnowledgeBowl/Team", isDirectory: true)

            if !fileManager.fileExists(atPath: teamDir.path) {
                try fileManager.createDirectory(at: teamDir, withIntermediateDirectories: true)
            }

            return teamDir
        }
    }

    private var statsDirectory: URL {
        get throws {
            let teamDir = try teamDirectory
            let statsDir = teamDir.appendingPathComponent("stats", isDirectory: true)

            if !fileManager.fileExists(atPath: statsDir.path) {
                try fileManager.createDirectory(at: statsDir, withIntermediateDirectories: true)
            }

            return statsDir
        }
    }

    private var profileURL: URL {
        get throws {
            try teamDirectory.appendingPathComponent("profile.json")
        }
    }

    // MARK: - JSON Encoder/Decoder

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Team Profile Operations

    /// Check if a team profile exists
    func hasTeamProfile() async throws -> Bool {
        let url = try profileURL
        return fileManager.fileExists(atPath: url.path)
    }

    /// Save the team profile
    func saveProfile(_ profile: KBTeamProfile) async throws {
        let url = try profileURL
        let data = try encoder.encode(profile)
        try data.write(to: url, options: [.atomic])
    }

    /// Load the team profile
    func loadProfile() async throws -> KBTeamProfile? {
        let url = try profileURL

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(KBTeamProfile.self, from: data)
    }

    /// Delete the team profile
    func deleteProfile() async throws {
        let url = try profileURL

        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Member Stats Operations

    /// Save stats for a member
    func saveStats(_ stats: KBMemberStats) async throws {
        let directory = try statsDirectory
        let filename = "\(stats.memberId.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        let data = try encoder.encode(stats)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Load stats for a specific member
    func loadStats(memberId: UUID) async throws -> KBMemberStats? {
        let directory = try statsDirectory
        let filename = "\(memberId.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(KBMemberStats.self, from: data)
    }

    /// Load stats for all members
    func loadAllStats() async throws -> [KBMemberStats] {
        let directory = try statsDirectory
        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        var allStats: [KBMemberStats] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let stats = try decoder.decode(KBMemberStats.self, from: data)
                allStats.append(stats)
            } catch {
                print("[KBTeamStore] Failed to load stats from \(fileURL.lastPathComponent): \(error)")
            }
        }

        return allStats
    }

    /// Delete stats for a specific member
    func deleteStats(memberId: UUID) async throws {
        let directory = try statsDirectory
        let filename = "\(memberId.uuidString).json"
        let fileURL = directory.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Export/Import

    /// Export team data as a complete package
    func exportPackage() async throws -> KBTeamProfile.ExportPackage? {
        guard let profile = try await loadProfile() else {
            return nil
        }

        let allStats = try await loadAllStats()
        return KBTeamProfile.ExportPackage(team: profile, memberStats: allStats)
    }

    /// Export team data to a .kbteam file at the specified URL
    func exportToFile(url: URL) async throws {
        guard let package = try await exportPackage() else {
            throw KBTeamStoreError.noTeamProfile
        }

        let data = try encoder.encode(package)
        try data.write(to: url, options: [.atomic])
    }

    /// Import team data from a .kbteam file
    func importFromFile(url: URL, mergeStats: Bool = true) async throws -> KBTeamProfile {
        let data = try Data(contentsOf: url)
        let package = try decoder.decode(KBTeamProfile.ExportPackage.self, from: data)

        // Save the team profile
        try await saveProfile(package.team)

        // Handle stats
        if let importedStats = package.memberStats {
            for stats in importedStats {
                if mergeStats, let existingStats = try await loadStats(memberId: stats.memberId) {
                    // Merge with existing stats
                    var merged = existingStats
                    merged.merge(with: stats)
                    try await saveStats(merged)
                } else {
                    // Save imported stats directly
                    try await saveStats(stats)
                }
            }
        }

        return package.team
    }

    /// Generate a temporary export file URL
    func temporaryExportURL(teamName: String) -> URL {
        let sanitizedName = teamName.replacingOccurrences(of: " ", with: "_")
        let filename = "\(sanitizedName)_\(Date().ISO8601Format()).kbteam"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    // MARK: - Cleanup

    /// Delete all team data
    func deleteAllData() async throws {
        let teamDir = try teamDirectory

        if fileManager.fileExists(atPath: teamDir.path) {
            try fileManager.removeItem(at: teamDir)
        }
    }

    /// Clean up stats for members no longer on the team
    func cleanupOrphanedStats() async throws {
        guard let profile = try await loadProfile() else {
            return
        }

        let memberIds = Set(profile.members.map(\.id))
        let allStats = try await loadAllStats()

        for stats in allStats {
            if !memberIds.contains(stats.memberId) {
                try await deleteStats(memberId: stats.memberId)
            }
        }
    }

    // MARK: - Convenience

    /// Get stats for all current team members
    func loadTeamStats() async throws -> [UUID: KBMemberStats] {
        guard let profile = try await loadProfile() else {
            return [:]
        }

        var statsMap: [UUID: KBMemberStats] = [:]
        for member in profile.members {
            if let stats = try await loadStats(memberId: member.id) {
                statsMap[member.id] = stats
            } else {
                // Return empty stats for members without recorded stats
                statsMap[member.id] = KBMemberStats.empty(for: member.id)
            }
        }

        return statsMap
    }
}

// MARK: - Errors

enum KBTeamStoreError: LocalizedError {
    case noTeamProfile
    case importFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .noTeamProfile:
            return "No team profile exists to export"
        case .importFailed(let reason):
            return "Failed to import team data: \(reason)"
        }
    }
}
