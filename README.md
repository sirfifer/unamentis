# VoiceLearn iOS

**Real-time bidirectional voice AI platform for extended educational conversations**

## Overview

VoiceLearn is an iOS application that enables 60-90+ minute voice-based learning sessions with AI tutoring. Built for iPhone 16/17 Pro Max with emphasis on:

- Sub-500ms end-to-end latency
- Natural interruption handling
- Curriculum-driven learning with progress tracking
- Comprehensive observability and cost tracking
- Modular architecture with swappable providers

## Quick Start

```bash
# 1. Create Xcode project (manual - see docs/QUICKSTART.md)

# 2. Set up environment
./scripts/setup-local-env.sh

# 3. Configure API keys
cp .env.example .env
# Edit .env and add your keys

# 4. Run tests
./scripts/test-quick.sh
```

See [Quick Start Guide](docs/QUICKSTART.md) for complete setup.

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md) - START HERE
- [Setup Guide](docs/SETUP.md)
- [Testing Guide](docs/TESTING.md)
- [Contributing](docs/CONTRIBUTING.md)

## Development

```bash
# Quick tests
./scripts/test-quick.sh

# All tests
./scripts/test-all.sh

# Format code
./scripts/format.sh

# Lint code
./scripts/lint.sh

# Health check
./scripts/health-check.sh
```

## Architecture

```
VoiceLearn/
├── Core/           # Core business logic
│   ├── Audio/      # Audio engine, VAD
│   ├── Session/    # Session management
│   ├── Curriculum/ # Learning materials
│   └── Telemetry/  # Metrics
├── Services/       # Provider integrations
│   ├── STT/        # Speech-to-text
│   ├── TTS/        # Text-to-speech
│   └── LLM/        # Language models
└── UI/             # SwiftUI views
```

## Technology Stack

- **Language**: Swift 6.0
- **UI**: SwiftUI
- **Audio**: AVFoundation
- **Transport**: LiveKit WebRTC
- **ML**: Core ML (Silero VAD)
- **Persistence**: Core Data
- **Testing**: XCTest (NO MOCKS!)

## License

[Your License]
