# Multilingual Voice AI Technology Evaluation

> **Generated:** 2026-01-02
> **Purpose:** Comprehensive evaluation of STT, TTS, and LLM options for determining which languages UnaMentis can practically support

---

## Executive Summary

This document evaluates all available Speech-to-Text (STT), Text-to-Speech (TTS), and Large Language Model (LLM) options with a focus on open-source and on-device solutions. The goal is to find the **intersection of languages** that are well-supported across all three capabilities, determining which languages the app can practically support.

**Key Finding:** A core set of **12-15 languages** have excellent support across all three technology pillars. An extended set of **25-30 languages** have good-to-moderate support suitable for production use.

### Tier 1 Languages (Full Support Recommended)
English, Spanish, French, German, Portuguese, Italian, Chinese (Mandarin), Japanese, Korean, Russian, Dutch, Polish

### Tier 2 Languages (Good Support)
Arabic, Hindi, Turkish, Vietnamese, Indonesian, Thai, Czech, Greek, Romanian, Ukrainian, Swedish, Norwegian, Danish, Finnish

### Tier 3 Languages (Moderate Support, Requires Testing)
Hebrew, Hungarian, Bulgarian, Croatian, Slovak, Slovenian, Tamil, Bengali, Malay, Tagalog/Filipino

---

## Table of Contents

