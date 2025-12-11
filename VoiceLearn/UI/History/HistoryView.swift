// VoiceLearn - History View
// Session history and playback
//
// Part of UI/UX (TDD Section 10)

import SwiftUI
import CoreData

/// Session history view showing past conversations
public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    SessionListView(sessions: viewModel.sessions)
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !viewModel.sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Export All") {
                                viewModel.exportAllSessions()
                            }
                            Button("Clear History", role: .destructive) {
                                viewModel.showClearConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $viewModel.showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Sessions", role: .destructive) {
                    viewModel.clearHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all session history.")
            }
        }
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        ContentUnavailableView(
            "No Sessions Yet",
            systemImage: "clock.badge.questionmark",
            description: Text("Your conversation history will appear here after your first session.")
        )
    }
}

// MARK: - Session List

struct SessionListView: View {
    let sessions: [SessionSummary]
    
    var body: some View {
        List {
            ForEach(groupedSessions, id: \.0) { date, daySessions in
                Section {
                    ForEach(daySessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                } header: {
                    Text(formatDate(date))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var groupedSessions: [(Date, [SessionSummary])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: SessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.topicName ?? "General Conversation")
                    .font(.headline)
                Spacer()
                Text(formatTime(session.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                Label(formatDuration(session.duration), systemImage: "clock")
                Label("\(session.turnCount) turns", systemImage: "message")
                Label(formatCost(session.totalCost), systemImage: "dollarsign.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes)m"
    }
    
    private func formatCost(_ cost: Decimal) -> String {
        String(format: "$%.2f", NSDecimalNumber(decimal: cost).doubleValue)
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    let session: SessionSummary
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session info
                SessionInfoCard(session: session)
                
                // Transcript
                TranscriptCard(entries: session.transcriptPreview)
                
                // Metrics
                MetricsCard(latency: session.avgLatency, cost: session.totalCost)
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Export Transcript") { }
                    Button("Share") { }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

struct SessionInfoCard: View {
    let session: SessionSummary
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(session.topicName ?? "General")
                        .font(.headline)
                    Text(formatDate(session.startTime))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(formatDuration(session.duration))
                        .font(.headline)
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct TranscriptCard: View {
    let entries: [TranscriptPreview]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Transcript", systemImage: "text.quote")
                .font(.headline)
            
            ForEach(entries) { entry in
                HStack(alignment: .top) {
                    Image(systemName: entry.isUser ? "person.fill" : "cpu")
                        .foregroundStyle(entry.isUser ? .blue : .purple)
                    Text(entry.content)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

struct MetricsCard: View {
    let latency: TimeInterval
    let cost: Decimal
    
    var body: some View {
        HStack {
            VStack {
                Text(String(format: "%.0fms", latency * 1000))
                    .font(.title2.bold())
                Text("Avg Latency")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack {
                Text(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
                    .font(.title2.bold())
                Text("Total Cost")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - View Model

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var sessions: [SessionSummary] = []
    @Published var showClearConfirmation = false
    
    init() {
        // TODO: Load from Core Data
    }
    
    func exportAllSessions() {
        // TODO: Implement export
    }
    
    func clearHistory() {
        // TODO: Clear Core Data
        sessions.removeAll()
    }
}

// MARK: - Data Models

struct SessionSummary: Identifiable {
    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    let topicName: String?
    let turnCount: Int
    let totalCost: Decimal
    let avgLatency: TimeInterval
    let transcriptPreview: [TranscriptPreview]
}

struct TranscriptPreview: Identifiable {
    let id = UUID()
    let isUser: Bool
    let content: String
}

// MARK: - Preview

#Preview {
    HistoryView()
}
