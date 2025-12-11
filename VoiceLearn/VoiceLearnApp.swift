// VoiceLearn iOS
// Real-Time Bidirectional Voice AI Platform for Extended Educational Conversations
//
// Entry point for the VoiceLearn application.

import SwiftUI
import Logging

/// Main application entry point
@main
struct VoiceLearnApp: App {
    /// Application state container
    @StateObject private var appState = AppState()
    
    /// Configure logging on app launch
    init() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

/// Root content view with tab navigation
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            SessionView()
                .tabItem {
                    Label("Session", systemImage: "waveform")
                }
            
            CurriculumView()
                .tabItem {
                    Label("Curriculum", systemImage: "book")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}



// MARK: - App State

/// Central application state container
/// Manages all core services and shared state
@MainActor
public class AppState: ObservableObject {
    /// Telemetry engine for metrics tracking
    public let telemetry = TelemetryEngine()
    
    /// API key manager
    public let apiKeys = APIKeyManager.shared
    
    /// Session manager (created when session starts)
    @Published public var sessionManager: SessionManager?
    
    /// Whether the app has all required configuration
    @Published public var isConfigured: Bool = false
    
    public init() {
        Task {
            await checkConfiguration()
        }
    }
    
    /// Curriculum engine
    @Published public var curriculum: CurriculumEngine?
    
    /// Check if all required API keys are configured
    private func checkConfiguration() async {
        let missingKeys = await apiKeys.validateRequiredKeys()
        await MainActor.run {
            isConfigured = missingKeys.isEmpty
        }
        
        if isConfigured {
            await initializeCurriculum()
        }
    }
    
    private func initializeCurriculum() async {
        guard let openAIKey = await apiKeys.getKey(.openAI) else { return }
        
        let embeddingService = OpenAIEmbeddingService(apiKey: openAIKey)
        let engine = CurriculumEngineFactory.create(
            persistenceController: .shared,
            embeddingService: embeddingService,
            telemetry: telemetry
        )
        
        await MainActor.run {
            self.curriculum = engine
        }
    }
    
    /// Create a new session manager with configured services
    public func createSessionManager() async throws -> SessionManager {
        guard isConfigured else {
            throw SessionError.servicesNotConfigured
        }
        
        let manager = SessionManager(
            telemetry: telemetry,
            curriculum: curriculum
        )
        sessionManager = manager
        return manager
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