1. [Methodology](#1-methodology)
2. [Speech-to-Text Options](#2-speech-to-text-options)
3. [Text-to-Speech Options](#3-text-to-speech-options)
4. [LLM Options](#4-llm-options)
5. [Language Intersection Matrix](#5-language-intersection-matrix)
6. [On-Device Deployment Strategy](#6-on-device-deployment-strategy)
7. [Recommendations](#7-recommendations)
8. [Implementation Priorities](#8-implementation-priorities)

---

## 1. Methodology

Languages are evaluated based on:
1. **STT Quality:** Word Error Rate (WER) below 15% for conversational speech
2. **TTS Quality:** Natural-sounding voices suitable for educational content
3. **LLM Quality:** Strong reasoning, instruction-following, and translation capabilities
4. **On-Device Feasibility:** Can run on iPhone 15 Pro (8GB RAM) or better
5. **License:** Permissive for commercial use (Apache 2.0, MIT, or equivalent)

---

## 2. Speech-to-Text Options

### 2.1 Open Source Models

#### OpenAI Whisper (MIT License)

| Model | Parameters | Size (GGUF Q4) | iOS Feasible | Languages |
|-------|------------|----------------|--------------|-----------|
| tiny | 39M | 75 MB | Yes | 99 |
| base | 74M | 142 MB | Yes | 99 |
| small | 244M | 466 MB | Yes | 99 |
| medium | 769M | 1.5 GB | Marginal | 99 |
| large-v3 | 1.55B | 2.9 GB | No | 99 |
| large-v3-turbo | 809M | ~1.5 GB | Marginal | 99 |

**Language Quality Tiers (by WER):**

| Tier | WER Range | Languages |
|------|-----------|-----------|
| Excellent | <8% | English, Italian, German, Spanish |
| Good | 8-15% | French, Portuguese, Japanese, Chinese, Russian, Korean, Dutch, Polish, Swedish, Norwegian, Danish, Finnish, Czech, Greek, Romanian, Hungarian, Turkish |
| Fair | 15-30% | Arabic, Hindi, Hebrew, Indonesian, Vietnamese, Thai, Ukrainian, Bulgarian, Croatian, Slovak, Slovenian, Lithuanian, Latvian, Estonian, Catalan, Basque, Galician, Welsh, Icelandic, Malay, Filipino |
| Limited | 30%+ | Most Indian languages (Tamil, Telugu, Kannada, Malayalam, Punjabi, Gujarati, Marathi, Bengali), African languages |

#### WhisperKit (MIT License, iOS Native)
- **Recommendation for iOS:** Best on-device option
- **Mean latency:** 0.45 seconds
- **Models:** tiny through large-v3, optimized for Apple Neural Engine
- **Languages:** Same 99 as Whisper

#### Vosk (Apache 2.0)
- **Model sizes:** 50-124 MB per language
- **Languages:** 20+ with varying quality
- **iOS:** Supported via SDK
- **Best for:** Offline-first scenarios

#### Moonshine (MIT License)
- **Size:** 27M-400M parameters
- **Languages (2025):** English, Arabic, Chinese, Japanese, Korean, Ukrainian, Vietnamese
- **Performance:** 5-15x faster than Whisper, 48% lower error rates than Whisper Tiny

### 2.2 On-Device iOS Options

| Option | Latency | Languages | Quality | Recommendation |
|--------|---------|-----------|---------|----------------|
| WhisperKit | ~450ms | 99 | Excellent | Primary |
| Apple SFSpeechRecognizer | <200ms | ~15 on-device | Good | Fallback for supported languages |
| whisper.cpp + CoreML | ~400ms | 99 | Excellent | Alternative |
| Vosk | 500-1200ms | 20+ | Good | Offline backup |

### 2.3 Commercial Providers (Fallback)

| Provider | Languages | Streaming | Latency | Price/min |
|----------|-----------|-----------|---------|-----------|
| Deepgram | 36+ | Yes | <300ms | $0.0043 |
| AssemblyAI | 99 (6 streaming) | Yes | ~300ms | $0.0025 |
| Google Cloud | 125+ | Yes | Low | $0.016 |

---

## 3. Text-to-Speech Options

### 3.1 Open Source Models

#### Piper TTS (MIT License)

| Quality | Size | Languages | iOS Feasible |
|---------|------|-----------|--------------|
| x_low | 15 MB | 51 | Yes |
| low | 30 MB | 51 | Yes |
| medium | 60 MB | 51 | Yes |
| high | 90 MB | 51 | Yes |

**Well-Supported Languages (51):**
Arabic, Catalan, Czech, Danish, German, Greek, English (multiple accents), Spanish, Persian, Finnish, French, Hungarian, Icelandic, Italian, Georgian, Kazakh, Korean, Luxembourgish, Nepali, Dutch, Norwegian, Polish, Portuguese, Romanian, Russian, Serbian, Swahili, Swedish, Turkish, Ukrainian, Vietnamese, Chinese

#### Kokoro-82M (Apache 2.0)

| Attribute | Value |
|-----------|-------|
| Parameters | 82M |
| Size | ~300 MB |
| iOS | Yes (CoreML available) |
| Languages | 8: American English, British English, French, Hindi, Spanish, Japanese, Chinese, Portuguese |
| Quality | Excellent for size |
| Latency | Up to 210x real-time on GPU |

#### Chatterbox Multilingual (MIT License)

| Attribute | Value |
|-----------|-------|
| Parameters | ~500M |
| Languages | 23 |
| Voice Cloning | Yes (zero-shot, cross-lingual) |
| iOS | Challenging (server-side recommended) |

**Languages:** Arabic, Danish, German, Greek, English, Spanish, Finnish, French, Hebrew, Hindi, Italian, Japanese, Korean, Malay, Dutch, Norwegian, Polish, Portuguese, Russian, Swedish, Swahili, Turkish, Chinese

#### MeloTTS (MIT License)

| Attribute | Value |
|-----------|-------|
| Target Size | 50 MB (quantized) |
| Languages | 6-9 |
| iOS | Possible (OpenVINO, ONNX) |
| Latency | 0.9x RTF on CPU |

**Core Languages:** English, Spanish, French, Chinese, Japanese, Korean
**Community:** Hindi, Arabic, German

#### Orpheus TTS (Apache 2.0)

| Model | Parameters | iOS Feasible |
|-------|------------|--------------|
| Orpheus 150M | 150M | Yes |
| Orpheus 400M | 400M | Marginal |
| Orpheus 1B | 1B | No |
| Orpheus 3B | 3B | No |

**Languages:** English, Chinese, Hindi, Korean, Spanish, French, German, Italian, Mandarin

### 3.2 On-Device iOS Options

| Option | Latency | Languages | Quality | Recommendation |
|--------|---------|-----------|---------|----------------|
| AVSpeechSynthesizer | <50ms | 50+ | Good (Enhanced: Excellent) | Primary for coverage |
| Kokoro-CoreML | <200ms | 8 | Excellent | Primary for key languages |
| Piper (ONNX) | <100ms | 51 | Good | Best open-source coverage |
| Orpheus 150M | ~200ms | 9 | Very Good | Voice cloning |

#### Apple AVSpeechSynthesizer Languages (50+)

Arabic, Chinese (Simplified/Traditional/HK), Czech, Danish, Dutch, English (US/UK/AU/IE/ZA), Finnish, French (FR/CA), German, Greek, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Norwegian, Polish, Portuguese (BR/PT), Romanian, Russian, Spanish (ES/MX), Swedish, Thai, Turkish, Vietnamese

### 3.3 Commercial Providers (Fallback)

| Provider | Languages | Streaming | Latency | Price |
|----------|-----------|-----------|---------|-------|
| ElevenLabs | 29-70+ | Yes | 75ms | $0.12-0.30/1K chars |
| Murf.ai Falcon | 35 | Yes | <55ms | $0.01/min |
| Azure Speech | 140+ | Yes | Low | $16/1M chars |

---

## 4. LLM Options

### 4.1 Open Source Models

#### Qwen 2.5 (Apache 2.0) - RECOMMENDED

| Model | Parameters | Size (Q4) | iOS Feasible | Languages |
|-------|------------|-----------|--------------|-----------|
| 0.5B | 0.5B | ~300 MB | Yes | 29+ |
| 1.5B | 1.5B | ~900 MB | Yes | 29+ |
| 3B | 3B | ~1.8 GB | Yes | 29+ |
| 7B | 7B | ~4 GB | Marginal | 29+ |

**Strong Languages (29+):** Chinese, English, French, Spanish, Portuguese, German, Italian, Russian, Japanese, Korean, Vietnamese, Thai, Arabic, Indonesian, Turkish, Polish, Ukrainian, Romanian, Greek, Hindi, Hebrew, Persian, Dutch, Czech

**Why Recommended:**
- Best multilingual coverage for parameter count
- Apache 2.0 license (fully permissive)
- Excellent math/reasoning for tutoring
- Strong Asian language support

#### Llama 3.2 (Llama Community License)

| Model | Parameters | Size (Q4) | iOS Feasible | Languages |
|-------|------------|-----------|--------------|-----------|
| 1B | 1B | ~600 MB | Yes | 8 (official) |
| 3B | 3B | ~1.9 GB | Yes | 8 (official) |

**Official Languages (8):** English, French, German, Hindi, Italian, Portuguese, Spanish, Thai

**Strengths:**
- Best instruction following (IFEval benchmark leader)
- Designed for on-device via ExecuTorch
- 33 tok/s on M1 Max with Core ML

#### Mistral/Ministral (Apache 2.0)

| Model | Parameters | Size (Q4) | iOS Feasible | Languages |
|-------|------------|-----------|--------------|-----------|
| Ministral 3B | 3B | ~1.8 GB | Yes | 40+ |

**Strengths:**
- Strong European language support
- Native French excellence
- 80+ coding languages

#### Phi-4 Mini (MIT License)

| Model | Parameters | Size (Q4) | iOS Feasible | Languages |
|-------|------------|-----------|--------------|-----------|
| 3.8B | 3.8B | ~2.2 GB | Yes | 22 |

**Languages (22):** English, Chinese, Japanese, Spanish, Portuguese, Arabic, Thai, Russian + 14 more

**Strengths:**
- Best for STEM/math tutoring
- MIT license (most permissive)
- Enhanced reasoning capabilities

#### Aya Expanse (Apache 2.0)

| Model | Parameters | Size (Q4) | iOS Feasible | Languages |
|-------|------------|-----------|--------------|-----------|
| 8B | 8B | ~4.5 GB | Marginal | 23 |

**Languages (23):** Arabic, Chinese (Simplified/Traditional), Czech, Dutch, English, French, German, Greek, Hebrew, Hindi, Indonesian, Italian, Japanese, Korean, Persian, Polish, Portuguese, Romanian, Russian, Spanish, Turkish, Ukrainian, Vietnamese

**Strengths:**
- Purpose-built for multilingual
- Outperforms larger models on multilingual benchmarks

### 4.2 Commercial APIs (Fallback)

| Provider | Languages | Best For |
|----------|-----------|----------|
| Claude | Major world languages | Nuanced explanations, safety |
| GPT-4 | 50+ | Accessibility, function calling |
| Gemini | 140+ | Maximum language coverage |

---

## 5. Language Intersection Matrix

### 5.1 Tier 1: Full Production Support

Languages with **excellent** support across all three technology pillars:

| Language | Code | STT Quality | TTS Quality | LLM Quality | On-Device |
|----------|------|-------------|-------------|-------------|-----------|
| English | en | Excellent | Excellent | Excellent | Yes |
| Spanish | es | Excellent | Excellent | Excellent | Yes |
| French | fr | Good | Excellent | Excellent | Yes |
| German | de | Excellent | Excellent | Excellent | Yes |
| Italian | it | Excellent | Excellent | Excellent | Yes |
| Portuguese | pt | Good | Excellent | Excellent | Yes |
| Chinese (Mandarin) | zh | Good | Excellent | Excellent | Yes |
| Japanese | ja | Good | Excellent | Excellent | Yes |
| Korean | ko | Good | Good | Excellent | Yes |
| Russian | ru | Good | Good | Good | Yes |
| Dutch | nl | Good | Good | Good | Yes |
| Polish | pl | Good | Good | Good | Yes |

**These 12 languages should be prioritized for full voice tutoring support.**

### 5.2 Tier 2: Good Production Support

Languages with **good** support, suitable for production with some limitations:

| Language | Code | STT Quality | TTS Quality | LLM Quality | Notes |
|----------|------|-------------|-------------|-------------|-------|
| Arabic | ar | Fair | Good | Good | RTL support needed |
| Hindi | hi | Fair | Good | Good | Large market |
| Turkish | tr | Good | Good | Good | |
| Vietnamese | vi | Fair | Good | Good | Qwen strength |
| Indonesian | id | Fair | Good | Good | |
| Thai | th | Fair | Good | Good | Llama 3 official |
| Czech | cs | Good | Good | Good | |
| Greek | el | Good | Good | Good | |
| Romanian | ro | Good | Good | Good | |
| Ukrainian | uk | Fair | Good | Good | |
| Swedish | sv | Good | Good | Good | |
| Norwegian | no | Good | Good | Good | |
| Danish | da | Good | Good | Good | |
| Finnish | fi | Good | Good | Good | |

**These 14 languages can be supported with appropriate quality expectations.**

### 5.3 Tier 3: Moderate Support

Languages with **moderate** support, requires additional testing:

| Language | Code | STT Quality | TTS Quality | LLM Quality | Notes |
|----------|------|-------------|-------------|-------------|-------|
| Hebrew | he | Fair | Good | Good | RTL support needed |
| Hungarian | hu | Good | Good | Fair | |
| Bulgarian | bg | Fair | Good | Fair | |
| Croatian | hr | Fair | Good | Fair | |
| Slovak | sk | Fair | Good | Fair | |
| Slovenian | sl | Fair | Good | Fair | |
| Tamil | ta | Limited | Fair | Fair | NPTEL strength |
| Bengali | bn | Limited | Fair | Fair | |
| Malay | ms | Fair | Good | Fair | |
| Tagalog/Filipino | tl | Fair | Fair | Fair | |

### 5.4 Technology Coverage by Language

#### STT Coverage (Open Source)

| Technology | Languages | Quality |
|------------|-----------|---------|
| Whisper large-v3 | 99 | Best overall |
| Whisper small | 99 | Good for on-device |
| WhisperKit | 99 | Best iOS option |
| Vosk | 20+ | Good offline |
| Apple Speech | ~15 on-device | Native |

#### TTS Coverage (Open Source)

| Technology | Languages | Quality |
|------------|-----------|---------|
| Piper | 51 | Good, lightweight |
| AVSpeechSynthesizer | 50+ | Native iOS |
| Chatterbox | 23 | Voice cloning |
| Kokoro | 8 | Excellent quality |
| MeloTTS | 6-9 | CPU optimized |

#### LLM Coverage (Open Source)

| Technology | Languages | Quality |
|------------|-----------|---------|
| Qwen 2.5 | 29+ | Best multilingual |
| Llama 3.2 | 8 (official) | Best instruction following |
| Aya Expanse | 23 | Purpose-built multilingual |
| Mistral | 40+ | Best European |

---

## 6. On-Device Deployment Strategy

### 6.1 iPhone Memory Budget

**iPhone 15 Pro (8GB RAM):**
- Available for app: ~4-5GB
- Recommended total model size: <3GB

**Recommended Configuration:**

| Component | Model | Size | Languages |
|-----------|-------|------|-----------|
| STT | WhisperKit small | 466 MB | 99 |
| TTS | Piper (per-language) | 60 MB each | 51 |
| LLM | Qwen 2.5 3B (Q4_K_M) | 1.8 GB | 29 |
| **Total** | | ~2.3-2.5 GB | All Tier 1 |

### 6.2 Fallback Strategy

```
Primary: On-device
  ├── STT: WhisperKit small
  ├── TTS: AVSpeechSynthesizer + Kokoro (key languages)
  └── LLM: Qwen 2.5 3B

Fallback 1: Server-hosted open source
  ├── STT: Whisper large-v3
  ├── TTS: Chatterbox Multilingual
  └── LLM: Qwen 2.5 7B

Fallback 2: Commercial APIs
  ├── STT: Deepgram Nova-3
  ├── TTS: ElevenLabs Flash
  └── LLM: Claude/GPT-4
```

### 6.3 Language-Specific Optimization

| Language | Recommended Stack | Notes |
|----------|-------------------|-------|
| English | WhisperKit + Kokoro + Qwen 3B | Best quality |
| Spanish | WhisperKit + Piper + Qwen 3B | Full open-source |
| Chinese | WhisperKit + AVSpeech + Qwen 3B | Qwen excels |
| Japanese | WhisperKit + Kokoro + Qwen 3B | Qwen excels |
| Hindi | WhisperKit + AVSpeech + Qwen 3B | Growing support |
| Arabic | WhisperKit + Chatterbox + Qwen 3B | RTL, server TTS |

---

## 7. Recommendations

### 7.1 Immediate Implementation (Phase 1)

**Target: 5 languages for MVP**

1. **English** - Primary, full on-device
2. **Spanish** - Largest non-English market
3. **French** - European coverage
4. **German** - European coverage
5. **Portuguese** - Brazil market

**Technology Stack:**
- STT: WhisperKit small (on-device)
- TTS: Kokoro-CoreML (EN) + Piper (others)
- LLM: Qwen 2.5 3B (on-device)

### 7.2 Expansion (Phase 2)

**Add: 7 more languages**

6. **Chinese (Mandarin)** - Qwen strength
7. **Japanese** - Qwen strength
8. **Korean** - Asian market
9. **Italian** - European coverage
10. **Russian** - Large market
11. **Dutch** - European coverage
12. **Polish** - European coverage

### 7.3 Extended Support (Phase 3)

**Add Tier 2 languages based on user demand:**
- Arabic, Hindi, Turkish, Vietnamese, Indonesian
- Thai, Czech, Greek, Romanian, Ukrainian
- Scandinavian languages (Swedish, Norwegian, Danish, Finnish)

### 7.4 License Summary

| Component | Recommended | License | Commercial OK |
|-----------|-------------|---------|---------------|
| STT | WhisperKit | MIT | Yes |
| TTS | Piper | MIT | Yes |
| TTS | Kokoro | Apache 2.0 | Yes |
| LLM | Qwen 2.5 | Apache 2.0 | Yes |
| LLM Alt | Llama 3.2 | Llama Community | Yes (<700M users) |

---

## 8. Implementation Priorities

### 8.1 Critical Path

1. **Integrate WhisperKit** for STT (all 99 languages covered)
2. **Integrate Qwen 2.5 3B** for LLM (29+ languages with Apache 2.0)
3. **Integrate Piper TTS** for open-source voices (51 languages)
4. **Keep AVSpeechSynthesizer** as fallback (50+ native iOS voices)

### 8.2 Configuration Required

```swift
// Session initialization with language
struct LanguageConfig {
    let code: String // BCP 47
    let sttModel: STTModel
    let ttsVoice: TTSVoice
    let llmPromptLanguage: String
}

// Tier 1 language configs
let tier1Languages = [
    "en-US", "es-ES", "fr-FR", "de-DE", "it-IT",
    "pt-BR", "zh-Hans", "ja-JP", "ko-KR", "ru-RU",
    "nl-NL", "pl-PL"
]
```

### 8.3 Quality Metrics to Track

| Metric | Target | Languages |
|--------|--------|-----------|
| STT WER | <15% | Tier 1 |
| TTS MOS | >3.5 | Tier 1 |
| LLM accuracy | >85% | Tier 1 |
| E2E latency | <500ms | All |

---

## Appendix A: Complete Language Support Table

| Language | ISO 639-1 | Whisper | Piper | AVSpeech | Qwen 2.5 | Llama 3.2 | Tier |
|----------|-----------|---------|-------|----------|----------|-----------|------|
| English | en | Excellent | Yes | Yes | Yes | Yes | 1 |
| Spanish | es | Excellent | Yes | Yes | Yes | Yes | 1 |
| French | fr | Good | Yes | Yes | Yes | Yes | 1 |
| German | de | Excellent | Yes | Yes | Yes | Yes | 1 |
| Italian | it | Excellent | Yes | Yes | Yes | Yes | 1 |
| Portuguese | pt | Good | Yes | Yes | Yes | Yes | 1 |
| Chinese | zh | Good | Yes | Yes | Yes | No | 1 |
| Japanese | ja | Good | No | Yes | Yes | No | 1 |
| Korean | ko | Good | Yes | Yes | Yes | No | 1 |
| Russian | ru | Good | Yes | Yes | Yes | No | 1 |
| Dutch | nl | Good | Yes | Yes | Yes | No | 1 |
| Polish | pl | Good | Yes | Yes | Yes | No | 1 |
| Arabic | ar | Fair | Yes | Yes | Yes | No | 2 |
| Hindi | hi | Fair | No | Yes | Yes | Yes | 2 |
| Turkish | tr | Good | Yes | Yes | Yes | No | 2 |
| Vietnamese | vi | Fair | Yes | Yes | Yes | No | 2 |
| Indonesian | id | Fair | No | Yes | Yes | No | 2 |
| Thai | th | Fair | No | Yes | Yes | Yes | 2 |
| Czech | cs | Good | Yes | Yes | Yes | No | 2 |
| Greek | el | Good | Yes | Yes | Yes | No | 2 |
| Romanian | ro | Good | Yes | Yes | Yes | No | 2 |
| Ukrainian | uk | Fair | Yes | No | Yes | No | 2 |
| Swedish | sv | Good | Yes | Yes | No | No | 2 |
| Norwegian | no | Good | Yes | Yes | No | No | 2 |
| Danish | da | Good | Yes | Yes | No | No | 2 |
| Finnish | fi | Good | Yes | Yes | No | No | 2 |
| Hebrew | he | Fair | No | Yes | Yes | No | 3 |
| Hungarian | hu | Good | Yes | Yes | No | No | 3 |
| Bulgarian | bg | Fair | No | No | No | No | 3 |
| Croatian | hr | Fair | Yes | No | No | No | 3 |
| Tamil | ta | Limited | No | No | No | No | 3 |
| Bengali | bn | Limited | No | No | No | No | 3 |

---

## Appendix B: Model Download Sizes

### STT Models (WhisperKit/whisper.cpp)
| Model | CoreML Size | GGUF Q4 Size |
|-------|-------------|--------------|
| tiny | ~100 MB | 75 MB |
| base | ~200 MB | 142 MB |
| small | ~500 MB | 466 MB |
| medium | ~1.5 GB | 1.5 GB |

### TTS Models (Piper)
| Quality | Per-Voice Size |
|---------|----------------|
| x_low | 15 MB |
| low | 30 MB |
| medium | 60 MB |
| high | 90 MB |

### LLM Models
| Model | Q4_K_M Size |
|-------|-------------|
| Qwen 2.5 0.5B | ~300 MB |
| Qwen 2.5 1.5B | ~900 MB |
| Qwen 2.5 3B | ~1.8 GB |
| Llama 3.2 1B | ~600 MB |
| Llama 3.2 3B | ~1.9 GB |

---

## Sources

### Speech-to-Text
- [OpenAI Whisper GitHub](https://github.com/openai/whisper)
- [WhisperKit GitHub](https://github.com/argmaxinc/WhisperKit)
- [whisper.cpp GitHub](https://github.com/ggml-org/whisper.cpp)
- [Vosk API](https://alphacephei.com/vosk/)
- [Apple SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)

### Text-to-Speech
- [Piper TTS GitHub](https://github.com/rhasspy/piper)
- [Kokoro-82M on Hugging Face](https://huggingface.co/hexgrad/Kokoro-82M)
- [Chatterbox GitHub](https://github.com/resemble-ai/chatterbox)
- [MeloTTS GitHub](https://github.com/myshell-ai/MeloTTS)
- [Apple AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)

### Large Language Models
- [Qwen 2.5 Blog](https://qwenlm.github.io/blog/qwen2.5-llm/)
- [Llama 3.2 Hugging Face](https://huggingface.co/blog/llama32)
- [Mistral AI Models](https://mistral.ai/news/mistral-3)
- [Aya Expanse](https://cohere.com/research/aya)
- [Apple Core ML LLM Research](https://machinelearning.apple.com/research/core-ml-on-device-llama)

### Benchmarks
- [Northflank STT Benchmarks 2025](https://northflank.com/blog/best-open-source-speech-to-text-stt-model-in-2025-benchmarks)
- [Picovoice TTS Latency Benchmark](https://picovoice.ai/docs/benchmark/tts-latency/)
- [OpenCompass LLM Leaderboard](https://opencompass.org.cn/)

---

*Document generated: 2026-01-02*
*UnaMentis Multilingual Technology Evaluation*
