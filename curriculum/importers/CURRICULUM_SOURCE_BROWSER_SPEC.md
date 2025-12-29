# Curriculum Source Browser Specification

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-12-23

---

## Overview

The Curriculum Source Browser is a server-side web interface that enables administrators to discover, preview, and import curriculum content from external sources (MIT OCW, Stanford SEE, CK-12, etc.) into the UnaMentis system.

### Architecture Context

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SERVER (Next.js Dashboard)                        │
│                                                                         │
│   Existing Tabs:                                                        │
│   [Dashboard] [Health] [Curriculum] [Metrics] [Logs] [Clients] ...     │
│                             │                                           │
│                             ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │  Curriculum Tab (Expanded)                                       │  │
│   │                                                                  │  │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │  │
│   │  │  My Library │  │   Import    │  │   Visual    │             │  │
│   │  │  (existing) │  │   Sources   │  │   Assets    │             │  │
│   │  │             │  │   (NEW)     │  │  (existing) │             │  │
│   │  └─────────────┘  └─────────────┘  └─────────────┘             │  │
│   │                         │                                        │  │
│   │                         ▼                                        │  │
│   │   ┌─────────────────────────────────────────────────────────┐   │  │
│   │   │  SOURCE BROWSER                                          │   │  │
│   │   │  ├─ Source Selection (MIT OCW, Stanford SEE, ...)       │   │  │
│   │   │  ├─ Course Catalog Browser                               │   │  │
│   │   │  ├─ Course Preview Panel                                 │   │  │
│   │   │  ├─ Import Configuration                                 │   │  │
│   │   │  └─ Import Progress Tracker                              │   │  │
│   │   └─────────────────────────────────────────────────────────┘   │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│   Backend:                                                              │
│   ├─ Python importers (mit_ocw, stanford_see, ck12, fastai)           │
│   ├─ AI Enrichment Pipeline                                            │
│   └─ UMCF file storage                                                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Export .umcf files
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        iOS CLIENT (Simple Loader)                        │
│   └─ Load pre-built .umcf → Use in tutoring sessions                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## User Experience Design

### Navigation Flow

```
Curriculum Tab
    │
    ├── [My Library] ────────────── View/manage imported curricula
    │                               (existing curriculum-panel.tsx)
    │
    ├── [Import Sources] ────────── NEW: Browse external sources
    │       │
    │       ├── Source Selection ─── Choose from configured sources
    │       │
    │       ├── Course Browser ───── Rich catalog interface
    │       │       │
    │       │       ├── Filter by subject, level, instructor
    │       │       ├── Search courses
    │       │       └── View course cards
    │       │
    │       ├── Course Preview ───── Detailed view before import
    │       │       │
    │       │       ├── Syllabus / description
    │       │       ├── Lecture list
    │       │       ├── Available materials
    │       │       ├── License information
    │       │       └── Import options
    │       │
    │       └── Import Progress ──── Track import & enrichment
    │               │
    │               ├── Download progress
    │               ├── Extraction progress
    │               ├── Enrichment stages (1-7)
    │               └── Completion / errors
    │
    └── [Visual Assets] ───────────── Edit assets (existing)
```

### Wireframes

