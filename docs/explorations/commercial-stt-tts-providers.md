# Commercial STT and TTS Providers: Multilingual Research

> Research Date: January 2026
> Purpose: Comparison and fallback planning for multilingual voice AI

## Executive Summary

This document provides comprehensive research on commercial Speech-to-Text (STT) and Text-to-Speech (TTS) providers with multilingual support. These are evaluated as potential fallbacks or alternatives to open-source solutions for the UnaMentis voice tutoring application.

---

## Speech-to-Text (STT) Providers

### 1. OpenAI Whisper API

**Supported Languages:** ~99 languages including Afrikaans, Arabic, Armenian, Azerbaijani, Belarusian, Bosnian, Bulgarian, Catalan, Chinese, Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, Galician, German, Greek, Hebrew, Hindi, Hungarian, Icelandic, Indonesian, Italian, Japanese, Kannada, Kazakh, Korean, Latvian, Lithuanian, Macedonian, Malay, Marathi, Maori, Nepali, Norwegian, Persian, Polish, Portuguese, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tagalog, Tamil, Thai, Turkish, Ukrainian, Urdu, Vietnamese, and Welsh.

**Quality Assessment:**
- Excellent for major languages (English, German, Spanish, French)
- 10-20% error reduction in large-v3 compared to large-v2
- Less common languages (Icelandic, Welsh, Swahili) have reduced accuracy due to limited training data

**Pricing:**
- $0.006 per minute (batch/async)
- Maximum file size: 25MB
- Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, webm

**Latency:**
- Batch processing only (no real-time streaming via API)
- Latency varies based on usage tier; can be 2x+ higher when exceeding tier limits

**Streaming Support:** No native streaming; file-based processing only

**Rate Limits:**
- Default: 50 RPM (requests per minute)
- Azure OpenAI: Default 3 RPM (can be increased for paid subscriptions)
- File size limit: 25MB per request

---

### 2. Google Cloud Speech-to-Text

**Supported Languages:** 125+ languages and variants (73 core languages with 120+ regional variants)

**Quality Assessment:**
- Strong across major world languages
- Chirp model (V2 only) offers improved accuracy
- Medical models available for specialized use cases

**Pricing:**
| Feature | Price |
|---------|-------|
| Standard (real-time) | $0.016/min |
| Dynamic Batch | $0.004/min |
| Volume discounts | As low as $0.004/min |
| Free tier | 60 minutes/month + $300 credits for new customers |

**Latency:**
- Real-time streaming available via gRPC
- Streaming designed for live audio capture

**Streaming Support:** Yes, via gRPC bi-directional streaming

**Rate Limits:**
- 300 concurrent streaming sessions per 5 minutes
- 3,000 requests per minute (shared across all sessions)
- 10MB limit per streaming request
- Quotas adjustable via Google Cloud Console

---

### 3. Amazon Transcribe

**Supported Languages:** 100+ languages and dialects; 54 languages for streaming

**Streaming Languages (recent additions):** Afrikaans, Amharic, Arabic (Gulf/Standard), Basque, Catalan, Croatian, Czech, Danish, Dutch, Farsi, Finnish, Galician, Greek, Hebrew, Indonesian, Latvian, Malay, Norwegian, Polish, Romanian, Russian, Serbian, Slovak, Somali, Swedish, Tagalog, Ukrainian, Vietnamese, Zulu

**Quality Assessment:**
- Strong for contact center and call transcription
- Custom vocabulary support for domain-specific terms
- Medical transcription model available (HIPAA-eligible)

**Pricing:**
| Tier | Minutes/Month | Price/Minute |
|------|---------------|--------------|
| Tier 1 | 0-250,000 | $0.024 |
| Tier 2 | 250,001-1M | $0.015 |
| Tier 3 | 1M+ | $0.0102 |
| Medical | Any | $0.075 |
| Free tier | 60 min/month (12 months) | Free |

**Latency:**
- Real-time streaming available
- Batch and streaming have identical pricing

**Streaming Support:** Yes, available in 16 AWS regions

**Rate Limits:**
- Billed in 1-second increments
- Minimum charge: 15 seconds per request

---

### 4. Azure Speech Services (STT)

**Supported Languages:** 100+ languages for STT

**Quality Assessment:**
- Good accuracy across 140+ supported language variants
- Custom Speech models available for domain adaptation
- Container deployment available for on-premises

