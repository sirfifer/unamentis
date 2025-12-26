# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UnaMentis is an iOS voice AI tutoring app built with Swift 6.0/SwiftUI. It enables 60-90+ minute voice-based learning sessions with sub-500ms latency. The project is developed with 100% AI assistance.

## Monorepo Structure

This repository contains multiple components, each with its own CLAUDE.md:

| Component | Location | Purpose |
|-----------|----------|---------|
| iOS App | `UnaMentis/` | Swift/SwiftUI voice tutoring client |
| Server | `server/` | Backend infrastructure |
| Management Console | `server/management/` | Python/aiohttp content admin (port 8766) |
| Operations Console | `server/web/` | Next.js/React DevOps monitoring (port 3000) |
| Importers | `server/importers/` | Curriculum import framework |
| Curriculum | `curriculum/` | UMLCF format specification |

See the CLAUDE.md in each directory for component-specific instructions.

## Quick Commands

```bash
# iOS build
xcodebuild -project UnaMentis.xcodeproj -scheme UnaMentis \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Quick tests
./scripts/test-quick.sh

# All tests
./scripts/test-all.sh

# Lint and format
./scripts/lint.sh
./scripts/format.sh

# Health check (lint + quick tests)
./scripts/health-check.sh
```

## Key Technical Requirements

**Testing Philosophy (Real Over Mock):**
- Only mock paid external APIs (LLM, STT, TTS, Embeddings)
- Use real implementations for all internal services
- See `AGENTS.md` for detailed testing philosophy

**Performance Targets:**
- E2E turn latency: <500ms (median), <1000ms (P99)
- Memory growth: <50MB over 90 minutes
- Session stability: 90+ minutes without crashes

## Multi-Agent Coordination

Check `docs/TASK_STATUS.md` before starting work. Claim tasks before working to prevent conflicts with other AI agents.

## Commit Convention

Follow Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `perf:`, `ci:`, `chore:`

Before committing: `./scripts/lint.sh && ./scripts/test-quick.sh`

## Key Documentation

- `docs/IOS_STYLE_GUIDE.md` - Mandatory iOS coding standards
- `docs/UnaMentis_TDD.md` - Technical design document
- `docs/TASK_STATUS.md` - Current task status
- `AGENTS.md` - AI development guidelines and testing philosophy
- `curriculum/README.md` - UMLCF curriculum format
