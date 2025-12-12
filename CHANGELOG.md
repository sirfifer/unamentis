# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- TTS streaming playback via AVAudioPlayerNode in AudioEngine
- Integration test suite (16+ tests) in VoiceSessionIntegrationTests.swift
- Debug & Testing UI (DiagnosticsView, AudioTestView, ProviderTestView)
- DEBUG_TESTING_UI.md documentation for troubleshooting tools
- TestDataFactory helpers for creating test Core Data entities

### Changed
- Updated TESTING.md with integration test documentation
- Updated AGENTS.md with MockVADService (test spy) documentation
- Updated README.md with current implementation status
- All Part 1 autonomous tasks now complete

### Fixed
- SessionManagerTests MainActor isolation errors
- TelemetryEngine switch case for ttsTimeToFirstByte latency type

## [0.1.0] - 2025-12-11

### Added
- Initial release
- Complete iOS app implementation (Phases 1-5)
- Support for AssemblyAI, Deepgram (STT)
- Support for ElevenLabs, Deepgram Aura (TTS)
- Support for OpenAI, Anthropic (LLM)
- Silero VAD integration
- Core Data persistence
- Comprehensive test suite