**Pricing:**
| Type | Price |
|------|-------|
| Real-time | $0.0167/min ($1/hour) |
| Batch | $0.006/min |
| Free tier | 5 hours/month |

**Latency:**
- 400-800ms typical latency
- Higher than specialized providers like Deepgram

**Streaming Support:** Yes, real-time streaming available

**Rate Limits:**
- Adjustable for Standard (S0) tier
- Free (F0) tier limits not adjustable
- HTTP 429 errors often caused by backend capacity, not quota
- Quota increases available via Azure Support

---

### 5. Deepgram

**Supported Languages:** 36+ languages with Nova-2; 31 languages with Nova-3

**Languages include:** Spanish, French, German, Portuguese, Italian, Dutch, Hindi, Japanese, Korean, Chinese, and more

**Quality Assessment:**
- Nova-3: 54.2% WER reduction vs competitors
- 36% lower WER than OpenAI Whisper on select datasets
- Excellent for real-time applications

**Pricing:**
| Model | Price |
|-------|-------|
| Nova-3 | $4.30/1000 minutes ($0.0043/min) |
| Batch | ~$0.0043/min |
| Real-time | ~$0.0077/min |
| Billing | Per-second (no rounding) |

**Latency:**
- Sub-300ms for real-time streaming
- Industry-leading speed for streaming transcription

**Streaming Support:** Yes, WebSocket-based streaming

**Rate Limits:**
| Plan | Streaming Concurrent | Pre-recorded Concurrent |
|------|---------------------|------------------------|
| Pay As You Go | 50 | 100 |
| Growth | 50 | 100 |
| Enterprise | 100+ (starting) | 100+ |
| TTS (combined REST/WSS) | 15 | 15 |

- Enterprise can scale to 500+ concurrent streams
- Limits based on concurrent requests, not requests per time period

---

### 6. AssemblyAI

**Supported Languages:** 99 languages for batch; 6 languages for streaming (English, Spanish, French, German, Italian, Portuguese)

**Quality Assessment:**
- Strong accuracy for supported languages
- Advanced features (sentiment analysis, entity detection) English-only
- Speaker diarization available for 95 languages

**Pricing:**
| Feature | Price |
|---------|-------|
| Universal STT | $0.15/hour ($0.0025/min) |
| Streaming (6 languages) | $0.15/hour |
| Free tier | $50 in credits |

**Add-on costs:**
- Speaker identification: +$0.02/hour
- Sentiment analysis: +$0.02/hour
- PII redaction: +$0.08/hour
- Summarization: +$0.03/hour

**Latency:**
- ~300ms P50 for streaming
- Fast endpoint detection for turn-taking

**Streaming Support:** Yes, WebSocket-based; unlimited concurrent streams for paid accounts

**Rate Limits:**
- 20,000 requests per 5 minutes (rate limit)
- Async concurrency: 200 default
- Streaming: Automatic scaling from baseline
  - Scales up 10% every 60 seconds at 70%+ usage
  - Can reach 610+ concurrent streams within 5 minutes

---

### 7. Rev.ai

**Supported Languages:** 36-58+ languages (reports vary)

**Languages include:** Spanish, French, Chinese, Portuguese, German, Russian, Japanese, Korean, Arabic, Turkish, and more

**Quality Assessment:**
- Hybrid approach: AI + human reviewers available
- Trained on 50,000+ hours of human-transcribed audio
- Good for high-accuracy requirements

**Pricing:**
| Product | Price |
|---------|-------|
| Reverb ASR | $0.003-0.005/min |
| Whisper models | $0.005/min |
| Human transcription | $1.99/min |
| Enterprise AI | $0.02/min (volume discounts available) |

**Add-ons:**
- Language identification: $0.003/min
- Sentiment analysis: $0.001/min

**Latency:**
- 1-3ms average for real-time applications
- Extremely low latency

**Streaming Support:** Yes, real-time streaming available

**Rate Limits:**
- Not explicitly documented in public sources
- SDKs available for Python, Java, Node.js

---

## Text-to-Speech (TTS) Providers

### 1. ElevenLabs

**Supported Languages:** 29-70+ languages depending on model
- Multilingual v2: 29 languages
- Flash v2.5: 32 languages
- Expressive model: 70+ languages

**Languages include:** English (USA, UK, Australia, Canada), Japanese, Chinese, German, Hindi, French (France, Canada), Korean, Portuguese (Brazil, Portugal), Italian, Spanish (Spain, Mexico), Indonesian