#### Source Selection Page

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Import Sources                                              [← Back]   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Select a curriculum source to browse available courses:                │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │   │
│  │  │  [MIT Logo]     │  │ [Stanford Logo] │  │  [CK-12 Logo]   │  │   │
│  │  │                 │  │                 │  │                 │  │   │
│  │  │  MIT            │  │  Stanford       │  │  CK-12          │  │   │
│  │  │  OpenCourseWare │  │  Engineering    │  │  FlexBooks      │  │   │
│  │  │                 │  │  Everywhere     │  │                 │  │   │
│  │  │  2,500+ courses │  │  10 courses     │  │  K-12 content   │  │   │
│  │  │  CC-BY-NC-SA    │  │  CC-BY-NC-SA    │  │  CC-BY-NC       │  │   │
│  │  │                 │  │                 │  │                 │  │   │
│  │  │  [Browse →]     │  │  [Browse →]     │  │  [Browse →]     │  │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘  │   │
│  │                                                                  │   │
│  │  ┌─────────────────┐  ┌─────────────────┐                       │   │
│  │  │  [Fast.ai Logo] │  │  [Upload Icon]  │                       │   │
│  │  │                 │  │                 │                       │   │
│  │  │  Fast.ai        │  │  Manual         │                       │   │
│  │  │  Courses        │  │  Upload         │                       │   │
│  │  │                 │  │                 │                       │   │
│  │  │  AI/ML focused  │  │  ZIP or UMCF    │                       │   │
│  │  │  CC-BY          │  │  files          │                       │   │
│  │  │                 │  │                 │                       │   │
│  │  │  [Browse →]     │  │  [Upload →]     │                       │   │
│  │  └─────────────────┘  └─────────────────┘                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Course Browser (MIT OCW Example)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  MIT OpenCourseWare                           [← Back to Sources]       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Search: [________________________] [🔍]                         │   │
│  │                                                                  │   │
│  │  Filters:                                                        │   │
│  │  Subject: [All ▼]  Level: [All ▼]  Features: [☑ Video] [☑ Trans]│   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌────────────────────────────────┬────────────────────────────────┐   │
│  │  Courses (2,500)               │  Preview                        │   │
│  │                                │                                 │   │
│  │  ┌──────────────────────────┐ │  ┌─────────────────────────────┐│   │
│  │  │ 📚 6.001 SICP           │ │  │  6.001 Structure and        ││   │
│  │  │    Abelson & Sussman    │ │  │  Interpretation of Computer ││   │
│  │  │    ⭐ Video ⭐ Transcript │ │  │  Programs                   ││   │
│  │  │    Computer Science     │ │  │                              ││   │
│  │  └──────────────────────────┘ │  │  Instructors:               ││   │
│  │  ┌──────────────────────────┐ │  │  Harold Abelson             ││   │
│  │  │ 📚 18.06 Linear Algebra │ │  │  Gerald Sussman             ││   │
│  │  │    Gilbert Strang       │ │  │                              ││   │
│  │  │    ⭐ Video ⭐ Transcript │ │  │  Spring 2005                ││   │
│  │  │    Mathematics          │ │  │                              ││   │
│  │  └──────────────────────────┘ │  │  This course covers the     ││   │
│  │  ┌──────────────────────────┐ │  │  techniques used to control ││   │
│  │  │ 📚 8.01 Physics I       │ │  │  the intellectual complexity││   │
│  │  │    Walter Lewin         │ │  │  of large software systems. ││   │
│  │  │    ⭐ Video ⭐ Transcript │ │  │                              ││   │
│  │  │    Physics              │ │  │  Materials:                  ││   │
│  │  └──────────────────────────┘ │  │  ☑ 28 Video Lectures        ││   │
│  │  ┌──────────────────────────┐ │  │  ☑ Transcripts              ││   │
│  │  │ 📚 6.006 Algorithms     │ │  │  ☑ Lecture Notes (PDF)      ││   │
│  │  │    Erik Demaine         │ │  │  ☑ Assignments (5)          ││   │
│  │  │    ⭐ Video              │ │  │  ☑ Exams (2)                ││   │
│  │  │    Computer Science     │ │  │                              ││   │
│  │  └──────────────────────────┘ │  │  License: CC-BY-NC-SA 4.0   ││   │
│  │                                │  │                              ││   │
│  │  [Load More...]               │  │  [View Full Details]         ││   │
│  │                                │  │  [Import This Course →]     ││   │
│  └────────────────────────────────┴──────────────────────────────────┘│
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Course Detail / Import Configuration

