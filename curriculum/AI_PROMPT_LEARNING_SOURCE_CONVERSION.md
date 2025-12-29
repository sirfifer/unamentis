# AI-Assisted Learning Source to UMLCF Conversion Guide

**Version:** 1.0.0
**Date:** 2025-12-29

---

## Overview

This guide provides prompts and instructions for using AI (ChatGPT, Claude, etc.) to convert raw learning materials into the Una Mentis Curriculum Format (UMLCF). This enables you to take documents, transcripts, lecture notes, textbook chapters, or any educational content and transform them into structured curriculum ready for conversational AI tutoring.

---

## Table of Contents

1. [When to Use This Guide](#when-to-use-this-guide)
2. [Prerequisites](#prerequisites)
3. [The Conversion Process](#the-conversion-process)
4. [Master Conversion Prompt](#master-conversion-prompt)
5. [Stage-Specific Prompts](#stage-specific-prompts)
6. [Post-Processing](#post-processing)
7. [Examples](#examples)
8. [Tips for Best Results](#tips-for-best-results)

---

## When to Use This Guide

Use this guide when you have:

- **Lecture transcripts** (from YouTube, Coursera, MIT OCW, etc.)
- **Textbook chapters** (PDF, EPUB, plain text)
- **Course notes** or slides
- **Tutorial articles** or blog posts
- **Documentation** you want to teach from
- **Any educational content** that needs to be structured for voice tutoring

---

## Prerequisites

Before starting, gather:

1. **Source material** - The content to convert (text, transcript, document)
2. **Target audience** - Who will learn this? (e.g., "8th grade students", "college freshmen", "professional developers")
3. **Learning goals** - What should learners be able to do after completing this?
4. **Approximate duration** - How long should the lesson take? (helps with segmentation)

---

## The Conversion Process

The conversion happens in stages:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONVERSION PIPELINE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ANALYZE           Understand content, audience, structure   │
│         ↓                                                       │
│  2. STRUCTURE         Create hierarchical organization          │
│         ↓                                                       │
│  3. SEGMENT           Break into tutoring-sized chunks          │
│         ↓                                                       │
│  4. ENRICH            Add objectives, assessments, glossary     │
│         ↓                                                       │
│  5. FORMAT            Output as valid UMLCF JSON                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

You can do this in a single comprehensive prompt or break it into stages.

---

## Master Conversion Prompt

Use this prompt for a complete conversion. Copy the entire prompt, then paste your source content where indicated.

```markdown
# UMLCF Curriculum Conversion Request

## Your Role
You are an expert curriculum designer and instructional technologist. Your task is to convert raw educational content into the Una Mentis Curriculum Format (UMLCF) - a JSON-based format optimized for conversational AI tutoring.

## Source Content Information
- **Target Audience**: [SPECIFY: e.g., "8th grade students", "college undergraduates", "professional developers"]
- **Subject Domain**: [SPECIFY: e.g., "Mathematics", "Computer Science", "Biology"]
- **Estimated Learning Time**: [SPECIFY: e.g., "30 minutes", "1 hour", "2 hours"]
- **Source Type**: [SPECIFY: "lecture transcript", "textbook chapter", "tutorial article", etc.]

## Source Content
[PASTE YOUR CONTENT HERE]

---

## Conversion Instructions

Please convert the above content into UMLCF format following these steps:

### Step 1: Analyze the Content
- Identify the main topic and subtopics
- Determine the key concepts that must be taught
- Note any technical vocabulary that needs glossary entries
- Identify natural stopping points for comprehension checks

### Step 2: Create Hierarchical Structure
Organize content into:
- **Modules** (major sections, 15-30 minutes each)
- **Topics** (teachable units, 5-15 minutes each)
- **Subtopics** if needed (2-5 minutes each)

### Step 3: Segment into Transcript Chunks
For each topic, create transcript segments that are:
- 100-300 words each (1-3 minutes of spoken content)
- Focused on ONE concept per segment
- Ending at natural pause points

### Step 4: Add Tutoring Elements
For each segment, add as appropriate:
- **Stopping points** with comprehension check prompts
- **Alternative explanations** (simpler, technical, analogy versions)
- **Speaking notes** for TTS (pace, emphasis, emotional tone)

### Step 5: Generate Assessments
Create comprehension questions at multiple Bloom's levels:
- **Remember**: Recall facts and definitions
- **Understand**: Explain concepts in own words
- **Apply**: Use knowledge in new situations
- **Analyze**: Compare, contrast, examine relationships

### Step 6: Extract Glossary Terms
Identify technical terms and provide:
- Clear, contextual definitions
- Pronunciation guides for difficult words
- Related terms

### Step 7: Identify Misconceptions
Note common errors learners might make:
- What they might incorrectly believe
- Trigger phrases that indicate the misconception
- How to correct the misunderstanding

---

## Output Format

Generate valid JSON following this UMLCF structure:

```json
{
  "vlcf": "1.0.0",
  "id": {
    "catalog": "UUID",
    "value": "[GENERATE-UUID]"
  },
  "title": "[Descriptive title for this curriculum]",
  "description": "[1-2 sentence overview]",
  "version": {
    "number": "1.0.0",
    "date": "[TODAY'S DATE]"
  },
  "metadata": {
    "language": "en",
    "keywords": ["keyword1", "keyword2"],
    "targetAudience": "[from input]"
  },
  "educational": {
    "typicalAgeRange": "[e.g., 13-14 for 8th grade]",
    "educationalLevel": "[elementary/middle-school/high-school/collegiate/professional]",
    "estimatedDuration": "[ISO 8601 duration, e.g., PT30M for 30 minutes]"
  },
  "content": [
    {
      "id": {"value": "module-1"},
      "title": "[Module Title]",
      "type": "module",
      "orderIndex": 1,
      "learningObjectives": [
        {
          "id": "obj-1",
          "text": "[Action verb] + [what learner will do]",
          "bloomLevel": "understand"
        }
      ],
      "children": [
        {
          "id": {"value": "topic-1-1"},
          "title": "[Topic Title]",
          "type": "topic",
          "orderIndex": 1,
          "transcript": {
            "segments": [
              {
                "id": "seg-1",
                "type": "introduction",
                "content": "[Segment text optimized for spoken delivery]",
                "speakingNotes": {
                  "pace": "moderate",
                  "emotionalTone": "welcoming"
                },
                "checkpoint": {
                  "type": "simple_confirmation",
                  "prompt": "Does that make sense so far?"
                }
              },
              {
                "id": "seg-2",
                "type": "explanation",
                "content": "[Main explanatory content]",
                "alternativeExplanations": [
                  {
                    "style": "simpler",
                    "content": "[Easier version for struggling learners]"
                  },
                  {
                    "style": "analogy",
                    "content": "[Real-world comparison]"
                  }
                ],
                "checkpoint": {
                  "type": "comprehension_check",
                  "prompt": "[Question to verify understanding]",
                  "expectedResponsePatterns": ["keyword1", "keyword2"]
                }
              }
            ]
          },
          "assessments": [
            {
              "id": {"value": "q-1"},
              "type": "choice",
              "prompt": "[Question text]",
              "choices": [
                {"id": "a", "text": "[Correct answer]", "correct": true},
                {"id": "b", "text": "[Plausible distractor]", "correct": false},
                {"id": "c", "text": "[Another distractor]", "correct": false}
              ],
              "feedback": {
                "correct": {"text": "[Positive reinforcement + why correct]"},
                "incorrect": {"text": "[Gentle correction + hint]"}
              },
              "difficulty": 0.3
            }
          ],
          "misconceptions": [
            {
              "id": "misc-1",
              "misconception": "[What learners incorrectly believe]",
              "triggerPhrases": ["phrase that indicates this error"],
              "correction": "[How to address it]",
              "correctUnderstanding": "[What they should understand instead]"
            }
          ],
          "glossaryTerms": [
            {
              "term": "[Technical term]",
              "definition": "[Clear, contextual definition]",
              "pronunciation": "[phonetic guide if needed]"
            }
          ]
        }
      ]
    }
  ],
  "glossary": [
    {
      "term": "[Curriculum-wide term]",
      "definition": "[Definition]"
    }
  ]
}
```

## Quality Requirements

Ensure your output:
1. ✅ Is valid JSON (no trailing commas, proper escaping)
2. ✅ Has unique IDs for all elements
3. ✅ Includes at least one learning objective per topic
4. ✅ Has transcript segments of appropriate length (100-300 words)
5. ✅ Includes comprehension checkpoints every 2-3 segments
6. ✅ Has assessments that can be answered from the content
7. ✅ Uses age-appropriate language for the target audience

---

Now please convert the source content provided above into UMLCF format.
```

---

## Stage-Specific Prompts

If the source content is long or complex, break the conversion into stages:

### Stage 1: Analysis Prompt

```markdown
# Content Analysis Request

Analyze the following educational content and provide:

1. **Main Topic**: What is this content primarily about?
2. **Key Concepts**: List 5-10 core concepts that must be understood
3. **Vocabulary**: List technical terms that need definitions
4. **Prerequisite Knowledge**: What should learners already know?
5. **Natural Sections**: Where does the content naturally divide?
6. **Estimated Reading Level**: What grade level is this written for?
7. **Suggested Modifications**: What needs to change for voice delivery?

## Content to Analyze:
[PASTE CONTENT HERE]

Respond in structured format (not JSON yet, just analysis).
```

### Stage 2: Structure Prompt

```markdown
# Hierarchical Structure Request

Based on this content, create a hierarchical outline for a tutoring curriculum:

## Target Audience: [SPECIFY]
## Estimated Duration: [SPECIFY]

## Content:
[PASTE CONTENT OR ANALYSIS FROM STAGE 1]

Create an outline with:
- Module titles (major sections)
- Topic titles under each module
- 1-2 sentence description of each topic
- Estimated duration for each topic
- 2-3 learning objectives for each topic

Format as a structured outline (not JSON yet).
```

### Stage 3: Transcript Segmentation Prompt

```markdown
# Transcript Segmentation Request

Convert this topic content into conversational transcript segments for an AI tutor.

## Topic: [TOPIC TITLE]
## Target Audience: [SPECIFY]
## Topic Content:
[PASTE TOPIC CONTENT]

For each segment, provide:
1. **Segment ID**: seg-1, seg-2, etc.
2. **Type**: introduction, explanation, example, transition, or summary
3. **Content**: 100-300 words, written as if spoken aloud
4. **Speaking Notes**: Pace (slow/moderate/fast), emphasis words, emotional tone
5. **Checkpoint** (if applicable): Question to verify understanding

Guidelines:
- Use conversational language ("Let's explore...", "Think of it this way...")
- Avoid abbreviations (spell out "for example" not "e.g.")
- One concept per segment
- End segments at natural pause points
- Add checkpoints after complex explanations

Output as JSON array of segments.
```

### Stage 4: Assessment Generation Prompt

```markdown
# Assessment Generation Request

Generate comprehension assessments for this topic:

## Topic: [TOPIC TITLE]
## Learning Objectives:
[LIST OBJECTIVES]

## Topic Content:
[PASTE CONTENT OR SEGMENTS]

Generate:
1. **2-3 Multiple Choice Questions** (testing recall and understanding)
2. **1-2 Short Answer Questions** (testing application and analysis)

For each question provide:
- Question text (clear, unambiguous)
- For MC: 3-4 choices with one correct answer
- Bloom's taxonomy level
- Difficulty rating (0.0-1.0)
- Feedback for correct and incorrect answers
- Hints for struggling learners

Output as JSON array matching UMLCF assessment schema.
```

### Stage 5: Enrichment Prompt

```markdown
# Tutoring Enrichment Request

Enhance this topic with tutoring-specific elements:

## Topic Content (with segments):
[PASTE SEGMENTS]

## Target Audience: [SPECIFY]

Add the following:

### 1. Alternative Explanations
For key concepts, provide:
- Simpler version (2 grade levels below target)
- Technical version (more precise)
- Analogy version (real-world comparison)

### 2. Misconceptions
Identify 2-3 common errors learners make:
- What they incorrectly believe
- Phrases that indicate this error
- How to correct it

### 3. Glossary Terms
For each technical term:
- Clear definition
- Pronunciation (if non-obvious)
- Related terms

### 4. Speaking Notes Enhancement
For each segment:
- Words to emphasize
- Suggested pace
- Emotional tone (encouraging, curious, serious)

Output as JSON additions to the existing content.
```

---

## Post-Processing

After AI generation, always:

### 1. Validate JSON
```bash
# Using Python
python -c "import json; json.load(open('curriculum.vlcf'))"

# Using jq
jq . curriculum.vlcf > /dev/null && echo "Valid JSON"
```

### 2. Check Required Fields
Ensure every content node has:
- `id` with `value` property
- `title`
- `type`

### 3. Verify IDs are Unique
```python
import json

with open('curriculum.vlcf') as f:
    data = json.load(f)

ids = []
def extract_ids(node):
    if isinstance(node, dict):
        if 'id' in node and isinstance(node['id'], dict):
            ids.append(node['id'].get('value'))
        for v in node.values():
            extract_ids(v)
    elif isinstance(node, list):
        for item in node:
            extract_ids(item)

extract_ids(data)
duplicates = [id for id in ids if ids.count(id) > 1]
print(f"Duplicate IDs: {set(duplicates) if duplicates else 'None'}")
```

### 4. Review for Voice Suitability
Read segments aloud to check:
- Natural flow
- Appropriate length
- Clear pronunciation cues

---

## Examples

### Example: Converting a MIT OCW Lecture Transcript

**Input prompt:**
```markdown
# UMLCF Curriculum Conversion Request

## Your Role
You are an expert curriculum designer...

## Source Content Information
- **Target Audience**: College computer science students (sophomores)
- **Subject Domain**: Computer Science - Data Structures
- **Estimated Learning Time**: 45 minutes
- **Source Type**: Lecture transcript from MIT OCW

## Source Content
PROFESSOR: Today we're going to talk about binary search trees.
A binary search tree is a data structure that maintains a sorted
collection of elements. Each node in the tree has at most two children...

[REST OF TRANSCRIPT]
```

### Example: Converting a Textbook Chapter

**Input prompt:**
```markdown
# UMLCF Curriculum Conversion Request

## Source Content Information
- **Target Audience**: 8th grade students
- **Subject Domain**: Biology - Cell Biology
- **Estimated Learning Time**: 30 minutes
- **Source Type**: Textbook chapter excerpt

## Source Content
Chapter 4: The Cell

4.1 Introduction to Cells
All living things are made of cells. A cell is the basic unit of
life. Some organisms consist of only one cell (unicellular), while
others are made of many cells (multicellular)...

[REST OF CHAPTER]
```

---

## Tips for Best Results

### Content Preparation

1. **Clean your source material**
   - Remove page numbers, headers, footers
   - Fix OCR errors from PDFs
   - Remove irrelevant navigation text

2. **Provide context**
   - Always specify target audience
   - Include subject domain
   - Note any prerequisites

3. **Chunk large content**
   - Process one chapter/lecture at a time
   - Combine results afterward

### Prompt Engineering

1. **Be specific about output format**
   - Include the exact JSON structure you want
   - Show examples of good segments

2. **Iterate on results**
   - First pass: Get structure right
   - Second pass: Enhance with tutoring elements
   - Third pass: Add assessments

3. **Use follow-up prompts**
   - "Add more stopping points to segments 3 and 5"
   - "Create an easier alternative explanation for segment 2"
   - "Add a misconception about [specific concept]"

### Quality Assurance

1. **Read segments aloud** - Do they sound natural?
2. **Test assessments** - Can they be answered from the content?
3. **Check progression** - Do concepts build logically?
4. **Verify difficulty** - Is it appropriate for the audience?

---

## Related Documentation

- [UMLCF Specification](spec/UMLCF_SPECIFICATION.md) - Full format specification
- [AI Enrichment Pipeline](importers/AI_ENRICHMENT_PIPELINE.md) - Automated enrichment details
- [Standards Traceability](spec/STANDARDS_TRACEABILITY.md) - Educational standards mapping

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-29 | Initial release |
