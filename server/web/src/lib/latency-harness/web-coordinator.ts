/**
 * UnaMentis - Web Client Latency Test Coordinator
 * Browser-based test execution for the latency harness
 */

import {
  TestConfiguration,
  TestResult,
  TestScenario,
  TestRun,
  ClientType,
  ClientCapabilities,
  ClientStatus,
  STTProvider,
  LLMProvider,
  TTSProvider,
  NetworkProfile,
  NETWORK_LATENCY_MS,
} from './types';

// ============================================================================
// Web Metrics Collector
// ============================================================================

class WebMetricsCollector {
  private testId: string = '';
  private configId: string = '';
  private scenarioName: string = '';
  private repetition: number = 0;
  private testStartTime: number = 0;

  // Latencies
  private sttLatencyMs?: number;
  private llmTTFBMs: number = 0;
  private llmCompletionMs: number = 0;
  private ttsTTFBMs: number = 0;
  private ttsCompletionMs: number = 0;
  private e2eLatencyMs: number = 0;

  // Quality metrics
  private sttConfidence?: number;
  private ttsAudioDurationMs?: number;
  private llmInputTokens?: number;
  private llmOutputTokens?: number;

  // Errors
  private errors: string[] = [];

  // Configuration snapshot
  private config?: TestConfiguration;

  startTest(config: TestConfiguration): void {
    this.testId = crypto.randomUUID();
    this.configId = config.id;
    this.scenarioName = config.scenarioName;
    this.repetition = config.repetition;
    this.config = config;

    // Reset metrics
    this.sttLatencyMs = undefined;
    this.llmTTFBMs = 0;
    this.llmCompletionMs = 0;
    this.ttsTTFBMs = 0;
    this.ttsCompletionMs = 0;
    this.e2eLatencyMs = 0;
    this.sttConfidence = undefined;
    this.ttsAudioDurationMs = undefined;
    this.llmInputTokens = undefined;
    this.llmOutputTokens = undefined;
    this.errors = [];

    // Record start time using performance.now() for sub-ms precision
    this.testStartTime = performance.now();
  }

  recordSTTLatency(ms: number): void { this.sttLatencyMs = ms; }
  recordLLMTTFB(ms: number): void { this.llmTTFBMs = ms; }
  recordLLMCompletion(ms: number): void { this.llmCompletionMs = ms; }
  recordTTSTTFB(ms: number): void { this.ttsTTFBMs = ms; }
  recordTTSCompletion(ms: number): void { this.ttsCompletionMs = ms; }
  recordE2ELatency(ms: number): void { this.e2eLatencyMs = ms; }
  recordSTTConfidence(confidence: number): void { this.sttConfidence = confidence; }
  recordTTSAudioDuration(ms: number): void { this.ttsAudioDurationMs = ms; }
  recordLLMTokenCounts(input: number, output: number): void {
    this.llmInputTokens = input;
    this.llmOutputTokens = output;
  }
  recordError(error: Error | string): void {
    this.errors.push(typeof error === 'string' ? error : error.message);
  }

  getElapsedMs(): number {
    return performance.now() - this.testStartTime;
  }

