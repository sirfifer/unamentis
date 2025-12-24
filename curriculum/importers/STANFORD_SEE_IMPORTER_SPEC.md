# Stanford Engineering Everywhere Importer Specification

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-12-23
**Target Audience:** Collegiate (Undergraduate/Graduate)

---

## Table of Contents

1. [Overview](#overview)
2. [Stanford SEE Platform Analysis](#stanford-see-platform-analysis)
3. [Licensing Requirements](#licensing-requirements)
4. [Supported Formats](#supported-formats)
5. [Data Mapping](#data-mapping)
6. [Implementation Specification](#implementation-specification)
7. [Content Extraction](#content-extraction)
8. [AI Enrichment Integration](#ai-enrichment-integration)
9. [Error Handling](#error-handling)
10. [Testing Strategy](#testing-strategy)

---

## Overview

The Stanford SEE importer converts Stanford Engineering Everywhere course packages into UMLCF format for use with UnaMentis's conversational AI tutoring system. SEE provides complete Stanford engineering courses including video lectures, handouts, assignments, and exams.

### Why Stanford SEE?

| Criterion | Assessment |
|-----------|------------|
| **License** | CC-BY-NC-SA 4.0 (with one exception, see below) |
| **Cost** | Free |
| **Quality** | Stanford University courses, world-class instructors (Andrew Ng, Stephen Boyd) |
| **Formats** | MP4 video, PDF documents, ZIP archives |
| **Coverage** | 10 courses in CS, AI/ML, Math, EE |
| **Structure** | Course → Lectures → Materials (maps to UMLCF hierarchy) |
| **Transcripts** | HTML and PDF transcripts for all video lectures |

### Import Scope

**In Scope:**
- Course ZIP packages (non-video materials)
- PDF lecture notes, handouts, assignments, exams, solutions
- Video transcripts (HTML and PDF formats)
- Syllabus and course information
- Video metadata (URLs, duration, topics)

**Out of Scope:**
- Video files themselves (URL references only, 500MB+ per course)
- MATLAB/software executables
- External server dependencies

---

## Stanford SEE Platform Analysis

### Available Courses

Stanford SEE provides 10 complete engineering courses:

| Category | Course | Title | Instructor | Lectures |
|----------|--------|-------|------------|----------|
| **CS Intro** | CS106A | Programming Methodology | Mehran Sahami | 28 |
| **CS Intro** | CS106B | Programming Abstractions | Julie Zelenski | 27 |
| **CS Intro** | CS107 | Programming Paradigms | Jerry Cain | 27 |
| **AI/ML** | CS223A | Introduction to Robotics | Oussama Khatib | 16 |
| **AI/ML** | CS229 | Machine Learning | Andrew Ng | 20 |
| **Math/EE** | EE261 | Fourier Transform and Applications | Brad Osgood | 30 |
| **Math/EE** | EE263 | Linear Dynamical Systems | Stephen Boyd | 20 |
| **Math/EE** | EE364A | Convex Optimization I | Stephen Boyd | 19 |
| **Math/EE** | EE364B | Convex Optimization II | Stephen Boyd | 8 |
| **Logic** | LOGIC | Introduction to Logic | Michael Genesereth | **Special License** |

### Content Organization

Each SEE course follows a consistent structure:

```
Course Website
├── Course Info
│   ├── Syllabus
│   ├── Schedule
│   └── Prerequisites
├── Course Materials (ZIP Download)
│   ├── handouts/
│   │   ├── lecture1.pdf
│   │   ├── lecture2.pdf
│   │   └── ...
│   ├── assignments/
│   │   ├── assignment1.pdf
│   │   ├── assignment1_solution.pdf
│   │   └── ...
│   ├── exams/
│   │   ├── midterm.pdf
│   │   ├── midterm_solution.pdf
│   │   ├── final.pdf
│   │   └── final_solution.pdf
│   └── additional/
│       └── supplementary materials
├── Video Lectures
│   ├── Lecture 1 (MP4 + Transcript HTML + Transcript PDF)
│   ├── Lecture 2 (MP4 + Transcript HTML + Transcript PDF)
│   └── ...
└── Lecture Notes (12-20 PDFs per course)
```

---

## Licensing Requirements

### CRITICAL: License Preservation

**All imported content MUST preserve original licensing information and honor all license conditions.**

### Standard License (9 of 10 courses)

| Field | Value |
|-------|-------|
| **License Type** | CC-BY-NC-SA 4.0 |
| **Full Name** | Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International |
| **URL** | https://creativecommons.org/licenses/by-nc-sa/4.0/ |
| **Permissions** | Share, Adapt |
| **Conditions** | Attribution, NonCommercial, ShareAlike |

**Required Attribution Format:**
```
This content is derived from Stanford Engineering Everywhere (see.stanford.edu),
provided by Stanford University, and licensed under CC-BY-NC-SA 4.0.
```

### Special License: Introduction to Logic

**The Logic course has different licensing arrangements.**

| Field | Value |
|-------|-------|
| **Course** | Stanford Introduction to Logic |
| **License Type** | Custom (requires permission) |
| **Contact** | intrologic@googlegroups.com |
| **Handling** | Must contact for reuse permissions |

**Importer Behavior for Logic Course:**
```python
if course_id == "LOGIC":
    raise LicenseRestrictionError(
        "The Stanford Introduction to Logic course has a custom license. "
        "Contact intrologic@googlegroups.com for reuse permissions before importing."
    )
```

### License Validation Implementation

```python
class StanfordSEELicenseValidator:
    """
    Validate and preserve Stanford SEE licensing information.

    CRITICAL: All content must maintain proper attribution and license info.
    """

    STANDARD_LICENSE = {
        "type": "CC-BY-NC-SA-4.0",
        "name": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International",
        "url": "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        "permissions": ["share", "adapt"],
        "conditions": ["attribution", "noncommercial", "sharealike"],
    }

    RESTRICTED_COURSES = {
        "LOGIC": {
            "reason": "Custom licensing arrangement",
            "contact": "intrologic@googlegroups.com",
            "importable": False,
        }
    }

    REQUIRED_ATTRIBUTION = {
        "required": True,
        "format": (
            "This content is derived from Stanford Engineering Everywhere (see.stanford.edu), "
            "provided by Stanford University, and licensed under CC-BY-NC-SA 4.0."
        ),
        "holder": {
            "name": "Stanford University",
            "url": "https://see.stanford.edu/"
        }
    }

    def validate_course_license(self, course_id: str) -> ValidationResult:
        """
        Validate that a course can be imported under its license terms.

        Returns:
            ValidationResult with license details or restriction notice
        """
        if course_id.upper() in self.RESTRICTED_COURSES:
            restriction = self.RESTRICTED_COURSES[course_id.upper()]
            return ValidationResult(
                is_valid=False,
                errors=[
                    f"Course {course_id} has restricted licensing: {restriction['reason']}",
                    f"Contact {restriction['contact']} for permissions before importing."
                ],
                metadata={"license_restriction": restriction}
            )

        return ValidationResult(
            is_valid=True,
            metadata={
                "license": self.STANDARD_LICENSE,
                "attribution": self.REQUIRED_ATTRIBUTION,
            }
        )

    def build_rights_block(self, course_id: str) -> Dict:
        """
        Build UMLCF rights block with full license preservation.

        This block MUST be included in all imported content.
        """
        validation = self.validate_course_license(course_id)
        if not validation.is_valid:
            raise LicenseRestrictionError(validation.errors[0])

        return {
            "license": self.STANDARD_LICENSE,
            "attribution": self.REQUIRED_ATTRIBUTION,
            "holder": {
                "name": "Stanford University",
                "url": "https://see.stanford.edu/"
            },
            "sourceUrl": f"https://see.stanford.edu/Course/{course_id}",
            "importedAt": datetime.utcnow().isoformat(),
            "originalFormat": "Stanford Engineering Everywhere",
        }
```

---

## Supported Formats

### Primary: Course Materials ZIP

Each course provides a ZIP download of all non-video materials:

```python
STANFORD_SEE_ZIP_STRUCTURE = {
    # Core directories
    "handouts/": "Lecture slides and handouts (PDF)",
    "assignments/": "Problem sets with solutions (PDF)",
    "exams/": "Midterms, finals with solutions (PDF)",
    "supplementary/": "Additional reading materials",

    # File types
    ".pdf": "Primary document format",
    ".zip": "Nested archives (code, data)",
    ".m": "MATLAB code files",
    ".py": "Python code files",
    ".java": "Java source files",
    ".txt": "Text files, READMEs",
}
```

### Secondary: Video Transcripts

Transcripts are the primary content source for lecture-based tutoring:

| Format | Description | Parsing Strategy |
|--------|-------------|------------------|
| **HTML Transcript** | Structured HTML with timestamps | Parse DOM, extract segments |
| **PDF Transcript** | Formatted PDF document | Extract text, infer structure |

### Tertiary: Course Website Scraping

For courses without ZIP downloads or for metadata extraction:
- Respect rate limits
- Cache responses
- Extract syllabus, schedule, prerequisites

---

## Data Mapping

### Metadata Mapping

| Stanford SEE Element | UMLCF Field | Notes |
|----------------------|-------------|-------|
| Course Number (CS229) | `id.value` | Prefixed with "STANFORD-SEE-" |
| Course Title | `title` | Full course title |
| Instructor Name | `lifecycle.contributors[0].name` | Primary instructor |
| "Stanford University" | `lifecycle.contributors[].organization` | Always included |
| Course Description | `description` | From syllabus |
| Prerequisites | `educational.audience.prerequisites` | Extracted from course info |
| CC-BY-NC-SA 4.0 | `rights.license` | **MANDATORY** |
| "see.stanford.edu" | `rights.sourceUrl` | **MANDATORY** |

### Content Hierarchy Mapping

| Stanford SEE Level | UMLCF Type | Example |
|--------------------|------------|---------|
| Course | Root curriculum | "CS229 Machine Learning" |
| Lecture Set | `module` | "Supervised Learning" |
| Individual Lecture | `topic` | "Lecture 2: Linear Regression" |
| Transcript Segment | `transcript.segments[]` | 3-5 minute content block |
| Problem Set | `module` with `assessments[]` | "Assignment 1" |

### Assessment Mapping

| Stanford SEE Assessment | UMLCF Type | Transformation |
|------------------------|------------|----------------|
| Problem Set Problem | `assessment` (text-entry) | Extract problem, add hints |
| Multiple Choice | `assessment` (choice) | Map choices directly |
| Exam Problem | `assessment` | Mark as summative |
| Solution | `feedback.correct` | Extract for feedback |

---

## Implementation Specification

### Module Structure

```python
umlcf_importer/
└── importers/
    └── stanford_see/
        ├── __init__.py
        ├── importer.py           # Main StanfordSEEImporter class
        ├── license_validator.py  # License validation (CRITICAL)
        ├── zip_parser.py         # Course materials ZIP extraction
        ├── transcript_parser.py  # Video transcript processing
        ├── pdf_extractor.py      # PDF content extraction
        ├── course_scraper.py     # Website metadata extraction
        ├── models.py             # Stanford SEE-specific models
        └── config.py             # Course-specific configuration
```

### StanfordSEEImporter Class

```python
from umlcf_importer.core.base import CurriculumImporter, ValidationResult
from umlcf_importer.core.models import CurriculumData
from typing import Dict, Any, List, Optional
from pathlib import Path
import zipfile

class StanfordSEEImporter(CurriculumImporter):
    """
    Importer for Stanford Engineering Everywhere course packages.

    Supports ZIP packages with PDF materials and video transcripts.
    Primary focus: Collegiate-level engineering, CS, and AI/ML courses.

    IMPORTANT: This importer preserves and validates licensing information.
    The Logic course (LOGIC) has special licensing and cannot be imported
    without explicit permission.
    """

    name = "stanford_see"
    description = "Import Stanford Engineering Everywhere courses (ZIP, transcripts)"
    file_extensions = [".zip", ".html", ".pdf"]

    # Stanford SEE specific configuration
    DEFAULT_CONFIG = {
        "extract_transcripts": True,
        "extract_pdfs": True,
        "extract_assessments": True,
        "include_solutions": True,
        "video_as_reference": True,
        "spoken_text_generation": True,
        "checkpoint_frequency": "per_topic",
        "parse_latex_math": True,
        "validate_license": True,  # MANDATORY - do not disable
    }

    # Course catalog with metadata
    COURSE_CATALOG = {
        "CS106A": {
            "title": "Programming Methodology",
            "instructor": "Mehran Sahami",
            "lectures": 28,
            "domain": "computer-science",
            "level": "introductory",
        },
        "CS106B": {
            "title": "Programming Abstractions",
            "instructor": "Julie Zelenski",
            "lectures": 27,
            "domain": "computer-science",
            "level": "introductory",
        },
        "CS107": {
            "title": "Programming Paradigms",
            "instructor": "Jerry Cain",
            "lectures": 27,
            "domain": "computer-science",
            "level": "intermediate",
        },
        "CS223A": {
            "title": "Introduction to Robotics",
            "instructor": "Oussama Khatib",
            "lectures": 16,
            "domain": "artificial-intelligence",
            "level": "advanced",
        },
        "CS229": {
            "title": "Machine Learning",
            "instructor": "Andrew Ng",
            "lectures": 20,
            "domain": "artificial-intelligence",
            "level": "advanced",
        },
        "EE261": {
            "title": "The Fourier Transform and its Applications",
            "instructor": "Brad G Osgood",
            "lectures": 30,
            "domain": "mathematics",
            "level": "advanced",
        },
        "EE263": {
            "title": "Introduction to Linear Dynamical Systems",
            "instructor": "Stephen Boyd",
            "lectures": 20,
            "domain": "mathematics",
            "level": "advanced",
        },
        "EE364A": {
            "title": "Convex Optimization I",
            "instructor": "Stephen Boyd",
            "lectures": 19,
            "domain": "mathematics",
            "level": "advanced",
        },
        "EE364B": {
            "title": "Convex Optimization II",
            "instructor": "Stephen Boyd",
            "lectures": 8,
            "domain": "mathematics",
            "level": "advanced",
        },
        "LOGIC": {
            "title": "Stanford Introduction to Logic",
            "instructor": "Michael Genesereth",
            "lectures": None,
            "domain": "logic",
            "level": "introductory",
            "license_restricted": True,  # SPECIAL HANDLING REQUIRED
        },
    }

    def __init__(
        self,
        storage: "StorageBackend",
        config: Optional[Dict[str, Any]] = None,
        logger: Optional["Logger"] = None
    ):
        super().__init__(storage, config, logger)
        self.config = {**self.DEFAULT_CONFIG, **(config or {})}

        # Initialize license validator (mandatory)
        self._license_validator = StanfordSEELicenseValidator()

        # Initialize sub-parsers
        self._zip_parser = None
        self._transcript_parser = None
        self._pdf_extractor = None

    async def validate(self, content: bytes, course_id: Optional[str] = None) -> ValidationResult:
        """
        Validate Stanford SEE content format and licensing.

        CRITICAL: License validation is mandatory and cannot be bypassed.

        Checks:
        - Valid ZIP structure
        - Course identification
        - License restrictions (blocks LOGIC course)
        - Contains expected materials
        """
        errors = []
        warnings = []
        metadata = {}

        # Detect format
        format_type = self._detect_format(content)
        metadata["format"] = format_type

        # If course_id provided, validate license first
        if course_id:
            license_result = self._license_validator.validate_course_license(course_id)
            if not license_result.is_valid:
                return ValidationResult(
                    is_valid=False,
                    errors=license_result.errors,
                    warnings=[],
                    format_version="Stanford SEE",
                    metadata={"license_blocked": True, **license_result.metadata}
                )
            metadata["license"] = license_result.metadata.get("license")

        if format_type == "zip":
            return await self._validate_zip(content, course_id)
        elif format_type == "html":
            return await self._validate_transcript(content)
        else:
            return ValidationResult(
                is_valid=False,
                errors=["Unknown or unsupported file format"],
                format_version=None,
                metadata={"detected_bytes": content[:20].hex()}
            )

    def _detect_format(self, content: bytes) -> str:
        """Detect file format from magic bytes"""
        if content[:4] == b'PK\x03\x04':  # ZIP
            return "zip"
        elif content[:5].lower() in (b'<!doc', b'<html', b'<?xml'):
            return "html"
        elif content[:5] == b'%PDF-':
            return "pdf"
        return "unknown"

    async def _validate_zip(self, content: bytes, course_id: Optional[str] = None) -> ValidationResult:
        """Validate Stanford SEE ZIP structure"""
        errors = []
        warnings = []
        metadata = {"format": "zip"}

        try:
            import io
            with zipfile.ZipFile(io.BytesIO(content)) as zf:
                namelist = zf.namelist()

                # Check for expected directories
                has_handouts = any("handout" in n.lower() for n in namelist)
                has_assignments = any("assignment" in n.lower() for n in namelist)

                if not has_handouts and not has_assignments:
                    warnings.append("No handouts or assignments found (may be incomplete)")

                # Try to detect course from content
                detected_course = self._detect_course_from_content(zf, namelist)
                if detected_course:
                    metadata["detected_course"] = detected_course

                    # Validate license for detected course
                    license_result = self._license_validator.validate_course_license(detected_course)
                    if not license_result.is_valid:
                        errors.extend(license_result.errors)
                        metadata["license_blocked"] = True

                # Count resources
                pdf_count = len([n for n in namelist if n.endswith('.pdf')])
                metadata["pdf_count"] = pdf_count
                metadata["file_count"] = len(namelist)

        except zipfile.BadZipFile:
            errors.append("Invalid ZIP file structure")
        except Exception as e:
            errors.append(f"ZIP validation error: {str(e)}")

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            format_version="Stanford SEE ZIP Package",
            metadata=metadata
        )

    def _detect_course_from_content(self, zf: zipfile.ZipFile, namelist: List[str]) -> Optional[str]:
        """Attempt to detect course ID from ZIP contents"""
        # Look for course indicators in filenames
        for course_id in self.COURSE_CATALOG.keys():
            course_lower = course_id.lower()
            for filename in namelist:
                if course_lower in filename.lower():
                    return course_id

        # Look in file contents
        for name in namelist[:10]:  # Sample first 10 files
            if name.endswith('.pdf'):
                continue  # Skip PDFs for now
            try:
                content = zf.read(name).decode('utf-8', errors='ignore')[:5000]
                for course_id in self.COURSE_CATALOG.keys():
                    if course_id in content:
                        return course_id
            except:
                pass

        return None

    async def extract(self, content: bytes, course_id: str) -> Dict[str, Any]:
        """
        Extract raw Stanford SEE structure before UMLCF transformation.

        Args:
            content: Raw ZIP file bytes
            course_id: Course identifier (e.g., "CS229")

        Returns:
            Intermediate representation with all extracted content
        """
        # Validate license first (mandatory)
        license_result = self._license_validator.validate_course_license(course_id)
        if not license_result.is_valid:
            raise LicenseRestrictionError(license_result.errors[0])

        format_type = self._detect_format(content)

        result = {
            "format": format_type,
            "course_id": course_id,
            "metadata": self._get_course_metadata(course_id),
            "license": license_result.metadata.get("license"),
            "attribution": license_result.metadata.get("attribution"),
            "lectures": [],
            "handouts": [],
            "assignments": [],
            "exams": [],
            "transcripts": [],
        }

        if format_type == "zip":
            return await self._extract_zip(content, result)
        else:
            raise ValueError(f"Unsupported format for extraction: {format_type}")

    async def _extract_zip(self, content: bytes, result: Dict) -> Dict:
        """Extract data from ZIP package"""
        import io

        with zipfile.ZipFile(io.BytesIO(content)) as zf:
            namelist = zf.namelist()

            # Categorize and extract files
            for filepath in namelist:
                filename = Path(filepath).name.lower()
                filepath_lower = filepath.lower()

                if filepath.endswith('.pdf'):
                    if "handout" in filepath_lower or "lecture" in filepath_lower:
                        result["handouts"].append(self._extract_pdf_info(zf, filepath))
                    elif "assignment" in filepath_lower or "homework" in filepath_lower:
                        is_solution = "solution" in filepath_lower or "answer" in filepath_lower
                        result["assignments"].append({
                            **self._extract_pdf_info(zf, filepath),
                            "is_solution": is_solution
                        })
                    elif "exam" in filepath_lower or "midterm" in filepath_lower or "final" in filepath_lower:
                        is_solution = "solution" in filepath_lower or "answer" in filepath_lower
                        result["exams"].append({
                            **self._extract_pdf_info(zf, filepath),
                            "is_solution": is_solution
                        })

        return result

    def _extract_pdf_info(self, zf: zipfile.ZipFile, filepath: str) -> Dict:
        """Extract information about a PDF file"""
        info = zf.getinfo(filepath)
        return {
            "path": filepath,
            "filename": Path(filepath).name,
            "size": info.file_size,
            "type": "pdf",
        }

    def _get_course_metadata(self, course_id: str) -> Dict:
        """Get course metadata from catalog"""
        catalog_entry = self.COURSE_CATALOG.get(course_id.upper(), {})
        return {
            "course_id": course_id.upper(),
            "title": catalog_entry.get("title", f"Stanford {course_id}"),
            "instructor": catalog_entry.get("instructor", "Unknown"),
            "domain": catalog_entry.get("domain", "engineering"),
            "level": catalog_entry.get("level", "collegiate"),
            "expected_lectures": catalog_entry.get("lectures"),
        }

    async def parse(self, content: bytes, course_id: str) -> CurriculumData:
        """
        Parse Stanford SEE content and transform to UMLCF format.

        IMPORTANT: This method ALWAYS includes proper licensing information.

        Full pipeline:
        1. Validate license (mandatory, cannot be skipped)
        2. Extract raw structure
        3. Map metadata to UMLCF
        4. Convert lectures to content nodes
        5. Process transcripts for segments
        6. Extract and map assessments
        7. Generate spoken text variants
        """
        # Step 1: Validate license (MANDATORY)
        license_result = self._license_validator.validate_course_license(course_id)
        if not license_result.is_valid:
            raise LicenseRestrictionError(license_result.errors[0])

        # Step 2: Extract
        raw = await self.extract(content, course_id)

        # Step 3: Build UMLCF structure with MANDATORY licensing
        umlcf = {
            "umlcf": "1.0.0",
            "id": self._generate_id(course_id),
            "title": raw["metadata"]["title"],
            "description": self._build_description(raw["metadata"]),
            "version": {
                "number": "1.0.0",
                "date": None
            },
            "lifecycle": self._build_lifecycle(raw["metadata"]),
            "metadata": self._build_metadata(raw["metadata"]),
            "educational": self._build_educational(raw["metadata"]),
            "rights": self._license_validator.build_rights_block(course_id),  # MANDATORY
            "content": [],
            "glossary": []
        }

        # Step 4: Transform handouts/lectures to content nodes
        lectures_module = await self._transform_lectures(raw)
        if lectures_module:
            umlcf["content"].append(lectures_module)

        # Step 5: Transform assignments
        if raw["assignments"]:
            assignments_module = await self._transform_assignments(raw["assignments"])
            umlcf["content"].append(assignments_module)

        # Step 6: Transform exams
        if raw["exams"]:
            exams_module = await self._transform_exams(raw["exams"])
            umlcf["content"].append(exams_module)

        return CurriculumData(**umlcf)

    def _generate_id(self, course_id: str) -> Dict:
        """Generate UMLCF ID from course identifier"""
        return {
            "catalog": "STANFORD-SEE",
            "value": course_id.upper()
        }

    def _build_description(self, metadata: Dict) -> str:
        """Build course description"""
        return (
            f"{metadata['title']} - A Stanford Engineering Everywhere course "
            f"taught by {metadata['instructor']}."
        )

    def _build_lifecycle(self, metadata: Dict) -> Dict:
        """Build UMLCF lifecycle from Stanford SEE metadata"""
        return {
            "status": "published",
            "contributors": [
                {
                    "role": "author",
                    "name": metadata["instructor"],
                    "organization": "Stanford University"
                },
                {
                    "role": "publisher",
                    "name": "Stanford Engineering Everywhere",
                    "organization": "Stanford University"
                }
            ]
        }

    def _build_metadata(self, metadata: Dict) -> Dict:
        """Build UMLCF metadata from Stanford SEE metadata"""
        keywords = [
            "Stanford",
            "Engineering",
            metadata["domain"],
            metadata["course_id"],
        ]

        return {
            "language": "en-US",
            "keywords": keywords,
            "structure": "hierarchical"
        }

    def _build_educational(self, metadata: Dict) -> Dict:
        """Build UMLCF educational context from Stanford SEE metadata"""
        level_mapping = {
            "introductory": "undergraduate",
            "intermediate": "undergraduate",
            "advanced": "graduate",
        }

        return {
            "audience": {
                "type": "learner",
                "educationalLevel": level_mapping.get(metadata["level"], "collegiate"),
                "prerequisites": []  # Will be enriched by AI pipeline
            },
            "alignment": [],
            "duration": {
                "estimated": metadata.get("expected_lectures", 20) * 1.5,  # ~1.5 hours per lecture
                "unit": "hours"
            }
        }

    async def _transform_lectures(self, raw: Dict) -> Optional[Dict]:
        """Transform lecture materials into content module"""
        if not raw["handouts"]:
            return None

        return {
            "id": {"value": f"{raw['course_id']}-lectures"},
            "title": "Video Lectures",
            "type": "module",
            "orderIndex": 0,
            "description": "Complete video lecture series with transcripts and handouts",
            "children": [
                {
                    "id": {"value": f"lecture-{i+1}"},
                    "title": f"Lecture {i+1}",
                    "type": "topic",
                    "orderIndex": i,
                    "resources": [
                        {
                            "type": "document",
                            "title": handout["filename"],
                            "url": handout["path"],
                        }
                    ]
                }
                for i, handout in enumerate(sorted(raw["handouts"], key=lambda x: x["filename"]))
            ]
        }

    async def _transform_assignments(self, assignments: List[Dict]) -> Dict:
        """Transform assignments into content module with assessments"""
        problems = [a for a in assignments if not a["is_solution"]]
        solutions = {
            self._get_assignment_number(a["filename"]): a
            for a in assignments if a["is_solution"]
        }

        children = []
        for i, problem in enumerate(sorted(problems, key=lambda x: x["filename"])):
            assignment_num = self._get_assignment_number(problem["filename"])
            solution = solutions.get(assignment_num)

            child = {
                "id": {"value": f"assignment-{assignment_num}"},
                "title": f"Assignment {assignment_num}",
                "type": "activity",
                "orderIndex": i,
                "resources": [
                    {
                        "type": "document",
                        "title": problem["filename"],
                        "url": problem["path"],
                    }
                ]
            }

            if solution:
                child["resources"].append({
                    "type": "document",
                    "title": f"Solution: {solution['filename']}",
                    "url": solution["path"],
                })

            children.append(child)

        return {
            "id": {"value": f"assignments"},
            "title": "Assignments",
            "type": "module",
            "orderIndex": 1,
            "description": "Problem sets with solutions",
            "children": children
        }

    async def _transform_exams(self, exams: List[Dict]) -> Dict:
        """Transform exams into content module"""
        exam_problems = [e for e in exams if not e["is_solution"]]
        exam_solutions = {
            self._get_exam_type(e["filename"]): e
            for e in exams if e["is_solution"]
        }

        children = []
        for i, exam in enumerate(sorted(exam_problems, key=lambda x: x["filename"])):
            exam_type = self._get_exam_type(exam["filename"])
            solution = exam_solutions.get(exam_type)

            child = {
                "id": {"value": f"exam-{exam_type}"},
                "title": exam_type.replace("_", " ").title(),
                "type": "assessment",
                "orderIndex": i,
                "resources": [
                    {
                        "type": "document",
                        "title": exam["filename"],
                        "url": exam["path"],
                    }
                ]
            }

            if solution:
                child["resources"].append({
                    "type": "document",
                    "title": f"Solution: {solution['filename']}",
                    "url": solution["path"],
                })

            children.append(child)

        return {
            "id": {"value": "exams"},
            "title": "Exams",
            "type": "module",
            "orderIndex": 2,
            "description": "Midterm and final examinations with solutions",
            "children": children
        }

    def _get_assignment_number(self, filename: str) -> str:
        """Extract assignment number from filename"""
        import re
        match = re.search(r'(\d+)', filename)
        return match.group(1) if match else "0"

    def _get_exam_type(self, filename: str) -> str:
        """Extract exam type from filename"""
        filename_lower = filename.lower()
        if "midterm" in filename_lower:
            return "midterm"
        elif "final" in filename_lower:
            return "final"
        elif "quiz" in filename_lower:
            return "quiz"
        return "exam"
```

---

## Content Extraction

### Transcript Parser

Stanford SEE provides transcripts in HTML and PDF formats:

```python
class StanfordSEETranscriptParser:
    """
    Parse Stanford SEE video transcripts into tutoring segments.

    Transcripts are available in:
    - HTML format (preferred, structured)
    - PDF format (fallback)
    """

    def __init__(self, config: Dict):
        self.target_segment_duration = config.get("segment_duration_seconds", 180)
        self.min_segment_words = config.get("min_segment_words", 100)
        self.max_segment_words = config.get("max_segment_words", 500)

    async def parse_html_transcript(self, html_content: str) -> Dict:
        """
        Parse HTML transcript into timestamped segments.

        Stanford SEE HTML transcripts typically have:
        - Paragraph markers with timestamps
        - Speaker identification (Professor, Student)
        - Topic/slide markers
        """
        from bs4 import BeautifulSoup

        soup = BeautifulSoup(html_content, 'html.parser')

        result = {
            "segments": [],
            "speakers": set(),
            "timestamps": [],
            "total_duration": None
        }

        current_segment = {
            "text": "",
            "speaker": "PROFESSOR",  # Default for lecture courses
            "start_time": None,
            "end_time": None,
            "type": "lecture"
        }

        # Find all transcript content
        transcript_div = soup.find('div', class_='transcript') or soup.find('article') or soup.body

        if not transcript_div:
            return result

        for element in transcript_div.find_all(['p', 'span', 'div']):
            text = element.get_text(strip=True)
            if not text:
                continue

            # Check for timestamp
            timestamp = self._extract_timestamp(element, text)
            if timestamp:
                current_segment["start_time"] = timestamp
                result["timestamps"].append(timestamp)

            # Check for speaker change
            speaker = self._detect_speaker(text)
            if speaker:
                if current_segment["text"]:
                    result["segments"].append(current_segment.copy())
                current_segment = {
                    "text": "",
                    "speaker": speaker,
                    "start_time": timestamp,
                    "end_time": None,
                    "type": "lecture"
                }
                result["speakers"].add(speaker)
                text = self._remove_speaker_prefix(text, speaker)

            # Accumulate text
            current_segment["text"] += " " + text

            # Check for segment boundary (word count)
            word_count = len(current_segment["text"].split())
            if word_count >= self.max_segment_words:
                result["segments"].append(current_segment.copy())
                current_segment = {
                    "text": "",
                    "speaker": current_segment["speaker"],
                    "start_time": None,
                    "end_time": None,
                    "type": "lecture"
                }

        # Don't forget last segment
        if current_segment["text"].strip():
            result["segments"].append(current_segment)

        # Convert sets to lists
        result["speakers"] = list(result["speakers"])

        return result

    def _extract_timestamp(self, element, text: str) -> Optional[str]:
        """Extract timestamp from element or text"""
        import re

        # Check data attributes
        for attr in ['data-start', 'data-time', 'data-timestamp']:
            if element.has_attr(attr):
                return element[attr]

        # Check for timestamp in text
        patterns = [
            r'\[(\d{1,2}:\d{2}:\d{2})\]',
            r'\[(\d{1,2}:\d{2})\]',
            r'(\d{1,2}:\d{2}:\d{2})',
        ]

        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(1)

        return None

    def _detect_speaker(self, text: str) -> Optional[str]:
        """Detect speaker from text patterns"""
        import re

        # Stanford SEE speaker patterns
        patterns = [
            r'^(PROFESSOR|Professor|Prof\.)[:\s]',
            r'^(STUDENT|Student)[:\s]',
            r'^(INSTRUCTOR|Instructor)[:\s]',
            r'^([A-Z]{2,})[:\s]',  # All caps speaker label
        ]

        for pattern in patterns:
            match = re.match(pattern, text)
            if match:
                return match.group(1).upper()

        return None

    def _remove_speaker_prefix(self, text: str, speaker: str) -> str:
        """Remove speaker prefix from text"""
        import re
        return re.sub(f'^{re.escape(speaker)}[:\s]*', '', text, flags=re.IGNORECASE)
```

---

## AI Enrichment Integration

### Enrichment Stages for Stanford SEE

Stanford SEE content is high-quality lecture material that needs specific enrichments:

```
┌─────────────────────────────────────────────────────────────────┐
│        STANFORD SEE → AI ENRICHMENT INTEGRATION                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Stage 1: Content Analysis                                      │
│  ├─ Input: Transcripts, PDFs, course info                       │
│  ├─ Output: Domain classification, difficulty assessment        │
│  └─ SEE Specific: Engineering/CS/ML focus, advanced level       │
│                                                                 │
│  Stage 2: Structure Inference                                   │
│  ├─ Input: Lecture sequence, syllabus                           │
│  ├─ Output: Topic hierarchy, prerequisites                      │
│  └─ SEE Specific: Use lecture numbering as primary structure    │
│                                                                 │
│  Stage 3: Content Segmentation                                  │
│  ├─ Input: Video transcripts                                    │
│  ├─ Output: 3-5 minute tutoring segments                        │
│  └─ SEE Specific: Align with video timestamps                   │
│                                                                 │
│  Stage 4: Learning Objective Extraction                         │
│  ├─ Input: Lecture content, course description                  │
│  ├─ Output: Bloom-aligned objectives                            │
│  └─ SEE Specific: Focus on "apply" and "analyze" levels         │
│                                                                 │
│  Stage 5: Assessment Generation                                 │
│  ├─ Input: Problem sets, exams (rich existing content!)         │
│  ├─ Output: Interactive assessments with hints/feedback         │
│  └─ SEE Specific: Parse LaTeX math, add step-by-step hints      │
│                                                                 │
│  Stage 6: Tutoring Enhancement                                  │
│  ├─ Input: All content                                          │
│  ├─ Output: Spoken text, alternatives, misconceptions           │
│  └─ SEE Specific: Mathematical notation to speech               │
│                                                                 │
│  Stage 7: Knowledge Graph                                       │
│  ├─ Input: Concepts from lectures                               │
│  ├─ Output: Prerequisite graph, concept relationships           │
│  └─ SEE Specific: Cross-reference related courses               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Course-Specific Enrichment Config

```python
STANFORD_SEE_ENRICHMENT_CONFIG = {
    "CS106A": {
        "domain": "programming",
        "concepts": ["variables", "loops", "functions", "objects", "Karel"],
        "spoken_text_rules": {
            "code_reading": True,  # Read code syntax aloud
            "camelCase_expansion": True,  # "myVariable" → "my Variable"
        }
    },
    "CS229": {
        "domain": "machine-learning",
        "concepts": ["regression", "classification", "neural-networks", "SVM", "clustering"],
        "spoken_text_rules": {
            "math_expansion": True,
            "greek_letters": True,
            "subscripts": True,  # "x_i" → "x sub i"
        },
        "mathematical_notation": {
            "\\theta": "theta",
            "\\nabla": "gradient",
            "\\sum": "sum",
            "\\prod": "product",
            "\\partial": "partial",
            "J(\\theta)": "J of theta, the cost function",
        }
    },
    "EE364A": {
        "domain": "optimization",
        "concepts": ["convex-sets", "convex-functions", "LP", "QP", "duality"],
        "spoken_text_rules": {
            "math_expansion": True,
            "optimization_notation": True,
        },
        "mathematical_notation": {
            "\\min": "minimize",
            "\\max": "maximize",
            "s.t.": "subject to",
            "\\leq": "less than or equal to",
            "\\geq": "greater than or equal to",
            "\\in": "in",
            "\\mathbb{R}^n": "R n, the set of n-dimensional real vectors",
        }
    }
}
```

---

## Error Handling

### Expected Errors and Recovery

```python
STANFORD_SEE_ERROR_HANDLING = {
    "license_restriction": {
        "cause": "Attempting to import LOGIC course or restricted content",
        "recovery": "Contact intrologic@googlegroups.com for permission",
        "fallback": None,  # No fallback - must respect license
        "severity": "blocking",
    },
    "zip_extraction_failed": {
        "cause": "Corrupted or incomplete download",
        "recovery": "Re-download from see.stanford.edu",
        "fallback": "Try individual file downloads",
    },
    "missing_transcripts": {
        "cause": "Transcript files not in package",
        "recovery": "Scrape from course website",
        "fallback": "Use PDF lecture notes as primary content",
    },
    "pdf_parsing_failed": {
        "cause": "Complex PDF layout or scanned content",
        "recovery": "Try alternative PDF parser",
        "fallback": "Reference PDF without text extraction",
    },
    "math_rendering_failed": {
        "cause": "Complex LaTeX or non-standard notation",
        "recovery": "Extract as images with alt text",
        "fallback": "Mark for manual review",
    },
}
```

---

## Testing Strategy

### Test Fixtures

```python
STANFORD_SEE_TEST_FIXTURES = {
    "minimal_valid": {
        "description": "Minimum valid Stanford SEE package",
        "course_id": "CS106A",
        "files": ["handouts/lecture1.pdf"],
        "expected_result": "valid",
    },
    "full_course_cs229": {
        "description": "Complete CS229 Machine Learning course",
        "course_id": "CS229",
        "expected_lectures": 20,
        "expected_assignments": 4,
        "has_solutions": True,
    },
    "license_blocked_logic": {
        "description": "Logic course should be blocked",
        "course_id": "LOGIC",
        "expected_result": "license_blocked",
        "expected_error": "custom license",
    },
    "transcript_parsing": {
        "description": "Test transcript HTML parsing",
        "source": "CS229 Lecture 1 transcript",
        "expected_segments": 15,  # Approximate
    },
}
```

### Integration Tests

```python
@pytest.mark.asyncio
async def test_stanford_see_full_import():
    """Test full import pipeline with Stanford SEE content"""

    # Use cached test fixture
    with open("fixtures/stanford_see_cs229_sample.zip", "rb") as f:
        content = f.read()

    importer = StanfordSEEImporter(storage=MemoryStorage())

    # Validate
    validation = await importer.validate(content, course_id="CS229")
    assert validation.is_valid
    assert validation.metadata.get("license")

    # Import
    result = await importer.import_async(content, course_id="CS229", dry_run=True)
    assert result.success
    assert result.curriculum.title == "Machine Learning"

    # Verify license preservation (CRITICAL)
    rights = result.curriculum.rights
    assert rights.license.type == "CC-BY-NC-SA-4.0"
    assert "Stanford" in rights.holder.name
    assert rights.attribution.required == True


@pytest.mark.asyncio
async def test_stanford_see_logic_course_blocked():
    """Verify that Logic course import is blocked due to license"""

    importer = StanfordSEEImporter(storage=MemoryStorage())

    # This should fail at validation
    validation = await importer.validate(b"dummy content", course_id="LOGIC")
    assert not validation.is_valid
    assert "license" in validation.errors[0].lower()
    assert validation.metadata.get("license_blocked") == True


@pytest.mark.asyncio
async def test_license_preservation():
    """Verify license information is preserved in all imported content"""

    with open("fixtures/stanford_see_cs106a_sample.zip", "rb") as f:
        content = f.read()

    importer = StanfordSEEImporter(storage=MemoryStorage())
    result = await importer.import_async(content, course_id="CS106A", dry_run=True)

    curriculum = result.curriculum

    # Verify all required license fields
    assert curriculum.rights is not None
    assert curriculum.rights.license.type == "CC-BY-NC-SA-4.0"
    assert curriculum.rights.license.url == "https://creativecommons.org/licenses/by-nc-sa/4.0/"
    assert "attribution" in curriculum.rights.license.conditions
    assert "noncommercial" in curriculum.rights.license.conditions
    assert curriculum.rights.attribution.required == True
    assert "Stanford" in curriculum.rights.attribution.format
    assert curriculum.rights.holder.name == "Stanford University"
    assert curriculum.rights.sourceUrl.startswith("https://see.stanford.edu")
```

---

## Next Steps

1. **Implement license validator** - Critical first step
2. **Implement core importer** - ZIP extraction and parsing
3. **Add transcript parser** - HTML transcript processing
4. **Integrate AI enrichment** - Connect to enrichment pipeline
5. **Test with real courses** - CS229, EE364A, CS106A

---

## License Compliance Checklist

Before releasing any imported content, verify:

- [ ] License type correctly identified (CC-BY-NC-SA 4.0 or restricted)
- [ ] Attribution format included in output
- [ ] Source URL preserved
- [ ] Holder information preserved
- [ ] NonCommercial restriction documented
- [ ] ShareAlike requirement documented
- [ ] Logic course blocked from import
- [ ] Import timestamp recorded
