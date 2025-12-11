# VoiceLearn - Quick Start Guide

**Get up and running in 30 minutes**

## Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode 15.2+
- GitHub account
- API keys (optional for initial setup):
  - AssemblyAI
  - Deepgram
  - OpenAI

## Step 1: Create Xcode Project (5 minutes)

1. **Open Xcode**
2. **File → New → Project**
3. **Select iOS → App**
4. **Configure Project**:
   - Product Name: `VoiceLearn`
   - Team: Select your team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI** ✓
   - Language: **Swift** ✓
   - Storage: **Core Data** ✓ (Important!)
   - Include Tests: ✓ (Important!)
5. **Save Location**: The directory where you ran the installer
6. Click **Create**

## Step 2: Set Up Environment (10 minutes)

```bash
cd ~/Projects/VoiceLearn-iOS  # Or your project location
./scripts/setup-local-env.sh
```

This will:
- Install Homebrew (if needed)
- Install SwiftLint, SwiftFormat, xcbeautify
- Check Xcode installation
- Create .env file from template
- Install git hooks

## Step 3: Configure API Keys (5 minutes)

```bash
# Edit .env file
code .env  # Or: nano .env

# Add your API keys:
ASSEMBLYAI_API_KEY=your_key_here
DEEPGRAM_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Optional for E2E tests:
RUN_E2E_TESTS=false
```

**Don't have API keys yet?** That's fine! You can still build and run unit tests.

## Step 4: Verify Setup (5 minutes)

```bash
# Build the project
open VoiceLearn.xcodeproj
# In Xcode: ⌘ + B to build

# Or from command line:
xcodebuild -scheme VoiceLearn build

# Run quick tests
./scripts/test-quick.sh

# Run health check
./scripts/health-check.sh
```

If all green ✓ - you're ready!

## Step 5: First Commit (5 minutes)

```bash
# Check status
git status

# Stage all files
git add .

# Commit
git commit -m "feat: add Xcode project and initial configuration"

# Create GitHub repo and push
gh repo create VoiceLearn-iOS --private --source=. --push

# Create develop branch
git checkout -b develop
git push -u origin develop
git checkout main
```

## What's Next?

### Week 1: Audio Foundation

Start with the audio pipeline:

```bash
# Create feature branch
git checkout -b feature/audio-foundation

# Open in Xcode or VS Code
open VoiceLearn.xcodeproj
# Or: code .

# Follow TDD approach:
# 1. Write tests first (AudioEngineTests.swift)
# 2. Implement AudioEngine
# 3. Add VAD integration
```

### Directory Structure

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

### Important Files

- `README.md` - Project overview
- `docs/TDD.md` - Technical design
- `docs/SETUP.md` - Setup details
- `docs/TESTING.md` - Testing guide
- `.env` - API keys (never commit!)
- `.swiftlint.yml` - Linting rules
- `.swiftformat` - Formatting rules

## Success Criteria

You've completed setup when:

- ✅ Project builds without errors
- ✅ Tests run (even if just initialization)
- ✅ Health check passes
- ✅ Can commit and push to GitHub
- ✅ API keys configured (or ready to add later)

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Setup issues**: Check [SETUP.md](SETUP.md) for details

---

**You're ready to build!** 🎉

Next: Start with [Week 1 - Audio Foundation](../README.md#phase-1-foundation-weeks-1-2)
