// VoiceLearn - Settings View
// Configuration and API key management
//
// Part of UI/UX (TDD Section 10)

import SwiftUI

/// Settings view for app configuration
public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    public init() { }
    
    public var body: some View {
        NavigationStack {
            List {
                // API Keys Section
                Section {
                    ForEach(APIKeyManager.KeyType.allCases, id: \.rawValue) { keyType in
                        APIKeyRow(
                            keyType: keyType,
                            isConfigured: viewModel.keyStatus[keyType] ?? false,
                            onTap: { viewModel.editKey(keyType) }
                        )
                    }
                } header: {
                    Text("API Keys")
                } footer: {
                    Text("API keys are stored securely in the Keychain.")
                }
                
                // Audio Settings Section
                Section("Audio") {
                    Picker("Sample Rate", selection: $viewModel.sampleRate) {
                        Text("16 kHz").tag(16000.0)
                        Text("24 kHz").tag(24000.0)
                        Text("48 kHz").tag(48000.0)
                    }
                    
                    Toggle("Voice Processing", isOn: $viewModel.enableVoiceProcessing)
                    Toggle("Echo Cancellation", isOn: $viewModel.enableEchoCancellation)
                    Toggle("Noise Suppression", isOn: $viewModel.enableNoiseSuppression)
                }
                
                // VAD Settings Section
                Section("Voice Detection") {
                    VStack(alignment: .leading) {
                        Text("Detection Threshold: \(viewModel.vadThreshold, specifier: "%.2f")")
                        Slider(value: $viewModel.vadThreshold, in: 0.3...0.9)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Interruption Threshold: \(viewModel.bargeInThreshold, specifier: "%.2f")")
                        Slider(value: $viewModel.bargeInThreshold, in: 0.5...0.95)
                    }
                    
                    Toggle("Enable Interruptions", isOn: $viewModel.enableBargeIn)
                }
                
                // LLM Settings Section
                Section("Language Model") {
                    Picker("Provider", selection: $viewModel.llmProvider) {
                        Text("OpenAI").tag(LLMProvider.openAI)
                        Text("Anthropic").tag(LLMProvider.anthropic)
                    }
                    
                    Picker("Model", selection: $viewModel.llmModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                        Slider(value: $viewModel.temperature, in: 0...1)
                    }
                    
                    Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 256...4096, step: 256)
                }
                
                // TTS Settings Section
                Section("Voice") {
                    Picker("Provider", selection: $viewModel.ttsProvider) {
                        Text("Deepgram Aura").tag(TTSProvider.deepgramAura2)
                        Text("ElevenLabs").tag(TTSProvider.elevenLabsFlash)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Speaking Rate: \(viewModel.speakingRate, specifier: "%.1f")x")
                        Slider(value: $viewModel.speakingRate, in: 0.5...2.0)
                    }
                }
                
                // Presets Section
                Section("Presets") {
                    Button("Balanced (Default)") {
                        viewModel.applyPreset(.balanced)
                    }
                    Button("Low Latency") {
                        viewModel.applyPreset(.lowLatency)
                    }
                    Button("High Quality") {
                        viewModel.applyPreset(.highQuality)
                    }
                    Button("Cost Optimized") {
                        viewModel.applyPreset(.costOptimized)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Documentation", destination: URL(string: "https://voicelearn.app/docs")!)
                    Link("Privacy Policy", destination: URL(string: "https://voicelearn.app/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(item: $viewModel.editingKeyType) { keyType in
                APIKeyEditSheet(keyType: keyType, onSave: viewModel.saveKey)
            }
        }
    }
}

// MARK: - API Key Row

struct APIKeyRow: View {
    let keyType: APIKeyManager.KeyType
    let isConfigured: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(keyType.displayName)
                    Text(isConfigured ? "Configured" : "Not set")
                        .font(.caption)
                        .foregroundStyle(isConfigured ? .green : .red)
                }
                
                Spacer()
                
                Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(isConfigured ? .green : .red)
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - API Key Edit Sheet

struct APIKeyEditSheet: View {
    let keyType: APIKeyManager.KeyType
    let onSave: (APIKeyManager.KeyType, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var keyValue = ""
    @State private var showKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if showKey {
                            TextField("API Key", text: $keyValue)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("API Key", text: $keyValue)
                        }
                        
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                    }
                } header: {
                    Text(keyType.displayName)
                } footer: {
                    Text("Your API key will be stored securely in the Keychain.")
                }
            }
            .navigationTitle("Edit API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(keyType, keyValue)
                        dismiss()
                    }
                    .disabled(keyValue.isEmpty)
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class SettingsViewModel: ObservableObject {
    // API Keys
    @Published var keyStatus: [APIKeyManager.KeyType: Bool] = [:]
    @Published var editingKeyType: APIKeyManager.KeyType?
    
    // Audio
    @Published var sampleRate: Double = 48000
    @Published var enableVoiceProcessing = true
    @Published var enableEchoCancellation = true
    @Published var enableNoiseSuppression = true
    
    // VAD
    @Published var vadThreshold: Float = 0.5
    @Published var bargeInThreshold: Float = 0.7
    @Published var enableBargeIn = true
    
    // LLM
    @Published var llmProvider: LLMProvider = .openAI
    @Published var llmModel = "gpt-4o"
    @Published var temperature: Float = 0.7
    @Published var maxTokens = 1024
    
    // TTS
    @Published var ttsProvider: TTSProvider = .deepgramAura2
    @Published var speakingRate: Float = 1.0
    
    /// Available models for current provider
    var availableModels: [String] {
        switch llmProvider {
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"]
        case .anthropic:
            return ["claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"]
        default:
            return ["gpt-4o"]
        }
    }
    
    init() {
        Task {
            await loadKeyStatus()
        }
    }
    
    private func loadKeyStatus() async {
        let status = await APIKeyManager.shared.getKeyStatus()
        await MainActor.run {
            keyStatus = status
        }
    }
    
    func editKey(_ keyType: APIKeyManager.KeyType) {
        editingKeyType = keyType
    }
    
    func saveKey(_ keyType: APIKeyManager.KeyType, value: String) {
        Task {
            try? await APIKeyManager.shared.setKey(keyType, value: value)
            await loadKeyStatus()
        }
    }
    
    enum Preset {
        case balanced, lowLatency, highQuality, costOptimized
    }
    
    func applyPreset(_ preset: Preset) {
        switch preset {
        case .balanced:
            sampleRate = 48000
            vadThreshold = 0.5
            llmModel = "gpt-4o"
            temperature = 0.7
            maxTokens = 1024
            
        case .lowLatency:
            sampleRate = 24000
            vadThreshold = 0.4
            llmModel = "gpt-4o-mini"
            temperature = 0.5
            maxTokens = 512
            
        case .highQuality:
            sampleRate = 48000
            vadThreshold = 0.6
            llmModel = "gpt-4o"
            temperature = 0.8
            maxTokens = 2048
            
        case .costOptimized:
            sampleRate = 16000
            vadThreshold = 0.5
            llmModel = "gpt-4o-mini"
            temperature = 0.5
            maxTokens = 512
        }
    }
}

extension APIKeyManager.KeyType: Identifiable {
    public var id: String { rawValue }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