**Quality Assessment:**
- Industry-leading naturalness and expressiveness
- Excellent for storytelling, gaming, media production
- Strong emotional control via audio tags

**Pricing:**
| Plan | Credits/Month | Price |
|------|---------------|-------|
| Free | 10,000 | $0 |
| Starter | 30,000 | $5/month |
| Creator | 100,000 | $11/month |
| Pro | 500,000 | $99/month |
| Scale | Millions | $330/month |
| Business | Millions | $1,320/month |

**Overage pricing:**
- Creator: $0.30/1000 chars
- Pro: $0.24/1000 chars
- Scale: $0.18/1000 chars
- Business: $0.12/1000 chars

**Latency:**
- Flash v2.5: 75ms ultra-low latency
- Multilingual v2: Higher quality, higher latency

**Streaming Support:** Yes, real-time streaming available

**Rate Limits (Concurrent Requests):**
| Plan | Concurrency |
|------|-------------|
| Free | 2 |
| Starter | 3 |
| Creator | 5 |
| Pro | 10 |
| Scale | 15 |
| Business | 15 |

- WebSocket connections only count during active generation
- Concurrency of 5 can support ~100 simultaneous conversations
- Burst pricing available (3x limit at 2x cost)

---

### 2. OpenAI TTS

**Supported Languages:** Same as Whisper (~99 languages)

**Languages include:** English, Spanish, French, German, Italian, Portuguese, Dutch, Polish, Russian, Japanese, Chinese, and more

**Quality Assessment:**
- Good quality across languages
- "Steerability" feature allows prompting voice style/emotion
- 6-9 distinct voices available

**Pricing:**
| Model | Price |
|-------|-------|
| TTS Standard | $15/1M characters |
| TTS HD | $30/1M characters |
| gpt-4o-mini-tts | $0.60/1M chars input, $12/1M audio tokens output (~$0.015/min) |

**Latency:**
- ~0.5s for standard models
- Streaming support for real-time playback

**Streaming Support:** Yes, chunk transfer encoding

**Rate Limits:**
- 4,096 characters per request maximum
- Rate limits vary by subscription tier
- Output formats: MP3, Opus, AAC, FLAC, WAV, PCM

---

### 3. Google Cloud Text-to-Speech

**Supported Languages:** 75+ languages with 380+ voices
- WaveNet and Neural2 models
- Chirp 3: HD voices in 30 styles
- Gemini TTS: 80+ locales, 30 speakers

**Quality Assessment:**
- WaveNet: Human-like emphasis and inflection
- Neural2: Custom Voice technology accessible to all
- Chirp 3 HD: Natural intonation for real-time use
- Gemini TTS: Granular control over style, accent, pace, tone

**Pricing:**
| Voice Type | Price per 1M chars |
|------------|-------------------|
| Standard | $4 |
| WaveNet/Neural | $16 |
| HD/Generative | $12.69 (estimated) |
| Free tier | 4M chars (standard), 1M chars (WaveNet) |

**Latency:**
- Chirp 3: HD supports low-latency real-time communication
- Text streaming supported

**Streaming Support:** Yes, real-time streaming available

**Rate Limits:**
- Quotas based on characters per month
- Adjustable via Google Cloud Console
- $300 credits for new customers

---

### 4. Amazon Polly

**Supported Languages:** 40+ languages with 100+ voices
- Standard: 29 languages, 60 voices
- Neural: 36 languages
- Generative: Latest, most natural voices

**Quality Assessment:**
- Standard: Concatenative synthesis, good quality
- Neural: Higher quality than standard
- Generative: Most natural, emotionally engaged speech
- Long-form voices available for extended content

**Pricing:**
| Voice Type | Price per 1M chars |
|------------|-------------------|
| Standard | $4.80 |
| Neural | $19.20 |

**Free Tier:**
- Standard: 5M chars/month (indefinite)
- Neural: 1M chars/month (12 months)
- Long-form: 500K chars/month (12 months)
- Generative: 100K chars/month (12 months)

**Latency:**
- Real-time synthesis available
- Supports 8kHz, 16kHz, 22kHz, 24kHz sampling rates

**Streaming Support:** Yes, audio streaming available

