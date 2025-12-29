# MIT OCW & Stanford SEE Implementation Plan

**Version:** 1.0.0
**Date:** 2025-12-23
**Status:** Ready for Implementation

---

## Executive Summary

This document outlines the implementation plan for importing MIT OpenCourseWare (OCW) and Stanford Engineering Everywhere (SEE) content into the UnaMentis curriculum system. These two sources are ideal test beds for the AI Enrichment Pipeline because they:

1. **Are well-structured** - Both have consistent content organization
2. **Have rich metadata** - Course info, syllabi, prerequisites
3. **Include transcripts** - Video transcripts enable content segmentation
4. **Contain assessments** - Problem sets and exams for assessment extraction
5. **Have clear licensing** - CC-BY-NC-SA 4.0 (with one exception)
6. **Represent different domains** - Broad STEM coverage for testing

---

## Phase Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    IMPLEMENTATION PHASES                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PHASE 1: Foundation (Week 1)                                          │
│  ├─ Core infrastructure                                                │
│  ├─ License validation system                                          │
│  └─ Basic ZIP/HTML parsing                                             │
│                                                                         │
│  PHASE 2: Content Extraction (Week 2)                                  │
│  ├─ PDF text extraction                                                │
│  ├─ Transcript parsing                                                 │
│  └─ Resource cataloging                                                │
│                                                                         │
│  PHASE 3: AI Enrichment Integration (Weeks 3-4)                        │
│  ├─ Stage 1-3: Analysis, Structure, Segmentation                       │
│  ├─ Stage 4-5: Objectives, Assessments                                 │
│  └─ Stage 6-7: Tutoring Enhancement, Knowledge Graph                   │
│                                                                         │
│  PHASE 4: Testing & Validation (Week 5)                                │
│  ├─ Real course imports                                                │
│  ├─ Quality validation                                                 │
│  └─ License compliance verification                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation

### 1.1 Core Infrastructure Setup

**Duration:** 2-3 days

#### Tasks

1. **Create package structure**
   ```bash
   mkdir -p curriculum/importers/src/umlcf_importer/{core,importers/mit_ocw,importers/stanford_see,parsers,enrichment}
   ```

2. **Implement base classes**
   - `CurriculumImporter` ABC
   - `StorageBackend` ABC
   - `ValidationResult` model
   - `CurriculumData` Pydantic model

3. **Set up entry points**
   ```toml
   [project.entry-points."umlcf.importers"]
   mit_ocw = "umlcf_importer.importers.mit_ocw:MITOCWImporter"
   stanford_see = "umlcf_importer.importers.stanford_see:StanfordSEEImporter"
   ```

#### Deliverables

- [ ] `core/base.py` - Abstract base classes
- [ ] `core/models.py` - Pydantic data models
- [ ] `core/registry.py` - Plugin discovery
- [ ] `core/errors.py` - Custom exceptions
- [ ] `pyproject.toml` - Package configuration

### 1.2 License Validation System

**Duration:** 1 day

**CRITICAL: This must be implemented first to ensure license compliance.**

#### Tasks

1. **Create license validator base**
   ```python
   # core/license.py
   class LicenseValidator(ABC):
       @abstractmethod
       def validate(self, source_id: str) -> LicenseValidationResult: ...

       @abstractmethod
       def build_rights_block(self, source_id: str) -> Dict: ...
   ```

2. **Implement MIT OCW license validator**
   - CC-BY-NC-SA 4.0 for all content
   - Attribution format preservation
   - Source URL tracking

3. **Implement Stanford SEE license validator**
   - CC-BY-NC-SA 4.0 for most courses
   - **Block LOGIC course** (custom license)
   - Course-specific validation

4. **Create license audit logging**
   - Log all license decisions
   - Track imported content sources
   - Generate compliance reports

#### Deliverables

- [ ] `core/license.py` - License validation base
- [ ] `importers/mit_ocw/license.py` - MIT OCW license handling
- [ ] `importers/stanford_see/license.py` - Stanford SEE license handling (with LOGIC block)
- [ ] License compliance tests

### 1.3 Basic ZIP/HTML Parsing

**Duration:** 2 days

