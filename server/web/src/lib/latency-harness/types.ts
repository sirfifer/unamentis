/**
 * UnaMentis - Latency Test Harness Types
 * Shared type definitions for the web client test harness
 */

// ============================================================================
// Client Types
// ============================================================================

export type ClientType = 'ios_simulator' | 'ios_device' | 'web';

export interface ClientCapabilities {
  supportedSTTProviders: STTProvider[];
  supportedLLMProviders: LLMProvider[];
  supportedTTSProviders: TTSProvider[];
  hasHighPrecisionTiming: boolean;
  hasDeviceMetrics: boolean;
  hasOnDeviceML: boolean;
  maxConcurrentTests: number;
}

export interface ClientStatus {
  clientId: string;
  clientType: ClientType;
  isConnected: boolean;
  isRunningTest: boolean;
  currentConfigId?: string;
  lastHeartbeat: Date;
}

// ============================================================================
// Provider Types
// ============================================================================

export type STTProvider =
  | 'deepgram'
  | 'assemblyai'
  | 'whisper'
  | 'groq'
  | 'apple'
  | 'glm-asr'
  | 'glm-asr-ondevice'
  | 'web-speech';

export type LLMProvider =
  | 'anthropic'
  | 'openai'
  | 'selfhosted'
  | 'mlx';

export type TTSProvider =
  | 'deepgram'
  | 'elevenlabs-flash'
  | 'elevenlabs-turbo'
  | 'playht'
  | 'apple'
  | 'piper'
  | 'vibevoice'
  | 'chatterbox'
  | 'web-speech';

// ============================================================================
// Test Configuration
// ============================================================================

export interface TestConfiguration {
  id: string;
  scenarioName: string;
  repetition: number;
  stt: STTTestConfig;
  llm: LLMTestConfig;
  tts: TTSTestConfig;
  audioEngine: AudioEngineTestConfig;
  networkProfile: NetworkProfile;
}

export interface STTTestConfig {
  provider: STTProvider;
  model?: string;
  chunkSizeMs?: number;
  language: string;
}

export interface LLMTestConfig {
  provider: LLMProvider;
  model: string;
  maxTokens: number;
  temperature: number;
  topP?: number;
  stream: boolean;
}

export interface TTSTestConfig {
  provider: TTSProvider;
  voiceId?: string;
  speed: number;
  useStreaming: boolean;
  chatterboxConfig?: ChatterboxConfig;
}

export interface ChatterboxConfig {
  exaggeration: number;
  cfgWeight: number;
  speed: number;
  enableParalinguisticTags: boolean;
  useMultilingual: boolean;
  language: string;
  useStreaming: boolean;
  seed?: number;
}

export interface AudioEngineTestConfig {
  sampleRate: number;
  bufferSize: number;
  vadThreshold: number;
  vadSmoothingWindow: number;
}

export type NetworkProfile =
  | 'localhost'
  | 'wifi'
  | 'cellular_us'
  | 'cellular_eu'
  | 'intercontinental';

export const NETWORK_LATENCY_MS: Record<NetworkProfile, number> = {
  localhost: 0,
  wifi: 10,
  cellular_us: 50,
  cellular_eu: 70,
  intercontinental: 120,
};

// ============================================================================
// Test Scenario
// ============================================================================

export type ScenarioType = 'audio_input' | 'text_input' | 'tts_only' | 'conversation';
export type ResponseType = 'short' | 'medium' | 'long';

export interface TestScenario {
  id: string;
  name: string;
  description: string;
  scenarioType: ScenarioType;
  repetitions: number;
  userUtteranceAudioPath?: string;
  userUtteranceText?: string;
  expectedResponseType: ResponseType;
}

// ============================================================================
// Test Result
// ============================================================================

export interface TestResult {
  id: string;
  configId: string;
  scenarioName: string;
  repetition: number;
  timestamp: string;  // ISO date string
  clientType: ClientType;

  // Per-stage latencies (milliseconds)
  sttLatencyMs?: number;
  llmTTFBMs: number;
  llmCompletionMs: number;
  ttsTTFBMs: number;
  ttsCompletionMs: number;
  e2eLatencyMs: number;

  // Network projections
  networkProfile: NetworkProfile;
  networkProjections: Record<NetworkProfile, number>;

  // Quality metrics
  sttConfidence?: number;
  ttsAudioDurationMs?: number;
  llmOutputTokens?: number;
  llmInputTokens?: number;

  // Resource utilization (may be unavailable on web)
  peakCPUPercent?: number;
  peakMemoryMB?: number;
  thermalState?: string;

  // Configuration snapshot
  sttConfig: STTTestConfig;
  llmConfig: LLMTestConfig;
  ttsConfig: TTSTestConfig;
  audioConfig: AudioEngineTestConfig;

  // Errors
  errors: string[];
  isSuccess: boolean;
}

// ============================================================================
// Test Run
// ============================================================================

export type RunStatus = 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';

export interface TestRun {
  id: string;
  suiteName: string;
  suiteId: string;
  startedAt: string;
  completedAt?: string;
  clientId: string;
  clientType: ClientType;
  status: RunStatus;
  totalConfigurations: number;
  completedConfigurations: number;
  results: TestResult[];
}

// ============================================================================
// Analysis Report
// ============================================================================

export interface AnalysisReport {
  runId: string;
  generatedAt: string;
  summary: SummaryStatistics;
  bestConfigurations: RankedConfiguration[];
  networkProjections: NetworkProjection[];
  regressions: Regression[];
  recommendations: string[];
}

export interface SummaryStatistics {
  totalConfigurations: number;
  totalTests: number;
  successfulTests: number;
  failedTests: number;
  overallMedianE2EMs: number;
  overallP99E2EMs: number;
  overallMinE2EMs: number;
  overallMaxE2EMs: number;
  medianSTTMs?: number;
  medianLLMTTFBMs: number;
  medianLLMCompletionMs: number;
  medianTTSTTFBMs: number;
  medianTTSCompletionMs: number;
  testDurationMinutes: number;
}

export interface RankedConfiguration {
  rank: number;
  configId: string;
  medianE2EMs: number;
  p99E2EMs: number;
  stddevMs: number;
  sampleCount: number;
  breakdown: LatencyBreakdown;
  networkProjections: Record<string, NetworkMeetsTarget>;
  estimatedCostPerHour: number;
}

export interface LatencyBreakdown {
  sttMs?: number;
  llmTTFBMs: number;
  llmCompletionMs: number;
  ttsTTFBMs: number;
  ttsCompletionMs: number;
}

export interface NetworkMeetsTarget {
  e2eMs: number;
  meets500ms: boolean;
  meets1000ms: boolean;
}

export interface NetworkProjection {
  network: string;
  addedLatencyMs: number;
  projectedMedianMs: number;
  projectedP99Ms: number;
  meetsTarget: boolean;
  configsMeetingTarget: number;
  totalConfigs: number;
}

export interface Regression {
  configId: string;
  metric: string;
  baselineValue: number;
  currentValue: number;
  changePercent: number;
  severity: 'minor' | 'moderate' | 'severe';
}

// ============================================================================
// Test Suite Definition
// ============================================================================

export interface TestSuiteDefinition {
  id: string;
  name: string;
  description: string;
  scenarios: TestScenario[];
  networkProfiles: NetworkProfile[];
  parameterSpace: ParameterSpace;
}

export interface ParameterSpace {
  sttConfigs: STTTestConfig[];
  llmConfigs: LLMTestConfig[];
  ttsConfigs: TTSTestConfig[];
  audioConfigs: AudioEngineTestConfig[];
}