  finalizeTest(): TestResult {
    if (this.e2eLatencyMs === 0) {
      this.e2eLatencyMs = this.getElapsedMs();
    }

    // Calculate network projections
    const networkProjections = this.calculateNetworkProjections();

    const result: TestResult = {
      id: this.testId,
      configId: this.configId,
      scenarioName: this.scenarioName,
      repetition: this.repetition,
      timestamp: new Date().toISOString(),
      clientType: 'web',

      sttLatencyMs: this.sttLatencyMs,
      llmTTFBMs: this.llmTTFBMs,
      llmCompletionMs: this.llmCompletionMs,
      ttsTTFBMs: this.ttsTTFBMs,
      ttsCompletionMs: this.ttsCompletionMs,
      e2eLatencyMs: this.e2eLatencyMs,

      networkProfile: this.config?.networkProfile ?? 'localhost',
      networkProjections,

      sttConfidence: this.sttConfidence,
      ttsAudioDurationMs: this.ttsAudioDurationMs,
      llmOutputTokens: this.llmOutputTokens,
      llmInputTokens: this.llmInputTokens,

      // Web doesn't have device metrics
      peakCPUPercent: undefined,
      peakMemoryMB: undefined,
      thermalState: undefined,

      sttConfig: this.config?.stt ?? { provider: 'web-speech', language: 'en-US' },
      llmConfig: this.config?.llm ?? { provider: 'anthropic', model: 'claude-3-5-haiku', maxTokens: 512, temperature: 0.7, stream: true },
      ttsConfig: this.config?.tts ?? { provider: 'web-speech', speed: 1.0, useStreaming: false },
      audioConfig: this.config?.audioEngine ?? { sampleRate: 48000, bufferSize: 1024, vadThreshold: 0.5, vadSmoothingWindow: 5 },

      errors: this.errors,
      isSuccess: this.errors.length === 0,
    };

    return result;
  }

  private calculateNetworkProjections(): Record<NetworkProfile, number> {
    const projections: Record<NetworkProfile, number> = {
      localhost: this.e2eLatencyMs,
      wifi: this.e2eLatencyMs,
      cellular_us: this.e2eLatencyMs,
      cellular_eu: this.e2eLatencyMs,
      intercontinental: this.e2eLatencyMs,
    };

    if (!this.config) return projections;

    // Add network latency for each stage that requires network
    const sttRequiresNetwork = !['web-speech'].includes(this.config.stt.provider);
    const llmRequiresNetwork = !['mlx'].includes(this.config.llm.provider);
    const ttsRequiresNetwork = !['web-speech'].includes(this.config.tts.provider);

    for (const profile of Object.keys(NETWORK_LATENCY_MS) as NetworkProfile[]) {
      const overhead = NETWORK_LATENCY_MS[profile];
      let projected = this.e2eLatencyMs;

      if (sttRequiresNetwork) projected += overhead;
      if (llmRequiresNetwork) projected += overhead;
      if (ttsRequiresNetwork) projected += overhead;

      projections[profile] = projected;
    }

    return projections;
  }
}

// ============================================================================
// Web Latency Test Coordinator
// ============================================================================

export class WebLatencyTestCoordinator {
  private clientId: string;
  private serverUrl: string;
  private metricsCollector: WebMetricsCollector;
  private currentConfig?: TestConfiguration;
  private isRunning: boolean = false;

  constructor(serverUrl: string = 'http://localhost:8766') {
    this.clientId = `web_${crypto.randomUUID().slice(0, 8)}`;
    this.serverUrl = serverUrl;
    this.metricsCollector = new WebMetricsCollector();
  }

  // ============================================================================
  // Client Info
  // ============================================================================

  getCapabilities(): ClientCapabilities {
    return {
      // Web can only use cloud STT providers + Web Speech API
      supportedSTTProviders: ['deepgram', 'assemblyai', 'whisper', 'groq', 'web-speech'],
      // Web can use all cloud LLM providers
      supportedLLMProviders: ['anthropic', 'openai', 'selfhosted'],
      // Web can use cloud TTS + Web Speech API
      supportedTTSProviders: ['deepgram', 'elevenlabs-flash', 'elevenlabs-turbo', 'chatterbox', 'vibevoice', 'piper', 'web-speech'],
      // performance.now() is not as precise as mach_absolute_time
      hasHighPrecisionTiming: false,
      // Browser doesn't expose device metrics
      hasDeviceMetrics: false,
      // No on-device ML in browser
      hasOnDeviceML: false,
      // Can run many tests in parallel
      maxConcurrentTests: 10,
    };
  }

  getStatus(): ClientStatus {
    return {
      clientId: this.clientId,
      clientType: 'web',
      isConnected: true,  // Assuming connected
      isRunningTest: this.isRunning,
      currentConfigId: this.currentConfig?.id,
      lastHeartbeat: new Date(),
    };
  }

