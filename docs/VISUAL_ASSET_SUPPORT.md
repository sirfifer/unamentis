# Visual Asset Support for Curriculum

**Version:** 1.0.0
**Date:** 2025-12-23
**Status:** Implementation

---

## Overview

This document describes the visual asset support system for UnaMentis curriculum. The system enables:

1. **Embedded visuals in curriculum** - Images, diagrams, formulas, and slide decks linked to curriculum content
2. **Synchronized display** - Visuals appear inline with text as audio plays during lessons
3. **On-demand visuals** - Users can request images/diagrams via barge-in during Barden mode
4. **Generated visuals** - Support for AI-generated diagrams and images based on user requests

---

## Architecture

### Visual Asset Types

```swift
enum VisualAssetType: String {
    case image          // Static images (PNG, JPEG, WebP, SVG)
    case diagram        // Architectural/flow diagrams
    case equation       // Mathematical equations (LaTeX/MathML)
    case chart          // Data visualizations
    case slideImage     // Individual slide from a deck
    case slideDeck      // Full slide deck reference
    case generated      // AI-generated on-demand
}
```

### Content Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     UMLCF Document                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ContentNode                                          │   │
│  │  ├── transcript (segments with text)                 │   │
│  │  └── media (images, diagrams, equations)             │   │
│  │       ├── embedded (inline with segments)            │   │
│  │       └── reference (optional, user-requestable)     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    UMLCFParser                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Parse media → Create VisualAsset entities            │   │
│  │ Cache images → VisualAssetCache                      │   │
│  │ Map segment timing → VisualAsset.segmentTiming       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    SessionView                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ TranscriptView (text display)                        │   │
│  │ VisualAssetOverlay (synchronized visual display)     │   │
│  │  ├── Show visuals when segment audio plays           │   │
│  │  ├── Support full-screen zoom                        │   │
│  │  └── Handle barge-in visual requests                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## UMLCF Schema Extension

### Media Object in ContentNode

```json
{
  "id": { "value": "topic-1" },
  "title": "Neural Networks",
  "type": "topic",
  "transcript": { ... },
  "media": {
    "embedded": [
      {
        "id": "img-1",
        "type": "diagram",
        "url": "https://curriculum.example.com/images/nn-architecture.png",
        "localPath": "media/nn-architecture.png",
        "title": "Neural Network Architecture",
        "alt": "Diagram showing input layer, hidden layers, and output layer",
        "caption": "A typical feedforward neural network with 3 hidden layers",
        "mimeType": "image/png",
        "dimensions": { "width": 1200, "height": 800 },
        "segmentTiming": {
          "startSegment": 2,
          "endSegment": 5,
          "displayMode": "persistent"
        }
      },
      {
        "id": "eq-1",
        "type": "equation",
        "latex": "\\sigma(x) = \\frac{1}{1 + e^{-x}}",
        "alt": "Sigmoid activation function: sigma of x equals 1 over 1 plus e to the negative x",
        "title": "Sigmoid Function",
        "segmentTiming": {
          "startSegment": 3,
          "endSegment": 3,
          "displayMode": "highlight"
        }
      }
    ],
    "reference": [
      {
        "id": "ref-1",
        "type": "slideDeck",
        "url": "https://curriculum.example.com/slides/nn-overview.pdf",
        "title": "Complete Neural Networks Slide Deck",
        "description": "30-slide presentation covering all topics",
        "keywords": ["architecture", "training", "backpropagation"]
      },
      {
        "id": "ref-2",
        "type": "diagram",
        "url": "https://curriculum.example.com/images/backprop-detail.svg",
        "title": "Detailed Backpropagation Flow",
        "description": "Step-by-step visualization of gradient flow",
        "keywords": ["backpropagation", "gradient", "chain rule"]
      }
    ]
  }
}
```

### Segment Timing Options

| Property | Type | Description |
|----------|------|-------------|
| `startSegment` | int | First segment where visual appears |
| `endSegment` | int | Last segment where visual is visible |
| `displayMode` | string | How the visual appears/disappears |

**Display Modes:**
- `persistent` - Visual stays on screen for entire segment range
- `highlight` - Visual briefly highlights at segment start, then fades to thumbnail
- `popup` - Visual appears as overlay, user dismisses
- `inline` - Visual embedded in transcript text flow

---

## Core Data Model

### VisualAsset Entity

```xml
<entity name="VisualAsset" representedClassName="VisualAsset" syncable="YES">
    <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="assetId" attributeType="String"/>
    <attribute name="type" attributeType="String"/>
    <attribute name="title" optional="YES" attributeType="String"/>
    <attribute name="altText" optional="YES" attributeType="String"/>
    <attribute name="caption" optional="YES" attributeType="String"/>
    <attribute name="remoteURL" optional="YES" attributeType="URI"/>
    <attribute name="localPath" optional="YES" attributeType="String"/>
    <attribute name="mimeType" optional="YES" attributeType="String"/>
    <attribute name="width" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    <attribute name="height" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    <attribute name="startSegment" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    <attribute name="endSegment" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    <attribute name="displayMode" optional="YES" attributeType="String" defaultValueString="persistent"/>
    <attribute name="isReference" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
    <attribute name="keywords" optional="YES" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromDataTransformerName" customClassName="[String]"/>
    <attribute name="cachedData" optional="YES" attributeType="Binary" allowsExternalBinaryDataStorage="YES"/>
    <attribute name="latex" optional="YES" attributeType="String"/>
    <relationship name="topic" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Topic" inverseName="visualAssets" inverseEntity="Topic"/>
</entity>
```

