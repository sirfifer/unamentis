# AI Development Guidelines for VoiceLearn

## Development Model

This project is developed with **100% AI assistance**. All code, tests, documentation, and architecture decisions are made collaboratively between human direction and AI implementation.

## Time Estimation Guidelines

### DO NOT use traditional software development timelines

Traditional estimates assume:
- Human typing speed and cognitive load
- Meeting overhead and context switching
- Learning curves and documentation reading
- Code review cycles with async feedback
- 6-8 productive hours per day

### DO use AI-assisted development timelines

AI-assisted development enables:
- Parallel exploration and implementation
- Instant context recall across entire codebase
- Continuous iteration without fatigue
- Real-time code review and correction
- 10-100x speedup on implementation tasks

### Calibration Data (This Project)

On December 11, 2025, the entire VoiceLearn iOS app (Phases 1-5 of a 12-week roadmap) was implemented in approximately 5 hours:

| Scope | Traditional Estimate | AI-Assisted Actual |
|-------|---------------------|-------------------|
| Full iOS app (Phases 1-5) | 10 weeks | ~5 hours |
| Single subsystem (Curriculum) | 2-4 weeks | ~2 hours |
| New feature with tests | 1-2 weeks | 30-60 minutes |
| Bug fix with regression test | 1-2 days | 5-15 minutes |

**Speedup Factor:** ~200x faster than traditional human team estimates

### When Providing Estimates

1. **Relative sizing is useful** - "This is 2x the complexity of the Curriculum system"
2. **Absolute timelines need context** - Always specify "AI-assisted" or "human team"
3. **The long tail matters** - Initial implementation is fast; polish/edge cases take proportionally longer
4. **Phase 6 is different** - Optimization, testing, and hardening don't parallelize as well

---

## Project Architecture

### Core Patterns
- **Swift 6.0 strict concurrency** - All services are actors
- **Protocol-first design** - Services defined by protocols, swappable implementations
- **TDD methodology** - Tests written before implementation
- **Real implementations in tests** - Only mock truly external dependencies (APIs)

### Key Directories
```
VoiceLearn/
├── Core/           # Core business logic
│   ├── Audio/      # Audio pipeline, VAD integration
│   ├── Curriculum/ # Curriculum management, progress tracking
│   └── Telemetry/  # Metrics, cost tracking, observability
├── Services/       # External service integrations (STT, TTS, LLM)
├── UI/             # SwiftUI views
└── Persistence/    # Core Data stack

VoiceLearnTests/
├── Unit/           # Unit tests (run frequently)
├── Integration/    # Integration tests
└── Helpers/        # Test utilities, mock services
```

### Build & Test Commands
```bash
# Build for simulator
xcodebuild -project VoiceLearn.xcodeproj -scheme VoiceLearn \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild test -project VoiceLearn.xcodeproj -scheme VoiceLearn \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run specific test class
xcodebuild test -project VoiceLearn.xcodeproj -scheme VoiceLearn \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:VoiceLearnTests/ProgressTrackerTests
```

---

## Working with This Codebase

### Before Implementation
1. Read relevant tests first - they document expected behavior
2. Check existing patterns in similar components
3. Reference `docs/VoiceLearn_TDD.md` for architectural decisions

### During Implementation
1. Write tests first (TDD)
2. Ensure Swift 6 concurrency compliance (@MainActor, Sendable, actors)
3. Run build frequently to catch issues early
4. Use TodoWrite to track progress on multi-step tasks

### Quality Gates
- All tests pass
- Build succeeds for iOS Simulator
- No force unwraps (!)
- Public APIs documented with /// comments
- Code follows existing patterns in the codebase

---

## Technical Specifications

### Performance Targets
- E2E turn latency: <500ms (median), <1000ms (P99)
- 90-minute session stability without crashes
- Memory growth: <50MB over 90 minutes

### Cost Targets
- Balanced preset: <$3/hour
- Cost-optimized: <$1.50/hour

See `docs/VoiceLearn_TDD.md` for complete specifications.