```
┌─────────────────────────────────────────────────────────────────────────┐
│  6.001 Structure and Interpretation of Computer Programs   [← Back]     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Course Information                                              │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  📖 Description:                                                 │   │
│  │  This course introduces students to the principles of           │   │
│  │  computation. It covers the techniques used to control the      │   │
│  │  intellectual complexity of large software systems...           │   │
│  │                                                                  │   │
│  │  👤 Instructors: Harold Abelson, Gerald Sussman                 │   │
│  │  📅 Semester: Spring 2005                                       │   │
│  │  🏛️ Department: Electrical Engineering & Computer Science       │   │
│  │                                                                  │   │
│  │  ⚖️ License: CC-BY-NC-SA 4.0                                    │   │
│  │     Attribution: Required                                        │   │
│  │     Commercial Use: Not Permitted                                │   │
│  │     Derivative Works: Share-Alike Required                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Content Preview                                    [Expand All] │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  📹 Lectures (28)                                               │   │
│  │  ├─ Lecture 1: Building Abstractions with Procedures           │   │
│  │  ├─ Lecture 2: Higher-order Procedures                         │   │
│  │  ├─ Lecture 3: Compound Data                                   │   │
│  │  └─ ... [Show All]                                             │   │
│  │                                                                  │   │
│  │  📝 Assignments (5)                                             │   │
│  │  ├─ Project 1: Collaborative Work                              │   │
│  │  ├─ Project 2: Web Development                                 │   │
│  │  └─ ...                                                        │   │
│  │                                                                  │   │
│  │  📋 Exams (2)                                                   │   │
│  │  ├─ Quiz 1 (with solutions)                                    │   │
│  │  └─ Quiz 2 (with solutions)                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Import Options                                                  │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  Content Selection:                                              │   │
│  │  [☑] Lecture transcripts (primary content)                      │   │
│  │  [☑] Lecture notes (PDFs)                                       │   │
│  │  [☑] Assignments with solutions                                 │   │
│  │  [☑] Exams with solutions                                       │   │
│  │  [☐] Video files (large, ~5GB)                                  │   │
│  │                                                                  │   │
│  │  AI Enrichment:                                                  │   │
│  │  [☑] Generate learning objectives                               │   │
│  │  [☑] Create comprehension checkpoints                           │   │
│  │  [☑] Generate spoken text variants                              │   │
│  │  [☑] Build knowledge graph                                      │   │
│  │  [☐] Generate additional practice problems                      │   │
│  │                                                                  │   │
│  │  Output Name: [6001-sicp_________________________]              │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                  │   │
│  │  Estimated Import Time: ~15-20 minutes                          │   │
│  │  Estimated Output Size: ~5MB (without videos)                   │   │
│  │                                                                  │   │
│  │        [Cancel]                    [Start Import →]             │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Import Progress Tracker

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Importing: 6.001 SICP                                    [← Back]      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Overall Progress                                                │   │
│  │  ════════════════════════════════════════════════════           │   │
│  │  ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  45%       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Pipeline Stages                                                 │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  ✅ 1. Download                     Completed (2.3MB)           │   │
│  │  ✅ 2. Validation                   License: CC-BY-NC-SA 4.0    │   │
│  │  ✅ 3. Content Extraction           28 lectures, 5 assignments  │   │
│  │  🔄 4. AI Enrichment                                            │   │
│  │     │                                                           │   │
│  │     ├─ ✅ Stage 1: Content Analysis     Collegiate, CS domain   │   │
│  │     ├─ ✅ Stage 2: Structure Inference  28 topics identified    │   │
│  │     ├─ 🔄 Stage 3: Segmentation         Processing (12/28)      │   │
│  │     ├─ ⏳ Stage 4: Objectives           Pending                 │   │
│  │     ├─ ⏳ Stage 5: Assessments          Pending                 │   │
│  │     ├─ ⏳ Stage 6: Tutoring Enhancement Pending                 │   │
│  │     └─ ⏳ Stage 7: Knowledge Graph      Pending                 │   │
│  │  ⏳ 5. Quality Validation           Pending                     │   │
│  │  ⏳ 6. UMCF Generation              Pending                     │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Current Activity                                                │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  🔄 Segmenting Lecture 12: Computational Objects                │   │
│  │     Creating 3-5 minute segments with stopping points...        │   │
│  │     Segments created: 8/15                                      │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Activity Log                                      [View Full]   │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │
│  │                                                                  │   │
│  │  14:23:45  Extracted 156 segments from lecture transcripts      │   │
│  │  14:23:32  Identified 28 lecture topics from navigation         │   │
│  │  14:23:18  Detected domain: computer-science                    │   │
│  │  14:22:55  Validated license: CC-BY-NC-SA 4.0                   │   │
│  │  14:22:30  Downloaded course package (2.3MB)                    │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│        [Cancel Import]                                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### New Components

```
src/components/dashboard/
├── curriculum-panel.tsx           # EXISTING - Update to add sub-navigation
├── sources/                       # NEW - Source browser components
│   ├── index.ts                  # Barrel export
│   ├── source-browser.tsx        # Main container with sub-navigation
│   ├── source-selection.tsx      # Source cards grid
│   ├── course-browser.tsx        # Course catalog browser
│   ├── course-preview.tsx        # Course detail preview panel
│   ├── course-detail.tsx         # Full course details + import config
│   ├── import-progress.tsx       # Import progress tracker
│   └── source-config.ts          # Source definitions and metadata
```

### Type Definitions

```typescript
// types/sources.ts

