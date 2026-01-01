# UnaMentis - Project Overview

## Purpose

UnaMentis is an AI-powered voice tutoring platform that enables extended (60-90+ minute) educational conversations. The project addresses limitations in existing voice AI (like ChatGPT's Advanced Voice Mode) by providing low-latency, natural voice interaction with curriculum-driven learning.

**Vision:** A personalized AI tutor that works with you over long stretches of time, understands your learning progress and style, and evolves into a true personal tutor.

**Development Model:** 100% AI-assisted development (Claude Code, Cursor, Windsurf). The entire app (Phases 1-5 of a 12-week roadmap) was implemented in approximately 5 hours, demonstrating ~200x speedup over traditional development.

---

## Monorepo Structure

```
unamentis/
├── UnaMentis/                 # iOS App (Swift 6.0/SwiftUI)
├── UnaMentisTests/            # iOS Test Suite (126+ tests)
├── server/                    # Backend Infrastructure
│   ├── management/            # Management API (Python/aiohttp, port 8766)
│   ├── web/                   # UnaMentis Server (Next.js/React, port 3000)
│   ├── database/              # Shared SQLite curriculum database
│   └── importers/             # Curriculum import framework
├── curriculum/                # UMCF specification and examples
├── docs/                      # Comprehensive documentation (40+ files)
├── scripts/                   # Build, test, lint automation
└── .github/                   # CI/CD workflows
```

### Component Summary

| Component | Location | Technology | Purpose |
|-----------|----------|------------|---------|
| iOS App | `UnaMentis/` | Swift 6.0, SwiftUI | Voice tutoring client |
| iOS Tests | `UnaMentisTests/` | XCTest | 126+ unit, 16+ integration tests |
| Management API | `server/management/` | Python, aiohttp | Backend API (port 8766) |
| UnaMentis Server | `server/web/` | Next.js 16.1, React 19 | Web interface (port 3000) |
| Importers | `server/importers/` | Python | Plugin-based curriculum import |
| Curriculum | `curriculum/` | UMCF JSON | Format specification |

---

## Architecture

### Voice Pipeline

All components are **protocol-based and swappable**:

| Component | On-Device | Cloud | Self-Hosted |
|-----------|-----------|-------|-------------|
| **STT** | Apple Speech, GLM-ASR-Nano | Deepgram Nova-3, AssemblyAI, OpenAI Whisper, Groq Whisper | GLM-ASR server |
| **TTS** | Apple TTS | ElevenLabs Turbo v2.5, Deepgram Aura-2 | Piper TTS |
| **LLM** | Ministral-3B (llama.cpp) | Anthropic Claude, OpenAI GPT-4o | Ollama, llama.cpp server, vLLM |
| **VAD** | Silero (CoreML on Neural Engine) | - | - |
| **Embeddings** | - | OpenAI text-embedding-3-small | - |

### Graceful Degradation

The app works on any device, even without API keys or servers:

| Component | Built-in Fallback | Always Available |
|-----------|-------------------|------------------|
| **STT** | Apple Speech | Yes |
| **TTS** | Apple TTS | Yes |
| **LLM** | OnDeviceLLMService | Requires bundled models |
| **VAD** | RMS-based detection | Yes |

### Session Flow

```
Microphone -> AudioEngine -> VAD -> STT (streaming)
    -> SessionManager (turn-taking, context)
    -> PatchPanel (route to LLM endpoint)
    -> LLM (streaming) -> TTS (streaming)
    -> AudioEngine -> Speaker
```

**Session States:** Idle -> User Speaking -> Processing -> AI Thinking -> AI Speaking -> (loop)

### LLM Routing (Patch Panel)

A switchboard system for routing LLM calls to any endpoint:

**Routing Priority:**
1. Global override (debugging)
2. Manual task-type override
3. Auto-routing rules (thermal, network, cost conditions)
4. Default routes per task type
5. Fallback chain

**20+ Task Types:** Tutoring, content generation, navigation, classification, and simple responses.

**Condition-Based Routing:** Device conditions (thermal, memory, battery), network conditions, cost thresholds, and time conditions.

---

## iOS App Structure

**Target:** iPhone 16/17 Pro Max | **Minimum:** iOS 18.0 | **Language:** Swift 6.0

### Core Components

```
UnaMentis/
├── Core/
│   ├── Audio/           # AudioEngine, VAD, thermal management
│   ├── Config/          # APIKeyManager (Keychain), ServerConfigManager
│   ├── Curriculum/      # CurriculumEngine, ProgressTracker, UMCFParser
│   ├── Logging/         # RemoteLogHandler
│   ├── Persistence/     # PersistenceController, 7 Core Data entities
│   ├── Routing/         # PatchPanelService, LLMEndpoint, RoutingTable
│   ├── Session/         # SessionManager (state machine, TTS config)
│   └── Telemetry/       # TelemetryEngine (latency, cost, events)
├── Services/
│   ├── LLM/             # OpenAI, Anthropic, Self-Hosted, On-Device
│   ├── STT/             # AssemblyAI, Deepgram, Apple, GLM-ASR, Router
│   ├── TTS/             # ElevenLabs, Deepgram, Apple, Self-Hosted
│   ├── VAD/             # SileroVADService (CoreML)
│   ├── Embeddings/      # OpenAIEmbeddingService
│   └── Curriculum/      # CurriculumService, VisualAssetCache
├── Intents/             # Siri & App Intents (iOS 16+)
│   ├── StartLessonIntent.swift      # "Hey Siri, start a lesson"
│   ├── ResumeLearningIntent.swift   # "Hey Siri, resume my lesson"
│   ├── ShowProgressIntent.swift     # "Hey Siri, show my progress"
│   ├── CurriculumEntity.swift       # Exposes curricula to Siri
│   └── TopicEntity.swift            # Exposes topics to Siri
└── UI/
    ├── Session/         # SessionView, VisualAssetView
    ├── Curriculum/      # CurriculumView
    ├── Settings/        # SettingsView, ServerSettingsView
    ├── History/         # HistoryView
    ├── Analytics/       # AnalyticsView
    └── Debug/           # DeviceMetricsView, DebugConversationTestView
```

### Service Counts
- **LLM Providers:** 5 (OpenAI, Anthropic, Self-Hosted, On-Device, Mock)
- **STT Providers:** 9 (AssemblyAI, Deepgram, Groq, Apple, GLM-ASR server, GLM-ASR on-device, Self-Hosted, Router, Health Monitor)
- **TTS Providers:** 5 (ElevenLabs, Deepgram, Apple, Self-Hosted, Pronunciation Processor)
- **UI Views:** 11 major views with supporting subviews
- **Swift Files:** 80+ source files, 26 test files

### Data Persistence

**Core Data entities (7 total):**
- `Curriculum` - Course containers
- `Topic` - Hierarchical learning units
- `Session` - Recorded conversations with transcripts
- `TopicProgress` - Time spent, mastery scores
- `TranscriptEntry` - Conversation history
- `Document` - Imported curriculum documents
- `VisualAsset` - Images, diagrams, equations linked to topics

---

## Server Infrastructure

### UnaMentis Server (Port 3000)

**Purpose:** Unified web interface for system and content management

**Tech Stack:** Next.js 16.1.0, React 19.2.3, TypeScript 5, Tailwind CSS 4

**Features:**
- System health monitoring (CPU, memory, thermal, battery)
- Service status dashboard (Ollama, VibeVoice, Piper, Gateway)
- Power/idle management profiles
- Performance metrics (E2E latency, STT/LLM/TTS latencies, costs)
- Logs and diagnostics with real-time filtering
- Client connection monitoring
- **Curriculum Studio** for viewing/editing UMCF content
- **Plugin Manager** for configuring content sources

### Management API (Port 8766)

**Purpose:** Backend API for curriculum and configuration data

**Tech Stack:** Python 3, aiohttp (async), SQLite

**Features:**
- Curriculum CRUD operations
- Import job orchestration with progress tracking
- Visual asset management
- AI enrichment pipeline (7 stages)
- User progress tracking and analytics
- Plugin management API

### Architecture Relationship

```
┌─────────────────────────────────────────────────────────┐
│              UnaMentis Server (Port 3000)               │
│              Next.js/React Frontend                     │
└────────────────────────┬────────────────────────────────┘
                         │ Proxy requests
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Management API (Port 8766)                 │
│              Python/aiohttp Backend                     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              SQLite Curriculum Database                 │
│              Curricula, Topics, Assets, Progress        │
└─────────────────────────────────────────────────────────┘
```

---

## Curriculum System (UMCF)

**Una Mentis Curriculum Format** - A JSON-based specification designed for conversational AI tutoring.

### Specification Status: Complete (v1.0.0)
- JSON Schema: 1,905 lines, 152 fields
- Standards alignment: IEEE LOM, LRMI, Dublin Core, SCORM, xAPI, CASE, QTI, Open Badges
- UMCF-native fields: 70 (46%) for tutoring-specific needs

### Structure

```
Curriculum
├── Metadata (title, version, language, lifecycle, rights, compliance)
├── Content[] (unlimited nesting depth)
│   ├── Node types: curriculum, unit, module, topic, subtopic, lesson, section, segment
│   ├── Learning objectives (Bloom's taxonomy aligned)
│   ├── Transcript segments with stopping points
│   ├── Alternative explanations (simpler, technical, analogy)
│   ├── Misconceptions + remediation (trigger phrases)
│   ├── Assessments (choice, multiple_choice, text_entry, true_false)
│   ├── Media (images, diagrams, equations, videos, slide decks)
│   └── Speaking notes for TTS (pace, emphasis, emotional tone)
└── Glossary (terms with spoken definitions)
```

### Content Depth Levels

| Level | Duration | Purpose |
|-------|----------|---------|
| Overview | 2-5 min | Intuition only |
| Introductory | 5-15 min | Basic concepts |
| Intermediate | 15-30 min | Moderate detail |
| Advanced | 30-60 min | In-depth with derivations |
| Graduate | 60-120 min | Comprehensive |
| Research | 90-180 min | Paper-level depth |

### Visual Asset Support
- **Embedded media types:** image, diagram, equation, chart, slideImage, slideDeck, video
- **Segment timing:** Controls when visuals appear during playback
- **Reference media:** Optional supplementary materials with keyword matching
- **Accessibility:** Required alt text, audio descriptions for all visual content
- **Equation format:** LaTeX notation with spoken description

---

## Curriculum Importers

### Plugin Architecture

The framework uses **filesystem-based plugin discovery** with explicit enable/disable control:

- **Auto-Discovery**: Plugins discovered from `plugins/` folder
- **Explicit Enablement**: Plugins must be enabled via Plugin Manager UI
- **Persistent State**: Plugin state persists in `plugins.json`
- **First-Run Wizard**: New installations prompt users to select plugins

### Implemented Importers

| Source | Status | Target Audience | Description |
|--------|--------|-----------------|-------------|
| **MIT OpenCourseWare** | Complete | Collegiate | 247 courses loaded, full catalog browser |
| **CK-12 FlexBooks** | Complete | K-12 (8th grade focus) | EPUB, PDF, HTML import |
| **EngageNY** | Complete | K-12 | New York State curriculum resources |
| **MERLOT** | Complete | Higher Ed | MERLOT digital collections |
| **Fast.ai** | Spec Complete | Collegiate AI/ML | Jupyter notebook import |
| **Stanford SEE** | Spec Complete | Engineering | PDF, transcript import |

### Import Pipeline Stages

1. **Download** - Fetch course materials
2. **Validate** - Check completeness and format
3. **Extract** - Parse into intermediate structure
4. **Enrich** - AI processing (optional)
5. **Generate** - Transform to UMCF
6. **Store** - Save to curriculum database

### AI Enrichment Pipeline (7 Stages)

1. **Content Analysis** - Readability metrics, domain detection, quality indicators
2. **Structure Inference** - Topic boundaries, hierarchical grouping
3. **Content Segmentation** - Meta-chunking based boundary detection
4. **Learning Objective Extraction** - Bloom's taxonomy alignment
5. **Assessment Generation** - Question generation with SRL + LLM
6. **Tutoring Enhancement** - Spoken text, misconceptions, glossary extraction
7. **Knowledge Graph** - Concept extraction, Wikidata linking, prerequisites

---

## Self-Hosted Server Support

UnaMentis can connect to local/LAN servers for zero-cost inference:

| Server Type | Port | Purpose |
|-------------|------|---------|
| Ollama | 11434 | LLM inference (primary target) |
| llama.cpp | 8080 | LLM inference |
| vLLM | 8000 | High-throughput LLM |
| GLM-ASR server | 11401 | STT (with WebSocket streaming) |
| Piper TTS | 11402 | TTS |

**Features:**
- Auto-discovery of available models/voices
- Health monitoring with automatic fallback
- OpenAI-compatible API support

---

## Current Status

### Complete
- All iOS services implemented (STT, TTS, LLM, VAD, Embeddings)
- Full UI (Session, Curriculum, History, Analytics, Settings, Debug)
- UMCF 1.0 specification with JSON Schema (1,905 lines)
- 126+ unit tests across 26 test files (including 23 App Intents tests)
- 16+ integration tests
- Telemetry, cost tracking, thermal management
- Self-hosted server discovery and health monitoring
- Patch Panel LLM routing system
- GLM-ASR implementation (server + on-device)
- Groq STT integration (Whisper API)
- STT Provider Router with automatic failover
- Visual asset support design
- Import architecture with 4 complete importers (MIT OCW, CK-12, EngageNY, MERLOT)
- UnaMentis Server (React/TypeScript) with Curriculum Studio
- Management API (Python/aiohttp)
- iOS Simulator MCP for AI-driven testing
- Siri & App Intents integration (voice commands, deep links)
- Graceful degradation architecture
- Plugin-based importer framework

### In Progress
- Visual asset caching optimization
- AI enrichment pipeline implementation
- Fast.ai and Stanford SEE importers

### Pending User Setup
- API key configuration (OpenAI, Anthropic, Deepgram, ElevenLabs, AssemblyAI, Groq)
- Physical device testing (iPhone 16/17 Pro Max)
- On-device GLM-ASR model download (~2.4GB)
- Long-session stability validation (90+ minutes)
- Curriculum content creation

---

## Performance Targets

| Metric | Target (Median) | Acceptable (P99) |
|--------|-----------------|------------------|
| End-to-end latency | <500ms | <1000ms |
| STT latency | <300ms | <1000ms |
| LLM time-to-first-token | <200ms | <500ms |
| TTS time-to-first-byte | <200ms | <400ms |
| Session duration | 60-90+ minutes | - |
| Memory growth | <50MB over 90 min | - |

## Cost Targets

| Preset | Target |
|--------|--------|
| Balanced | <$3/hour |
| Cost-optimized | <$1.50/hour |

---

## Tech Stack Summary

### iOS App
| Layer | Technology |
|-------|-----------|
| Language | Swift 6.0 with strict concurrency |
| UI | SwiftUI |
| Concurrency | Actors, @MainActor, async/await |
| Persistence | Core Data (SQLite) |
| Audio | AVFoundation, Audio Toolbox |
| Networking | LiveKit (WebRTC), URLSession |
| Inference | llama.cpp, CoreML |
| Testing | XCTest (real > mock philosophy) |

### UnaMentis Server
| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16.1.0 (App Router) |
| UI Library | React 19.2.3 |
| Language | TypeScript 5 |
| Styling | Tailwind CSS 4 |
| Icons | Lucide React |

### Management API
| Layer | Technology |
|-------|-----------|
| Language | Python 3 |
| Framework | aiohttp (async) |
| Database | SQLite |

### Importers
| Layer | Technology |
|-------|-----------|
| Language | Python 3 |
| Architecture | Plugin-based discovery |
| Output | UMCF JSON |

---

## Key Files

| Path | Purpose |
|------|---------|
| `UnaMentis/Core/Session/SessionManager.swift` | Orchestrates voice sessions, state machine |
| `UnaMentis/Core/Curriculum/CurriculumEngine.swift` | Curriculum context generation |
| `UnaMentis/Core/Routing/PatchPanelService.swift` | LLM endpoint routing |
| `UnaMentis/Services/STT/STTProviderRouter.swift` | STT failover routing |
| `UnaMentis/Services/LLM/SelfHostedLLMService.swift` | Ollama/llama.cpp integration |
| `UnaMentis/Services/STT/GLMASROnDeviceSTTService.swift` | On-device speech recognition |
| `curriculum/spec/umcf-schema.json` | UMCF JSON Schema (1,905 lines) |
| `curriculum/spec/UMCF_SPECIFICATION.md` | Human-readable format spec |
| `server/management/server.py` | Management API backend |
| `server/importers/plugins/sources/mit_ocw.py` | MIT OCW course handler |
| `server/web/src/components/curriculum/` | Curriculum Studio components |

---

## Documentation

### Getting Started
| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](QUICKSTART.md) | START HERE |
| [SETUP.md](SETUP.md) | Environment setup |
| [TESTING.md](TESTING.md) | Testing guide |
| [DEBUG_TESTING_UI.md](DEBUG_TESTING_UI.md) | Built-in troubleshooting |

