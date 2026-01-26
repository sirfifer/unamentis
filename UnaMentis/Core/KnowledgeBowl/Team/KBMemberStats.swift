//
//  KBMemberStats.swift
//  UnaMentis
//
//  Performance statistics for Knowledge Bowl team members
//

import Foundation

// MARK: - Member Stats

/// Performance statistics for a team member across all domains
struct KBMemberStats: Codable, Sendable, Identifiable, Equatable {
    /// Member ID this stats record belongs to
    let memberId: UUID

    /// Stats broken down by domain
    var domainStats: [String: KBDomainStats]

    /// When the member last practiced
    var lastPracticeDate: Date?

    /// Total number of practice sessions
    var totalSessions: Int

    /// Total questions answered across all sessions
    var totalQuestions: Int

    /// When these stats were last synced with other devices/server
    var lastSyncedAt: Date

    /// Computed identifier for Identifiable conformance
    var id: UUID { memberId }

    // MARK: - Initialization

    init(
        memberId: UUID,
        domainStats: [String: KBDomainStats] = [:],
        lastPracticeDate: Date? = nil,
        totalSessions: Int = 0,
        totalQuestions: Int = 0,
        lastSyncedAt: Date = Date()
    ) {
        self.memberId = memberId
        self.domainStats = domainStats
        self.lastPracticeDate = lastPracticeDate
        self.totalSessions = totalSessions
        self.totalQuestions = totalQuestions
        self.lastSyncedAt = lastSyncedAt
    }

    // MARK: - Domain Stats Access

    /// Get stats for a specific domain
    func stats(for domain: KBDomain) -> KBDomainStats? {
        domainStats[domain.rawValue]
    }

    /// Update stats for a domain
    mutating func updateStats(for domain: KBDomain, stats: KBDomainStats) {
        domainStats[domain.rawValue] = stats
        lastSyncedAt = Date()
    }

    /// Get the member's strongest domains (sorted by accuracy)
    var strongestDomains: [(domain: KBDomain, stats: KBDomainStats)] {
        domainStats.compactMap { key, stats in
            guard let domain = KBDomain(rawValue: key) else { return nil }
            return (domain, stats)
        }
        .filter { $0.stats.questionCount >= 5 } // Need minimum questions for meaningful ranking
        .sorted { $0.stats.accuracy > $1.stats.accuracy }
    }

    /// Get the member's weakest domains (sorted by accuracy ascending)
    var weakestDomains: [(domain: KBDomain, stats: KBDomainStats)] {
        domainStats.compactMap { key, stats in
            guard let domain = KBDomain(rawValue: key) else { return nil }
            return (domain, stats)
        }
        .filter { $0.stats.questionCount >= 5 }
        .sorted { $0.stats.accuracy < $1.stats.accuracy }
    }

    /// Overall accuracy across all domains
    var overallAccuracy: Double {
        let allStats = domainStats.values
        guard !allStats.isEmpty else { return 0 }

        let totalCorrect = allStats.reduce(0) { $0 + Int(Double($1.questionCount) * $1.accuracy) }
        let totalQuestions = allStats.reduce(0) { $0 + $1.questionCount }

        guard totalQuestions > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestions)
    }

    /// Average response time across all domains
    var averageResponseTime: TimeInterval {
        let allStats = domainStats.values.filter { $0.questionCount > 0 }
        guard !allStats.isEmpty else { return 0 }

        let weightedSum = allStats.reduce(0.0) {
            $0 + ($1.avgResponseTime * Double($1.questionCount))
        }
        let totalQuestions = allStats.reduce(0) { $0 + $1.questionCount }

        guard totalQuestions > 0 else { return 0 }
        return weightedSum / Double(totalQuestions)
    }

    // MARK: - Session Recording

    /// Record results from a practice session
    mutating func recordSession(
        domain: KBDomain,
        questionsAnswered: Int,
        correctAnswers: Int,
        avgResponseTime: TimeInterval
    ) {
        var stats = domainStats[domain.rawValue] ?? KBDomainStats()

        // Update running averages
        let oldTotal = stats.questionCount
        let newTotal = oldTotal + questionsAnswered

        if newTotal > 0 {
            // Weighted average for accuracy
            let oldCorrect = Int(stats.accuracy * Double(oldTotal))
            let newCorrect = oldCorrect + correctAnswers
            stats.accuracy = Double(newCorrect) / Double(newTotal)

            // Weighted average for response time
            let oldTimeSum = stats.avgResponseTime * Double(oldTotal)
            let newTimeSum = avgResponseTime * Double(questionsAnswered)
            stats.avgResponseTime = (oldTimeSum + newTimeSum) / Double(newTotal)

            stats.questionCount = newTotal
        }

        // Update mastery level based on new accuracy and question count
        stats.masteryLevel = KBMasteryLevel.calculate(
            accuracy: stats.accuracy,
            questionCount: stats.questionCount
        )

        domainStats[domain.rawValue] = stats
        lastPracticeDate = Date()
        totalSessions += 1
        totalQuestions += questionsAnswered
        lastSyncedAt = Date()
    }
}