/**
 * Source Configuration
 */
interface CurriculumSource {
  id: string;                      // e.g., "mit_ocw", "stanford_see"
  name: string;                    // Display name
  description: string;             // Short description
  logoUrl?: string;                // Source logo
  license: LicenseInfo;            // License details
  courseCount: number | "2500+";   // Approximate course count
  features: SourceFeature[];       // Available features
  status: "active" | "coming_soon" | "maintenance";
}

interface SourceFeature {
  id: string;                      // e.g., "video", "transcript", "assessments"
  name: string;
  available: boolean;
}

interface LicenseInfo {
  type: string;                    // e.g., "CC-BY-NC-SA-4.0"
  name: string;                    // Full license name
  url: string;                     // License URL
  attributionRequired: boolean;
  commercialUse: boolean;
  derivativesAllowed: boolean;
  shareAlike: boolean;
  restrictions?: string[];         // e.g., ["LOGIC course requires separate permission"]
}

/**
 * Course Catalog
 */
interface CourseCatalogEntry {
  id: string;                      // Source-specific ID (e.g., "6.001")
  sourceId: string;                // Parent source
  title: string;
  instructors: string[];
  department?: string;
  semester?: string;
  description: string;
  level: "introductory" | "intermediate" | "advanced";
  features: CourseFeature[];       // What's available
  license: LicenseInfo;
  thumbnailUrl?: string;
}

interface CourseFeature {
  type: "video" | "transcript" | "lecture_notes" | "assignments" | "exams" | "code";
  count?: number;
  available: boolean;
}

/**
 * Course Detail (Full Information)
 */
interface CourseDetail extends CourseCatalogEntry {
  syllabus?: string;               // Full syllabus text
  prerequisites?: string[];
  lectures: LectureInfo[];
  assignments: AssignmentInfo[];
  exams: ExamInfo[];
  estimatedImportTime: string;     // e.g., "15-20 minutes"
  estimatedOutputSize: string;     // e.g., "5MB"
}

interface LectureInfo {
  id: string;
  number: number;
  title: string;
  duration?: string;
  hasVideo: boolean;
  hasTranscript: boolean;
  hasNotes: boolean;
}

interface AssignmentInfo {
  id: string;
  title: string;
  hasSolutions: boolean;
}

interface ExamInfo {
  id: string;
  title: string;
  type: "quiz" | "midterm" | "final";
  hasSolutions: boolean;
}

/**
 * Import Configuration
 */
interface ImportConfig {
  sourceId: string;
  courseId: string;
  outputName: string;

