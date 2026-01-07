# Pronunciation Guide System

**Status:** Implemented
**Version:** 1.0
**Last Updated:** December 2025

---

## Overview

UnaMentis includes a pronunciation guide system that enables TTS (Text-to-Speech) services to correctly pronounce proper nouns, foreign terms, technical vocabulary, and other words that might be mispronounced by default TTS engines.

The pronunciation system is curriculum-integrated, meaning pronunciation hints are defined in UMCF curriculum files and automatically applied during TTS synthesis for curriculum-based sessions.

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                     Pronunciation Pipeline                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  UMCF Curriculum File                                              │
│  ├── pronunciationGuide: { "Medici": { "ipa": "/ˈmɛdɪtʃi/", ... }}│
│  │                                                                 │
│  ▼                                                                 │
│  UMCFParser                                                        │
│  ├── Parses curriculum JSON                                        │
│  ├── Converts to TranscriptData.PronunciationEntry                │
│  │                                                                 │
│  ▼                                                                 │
│  TranscriptData                                                    │
│  ├── Stored in Document.embedding field (JSON)                    │
│  ├── Contains pronunciationGuide dictionary                       │
│  │                                                                 │
│  ▼                                                                 │
│  PronunciationProcessor                                            │
│  ├── Accepts TranscriptData.pronunciationGuide                    │
│  ├── Processes text with whole-word matching                      │
│  ├── Outputs SSML, respelling hints, or plain text                │
│  │                                                                 │
│  ▼                                                                 │
│  TTS Service                                                       │
│  └── Synthesizes speech with pronunciation hints                  │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. PronunciationProcessor

**Location:** `UnaMentis/Services/TTS/PronunciationProcessor.swift`

The `PronunciationProcessor` is a Sendable struct that transforms text by applying pronunciation hints from curriculum data.

#### Key Types

```swift
/// A pronunciation entry for a term
public struct PronunciationHint: Sendable {
    public let term: String       // The word to enhance
    public let ipa: String        // IPA phonetic transcription
    public let respelling: String? // Optional respelling hint
    public let language: String?   // Optional language code (BCP 47)
}

/// Output format for the processed text
public enum OutputFormat: Sendable {
    case ssml       // SSML with <phoneme> tags
    case respelling // Plain text with respelling hints in parentheses
    case plain      // Unchanged text (TTS guesses)
}
```

#### Usage

```swift
// Initialize from curriculum pronunciation guide
let processor = PronunciationProcessor(
    pronunciationGuide: transcriptData.pronunciationGuide,
    outputFormat: .ssml
)

// Process text
let inputText = "The Medici family ruled Florence during the Renaissance."
let outputText = processor.process(inputText)

// Result (SSML format):
// The <phoneme alphabet="ipa" ph="ˈmɛdɪtʃi" xml:lang="it">Medici</phoneme>
// family ruled Florence during the Renaissance.
```

#### String Extension

For convenience, there's a String extension:

```swift
let text = "Discuss the role of Machiavelli."
let processed = text.withPronunciationHints(
    from: transcriptData.pronunciationGuide,
    format: .ssml
)
```

### 2. TranscriptData

**Location:** `UnaMentis/Core/Curriculum/UMCFParser.swift`

The `TranscriptData` struct stores parsed transcript data including the pronunciation guide.

```swift
public struct TranscriptData: Codable, Sendable {
    public let segments: [Segment]
    public let totalDuration: String?
    public let pronunciationGuide: [String: PronunciationEntry]?

    public struct PronunciationEntry: Codable, Sendable {
        public let ipa: String        // IPA pronunciation
        public let respelling: String? // Human-readable respelling
        public let language: String?   // Language of origin (BCP 47)
    }
}
```

### 3. UMCF Curriculum Format

**Location:** `curriculum/spec/umcf-schema.json`

Pronunciation guides are defined at the transcript level in UMCF curriculum files:

```json
{
  "transcript": {
    "segments": [...],
    "pronunciationGuide": {
      "Medici": {
        "ipa": "/ˈmɛdɪtʃi/",
        "respelling": "MED-ih-chee",
        "language": "it"
      },
      "Machiavelli": {
        "ipa": "/ˌmækiəˈvɛli/",
        "respelling": "mak-ee-uh-VEL-ee",
        "language": "it"
      },
      "Cosimo": {
        "ipa": "/ˈkɔːzɪmoʊ/",
        "respelling": "KOH-zee-moh",
        "language": "it"
      }
    }
  }
}
```