**Rate Limits:**
| Voice Type | TPS | Concurrent Requests |
|------------|-----|---------------------|
| Standard | 80 | 80 |
| Neural | 8 (burst: 10) | 18 |
| Generative | N/A | 26 |
| Long-form | N/A | 26 |

- 3,000 billed chars (6,000 total) per SynthesizeSpeech request
- 100,000 billed chars for async (StartSpeechSynthesisTask)

---

### 5. Azure Speech Services (TTS)

**Supported Languages:** 140+ languages with 500+ voices
- Neural HD models with 600+ voices in 150+ locales
- Custom Neural Voice available

**Quality Assessment:**
- Neural voices with lifelike intonation
- 30+ highly natural conversational voices
- Container deployment for on-premises/offline use
- Personal Voice feature (limited access)

**Pricing:**
| Feature | Price |
|---------|-------|
| Neural TTS | $16/1M characters |
| Custom Neural Voice Training | $400/training hour |
| Free tier | Limited (less generous than competitors) |

**Latency:**
- Real-time streaming available
- Rate scaling automatic based on demand

**Streaming Support:** Yes, real-time synthesis

**Rate Limits:**
- Default: 200 TPS for Standard Voice
- Adjustable with business justification (no extra charge)
- HTTP 429 errors often from backend capacity, not quota
- Quota increases via Azure Support

---

### 6. Play.ht (PlayAI)

**Supported Languages:** Claims 140+ languages, but quality varies
- High quality: English (US, UK, Australian), Spanish, French, German, Portuguese
- Lower quality: Arabic, Hindi, most African/Eastern European languages
- 800+ voices across 142 languages (claimed)

**Quality Assessment:**
- ~20 languages with genuinely usable quality
- Good SSML support (rate, pitch, volume, pronunciations)
- Cross-language voice cloning available

**Pricing:**
| Plan | Price |
|------|-------|
| Free | $0 (non-commercial only) |
| Unlimited | $39-198/month |
| Fair usage limit | 2.5M chars/month, 30M chars/year |

**Latency:**
- Ultra-low latency for live applications
- Real-time voice synthesis

**Streaming Support:** Yes, real-time API available

**Rate Limits:**
- Not explicitly documented
- 20% discount for students, educators, non-profits

---

### 7. Murf.ai

**Supported Languages:** 35 languages with 150+ voices

**Languages include:** English, German, Spanish, French, Mandarin, Arabic, Hindi, Bengali, Tamil, and more

**Quality Assessment:**
- 99.38% pronunciation accuracy
- Studio-quality voiceovers available
- Good for dubbing (40+ languages)

**Pricing:**
| Product | Price |
|---------|-------|
| Falcon API (conversational) | $0.01/minute |
| Enterprise API | ~$3,000/year |
| Basic plan | $19/user/month (annual) |
| Pro plan | $26/month |
| Enterprise plan | $75/month (5 users) |

**Latency:**
- Falcon: <55ms model latency, <130ms time to first audio
- Industry-leading for voice agents

**Streaming Support:** Yes, real-time synthesis

**Rate Limits:**
- Falcon: Up to 10,000 concurrent calls at consistent latency
- Output formats: MP3, FLAC, WAV

---

## Comparison Summary

### STT Provider Comparison

| Provider | Languages | Streaming | Latency | Price (approx) | Best For |
|----------|-----------|-----------|---------|----------------|----------|
| OpenAI Whisper | 99 | No | N/A (batch) | $0.006/min | Batch processing, accuracy |
| Google Cloud | 125+ | Yes | Low | $0.016/min | Enterprise, medical |
| Amazon Transcribe | 100+ | Yes (54 langs) | Low | $0.024/min | AWS ecosystem, contact centers |
| Azure Speech | 100+ | Yes | 400-800ms | $0.0167/min | Microsoft ecosystem |
| Deepgram | 36+ | Yes | <300ms | $0.0043/min | Real-time, low latency |
| AssemblyAI | 99 (6 streaming) | Yes | ~300ms | $0.0025/min | Cost-effective, scaling |
| Rev.ai | 36-58 | Yes | 1-3ms | $0.003-0.02/min | High accuracy, hybrid |

### TTS Provider Comparison

