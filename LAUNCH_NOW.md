# 🚀 UnaMentis - Ready to Launch!

## Current Status: ✅ Ready

All prerequisites are met. You can now run UnaMentis in the simulator.

## Launch Steps (30 seconds)

### In Xcode (already open):

1. **Select Simulator**
   - Top toolbar → Click device dropdown (center)
   - Select any iPhone (e.g., "iPhone 15 Pro", "iPhone 16")

2. **Press ⌘R**
   - Or click Play button (▶)
   - First build: 3-5 minutes
   - Subsequent builds: 30-60 seconds

3. **Wait for simulator to launch**
   - Xcode builds the app
   - Simulator opens automatically
   - App launches in simulator

### That's it! 🎉

---

## What You'll See

### 1. First Launch (Onboarding)

The app will show:
- Welcome screens
- Permission requests (tap "Allow")
- Feature overview
- "Get Started" button

Swipe through and tap "Get Started"

### 2. Main Interface

After onboarding, you'll see:
- **Home tab**: Start/resume sessions
- **Curriculum tab**: Browse learning topics
- **Analytics tab**: View session metrics
- **Settings tab**: Configure app (⚙️ icon)

### 3. Configure Mock Services

**Important**: For offline use without API keys:

1. Tap Settings (⚙️)
2. Scroll to "API Provider Configuration"
3. For each service, tap and select **"Mock"**:
   - LLM Service → Mock
   - STT Service → Mock
   - TTS Service → Mock
   - Embeddings Service → Mock

Mock services let you test all features without:
- API keys
- Internet connection
- API costs

### 4. Start Using the App

1. Go back to Home tab
2. Tap "Start Session" or "Resume Learning"
3. The app simulates a tutoring session using mock services

---

## Monitoring & Debugging

### View Logs (Real-time)

Open in browser while app runs:
```bash
open http://localhost:8765/
```

Or command line:
```bash
# View latest logs
curl -s http://localhost:8765/logs | python3 -m json.tool | tail -30

# Clear logs before testing
curl -X POST http://localhost:8765/clear
```

### Check App State

In Xcode:
- Bottom panel shows build output
- Debug console shows runtime logs
- Errors appear in red

---

## Quick Troubleshooting

### Build Fails?

**"Signing certificate"**
- Select UnaMentis target (left sidebar)
- Signing & Capabilities tab
- Change Team to your Apple ID

**"No simulators"**
- Xcode > Settings > Platforms
- Download iOS 18 Simulator

**Other errors**
- Clean: Shift + ⌘K
- Rebuild: ⌘R

### App Crashes?

1. Check logs: http://localhost:8765/
2. Look for error messages
3. Common issues:
   - Log server not running (should be running ✓)
   - Permissions denied (tap "Allow" in simulator)
   - Service not configured (select "Mock" in settings)

---

## System Status

✅ **Log Server**: Running at http://localhost:8765/
✅ **Xcode**: Open with UnaMentis project
✅ **Package.swift**: Fixed and ready
✅ **Git**: On branch Cy-Setup
✅ **Environment**: Ready to build

---

## Next Steps After Launch

### Test Features

- **Voice Sessions**: Start a tutoring session
- **Curriculum**: Browse and select topics
- **Analytics**: View session metrics
- **Settings**: Explore configuration options
- **Debug Menu**: Access developer tools

### Switch to Real Services (Optional)

When you have API keys:

1. Settings → API Provider Configuration
2. Select a provider (OpenAI, Anthropic, etc.)
3. Enter API key
4. Service becomes live

### Development Workflow

1. Make code changes
2. Build & run (⌘R)
3. Test in simulator
4. Check logs
5. Iterate

---

## Resources

- **Full Guide**: [QUICKSTART.md](QUICKSTART.md)
- **Step-by-Step**: [QUICKSTART_STEPS.md](QUICKSTART_STEPS.md)
- **Dev Setup**: `docs/DEV_ENVIRONMENT.md`
- **Architecture**: `docs/UnaMentis_TDD.md`
- **Logs**: http://localhost:8765/

---

## Ready to Launch?

**In Xcode now:**

1. ✅ Select an iPhone simulator (top toolbar)
2. ✅ Press ⌘R (Command + R)
3. ✅ Wait 3-5 minutes for first build
4. ✅ App launches in simulator automatically

**That's it!** 🎓

The app will launch with mock services enabled by default. No configuration needed to start testing!

---

**Questions?** Check the logs at http://localhost:8765/ or see [QUICKSTART.md](QUICKSTART.md) for detailed help.