#### Tasks

1. **Implement ZIP parser**
   - Extract file listing
   - Detect content structure
   - Handle nested archives

2. **Implement HTML parser**
   - BeautifulSoup-based extraction
   - Navigation structure parsing
   - Metadata extraction

3. **Implement IMS manifest parser** (MIT OCW)
   - Parse `imsmanifest.xml`
   - Extract navigation hierarchy
   - Map to UMCF structure

#### Deliverables

- [ ] `parsers/zip_parser.py`
- [ ] `parsers/html_parser.py`
- [ ] `parsers/ims_manifest.py`
- [ ] Unit tests for each parser

---

## Phase 2: Content Extraction

### 2.1 PDF Text Extraction

**Duration:** 2-3 days

#### Tasks

1. **Select PDF library**
   - Primary: `pdfminer.six` (pure Python, cross-platform)
   - Fallback: `PyMuPDF` for complex layouts

2. **Implement lecture notes extractor**
   - Preserve heading structure
   - Extract text blocks
   - Handle mathematical notation
   - Catalog embedded images

3. **Implement problem set extractor**
   - Identify problem boundaries
   - Extract problem numbers
   - Parse sub-parts (a, b, c)
   - Handle solution files separately

4. **Handle mathematical notation**
   - Detect LaTeX blocks
   - Convert to spoken form where possible
   - Preserve original for display

#### Deliverables

- [ ] `parsers/pdf_extractor.py`
- [ ] `parsers/math_converter.py`
- [ ] Test fixtures with sample PDFs
- [ ] LaTeX-to-speech conversion tables

### 2.2 Transcript Parsing

**Duration:** 2 days

#### Tasks

1. **Implement HTML transcript parser**
   - Extract timestamped segments
   - Identify speaker changes
   - Detect topic boundaries
   - Preserve original timestamps

2. **Implement PDF transcript parser** (fallback)
   - Extract text with layout preservation
   - Infer structure from formatting
   - Handle multi-column layouts

3. **Create segment boundaries**
   - Target 3-5 minute segments
   - Align with topic changes
   - Mark natural stopping points

#### Deliverables

- [ ] `parsers/transcript_parser.py`
- [ ] Segment boundary detection
- [ ] Speaker identification
- [ ] Test fixtures with sample transcripts

### 2.3 Resource Cataloging

**Duration:** 1 day

#### Tasks

1. **Create resource type classifier**
   - PDF (lecture notes, problems, solutions, readings)
   - Code files (Python, MATLAB, Java)
   - Data files (CSV, ZIP archives)
   - Media (images, video URLs)

2. **Build resource index**
   - Map files to lectures/topics
   - Track file sizes
   - Identify solution pairs

3. **Generate resource metadata**
   - File type detection
   - Content summarization
   - Dependency tracking

#### Deliverables

- [ ] `parsers/resource_cataloger.py`
- [ ] Resource type classification
- [ ] File-to-topic mapping

---

## Phase 3: AI Enrichment Integration

This is the core of making these sources useful for tutoring.

### 3.1 Stages 1-3: Analysis, Structure, Segmentation

**Duration:** 4-5 days

#### Stage 1: Content Analysis

**Tasks:**
1. Connect to content analysis module
2. Configure for collegiate STEM content
3. Run readability analysis on extracted text
4. Detect domain (CS, Math, Physics, etc.)
5. Assess complexity levels

**MIT OCW Specific:**
- Expect collegiate reading level
- Support for mathematical content
- Multiple domains per course

**Stanford SEE Specific:**
- Focus on engineering/CS domains
- Higher difficulty threshold
- Technical vocabulary detection

#### Stage 2: Structure Inference

**Tasks:**
1. Use existing structure from sources as template
2. Validate hierarchy against UMCF requirements
3. Fill gaps with LLM inference
4. Map to standard content types

**MIT OCW Specific:**
- Use `imsmanifest.xml` as primary structure
- Supplement with heading extraction from PDFs
- Infer module boundaries from lecture numbers

**Stanford SEE Specific:**
- Use course catalog as structure template
- Lecture numbering is authoritative
- Align with syllabus sections