// MARK: - Domain Stats

/// Performance statistics for a single domain
struct KBDomainStats: Codable, Sendable, Equatable {
    /// Accuracy rate (0.0 to 1.0)
    var accuracy: Double

    /// Average response time in seconds
    var avgResponseTime: TimeInterval

    /// Total questions answered in this domain
    var questionCount: Int

    /// Current mastery level
    var masteryLevel: KBMasteryLevel

    init(
        accuracy: Double = 0,
        avgResponseTime: TimeInterval = 0,
        questionCount: Int = 0,
        masteryLevel: KBMasteryLevel = .beginner
    ) {
        self.accuracy = accuracy
        self.avgResponseTime = avgResponseTime
        self.questionCount = questionCount
        self.masteryLevel = masteryLevel
    }
}

// MARK: - Mastery Level

/// Mastery level for a domain based on performance
enum KBMasteryLevel: String, Codable, Sendable, CaseIterable {
    case beginner = "beginner"
    case developing = "developing"
    case intermediate = "intermediate"
    case proficient = "proficient"
    case expert = "expert"

    /// Display name for UI
    var displayName: String {
        rawValue.capitalized
    }

    /// Icon for this mastery level
    var icon: String {
        switch self {
        case .beginner: return "leaf"
        case .developing: return "arrow.up.right"
        case .intermediate: return "chart.bar"
        case .proficient: return "star"
        case .expert: return "star.fill"
        }
    }

    /// Color associated with this mastery level (hex)
    var colorHex: String {
        switch self {
        case .beginner: return "#9CA3AF"     // Gray
        case .developing: return "#3B82F6"   // Blue
        case .intermediate: return "#22C55E" // Green
        case .proficient: return "#F59E0B"   // Amber
        case .expert: return "#8B5CF6"       // Purple
        }
    }

    /// Calculate mastery level based on performance metrics
    static func calculate(accuracy: Double, questionCount: Int) -> KBMasteryLevel {
        // Need minimum questions for each level
        guard questionCount >= 5 else { return .beginner }

        switch (accuracy, questionCount) {
        case (0.9..., 50...):
            return .expert
        case (0.8..., 30...):
            return .proficient
        case (0.7..., 15...):
            return .intermediate
        case (0.5..., 10...):
            return .developing
        default:
            return .beginner
        }
    }
}

// MARK: - Stats Aggregation

extension KBMemberStats {
    /// Create an empty stats record for a new member
    static func empty(for memberId: UUID) -> KBMemberStats {
        KBMemberStats(memberId: memberId)
    }

    /// Merge stats from another device/sync source
    mutating func merge(with other: KBMemberStats) {
        // Take the more recent sync time
        guard other.lastSyncedAt > lastSyncedAt else { return }

        // Merge domain stats, preferring higher question counts
        for (domain, otherStats) in other.domainStats {
            if let existing = domainStats[domain] {
                if otherStats.questionCount > existing.questionCount {
                    domainStats[domain] = otherStats
                }
            } else {
                domainStats[domain] = otherStats
            }
        }

        // Take the more recent practice date
        if let otherDate = other.lastPracticeDate {
            if let currentDate = lastPracticeDate {
                lastPracticeDate = max(currentDate, otherDate)
            } else {
                lastPracticeDate = otherDate
            }
        }

        // Take higher session/question counts
        totalSessions = max(totalSessions, other.totalSessions)
        totalQuestions = max(totalQuestions, other.totalQuestions)
        lastSyncedAt = Date()
    }
}
