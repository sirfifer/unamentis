// UnaMentis - History View
// Session history and playback
//
// Part of UI/UX (TDD Section 10)

import SwiftUI
import CoreData
import Logging
#if os(iOS)
import UIKit
#endif

/// Session history view showing past conversations
public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showingHistoryHelp = false

    private static let logger = Logger(label: "com.unamentis.ui.history.view")

    public init() {
        // NOTE: No logging in init - can be called frequently by SwiftUI
    }

    public var body: some View {
        // NOTE: Removed debug logging from view body to prevent side effects
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    SessionListView(sessions: viewModel.sessions)
                }
            }
            .navigationTitle("History")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BrandLogo(size: .compact)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingHistoryHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .accessibilityLabel("History help")
                        .accessibilityHint("Learn about session history and metrics")

                        if !viewModel.sessions.isEmpty {
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
                            .accessibilityLabel("History options")
                        }
                    }
                }
            }
            #endif
            .sheet(isPresented: $showingHistoryHelp) {
                HistoryHelpSheet()
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
            #if os(iOS)
            .sheet(isPresented: $viewModel.showExportSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
            #endif
            .task {
                // Load data after view appears (non-blocking)
                Self.logger.info("HistoryView .task STARTED")
                await viewModel.loadAsync()
                Self.logger.info("HistoryView .task COMPLETED")
            }
        }
    }
}

