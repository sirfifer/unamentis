# VoiceLearn - Detailed Setup Guide

## System Requirements

- **macOS**: 14.0+ (Sonoma or later)
- **Xcode**: 15.2+
- **RAM**: 16GB+ recommended
- **Disk**: 10GB+ free space
- **iOS Device**: iPhone 16/17 Pro Max (or simulator)

## Development Tools

### Required

- **Xcode 15.2+**
  ```bash
  # Install from App Store
  # Or download from developer.apple.com
  ```

- **Homebrew**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- **GitHub CLI** (optional but recommended)
  ```bash
  brew install gh
  gh auth login
  ```

### Development Dependencies

Installed automatically by `setup-local-env.sh`:

- **SwiftLint** - Code linting
- **SwiftFormat** - Code formatting
- **xcbeautify** - Readable build output

## Project Structure Setup

### 1. Directory Layout

After running the installer, you'll have:

```
VoiceLearn-iOS/
├── .git/                      # Git repository
├── .github/
│   └── workflows/
│       └── ios.yml           # CI/CD configuration
├── .vscode/
│   ├── settings.json         # VS Code settings
│   └── tasks.json            # Build tasks
├── VoiceLearn/               # Main app (after Xcode setup)
│   ├── Core/
│   │   ├── Audio/
│   │   ├── Session/
│   │   ├── Curriculum/
│   │   └── Telemetry/
│   ├── Services/
│   │   ├── STT/
│   │   ├── TTS/
│   │   ├── LLM/
│   │   ├── VAD/
│   │   └── Protocols/
│   └── UI/
├── VoiceLearnTests/          # Tests
│   ├── Unit/
│   ├── Integration/
│   ├── E2E/
│   └── Helpers/
├── scripts/                  # Development scripts
│   ├── setup-local-env.sh
│   ├── test-quick.sh
│   ├── test-all.sh
│   ├── test-e2e.sh
│   ├── lint.sh
│   ├── format.sh
│   └── health-check.sh
├── docs/                     # Documentation
│   ├── QUICKSTART.md
│   ├── SETUP.md
│   ├── TESTING.md
│   └── CONTRIBUTING.md
├── .gitignore               # Git ignore
├── .swiftlint.yml          # Linting config
├── .swiftformat            # Format config
├── .env.example            # Environment template
└── README.md               # Main README
```

### 2. Xcode Project Setup

This must be done manually because Xcode project files are binary:

1. **Open Xcode**
2. **File → New → Project**
3. **iOS → App**
4. **Configure**:
   - Product Name: `VoiceLearn`
   - Team: Your team
   - Organization ID: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data** ✓ CRITICAL!
   - Include Tests: ✓ CRITICAL!
5. **Save** to project directory
6. **Don't** check "Create Git repository" (already done)

### 3. Swift Package Dependencies

Add via Xcode:

1. **File → Add Package Dependencies**
2. Add these packages:

```
LiveKit Swift SDK
https://github.com/livekit/client-sdk-swift
```

```
Swift Log
https://github.com/apple/swift-log
```

## Configuration

### API Keys

1. Copy template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env`:
   ```bash
   code .env  # Or nano .env
   ```

3. Add your keys:
   ```
   ASSEMBLYAI_API_KEY=your_key_here
   DEEPGRAM_API_KEY=your_key_here
   OPENAI_API_KEY=your_key_here
   ANTHROPIC_API_KEY=your_key_here
   ELEVENLABS_API_KEY=your_key_here
   ```

4. **Never commit** `.env` - it's in `.gitignore`

### VS Code Configuration

Already configured in `.vscode/`:

- Format on save
- Swift language support
- Build tasks (⌘ + Shift + B)
- Test tasks

## Verification

### Build Test

```bash
# From command line
xcodebuild -scheme VoiceLearn build

# Or in Xcode
⌘ + B
```

### Run Tests

```bash
# Quick tests
./scripts/test-quick.sh

# All tests
./scripts/test-all.sh

# Health check
./scripts/health-check.sh
```

### Check Code Quality

```bash
# Lint
./scripts/lint.sh

# Format
./scripts/format.sh
```

## Troubleshooting

### Issue: Xcode project won't build

**Solution**:
```bash
# Clean build folder
xcodebuild clean

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Issue: Tests won't run

**Check**:
1. Test target is enabled in scheme
2. iOS Simulator is available
3. Xcode Command Line Tools installed:
   ```bash
   xcode-select --install
   ```

### Issue: SwiftLint errors

**Solution**:
```bash
# Reinstall SwiftLint
brew reinstall swiftlint

# Check version (should be 0.50+)
swiftlint version
```

### Issue: API keys not working

**Check**:
1. `.env` file exists in project root
2. Keys have no quotes or spaces
3. Keys are valid (test on provider websites)

### Issue: Git hooks not running

**Solution**:
```bash
# Reinstall hooks
./scripts/setup-local-env.sh

# Check hook is executable
ls -l .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Advanced Setup

### Custom Xcode Schemes

Create schemes for different configurations:

1. **Development** - Local testing, mock APIs
2. **Staging** - Real APIs, test data
3. **Production** - Production APIs, real data

### Test Fixtures

Generate test audio:
```bash
cd Tests/Fixtures
./generate-test-audio.sh
```

### Code Coverage

Enable in Xcode:
1. Edit Scheme (⌘ + <)
2. Test → Options
3. ✓ Gather coverage for all targets

View coverage:
```bash
open DerivedData/.../coverage.lcov
```

## CI/CD Setup

GitHub Actions is configured in `.github/workflows/ios.yml`.

**To enable**:
1. Push to GitHub
2. Actions run automatically on push/PR
3. View results in GitHub Actions tab

**Requirements**:
- GitHub repository
- Secrets configured (if using real API keys in CI)

## Next Steps

- Read [TESTING.md](TESTING.md) for testing strategy
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for workflow
- Start with Week 1 implementation

---

**Need help?** Open an issue on GitHub.
