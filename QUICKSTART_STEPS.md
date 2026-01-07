# UnaMentis - Quick Launch Steps

## ✅ Completed Setup

1. ✓ Log server is running at http://localhost:8765/
2. ✓ Xcode project opened
3. ✓ Fixed Package.swift issues

## 🚀 Next: Launch in Simulator

### In Xcode (now open):

1. **Select Simulator** (Top toolbar, near center)
   - Click the device dropdown
   - Choose any "iPhone" device (e.g., iPhone 15 Pro, iPhone 16 Pro)
   - If no simulators appear, go to: Xcode > Settings > Platforms > Download iOS 18

2. **Build and Run**
   - Press **⌘R** (Command + R)
   - Or click the Play button (▶) in the toolbar
   - First build takes 3-5 minutes
   - Xcode will download dependencies automatically

3. **Wait for Build**
   - Watch the progress bar at the top
   - Build output appears in the bottom panel
   - Errors (if any) will show in red

### Expected Behavior

The simulator will launch automatically and UnaMentis will open. You'll see:

1. **Splash screen** with UnaMentis logo
2. **Onboarding flow** (first launch only)
3. **Main interface** after onboarding

## 🔧 Configure Mock Services (No API Keys)

### After app launches:

1. **Complete Onboarding**
   - Swipe through welcome screens
   - Tap "Get Started" or "Continue"

2. **Go to Settings**
   - Tap the gear icon ⚙️ (top right)
   - Or navigate to Settings tab

3. **Configure API Providers**
   - Scroll to "API Provider Configuration"
   - For each service, tap and select **"Mock"**:
     - **LLM Service** → Mock
     - **STT Service** → Mock
     - **TTS Service** → Mock
     - **Embeddings Service** → Mock

4. **Start Using the App**
   - Go back to home screen
   - Tap "Start Session" or "Resume Learning"
   - Mock services work offline, no API keys needed

## 🐛 Troubleshooting

### Build Errors?

**"Developer Tools Access"**
- Xcode may prompt for permission
- Click "Always Allow" or enter password

**"Signing Certificate"**
- Select UnaMentis target (left sidebar)
- Go to "Signing & Capabilities" tab
- Change Team to your Apple ID
- Or set "Signing" to "Sign to Run Locally"

**"No Simulators Available"**
- Xcode > Settings (⌘,)
- Go to "Platforms" tab
- Download "iOS 18.x Simulator"

### App Crashes on Launch?

1. **Check logs:**
   ```bash
   curl -s http://localhost:8765/logs | python3 -m json.tool | tail -50
   ```

2. **Or open in browser:**
   - Visit http://localhost:8765/
   - Look for errors in red

3. **Clear logs and retry:**
   ```bash
   curl -X POST http://localhost:8765/clear
   ```
   - Then rebuild and run (⌘R)

### Xcode Not Responding?

- Force quit: ⌘Q
- Reopen: `open UnaMentis.xcodeproj`
- Clean build folder: Shift + ⌘K
- Try again: ⌘R

## 📊 Monitoring

While the app runs, monitor logs:

```bash
# In a new terminal:
curl -s http://localhost:8765/logs | python3 -m json.tool | tail -20

# Or watch in real-time (browser):
open http://localhost:8765/
```

## 🎯 Testing the App

### Try These Features (Mock Mode):

1. **Start a Session**
   - Tap "Start Session"
   - Mock services will simulate AI tutor

2. **Browse Curriculum**
   - Navigate to Curriculum tab
   - Explore learning topics

3. **View Analytics**
   - Check session metrics
   - See usage statistics

4. **Test Settings**
   - Toggle different providers
   - Adjust preferences

All features work in mock mode without internet!

## ✅ Success Indicators

You'll know it's working when:

- ✓ App launches without crashes
- ✓ Onboarding completes smoothly
- ✓ Settings show "Mock" providers
- ✓ You can start a session
- ✓ No errors in logs (http://localhost:8765/)

## 📚 What's Next?

See [QUICKSTART.md](QUICKSTART.md) for:
- Full feature overview
- Development workflow
- Testing guide
- Advanced configuration

## 🆘 Need Help?

1. Check http://localhost:8765/ for logs
2. Review `docs/DEV_ENVIRONMENT.md`
3. See build output in Xcode (bottom panel)
4. Clear build: Shift + ⌘K, then rebuild

---

**Current Status:**
- ✅ Log server: Running (http://localhost:8765/)
- ✅ Xcode: Open with UnaMentis project
- ⏳ Next: Press ⌘R to build and run!
