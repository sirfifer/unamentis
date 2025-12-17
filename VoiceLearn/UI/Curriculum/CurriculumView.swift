// VoiceLearn - Curriculum View
// UI for browsing and starting curriculum topics
//
// Part of Curriculum UI (Phase 4 Integration)

import SwiftUI

struct CurriculumView: View {
    @EnvironmentObject var appState: AppState
    @State private var topics: [Topic] = []
    @State private var curriculumName: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                if topics.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Curriculum Loaded",
                        systemImage: "book.closed",
                        description: Text("Import a curriculum to get started.")
                    )
                } else {
                    if let name = curriculumName {
                        Section {
                            ForEach(topics, id: \.id) { topic in
                                TopicRow(topic: topic)
                                    .onTapGesture {
                                        startTopic(topic)
                                    }
                            }
                        } header: {
                            Text(name)
                        } footer: {
                            Text("\(topics.count) topics")
                        }
                    } else {
                        ForEach(topics, id: \.id) { topic in
                            TopicRow(topic: topic)
                                .onTapGesture {
                                    startTopic(topic)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Curriculum")
            .task {
                await loadCurriculumAndTopics()
            }
            .refreshable {
                await loadCurriculumAndTopics()
            }
        }
    }

    private func loadCurriculumAndTopics() async {
        isLoading = true

        // First, try to load first available curriculum from Core Data
        await loadFirstCurriculum()

        // Then load topics from the active curriculum
        guard let engine = appState.curriculum else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }

        let loadedTopics = await engine.getTopics()
        let name = await engine.activeCurriculum?.name

        await MainActor.run {
            self.topics = loadedTopics
            self.curriculumName = name
            self.isLoading = false
        }
    }

    private func loadFirstCurriculum() async {
        guard let engine = appState.curriculum else { return }

        // Check if we already have an active curriculum
        let hasActive = await engine.activeCurriculum != nil
        if hasActive { return }

        // Load first available curriculum
        let context = PersistenceController.shared.viewContext
        let request = Curriculum.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Curriculum.createdAt, ascending: false)]

        do {
            let results = try context.fetch(request)
            if let firstCurriculum = results.first, let id = firstCurriculum.id {
                try await engine.loadCurriculum(id)
            }
        } catch {
            print("Failed to load curriculum: \(error)")
        }
    }
    
    private func startTopic(_ topic: Topic) {
        Task {
            guard let engine = appState.curriculum else { return }
            do {
                try await engine.startTopic(topic)
                // In a real app, this would navigate to the SessionView
                // For now, we update the engine state which SessionManager can observe if needed
            } catch {
                print("Failed to start topic: \(error)")
            }
        }
    }
}

struct TopicRow: View {
    @ObservedObject var topic: Topic
    
    var body: some View {
        HStack {
            StatusIcon(status: topic.status)
            
            VStack(alignment: .leading) {
                Text(topic.title ?? "Untitled Topic")
                    .font(.headline)
                
                if let summary = topic.outline, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if let progress = topic.progress, progress.timeSpent > 0 {
                    Text(formatTime(progress.timeSpent))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes)m spent"
    }
}

struct StatusIcon: View {
    let status: TopicStatus
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 32, height: 32)
            
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
        }
    }
    
    var iconName: String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .reviewing: return "arrow.triangle.2.circlepath"
        }
    }
    
    var iconColor: Color {
        switch status {
        case .notStarted: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .reviewing: return .orange
        }
    }
}

#Preview {
    CurriculumView()
        .environmentObject(AppState())
}