  // Content selection
  includeTranscripts: boolean;
  includeLectureNotes: boolean;
  includeAssignments: boolean;
  includeExams: boolean;
  includeVideos: boolean;          // Usually false (large files)

  // AI Enrichment options
  generateObjectives: boolean;
  createCheckpoints: boolean;
  generateSpokenText: boolean;
  buildKnowledgeGraph: boolean;
  generatePracticeProblems: boolean;
}

/**
 * Import Progress
 */
interface ImportProgress {
  id: string;                      // Import job ID
  config: ImportConfig;
  status: "queued" | "downloading" | "extracting" | "enriching" | "validating" | "complete" | "failed";
  overallProgress: number;         // 0-100
  currentStage: string;
  currentActivity: string;

  stages: ImportStage[];
  log: ImportLogEntry[];

  result?: ImportResult;
  error?: string;
}

interface ImportStage {
  id: string;
  name: string;
  status: "pending" | "running" | "complete" | "failed";
  progress?: number;
  details?: string;
  substages?: ImportStage[];       // For AI enrichment stages
}

interface ImportLogEntry {
  timestamp: string;
  level: "info" | "warning" | "error";
  message: string;
}

interface ImportResult {
  curriculumId: string;
  title: string;
  topicCount: number;
  assessmentCount: number;
  outputPath: string;
  outputSize: string;
  license: LicenseInfo;
}
```

### API Endpoints

```typescript
// New API routes for source browser

// GET /api/sources
// Returns list of configured curriculum sources
interface SourcesResponse {
  sources: CurriculumSource[];
}

// GET /api/sources/{sourceId}/courses
// Returns course catalog for a source
interface CourseCatalogResponse {
  source: CurriculumSource;
  courses: CourseCatalogEntry[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
  };
  filters: {
    subjects: string[];
    levels: string[];
    features: string[];
  };
}

// GET /api/sources/{sourceId}/courses/{courseId}
// Returns full course details
interface CourseDetailResponse {
  course: CourseDetail;
  canImport: boolean;              // License check result
  licenseWarnings?: string[];
}

// POST /api/imports
// Start a new import job
interface StartImportRequest {
  config: ImportConfig;
}
interface StartImportResponse {
  importId: string;
  status: "queued";
}

// GET /api/imports/{importId}
// Get import progress
interface ImportProgressResponse {
  progress: ImportProgress;
}

// DELETE /api/imports/{importId}
// Cancel an import job
interface CancelImportResponse {
  cancelled: boolean;
}

// GET /api/imports
// List recent/active imports
interface ImportsListResponse {
  imports: ImportProgress[];
}
```

---

## Backend Integration

### Python Backend Structure

```
server/
├── management/
│   ├── curriculum_sources/        # NEW - Source handlers
│   │   ├── __init__.py
│   │   ├── base.py               # Abstract source handler
│   │   ├── mit_ocw.py            # MIT OCW catalog & download
│   │   ├── stanford_see.py       # Stanford SEE catalog & download
│   │   ├── ck12.py               # CK-12 catalog & download
│   │   └── fastai.py             # Fast.ai catalog & download
│   │
│   ├── import_pipeline/          # NEW - Import orchestration
│   │   ├── __init__.py
│   │   ├── orchestrator.py       # Main import coordinator
│   │   ├── downloader.py         # Content download handler
│   │   ├── extractor.py          # Content extraction
│   │   └── progress_tracker.py   # Progress reporting
│   │
│   └── api/
│       └── sources.py            # NEW - API endpoints for sources
```

### Source Handler Base Class

```python
# server/management/curriculum_sources/base.py

from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from dataclasses import dataclass

@dataclass
class CourseInfo:
    id: str
    title: str
    instructors: List[str]
    description: str
    level: str
    features: List[Dict]
    license: Dict

@dataclass
class CourseDetail(CourseInfo):
    syllabus: Optional[str]
    lectures: List[Dict]
    assignments: List[Dict]
    exams: List[Dict]