#### Stage 3: Content Segmentation

**Tasks:**
1. Apply meta-chunking to transcripts
2. Align segments with video timestamps
3. Identify stopping points
4. Mark segment types (narrative, definition, example)

**Segmentation Parameters:**
```python
SEGMENTATION_CONFIG = {
    "target_duration_seconds": 180,  # 3 minutes
    "min_words": 100,
    "max_words": 500,
    "stopping_point_frequency": "per_concept",
    "align_to_timestamps": True,
}
```

#### Deliverables

- [ ] `enrichment/analyzer.py` - Content analysis integration
- [ ] `enrichment/structure.py` - Structure inference
- [ ] `enrichment/segmenter.py` - Content segmentation
- [ ] Configuration files for each source

### 3.2 Stages 4-5: Objectives and Assessments

**Duration:** 4-5 days

#### Stage 4: Learning Objective Extraction

**Tasks:**
1. Extract explicit objectives from syllabi
2. Infer objectives from lecture content
3. Classify by Bloom's taxonomy level
4. Map objectives to segments

**Sources for Objectives:**
| Source | Priority | Quality |
|--------|----------|---------|
| Syllabus "Students will..." | High | Explicit |
| Course description | Medium | General |
| Lecture headings | Medium | Inferred |
| Problem set themes | Low | Inferred |

#### Stage 5: Assessment Generation

**This is where MIT OCW and Stanford SEE shine - they have existing assessments!**

**Tasks:**
1. Parse existing problem sets into structured format
2. Match problems with solutions
3. Generate hints from solutions
4. Create feedback from solution explanations
5. Add variations for practice

**Assessment Transformation Pipeline:**
```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Problem Set PDF │ ──▶ │  Parsed Problems │ ──▶ │ UMCF Assessments │
│  - Problem text  │     │  - Number        │     │  - prompt        │
│  - Parts (a,b,c) │     │  - Text          │     │  - type          │
│  - Point values  │     │  - Parts[]       │     │  - choices[]     │
└──────────────────┘     └──────────────────┘     │  - feedback      │
                                                   │  - hints[]       │
┌──────────────────┐                              └──────────────────┘
│  Solution PDF    │ ──────────────────────────────────▲
│  - Step-by-step  │     Generate hints & feedback     │
│  - Explanations  │ ──────────────────────────────────┘
└──────────────────┘
```

**LLM Enhancement Tasks:**
1. Generate alternative phrasings of problems
2. Create hints at multiple levels
3. Generate feedback for common mistakes
4. Add difficulty ratings

#### Deliverables

- [ ] `enrichment/objectives.py` - Objective extraction
- [ ] `enrichment/assessments.py` - Assessment generation
- [ ] Problem set parser
- [ ] Solution-to-feedback transformer
- [ ] Hint generation prompts

### 3.3 Stages 6-7: Tutoring Enhancement and Knowledge Graph

**Duration:** 3-4 days

#### Stage 6: Tutoring Enhancement

**Tasks:**
1. Generate spoken text variants
2. Create alternative explanations
3. Identify common misconceptions
4. Configure stopping points

**Spoken Text Generation (Critical for TTS):**
```python
# Mathematical notation to speech
MATH_SPEECH_RULES = {
    # Greek letters
    r"α": "alpha",
    r"β": "beta",
    r"θ": "theta",
    r"λ": "lambda",

    # Operators
    r"=": "equals",
    r"≠": "does not equal",
    r"≤": "is less than or equal to",
    r"≥": "is greater than or equal to",
    r"∑": "the sum of",
    r"∫": "the integral of",
    r"∂": "the partial derivative of",

    # Common expressions
    r"O\(n\)": "order n or big O of n",
    r"O\(n²\)": "order n squared",
    r"O\(log n\)": "order log n",
    r"i\.e\.": "that is",
    r"e\.g\.": "for example",
}
```

**Misconception Identification:**
1. Use domain-specific misconception databases
2. Generate from solution common mistakes
3. Create remediation paths
4. Link to prerequisite content

#### Stage 7: Knowledge Graph Construction