  // ============================================================================
  // Test Execution
  // ============================================================================

  async executeTest(
    scenario: TestScenario,
    config: TestConfiguration
  ): Promise<TestResult> {
    this.isRunning = true;
    this.currentConfig = config;

    // Start metrics collection
    this.metricsCollector.startTest(config);

    try {
      switch (scenario.scenarioType) {
        case 'text_input':
          await this.executeTextInputScenario(scenario, config);
          break;
        case 'tts_only':
          await this.executeTTSOnlyScenario(scenario, config);
          break;
        case 'audio_input':
          // Fallback to text if available
          if (scenario.userUtteranceText) {
            await this.executeTextInputScenario(scenario, config);
          } else {
            throw new Error('Audio input not supported in web client without text fallback');
          }
          break;
        case 'conversation':
          throw new Error('Conversation scenarios not yet implemented');
      }
    } catch (error) {
      this.metricsCollector.recordError(error as Error);
    }

    this.isRunning = false;
    return this.metricsCollector.finalizeTest();
  }

  // ============================================================================
  // Scenario Implementations
  // ============================================================================

  private async executeTextInputScenario(
    scenario: TestScenario,
    config: TestConfiguration
  ): Promise<void> {
    const userText = scenario.userUtteranceText ?? 'What is the capital of France?';

    // Phase: LLM
    const llmStartTime = performance.now();
    let firstTokenReceived = false;
    let fullResponse = '';
    let outputTokenCount = 0;

    // Make streaming LLM request
    const llmResponse = await this.callLLMStreaming(userText, config.llm);

    for await (const token of llmResponse) {
      if (!firstTokenReceived) {
        firstTokenReceived = true;
        this.metricsCollector.recordLLMTTFB(performance.now() - llmStartTime);
      }
      fullResponse += token.content;
      if (token.tokenCount) {
        outputTokenCount = token.tokenCount;
      }
    }

    this.metricsCollector.recordLLMCompletion(performance.now() - llmStartTime);
    this.metricsCollector.recordLLMTokenCounts(
      Math.ceil(userText.length / 4),  // Rough estimate
      outputTokenCount
    );

    // Phase: TTS
    const ttsStartTime = performance.now();
    let firstAudioReceived = false;
    let totalAudioDurationMs = 0;

    const ttsResponse = await this.callTTSStreaming(fullResponse, config.tts);

    for await (const chunk of ttsResponse) {
      if (!firstAudioReceived) {
        firstAudioReceived = true;
        this.metricsCollector.recordTTSTTFB(performance.now() - ttsStartTime);
      }
      totalAudioDurationMs += chunk.durationMs;
    }

    this.metricsCollector.recordTTSCompletion(performance.now() - ttsStartTime);
    this.metricsCollector.recordTTSAudioDuration(totalAudioDurationMs);

    // Record E2E
    this.metricsCollector.recordE2ELatency(this.metricsCollector.getElapsedMs());
  }

  private async executeTTSOnlyScenario(
    scenario: TestScenario,
    config: TestConfiguration
  ): Promise<void> {
    // Generate test text based on response type
    const testText = this.getTestText(scenario.expectedResponseType);

    const ttsStartTime = performance.now();
    let firstAudioReceived = false;
    let totalAudioDurationMs = 0;

    const ttsResponse = await this.callTTSStreaming(testText, config.tts);

    for await (const chunk of ttsResponse) {
      if (!firstAudioReceived) {
        firstAudioReceived = true;
        this.metricsCollector.recordTTSTTFB(performance.now() - ttsStartTime);
      }
      totalAudioDurationMs += chunk.durationMs;
    }

    this.metricsCollector.recordTTSCompletion(performance.now() - ttsStartTime);
    this.metricsCollector.recordTTSAudioDuration(totalAudioDurationMs);
    this.metricsCollector.recordE2ELatency(performance.now() - ttsStartTime);
  }