| Provider | Languages | Streaming | Latency | Price (approx) | Best For |
|----------|-----------|-----------|---------|----------------|----------|
| ElevenLabs | 29-70+ | Yes | 75ms | $0.12-0.30/1K chars | Quality, expressiveness |
| OpenAI TTS | 99 | Yes | ~500ms | $15/1M chars | Steerability, integration |
| Google Cloud | 75+ | Yes | Low | $4-16/1M chars | Enterprise, scale |
| Amazon Polly | 40+ | Yes | Low | $4.80-19.20/1M chars | AWS ecosystem |
| Azure Speech | 140+ | Yes | Low | $16/1M chars | Microsoft ecosystem |
| Play.ht | ~20 usable | Yes | Low | $39-198/month | Voice cloning |
| Murf.ai | 35 | Yes | <55ms | $0.01/min | Voice agents, dubbing |

---

## Recommendations for UnaMentis

### Primary Considerations

1. **Latency Requirements:** UnaMentis targets <500ms end-to-end latency
   - Best STT: Deepgram (<300ms), Rev.ai (1-3ms), AssemblyAI (~300ms)
   - Best TTS: Murf.ai Falcon (<55ms), ElevenLabs Flash (75ms)

2. **Multilingual Support:** For voice tutoring across languages
   - Best STT: OpenAI Whisper (99 langs), Google Cloud (125+), AssemblyAI (99)
   - Best TTS: Azure (140+), Google Cloud (75+), ElevenLabs (70+)

3. **Cost at Scale:** For 60-90 minute sessions
   - Most cost-effective STT: AssemblyAI ($0.0025/min), Deepgram ($0.0043/min)
   - Most cost-effective TTS: Murf.ai Falcon ($0.01/min), Amazon Polly Standard ($4.80/1M chars)

4. **Streaming for Real-time:** Essential for voice tutoring
   - STT: All except OpenAI Whisper API support streaming
   - TTS: All providers support streaming

### Recommended Fallback Strategy

**STT Priority Order:**
1. Deepgram Nova-3 (primary) - Best latency/cost ratio
2. AssemblyAI Universal (fallback) - Better language coverage
3. Google Cloud Speech-to-Text (enterprise fallback) - Maximum language coverage

**TTS Priority Order:**
1. ElevenLabs Flash v2.5 (primary) - Best quality with low latency
2. Murf.ai Falcon (cost-sensitive fallback) - Lowest cost for voice agents
3. Azure Speech (enterprise fallback) - Maximum language coverage

---

## Sources

### STT Sources
- [OpenAI Whisper Supported Languages](https://platform.openai.com/docs/guides/speech-to-text/supported-languages)
- [Google Cloud Speech-to-Text Pricing](https://cloud.google.com/speech-to-text/pricing)
- [Google Cloud Speech-to-Text Supported Languages](https://docs.cloud.google.com/speech-to-text/docs/speech-to-text-supported-languages)
- [Amazon Transcribe Pricing](https://aws.amazon.com/transcribe/pricing/)
- [Amazon Transcribe Supported Languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html)
- [Azure Speech Services Pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/)
- [Azure Speech Language Support](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support)
- [Deepgram Pricing](https://deepgram.com/pricing)
- [Deepgram API Rate Limits](https://developers.deepgram.com/reference/api-rate-limits)
- [AssemblyAI Pricing](https://www.assemblyai.com/pricing)
- [AssemblyAI Concurrency Limits](https://www.assemblyai.com/docs/faq/what-are-my-concurrency-limits)
- [Rev.ai Pricing](https://www.rev.ai/pricing)

### TTS Sources
- [ElevenLabs API Pricing](https://elevenlabs.io/pricing/api)
- [ElevenLabs Rate Limits](https://help.elevenlabs.io/hc/en-us/articles/14312733311761-How-many-requests-can-I-make-and-can-I-increase-it)
- [OpenAI TTS Documentation](https://platform.openai.com/docs/guides/text-to-speech)
- [Google Cloud Text-to-Speech Pricing](https://cloud.google.com/text-to-speech/pricing)
- [Google Cloud TTS Voices](https://docs.cloud.google.com/text-to-speech/docs/list-voices-and-types)
- [Amazon Polly Pricing](https://aws.amazon.com/polly/pricing/)
- [Amazon Polly Quotas](https://docs.aws.amazon.com/polly/latest/dg/limits.html)
- [Azure Speech Services Quotas](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-services-quotas-and-limits)
- [PlayAI Pricing](https://play.ht/pricing/)
- [Murf.ai Pricing](https://murf.ai/pricing)
- [Murf.ai API](https://murf.ai/api)