class CurriculumSourceHandler(ABC):
    """
    Abstract base class for curriculum source handlers.

    Each source (MIT OCW, Stanford SEE, etc.) implements this
    to provide catalog browsing and content download.
    """

    @property
    @abstractmethod
    def source_id(self) -> str:
        """Unique identifier for this source"""
        pass

    @property
    @abstractmethod
    def source_name(self) -> str:
        """Display name for this source"""
        pass

    @property
    @abstractmethod
    def license_info(self) -> Dict:
        """Default license information"""
        pass

    @abstractmethod
    async def get_course_catalog(
        self,
        page: int = 1,
        page_size: int = 20,
        filters: Optional[Dict] = None,
        search: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get paginated course catalog.

        Returns:
            {
                "courses": [...],
                "pagination": {...},
                "filters": {...}
            }
        """
        pass

    @abstractmethod
    async def get_course_detail(self, course_id: str) -> CourseDetail:
        """
        Get full details for a specific course.

        Args:
            course_id: Source-specific course identifier

        Returns:
            CourseDetail with full information

        Raises:
            LicenseRestrictionError if course cannot be imported
        """
        pass

    @abstractmethod
    async def download_course(
        self,
        course_id: str,
        output_dir: str,
        progress_callback: Optional[callable] = None
    ) -> str:
        """
        Download course content to local directory.

        Args:
            course_id: Course to download
            output_dir: Where to save content
            progress_callback: Called with (current, total, message)

        Returns:
            Path to downloaded content
        """
        pass

    @abstractmethod
    def validate_license(self, course_id: str) -> Dict:
        """
        Validate that course can be imported under its license.

        Returns:
            {
                "can_import": bool,
                "license": {...},
                "warnings": [...],
                "attribution": str
            }
        """
        pass
```

### Import Orchestrator

```python
# server/management/import_pipeline/orchestrator.py

import asyncio
from typing import Optional, Callable
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

class ImportStatus(Enum):
    QUEUED = "queued"
    DOWNLOADING = "downloading"
    EXTRACTING = "extracting"
    ENRICHING = "enriching"
    VALIDATING = "validating"
    COMPLETE = "complete"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class ImportJob:
    id: str
    config: dict
    status: ImportStatus = ImportStatus.QUEUED
    progress: float = 0.0
    current_stage: str = ""
    current_activity: str = ""
    stages: list = field(default_factory=list)
    log: list = field(default_factory=list)
    result: Optional[dict] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)

class ImportOrchestrator:
    """
    Orchestrates the full curriculum import pipeline.

    Pipeline stages:
    1. Download - Fetch content from source
    2. Validate - Check license and structure
    3. Extract - Parse content into intermediate format
    4. Enrich - Run AI enrichment pipeline (7 sub-stages)
    5. Validate - Quality checks
    6. Generate - Create UMCF output
    """

    def __init__(
        self,
        source_handlers: dict,
        enrichment_pipeline,
        output_dir: str
    ):
        self.source_handlers = source_handlers
        self.enrichment_pipeline = enrichment_pipeline
        self.output_dir = output_dir
        self.jobs: dict[str, ImportJob] = {}

    async def start_import(self, config: dict) -> str:
        """
        Start a new import job.

        Args:
            config: ImportConfig with source, course, and options

        Returns:
            Job ID for tracking progress
        """
        import uuid

        job_id = str(uuid.uuid4())
        job = ImportJob(
            id=job_id,
            config=config,
            stages=self._create_stage_list(config)
        )
        self.jobs[job_id] = job

        # Start import in background
        asyncio.create_task(self._run_import(job))

        return job_id

    async def _run_import(self, job: ImportJob):
        """Run the full import pipeline"""
        try:
            config = job.config
            source_handler = self.source_handlers[config["sourceId"]]

            # Stage 1: Download
            job.status = ImportStatus.DOWNLOADING
            job.current_stage = "download"
            self._log(job, "info", "Starting download...")

            content_path = await source_handler.download_course(
                config["courseId"],
                self.output_dir,
                progress_callback=lambda c, t, m: self._update_progress(job, "download", c/t, m)
            )
            self._complete_stage(job, "download", f"Downloaded to {content_path}")

            # Stage 2: Validate license
            job.current_stage = "validate_license"
            self._log(job, "info", "Validating license...")

            license_result = source_handler.validate_license(config["courseId"])
            if not license_result["can_import"]:
                raise LicenseRestrictionError(license_result["warnings"][0])
            self._complete_stage(job, "validate_license", f"License: {license_result['license']['type']}")

            # Stage 3: Extract content
            job.status = ImportStatus.EXTRACTING
            job.current_stage = "extract"
            self._log(job, "info", "Extracting content...")

            # Get importer for this source
            importer = self._get_importer(config["sourceId"])
            with open(content_path, "rb") as f:
                content = f.read()

            raw_data = await importer.extract(content)
            self._complete_stage(job, "extract", f"Extracted {len(raw_data.get('sections', []))} sections")

            # Stage 4: AI Enrichment
            job.status = ImportStatus.ENRICHING
            job.current_stage = "enrich"

            if any([
                config.get("generateObjectives"),
                config.get("createCheckpoints"),
                config.get("generateSpokenText"),
                config.get("buildKnowledgeGraph")
            ]):
                enriched = await self._run_enrichment(job, raw_data, config)
            else:
                enriched = raw_data

            self._complete_stage(job, "enrich", "Enrichment complete")

            # Stage 5: Quality validation
            job.status = ImportStatus.VALIDATING
            job.current_stage = "quality"
            self._log(job, "info", "Running quality checks...")

            quality_result = await self._validate_quality(enriched)
            self._complete_stage(job, "quality", f"Quality score: {quality_result['score']:.0%}")

            # Stage 6: Generate UMCF
            job.current_stage = "generate"
            self._log(job, "info", "Generating UMCF output...")

            umlcf = await importer.parse(content)
            output_path = self._save_umlcf(umlcf, config["outputName"])
            self._complete_stage(job, "generate", f"Saved to {output_path}")

            # Complete
            job.status = ImportStatus.COMPLETE
            job.progress = 100.0
            job.result = {
                "curriculumId": umlcf.id.value,
                "title": umlcf.title,
                "topicCount": self._count_topics(umlcf),
                "assessmentCount": self._count_assessments(umlcf),
                "outputPath": output_path,
                "license": license_result["license"]
            }
            self._log(job, "info", f"Import complete: {umlcf.title}")

        except Exception as e:
            job.status = ImportStatus.FAILED
            job.error = str(e)
            self._log(job, "error", f"Import failed: {e}")

    async def _run_enrichment(self, job: ImportJob, raw_data: dict, config: dict) -> dict:
        """Run AI enrichment pipeline with progress tracking"""

        enrichment_stages = [
            ("analysis", "Content Analysis", config.get("generateObjectives", True)),
            ("structure", "Structure Inference", True),
            ("segmentation", "Segmentation", config.get("createCheckpoints", True)),
            ("objectives", "Learning Objectives", config.get("generateObjectives", True)),
            ("assessments", "Assessment Enhancement", True),
            ("tutoring", "Tutoring Enhancement", config.get("generateSpokenText", True)),
            ("knowledge_graph", "Knowledge Graph", config.get("buildKnowledgeGraph", True)),
        ]

        result = raw_data

        for stage_id, stage_name, enabled in enrichment_stages:
            if not enabled:
                self._skip_stage(job, f"enrich_{stage_id}")
                continue

            job.current_activity = f"Running {stage_name}..."
            self._log(job, "info", f"Starting enrichment stage: {stage_name}")

            try:
                result = await self.enrichment_pipeline.run_stage(
                    stage_id,
                    result,
                    progress_callback=lambda p, m: self._update_substage(job, f"enrich_{stage_id}", p, m)
                )
                self._complete_stage(job, f"enrich_{stage_id}", f"{stage_name} complete")
            except Exception as e:
                self._log(job, "warning", f"Enrichment stage {stage_name} failed: {e}")
                # Continue with other stages

        return result

    def get_progress(self, job_id: str) -> Optional[ImportJob]:
        """Get current progress for a job"""
        return self.jobs.get(job_id)

    def cancel_import(self, job_id: str) -> bool:
        """Cancel an import job"""
        job = self.jobs.get(job_id)
        if job and job.status in [ImportStatus.QUEUED, ImportStatus.DOWNLOADING, ImportStatus.EXTRACTING, ImportStatus.ENRICHING]:
            job.status = ImportStatus.CANCELLED
            self._log(job, "info", "Import cancelled by user")
            return True
        return False
```

---

## Implementation Phases

### Phase 1: Foundation (3-4 days)

1. **Create component structure**
   - Add `sources/` directory under `components/dashboard/`
   - Create base components and types

2. **Implement source selection page**
   - Source cards with logos and metadata
   - Static source configuration

3. **Add navigation to curriculum panel**
   - Sub-tabs: My Library / Import Sources / Visual Assets
   - Route handling

### Phase 2: Course Browser (4-5 days)

1. **Implement course catalog browser**
   - Course list with filtering
   - Search functionality
   - Preview panel

2. **Create course detail view**
   - Full course information
   - Content preview (lectures, assignments)
   - License display

3. **Backend: Source handlers**
   - MIT OCW catalog (start with static, then live)
   - Stanford SEE catalog
   - API endpoints for catalog

### Phase 3: Import Pipeline (5-6 days)

1. **Implement import configuration**
   - Content selection options
   - Enrichment options
   - Output naming

2. **Create progress tracker**
   - Stage progress display
   - Activity log
   - Cancel functionality

3. **Backend: Import orchestration**
   - Download handling
   - Extraction integration
   - Enrichment integration

### Phase 4: Testing & Polish (2-3 days)

1. **Test with real sources**
   - Import MIT OCW course
   - Import Stanford SEE course

2. **Error handling**
   - License restriction UI
   - Download failure recovery
   - Enrichment error handling

3. **Polish UI**
   - Loading states
   - Error messages
   - Success feedback

---

## Success Criteria

### Must Have
- [ ] Source selection page shows all configured sources
- [ ] Course browser displays catalog for MIT OCW and Stanford SEE
- [ ] Course preview shows key information and license
- [ ] Import configuration allows content and enrichment selection
- [ ] Progress tracker shows real-time import status
- [ ] License information is preserved in imported curriculum
- [ ] Stanford SEE Logic course is blocked with clear explanation

### Should Have
- [ ] Course search and filtering
- [ ] Import history list
- [ ] Cancel in-progress imports
- [ ] Estimated import time display

### Nice to Have
- [ ] Course recommendations
- [ ] Import templates/presets
- [ ] Bulk import selection
- [ ] Import scheduling

---

## iOS Client: Simple UMCF Loader

For the iOS client, we keep it simple for now:

```swift
// Simple curriculum loader for iOS
// Loads pre-built .umcf files exported from server

class CurriculumLoader {
    /// Load a UMCF curriculum file
    func loadCurriculum(from url: URL) async throws -> UMCFDocument {
        let data = try Data(contentsOf: url)
        let document = try JSONDecoder().decode(UMCFDocument.self, from: data)

        // Validate license is present
        guard document.rights != nil else {
            throw CurriculumError.missingLicense
        }

        return document
    }

    /// Import from Files app
    func importFromFiles() async throws -> UMCFDocument {
        // Present document picker for .umcf files
        // Load selected file
    }

    /// Import from shared URL (AirDrop, etc.)
    func importFromURL(_ url: URL) async throws -> UMCFDocument {
        // Load from incoming URL
    }
}
```

The full import pipeline runs on the server; the iOS client just consumes the resulting UMCF files.
