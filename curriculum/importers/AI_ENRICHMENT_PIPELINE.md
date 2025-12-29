# AI-Powered Curriculum Enrichment Pipeline

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-12-17

---

## Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Pipeline Architecture](#pipeline-architecture)
4. [Prior Art & Foundations](#prior-art--foundations)
5. [Stage 1: Content Analysis](#stage-1-content-analysis)
6. [Stage 2: Structure Inference](#stage-2-structure-inference)
7. [Stage 3: Content Segmentation](#stage-3-content-segmentation)
8. [Stage 4: Learning Objective Extraction](#stage-4-learning-objective-extraction)
9. [Stage 5: Assessment Generation](#stage-5-assessment-generation)
10. [Stage 6: Tutoring Enhancement](#stage-6-tutoring-enhancement)
11. [Stage 7: Knowledge Graph Construction](#stage-7-knowledge-graph-construction)
12. [LLM Prompt Engineering](#llm-prompt-engineering)
13. [Quality Assurance](#quality-assurance)
14. [Human-in-the-Loop Editor](#human-in-the-loop-editor)
15. [Implementation Roadmap](#implementation-roadmap)

---

## Overview

The AI Enrichment Pipeline transforms **sparse curriculum content** (plain text, simple outlines, flat documents) into **richly structured UMCF** with all tutoring-specific elements required for effective conversational AI tutoring.

### What "Sparse" Content Lacks

| Missing Element | Impact on Tutoring |
|-----------------|-------------------|
| **Proper granularity** | Can't pace content appropriately |
| **Stopping points** | No natural places for comprehension checks |
| **Learning objectives** | Can't assess progress or align to standards |
| **Assessments/quizzes** | No verification of understanding |
| **Examples** | Abstract concepts remain abstract |
| **Prerequisites** | Learners get lost without foundation |
| **Spoken text variants** | TTS sounds unnatural |
| **Misconceptions** | Common errors go unaddressed |
| **Glossary terms** | Vocabulary barriers unresolved |

### Pipeline Goal

```
┌─────────────────────────────────────────────────────────────────┐
│                      SPARSE INPUT                                │
│  • Plain text document                                          │
│  • Simple outline                                               │
│  • Flat PDF/EPUB                                                │
│  • Minimal metadata                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AI ENRICHMENT PIPELINE                          │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Analyze  │→ │ Structure│→ │ Segment  │→ │ Extract  │       │
│  │ Content  │  │ Infer    │  │ Content  │  │ Objectives│       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │ Generate │→ │ Enhance  │→ │ Build    │                     │
│  │ Assess.  │  │ Tutoring │  │ KG       │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      RICH UMCF OUTPUT                           │
│  • Hierarchical content (modules → topics → subtopics)         │
│  • Transcript segments with stopping points                    │
│  • Learning objectives (Bloom-aligned)                         │
│  • Comprehension assessments                                   │
│  • Worked examples                                             │
│  • Spoken text variants                                        │
│  • Misconceptions with remediation                             │
│  • Prerequisites and knowledge graph                           │
│  • Glossary with contextual definitions                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Problem Statement

### The Enrichment Challenge

Most curriculum content exists in forms optimized for **reading**, not **tutoring**:

1. **Textbooks**: Linear narrative, designed for self-study
2. **Lecture notes**: Dense, assumes instructor mediation
3. **Web articles**: SEO-optimized, variable quality
4. **PDFs**: Formatting preserved, structure lost
5. **Slides**: Bullet points without context

UnaMentis's conversational AI needs:
- **Chunked content** for turn-by-turn delivery
- **Checkpoints** to verify understanding before proceeding
- **Multiple explanation styles** for different learners
- **Questions** to engage active recall
- **Scaffolding** for when learners struggle

### Why AI is Required

Rule-based approaches fail because:
1. **Context dependence**: What's a good stopping point depends on content
2. **Semantic understanding**: Identifying concepts requires comprehension
3. **Generation quality**: Creating good questions requires reasoning
4. **Adaptation**: Different domains need different approaches

AI excels at:
1. **Reading comprehension**: Understanding what text means
2. **Pattern recognition**: Identifying structural elements
3. **Generation**: Creating natural questions, explanations, examples
4. **Reasoning**: Determining prerequisites, difficulty, relationships

---

## Pipeline Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENRICHMENT PIPELINE                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    ORCHESTRATOR                              │   │
│  │  • Manages pipeline stages                                   │   │
│  │  • Tracks enrichment progress                                │   │
│  │  • Handles errors and retries                                │   │
│  │  • Coordinates LLM calls                                     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│       ┌──────────────────────┼──────────────────────┐              │
│       │                      │                      │              │
│       ▼                      ▼                      ▼              │
│  ┌─────────┐           ┌─────────┐           ┌─────────┐          │
│  │ Stage 1 │           │ Stage 2 │           │ Stage 3 │          │
│  │ Analyze │     →     │Structure│     →     │ Segment │    →     │
│  └─────────┘           └─────────┘           └─────────┘          │
│       │                      │                      │              │
│       ▼                      ▼                      ▼              │
│  ┌─────────┐           ┌─────────┐           ┌─────────┐          │
│  │ Stage 4 │           │ Stage 5 │           │ Stage 6 │          │
│  │Extract  │     →     │Generate │     →     │ Enhance │    →     │
│  │Objectives│          │Assess.  │           │Tutoring │          │
│  └─────────┘           └─────────┘           └─────────┘          │
│       │                                                            │
│       ▼                                                            │
│  ┌─────────┐                                                       │
│  │ Stage 7 │                                                       │
│  │Build KG │                                                       │
│  └─────────┘                                                       │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                        SHARED SERVICES                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │   LLM    │  │  NLP     │  │  Entity  │  │ Quality  │           │
│  │ Provider │  │ Toolkit  │  │  Linker  │  │ Checker  │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **LLM Provider** | OpenAI GPT-4, Claude, local Llama | Best reasoning for educational content |
| **NLP Toolkit** | spaCy + NLTK | Industrial NLP (spaCy) + educational corpora (NLTK) |
| **Readability** | py-readability-metrics | Proven formulas (Flesch, Dale-Chall, SMOG) |
| **Entity Linking** | spaCy Entity Linker + Wikidata | Ground concepts in knowledge bases |
| **Embeddings** | sentence-transformers | Semantic similarity for chunking |
| **Orchestration** | LangChain | RAG, chains, memory management |
| **Validation** | Pydantic | Runtime type checking |

---

## Prior Art & Foundations

### Pre-AI Foundations (Proven, Established)

These techniques have decades of research validation:

#### 1. Readability Analysis

| Formula | Best For | Implementation |
|---------|----------|----------------|
| **Flesch-Kincaid** | General English | `textstat.flesch_kincaid_grade()` |
| **Dale-Chall** | Educational content | `textstat.dale_chall_readability_score()` |
| **SMOG Index** | Health/technical | `textstat.smog_index()` |
| **Gunning Fog** | Business writing | `textstat.gunning_fog()` |

```python
# py-readability-metrics example
from readability import Readability
r = Readability(text)
print(r.flesch_kincaid())  # Grade level
print(r.dale_chall())       # Difficulty score
```

#### 2. Semantic Role Labeling (SRL)

**Source**: He, Lewis & Zettlemoyer (2015) - QA-SRL Framework

SRL identifies WHO did WHAT to WHOM, WHERE, WHEN, WHY:
- **Agent**: Who performed the action
- **Patient**: What received the action
- **Instrument**: With what
- **Location**: Where
- **Time**: When

**Why it matters**: SRL enables rule-based question generation:
- "The mitochondria [AGENT] produces [ACTION] ATP [PATIENT] through cellular respiration [MANNER]"
- → "What does the mitochondria produce?"
- → "How does the mitochondria produce ATP?"

```python
# Using AllenNLP SRL
from allennlp.predictors.predictor import Predictor
predictor = Predictor.from_path("srl-model")
result = predictor.predict(sentence="The mitochondria produces ATP")
```

#### 3. Bloom's Taxonomy Classification

**Source**: Anderson & Krathwohl (2001) - Revised Bloom's Taxonomy

| Level | Verbs | Question Stems |
|-------|-------|----------------|
| **Remember** | define, list, recall | "What is...?", "List the..." |
| **Understand** | explain, describe, summarize | "Explain how...", "Describe..." |
| **Apply** | use, solve, demonstrate | "How would you use...?" |
| **Analyze** | compare, contrast, examine | "What is the difference...?" |
| **Evaluate** | judge, assess, justify | "Do you agree...? Why?" |
| **Create** | design, construct, develop | "How would you design...?" |

```python
# Bloom verb detection
BLOOM_VERBS = {
    "remember": ["define", "list", "recall", "identify", "name"],
    "understand": ["explain", "describe", "summarize", "interpret"],
    "apply": ["use", "solve", "demonstrate", "calculate"],
    "analyze": ["compare", "contrast", "examine", "differentiate"],
    "evaluate": ["judge", "assess", "justify", "critique"],
    "create": ["design", "construct", "develop", "formulate"]
}
```

#### 4. Text Segmentation (TextTiling)

**Source**: Hearst (1997) - TextTiling Algorithm

TextTiling detects topic boundaries by measuring lexical cohesion:
1. Divide text into pseudo-sentences
2. Calculate similarity between adjacent blocks
3. Identify valleys (low similarity = topic shift)

```python
from nltk.tokenize import TextTilingTokenizer
tt = TextTilingTokenizer()
segments = tt.tokenize(document)
```

### AI-Powered Approaches (State of the Art)

#### 1. COGENT Framework (2025)

**Source**: Liu, Yin, Goh, Chen - "COGENT: Curriculum-Oriented Generation"
**Paper**: arxiv.org/abs/2506.09367

Key innovations:
- **Curriculum hierarchy integration**: Maps content to Core Ideas → Learning Objectives
- **Controllable generation**: Length, vocabulary, sentence complexity
- **Wonder-based engagement**: Generates content that sparks curiosity
- **Multi-aspect evaluation**: Automated + human assessment

**How we use it**: Prompt structure for grade-appropriate content generation.

#### 2. Meta-Chunking (2024)

**Source**: "Learning Text Segmentation via Logical Perception"
**Paper**: arxiv.org/abs/2410.12788

Key innovations:
- **Perplexity-based chunking**: Uses language model uncertainty to find boundaries
- **Margin sampling**: Identifies points where topic confidence drops
- **Dual-strategy approach**: Combines multiple signals

**Results**: 1.32 improvement on multi-hop QA, 45.8% less computation than similarity-based chunking.

**How we use it**: Intelligent transcript segmentation.

#### 3. Knowledge Graph Construction with LLMs

**Source**: Multiple papers on EduKG, CourseMapper, LLM-KG integration

Key patterns:
- **Concept extraction**: LLM identifies key concepts from text
- **Relation inference**: LLM proposes prerequisite/related relationships
- **Entity linking**: Ground concepts to Wikidata/DBpedia
- **Graph completion**: Fill missing relationships

**How we use it**: Build prerequisite graphs and learning paths.

#### 4. Automatic Question Generation (AQG)

**Source**: Survey in PMC journals, multiple implementations

Evolution:
1. **Rule-based SRL** (2015-2018): Pattern matching on semantic roles
2. **Seq2Seq** (2018-2020): Encoder-decoder neural models
3. **Transformer-based** (2020-present): BERT, T5, GPT for generation
4. **Hybrid** (current best): SRL for structure + LLM for quality

**How we use it**: Generate comprehension questions and assessments.

---

## Stage 1: Content Analysis

### Purpose

Analyze raw content to understand its characteristics before enrichment.

### Outputs

```python
@dataclass
class ContentAnalysis:
    # Readability metrics
    flesch_kincaid_grade: float
    dale_chall_score: float
    smog_index: float
    automated_readability_index: float

    # Structural metrics
    word_count: int
    sentence_count: int
    paragraph_count: int
    avg_sentence_length: float
    avg_word_length: float

    # Content metrics
    detected_language: str
    detected_domain: str  # e.g., "mathematics", "biology", "programming"
    formality_level: str  # formal, semi-formal, informal

    # Quality indicators
    has_headings: bool
    has_lists: bool
    has_code_blocks: bool
    has_equations: bool
    has_citations: bool

    # Estimated effort
    estimated_reading_time_minutes: int
    estimated_study_time_minutes: int

    # Recommendations
    target_audience: str  # elementary, middle-school, high-school, collegiate
    recommended_chunk_size: int
    complexity_warnings: List[str]
```

### Implementation

```python
class ContentAnalyzer:
    """
    Analyze raw content for enrichment planning.

    Uses established readability formulas and NLP analysis.
    """

    def __init__(self, nlp_model: str = "en_core_web_sm"):
        self.nlp = spacy.load(nlp_model)

    async def analyze(self, content: str) -> ContentAnalysis:
        # 1. Readability metrics (proven formulas)
        readability = self._compute_readability(content)

        # 2. Structural analysis (NLP)
        structure = self._analyze_structure(content)

        # 3. Domain detection (LLM-assisted)
        domain = await self._detect_domain(content)

        # 4. Quality indicators
        quality = self._assess_quality(content)

        # 5. Recommendations
        recommendations = self._generate_recommendations(
            readability, structure, domain, quality
        )

        return ContentAnalysis(
            **readability,
            **structure,
            **domain,
            **quality,
            **recommendations
        )

    def _compute_readability(self, content: str) -> dict:
        """Compute established readability metrics"""
        import textstat

        return {
            "flesch_kincaid_grade": textstat.flesch_kincaid_grade(content),
            "dale_chall_score": textstat.dale_chall_readability_score(content),
            "smog_index": textstat.smog_index(content),
            "automated_readability_index": textstat.automated_readability_index(content),
        }

    def _analyze_structure(self, content: str) -> dict:
        """Analyze structural characteristics"""
        doc = self.nlp(content)

        sentences = list(doc.sents)
        words = [token for token in doc if not token.is_punct]

        return {
            "word_count": len(words),
            "sentence_count": len(sentences),
            "paragraph_count": content.count('\n\n') + 1,
            "avg_sentence_length": len(words) / max(len(sentences), 1),
            "avg_word_length": sum(len(w.text) for w in words) / max(len(words), 1),
        }

    async def _detect_domain(self, content: str) -> dict:
        """Use LLM to detect content domain"""
        prompt = f"""Analyze this educational content and identify:
1. The primary subject domain (e.g., mathematics, biology, programming, history)
2. The formality level (formal, semi-formal, informal)
3. The detected language

Content (first 2000 chars):
{content[:2000]}

Respond in JSON format:
{{"domain": "...", "formality": "...", "language": "..."}}
"""
        response = await self.llm.generate(prompt)
        return json.loads(response)
```

### Domain-Specific Adaptations

| Domain | Special Handling |
|--------|-----------------|
| **Mathematics** | Detect equations, preserve notation, expand for speech |
| **Programming** | Identify code blocks, syntax highlighting, executable examples |
| **Science** | Extract vocabulary, link to standards (NGSS) |
| **History** | Timeline extraction, date normalization |
| **Language Arts** | Literary devices, vocabulary level |

---

## Stage 2: Structure Inference

### Purpose

Infer hierarchical structure from flat or minimally structured content.

### The Challenge

Input may be:
- Pure text with no headings
- Inconsistent heading levels
- Implicit structure (topic shifts without markers)
- Mixed formats (some sections structured, others not)

### Approach: Hybrid Inference

```
┌─────────────────────────────────────────────────────────────────┐
│                   STRUCTURE INFERENCE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. EXPLICIT MARKERS (if present)                              │
│     • HTML headings (<h1>, <h2>)                               │
│     • Markdown headings (#, ##)                                │
│     • Numbered sections (1., 1.1, 1.1.1)                       │
│                                                                 │
│  2. FORMATTING HEURISTICS                                       │
│     • Bold/caps text at paragraph start                        │
│     • Standalone short lines (potential headings)              │
│     • List introductions                                       │
│                                                                 │
│  3. SEMANTIC ANALYSIS (LLM)                                     │
│     • Topic shift detection                                    │
│     • Logical grouping inference                               │
│     • Hierarchy depth recommendation                           │
│                                                                 │
│  4. DOMAIN TEMPLATES                                            │
│     • Math: Concept → Definition → Theorem → Example → Practice│
│     • Science: Phenomenon → Explanation → Evidence → Application│
│     • Programming: Concept → Syntax → Example → Exercise       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Output: Proposed Structure

```python
@dataclass
class ProposedStructure:
    """Proposed hierarchical structure for content"""

    @dataclass
    class StructureNode:
        id: str
        title: str
        type: str  # module, topic, subtopic
        level: int  # 1, 2, 3...
        start_offset: int  # Character offset in source
        end_offset: int
        confidence: float  # 0.0-1.0
        inference_method: str  # explicit, heuristic, semantic
        children: List["StructureNode"]

    root_nodes: List[StructureNode]
    total_depth: int
    confidence_overall: float
    warnings: List[str]
    suggestions: List[str]
```

### LLM Prompt for Structure Inference

```python
STRUCTURE_INFERENCE_PROMPT = """You are an expert curriculum designer analyzing educational content to propose a hierarchical structure.

## Task
Analyze the following content and propose a hierarchical organization suitable for tutoring.

## Guidelines
1. Identify natural topic boundaries (where a new concept or theme begins)
2. Group related content together
3. Create hierarchy with 2-4 levels maximum
4. Each top-level section should be 5-15 minutes of learning content
5. Each subsection should be 2-5 minutes
6. Use descriptive titles that indicate the learning focus

## Content Type: {domain}
## Target Audience: {audience}
## Detected Reading Level: Grade {grade_level}

## Content to Analyze:
{content}

## Output Format
Respond with a JSON structure:
```json
{
  "proposed_structure": [
    {
      "title": "Section Title",
      "type": "module",
      "summary": "Brief description of what this section covers",
      "start_text": "First ~50 chars of this section",
      "children": [
        {
          "title": "Subsection Title",
          "type": "topic",
          "summary": "...",
          "start_text": "..."
        }
      ]
    }
  ],
  "rationale": "Explanation of why this structure was chosen",
  "alternative_structures": ["Brief description of other valid approaches"],
  "warnings": ["Any concerns about the content structure"]
}
```
"""
```

### Implementation

```python
class StructureInferencer:
    """Infer hierarchical structure from content"""

    async def infer_structure(
        self,
        content: str,
        analysis: ContentAnalysis
    ) -> ProposedStructure:

        # 1. Try explicit markers first
        explicit = self._extract_explicit_structure(content)
        if explicit.confidence_overall > 0.8:
            return explicit

        # 2. Apply formatting heuristics
        heuristic = self._apply_heuristics(content)

        # 3. Use LLM for semantic analysis
        semantic = await self._llm_structure_inference(
            content, analysis
        )

        # 4. Merge results with confidence weighting
        merged = self._merge_structures(
            explicit, heuristic, semantic
        )

        # 5. Apply domain template if applicable
        if analysis.detected_domain in self.domain_templates:
            merged = self._apply_domain_template(
                merged,
                self.domain_templates[analysis.detected_domain]
            )

        return merged

    def _extract_explicit_structure(self, content: str) -> ProposedStructure:
        """Extract structure from explicit markers (headings, numbers)"""
        import re

        nodes = []

        # Markdown headings
        heading_pattern = r'^(#{1,6})\s+(.+)$'
        for match in re.finditer(heading_pattern, content, re.MULTILINE):
            level = len(match.group(1))
            title = match.group(2).strip()
            nodes.append({
                "title": title,
                "level": level,
                "offset": match.start(),
                "inference_method": "explicit"
            })

        # HTML headings
        html_pattern = r'<h([1-6])[^>]*>(.+?)</h\1>'
        for match in re.finditer(html_pattern, content, re.IGNORECASE):
            level = int(match.group(1))
            title = re.sub(r'<[^>]+>', '', match.group(2)).strip()
            nodes.append({
                "title": title,
                "level": level,
                "offset": match.start(),
                "inference_method": "explicit"
            })

        # Numbered sections (1., 1.1, 1.1.1)
        number_pattern = r'^(\d+(?:\.\d+)*)\s+(.+)$'
        for match in re.finditer(number_pattern, content, re.MULTILINE):
            number = match.group(1)
            level = number.count('.') + 1
            title = match.group(2).strip()
            nodes.append({
                "title": title,
                "level": level,
                "offset": match.start(),
                "inference_method": "explicit"
            })

        return self._build_hierarchy(nodes)
```

---

## Stage 3: Content Segmentation

### Purpose

Divide content into appropriately-sized segments for conversational delivery.

### Segmentation Principles

1. **Semantic coherence**: Each segment should be about one idea
2. **Appropriate length**: 1-3 minutes of spoken content (~100-300 words)
3. **Natural boundaries**: End at sentence/paragraph boundaries
4. **Checkpoint opportunities**: Create natural places for comprehension checks

### Approach: Meta-Chunking

Based on the Meta-Chunking paper (2024), we use a dual-strategy approach:

```
┌─────────────────────────────────────────────────────────────────┐
│                    META-CHUNKING PIPELINE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SENTENCE BOUNDARY DETECTION                                 │
│     • spaCy sentence tokenizer                                  │
│     • Handle abbreviations, decimals, URLs                      │
│                                                                 │
│  2. PERPLEXITY-BASED SCORING                                    │
│     • Compute perplexity at each sentence boundary              │
│     • High perplexity = topic shift                             │
│                                                                 │
│  3. MARGIN SAMPLING                                              │
│     • Measure confidence drop between adjacent sentences        │
│     • Large margin = potential chunk boundary                   │
│                                                                 │
│  4. SEMANTIC SIMILARITY                                          │
│     • Compute embeddings for sentence groups                    │
│     • Low similarity = topic shift                              │
│                                                                 │
│  5. BOUNDARY VOTING                                              │
│     • Combine signals with learned weights                      │
│     • Threshold to select final boundaries                      │
│                                                                 │
│  6. CONSTRAINT SATISFACTION                                      │
│     • Enforce min/max segment size                              │
│     • Preserve paragraph structure where possible               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Output: Segmented Content

```python
@dataclass
class Segment:
    id: str
    text: str
    type: str  # narrative, definition, example, transition, summary

    # Position
    start_offset: int
    end_offset: int

    # Metrics
    word_count: int
    estimated_duration_seconds: int

    # Segmentation metadata
    boundary_confidence: float
    boundary_signals: Dict[str, float]  # perplexity, margin, similarity

    # Tutoring hints
    suggested_stopping_point: bool
    stopping_point_type: Optional[str]  # check_understanding, take_break, etc.
    key_concepts: List[str]

@dataclass
class SegmentedContent:
    segments: List[Segment]
    total_segments: int
    avg_segment_length: float
    segmentation_quality_score: float
```

### Implementation

```python
class ContentSegmenter:
    """Segment content using meta-chunking approach"""

    def __init__(self):
        self.nlp = spacy.load("en_core_web_sm")
        self.embedder = SentenceTransformer("all-MiniLM-L6-v2")

        # Configurable parameters
        self.min_segment_words = 50
        self.max_segment_words = 300
        self.target_segment_words = 150

    async def segment(
        self,
        content: str,
        structure: ProposedStructure
    ) -> SegmentedContent:

        # 1. Tokenize into sentences
        doc = self.nlp(content)
        sentences = [sent.text.strip() for sent in doc.sents]

        # 2. Compute boundary scores
        perplexity_scores = await self._compute_perplexity_scores(sentences)
        margin_scores = self._compute_margin_scores(sentences)
        similarity_scores = self._compute_similarity_scores(sentences)

        # 3. Combine scores
        combined_scores = self._combine_boundary_scores(
            perplexity_scores,
            margin_scores,
            similarity_scores
        )

        # 4. Select boundaries
        boundaries = self._select_boundaries(
            combined_scores,
            sentences
        )

        # 5. Build segments
        segments = self._build_segments(sentences, boundaries)

        # 6. Classify segment types
        segments = await self._classify_segments(segments)

        # 7. Identify stopping points
        segments = self._identify_stopping_points(segments)

        return SegmentedContent(
            segments=segments,
            total_segments=len(segments),
            avg_segment_length=sum(s.word_count for s in segments) / len(segments),
            segmentation_quality_score=self._compute_quality_score(segments)
        )

    def _compute_similarity_scores(self, sentences: List[str]) -> List[float]:
        """Compute semantic similarity between adjacent sentence groups"""
        window_size = 3
        scores = []

        embeddings = self.embedder.encode(sentences)

        for i in range(len(sentences) - 1):
            # Get embeddings for sentences before and after boundary
            before_start = max(0, i - window_size + 1)
            before_emb = embeddings[before_start:i+1].mean(axis=0)

            after_end = min(len(sentences), i + window_size + 1)
            after_emb = embeddings[i+1:after_end].mean(axis=0)

            # Cosine similarity (1 - similarity = boundary score)
            similarity = np.dot(before_emb, after_emb) / (
                np.linalg.norm(before_emb) * np.linalg.norm(after_emb)
            )
            scores.append(1 - similarity)

        return scores

    def _identify_stopping_points(self, segments: List[Segment]) -> List[Segment]:
        """Identify natural stopping points for comprehension checks"""

        for i, segment in enumerate(segments):
            # Criteria for stopping points
            is_stopping = False
            stop_type = None

            # After definitions
            if segment.type == "definition":
                is_stopping = True
                stop_type = "check_understanding"

            # After complex explanations (high word count)
            elif segment.word_count > 200:
                is_stopping = True
                stop_type = "check_understanding"

            # At natural break points (end of subsection)
            elif self._is_section_boundary(segment, segments, i):
                is_stopping = True
                stop_type = "section_complete"

            # After examples
            elif segment.type == "example":
                is_stopping = True
                stop_type = "apply_knowledge"

            segment.suggested_stopping_point = is_stopping
            segment.stopping_point_type = stop_type

        return segments
```

---

## Stage 4: Learning Objective Extraction

### Purpose

Extract or generate learning objectives aligned to Bloom's Taxonomy.

### Approach: Hybrid Extraction + Generation

```
┌─────────────────────────────────────────────────────────────────┐
│              LEARNING OBJECTIVE EXTRACTION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. EXPLICIT EXTRACTION                                         │
│     • "By the end of this lesson, you will..."                 │
│     • "Learning objectives:"                                   │
│     • "Students will be able to..."                            │
│                                                                 │
│  2. VERB-BASED INFERENCE                                        │
│     • Identify Bloom's taxonomy verbs in content               │
│     • Map to cognitive levels                                  │
│                                                                 │
│  3. CONCEPT-BASED GENERATION                                    │
│     • Extract key concepts                                     │
│     • Generate objectives at multiple Bloom levels             │
│                                                                 │
│  4. STANDARDS ALIGNMENT                                         │
│     • Match to Common Core, NGSS, etc.                         │
│     • Inherit objectives from aligned standards                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Output: Learning Objectives

```python
@dataclass
class LearningObjective:
    id: str
    text: str

    # Bloom's taxonomy
    bloom_level: str  # remember, understand, apply, analyze, evaluate, create
    bloom_verb: str   # The action verb used

    # Source
    source: str  # extracted, inferred, generated
    confidence: float

    # Content mapping
    relevant_segments: List[str]  # Segment IDs

    # Standards alignment
    alignments: List[Dict]  # Standard framework, code, description
```

### LLM Prompt for Objective Generation

```python
OBJECTIVE_GENERATION_PROMPT = """You are an expert instructional designer creating learning objectives for educational content.

## Task
Generate learning objectives for the following content. Create objectives at multiple Bloom's taxonomy levels.

## Bloom's Taxonomy Levels (with example verbs)
1. Remember: define, list, recall, identify, name
2. Understand: explain, describe, summarize, interpret, classify
3. Apply: use, solve, demonstrate, calculate, apply
4. Analyze: compare, contrast, examine, differentiate, analyze
5. Evaluate: judge, assess, justify, critique, evaluate
6. Create: design, construct, develop, formulate, create

## Guidelines
1. Use measurable action verbs (not "understand" alone - use "explain", "describe")
2. Be specific about what the learner will do
3. Align to the content's complexity (don't require "create" for basic content)
4. Include at least one objective per major concept
5. Write objectives from the learner's perspective ("You will be able to...")

## Target Audience: {audience}
## Content Domain: {domain}
## Content:
{content}

## Output Format
```json
{
  "objectives": [
    {
      "text": "Explain the process of cellular respiration",
      "bloom_level": "understand",
      "bloom_verb": "explain",
      "key_concept": "cellular respiration",
      "rationale": "Core concept requiring conceptual understanding"
    }
  ]
}
```
"""
```

### Implementation

```python
class ObjectiveExtractor:
    """Extract and generate learning objectives"""

    # Bloom's taxonomy verb patterns
    BLOOM_PATTERNS = {
        "remember": [
            r"\b(define|list|recall|identify|name|recognize|state|describe)\b"
        ],
        "understand": [
            r"\b(explain|describe|summarize|interpret|classify|compare|contrast)\b"
        ],
        "apply": [
            r"\b(use|solve|demonstrate|calculate|apply|implement|execute)\b"
        ],
        "analyze": [
            r"\b(analyze|examine|differentiate|distinguish|investigate)\b"
        ],
        "evaluate": [
            r"\b(evaluate|judge|assess|justify|critique|defend)\b"
        ],
        "create": [
            r"\b(create|design|construct|develop|formulate|propose)\b"
        ]
    }

    async def extract_objectives(
        self,
        content: str,
        segments: SegmentedContent,
        analysis: ContentAnalysis
    ) -> List[LearningObjective]:

        objectives = []

        # 1. Try explicit extraction
        explicit = self._extract_explicit_objectives(content)
        objectives.extend(explicit)

        # 2. Infer from content verbs
        inferred = self._infer_from_verbs(content, segments)
        objectives.extend(inferred)

        # 3. Generate for key concepts
        concepts = self._extract_key_concepts(content, segments)
        generated = await self._generate_objectives(
            content, concepts, analysis
        )
        objectives.extend(generated)

        # 4. Deduplicate and rank
        objectives = self._deduplicate_objectives(objectives)

        # 5. Align to standards if possible
        objectives = await self._align_to_standards(
            objectives, analysis.detected_domain
        )

        return objectives

    def _extract_explicit_objectives(self, content: str) -> List[LearningObjective]:
        """Extract explicitly stated objectives"""
        import re

        objectives = []

        # Patterns for explicit objectives
        patterns = [
            r"(?:learning objectives?|goals?|outcomes?)[\s:]+(.+?)(?:\n\n|\Z)",
            r"(?:by the end|after completing).+(?:you will|students will|learners will)\s+(.+?)(?:\.|$)",
            r"(?:students?|learners?|you) will be able to\s+(.+?)(?:\.|$)",
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, content, re.IGNORECASE | re.DOTALL):
                text = match.group(1).strip()
                # Split if multiple objectives
                items = re.split(r'[\n•\-\d\.]+', text)
                for item in items:
                    item = item.strip()
                    if len(item) > 10:  # Filter noise
                        bloom = self._classify_bloom_level(item)
                        objectives.append(LearningObjective(
                            id=self._generate_id(),
                            text=item,
                            bloom_level=bloom["level"],
                            bloom_verb=bloom["verb"],
                            source="extracted",
                            confidence=0.9,
                            relevant_segments=[],
                            alignments=[]
                        ))

        return objectives

    def _classify_bloom_level(self, text: str) -> Dict[str, str]:
        """Classify Bloom's level from objective text"""
        import re

        text_lower = text.lower()

        for level, patterns in self.BLOOM_PATTERNS.items():
            for pattern in patterns:
                match = re.search(pattern, text_lower)
                if match:
                    return {"level": level, "verb": match.group(1)}

        # Default to "understand" if no verb detected
        return {"level": "understand", "verb": "understand"}
```

---

## Stage 5: Assessment Generation

### Purpose

Generate comprehension questions and assessments at multiple cognitive levels.

### Approach: SRL + LLM Hybrid

Based on research, the best results come from combining:
1. **Semantic Role Labeling (SRL)**: Provides structured understanding of WHO/WHAT/WHERE
2. **LLM Generation**: Creates natural, varied questions

```
┌─────────────────────────────────────────────────────────────────┐
│                  ASSESSMENT GENERATION                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INPUT: Segment + Key Concepts + Learning Objectives            │
│                                                                 │
│  1. SEMANTIC ROLE ANALYSIS                                      │
│     • Extract: Agent, Action, Patient, Location, Time          │
│     • Generate question templates                               │
│                                                                 │
│  2. QUESTION TYPE SELECTION                                     │
│     • Match Bloom level to question type                       │
│     • Remember → Multiple choice, True/False                   │
│     • Understand → Short answer, Explain                       │
│     • Apply → Problem solving, Scenario                        │
│     • Analyze → Compare/contrast, Case study                   │
│                                                                 │
│  3. LLM QUESTION GENERATION                                     │
│     • Generate questions from templates                         │
│     • Create distractors for multiple choice                   │
│     • Generate feedback for answers                            │
│                                                                 │
│  4. QUALITY FILTERING                                           │
│     • Check answerability from content                         │
│     • Validate difficulty matches target                       │
│     • Remove duplicates and near-duplicates                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Output: Generated Assessments

```python
@dataclass
class GeneratedAssessment:
    id: str
    type: str  # choice, text-entry, self-assessment
    prompt: str

    # For multiple choice
    choices: Optional[List[Dict]]  # {id, text, correct, distractor_type}

    # For text entry
    expected_response: Optional[str]
    acceptable_variations: Optional[List[str]]

    # Metadata
    bloom_level: str
    difficulty: str  # easy, medium, hard
    source_segment: str
    learning_objective: Optional[str]

    # Feedback
    feedback_correct: str
    feedback_incorrect: str
    hints: List[str]

    # Quality metrics
    answerability_score: float  # Can this be answered from content?
    distractor_quality: Optional[float]  # For MC: Are distractors plausible?
```

### LLM Prompts for Question Generation

```python
MULTIPLE_CHOICE_PROMPT = """Generate a multiple choice question based on the following content.

## Content
{content}

## Key Concept to Test
{concept}

## Target Bloom Level
{bloom_level}

## Guidelines
1. The correct answer must be unambiguously supported by the content
2. Create 3-4 plausible distractors that:
   - Are similar in length and style to the correct answer
   - Represent common misconceptions or partial understanding
   - Are clearly wrong to someone who understands the material
3. Avoid "all of the above" or "none of the above"
4. The question stem should be clear and complete

## Output Format
```json
{
  "question": "What is the primary function of...",
  "choices": [
    {"id": "a", "text": "...", "correct": true, "why_wrong": null},
    {"id": "b", "text": "...", "correct": false, "why_wrong": "This is a common misconception because..."},
    {"id": "c", "text": "...", "correct": false, "why_wrong": "This confuses X with Y"},
    {"id": "d", "text": "...", "correct": false, "why_wrong": "This is partially true but missing..."}
  ],
  "feedback_correct": "Correct! The answer is A because...",
  "feedback_incorrect": "Not quite. Remember that...",
  "hint": "Think about what happens when..."
}
```
"""

SHORT_ANSWER_PROMPT = """Generate a short answer question based on the following content.

## Content
{content}

## Key Concept to Test
{concept}

## Target Bloom Level
{bloom_level}

## Guidelines
1. Ask a question that requires explanation, not just recall
2. The answer should be 1-3 sentences
3. Provide a model answer and acceptable variations
4. Include scaffolding hints for learners who struggle

## Output Format
```json
{
  "question": "Explain why...",
  "model_answer": "A complete answer would explain...",
  "key_points": ["Must mention X", "Should reference Y"],
  "acceptable_variations": ["Could also mention...", "Alternative phrasing..."],
  "feedback_rubric": {
    "full_credit": "Answer includes all key points",
    "partial_credit": "Answer mentions some key points",
    "no_credit": "Answer misses the main concept"
  },
  "hints": [
    "Think about what happens during...",
    "Consider the relationship between..."
  ]
}
```
"""
```

### Implementation

```python
class AssessmentGenerator:
    """Generate assessments using SRL + LLM hybrid approach"""

    def __init__(self):
        # Load SRL model (AllenNLP or spaCy)
        self.srl_predictor = self._load_srl_model()

    async def generate_assessments(
        self,
        segments: SegmentedContent,
        objectives: List[LearningObjective],
        analysis: ContentAnalysis
    ) -> List[GeneratedAssessment]:

        assessments = []

        for segment in segments.segments:
            # Skip non-content segments
            if segment.type in ["transition", "summary"]:
                continue

            # 1. Extract semantic roles
            roles = self._extract_semantic_roles(segment.text)

            # 2. Generate questions based on roles
            role_questions = self._generate_from_roles(roles, segment)

            # 3. Match objectives to segment
            relevant_objectives = self._match_objectives(
                segment, objectives
            )

            # 4. Generate LLM questions for objectives
            for obj in relevant_objectives:
                llm_questions = await self._generate_llm_questions(
                    segment, obj, analysis
                )
                assessments.extend(llm_questions)

            # 5. Validate and filter
            assessments = self._validate_assessments(assessments, segments)

        # 6. Balance question types and difficulty
        assessments = self._balance_assessments(assessments)

        return assessments

    def _extract_semantic_roles(self, text: str) -> List[Dict]:
        """Extract semantic roles using SRL"""
        # Returns: {"verb": "produces", "ARG0": "mitochondria", "ARG1": "ATP"}
        result = self.srl_predictor.predict(sentence=text)
        return result.get("verbs", [])

    def _generate_from_roles(
        self,
        roles: List[Dict],
        segment: Segment
    ) -> List[GeneratedAssessment]:
        """Generate questions from semantic roles"""
        questions = []

        for role_set in roles:
            verb = role_set.get("verb", "")
            args = role_set.get("tags", [])

            # WHO questions (ARG0 = Agent)
            if "ARG0" in str(args):
                agent = self._extract_arg(role_set, "ARG0")
                if agent:
                    questions.append(self._create_who_question(
                        verb, agent, segment
                    ))

            # WHAT questions (ARG1 = Patient)
            if "ARG1" in str(args):
                patient = self._extract_arg(role_set, "ARG1")
                if patient:
                    questions.append(self._create_what_question(
                        verb, patient, segment
                    ))

            # WHERE questions (ARGM-LOC)
            if "ARGM-LOC" in str(args):
                location = self._extract_arg(role_set, "ARGM-LOC")
                if location:
                    questions.append(self._create_where_question(
                        verb, location, segment
                    ))

        return [q for q in questions if q is not None]
```

---

## Stage 6: Tutoring Enhancement

### Purpose

Add tutoring-specific elements that make content effective for conversational AI.

### Enhancements

```
┌─────────────────────────────────────────────────────────────────┐
│                  TUTORING ENHANCEMENTS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SPOKEN TEXT GENERATION                                      │
│     • Expand abbreviations                                      │
│     • Spell out symbols/equations                              │
│     • Add natural pauses (punctuation)                         │
│     • Simplify complex sentences                               │
│                                                                 │
│  2. ALTERNATIVE EXPLANATIONS                                    │
│     • Simpler version (lower grade level)                      │
│     • Technical version (more precise)                         │
│     • Analogy version (real-world comparison)                  │
│                                                                 │
│  3. MISCONCEPTION IDENTIFICATION                                │
│     • Common errors for this topic                             │
│     • Trigger phrases ("students often think...")              │
│     • Remediation paths                                        │
│                                                                 │
│  4. STOPPING POINT CONFIGURATION                                │
│     • Comprehension check questions                            │
│     • Branching based on understanding                         │
│     • Recovery prompts for confusion                           │
│                                                                 │
│  5. GLOSSARY EXTRACTION                                         │
│     • Technical terms                                          │
│     • Contextual definitions                                   │
│     • Pronunciation guides                                     │
│                                                                 │
│  6. EXAMPLE GENERATION                                          │
│     • Worked examples                                          │
│     • Counter-examples                                         │
│     • Real-world applications                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### LLM Prompts for Enhancement

```python
ALTERNATIVE_EXPLANATION_PROMPT = """Generate alternative explanations for the following concept.

## Original Explanation
{original}

## Target Audience
{audience}

## Task
Create three alternative explanations:
1. **Simpler**: For someone 2-3 grade levels below the target
2. **Technical**: More precise, for advanced learners
3. **Analogy**: Using a real-world comparison

## Output Format
```json
{
  "simpler": {
    "text": "...",
    "grade_level": "3rd grade",
    "key_simplifications": ["Removed jargon", "Used shorter sentences"]
  },
  "technical": {
    "text": "...",
    "additional_details": ["Added precise terminology", "Included edge cases"]
  },
  "analogy": {
    "text": "...",
    "comparison_to": "How a factory assembly line works",
    "mapping": {"concept_x": "assembly line", "concept_y": "workers"}
  }
}
```
"""

MISCONCEPTION_PROMPT = """Identify common misconceptions about the following concept.

## Concept
{concept}

## Content Context
{context}

## Target Audience
{audience}

## Task
Identify 2-3 common misconceptions that learners have about this topic.

## Output Format
```json
{
  "misconceptions": [
    {
      "description": "What the learner incorrectly believes",
      "trigger_phrases": ["If the learner says this...", "Or this..."],
      "why_wrong": "Explanation of why this is incorrect",
      "remediation": "How to correct this misunderstanding",
      "correct_understanding": "What they should understand instead"
    }
  ]
}
```
"""

GLOSSARY_EXTRACTION_PROMPT = """Extract technical terms and definitions from the following content.

## Content
{content}

## Task
Identify technical terms that should be in a glossary.

## Guidelines
1. Include terms that might be unfamiliar to the target audience
2. Provide contextual definitions (how the term is used HERE)
3. Include pronunciation for difficult words
4. Note related terms

## Output Format
```json
{
  "terms": [
    {
      "term": "mitochondria",
      "definition": "Organelles that produce energy for the cell",
      "pronunciation": "my-toh-KON-dree-uh",
      "context": "In this lesson, we focus on mitochondria's role in ATP production",
      "related_terms": ["ATP", "cellular respiration", "organelle"]
    }
  ]
}
```
"""
```

### Implementation

```python
class TutoringEnhancer:
    """Add tutoring-specific elements to curriculum"""

    async def enhance(
        self,
        segments: SegmentedContent,
        objectives: List[LearningObjective],
        assessments: List[GeneratedAssessment],
        analysis: ContentAnalysis
    ) -> EnhancedCurriculum:

        enhanced_segments = []
        glossary = []

        for segment in segments.segments:
            enhanced = await self._enhance_segment(segment, analysis)
            enhanced_segments.append(enhanced)

            # Extract glossary terms
            terms = await self._extract_glossary(segment, analysis)
            glossary.extend(terms)

        # Identify misconceptions across content
        misconceptions = await self._identify_misconceptions(
            segments, analysis
        )

        # Generate examples where needed
        examples = await self._generate_examples(
            segments, objectives, analysis
        )

        # Configure stopping points
        stopping_points = self._configure_stopping_points(
            enhanced_segments, assessments
        )

        return EnhancedCurriculum(
            segments=enhanced_segments,
            objectives=objectives,
            assessments=assessments,
            glossary=self._deduplicate_glossary(glossary),
            misconceptions=misconceptions,
            examples=examples,
            stopping_points=stopping_points
        )

    async def _enhance_segment(
        self,
        segment: Segment,
        analysis: ContentAnalysis
    ) -> EnhancedSegment:
        """Add tutoring elements to a segment"""

        # 1. Generate spoken text
        spoken = self._generate_spoken_text(segment.text, analysis)

        # 2. Generate alternative explanations for key content
        alternatives = None
        if segment.type in ["definition", "explanation"]:
            alternatives = await self._generate_alternatives(
                segment.text, analysis
            )

        # 3. Add speaking notes
        speaking_notes = self._generate_speaking_notes(segment, analysis)

        return EnhancedSegment(
            **segment.__dict__,
            spoken_text=spoken,
            alternatives=alternatives,
            speaking_notes=speaking_notes
        )

    def _generate_spoken_text(self, text: str, analysis: ContentAnalysis) -> str:
        """Convert text to TTS-friendly format"""
        import re

        result = text

        # Expand abbreviations
        abbreviations = {
            r'\be\.g\.\b': 'for example',
            r'\bi\.e\.\b': 'that is',
            r'\betc\.\b': 'and so on',
            r'\bvs\.\b': 'versus',
            r'\bFig\.\b': 'Figure',
            r'\bEq\.\b': 'Equation',
            r'\bDr\.\b': 'Doctor',
            r'\bMr\.\b': 'Mister',
            r'\bMs\.\b': 'Miss',
        }
        for pattern, replacement in abbreviations.items():
            result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)

        # Spell out mathematical symbols
        if analysis.has_equations:
            symbols = {
                '=': ' equals ',
                '+': ' plus ',
                '-': ' minus ',
                '×': ' times ',
                '÷': ' divided by ',
                '<': ' is less than ',
                '>': ' is greater than ',
                '≤': ' is less than or equal to ',
                '≥': ' is greater than or equal to ',
                '%': ' percent',
                '^2': ' squared',
                '^3': ' cubed',
            }
            for symbol, replacement in symbols.items():
                result = result.replace(symbol, replacement)

        # Add pauses for complex sentences
        result = re.sub(r'([.!?])\s+', r'\1 ... ', result)

        return result.strip()
```

---

## Stage 7: Knowledge Graph Construction

### Purpose

Build a knowledge graph connecting concepts, prerequisites, and relationships.

### Graph Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    KNOWLEDGE GRAPH                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  NODE TYPES                                                     │
│  • Concept: Key ideas in the curriculum                        │
│  • Topic: Sections of content                                  │
│  • Assessment: Quiz questions                                  │
│  • Resource: External references                               │
│                                                                 │
│  EDGE TYPES                                                     │
│  • PREREQUISITE_OF: A must be learned before B                 │
│  • RELATED_TO: A and B are conceptually similar                │
│  • PART_OF: A is a component of B                              │
│  • ASSESSES: Assessment A tests Concept B                      │
│  • TEACHES: Topic A covers Concept B                           │
│  • SAME_AS: Wikidata entity alignment                          │
│                                                                 │
│  EXAMPLE                                                        │
│                                                                 │
│    [Algebra] ──PREREQUISITE_OF──► [Linear Equations]           │
│        │                               │                        │
│        └──RELATED_TO──► [Arithmetic]   │                        │
│                                        ▼                        │
│                              [Quadratic Equations]              │
│                                        │                        │
│                              ──SAME_AS──► wd:Q123456           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Entity Linking

Connect concepts to external knowledge bases:

| Knowledge Base | Use Case | Tool |
|----------------|----------|------|
| **Wikidata** | General concepts | spaCy Entity Linker |
| **DBpedia** | Encyclopedia facts | DBpedia Spotlight |
| **Common Core** | Standards alignment | Custom matcher |
| **NGSS** | Science standards | Custom matcher |

### Implementation

```python
class KnowledgeGraphBuilder:
    """Build knowledge graph from enriched curriculum"""

    def __init__(self):
        self.entity_linker = EntityLinker()

    async def build_graph(
        self,
        curriculum: EnhancedCurriculum
    ) -> KnowledgeGraph:

        graph = KnowledgeGraph()

        # 1. Extract concepts from content
        concepts = await self._extract_concepts(curriculum)
        for concept in concepts:
            graph.add_node(concept)

        # 2. Link to external knowledge bases
        for concept in concepts:
            wikidata_id = await self.entity_linker.link_to_wikidata(
                concept.text
            )
            if wikidata_id:
                graph.add_edge(concept.id, wikidata_id, "SAME_AS")

        # 3. Infer prerequisite relationships
        prerequisites = await self._infer_prerequisites(concepts)
        for prereq in prerequisites:
            graph.add_edge(
                prereq["from"],
                prereq["to"],
                "PREREQUISITE_OF",
                confidence=prereq["confidence"]
            )

        # 4. Compute semantic similarity for RELATED_TO
        similarities = self._compute_similarities(concepts)
        for sim in similarities:
            if sim["score"] > 0.7:
                graph.add_edge(
                    sim["concept_a"],
                    sim["concept_b"],
                    "RELATED_TO",
                    weight=sim["score"]
                )

        # 5. Link assessments to concepts
        for assessment in curriculum.assessments:
            for concept in assessment.key_concepts:
                graph.add_edge(
                    assessment.id,
                    concept,
                    "ASSESSES"
                )

        # 6. Generate learning paths
        paths = self._generate_learning_paths(graph)
        graph.metadata["learning_paths"] = paths

        return graph

    async def _infer_prerequisites(
        self,
        concepts: List[Concept]
    ) -> List[Dict]:
        """Use LLM to infer prerequisite relationships"""

        prompt = f"""Given these concepts from an educational curriculum, identify prerequisite relationships.

## Concepts
{[c.text for c in concepts]}

## Task
For each concept, identify which other concepts (if any) should be learned first.

## Guidelines
1. Only include strong prerequisite relationships
2. Consider logical dependencies (can't understand B without A)
3. Avoid circular dependencies
4. Rate confidence (0.0-1.0)

## Output Format
```json
{{
  "prerequisites": [
    {{"from": "Concept A", "to": "Concept B", "confidence": 0.9, "reason": "..."}}
  ]
}}
```
"""
        response = await self.llm.generate(prompt)
        return json.loads(response)["prerequisites"]
```

---

## LLM Prompt Engineering

### CO-STAR Framework

All LLM prompts in this pipeline follow the CO-STAR framework:

| Component | Description | Example |
|-----------|-------------|---------|
| **C**ontext | Background information | "You are analyzing 8th-grade science content" |
| **O**bjective | What to accomplish | "Generate comprehension questions" |
| **S**tyle | Writing style | "Use age-appropriate language" |
| **T**one | Attitude | "Encouraging and supportive" |
| **A**ction | Specific steps | "1. Read the content, 2. Identify key concepts" |
| **R**esult | Expected output | "Return JSON with questions and answers" |

### Prompt Templates

All prompts are stored as templates with placeholders:

```python
# prompts/assessment_generation.py

PROMPT_TEMPLATES = {
    "multiple_choice": {
        "system": """You are an expert educational assessment designer.
Your task is to create high-quality multiple choice questions that test understanding, not just recall.""",

        "user": """## Context
Content domain: {domain}
Target audience: {audience}
Bloom's level: {bloom_level}

## Content
{content}

## Objective
Generate a multiple choice question testing the concept: {concept}

## Style
- Age-appropriate language for {audience}
- Clear, unambiguous question stem
- Plausible distractors based on common misconceptions

## Output Format
{output_schema}
""",
        "output_schema": {
            "type": "object",
            "properties": {
                "question": {"type": "string"},
                "choices": {"type": "array"},
                "correct_answer": {"type": "string"},
                "explanation": {"type": "string"}
            }
        }
    }
}
```

### Chain-of-Thought for Complex Tasks

For complex reasoning tasks (prerequisite inference, structure detection), use Chain-of-Thought:

```python
COT_PREREQUISITE_PROMPT = """Analyze the prerequisite relationships between these concepts.

## Concepts
{concepts}

## Think through this step by step:

1. **Identify core concepts**: Which concepts are foundational?
   - List concepts that don't depend on others...

2. **Map dependencies**: For each concept, what must be understood first?
   - Consider: Can a student understand Concept B without knowing Concept A?
   - Look for: definitions that reference other terms, skills that build on others

3. **Check for cycles**: Are there any circular dependencies?
   - If A requires B and B requires A, one relationship is probably wrong

4. **Assign confidence**: How sure are you about each relationship?
   - High (0.9+): Clear logical dependency
   - Medium (0.7-0.9): Strong correlation, likely dependency
   - Low (<0.7): Possible relationship, needs verification

## Final Answer
Based on this analysis, here are the prerequisite relationships:
{output_format}
"""
```

---

## Quality Assurance

### Automated Quality Checks

```python
class QualityChecker:
    """Validate enrichment quality"""

    def check_all(self, curriculum: EnhancedCurriculum) -> QualityReport:
        checks = [
            self._check_segment_length(),
            self._check_objective_coverage(),
            self._check_assessment_answerability(),
            self._check_glossary_completeness(),
            self._check_spoken_text_quality(),
            self._check_structure_depth(),
        ]

        return QualityReport(
            overall_score=self._compute_overall(checks),
            checks=checks,
            recommendations=self._generate_recommendations(checks)
        )

    def _check_segment_length(self) -> QualityCheck:
        """Verify segments are appropriate length"""
        issues = []
        for seg in self.curriculum.segments:
            if seg.word_count < 30:
                issues.append(f"Segment {seg.id} too short ({seg.word_count} words)")
            elif seg.word_count > 400:
                issues.append(f"Segment {seg.id} too long ({seg.word_count} words)")

        return QualityCheck(
            name="segment_length",
            passed=len(issues) == 0,
            score=1.0 - (len(issues) / len(self.curriculum.segments)),
            issues=issues
        )

    def _check_assessment_answerability(self) -> QualityCheck:
        """Verify assessments can be answered from content"""
        issues = []

        for assessment in self.curriculum.assessments:
            # Check if answer is in content
            if not self._answer_in_content(assessment):
                issues.append(
                    f"Assessment {assessment.id} may not be answerable from content"
                )

        return QualityCheck(
            name="assessment_answerability",
            passed=len(issues) == 0,
            score=1.0 - (len(issues) / len(self.curriculum.assessments)),
            issues=issues
        )
```

### Human Review Integration

The pipeline produces a **review manifest** for human editors:

```python
@dataclass
class ReviewManifest:
    """Items flagged for human review"""

    # Structure decisions
    structure_proposals: List[Dict]  # Alternative structures considered

    # Low-confidence items
    low_confidence_segments: List[Segment]  # Boundary confidence < 0.7
    low_confidence_objectives: List[LearningObjective]  # Source = "generated", confidence < 0.8
    low_confidence_assessments: List[GeneratedAssessment]  # Answerability < 0.8

    # Generated content
    generated_alternatives: List[Dict]  # Alternative explanations to verify
    generated_misconceptions: List[Dict]  # Misconceptions to validate

    # Knowledge graph
    uncertain_prerequisites: List[Dict]  # Prerequisite relationships to confirm
    unlinked_concepts: List[str]  # Concepts not linked to Wikidata

    # Quality flags
    quality_issues: List[str]  # From QualityChecker
```

---

## Human-in-the-Loop Editor

### Editor Interface (Web-Based)

The enrichment pipeline produces UMCF that can be reviewed and edited:

```
┌─────────────────────────────────────────────────────────────────┐
│                     CURRICULUM EDITOR                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  STRUCTURE VIEW                    [Propose Alternative]  │  │
│  │                                                          │  │
│  │  📁 Module 1: Introduction                              │  │
│  │    📄 Topic 1.1: Basic Concepts ⚠️ (low confidence)     │  │
│  │    📄 Topic 1.2: Key Terms                              │  │
│  │  📁 Module 2: Core Content                              │  │
│  │    ...                                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  SEGMENT EDITOR                                          │  │
│  │                                                          │  │
│  │  Original Text:                                         │  │
│  │  [The mitochondria produces ATP through...]             │  │
│  │                                                          │  │
│  │  Spoken Text: ✏️ [Edit]                                 │  │
│  │  [The mitochondria produces A T P through...]           │  │
│  │                                                          │  │
│  │  Stopping Point: ☑️ [Check Understanding]               │  │
│  │                                                          │  │
│  │  Alternative Explanations:                              │  │
│  │  [Simpler ▼] [Technical ▼] [Analogy ▼]                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ASSESSMENTS                        [+ Add Assessment]   │  │
│  │                                                          │  │
│  │  Q1: What is the function of mitochondria? ✅           │  │
│  │      Type: Multiple Choice | Bloom: Remember            │  │
│  │                                                          │  │
│  │  Q2: Explain why ATP is important... ⚠️                 │  │
│  │      ⚠️ Low answerability score (0.65)                  │  │
│  │      [Edit] [Regenerate] [Delete]                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  KNOWLEDGE GRAPH                   [View Full Graph]     │  │
│  │                                                          │  │
│  │  Prerequisites (confirm):                               │  │
│  │  ☑️ Cells → Organelles (confidence: 0.95)               │  │
│  │  ⬜ Atoms → Molecules (confidence: 0.72) [Confirm?]     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  [Save Draft]  [Export UMCF]  [Publish]                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Edit Actions

| Action | Effect |
|--------|--------|
| **Approve** | Mark AI-generated item as verified |
| **Edit** | Modify AI-generated content |
| **Regenerate** | Request new AI generation with feedback |
| **Delete** | Remove item |
| **Split** | Divide segment into multiple |
| **Merge** | Combine segments |
| **Reorder** | Change sequence |
| **Add** | Create new item manually |

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

1. **Content Analysis (Stage 1)**
   - Integrate py-readability-metrics
   - Implement spaCy-based structural analysis
   - Create LLM domain detection prompt

2. **Basic Segmentation (Stage 3)**
   - Implement sentence tokenization
   - Add similarity-based chunking
   - Enforce min/max constraints

### Phase 2: Core Enrichment (Weeks 3-4)

3. **Structure Inference (Stage 2)**
   - Explicit marker extraction
   - LLM-based semantic inference
   - Domain template application

4. **Objective Extraction (Stage 4)**
   - Explicit extraction patterns
   - Bloom's verb classification
   - LLM objective generation

### Phase 3: Assessment & Tutoring (Weeks 5-6)

5. **Assessment Generation (Stage 5)**
   - SRL integration (AllenNLP)
   - Multiple choice generation
   - Short answer generation

6. **Tutoring Enhancement (Stage 6)**
   - Spoken text conversion
   - Alternative explanation generation
   - Misconception identification

### Phase 4: Knowledge & Quality (Weeks 7-8)

7. **Knowledge Graph (Stage 7)**
   - Concept extraction
   - Entity linking (Wikidata)
   - Prerequisite inference

8. **Quality Assurance**
   - Automated quality checks
   - Review manifest generation
   - Editor integration

### Phase 5: Integration (Weeks 9-10)

9. **Pipeline Orchestration**
   - Stage coordination
   - Error handling
   - Progress tracking

10. **Web Editor**
    - Review interface
    - Edit capabilities
    - Export functionality

---

## Appendix: Research References

### Pre-AI Foundations

| Topic | Source | Key Contribution |
|-------|--------|------------------|
| Readability | Flesch (1948), Dale-Chall (1995) | Validated formulas |
| Text Segmentation | Hearst (1997) - TextTiling | Lexical cohesion |
| SRL | Palmer et al. (2005) - PropBank | Semantic role annotation |
| Bloom's Taxonomy | Anderson & Krathwohl (2001) | Revised taxonomy |
| Question Generation | Heilman (2011) | Rule-based AQG |

### AI-Powered Approaches

| Topic | Source | Key Contribution |
|-------|--------|------------------|
| Curriculum Generation | COGENT (Liu et al., 2025) | Curriculum-oriented LLM |
| Meta-Chunking | arxiv:2410.12788 (2024) | Perplexity-based segmentation |
| Educational KG | EduKG, CourseMapper | Large-scale KG construction |
| AQG with LLMs | Multiple (2022-2024) | Transformer-based generation |
| Prerequisite Learning | ACM Survey (2025) | Comprehensive review |

### Open-Source Tools

| Tool | Repository | Use Case |
|------|------------|----------|
| py-readability-metrics | github.com/cdimascio | Readability analysis |
| spaCy | spacy.io | NLP pipeline |
| AllenNLP | allennlp.org | SRL models |
| sentence-transformers | sbert.net | Embeddings |
| LangChain | langchain.com | LLM orchestration |
| spaCy Entity Linker | github.com/egerber | Wikidata linking |
