# MIT OpenCourseWare Importer Specification

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-12-23
**Target Audience:** Collegiate (Undergraduate/Graduate)

---

## Table of Contents

1. [Overview](#overview)
2. [MIT OCW Platform Analysis](#mit-ocw-platform-analysis)
3. [Supported Formats](#supported-formats)
4. [Data Mapping](#data-mapping)
5. [Implementation Specification](#implementation-specification)
6. [Content Extraction](#content-extraction)
7. [AI Enrichment Integration](#ai-enrichment-integration)
8. [Error Handling](#error-handling)
9. [Testing Strategy](#testing-strategy)

---

## Overview

The MIT OCW importer converts MIT OpenCourseWare course packages into UMLCF format for use with UnaMentis's conversational AI tutoring system. MIT OCW is a free, publicly accessible collection of over 2,500 MIT courses with comprehensive materials.

### Why MIT OCW?

| Criterion | Assessment |
|-----------|------------|
| **License** | CC-BY-NC-SA 4.0 (Creative Commons Attribution-NonCommercial-ShareAlike) |
| **Cost** | Free |
| **Quality** | University-level, peer-reviewed, used by millions worldwide |
| **Formats** | ZIP packages with HTML, PDF, video links |
| **Coverage** | 2,500+ courses across all disciplines |
| **Standards Alignment** | University curriculum standards |
| **Structure** | Course → Lecture/Topic → Resources (maps to UMLCF hierarchy) |

### Import Scope

**In Scope:**
- Course ZIP packages (primary)
- HTML index and content files
- PDF lecture notes, problem sets, exams, readings
- Video metadata and transcript extraction
- imsmanifest.xml navigation structure
- Syllabus and course information

**Out of Scope:**
- Video files themselves (URL references only, too large)
- Interactive simulations (URL references only)
- External tool integrations (MATLAB servers, etc.)
- Real-time course features

---

## MIT OCW Platform Analysis

### Content Organization

MIT OCW organizes content in a clear hierarchy that maps well to UMLCF:

```
Course ZIP Package
├── index.html                    # Course homepage
├── imsmanifest.xml              # Navigation structure (IMS format)
├── pages/                        # HTML content pages
│   ├── syllabus.html
│   ├── calendar.html
│   ├── lecture-notes.html
│   ├── readings.html
│   ├── assignments.html
│   ├── exams.html
│   └── [topic-pages].html
├── static_resources/             # Downloadable files
│   ├── *.pdf                    # Lecture notes, problem sets, solutions
│   ├── *.zip                    # Code, data files
│   └── *.tex                    # LaTeX source (sometimes)
└── resources/                    # Additional assets
    └── *.png, *.jpg             # Images, diagrams
```

### Course Types

| Type | Description | UMLCF Mapping |
|------|-------------|---------------|
| **Full Course** | Complete semester materials | Complete curriculum |
| **Video Course** | Primarily lecture videos | Video-heavy modules |
| **OCW Scholar** | Self-study optimized | Enhanced with assessments |
| **Supplemental** | Additional resources | Resource modules |

### Primary Target Courses (Initial Import)

Focus on courses with rich, well-structured content:

| Subject | Course Number | Title | Instructor |
|---------|---------------|-------|------------|
| **CS** | 6.001 | Structure and Interpretation of Computer Programs | Abelson, Sussman |
| **CS** | 6.006 | Introduction to Algorithms | Demaine, Devadas |
| **Math** | 18.01 | Single Variable Calculus | Jerison |
| **Math** | 18.06 | Linear Algebra | Strang |
| **Physics** | 8.01 | Physics I: Classical Mechanics | Lewin |
| **Biology** | 7.012 | Introduction to Biology | Lander, Weinberg |

---

## Supported Formats

### Primary: Course ZIP Package

ZIP packages are the preferred format because:
- Self-contained with all text materials
- Structured HTML with consistent markup
- imsmanifest.xml provides navigation
- Includes PDF resources
- Standard format across all courses

### ZIP Package Structure Analysis

```python
# Typical ZIP contents analysis
MIT_OCW_ZIP_STRUCTURE = {
    "index.html": "Course homepage with navigation",
    "imsmanifest.xml": "IMS content packaging manifest",
    "pages/": {
        "syllabus.html": "Course overview, objectives, schedule",
        "calendar.html": "Week-by-week schedule",
        "lecture-notes.html": "Links to lecture PDFs",
        "readings.html": "Reading assignments",
        "assignments.html": "Problem sets",
        "exams.html": "Midterms, finals, solutions",
        "video-lectures.html": "Video index with YouTube/Archive links",
    },
    "static_resources/": {
        "*.pdf": "Lecture notes, problem sets, solutions, readings",
        "*.zip": "Code files, datasets",
        "*.tex": "LaTeX source files",
        "*.py/*.m/*.java": "Code examples",
    },
    "resources/": {
        "*.png/*.jpg/*.gif": "Diagrams, figures, images",
    }
}
```

### Secondary: Direct URL Scraping

For courses without ZIP packages:
- Respect robots.txt
- Rate-limited requests
- Cache responses
- Extract same structure from live site

---

## Data Mapping

### Metadata Mapping

| MIT OCW Element | UMLCF Field | Notes |
|-----------------|-------------|-------|
| `<title>` from index.html | `title` | Course title |
| Course number (6.001) | `id.value` | Unique identifier |
| Instructor name | `lifecycle.contributors[].name` | Primary instructor |
| "MIT" | `lifecycle.contributors[].name` | Publisher |
| Course description | `description` | From syllabus or meta |
| Subject tags | `metadata.keywords[]` | CS, Math, Physics, etc. |
| CC-BY-NC-SA 4.0 | `rights.license` | Standard OCW license |
| "en-US" | `metadata.language` | Primary language |
| imsmanifest.xml items | `content[]` hierarchy | Navigation structure |

### Content Hierarchy Mapping

| MIT OCW Level | UMLCF Type | Example |
|---------------|------------|---------|
| Course | Root curriculum | "6.001 SICP" |
| Section (Lecture Notes) | `module` | "Lecture Notes" |
| Individual Lecture | `topic` | "Lecture 1: Building Abstractions" |
| Subsection | `topic` (child) | "1.1 Elements of Programming" |
| Paragraph/Slide | `transcript.segments[]` | Content text |

### Resource Type Mapping

| MIT OCW Resource | UMLCF Element | Transformation |
|------------------|---------------|----------------|
| Lecture PDF | `transcript` segments | Extract text, create segments |
| Problem Set PDF | `assessments[]` | Parse problems into questions |
| Solution PDF | `assessments[].feedback` | Extract solutions for feedback |
| Exam PDF | `assessments[]` | High-stakes assessment items |
| Reading | `resources[]` + prereqs | Reference material |
| Video URL | `resources[]` | External video link |
| Video Transcript | `transcript` segments | Primary content source |

### Video Transcript Integration

Video transcripts are the richest content source for lecture courses:

```python
# Video transcript to UMLCF mapping
VIDEO_TRANSCRIPT_MAPPING = {
    # OCW provides transcripts in multiple formats
    "transcript_html": "Primary source - clean HTML",
    "transcript_pdf": "Fallback - requires extraction",
    "transcript_srt": "Subtitle format - needs parsing",

    # Transformation process
    "process": [
        "1. Parse transcript into timestamped segments",
        "2. Identify topic boundaries from pauses/headings",
        "3. Create segment groups (~2-5 minutes each)",
        "4. Mark natural stopping points",
        "5. Link to video timestamps for reference",
    ]
}
```

---

## Implementation Specification

### Module Structure

```python
umlcf_importer/
└── importers/
    └── mit_ocw/
        ├── __init__.py
        ├── importer.py          # Main MITOCWImporter class
        ├── zip_parser.py        # ZIP package extraction
        ├── html_parser.py       # HTML content parsing
        ├── pdf_extractor.py     # PDF text extraction
        ├── transcript_parser.py # Video transcript handling
        ├── manifest_parser.py   # imsmanifest.xml parsing
        ├── resource_mapper.py   # File type classification
        └── models.py            # MIT OCW-specific data models
```

### MITOCWImporter Class

```python
from umlcf_importer.core.base import CurriculumImporter, ValidationResult
from umlcf_importer.core.models import CurriculumData
from typing import Dict, Any, List, Optional
from pathlib import Path
import zipfile

class MITOCWImporter(CurriculumImporter):
    """
    Importer for MIT OpenCourseWare course packages.

    Supports ZIP packages with HTML, PDF, and transcript content.
    Primary focus: Collegiate-level STEM courses.
    """

    name = "mit_ocw"
    description = "Import MIT OpenCourseWare course packages (ZIP, HTML)"
    file_extensions = [".zip", ".html"]

    # MIT OCW specific configuration
    DEFAULT_CONFIG = {
        "extract_transcripts": True,
        "extract_pdfs": True,
        "extract_assessments": True,
        "include_solutions": True,
        "video_as_reference": True,  # Don't download videos, just reference
        "spoken_text_generation": True,
        "checkpoint_frequency": "per_topic",
        "parse_latex_math": True,
    }

    def __init__(
        self,
        storage: "StorageBackend",
        config: Optional[Dict[str, Any]] = None,
        logger: Optional["Logger"] = None
    ):
        super().__init__(storage, config, logger)
        self.config = {**self.DEFAULT_CONFIG, **(config or {})}

        # Initialize sub-parsers
        self._zip_parser = None
        self._html_parser = None
        self._pdf_extractor = None
        self._transcript_parser = None
        self._manifest_parser = None

    async def validate(self, content: bytes) -> ValidationResult:
        """
        Validate MIT OCW content format.

        Checks:
        - Valid ZIP structure
        - Contains index.html or imsmanifest.xml
        - Has static_resources directory
        - Contains expected OCW markers
        """
        errors = []
        warnings = []
        metadata = {}

        # Detect format
        format_type = self._detect_format(content)
        metadata["format"] = format_type

        if format_type == "zip":
            return await self._validate_zip(content)
        elif format_type == "html":
            return await self._validate_html(content)
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
        return "unknown"

    async def _validate_zip(self, content: bytes) -> ValidationResult:
        """Validate MIT OCW ZIP structure"""
        errors = []
        warnings = []
        metadata = {"format": "zip"}

        try:
            import io
            with zipfile.ZipFile(io.BytesIO(content)) as zf:
                namelist = zf.namelist()

                # Check for index.html
                has_index = any("index.html" in n.lower() for n in namelist)
                if not has_index:
                    errors.append("Missing index.html (not a valid OCW package)")

                # Check for imsmanifest.xml
                has_manifest = any("imsmanifest.xml" in n.lower() for n in namelist)
                if not has_manifest:
                    warnings.append("Missing imsmanifest.xml (navigation may be limited)")

                # Check for static_resources
                has_resources = any("static_resources" in n for n in namelist)
                if not has_resources:
                    warnings.append("Missing static_resources folder (limited content)")

                # Look for MIT OCW markers
                for name in namelist:
                    content_sample = ""
                    if name.endswith(".html"):
                        try:
                            content_sample = zf.read(name).decode('utf-8', errors='ignore')[:2000]
                            if "mit.edu" in content_sample.lower() or "opencourseware" in content_sample.lower():
                                metadata["ocw_confirmed"] = True
                                break
                        except:
                            pass

                # Count resources
                pdf_count = len([n for n in namelist if n.endswith('.pdf')])
                html_count = len([n for n in namelist if n.endswith('.html')])

                metadata["file_count"] = len(namelist)
                metadata["pdf_count"] = pdf_count
                metadata["html_count"] = html_count

        except zipfile.BadZipFile:
            errors.append("Invalid ZIP file structure")
        except Exception as e:
            errors.append(f"ZIP validation error: {str(e)}")

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            format_version="MIT OCW ZIP Package",
            metadata=metadata
        )

    async def extract(self, content: bytes) -> Dict[str, Any]:
        """
        Extract raw MIT OCW structure before UMLCF transformation.

        Returns intermediate representation with:
        - Course metadata from index.html
        - Navigation from imsmanifest.xml
        - Content from HTML pages
        - Resources from static_resources
        """
        format_type = self._detect_format(content)

        if format_type == "zip":
            return await self._extract_zip(content)
        else:
            return await self._extract_html(content)

    async def _extract_zip(self, content: bytes) -> Dict[str, Any]:
        """Extract data from ZIP package"""
        import io
        from bs4 import BeautifulSoup

        result = {
            "format": "zip",
            "metadata": {},
            "navigation": [],
            "sections": [],
            "resources": [],
            "transcripts": [],
            "assessments": []
        }

        with zipfile.ZipFile(io.BytesIO(content)) as zf:
            namelist = zf.namelist()

            # Find and parse index.html
            index_path = self._find_file(namelist, "index.html")
            if index_path:
                index_content = zf.read(index_path).decode('utf-8', errors='ignore')
                result["metadata"] = self._parse_course_metadata(index_content)

            # Find and parse imsmanifest.xml
            manifest_path = self._find_file(namelist, "imsmanifest.xml")
            if manifest_path:
                manifest_content = zf.read(manifest_path).decode('utf-8', errors='ignore')
                result["navigation"] = self._parse_ims_manifest(manifest_content)

            # Extract content pages
            page_paths = [n for n in namelist if "/pages/" in n and n.endswith(".html")]
            for page_path in page_paths:
                try:
                    page_content = zf.read(page_path).decode('utf-8', errors='ignore')
                    section_data = self._parse_content_page(page_content, page_path)
                    if section_data:
                        result["sections"].append(section_data)
                except Exception as e:
                    self.logger.warning(f"Failed to parse {page_path}: {e}")

            # Catalog resources
            resource_paths = [n for n in namelist if "static_resources" in n]
            for resource_path in resource_paths:
                resource_info = self._catalog_resource(resource_path, zf)
                if resource_info:
                    result["resources"].append(resource_info)

            # Extract transcripts if present
            transcript_paths = [n for n in namelist if "transcript" in n.lower()]
            for transcript_path in transcript_paths:
                try:
                    transcript_content = zf.read(transcript_path).decode('utf-8', errors='ignore')
                    transcript_data = self._parse_transcript(transcript_content, transcript_path)
                    if transcript_data:
                        result["transcripts"].append(transcript_data)
                except Exception as e:
                    self.logger.warning(f"Failed to parse transcript {transcript_path}: {e}")

        return result

    def _parse_course_metadata(self, html_content: str) -> Dict[str, Any]:
        """Extract course metadata from index.html"""
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html_content, 'html.parser')

        metadata = {}

        # Title
        title_tag = soup.find('title')
        if title_tag:
            metadata["title"] = title_tag.text.strip()

        # Course number (look for patterns like "6.001" or "18.06")
        import re
        course_pattern = r'\b(\d{1,2}\.\d{2,4}[A-Z]?)\b'
        text = soup.get_text()
        course_match = re.search(course_pattern, text)
        if course_match:
            metadata["course_number"] = course_match.group(1)

        # Description from meta tags
        desc_meta = soup.find('meta', {'name': 'description'})
        if desc_meta:
            metadata["description"] = desc_meta.get('content', '')

        # Instructor (look for common patterns)
        instructor_patterns = [
            r'(?:Instructor|Prof\.|Professor|Dr\.)[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
            r'(?:Taught by|Lecturer)[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
        ]
        for pattern in instructor_patterns:
            match = re.search(pattern, text)
            if match:
                metadata["instructor"] = match.group(1)
                break

        # Department/Subject
        dept_patterns = [
            r'(?:Department of|Dept\.?)[:\s]+([A-Za-z\s]+?)(?:\n|<)',
            r'(Electrical Engineering|Computer Science|Mathematics|Physics|Chemistry|Biology)',
        ]
        for pattern in dept_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                metadata["department"] = match.group(1).strip()
                break

        return metadata

    def _parse_ims_manifest(self, xml_content: str) -> List[Dict]:
        """Parse imsmanifest.xml for navigation structure"""
        from xml.etree import ElementTree as ET

        navigation = []

        try:
            # Handle namespace
            root = ET.fromstring(xml_content)

            # Find all item elements (typically represent navigation items)
            ns = {'ims': 'http://www.imsglobal.org/xsd/imscp_v1p1'}

            items = root.findall('.//ims:item', ns)
            if not items:
                # Try without namespace
                items = root.findall('.//item')

            for item in items:
                nav_item = {
                    "identifier": item.get('identifier', ''),
                    "title": "",
                    "href": "",
                    "children": []
                }

                # Get title
                title_elem = item.find('ims:title', ns) or item.find('title')
                if title_elem is not None:
                    nav_item["title"] = title_elem.text or ''

                # Get resource reference
                identifierref = item.get('identifierref', '')
                if identifierref:
                    nav_item["identifierref"] = identifierref

                navigation.append(nav_item)

        except ET.ParseError as e:
            self.logger.warning(f"Failed to parse imsmanifest.xml: {e}")

        return navigation

    def _parse_content_page(self, html_content: str, page_path: str) -> Optional[Dict]:
        """Parse an HTML content page into structured data"""
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html_content, 'html.parser')

        # Get page title
        title_tag = soup.find('title') or soup.find('h1')
        title = title_tag.text.strip() if title_tag else Path(page_path).stem

        # Determine page type
        page_type = self._classify_page_type(page_path, title.lower())

        # Extract main content
        main_content = soup.find('main') or soup.find('article') or soup.find('div', class_='content')
        if not main_content:
            main_content = soup.body

        if not main_content:
            return None

        # Extract paragraphs
        paragraphs = []
        for p in main_content.find_all(['p', 'li', 'h2', 'h3', 'h4']):
            text = p.get_text(strip=True)
            if len(text) > 20:  # Filter noise
                paragraphs.append({
                    "text": text,
                    "tag": p.name,
                    "is_heading": p.name.startswith('h')
                })

        # Extract links to resources
        resource_links = []
        for a in main_content.find_all('a', href=True):
            href = a['href']
            if any(href.endswith(ext) for ext in ['.pdf', '.zip', '.mp4', '.mp3']):
                resource_links.append({
                    "href": href,
                    "text": a.get_text(strip=True),
                    "type": Path(href).suffix.lstrip('.')
                })

        return {
            "path": page_path,
            "title": title,
            "type": page_type,
            "paragraphs": paragraphs,
            "resource_links": resource_links
        }

    def _classify_page_type(self, page_path: str, title: str) -> str:
        """Classify page type from path and title"""
        path_lower = page_path.lower()

        if "syllabus" in path_lower or "syllabus" in title:
            return "syllabus"
        elif "calendar" in path_lower or "schedule" in title:
            return "calendar"
        elif "lecture" in path_lower:
            return "lecture_notes"
        elif "reading" in path_lower:
            return "readings"
        elif "assignment" in path_lower or "problem" in path_lower:
            return "assignments"
        elif "exam" in path_lower or "quiz" in path_lower:
            return "exams"
        elif "video" in path_lower:
            return "video_lectures"
        elif "resource" in path_lower or "download" in path_lower:
            return "resources"
        else:
            return "content"

    async def parse(self, content: bytes) -> CurriculumData:
        """
        Parse MIT OCW content and transform to UMLCF format.

        Full pipeline:
        1. Extract raw structure
        2. Map metadata to UMLCF
        3. Convert sections to content nodes
        4. Extract and map assessments
        5. Process transcripts for segments
        6. Generate spoken text variants
        """
        # Step 1: Extract
        raw = await self.extract(content)

        # Step 2: Build UMLCF structure
        umlcf = {
            "umlcf": "1.0.0",
            "id": self._generate_id(raw),
            "title": raw["metadata"].get("title", "Untitled MIT OCW Course"),
            "description": raw["metadata"].get("description", ""),
            "version": {
                "number": "1.0.0",
                "date": None
            },
            "lifecycle": self._build_lifecycle(raw["metadata"]),
            "metadata": self._build_metadata(raw["metadata"]),
            "educational": self._build_educational(raw["metadata"]),
            "rights": self._build_rights(),
            "content": [],
            "glossary": []
        }

        # Step 3: Transform sections to content nodes
        for section in raw["sections"]:
            content_node = await self._transform_section(section, raw)
            umlcf["content"].append(content_node)

        return CurriculumData(**umlcf)

    def _build_lifecycle(self, metadata: Dict) -> Dict:
        """Build UMLCF lifecycle from MIT OCW metadata"""
        contributors = [
            {
                "role": "publisher",
                "name": "MIT OpenCourseWare",
                "organization": "Massachusetts Institute of Technology"
            }
        ]

        if metadata.get("instructor"):
            contributors.insert(0, {
                "role": "author",
                "name": metadata["instructor"],
                "organization": "Massachusetts Institute of Technology"
            })

        return {
            "status": "published",
            "contributors": contributors
        }

    def _build_metadata(self, metadata: Dict) -> Dict:
        """Build UMLCF metadata from MIT OCW metadata"""
        keywords = ["MIT", "OpenCourseWare", "university"]

        if metadata.get("department"):
            keywords.append(metadata["department"])

        return {
            "language": "en-US",
            "keywords": keywords,
            "structure": "hierarchical"
        }

    def _build_educational(self, metadata: Dict) -> Dict:
        """Build UMLCF educational context from MIT OCW metadata"""
        return {
            "audience": {
                "type": "learner",
                "educationalLevel": "collegiate",
                "prerequisites": []
            },
            "alignment": [],
            "duration": {
                "estimated": 40,  # Typical semester course hours
                "unit": "hours"
            }
        }

    def _build_rights(self) -> Dict:
        """Build UMLCF rights from MIT OCW license"""
        return {
            "license": {
                "type": "CC-BY-NC-SA-4.0",
                "name": "Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International",
                "url": "https://creativecommons.org/licenses/by-nc-sa/4.0/",
                "permissions": ["share", "adapt"],
                "conditions": ["attribution", "noncommercial", "sharealike"]
            },
            "attribution": {
                "required": True,
                "format": "Content from MIT OpenCourseWare (ocw.mit.edu), licensed under CC-BY-NC-SA 4.0."
            },
            "holder": {
                "name": "Massachusetts Institute of Technology",
                "url": "https://ocw.mit.edu/"
            }
        }

    def _generate_id(self, raw: Dict) -> Dict:
        """Generate UMLCF ID from MIT OCW metadata"""
        course_number = raw["metadata"].get("course_number")
        if course_number:
            return {"catalog": "MIT-OCW", "value": course_number}

        from uuid import uuid4
        return {"catalog": "UUID", "value": str(uuid4())}

    # Helper methods
    def _find_file(self, namelist: List[str], filename: str) -> Optional[str]:
        """Find a file in the ZIP namelist (case-insensitive)"""
        for name in namelist:
            if name.lower().endswith(filename.lower()):
                return name
        return None

    def _catalog_resource(self, resource_path: str, zf: zipfile.ZipFile) -> Optional[Dict]:
        """Catalog a resource file"""
        suffix = Path(resource_path).suffix.lower()

        resource_types = {
            ".pdf": "document",
            ".zip": "archive",
            ".py": "code",
            ".m": "code",
            ".java": "code",
            ".c": "code",
            ".cpp": "code",
            ".tex": "source",
            ".png": "image",
            ".jpg": "image",
            ".gif": "image",
            ".mp4": "video",
            ".mp3": "audio",
        }

        resource_type = resource_types.get(suffix, "other")

        # Get file info
        try:
            info = zf.getinfo(resource_path)
            return {
                "path": resource_path,
                "filename": Path(resource_path).name,
                "type": resource_type,
                "size": info.file_size,
                "suffix": suffix
            }
        except:
            return None
```

---

## Content Extraction

### PDF Extraction Strategy

MIT OCW courses contain rich PDF content that requires extraction:

```python
class MITOCWPDFExtractor:
    """
    Extract content from MIT OCW PDF files.

    Handles:
    - Lecture notes (slides, handouts)
    - Problem sets and solutions
    - Exams and answers
    - Reading materials
    """

    def __init__(self):
        # Use pure Python PDF library for cross-platform
        self.use_pdfminer = True

    async def extract_lecture_notes(self, pdf_bytes: bytes) -> Dict:
        """
        Extract lecture notes from PDF.

        Returns:
        - Structured content with headings
        - Extracted text segments
        - Mathematical notation (as LaTeX or images)
        - Diagrams (as image references)
        """
        from pdfminer.high_level import extract_text, extract_pages
        from pdfminer.layout import LAParams, LTTextBox, LTFigure

        result = {
            "title": "",
            "sections": [],
            "figures": [],
            "equations": []
        }

        # Extract text with layout analysis
        laparams = LAParams(
            line_margin=0.5,
            word_margin=0.1,
            char_margin=2.0,
            detect_vertical=True
        )

        current_section = {"title": "", "content": []}

        for page_layout in extract_pages(io.BytesIO(pdf_bytes), laparams=laparams):
            for element in page_layout:
                if isinstance(element, LTTextBox):
                    text = element.get_text().strip()

                    # Detect headings (typically larger/bold text)
                    if self._is_heading(element, text):
                        if current_section["content"]:
                            result["sections"].append(current_section)
                        current_section = {"title": text, "content": []}
                    else:
                        current_section["content"].append(text)

                elif isinstance(element, LTFigure):
                    # Track figure locations
                    result["figures"].append({
                        "page": page_layout.pageid,
                        "bbox": element.bbox
                    })

        # Don't forget last section
        if current_section["content"]:
            result["sections"].append(current_section)

        return result

    async def extract_problem_set(self, pdf_bytes: bytes) -> List[Dict]:
        """
        Extract problem set into individual problems.

        Returns list of problems with:
        - Problem number
        - Problem text
        - Parts (a, b, c, etc.)
        - Point values if present
        """
        import re

        text = self._extract_text(pdf_bytes)
        problems = []

        # Common problem patterns
        problem_patterns = [
            r'(?:Problem|Question|Exercise)\s*(\d+)[.:\s]+(.*?)(?=(?:Problem|Question|Exercise)\s*\d+|$)',
            r'(\d+)[.]\s+(.*?)(?=\d+[.]|$)',
        ]

        for pattern in problem_patterns:
            matches = re.findall(pattern, text, re.DOTALL | re.IGNORECASE)
            if matches:
                for num, content in matches:
                    problem = {
                        "number": int(num),
                        "text": content.strip(),
                        "parts": self._extract_parts(content)
                    }
                    problems.append(problem)
                break

        return problems

    def _extract_parts(self, problem_text: str) -> List[Dict]:
        """Extract sub-parts (a), (b), (c) from problem text"""
        import re

        parts = []
        part_pattern = r'\(([a-z])\)\s*(.*?)(?=\([a-z]\)|$)'

        matches = re.findall(part_pattern, problem_text, re.DOTALL)
        for letter, content in matches:
            parts.append({
                "label": letter,
                "text": content.strip()
            })

        return parts
```

### Transcript Processing

Video transcripts are key for lecture courses:

```python
class MITOCWTranscriptParser:
    """
    Parse MIT OCW video transcripts into tutoring segments.

    Transcripts typically come in:
    - HTML format (primary)
    - PDF format (fallback)
    - SRT/WebVTT subtitles
    """

    def __init__(self, config: Dict):
        self.target_segment_duration = config.get("segment_duration_seconds", 180)  # 3 minutes
        self.min_segment_words = config.get("min_segment_words", 100)
        self.max_segment_words = config.get("max_segment_words", 500)

    async def parse_html_transcript(self, html_content: str) -> Dict:
        """
        Parse HTML transcript into timestamped segments.

        MIT OCW transcripts typically have:
        - Paragraph markers
        - Speaker identification
        - Topic headers
        """
        from bs4 import BeautifulSoup

        soup = BeautifulSoup(html_content, 'html.parser')

        result = {
            "segments": [],
            "speakers": set(),
            "topics": []
        }

        current_segment = {
            "text": "",
            "speaker": None,
            "timestamp": None,
            "type": "narrative"
        }

        for element in soup.find_all(['p', 'h2', 'h3', 'span']):
            text = element.get_text(strip=True)

            # Check for timestamp
            timestamp = self._extract_timestamp(element)

            # Check for speaker
            speaker = self._extract_speaker(text)

            # Check for topic heading
            if element.name in ['h2', 'h3']:
                # Save current segment
                if current_segment["text"]:
                    result["segments"].append(current_segment.copy())

                result["topics"].append({
                    "title": text,
                    "segment_index": len(result["segments"])
                })

                current_segment = {
                    "text": "",
                    "speaker": None,
                    "timestamp": timestamp,
                    "type": "topic_start"
                }
            else:
                # Accumulate text
                if speaker:
                    current_segment["speaker"] = speaker
                    result["speakers"].add(speaker)
                    text = self._remove_speaker(text, speaker)

                current_segment["text"] += " " + text

                if timestamp:
                    current_segment["timestamp"] = timestamp

                # Check if we should create a new segment (word count threshold)
                word_count = len(current_segment["text"].split())
                if word_count >= self.max_segment_words:
                    result["segments"].append(current_segment.copy())
                    current_segment = {
                        "text": "",
                        "speaker": current_segment["speaker"],
                        "timestamp": None,
                        "type": "narrative"
                    }

        # Don't forget last segment
        if current_segment["text"].strip():
            result["segments"].append(current_segment)

        # Convert speakers set to list
        result["speakers"] = list(result["speakers"])

        return result

    def _extract_timestamp(self, element) -> Optional[str]:
        """Extract timestamp from element attributes or content"""
        import re

        # Check data attributes
        timestamp = element.get('data-time') or element.get('data-timestamp')
        if timestamp:
            return timestamp

        # Check for timestamp in text (e.g., "[00:05:30]" or "5:30")
        text = element.get_text()
        patterns = [
            r'\[(\d{1,2}:\d{2}:\d{2})\]',
            r'\[(\d{1,2}:\d{2})\]',
        ]
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(1)

        return None

    def _extract_speaker(self, text: str) -> Optional[str]:
        """Extract speaker name from text"""
        import re

        # Common patterns: "PROFESSOR:", "Dr. Smith:", "STUDENT:"
        patterns = [
            r'^(PROFESSOR|INSTRUCTOR|DR\.\s*\w+|STUDENT)[:\s]',
            r'^([A-Z][A-Z\s]+)[:\s]',
        ]

        for pattern in patterns:
            match = re.match(pattern, text)
            if match:
                return match.group(1).strip()

        return None

    def _remove_speaker(self, text: str, speaker: str) -> str:
        """Remove speaker prefix from text"""
        import re
        return re.sub(f'^{re.escape(speaker)}[:\s]*', '', text, flags=re.IGNORECASE)
```

---

## AI Enrichment Integration

### Enrichment Stages for MIT OCW

MIT OCW content is relatively well-structured but needs enrichment for tutoring:

```
┌─────────────────────────────────────────────────────────────────┐
│          MIT OCW → AI ENRICHMENT INTEGRATION                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Stage 1: Content Analysis                                      │
│  ├─ Input: Extracted PDF text, HTML content                     │
│  ├─ Output: Readability metrics, domain detection               │
│  └─ MIT OCW Specific: Collegiate level, STEM focus              │
│                                                                 │
│  Stage 2: Structure Inference                                   │
│  ├─ Input: Page structure, imsmanifest.xml                      │
│  ├─ Output: Verified/enhanced hierarchy                         │
│  └─ MIT OCW Specific: Use existing structure as template        │
│                                                                 │
│  Stage 3: Content Segmentation                                  │
│  ├─ Input: Lecture notes, transcripts                           │
│  ├─ Output: 2-5 minute segments with stopping points            │
│  └─ MIT OCW Specific: Align with video timestamps               │
│                                                                 │
│  Stage 4: Learning Objective Extraction                         │
│  ├─ Input: Syllabus, lecture content                            │
│  ├─ Output: Bloom-aligned objectives                            │
│  └─ MIT OCW Specific: Extract from syllabus "by end of..."      │
│                                                                 │
│  Stage 5: Assessment Generation                                 │
│  ├─ Input: Problem sets, exams (existing)                       │
│  ├─ Output: UMLCF assessments with feedback                     │
│  └─ MIT OCW Specific: Parse existing problems, add hints        │
│                                                                 │
│  Stage 6: Tutoring Enhancement                                  │
│  ├─ Input: All content                                          │
│  ├─ Output: Spoken text, alternatives, misconceptions           │
│  └─ MIT OCW Specific: Technical term pronunciation              │
│                                                                 │
│  Stage 7: Knowledge Graph                                       │
│  ├─ Input: Concepts, prerequisites                              │
│  ├─ Output: Prerequisite graph, related concepts                │
│  └─ MIT OCW Specific: Cross-reference other MIT courses         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### MIT OCW-Specific Enrichment

```python
class MITOCWEnrichmentConfig:
    """
    Configuration for AI enrichment of MIT OCW content.

    MIT OCW content is already high-quality but needs:
    - Segmentation for conversational delivery
    - Stopping points for comprehension checks
    - Spoken text variants for mathematical notation
    - Problem set transformation to interactive assessments
    """

    # Content Analysis settings
    EXPECTED_READING_LEVEL = "collegiate"
    EXPECTED_DOMAINS = ["mathematics", "computer-science", "physics", "engineering", "biology", "chemistry"]

    # Segmentation settings
    TARGET_SEGMENT_DURATION_SECONDS = 180  # 3 minutes
    MAX_SEGMENT_WORDS = 400
    MIN_SEGMENT_WORDS = 80

    # Stopping point frequency
    STOPPING_POINT_TRIGGERS = [
        "definition",           # After new terms
        "theorem",              # After important theorems
        "example_complete",     # After worked examples
        "section_end",          # At section boundaries
        "complexity_spike",     # When difficulty increases
    ]

    # Mathematical notation handling
    MATH_SPOKEN_CONVERSIONS = {
        # Greek letters
        "α": "alpha",
        "β": "beta",
        "γ": "gamma",
        "δ": "delta",
        "θ": "theta",
        "λ": "lambda",
        "π": "pi",
        "σ": "sigma",
        "Σ": "sum of",
        "∫": "integral of",
        "∂": "partial derivative",
        "∇": "del or nabla",
        "∞": "infinity",

        # Common expressions
        r"\frac{d}{dx}": "the derivative with respect to x of",
        r"\lim_{x \to": "the limit as x approaches",
        r"\sum_{i=": "the sum from i equals",
        r"O(n)": "order n or big O of n",
        r"O(n^2)": "order n squared",
    }

    # Assessment transformation
    ASSESSMENT_ENRICHMENT = {
        "add_hints": True,
        "generate_feedback": True,
        "create_variations": True,
        "difficulty_classification": True,
    }
```

---

## Error Handling

### Expected Errors and Recovery

```python
MIT_OCW_ERROR_HANDLING = {
    "zip_extraction_failed": {
        "cause": "Corrupted or incomplete download",
        "recovery": "Re-download package, try alternative source",
        "fallback": "Attempt URL-based extraction",
    },
    "missing_index_html": {
        "cause": "Non-standard package structure",
        "recovery": "Look for alternative entry points",
        "fallback": "Process all HTML files independently",
    },
    "pdf_extraction_failed": {
        "cause": "Scanned PDF or protected content",
        "recovery": "Try OCR-based extraction",
        "fallback": "Reference PDF without text extraction",
    },
    "missing_transcripts": {
        "cause": "Video-only course without transcripts",
        "recovery": "Generate transcripts via speech-to-text",
        "fallback": "Use lecture notes as primary content",
    },
    "math_parsing_failed": {
        "cause": "Complex LaTeX or images",
        "recovery": "Extract as images with alt text",
        "fallback": "Mark for manual review",
    },
}
```

---

## Testing Strategy

### Test Fixtures

```python
MIT_OCW_TEST_FIXTURES = {
    "minimal_valid": {
        "description": "Minimum valid MIT OCW package",
        "files": ["index.html", "pages/syllabus.html"],
        "expected_result": "valid",
    },
    "full_course": {
        "description": "Complete course with all materials",
        "source": "6.001 SICP",
        "files": ["index.html", "imsmanifest.xml", "pages/*", "static_resources/*"],
        "expected_topics": 28,  # Approximate
    },
    "video_course": {
        "description": "Video-heavy course with transcripts",
        "source": "18.06 Linear Algebra",
        "files": ["index.html", "pages/video-lectures.html", "resources/transcripts/*"],
        "expected_transcripts": 34,
    },
    "problem_set_extraction": {
        "description": "Test problem set PDF parsing",
        "source": "Sample problem set PDF",
        "expected_problems": 10,
        "expected_parts_per_problem": 3,
    },
}
```

### Integration Tests

```python
@pytest.mark.asyncio
async def test_mit_ocw_full_import():
    """Test full import pipeline with real MIT OCW content"""

    # Use cached test fixture (actual MIT OCW download)
    with open("fixtures/mit_ocw_6001_sample.zip", "rb") as f:
        content = f.read()

    importer = MITOCWImporter(storage=MemoryStorage())

    # Validate
    validation = await importer.validate(content)
    assert validation.is_valid
    assert validation.metadata.get("ocw_confirmed")

    # Import
    result = await importer.import_async(content, dry_run=True)
    assert result.success
    assert result.curriculum.title
    assert result.topic_count > 0

    # Check structure
    curriculum = result.curriculum
    assert curriculum.rights.license.type == "CC-BY-NC-SA-4.0"
    assert "MIT" in curriculum.lifecycle.contributors[0].organization
```

---

## Next Steps

1. **Implement core importer** - ZIP extraction and HTML parsing
2. **Add PDF extraction** - Lecture notes and problem sets
3. **Add transcript parser** - Video transcript processing
4. **Integrate AI enrichment** - Connect to enrichment pipeline
5. **Test with real courses** - 6.001, 18.06, 8.01
