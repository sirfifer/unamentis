"""
UnaMentis Latency Test Harness - Data Models

Shared data structures for test configuration, results, and analysis.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, List, Any
import uuid


# ============================================================================
# Enums
# ============================================================================

class ClientType(str, Enum):
    IOS_SIMULATOR = "ios_simulator"
    IOS_DEVICE = "ios_device"
    WEB = "web"


class RunStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class NetworkProfile(str, Enum):
    LOCALHOST = "localhost"
    WIFI = "wifi"
    CELLULAR_US = "cellular_us"
    CELLULAR_EU = "cellular_eu"
    INTERCONTINENTAL = "intercontinental"

    @property
    def added_latency_ms(self) -> float:
        """Expected network overhead in milliseconds."""
        return {
            NetworkProfile.LOCALHOST: 0,
            NetworkProfile.WIFI: 10,
            NetworkProfile.CELLULAR_US: 50,
            NetworkProfile.CELLULAR_EU: 70,
            NetworkProfile.INTERCONTINENTAL: 120,
        }[self]


class ScenarioType(str, Enum):
    AUDIO_INPUT = "audio_input"
    TEXT_INPUT = "text_input"
    TTS_ONLY = "tts_only"
    CONVERSATION = "conversation"


class ResponseType(str, Enum):
    SHORT = "short"
    MEDIUM = "medium"
    LONG = "long"


class RegressionSeverity(str, Enum):
    MINOR = "minor"       # 10-20% regression
    MODERATE = "moderate" # 20-50% regression
    SEVERE = "severe"     # >50% regression


# ============================================================================
# Provider Configurations
# ============================================================================

@dataclass
class STTTestConfig:
    provider: str
    model: Optional[str] = None
    chunk_size_ms: Optional[int] = None
    language: str = "en-US"

    @property
    def requires_network(self) -> bool:
        return self.provider not in ["apple", "glm-asr-ondevice", "web-speech"]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "provider": self.provider,
            "model": self.model,
            "chunkSizeMs": self.chunk_size_ms,
            "language": self.language,
        }


@dataclass
class LLMTestConfig:
    provider: str
    model: str
    max_tokens: int = 512
    temperature: float = 0.7
    top_p: Optional[float] = None
    stream: bool = True

    @property
    def requires_network(self) -> bool:
        return self.provider not in ["mlx"]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "provider": self.provider,
            "model": self.model,
            "maxTokens": self.max_tokens,
            "temperature": self.temperature,
            "topP": self.top_p,
            "stream": self.stream,
        }


@dataclass
class ChatterboxConfig:
    exaggeration: float = 0.5
    cfg_weight: float = 0.5
    speed: float = 1.0
    enable_paralinguistic_tags: bool = False
    use_multilingual: bool = False
    language: str = "en"
    use_streaming: bool = True
    seed: Optional[int] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "exaggeration": self.exaggeration,
            "cfgWeight": self.cfg_weight,
            "speed": self.speed,
            "enableParalinguisticTags": self.enable_paralinguistic_tags,
            "useMultilingual": self.use_multilingual,
            "language": self.language,
            "useStreaming": self.use_streaming,
            "seed": self.seed,
        }


@dataclass
class TTSTestConfig:
    provider: str
    voice_id: Optional[str] = None
    speed: float = 1.0
    use_streaming: bool = True
    chatterbox_config: Optional[ChatterboxConfig] = None

    @property
    def requires_network(self) -> bool:
        return self.provider not in ["apple", "web-speech"]

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "provider": self.provider,
            "voiceId": self.voice_id,
            "speed": self.speed,
            "useStreaming": self.use_streaming,
        }
        if self.chatterbox_config:
            result["chatterboxConfig"] = self.chatterbox_config.to_dict()
        return result


@dataclass
class AudioEngineTestConfig:
    sample_rate: float = 24000
    buffer_size: int = 1024
    vad_threshold: float = 0.5
    vad_smoothing_window: int = 5

    def to_dict(self) -> Dict[str, Any]:
        return {
            "sampleRate": self.sample_rate,
            "bufferSize": self.buffer_size,
            "vadThreshold": self.vad_threshold,
            "vadSmoothingWindow": self.vad_smoothing_window,
        }


# ============================================================================
# Test Configuration
# ============================================================================

@dataclass
class TestConfiguration:
    """Complete configuration for a single test execution."""
    id: str
    scenario_name: str
    repetition: int
    stt: STTTestConfig
    llm: LLMTestConfig
    tts: TTSTestConfig
    audio_engine: AudioEngineTestConfig
    network_profile: NetworkProfile = NetworkProfile.LOCALHOST

    @property
    def config_id(self) -> str:
        """Generate a unique configuration identifier."""
        return f"{self.stt.provider}_{self.llm.provider}_{self.llm.model}_{self.tts.provider}"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "scenarioName": self.scenario_name,
            "repetition": self.repetition,
            "stt": self.stt.to_dict(),
            "llm": self.llm.to_dict(),
            "tts": self.tts.to_dict(),
            "audioEngine": self.audio_engine.to_dict(),
            "networkProfile": self.network_profile.value,
        }


# ============================================================================
# Test Scenario
# ============================================================================

@dataclass
class TestScenario:
    """Definition of a test scenario."""
    id: str
    name: str
    description: str
    scenario_type: ScenarioType
    repetitions: int = 10
    user_utterance_audio_path: Optional[str] = None
    user_utterance_text: Optional[str] = None
    expected_response_type: ResponseType = ResponseType.MEDIUM

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "scenarioType": self.scenario_type.value,
            "repetitions": self.repetitions,
            "userUtteranceAudioPath": self.user_utterance_audio_path,
            "userUtteranceText": self.user_utterance_text,
            "expectedResponseType": self.expected_response_type.value,
        }


# ============================================================================
# Test Result
# ============================================================================

@dataclass
class TestResult:
    """Complete result from a single test execution."""
    id: str
    config_id: str
    scenario_name: str
    repetition: int
    timestamp: datetime
    client_type: ClientType

    # Per-stage latencies (milliseconds)
    stt_latency_ms: Optional[float]
    llm_ttfb_ms: float
    llm_completion_ms: float
    tts_ttfb_ms: float
    tts_completion_ms: float
    e2e_latency_ms: float

    # Network profile
    network_profile: NetworkProfile
    network_projections: Dict[str, float] = field(default_factory=dict)

    # Quality metrics
    stt_confidence: Optional[float] = None
    tts_audio_duration_ms: Optional[float] = None
    llm_output_tokens: Optional[int] = None
    llm_input_tokens: Optional[int] = None

    # Resource utilization
    peak_cpu_percent: Optional[float] = None
    peak_memory_mb: Optional[float] = None
    thermal_state: Optional[str] = None

    # Configuration snapshot
    stt_config: Optional[Dict[str, Any]] = None
    llm_config: Optional[Dict[str, Any]] = None
    tts_config: Optional[Dict[str, Any]] = None
    audio_config: Optional[Dict[str, Any]] = None

    # Errors
    errors: List[str] = field(default_factory=list)

    @property
    def is_success(self) -> bool:
        return len(self.errors) == 0

    def calculate_network_projections(
        self,
        stt_requires_network: bool,
        llm_requires_network: bool,
        tts_requires_network: bool,
    ) -> Dict[str, float]:
        """Calculate projected E2E latency for different network conditions."""
        projections = {}
        for profile in NetworkProfile:
            projected = self.e2e_latency_ms
            if stt_requires_network:
                projected += profile.added_latency_ms
            if llm_requires_network:
                projected += profile.added_latency_ms
            if tts_requires_network:
                projected += profile.added_latency_ms
            projections[profile.value] = projected
        return projections

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "configId": self.config_id,
            "scenarioName": self.scenario_name,
            "repetition": self.repetition,
            "timestamp": self.timestamp.isoformat(),
            "clientType": self.client_type.value,
            "sttLatencyMs": self.stt_latency_ms,
            "llmTTFBMs": self.llm_ttfb_ms,
            "llmCompletionMs": self.llm_completion_ms,
            "ttsTTFBMs": self.tts_ttfb_ms,
            "ttsCompletionMs": self.tts_completion_ms,
            "e2eLatencyMs": self.e2e_latency_ms,
            "networkProfile": self.network_profile.value,
            "networkProjections": self.network_projections,
            "sttConfidence": self.stt_confidence,
            "ttsAudioDurationMs": self.tts_audio_duration_ms,
            "llmOutputTokens": self.llm_output_tokens,
            "llmInputTokens": self.llm_input_tokens,
            "peakCPUPercent": self.peak_cpu_percent,
            "peakMemoryMB": self.peak_memory_mb,
            "thermalState": self.thermal_state,
            "sttConfig": self.stt_config,
            "llmConfig": self.llm_config,
            "ttsConfig": self.tts_config,
            "audioConfig": self.audio_config,
            "errors": self.errors,
            "isSuccess": self.is_success,
        }


# ============================================================================
# Client Status
# ============================================================================

@dataclass
class ClientCapabilities:
    """Capabilities of a test client."""
    supported_stt_providers: List[str]
    supported_llm_providers: List[str]
    supported_tts_providers: List[str]
    has_high_precision_timing: bool
    has_device_metrics: bool
    has_on_device_ml: bool
    max_concurrent_tests: int


@dataclass
class ClientStatus:
    """Current status of a test client."""
    client_id: str
    client_type: ClientType
    is_connected: bool
    is_running_test: bool
    current_config_id: Optional[str]
    last_heartbeat: datetime
    capabilities: Optional[ClientCapabilities] = None


# ============================================================================
# Test Run
# ============================================================================

@dataclass
class TestRun:
    """A complete test run (execution of a test suite)."""
    id: str
    suite_name: str
    suite_id: str
    started_at: datetime
    client_id: str
    client_type: ClientType
    total_configurations: int
    status: RunStatus = RunStatus.PENDING
    completed_at: Optional[datetime] = None
    completed_configurations: int = 0
    results: List[TestResult] = field(default_factory=list)

    @property
    def progress_percent(self) -> float:
        if self.total_configurations == 0:
            return 0.0
        return self.completed_configurations / self.total_configurations * 100

    @property
    def elapsed_time(self) -> float:
        """Elapsed time in seconds."""
        end_time = self.completed_at or datetime.now()
        return (end_time - self.started_at).total_seconds()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "suiteName": self.suite_name,
            "suiteId": self.suite_id,
            "startedAt": self.started_at.isoformat(),
            "completedAt": self.completed_at.isoformat() if self.completed_at else None,
            "clientId": self.client_id,
            "clientType": self.client_type.value,
            "status": self.status.value,
            "totalConfigurations": self.total_configurations,
            "completedConfigurations": self.completed_configurations,
            "progressPercent": self.progress_percent,
            "elapsedTimeSeconds": self.elapsed_time,
        }


# ============================================================================
# Analysis Report
# ============================================================================

@dataclass
class LatencyBreakdown:
    stt_ms: Optional[float]
    llm_ttfb_ms: float
    llm_completion_ms: float
    tts_ttfb_ms: float
    tts_completion_ms: float


@dataclass
class NetworkMeetsTarget:
    e2e_ms: float
    meets_500ms: bool
    meets_1000ms: bool


@dataclass
class RankedConfiguration:
    rank: int
    config_id: str
    median_e2e_ms: float
    p99_e2e_ms: float
    stddev_ms: float
    sample_count: int
    breakdown: LatencyBreakdown
    network_projections: Dict[str, NetworkMeetsTarget]
    estimated_cost_per_hour: float


@dataclass
class SummaryStatistics:
    total_configurations: int
    total_tests: int
    successful_tests: int
    failed_tests: int
    overall_median_e2e_ms: float
    overall_p99_e2e_ms: float
    overall_min_e2e_ms: float
    overall_max_e2e_ms: float
    median_stt_ms: Optional[float]
    median_llm_ttfb_ms: float
    median_llm_completion_ms: float
    median_tts_ttfb_ms: float
    median_tts_completion_ms: float
    test_duration_minutes: float


@dataclass
class NetworkProjection:
    network: str
    added_latency_ms: float
    projected_median_ms: float
    projected_p99_ms: float
    meets_target: bool
    configs_meeting_target: int
    total_configs: int


@dataclass
class Regression:
    config_id: str
    metric: str
    baseline_value: float
    current_value: float
    change_percent: float
    severity: RegressionSeverity


@dataclass
class AnalysisReport:
    run_id: str
    generated_at: datetime
    summary: SummaryStatistics
    best_configurations: List[RankedConfiguration]
    network_projections: List[NetworkProjection]
    regressions: List[Regression]
    recommendations: List[str]


# ============================================================================
# Test Suite Definition
# ============================================================================

@dataclass
class ParameterSpace:
    stt_configs: List[STTTestConfig]
    llm_configs: List[LLMTestConfig]
    tts_configs: List[TTSTestConfig]
    audio_configs: List[AudioEngineTestConfig] = field(
        default_factory=lambda: [AudioEngineTestConfig()]
    )


@dataclass
class TestSuiteDefinition:
    """Complete test suite definition."""
    id: str
    name: str
    description: str
    scenarios: List[TestScenario]
    network_profiles: List[NetworkProfile]
    parameter_space: ParameterSpace

    def generate_configurations(self) -> List[TestConfiguration]:
        """Generate all test configurations from parameter space."""
        configs = []
        config_index = 0

        for scenario in self.scenarios:
            for stt_config in self.parameter_space.stt_configs:
                for llm_config in self.parameter_space.llm_configs:
                    for tts_config in self.parameter_space.tts_configs:
                        for audio_config in self.parameter_space.audio_configs:
                            for network_profile in self.network_profiles:
                                for repetition in range(1, scenario.repetitions + 1):
                                    config_index += 1
                                    config = TestConfiguration(
                                        id=f"config_{config_index}",
                                        scenario_name=scenario.name,
                                        repetition=repetition,
                                        stt=stt_config,
                                        llm=llm_config,
                                        tts=tts_config,
                                        audio_engine=audio_config,
                                        network_profile=network_profile,
                                    )
                                    configs.append(config)

        return configs

    @property
    def total_test_count(self) -> int:
        """Estimated total number of tests."""
        scenario_reps = sum(s.repetitions for s in self.scenarios)
        return (
            scenario_reps
            * len(self.parameter_space.stt_configs)
            * len(self.parameter_space.llm_configs)
            * len(self.parameter_space.tts_configs)
            * len(self.parameter_space.audio_configs)
            * len(self.network_profiles)
        )


# ============================================================================
# Predefined Test Suites
# ============================================================================

def create_quick_validation_suite() -> TestSuiteDefinition:
    """Quick validation suite for CI/CD."""
    return TestSuiteDefinition(
        id="quick_validation",
        name="Quick Validation",
        description="Fast sanity check for CI/CD pipelines",
        scenarios=[
            TestScenario(
                id="short_response",
                name="Short Response",
                description="Brief Q&A exchange",
                scenario_type=ScenarioType.TEXT_INPUT,
                repetitions=3,
                user_utterance_text="What is the capital of France?",
                expected_response_type=ResponseType.SHORT,
            )
        ],
        network_profiles=[NetworkProfile.LOCALHOST],
        parameter_space=ParameterSpace(
            stt_configs=[STTTestConfig(provider="deepgram")],
            llm_configs=[LLMTestConfig(provider="anthropic", model="claude-3-5-haiku-20241022")],
            tts_configs=[TTSTestConfig(provider="chatterbox")],
        ),
    )


def create_provider_comparison_suite() -> TestSuiteDefinition:
    """Provider comparison suite."""
    return TestSuiteDefinition(
        id="provider_comparison",
        name="Provider Comparison",
        description="Compare all available providers",
        scenarios=[
            TestScenario(
                id="short_response",
                name="Short Response",
                description="Brief Q&A exchange",
                scenario_type=ScenarioType.TEXT_INPUT,
                repetitions=10,
                user_utterance_text="What is photosynthesis?",
                expected_response_type=ResponseType.SHORT,
            ),
            TestScenario(
                id="medium_response",
                name="Medium Response",
                description="Moderate explanation",
                scenario_type=ScenarioType.TEXT_INPUT,
                repetitions=5,
                user_utterance_text="Explain how the human heart works.",
                expected_response_type=ResponseType.MEDIUM,
            ),
        ],
        network_profiles=[
            NetworkProfile.LOCALHOST,
            NetworkProfile.WIFI,
            NetworkProfile.CELLULAR_US,
        ],
        parameter_space=ParameterSpace(
            stt_configs=[
                STTTestConfig(provider="deepgram"),
                STTTestConfig(provider="assemblyai"),
                STTTestConfig(provider="apple"),
            ],
            llm_configs=[
                LLMTestConfig(provider="anthropic", model="claude-3-5-haiku-20241022"),
                LLMTestConfig(provider="openai", model="gpt-4o-mini"),
                LLMTestConfig(provider="selfhosted", model="qwen2.5:7b"),
            ],
            tts_configs=[
                TTSTestConfig(provider="chatterbox"),
                TTSTestConfig(provider="vibevoice"),
                TTSTestConfig(provider="apple"),
            ],
        ),
    )