---

## Output Formats

### SSML Format (Recommended)

For TTS services that support SSML (ElevenLabs, Google Cloud TTS, Amazon Polly, Azure Speech):

```xml
<phoneme alphabet="ipa" ph="ˈmɛdɪtʃi" xml:lang="it">Medici</phoneme>
```

The processor automatically:
- Strips leading/trailing slashes from IPA (`/ˈmɛdɪtʃi/` → `ˈmɛdɪtʃi`)
- Adds `xml:lang` attribute when language is specified
- Uses the `ipa` alphabet designation

### Respelling Format

For TTS services without SSML support (Apple TTS, some ElevenLabs modes):

```
Medici (MED-ih-chee)
```

This provides a human-readable hint that most TTS engines handle reasonably well.

### Plain Format

Returns text unchanged, relying on the TTS engine's default pronunciation. Use when:
- No pronunciation guide is available
- Testing TTS output without hints
- The TTS service has good default pronunciation

---

## Best Practices

### When to Add Pronunciation Hints

1. **Proper Nouns**: Historical figures, places, institutions
   - "Machiavelli", "Brunelleschi", "Uffizi"

2. **Foreign Terms**: Words from other languages used in context
   - "Schadenfreude", "Zeitgeist", "coup d'état"

3. **Technical Vocabulary**: Domain-specific terms with non-obvious pronunciation
   - "Bayesian", "Fourier", "Euler"

4. **Acronyms and Abbreviations**: When they should be spelled out
   - "API" → "A P I", "SQL" → "sequel" or "S Q L"

5. **Homographs**: Words spelled the same but pronounced differently
   - "read" (present vs past tense), "lead" (verb vs metal)

### IPA Guidelines

- Use standard IPA notation
- Include stress markers (ˈ for primary, ˌ for secondary)
- Use language-appropriate phonemes
- Slashes are optional (processor strips them)

### Respelling Guidelines

- Use capital letters for stressed syllables
- Use hyphens to separate syllables
- Use common English letter combinations
- Keep it intuitive for English speakers

---

## Integration with TTS Services

### ElevenLabs

ElevenLabs supports SSML in their standard and premium tiers. The `SelfHostedTTSService` and `ElevenLabsTTSService` can accept SSML-formatted text.

### Apple TTS (AVSpeechSynthesizer)

Apple's native TTS has limited SSML support. Use the `respelling` output format for Apple TTS, which provides parenthetical hints.

### Deepgram Aura

Deepgram Aura TTS supports SSML phonemes. Use the `ssml` output format.

### Self-Hosted TTS

Self-hosted Piper TTS has limited SSML support. Test pronunciation hints and fall back to respelling format if needed.

---

## Example Curriculum Entry

```json
{
  "umlcf": "1.0.0",
  "id": "renaissance-history-101",
  "title": "Introduction to the Renaissance",
  "content": [
    {
      "id": "topic-medici",
      "title": "The Medici Family",
      "type": "topic",
      "transcript": {
        "segments": [
          {
            "id": "seg-1",
            "type": "explanation",
            "content": "The Medici family was the most powerful banking family in Renaissance Florence. Cosimo de' Medici, often called Cosimo the Elder, established the family's political dominance."
          }
        ],
        "pronunciationGuide": {
          "Medici": {
            "ipa": "/ˈmɛdɪtʃi/",
            "respelling": "MED-ih-chee",
            "language": "it"
          },
          "Cosimo": {
            "ipa": "/ˈkɔːzɪmoʊ/",
            "respelling": "KOH-zee-moh",
            "language": "it"
          },
          "de'": {
            "ipa": "/deɪ/",
            "respelling": "day",
            "language": "it"
          }
        }
      }
    }
  ]
}
```

---

## Future Enhancements

1. **Per-TTS-Provider Configuration**: Allow different output formats per TTS provider
2. **Pronunciation Database**: Shared pronunciation database for common terms
3. **Auto-Detection**: Identify potential pronunciation issues automatically
4. **User Override**: Let users customize pronunciations for their preferences
5. **Regional Variants**: Support American vs British pronunciations

---

## Related Documentation

- [UMCF Specification](../curriculum/spec/UMCF_SPECIFICATION.md) - Full curriculum format specification
- [TTS Services](./PROJECT_OVERVIEW.md#voice-pipeline) - TTS provider integrations
- [Curriculum System](../curriculum/README.md) - Curriculum format overview
