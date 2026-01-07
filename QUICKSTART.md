# UnaMentis Quickstart Guide

Get UnaMentis running in the iOS Simulator in under 5 minutes, no API keys required.

## Prerequisites

- macOS 14.5+ (Sonoma or later)
- Xcode 16+ installed from the Mac App Store
- 8GB+ RAM
- iOS 18 Simulator runtime installed

## Step 1: Start the Log Server

The log server **MUST** be running before launching the app.

```bash
# Start the log server (keep this terminal open)
python3 scripts/log_server.py
```

Verify it's running:
```bash
curl http://localhost:8765/health  # Should return "OK"
```

Access logs in your browser: [http://localhost:8765/](http://localhost:8765/)

## Step 2: Open the Project in Xcode

```bash
open UnaMentis.xcodeproj
```

Or from Xcode: File > Open > Select `UnaMentis.xcodeproj`

## Step 3: Select Simulator and Build

1. In Xcode's toolbar, click the device selector (top center)
2. Choose any iPhone simulator (e.g., "iPhone 17 Pro")
3. Press **⌘R** (Command + R) to build and run

The app will build (first time takes 3-5 minutes) and launch in the simulator.

## Step 4: Use Mock Services (No API Keys Required)

UnaMentis works without API keys using mock services:

### First Launch Configuration

1. When the app launches, you'll see the **Onboarding** screen
2. Tap through the welcome slides
3. You'll reach the **Settings** screen

### Enable Mock Mode

4. In Settings, scroll to **"API Provider Configuration"**
5. For each service (LLM, STT, TTS, Embeddings):
   - Tap the service
   - Select **"Mock"** as the provider
   - Mock services require no API keys and work offline

### Alternative: Use Real Services (Optional)

If you have API keys, you can configure:

- **LLM**: OpenAI, Anthropic, or Gemini
- **STT**: Deepgram, OpenAI Whisper, or Self-hosted
- **TTS**: ElevenLabs, OpenAI, Chatterbox, or Edge TTS
- **Embeddings**: OpenAI

Add your API keys in the respective service configuration screens.

## Step 5: Start a Session

1. Return to the main screen (tap back or home)
2. Tap **"Start Session"** or **"Resume Learning"**
3. The app will use mock services to simulate:
   - Voice transcription (STT)
   - AI tutor responses (LLM)
   - Text-to-speech (TTS)
   - No internet connection required in mock mode

## Testing the App

### Quick Health Check

```bash
./scripts/health-check.sh
```

This runs linting and quick tests to verify the codebase.

### Run Full Test Suite

```bash
./scripts/test-all.sh
```

### Run Tests in Xcode

1. Press **⌘U** (Command + U) to run all tests
2. Or use Test Navigator (⌘6) to run specific tests

## Troubleshooting

### Build Fails

**Error:** "Missing developer tools"
```bash
xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app
```

**Error:** "Signing certificate not found"
- In Xcode, select the UnaMentis target
- Go to Signing & Capabilities
- Change Team to your Apple ID or "None"

### App Crashes on Launch

1. **Check log server is running:**
   ```bash
   curl http://localhost:8765/health
   ```
   If not, restart it: `python3 scripts/log_server.py &`

2. **View logs:**
   - Open [http://localhost:8765/](http://localhost:8765/) in your browser
   - Or: `curl -s http://localhost:8765/logs | python3 -m json.tool`

3. **Clear logs and reproduce:**
   ```bash
   curl -X POST http://localhost:8765/clear
   # Then launch app again and check logs
   ```

### Simulator Issues

**Simulator not showing:**
- Xcode > Window > Devices and Simulators
- Add a new iOS 18 simulator if needed

**Simulator is slow:**
- Close other apps
- Increase RAM allocation to the simulator
- Use a newer simulator device (iPhone 15+)

### Mock Services Not Working

Mock services are enabled by default and require no configuration. If you're seeing errors:

1. Check that you selected "Mock" provider for each service
2. Restart the app
3. Check logs at http://localhost:8765/

## Understanding Mock Mode

Mock services simulate real AI services for development and testing:

- **Mock LLM**: Returns predefined tutor responses, no API calls
- **Mock STT**: Echoes back dummy transcriptions
- **Mock TTS**: Simulates speech generation without audio synthesis
- **Mock Embeddings**: Returns random vectors for semantic search

This allows full app testing without:
- API costs
- Internet connection
- API key management
- Rate limits

## Next Steps

### Explore the App

- **Curriculum**: Browse learning topics
- **Sessions**: Start voice-based learning
- **Analytics**: View session metrics
- **Settings**: Configure services and preferences
- **Debug**: Access developer tools (Debug menu)

### Development Workflow

1. **Make changes** in Xcode or VS Code
2. **Build and test** (⌘R for run, ⌘U for tests)
3. **Check logs** at http://localhost:8765/
4. **Run health check** before committing:
   ```bash
   ./scripts/health-check.sh
   ```

### Learn More

- **Architecture**: See `docs/UnaMentis_TDD.md`
- **Development Environment**: See `docs/DEV_ENVIRONMENT.md`
- **iOS Style Guide**: See `docs/IOS_STYLE_GUIDE.md`
- **Testing Philosophy**: See `AGENTS.md`
- **Contributing**: See `docs/CONTRIBUTING.md`

## Quick Commands Reference

```bash
# Health check (lint + quick tests)
./scripts/health-check.sh

# Run all tests
./scripts/test-all.sh

# Format code
./scripts/format.sh

# Lint code
./scripts/lint.sh

# Start log server
python3 scripts/log_server.py &

# Check log server
curl http://localhost:8765/health

# View logs (JSON)
curl -s http://localhost:8765/logs | python3 -m json.tool

# Clear logs
curl -X POST http://localhost:8765/clear

# View logs (browser)
open http://localhost:8765/
```

## Getting Help

- Check logs at http://localhost:8765/
- See `docs/` directory for detailed documentation
- Check `CLAUDE.md` for AI development guidelines
- Review test files for usage examples

---

**Happy Learning! 🎓**