**Tasks:**
1. Extract concepts from content
2. Identify prerequisite relationships
3. Link related concepts across lectures
4. Connect to external knowledge bases (Wikidata)
5. Cross-reference between MIT OCW and Stanford SEE courses

**Cross-Source Concept Mapping:**
```python
# Example concept relationships across sources
CONCEPT_MAPPINGS = {
    "linear_regression": {
        "stanford_see": "CS229/lecture2",
        "mit_ocw": "18.06/lecture1",  # Linear algebra foundation
        "prerequisites": ["matrix_multiplication", "derivatives"],
        "related": ["gradient_descent", "cost_function"],
    },
    "gradient_descent": {
        "stanford_see": "CS229/lecture3",
        "mit_ocw": "6.006/lecture_optimization",
        "prerequisites": ["derivatives", "learning_rate"],
    }
}
```

#### Deliverables

- [ ] `enrichment/spoken_text.py` - TTS optimization
- [ ] `enrichment/alternatives.py` - Alternative explanations
- [ ] `enrichment/misconceptions.py` - Misconception handling
- [ ] `enrichment/knowledge_graph.py` - KG construction
- [ ] Cross-source concept mapping

---

## Phase 4: Testing & Validation

### 4.1 Real Course Imports

**Duration:** 2-3 days

#### Test Courses

**MIT OCW Priority:**
| Course | Why Test | Expected Challenges |
|--------|----------|---------------------|
| 6.001 SICP | Code + concepts | Code block handling |
| 18.06 Linear Algebra | Math-heavy | LaTeX conversion |
| 8.01 Physics I | Videos + transcripts | Transcript alignment |

**Stanford SEE Priority:**
| Course | Why Test | Expected Challenges |
|--------|----------|---------------------|
| CS229 Machine Learning | Rich content | Math notation |
| CS106A Programming | Intro level | Code examples |
| EE364A Convex Optimization | Advanced math | Complex LaTeX |

#### Test Protocol

1. **Download test courses** (cache locally)
2. **Run validation** - Check structure recognition
3. **Run extraction** - Verify content capture
4. **Run enrichment** - Test AI pipeline
5. **Manual review** - Spot-check quality
6. **License audit** - Verify compliance

### 4.2 Quality Validation

**Duration:** 1-2 days

#### Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Structure accuracy | >90% | Manual review of hierarchy |
| Segment coherence | >85% | Semantic similarity within segments |
| Objective relevance | >80% | LLM evaluation |
| Assessment quality | >75% | Answerability check |
| Spoken text clarity | >90% | TTS testing |

#### Automated Quality Checks

```python
QUALITY_CHECKS = [
    "segment_length_appropriate",      # 100-500 words
    "objectives_bloom_aligned",        # Valid Bloom verbs
    "assessments_answerable",          # Can answer from content
    "spoken_text_pronounceable",       # No unpronounceable symbols
    "license_preserved",               # License block present
    "source_attribution_correct",      # Correct holder, URL
]
```

### 4.3 License Compliance Verification

**Duration:** 1 day

**CRITICAL: Must pass before any release.**

#### Verification Checklist

- [ ] All MIT OCW content has CC-BY-NC-SA 4.0 license block
- [ ] MIT attribution format is correct
- [ ] MIT source URL is preserved
- [ ] All Stanford SEE content (except LOGIC) has CC-BY-NC-SA 4.0 license block
- [ ] Stanford attribution format is correct
- [ ] Stanford source URL is preserved
- [ ] LOGIC course is blocked from import
- [ ] Import timestamps are recorded
- [ ] No license information is lost in transformation
- [ ] Downstream users informed of license requirements

---

## Technical Decisions

### Dependencies

**Core (Pure Python, Cross-Platform):**
```
pydantic>=2.0
aiofiles>=23.0
beautifulsoup4>=4.12
pdfminer.six>=20221105
```

**Optional (Server Only):**
```
lxml>=4.9           # Faster XML parsing
PyMuPDF>=1.23       # Better PDF handling
spacy>=3.7          # NLP pipeline
sentence-transformers>=2.2  # Embeddings
```

### LLM Integration

**Supported Providers:**
- OpenAI GPT-4 (primary)
- Anthropic Claude (alternative)
- Local models via Ollama (development)

