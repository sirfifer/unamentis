# Apple Intelligence Integration Guide

This document describes UnaMentis's integration with Apple Intelligence features and Apple Silicon optimizations.

## Overview

UnaMentis leverages Apple's native AI capabilities to provide a seamless voice tutoring experience. This includes:

- **Siri & App Intents** - Voice commands for hands-free control
- **Core ML & Neural Engine** - On-device ML inference for VAD and LLM
- **Apple Speech & TTS** - Native speech recognition and synthesis
- **Spotlight Integration** - Search curricula from anywhere in iOS

## Current Implementations

### Siri Voice Commands (iOS 16+)

Users can control UnaMentis entirely hands-free with voice commands:

#### Freeform Conversation (Hands-Free)

Start a voice conversation without touching the phone:

```
"Hey Siri, talk to UnaMentis"
"Hey Siri, start a conversation with UnaMentis"
"Hey Siri, chat with UnaMentis"
"Hey Siri, I want to learn something with UnaMentis"
```

This opens the app and immediately starts a voice session, perfect for spontaneous learning while walking or doing other activities.

#### Curriculum-Based Lessons

Start a structured lesson on a specific topic:

```
"Hey Siri, start a lesson in UnaMentis"
"Hey Siri, teach me about Quantum Mechanics in UnaMentis"
"Hey Siri, study Physics with UnaMentis"
```

#### Resume & Progress

```
"Hey Siri, resume learning in UnaMentis"
"Hey Siri, continue my lesson in UnaMentis"
"Hey Siri, show my progress in UnaMentis"
```

#### Implementation Files

| File | Purpose |
|------|---------|
| `UnaMentis/Intents/AppShortcutsProvider.swift` | Registers shortcuts with Siri |
| `UnaMentis/Intents/StartConversationIntent.swift` | Handles freeform "talk to" commands |
| `UnaMentis/Intents/StartLessonIntent.swift` | Handles "start lesson" commands |
| `UnaMentis/Intents/ResumeLearningIntent.swift` | Handles "resume" commands |
| `UnaMentis/Intents/ShowProgressIntent.swift` | Handles "show progress" commands |
| `UnaMentis/Intents/CurriculumEntity.swift` | Exposes curricula to Siri |
| `UnaMentis/Intents/TopicEntity.swift` | Exposes topics to Siri |

#### Deep Link URL Scheme

The intents use deep links to navigate to specific screens:

```
unamentis://chat                              # Start freeform conversation
unamentis://chat?prompt=<encoded-question>    # Start with initial question
unamentis://lesson?id=<UUID>&depth=<level>    # Start curriculum lesson
unamentis://resume?id=<UUID>                  # Resume specific topic
unamentis://analytics                         # Show progress
```

Depth levels: `overview`, `introductory`, `intermediate`, `advanced`, `graduate`

### Apple Speech Recognition

On-device speech-to-text using `SFSpeechRecognizer`:

- **File**: `UnaMentis/Services/STT/AppleSpeechSTTService.swift`
- **Latency**: <30ms (on-device)
- **Cost**: Free (no API calls)
- **Features**: Word-level timestamps, confidence scores, streaming

### Apple Text-to-Speech

On-device speech synthesis using `AVSpeechSynthesizer`:

- **File**: `UnaMentis/Services/TTS/AppleTTSService.swift`
- **Latency**: 50-100ms TTFB
- **Cost**: Free
- **Features**: Voice selection, rate/pitch control, enhanced voices

### Core ML & Neural Engine

#### Voice Activity Detection (VAD)

Silero VAD model runs on Neural Engine:

- **File**: `UnaMentis/Services/VAD/SileroVADService.swift`
- **Compute Units**: `.cpuAndNeuralEngine`
- **Latency**: <25ms per frame
- **Model**: LSTM-based, 128x64 hidden state

#### On-Device LLM

llama.cpp with Metal GPU acceleration:

- **File**: `UnaMentis/Services/LLM/OnDeviceLLMService.swift`
- **Models**: Ministral 3B (primary), TinyLlama 1.1B (fallback)
- **GPU Layers**: 99 (fully GPU-resident)
- **Performance**: 15-30 tokens/sec depending on model

## Planned Integrations

### iOS 18+ Features

| Feature | Status | Priority |
|---------|--------|----------|
| WidgetKit Dashboard | Planned | P1 |
| Live Activities (Dynamic Island) | Planned | P2 |
| Spotlight Curriculum Indexing | Planned | P2 |

### iOS 26+ Features (Foundation Models Framework)

| Feature | Status | Priority |
|---------|--------|----------|
| @Generable for structured outputs | Research | P3 |
| Tool Calling for curriculum queries | Research | P3 |
| LoRA adapters for domain tuning | Research | P4 |

## Device Tier Architecture

UnaMentis adapts to device capabilities:

### Tier 1: Pro Max (A17 Pro+, 8GB+ RAM)
- Full 3B on-device LLM
- 48kHz audio
- All Neural Engine features

### Tier 2: Pro Standard (A16+, 6GB+ RAM)
- 1B fallback LLM
- 24kHz audio
- All Neural Engine features

### Thermal Adaptation

The app monitors thermal state and adapts:

```swift
switch ProcessInfo.processInfo.thermalState {
case .nominal: // Full capabilities
case .fair:    // Normal operation
case .serious: // Downgrade to Tier 2 behavior
case .critical: // Disable on-device LLM
}
```

## Testing

### Unit Tests

App Intents are tested in `UnaMentisTests/Unit/Intents/AppIntentsTests.swift`:

```bash
xcodebuild test -project UnaMentis.xcodeproj -scheme UnaMentis \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:UnaMentisTests/CurriculumEntityTests \
  -only-testing:UnaMentisTests/TopicEntityTests
```

### Manual Testing

1. Build and run on device
2. Say "Hey Siri, start a lesson in UnaMentis"
3. Verify app opens to lesson selection
4. Test "resume" and "progress" commands

## Profiling Neural Engine Usage

Use Xcode Instruments with the Core ML template:

1. Open Instruments
2. Select "Core ML" template
3. Profile the app during VAD operation
4. Verify operations run on Neural Engine (not CPU fallback)

## References

### Apple Documentation
- [App Intents](https://developer.apple.com/documentation/appintents)
- [Core ML](https://developer.apple.com/documentation/coreml)
- [Speech Framework](https://developer.apple.com/documentation/speech)
- [Apple Intelligence](https://developer.apple.com/apple-intelligence/)

### WWDC Sessions
- [Bring Your App to Siri (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10133/)
- [Deploy ML Models On-Device (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10161/)
- [Meet the Foundation Models Framework (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/286/)

### Project Files
- Plan: `~/.claude/plans/` (Claude Code plan files)
- Style Guide: `docs/ios/IOS_STYLE_GUIDE.md`
- TDD: `docs/architecture/UnaMentis_TDD.md`
