// VoiceLearn - Session View
// Main voice conversation UI
//
// Part of UI/UX (TDD Section 10)

import SwiftUI
import Combine

/// Main session view for voice conversations
public struct SessionView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SessionViewModel()
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Status indicator
                    SessionStatusView(state: viewModel.state)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Transcript display
                    TranscriptView(
                        userTranscript: viewModel.userTranscript,
                        aiResponse: viewModel.aiResponse
                    )
                    .frame(maxHeight: 300)
                    
                    Spacer()
                    
                    // Audio level visualizer
                    AudioLevelView(level: viewModel.audioLevel)
                        .frame(height: 60)
                    
                    // Main control button
                    SessionControlButton(
                        isActive: viewModel.isSessionActive,
                        isLoading: viewModel.isLoading,
                        action: viewModel.toggleSession
                    )
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Voice Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSessionActive {
                        MetricsBadge(
                            latency: viewModel.lastLatency,
                            cost: viewModel.sessionCost
                        )
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SessionSettingsView()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Session Status View

struct SessionStatusView: View {
    let state: SessionState
    
    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay {
                    if state.isActive {
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .scaleEffect(1.5)
                            .opacity(0.7)
                    }
                }
            
            Text(state.rawValue)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .idle: return .gray
        case .userSpeaking: return .green
        case .aiThinking: return .orange
        case .aiSpeaking: return .blue
        case .interrupted: return .yellow
        case .processingUserUtterance: return .purple
        case .error: return .red
        }
    }
}

// MARK: - Transcript View

struct TranscriptView: View {
    let userTranscript: String
    let aiResponse: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !userTranscript.isEmpty {
                    TranscriptBubble(
                        text: userTranscript,
                        isUser: true
                    )
                }
                
                if !aiResponse.isEmpty {
                    TranscriptBubble(
                        text: aiResponse,
                        isUser: false
                    )
                }
            }
            .padding()
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct TranscriptBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            
            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isUser ? Color.blue : Color(.systemGray5))
                }
                .foregroundStyle(isUser ? .white : .primary)
            
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Audio Level View

struct AudioLevelView: View {
    let level: Float
    
    private let barCount = 20
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 8)
                    .scaleEffect(y: barScale(for: index), anchor: .bottom)
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 40)
    }
    
    private func barScale(for index: Int) -> CGFloat {
        // Convert dB to 0-1 range (-60dB to 0dB)
        let normalizedLevel = max(0, min(1, (level + 60) / 60))
        let threshold = Float(index) / Float(barCount)
        return normalizedLevel > threshold ? 1.0 : 0.2
    }
    
    private func barColor(for index: Int) -> Color {
        let ratio = Float(index) / Float(barCount)
        if ratio < 0.6 {
            return .green
        } else if ratio < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Session Control Button

struct SessionControlButton: View {
    let isActive: Bool
    let isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isActive ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(color: (isActive ? Color.red : Color.blue).opacity(0.4), radius: 10)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isActive ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(isLoading)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Metrics Badge

struct MetricsBadge: View {
    let latency: TimeInterval
    let cost: Decimal
    
    var body: some View {
        HStack(spacing: 8) {
            // Latency
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption2)
                Text(String(format: "%.0fms", latency * 1000))
                    .font(.caption.monospacedDigit())
            }
            
            // Cost
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle")
                    .font(.caption2)
                Text(String(format: "$%.3f", NSDecimalNumber(decimal: cost).doubleValue))
                    .font(.caption.monospacedDigit())
            }
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Session Settings View

struct SessionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Audio") {
                    // Audio settings will go here
                    Text("Audio settings coming soon")
                        .foregroundStyle(.secondary)
                }
                
                Section("Voice") {
                    // TTS voice settings
                    Text("Voice settings coming soon")
                        .foregroundStyle(.secondary)
                }
                
                Section("Model") {
                    // LLM model settings
                    Text("Model settings coming soon")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Session Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Session View Model

@MainActor
class SessionViewModel: ObservableObject {
    @Published var state: SessionState = .idle
    @Published var userTranscript: String = ""
    @Published var aiResponse: String = ""
    @Published var audioLevel: Float = -60
    @Published var isLoading: Bool = false
    @Published var showSettings: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var lastLatency: TimeInterval = 0
    @Published var sessionCost: Decimal = 0
    
    var isSessionActive: Bool {
        state.isActive
    }
    
    func toggleSession() async {
        if isSessionActive {
            await stopSession()
        } else {
            await startSession()
        }
    }
    
    private func startSession() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Initialize services and start session
        // This will be connected to SessionManager
        
        state = .userSpeaking
    }
    
    private func stopSession() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Stop session via SessionManager
        
        state = .idle
        userTranscript = ""
        aiResponse = ""
    }
}

// MARK: - Preview

#Preview {
    SessionView()
        .environmentObject(AppState())
}