### Architecture & Design
| Document | Purpose |
|----------|---------|
| [UnaMentis_TDD.md](UnaMentis_TDD.md) | Technical Design Document |
| [ENTERPRISE_ARCHITECTURE.md](ENTERPRISE_ARCHITECTURE.md) | System design |
| [PATCH_PANEL_ARCHITECTURE.md](PATCH_PANEL_ARCHITECTURE.md) | LLM routing |
| [FALLBACK_ARCHITECTURE.md](FALLBACK_ARCHITECTURE.md) | Graceful degradation |

### Curriculum
| Document | Purpose |
|----------|---------|
| [curriculum/README.md](../curriculum/README.md) | UMCF overview |
| [UMCF_SPECIFICATION.md](../curriculum/spec/UMCF_SPECIFICATION.md) | Format spec |
| [IMPORTER_ARCHITECTURE.md](../curriculum/importers/IMPORTER_ARCHITECTURE.md) | Import system |
| [AI_ENRICHMENT_PIPELINE.md](../curriculum/importers/AI_ENRICHMENT_PIPELINE.md) | AI processing |

### Feature Documentation
| Document | Purpose |
|----------|---------|
| [APPLE_INTELLIGENCE.md](APPLE_INTELLIGENCE.md) | Siri & App Intents |
| [GLM_ASR_ON_DEVICE_GUIDE.md](GLM_ASR_ON_DEVICE_GUIDE.md) | On-device STT |
| [AI_SIMULATOR_TESTING.md](AI_SIMULATOR_TESTING.md) | AI-driven testing |
| [VISUAL_ASSET_SUPPORT.md](VISUAL_ASSET_SUPPORT.md) | Curriculum media |