---

## UI Components

### VisualAssetView

Main component for rendering visual assets:

```swift
struct VisualAssetView: View {
    let asset: VisualAsset
    @State private var isFullscreen = false

    var body: some View {
        Group {
            switch asset.visualType {
            case .image, .diagram, .slideImage:
                ImageAssetView(asset: asset, isFullscreen: $isFullscreen)
            case .equation:
                EquationView(latex: asset.latex ?? "")
            case .chart:
                ChartAssetView(asset: asset)
            case .slideDeck:
                SlideDeckPreview(asset: asset)
            case .generated:
                GeneratedImageView(asset: asset)
            }
        }
        .fullScreenCover(isPresented: $isFullscreen) {
            FullscreenVisualView(asset: asset)
        }
    }
}
```

### VisualAssetOverlay

Manages synchronized visual display during curriculum playback:

```swift
struct VisualAssetOverlay: View {
    let currentSegment: Int
    let assets: [VisualAsset]

    private var activeAssets: [VisualAsset] {
        assets.filter { asset in
            let start = Int(asset.startSegment)
            let end = Int(asset.endSegment)
            return currentSegment >= start && currentSegment <= end
        }
    }

    var body: some View {
        VStack {
            Spacer()
            if !activeAssets.isEmpty {
                VisualAssetCarousel(assets: activeAssets)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: activeAssets.count)
    }
}
```

---

## Barge-In Visual Requests

### User-Initiated Visual Requests

Users can request visuals during Barden mode by saying things like:
- "Show me a diagram of that"
- "Can I see the formula?"
- "Display the architecture"

### Request Detection

The barge-in handler detects visual requests:

```swift
private func isVisualRequest(_ transcript: String) -> VisualRequestType? {
    let visualKeywords = ["show", "display", "see", "diagram", "image", "picture", "formula", "equation", "chart", "visual"]
    let requestPatterns = [
        "show me",
        "can i see",
        "display the",
        "what does .* look like"
    ]

    // Check for reference match or generation request
    if matchesReferenceAsset(transcript) {
        return .reference(assetId: matchedAssetId)
    } else if containsGenerationRequest(transcript) {
        return .generate(prompt: transcript)
    }
    return nil
}
```

### Response Flow

1. **Reference Asset**: If request matches a known reference visual, display it
2. **Embedded Asset**: If request relates to current content, show relevant embedded visual
3. **Generated Visual**: If no match, generate on-demand using image generation API

---

## Image Caching Service

### VisualAssetCache

```swift
actor VisualAssetCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var memoryCache: [String: Data] = [:]
    private let maxMemoryCacheSize = 50 * 1024 * 1024 // 50MB

    func cache(asset: VisualAsset, data: Data) async throws
    func retrieve(assetId: String) async -> Data?
    func preloadAssets(for topic: Topic) async
    func clearCache() async
    func cacheSize() async -> Int
}
```

### Preloading Strategy

- When curriculum is imported, download and cache all embedded visuals
- Reference visuals are cached on first access
- Generated visuals are cached with TTL

---

## Integration with TranscriptStreamingService

### Server-Side Changes

The curriculum server should include visual metadata in streaming responses:

```json
{
  "type": "segment_text",
  "index": 3,
  "content": "The sigmoid function is...",
  "visuals": [
    {
      "id": "eq-1",
      "type": "equation",
      "latex": "\\sigma(x) = \\frac{1}{1 + e^{-x}}"
    }
  ]
}
```

### Client-Side Handling

```swift
onSegmentText: { index, type, text, visuals in
    // Buffer text and visuals together
    pendingSegments[index] = (text: text, visuals: visuals)
}

// When playing audio, display both text AND visuals
private func displaySegment(_ segment: Segment) {
    aiResponse = segment.text
    currentVisuals = segment.visuals
}
```

---

## Accessibility

### VoiceOver Support

- All images have descriptive alt text
- Equations have verbal descriptions
- Charts include data summaries

### Audio Descriptions

For visually complex content, provide audio descriptions:

```json
{
  "id": "diagram-1",
  "type": "diagram",
  "url": "...",
  "alt": "Architecture diagram",
  "audioDescription": "The diagram shows three layers: an input layer with 4 nodes, two hidden layers with 8 nodes each, and an output layer with 2 nodes. Arrows connect each node in one layer to all nodes in the next layer, representing a fully connected neural network.",
  "audioDescriptionURL": "media/diagram-1-description.mp3"
}
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Current)
- [x] Design document
- [ ] UMLCF schema extension
- [ ] Core Data VisualAsset entity
- [ ] CurriculumModels visual types
- [ ] UMLCFParser media handling

### Phase 2: UI Components
- [ ] VisualAssetView component
- [ ] VisualAssetOverlay for SessionView
- [ ] Fullscreen visual viewer
- [ ] Equation renderer (LaTeX)

### Phase 3: Synchronized Display
- [ ] Segment-visual timing logic
- [ ] TranscriptStreamingService integration
- [ ] Visual transition animations

### Phase 4: Barge-In Support
- [ ] Visual request detection
- [ ] Reference asset lookup
- [ ] Generated image integration

### Phase 5: Caching & Offline
- [ ] VisualAssetCache service
- [ ] Preloading during import
- [ ] Offline visual support

---

## Future Enhancements

1. **Interactive Diagrams** - Tap to highlight sections, synchronized with narration
2. **Video Clips** - Short video segments for demonstrations
3. **3D Models** - AR/VR visualization of complex structures
4. **Collaborative Annotations** - User notes on visuals
5. **Export Options** - Save visuals for reference
