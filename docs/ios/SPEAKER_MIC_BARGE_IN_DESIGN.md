# Speaker-Microphone Barge-In Design

This document outlines the design for robust barge-in detection when the speaker and microphone are exposed to each other (no headphones).

## The Challenge

When a user isn't wearing headphones, the AI's voice plays through the device speaker and gets picked up by the microphone. This creates two problems:

1. **False Positives**: The AI's own voice triggers VAD, causing spurious barge-in events
2. **Echo/Feedback**: User speech gets mixed with AI playback in the microphone signal

## Solution Architecture: Layered Defense

We use a **layered approach** combining multiple techniques, from most reliable to most sophisticated:

### Layer 1: Hardware AEC (Apple Voice Processing) - PRIMARY

iOS provides built-in acoustic echo cancellation via `setVoiceProcessingEnabled(true)`.

**What it provides:**
- Acoustic Echo Cancellation (AEC)
- Noise Suppression
- Automatic Gain Control (AGC)
- Uses the far-end (speaker) signal as reference to subtract from microphone

**Implementation:**
```swift
// In AudioEngine.configure()
try engine.inputNode.setVoiceProcessingEnabled(true)

// Audio session must be .playAndRecord with .voiceChat mode
try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
```

**Constraints:**
- Requires mono output (not stereo)
- Engine must be stopped when enabling
- Works best with Apple's audio session modes

**Effectiveness:** ~80-90% of speaker audio removed in typical conditions. This is our primary defense and handles most cases.

### Layer 2: Reference Signal Subtraction - RECOMMENDED

Since we control exactly what audio is being played (the TTS output), we can use it as a **known reference signal** for additional echo cancellation.

**How it works:**
1. Before playing TTS audio through speaker, store the audio samples
2. When processing microphone input, correlate with stored reference
3. Subtract the estimated echo path from microphone signal

**Implementation approach:**
```swift
class ReferenceSignalEchoCanceller {
    private var referenceBuffer: CircularBuffer<Float>
    private var adaptiveFilter: AdaptiveFilter  // NLMS or Kalman

    func setReference(_ samples: [Float]) {
        referenceBuffer.append(samples)
    }

    func process(_ micSamples: [Float]) -> [Float] {
        let estimated = adaptiveFilter.filter(referenceBuffer.last(micSamples.count))
        return micSamples.subtract(estimated)
    }
}
```