// MARK: - Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
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
            // Top row: Session type icon, title, time
            HStack(spacing: 8) {
                Image(systemName: session.sessionType.iconName)
                    .foregroundStyle(sessionTypeColor)
                    .font(.caption)

                Text(sessionTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(formatTime(session.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Middle row: Duration, turns, cost (conditional)
            HStack(spacing: 16) {
                Label(formatDuration(session.duration), systemImage: "clock")
                Label(session.turnCount == 1 ? "1 turn" : "\(session.turnCount) turns", systemImage: "message")

                if session.shouldShowCost {
                    Label(formatCost(session.totalCost), systemImage: "dollarsign.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Bottom row: Provider badges
            if let providers = session.providers {
                ProviderBadgesRow(providers: providers)
            }

            // Validation indicator if present
            if session.hasValidation {
                ValidationIndicator(results: session.validationResults)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.sessionType.displayName): \(sessionTitle)")
        .accessibilityValue(accessibilityDescription)
        .accessibilityHint("Double-tap to view session details")
    }

    private var sessionTitle: String {
        // For curriculum sessions, show curriculum name if available
        if let curriculumInfo = session.curriculumInfo {
            return curriculumInfo.curriculumName
        }
        return session.topicName ?? "General Conversation"
    }

    private var sessionTypeColor: Color {
        switch session.sessionType {
        case .chat: return .blue
        case .module: return .purple
        case .curriculum: return .orange
        }
    }

    private var accessibilityDescription: String {
        var parts = ["Duration \(formatDuration(session.duration))", "\(session.turnCount) turns"]
        if session.shouldShowCost {
            parts.append("cost \(formatCost(session.totalCost))")
        }
        return parts.joined(separator: ", ")
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

// MARK: - Provider Badges Row

struct ProviderBadgesRow: View {
    let providers: SessionProviders

    var body: some View {
        HStack(spacing: 6) {
            if let stt = providers.stt {
                ProviderBadge(label: "STT", provider: stt, color: .blue)
            }
            if let llm = providers.llm {
                ProviderBadge(label: "LLM", provider: llm, color: .purple)
            }
            if let tts = providers.tts {
                ProviderBadge(label: "TTS", provider: tts, color: .green)
            }
        }
    }
}

struct ProviderBadge: View {
    let label: String
    let provider: SessionProviderInfo
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: provider.location.iconName)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityLabel("\(label): \(provider.providerName), \(provider.location.displayName)")
    }
}

// MARK: - Validation Indicator

struct ValidationIndicator: View {
    let results: [SessionValidationResult]

    private var passedCount: Int {
        results.filter { $0.passed }.count
    }

    private var allPassed: Bool {
        passedCount == results.count
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: allPassed ? "checkmark.seal.fill" : "checkmark.seal")
                .foregroundStyle(allPassed ? .green : .orange)
                .font(.caption2)

            Text("\(passedCount)/\(results.count) passed")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    let session: SessionSummary
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session info with type badge
                EnhancedSessionInfoCard(session: session)

                // Provider information
                if let providers = session.providers {
                    ProvidersCard(providers: providers)
                }

                // Curriculum info if applicable
                if let curriculumInfo = session.curriculumInfo {
                    CurriculumCard(info: curriculumInfo)
                }

                // Validation results if present
                if !session.validationResults.isEmpty {
                    ValidationResultsCard(results: session.validationResults)
                }

                // Transcript (adapted for curriculum sessions)
                if session.sessionType == .curriculum, let curriculumInfo = session.curriculumInfo {
                    CurriculumTranscriptCard(
                        entries: session.transcriptPreview,
                        curriculumInfo: curriculumInfo
                    )
                } else {
                    TranscriptCard(entries: session.transcriptPreview)
                }

                // Metrics (cost only if applicable)
                EnhancedMetricsCard(
                    latency: session.avgLatency,
                    cost: session.totalCost,
                    showCost: session.shouldShowCost
                )
            }
            .padding()
        }
        .navigationTitle("Session Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        exportTranscript()
                    } label: {
                        Label("Export Transcript", systemImage: "doc.text")
                    }
                    Button {
                        shareSession()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        #endif
    }

    private func exportTranscript() {
        let transcriptText = session.transcriptPreview.map { entry in
            "\(entry.isUser ? "You" : "AI"): \(entry.content)"
        }.joined(separator: "\n\n")

        let content = """
        Session: \(session.topicName ?? "General Conversation")
        Date: \(formatDate(session.startTime))
        Duration: \(formatDuration(session.duration))
        Turns: \(session.turnCount)
        Cost: \(formatCost(session.totalCost))

        ---

        \(transcriptText)
        """

        // Write to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "session_\(session.id.uuidString.prefix(8))_transcript.txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showShareSheet = true
        } catch {
            print("Failed to export transcript: \(error)")
        }
    }

    private func shareSession() {
        // Create shareable content
        let content = """
        Learning Session Summary
        Topic: \(session.topicName ?? "General Conversation")
        Duration: \(formatDuration(session.duration))
        Date: \(formatDate(session.startTime))
        Turns: \(session.turnCount)
        """

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "session_summary.txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showShareSheet = true
        } catch {
            print("Failed to share session: \(error)")
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

    private func formatCost(_ cost: Decimal) -> String {
        String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue)
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Average latency")
            .accessibilityValue("\(Int(latency * 1000)) milliseconds")

            Divider()

            VStack {
                Text(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
                    .font(.title2.bold())
                Text("Total Cost")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total cost")
            .accessibilityValue(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Enhanced Session Info Card

struct EnhancedSessionInfoCard: View {
    let session: SessionSummary

    var body: some View {
        VStack(spacing: 12) {
            // Session type badge and title
            HStack {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: session.sessionType.iconName)
                    Text(session.sessionType.displayName)
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sessionTypeColor.opacity(0.15))
                .foregroundStyle(sessionTypeColor)
                .clipShape(Capsule())

                Spacer()

                Text(formatDuration(session.duration))
                    .font(.headline)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text(sessionTitle)
                        .font(.headline)
                    Text(formatDate(session.startTime))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    private var sessionTitle: String {
        if let curriculumInfo = session.curriculumInfo {
            return curriculumInfo.curriculumName
        }
        return session.topicName ?? "General Conversation"
    }

    private var sessionTypeColor: Color {
        switch session.sessionType {
        case .chat: return .blue
        case .module: return .purple
        case .curriculum: return .orange
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

// MARK: - Providers Card

struct ProvidersCard: View {
    let providers: SessionProviders

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Models Used", systemImage: "cpu")
                .font(.headline)

            VStack(spacing: 8) {
                if let stt = providers.stt {
                    ProviderRow(category: "Speech-to-Text", provider: stt, color: .blue)
                }
                if let llm = providers.llm {
                    ProviderRow(category: "Language Model", provider: llm, color: .purple)
                }
                if let tts = providers.tts {
                    ProviderRow(category: "Text-to-Speech", provider: tts, color: .green)
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

struct ProviderRow: View {
    let category: String
    let provider: SessionProviderInfo
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(provider.displayString)
                    .font(.subheadline)
            }

            Spacer()

            // Location badge
            HStack(spacing: 4) {
                Image(systemName: provider.location.iconName)
                Text(provider.location.shortLabel)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Curriculum Card

struct CurriculumCard: View {
    let info: CurriculumSessionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Curriculum", systemImage: "book.closed")
                    .font(.headline)
                Spacer()
                if let source = info.source {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Topics covered
            if !info.topicsCovered.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Topics Covered")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(info.topicsCovered) { topic in
                        TopicProgressRow(topic: topic)
                    }
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

struct TopicProgressRow: View {
    let topic: CurriculumSessionInfo.TopicSummary

    var body: some View {
        HStack {
            Text(topic.title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            if let improvement = topic.masteryImprovement {
                HStack(spacing: 4) {
                    Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(improvement >= 0 ? .green : .red)
                    Text(String(format: "%.0f%%", improvement * 100))
                }
                .font(.caption)
                .foregroundStyle(improvement >= 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Validation Results Card

struct ValidationResultsCard: View {
    let results: [SessionValidationResult]

    private var passedCount: Int {
        results.filter { $0.passed }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Validation Results", systemImage: "checkmark.seal")
                    .font(.headline)
                Spacer()
                Text("\(passedCount)/\(results.count) passed")
                    .font(.subheadline)
                    .foregroundStyle(passedCount == results.count ? .green : .orange)
            }

            ForEach(results) { result in
                ValidationResultRow(result: result)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

struct ValidationResultRow: View {
    let result: SessionValidationResult

    var body: some View {
        HStack {
            Image(systemName: result.type.iconName)
                .foregroundStyle(result.passed ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.type.displayName)
                    .font(.subheadline)
                if let details = result.details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let scoreString = result.scoreString {
                Text(scoreString)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(result.passed ? .green : .red)
            } else {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.passed ? .green : .red)
            }
        }
    }
}

// MARK: - Curriculum Transcript Card

struct CurriculumTranscriptCard: View {
    let entries: [TranscriptPreview]
    let curriculumInfo: CurriculumSessionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Session Summary", systemImage: "doc.text")
                .font(.headline)

            // Curriculum source info
            VStack(alignment: .leading, spacing: 4) {
                if let source = curriculumInfo.source {
                    Text("Source: \(source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Curriculum: \(curriculumInfo.curriculumName)")
                    .font(.subheadline)

                if !curriculumInfo.topicsCovered.isEmpty {
                    Text("Topics: \(curriculumInfo.topicsCovered.map { $0.title }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 8)

            Divider()

            // Key interactions from transcript
            Text("Key Interactions")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

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

// MARK: - Enhanced Metrics Card

struct EnhancedMetricsCard: View {
    let latency: TimeInterval
    let cost: Decimal
    let showCost: Bool

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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Average latency")
            .accessibilityValue("\(Int(latency * 1000)) milliseconds")

            if showCost {
                Divider()

                VStack {
                    Text(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
                        .font(.title2.bold())
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total cost")
                .accessibilityValue(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
            }
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
    @Published var exportURL: URL?
    @Published var showExportSheet = false

    private let persistence = PersistenceController.shared
    private let logger = Logger(label: "com.unamentis.ui.history")

    /// Whether data has been loaded
    private var hasLoaded = false

    init() {
        // NOTE: No logging in init - can be called frequently by SwiftUI
        // Data loading is deferred to loadAsync() called from the view's .task modifier
    }

    /// Load data asynchronously (call from view's .task modifier)
    func loadAsync() async {
        logger.info("HistoryViewModel.loadAsync() START - hasLoaded=\(hasLoaded)")
        guard !hasLoaded else {
            logger.info("HistoryViewModel.loadAsync() SKIPPED - already loaded")
            return
        }
        hasLoaded = true
        logger.info("HistoryViewModel.loadAsync() calling loadFromCoreDataAsync()")
        await loadFromCoreDataAsync()
        logger.info("HistoryViewModel.loadAsync() COMPLETE")
    }

    /// Load sessions from Core Data using background context to avoid blocking MainActor
    private func loadFromCoreDataAsync() async {
        logger.info("loadFromCoreDataAsync() START - creating background context")
        let backgroundContext = persistence.newBackgroundContext()
        logger.info("loadFromCoreDataAsync() background context created, launching Task.detached")

        // Use Task.detached to ensure we're truly off the MainActor
        let summaries: [SessionSummary] = await Task.detached(priority: .userInitiated) { [logger] in
            logger.info("loadFromCoreDataAsync() Task.detached ENTERED")
            let result = await backgroundContext.perform {
                logger.info("loadFromCoreDataAsync() backgroundContext.perform ENTERED")
                let request = Session.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Session.startTime, ascending: false)]
                request.fetchLimit = 100
                // Prefetch relationships to avoid faulting issues
                request.relationshipKeyPathsForPrefetching = ["topic", "transcript"]

                do {
                    logger.info("loadFromCoreDataAsync() executing fetch...")
                    let coreDataSessions = try backgroundContext.fetch(request)
                    logger.info("loadFromCoreDataAsync() fetched \(coreDataSessions.count) sessions")

                    let mapped = coreDataSessions.compactMap { session -> SessionSummary? in
                        guard let id = session.id,
                              let startTime = session.startTime else {
                            return nil
                        }

                        // Get topic name (prefetched, so no additional fetch)
                        let topicName = session.topic?.title

                        // Get transcript entries for preview
                        let transcriptEntries = (session.transcript?.array as? [TranscriptEntry]) ?? []
                        let preview = transcriptEntries.prefix(3).compactMap { entry -> TranscriptPreview? in
                            guard let content = entry.content, let role = entry.role else { return nil }
                            return TranscriptPreview(isUser: role == "user", content: String(content.prefix(100)))
                        }

                        // Calculate average latency from metrics snapshot if available
                        var avgLatency: TimeInterval = 0.3 // default
                        if let metricsData = session.metricsSnapshot {
                            // Try decoding the full MetricsSnapshot format first
                            if let metrics = try? JSONDecoder().decode(MetricsSnapshot.self, from: metricsData) {
                                avgLatency = TimeInterval(metrics.latencies.e2eMedianMs) / 1000.0
                            } else if let legacyMetrics = try? JSONDecoder().decode(SessionMetricsData.self, from: metricsData),
                                      let lat = legacyMetrics.avgLatency {
                                avgLatency = lat
                            }
                        }

                        return SessionSummary(
                            id: id,
                            startTime: startTime,
                            duration: session.duration,
                            topicName: topicName,
                            turnCount: transcriptEntries.count,
                            totalCost: session.totalCost as Decimal? ?? 0,
                            avgLatency: avgLatency,
                            transcriptPreview: preview,
                            sessionType: session.sessionType,
                            providers: session.providers,
                            curriculumInfo: session.curriculum,
                            validationResults: session.validations
                        )
                    }
                    logger.info("loadFromCoreDataAsync() mapped \(mapped.count) session summaries")
                    return mapped
                } catch {
                    logger.error("loadFromCoreDataAsync() fetch ERROR: \(error)")
                    return []
                }
            }
            logger.info("loadFromCoreDataAsync() backgroundContext.perform COMPLETE")
            return result
        }.value

        logger.info("loadFromCoreDataAsync() Task.detached COMPLETE, updating UI with \(summaries.count) sessions")

        // Update UI on MainActor (we're already on MainActor due to class isolation)
        self.sessions = summaries
        logger.info("loadFromCoreDataAsync() UI updated, COMPLETE")
    }

    /// Synchronous load for refresh operations (called from MainActor context)
    func loadFromCoreData() {
        Task {
            await loadFromCoreDataAsync()
        }
    }

    func exportAllSessions() {
        do {
            let coreDataSessions = try persistence.fetchRecentSessions(limit: 1000)
            let exportData = coreDataSessions.map { session -> [String: Any] in
                var dict: [String: Any] = [
                    "id": session.id?.uuidString ?? "",
                    "startTime": session.startTime?.ISO8601Format() ?? "",
                    "duration": session.duration,
                    "totalCost": (session.totalCost as NSDecimalNumber?)?.doubleValue ?? 0
                ]

                if let topic = session.topic {
                    dict["topic"] = topic.title ?? "Unknown"
                }

                // Include transcript
                if let entries = session.transcript?.array as? [TranscriptEntry] {
                    dict["transcript"] = entries.map { entry in
                        [
                            "role": entry.role ?? "unknown",
                            "content": entry.content ?? "",
                            "timestamp": entry.timestamp?.ISO8601Format() ?? ""
                        ]
                    }
                }

                return dict
            }

            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)

            // Write to temp file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "voicelearn_sessions_\(Date().ISO8601Format()).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try jsonData.write(to: fileURL)

            exportURL = fileURL
            showExportSheet = true
        } catch {
            logger.error("Failed to export sessions: \(error.localizedDescription)")
        }
    }

    func clearHistory() {
        let context = persistence.viewContext

        // Fetch all sessions
        let request = Session.fetchRequest()
        do {
            let sessions = try context.fetch(request)
            for session in sessions {
                context.delete(session)
            }
            try persistence.save()
            self.sessions.removeAll()
        } catch {
            logger.error("Failed to clear sessions: \(error.localizedDescription)")
        }
    }
}

// Helper struct for session metrics decoding from legacy format
private struct SessionMetricsData: Codable {
    let avgLatency: TimeInterval?
    let totalCost: Double?
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

    // Enhanced fields
    let sessionType: SessionType
    let providers: SessionProviders?
    let curriculumInfo: CurriculumSessionInfo?
    let validationResults: [SessionValidationResult]

    /// Whether to show cost (only if > 0 and uses paid providers)
    var shouldShowCost: Bool {
        totalCost > 0 || (providers?.hasCosts ?? false)
    }

    /// Whether this session has validation results
    var hasValidation: Bool {
        !validationResults.isEmpty
    }

    /// Overall validation pass rate
    var validationPassRate: Float? {
        guard !validationResults.isEmpty else { return nil }
        let passedCount = validationResults.filter { $0.passed }.count
        return Float(passedCount) / Float(validationResults.count)
    }
}

struct TranscriptPreview: Identifiable {
    let id = UUID()
    let isUser: Bool
    let content: String
}

// MARK: - History Help Sheet

/// In-app help for the history view explaining metrics and features
struct HistoryHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Overview Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review your past learning sessions. Each entry shows when you studied, how long, key metrics, and which AI models were used.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Session Types Section
                Section("Session Types") {
                    HistoryHelpRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: .blue,
                        title: "Chat",
                        description: "Free-form conversation with the AI tutor on any topic."
                    )
                    HistoryHelpRow(
                        icon: "square.stack.3d.up.fill",
                        iconColor: .purple,
                        title: "Module",
                        description: "Structured learning module with specific objectives."
                    )
                    HistoryHelpRow(
                        icon: "book.closed.fill",
                        iconColor: .orange,
                        title: "Curriculum",
                        description: "Curriculum-based learning following a study plan with progress tracking."
                    )
                }

                // Metrics Explained Section
                Section("Understanding Metrics") {
                    HistoryHelpRow(
                        icon: "clock.fill",
                        iconColor: .green,
                        title: "Duration",
                        description: "Total time spent in the session."
                    )
                    HistoryHelpRow(
                        icon: "message.fill",
                        iconColor: .blue,
                        title: "Turns",
                        description: "Number of conversation exchanges. You speak, then the AI responds. That's one turn."
                    )
                    HistoryHelpRow(
                        icon: "dollarsign.circle.fill",
                        iconColor: .orange,
                        title: "Cost",
                        description: "Estimated API usage costs. Only shown when paid cloud models were used. On-device and self-hosted options are free."
                    )
                    HistoryHelpRow(
                        icon: "timer",
                        iconColor: .purple,
                        title: "Avg Latency",
                        description: "Average response time. Lower is better. Target: under 500ms."
                    )
                }

                // Models Section
                Section("AI Models Used") {
                    HistoryHelpRow(
                        icon: "waveform",
                        iconColor: .blue,
                        title: "STT (Speech-to-Text)",
                        description: "Converts your voice to text. Shows which provider processed your speech."
                    )
                    HistoryHelpRow(
                        icon: "brain",
                        iconColor: .purple,
                        title: "LLM (Language Model)",
                        description: "The AI that generates intelligent responses to your questions."
                    )
                    HistoryHelpRow(
                        icon: "speaker.wave.2.fill",
                        iconColor: .green,
                        title: "TTS (Text-to-Speech)",
                        description: "Converts AI responses to natural speech."
                    )
                }

                // Provider Locations Section
                Section("Where Models Run") {
                    HistoryHelpRow(
                        icon: "cloud.fill",
                        iconColor: .cyan,
                        title: "Cloud",
                        description: "Runs on external servers (OpenAI, Anthropic, etc.). Highest quality but may have costs."
                    )
                    HistoryHelpRow(
                        icon: "server.rack",
                        iconColor: .indigo,
                        title: "Self-Hosted",
                        description: "Runs on your own server. No external costs, requires your hardware."
                    )
                    HistoryHelpRow(
                        icon: "iphone",
                        iconColor: .mint,
                        title: "On-Device",
                        description: "Runs entirely on your device. Free, works offline, maximum privacy."
                    )
                }

                // Validation Section
                Section("Assessments") {
                    HistoryHelpRow(
                        icon: "checkmark.seal.fill",
                        iconColor: .green,
                        title: "Validation Results",
                        description: "Shows quiz scores, comprehension checks, and other assessments from the session."
                    )
                }

                // What Good Metrics Look Like
                Section("Target Metrics") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Latency")
                            Spacer()
                            Text("< 500ms")
                                .foregroundStyle(.green)
                        }
                        HStack {
                            Text("Cost per hour")
                            Spacer()
                            Text("< $0.50")
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.subheadline)
                }

                // Export Section
                Section("Exporting Data") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export your session history as JSON for backup or analysis. Use the menu button to export all sessions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Tips Section
                Section("Tips") {
                    Label("Tap any session to see the full transcript", systemImage: "hand.tap.fill")
                        .foregroundStyle(.blue, .primary)
                    Label("Sessions are grouped by date automatically", systemImage: "calendar")
                        .foregroundStyle(.purple, .primary)
                    Label("Provider badges show where each AI model ran", systemImage: "cpu")
                        .foregroundStyle(.orange, .primary)
                }
            }
            .navigationTitle("History Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Helper row for history help items
private struct HistoryHelpRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}

#Preview("History Help") {
    HistoryHelpSheet()
}