  private getTestText(responseType: 'short' | 'medium' | 'long'): string {
    switch (responseType) {
      case 'short':
        return 'The capital of France is Paris. It is known for the Eiffel Tower.';
      case 'medium':
        return `Photosynthesis is the process by which plants convert sunlight into energy.
                During this process, plants absorb carbon dioxide from the air and water from the soil.
                Using sunlight as energy, they convert these into glucose and oxygen.
                The glucose provides energy for the plant to grow, while the oxygen is released into the atmosphere.`;
      case 'long':
        return `The human heart is a remarkable organ that serves as the body's primary circulatory pump.
                Located in the chest cavity between the lungs, it beats approximately 100,000 times per day.
                The heart consists of four chambers: two upper chambers called atria and two lower chambers called ventricles.
                Deoxygenated blood returns to the right atrium from the body through the superior and inferior vena cava.
                It then flows into the right ventricle, which pumps it to the lungs for oxygenation.
                Oxygen-rich blood returns from the lungs to the left atrium, flows into the left ventricle,
                and is then pumped throughout the body via the aorta.`;
    }
  }

  // ============================================================================
  // Provider Calls
  // ============================================================================

  private async *callLLMStreaming(
    userText: string,
    config: TestConfiguration['llm']
  ): AsyncGenerator<{ content: string; tokenCount?: number }> {
    // For now, call through our backend API which proxies to LLM providers
    const response = await fetch(`${this.serverUrl}/api/llm/stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        provider: config.provider,
        model: config.model,
        messages: [
          { role: 'system', content: 'You are a helpful tutor. Be concise.' },
          { role: 'user', content: userText },
        ],
        maxTokens: config.maxTokens,
        temperature: config.temperature,
        stream: true,
      }),
    });

    if (!response.ok) {
      throw new Error(`LLM request failed: ${response.statusText}`);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('No response body');
    }

    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() ?? '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') continue;
          try {
            const parsed = JSON.parse(data);
            if (parsed.content) {
              yield { content: parsed.content, tokenCount: parsed.tokenCount };
            }
          } catch {
            // Ignore parse errors
          }
        }
      }
    }
  }

  private async *callTTSStreaming(
    text: string,
    config: TestConfiguration['tts']
  ): AsyncGenerator<{ data: ArrayBuffer; durationMs: number }> {
    // Call through our backend API which proxies to TTS providers
    const response = await fetch(`${this.serverUrl}/api/tts/stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        provider: config.provider,
        text,
        voiceId: config.voiceId,
        speed: config.speed,
        useStreaming: config.useStreaming,
        chatterboxConfig: config.chatterboxConfig,
      }),
    });

    if (!response.ok) {
      throw new Error(`TTS request failed: ${response.statusText}`);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('No response body');
    }

    // For simplicity, assuming chunked audio response
    // In production, would properly parse audio chunks
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      // Estimate duration from chunk size (rough approximation)
      // Assuming 24kHz 16-bit mono audio
      const samples = value.byteLength / 2;
      const durationMs = (samples / 24000) * 1000;

      yield { data: value.buffer, durationMs };
    }
  }

  // ============================================================================
  // Server Communication
  // ============================================================================

  async reportResult(result: TestResult): Promise<void> {
    await fetch(`${this.serverUrl}/api/latency-tests/results`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        clientId: this.clientId,
        clientType: 'web',
        result,
      }),
    });
  }

  async sendHeartbeat(): Promise<void> {
    await fetch(`${this.serverUrl}/api/latency-tests/heartbeat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        clientId: this.clientId,
        clientType: 'web',
        status: this.getStatus(),
        capabilities: this.getCapabilities(),
      }),
    });
  }
}

// ============================================================================
// Singleton Instance
// ============================================================================

let instance: WebLatencyTestCoordinator | null = null;

export function getWebLatencyTestCoordinator(serverUrl?: string): WebLatencyTestCoordinator {
  if (!instance) {
    instance = new WebLatencyTestCoordinator(serverUrl);
  }
  return instance;
}