**Libraries available:**
- [WebRTC AEC3](https://github.com/nickoala/nickoala/blob/master/nicko/nicko/webrtcaec3/) - Google's state-of-the-art AEC
- [Speex AEC](https://speex.org/) - Lightweight, well-tested
- [PJSIP](https://docs.pjsip.org/en/latest/specific-guides/audio/aec.html) - Cross-platform with multiple AEC backends

**Effectiveness:** Additional 5-15% improvement over hardware AEC alone.

### Layer 3: Audio Fingerprinting / Watermarking - OPTIONAL

Embed an inaudible marker in TTS audio that can be detected in microphone input.

**How it works:**
1. Before playback, embed a unique pattern (watermark) in high-frequency or psychoacoustically masked frequencies
2. When analyzing microphone input, detect presence of watermark
3. If watermark detected, audio is AI speech → ignore for barge-in

**Advantages:**
- Works even when AEC fails (reverberant rooms, delayed echoes)
- Binary detection: watermark present = AI audio, absent = user speech
- Robust to acoustic distortion per [Amazon's research](https://www.amazon.science/blog/audio-watermarking-algorithm-is-first-to-solve-second-screen-problem-in-real-time)

**Implementation complexity:** Medium-high. Requires careful watermark design to survive acoustic channel.

**Effectiveness:** High confidence detection when watermark survives. Good for edge cases.

### Layer 4: VAD Confidence Gating

Even with perfect echo cancellation, we use VAD thresholds to filter noise.

**Current implementation:**
- General VAD threshold: 0.5
- Barge-in threshold: 0.7 (higher = fewer false positives)
- Two-stage confirmation: 600ms window

**Enhancement:** Dynamic threshold based on playback state:
```swift
var effectiveBargeInThreshold: Float {
    if isPlayingAudio {
        return 0.8  // Higher threshold during playback
    } else {
        return 0.6  // Lower threshold when silent
    }
}
```

### Layer 5: Spectral Fingerprinting - ADVANCED

Compare the spectral signature of microphone input against the known TTS output.

**How it works:**
1. Compute spectrogram of TTS audio being played
2. Compute spectrogram of microphone input
3. If spectrograms are highly correlated → it's echo, not user speech
4. Human speech has different spectral characteristics than replayed TTS

**Implementation:**
```swift
func isLikelyEcho(_ micSpectrum: [Float], _ ttsSpectrum: [Float]) -> Bool {
    let correlation = crossCorrelate(micSpectrum, ttsSpectrum)
    return correlation > 0.7  // Threshold for "same audio"
}
```

**Effectiveness:** Good for detecting obvious echo. Less effective if user speaks over AI.

---

## Recommended Implementation Order

### Phase 1: Maximize Hardware AEC (Current + Quick Wins)

1. ✅ Enable `setVoiceProcessingEnabled(true)` on AudioEngine
2. ✅ Use `.voiceChat` mode with `.playAndRecord` category
3. ⬜ Verify mono output is being used
4. ⬜ Add dynamic VAD threshold during playback

### Phase 2: Reference Signal Enhancement

1. ⬜ Store TTS audio samples in circular buffer before playback
2. ⬜ Implement simple NLMS adaptive filter
3. ⬜ Apply filter to microphone input during playback
4. ⬜ Test improvement in various acoustic environments

### Phase 3: Evaluation & Advanced Techniques

1. ⬜ Measure false positive rate with Phase 1+2
2. ⬜ If needed, implement spectral fingerprinting
3. ⬜ If still problematic, consider audio watermarking

---

## Implementation Details

### Enabling Hardware Voice Processing

The `AudioEngine` already supports voice processing. Ensure it's enabled:

```swift
// In AudioEngine.configure()
if config.enableVoiceProcessing {
    do {
        try engine.inputNode.setVoiceProcessingEnabled(true)
    } catch {
        logger.warning("Voice processing not available: \(error)")
    }
}
```

### Audio Session Configuration

Critical: Use the right combination:

```swift
// For speaker-mic barge-in support
try session.setCategory(
    .playAndRecord,
    mode: .voiceChat,  // Enables Apple's AEC
    options: [
        .defaultToSpeaker,      // Route to speaker (not earpiece)
        .allowBluetoothA2DP     // Support Bluetooth
    ]
)
```

**Warning:** Using `.default` mode or `.playback` category disables hardware AEC.

### Reference Signal Buffer

For Phase 2, implement a circular buffer for reference audio:

```swift
class TTSReferenceBuffer {
    private var buffer: [Float]
    private let maxDuration: TimeInterval = 5.0  // 5 seconds
    private let sampleRate: Double = 24000

    func append(_ samples: [Float]) {
        buffer.append(contentsOf: samples)
        // Trim to max duration
        let maxSamples = Int(maxDuration * sampleRate)
        if buffer.count > maxSamples {
            buffer.removeFirst(buffer.count - maxSamples)
        }
    }

    func getReference(length: Int, delay: Int) -> [Float] {
        // Account for acoustic delay (typically 10-50ms)
        let start = max(0, buffer.count - length - delay)
        return Array(buffer[start..<min(start + length, buffer.count)])
    }
}
```

---

## Testing Strategy

### Test Scenarios

1. **Quiet room, no headphones**: Baseline case
2. **Echo-prone room** (hard walls, reverb): Tests AEC limits
3. **User speaking softly**: Tests sensitivity
4. **User speaking loudly over AI**: Tests double-talk handling
5. **Background noise** (TV, other people): Tests noise rejection

### Metrics to Track

- **False Positive Rate**: % of AI speech incorrectly detected as user
- **True Positive Rate**: % of user speech correctly detected
- **Detection Latency**: Time from speech start to detection
- **Echo Suppression**: dB reduction of speaker in mic signal

### Automated Testing

Use audio injection through `AudioEngine.processAudioBuffer()`:

```swift
// Test: Inject TTS audio, should NOT trigger barge-in
let ttsAudio = loadTestAudio("ai_speech.wav")
for chunk in ttsAudio.chunked(size: 1024) {
    await audioEngine.processAudioBuffer(chunk)
}
XCTAssertFalse(viewModel.isTentativeBargeIn)

// Test: Inject user speech, SHOULD trigger barge-in
let userSpeech = loadTestAudio("user_question.wav")
for chunk in userSpeech.chunked(size: 1024) {
    await audioEngine.processAudioBuffer(chunk)
}
XCTAssertTrue(viewModel.isTentativeBargeIn)
```

---

## Sources

- [Apple WWDC 2023: What's new in voice processing](https://developer.apple.com/videos/play/wwdc2023/10235/)
- [Apple setVoiceProcessingEnabled documentation](https://developer.apple.com/documentation/avfaudio/avaudioionode/setvoiceprocessingenabled(_:))
- [VOCAL: AEC Barge-In](https://vocal.com/echo-cancellation/aec-barge-in/)
- [Echo suppression and cancellation - Wikipedia](https://en.wikipedia.org/wiki/Echo_suppression_and_cancellation)
- [WebRTC AEC Optimization](https://webrtc.github.io/webrtc-org/blog/2011/07/11/webrtc-improvement-optimized-aec-acoustic-echo-cancellation.html)
- [Amazon Audio Watermarking for Second-Screen Problem](https://www.amazon.science/blog/audio-watermarking-algorithm-is-first-to-solve-second-screen-problem-in-real-time)
- [PJSIP AEC Documentation](https://docs.pjsip.org/en/latest/specific-guides/audio/aec.html)
- [Speex Echo Cancellation](https://speex.org/docs/manual/speex-manual/node7.html)
- [EchoFree: Ultra Lightweight Neural AEC](https://arxiv.org/html/2508.06271v1)
- [SparkCo: Optimizing Voice Agent Barge-in Detection](https://sparkco.ai/blog/optimizing-voice-agent-barge-in-detection-for-2025)

---

## Recommendation

**For immediate implementation:** Stick with **Layer 1 (Hardware AEC)** which is already enabled, but verify the audio session configuration is optimal. The `.voiceChat` mode combined with `setVoiceProcessingEnabled(true)` provides Apple's best-in-class AEC.

**For Phase 2:** If testing reveals significant false positive issues in speaker-mic scenarios, implement the **Reference Signal Subtraction** using the simple NLMS adaptive filter approach. This is well-understood, computationally efficient, and provides meaningful improvement.

**Skip for now:** Audio watermarking and spectral fingerprinting are complex and likely overkill given the quality of Apple's built-in AEC. Only revisit if Phase 1+2 prove insufficient.