---

## Roadmap

### Phase 1-5: Core Implementation (Complete)
- Voice pipeline, UI, curriculum system, telemetry

### Phase 6: Curriculum Import System (Mostly Complete)
- MIT OCW, CK-12, EngageNY, MERLOT importers (complete)
- Curriculum Studio (complete)
- Plugin management framework (complete)
- AI enrichment pipeline (in progress)
- Fast.ai and Stanford SEE importers (spec complete)

### Phase 7: Advanced Features (Planned)
- Knowledge graph construction
- Interactive visual diagrams
- Collaborative annotations
- Cross-platform expansion

### Phase 8: Production Hardening (Pending)
- Performance optimization based on device testing
- 90-minute session stability
- TestFlight distribution

---

## Project Vision

### Open Source Core
The fundamental core of UnaMentis will always remain open source:
- Core voice pipeline and session management
- Curriculum system and progress tracking
- All provider integrations
- Cross-platform support (planned)

### Enterprise Features (Future)
A separate commercial layer may offer:
- Single sign-on (SSO) integration
- Advanced reporting and analytics
- Permission controls and user management
- Corporate curriculum publishing
- Priority support

---

## File Statistics

| Component | Language | Files | Purpose |
|-----------|----------|-------|---------|
| iOS App | Swift | 80+ | Voice tutoring client |
| iOS Tests | Swift | 26 | Unit & integration tests |
| Management API | Python | 10+ | Content administration |
| UnaMentis Server | TypeScript/React | 67 | Web interface |
| Importers | Python | 25+ | Curriculum ingestion |
| Curriculum Spec | Markdown/JSON | 19 | Format specification |
| Documentation | Markdown | 40+ | Comprehensive guides |
| **TOTAL** | Mixed | 267+ | Full system |
