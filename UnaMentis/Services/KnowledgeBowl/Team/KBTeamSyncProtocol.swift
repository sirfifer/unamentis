//
//  KBTeamSyncProtocol.swift
//  UnaMentis
//
//  Protocol defining the team sync interface
//  Allows swapping between server and local sync implementations
//

import Foundation

// MARK: - Sync Mode

/// The current synchronization mode for team data
enum KBTeamSyncMode: Sendable, Equatable {
    /// Connected to UnaMentis server
    case server(baseURL: URL)

    /// Local mode, captain's device is source of truth
    case local

    /// Offline, pending sync when connection available
    case offline

    var displayName: String {
        switch self {
        case .server: return "Server"
        case .local: return "Local"
        case .offline: return "Offline"
        }
    }

    var isConnected: Bool {
        switch self {
        case .server, .local: return true
        case .offline: return false
        }
    }
}

// MARK: - Sync Status

/// Status of a sync operation
struct KBTeamSyncStatus: Sendable {
    /// Current sync mode
    let mode: KBTeamSyncMode

    /// Whether sync is currently in progress
    let isSyncing: Bool

    /// Last successful sync time
    let lastSyncTime: Date?

    /// Number of pending changes to sync
    let pendingChanges: Int

    /// Any error from the last sync attempt
    let lastError: String?

    static let initial = KBTeamSyncStatus(
        mode: .offline,
        isSyncing: false,
        lastSyncTime: nil,
        pendingChanges: 0,
        lastError: nil
    )
}

// MARK: - Sync Provider Protocol

/// Protocol for team data synchronization
/// Implemented by both server and local sync providers
protocol KBTeamSyncProvider: Actor {
    /// Current sync status
    var status: KBTeamSyncStatus { get async }

    /// Current sync mode
    var syncMode: KBTeamSyncMode { get async }

    /// Whether currently connected and able to sync
    var isConnected: Bool { get async }

    // MARK: - Team Operations

    /// Fetch the current team profile
    func fetchTeam() async throws -> KBTeamProfile?

    /// Save the team profile
    func saveTeam(_ team: KBTeamProfile) async throws

    /// Delete the team
    func deleteTeam() async throws

    // MARK: - Member Operations

    /// Fetch all team members
    func fetchMembers() async throws -> [KBTeamMember]

    /// Add a new member
    func addMember(_ member: KBTeamMember) async throws

    /// Update an existing member
    func updateMember(_ member: KBTeamMember) async throws

    /// Delete a member
    func deleteMember(id: UUID) async throws

    // MARK: - Stats Operations

    /// Fetch stats for a specific member
    func fetchStats(memberId: UUID) async throws -> KBMemberStats?

    /// Fetch stats for all members
    func fetchAllStats() async throws -> [KBMemberStats]

    /// Push stats update for a member
    func pushStats(_ stats: KBMemberStats) async throws

    // MARK: - Assignment Operations

    /// Fetch all domain assignments
    func fetchAssignments() async throws -> [KBDomainAssignment]

    /// Update domain assignments
    func updateAssignments(_ assignments: [KBDomainAssignment]) async throws

    /// Get auto-suggested assignments based on performance
    func fetchSuggestions() async throws -> [KBAssignmentSuggestion]

    // MARK: - Sync Control

    /// Force a sync now
    func syncNow() async throws

    /// Start automatic sync (if supported)
    func startAutoSync(interval: TimeInterval) async

    /// Stop automatic sync
    func stopAutoSync() async
}

// MARK: - Sync Events

/// Events emitted during sync operations
enum KBTeamSyncEvent: Sendable {
    /// Team profile was updated
    case teamUpdated(KBTeamProfile)

    /// Member was added or updated
    case memberUpdated(KBTeamMember)

    /// Member was removed
    case memberRemoved(UUID)

    /// Stats were updated
    case statsUpdated(KBMemberStats)

    /// Assignments were updated
    case assignmentsUpdated([KBDomainAssignment])

    /// Sync status changed
    case statusChanged(KBTeamSyncStatus)

    /// Error occurred
    case error(String)
}

// MARK: - Sync Event Handler

/// Handler for receiving sync events
protocol KBTeamSyncEventHandler: AnyObject, Sendable {
    /// Called when a sync event occurs
    func handleSyncEvent(_ event: KBTeamSyncEvent) async
}

// MARK: - Provider Factory

/// Factory for creating the appropriate sync provider
enum KBTeamSyncProviderFactory {
    /// Create a sync provider based on configuration
    static func create(
        store: KBTeamStore,
        serverURL: URL? = nil
    ) -> any KBTeamSyncProvider {
        if let serverURL = serverURL {
            // Server mode: will be implemented in Sprint 3
            // For now, fall back to local
            print("[KBTeamSync] Server URL provided: \(serverURL), but server sync not yet implemented")
            return KBLocalTeamSync(store: store)
        } else {
            return KBLocalTeamSync(store: store)
        }
    }

    /// Check if a server URL is reachable
    static func isServerReachable(_ url: URL) async -> Bool {
        // Simple connectivity check
        let healthURL = url.appendingPathComponent("api/health")
        var request = URLRequest(url: healthURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200..<300).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}