**Rate Limiting:**
```python
LLM_RATE_LIMITS = {
    "openai_gpt4": {
        "requests_per_minute": 60,
        "tokens_per_minute": 90000,
    },
    "anthropic_claude": {
        "requests_per_minute": 60,
        "tokens_per_minute": 100000,
    }
}
```

### Storage Strategy

**During Import:**
- In-memory for small courses
- SQLite for large courses
- JSON files for intermediate results

**Final Output:**
- UMCF JSON files
- Resource files in structured directories
- Metadata index for quick lookup

---

## Risk Mitigation

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| PDF parsing fails | Content loss | Multiple parser fallbacks |
| Math notation unreadable | TTS quality | Expand conversion tables |
| LLM rate limits | Slow processing | Batch processing, caching |
| Large file handling | Memory issues | Streaming processing |

### Legal Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| License violation | Legal liability | Mandatory license validation |
| Attribution missing | Non-compliance | Automated attribution insertion |
| LOGIC course imported | License breach | Hard block in code |

---

## Success Criteria

### Phase 1 Complete When:
- [ ] Both importers can validate valid ZIP packages
- [ ] License validation blocks LOGIC course
- [ ] Basic structure extraction works

### Phase 2 Complete When:
- [ ] PDF text extraction works for 90% of files
- [ ] Transcripts parse into timestamped segments
- [ ] Resources are correctly cataloged

### Phase 3 Complete When:
- [ ] Enrichment pipeline produces valid UMCF
- [ ] Objectives are Bloom-aligned
- [ ] Assessments have hints and feedback
- [ ] Spoken text is TTS-ready

### Phase 4 Complete When:
- [ ] 3+ courses from each source import successfully
- [ ] Quality metrics meet targets
- [ ] License compliance verified
- [ ] Documentation complete

---

## Next Actions

### Immediate (This Week)

1. **Set up package structure** - Create directories and base files
2. **Implement license validators** - Critical first step
3. **Create test fixtures** - Download sample courses

### Short-term (Next 2 Weeks)

1. **Implement ZIP/HTML parsing** - Get content extraction working
2. **Implement PDF extraction** - Handle lecture notes and problems
3. **Connect enrichment pipeline** - Integration with existing AI modules

### Medium-term (Weeks 3-5)

1. **Complete enrichment integration** - All 7 stages
2. **Test with real courses** - Full import validation
3. **Document and release** - Ready for production use

---

## Appendix: Sample Course Structure

### MIT OCW 6.001 (Expected Structure)

```
6.001 Structure and Interpretation of Computer Programs
├── Module: Lecture Notes (28 topics)
│   ├── Topic: Lecture 1 - Building Abstractions with Procedures
│   │   ├── Transcript segments (12-15 segments)
│   │   ├── Learning objectives (3-5)
│   │   └── Resources (PDF, video link)
│   ├── Topic: Lecture 2 - Higher-order Procedures
│   └── ...
├── Module: Assignments (5 projects)
│   ├── Activity: Project 1
│   │   ├── Assessments (extracted problems)
│   │   └── Resources (PDF, code files)
│   └── ...
├── Module: Exams
│   ├── Assessment: Quiz 1
│   └── Assessment: Quiz 2
└── Glossary (extracted terms)
```

### Stanford SEE CS229 (Expected Structure)

```
CS229 Machine Learning
├── Module: Supervised Learning (Lectures 1-8)
│   ├── Topic: Lecture 1 - Introduction
│   │   ├── Transcript segments (15-20 segments)
│   │   ├── Learning objectives (4-6)
│   │   └── Resources (PDF notes, video link)
│   ├── Topic: Lecture 2 - Linear Regression
│   └── ...
├── Module: Unsupervised Learning (Lectures 9-14)
│   └── ...
├── Module: Assignments
│   ├── Activity: Problem Set 1
│   │   ├── Assessments (10-15 problems)
│   │   ├── Hints (generated)
│   │   └── Feedback (from solutions)
│   └── ...
├── Module: Exams
│   └── Assessment: Final Exam
└── Glossary (ML terminology)
```
