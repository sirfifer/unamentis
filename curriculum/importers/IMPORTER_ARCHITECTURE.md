# UMCF Import System Architecture

**Version:** 1.0.0
**Status:** Draft
**Date:** 2025-12-17

---

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Architecture](#architecture)
4. [Plugin System](#plugin-system)
5. [Deployment Targets](#deployment-targets)
6. [Core Interfaces](#core-interfaces)
7. [Implementation Guide](#implementation-guide)
8. [Technology Decisions](#technology-decisions)

---

## Overview

The UMCF Import System is a **pluggable, cross-platform** toolkit for converting external curriculum formats into the Una Mentis Curriculum Format (UMCF). It follows a "hub-and-spoke" model where UMCF is the canonical format and importers are plugins that convert from various sources.

### Goals

1. **Pluggable**: Add new importers without modifying core code
2. **Cross-Platform**: Same codebase runs on iOS, server, CLI, and browser
3. **Standards-Based**: Leverage existing educational standards (IMSCC, QTI, OLX)
4. **Python-First**: Python as primary implementation language
5. **Async-Native**: Non-blocking I/O for performance across all platforms

### Hub-and-Spoke Model

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   CK-12     │     │   Fast.ai   │     │   IMSCC     │
│   (EPUB)    │     │ (Notebooks) │     │   (ZIP)     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │    ┌──────────────┼──────────────┐    │
       │    │              │              │    │
       ▼    ▼              ▼              ▼    ▼
┌──────────────────────────────────────────────────┐
│                  IMPORT PLUGINS                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ CK12     │  │ Fastai   │  │ IMSCC    │  ...  │
│  │ Importer │  │ Importer │  │ Importer │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
└───────┼─────────────┼─────────────┼──────────────┘
        │             │             │
        ▼             ▼             ▼
┌──────────────────────────────────────────────────┐
│                    UMCF                            │
│              (Canonical Format)                   │
│                   .umcf                            │
└──────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────┐
│               STORAGE BACKENDS                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ CoreData │  │ SQLite   │  │ FileSystem│       │
│  │  (iOS)   │  │ (Server) │  │   (CLI)  │       │
│  └──────────┘  └──────────┘  └──────────┘       │
└──────────────────────────────────────────────────┘
```

---

## Design Principles

### 1. Pure Python Core

All core logic must be pure Python (no C extensions) to ensure compatibility with:
- iOS (Pythonista, Pyto, PEP 730)
- Browser (Pyodide/WebAssembly)
- Server (standard CPython)

**Exception**: Server-only deployments may use optional C extensions for performance (lxml, etc.)

### 2. Dependency Injection

Services (storage, logging, HTTP clients) are injected, not hard-coded:
- Different implementations for each platform
- Easy testing with mock services
- No platform-specific imports in core logic

### 3. Entry Points for Plugin Discovery

Plugins register via Python entry points (PEP 621):
- Standard mechanism across all Python environments
- Lazy loading for fast startup
- Third-party plugins supported

### 4. Async/Await Native

All I/O operations are async:
- Non-blocking on server (handles concurrent requests)
- Responsive on iOS (doesn't freeze UI)
- Compatible with sync wrappers where needed

### 5. Pydantic for Validation

All data models use Pydantic:
- Runtime type validation
- JSON serialization built-in
- Works in API, CLI, and tests

---

## Architecture

### Directory Structure

```
unamentis_curriculum_importer/
│
├── pyproject.toml              # Package config + entry points
├── README.md
│
├── src/
│   └── vlcf_importer/
│       │
│       ├── __init__.py
│       ├── version.py
│       │
│       ├── core/                    # Core abstractions
│       │   ├── __init__.py
│       │   ├── base.py              # ABC: CurriculumImporter
│       │   ├── models.py            # Pydantic: ImportResult, CurriculumData
│       │   ├── registry.py          # Plugin discovery & registration
│       │   ├── context.py           # ImportContext (DI container)
│       │   └── errors.py            # Domain exceptions
│       │
│       ├── importers/               # Plugin implementations
│       │   ├── __init__.py
│       │   ├── ck12/                # CK-12 FlexBook importer
│       │   │   ├── __init__.py
│       │   │   ├── importer.py
│       │   │   ├── epub_parser.py
│       │   │   └── quiz_extractor.py
│       │   │
│       │   ├── fastai/              # Fast.ai notebook importer
│       │   │   ├── __init__.py
│       │   │   ├── importer.py
│       │   │   ├── notebook_parser.py
│       │   │   └── code_extractor.py
│       │   │
│       │   ├── imscc/               # IMS Common Cartridge
│       │   │   ├── __init__.py
│       │   │   ├── importer.py
│       │   │   ├── manifest_parser.py
│       │   │   └── qti_parser.py
│       │   │
│       │   └── raw/                 # Raw JSON/YAML files
│       │       ├── __init__.py
│       │       └── importer.py
│       │
│       ├── parsers/                 # Shared format parsers
│       │   ├── __init__.py
│       │   ├── xml_parser.py        # Pure Python XML
│       │   ├── json_parser.py
│       │   ├── html_extractor.py
│       │   ├── epub_parser.py       # EPUB structure
│       │   ├── notebook_parser.py   # Jupyter .ipynb
│       │   └── markdown_parser.py
│       │
│       ├── transformers/            # UMCF model transformers
│       │   ├── __init__.py
│       │   ├── content_transformer.py
│       │   ├── assessment_transformer.py
│       │   └── metadata_transformer.py
│       │
│       ├── storage/                 # Pluggable storage backends
│       │   ├── __init__.py
│       │   ├── base.py              # ABC: StorageBackend
│       │   ├── filesystem.py        # Local files
│       │   ├── memory.py            # In-memory (testing)
│       │   └── database.py          # SQLAlchemy (server)
│       │
│       ├── validators/              # Format validators
│       │   ├── __init__.py
│       │   ├── vlcf_validator.py    # JSON Schema validation
│       │   └── content_validator.py # Business logic validation
│       │
│       └── config/
│           ├── __init__.py
│           └── settings.py          # Pydantic BaseSettings
│
├── server/                          # Server-specific (optional)
│   ├── __init__.py
│   ├── api.py                       # FastAPI app
│   ├── routes.py                    # API endpoints
│   └── dependencies.py              # FastAPI DI
│
├── cli/                             # CLI tool
│   ├── __init__.py
│   └── main.py                      # Typer commands
│
└── tests/
    ├── conftest.py
    ├── test_importers/
    ├── test_parsers/
    └── fixtures/
```

### Entry Points Configuration

```toml
# pyproject.toml

[project]
name = "vlcf-importer"
version = "1.0.0"
description = "Pluggable curriculum importer for UnaMentis"
requires-python = ">=3.10"
dependencies = [
    "pydantic>=2.0",
    "aiofiles>=23.0",
]

[project.optional-dependencies]
server = [
    "fastapi>=0.100",
    "uvicorn>=0.23",
]
cli = [
    "typer>=0.9",
    "rich>=13.0",
]
dev = [
    "pytest>=7.0",
    "pytest-asyncio>=0.21",
]

[project.entry-points."vlcf.importers"]
ck12 = "vlcf_importer.importers.ck12:CK12Importer"
fastai = "vlcf_importer.importers.fastai:FastaiImporter"
imscc = "vlcf_importer.importers.imscc:IMSCCImporter"
raw = "vlcf_importer.importers.raw:RawImporter"

[project.entry-points."vlcf.storage"]
filesystem = "vlcf_importer.storage.filesystem:FileSystemStorage"
memory = "vlcf_importer.storage.memory:MemoryStorage"
database = "vlcf_importer.storage.database:DatabaseStorage"

[project.scripts]
vlcf-import = "vlcf_importer.cli.main:app"
```

---

## Plugin System

### Plugin Discovery

Plugins are discovered at runtime via `importlib.metadata`:

```python
# core/registry.py
from importlib.metadata import entry_points
from typing import Dict, Type
from .base import CurriculumImporter

class ImporterRegistry:
    """Registry for curriculum importer plugins"""

    _importers: Dict[str, Type[CurriculumImporter]] = {}
    _loaded: bool = False

    @classmethod
    def discover(cls) -> None:
        """Discover and register all available importers"""
        if cls._loaded:
            return

        eps = entry_points(group="vlcf.importers")
        for ep in eps:
            try:
                importer_class = ep.load()
                cls._importers[ep.name] = importer_class
            except Exception as e:
                # Log but don't fail - plugin may have missing deps
                pass

        cls._loaded = True

    @classmethod
    def get(cls, name: str) -> Type[CurriculumImporter]:
        """Get importer class by name"""
        cls.discover()
        if name not in cls._importers:
            raise ValueError(f"Unknown importer: {name}")
        return cls._importers[name]

    @classmethod
    def list_available(cls) -> list[str]:
        """List all available importer names"""
        cls.discover()
        return list(cls._importers.keys())
```

### Creating a New Importer Plugin

1. Create a new package under `importers/`
2. Implement the `CurriculumImporter` ABC
3. Register via entry points in `pyproject.toml`

```python
# importers/myformat/importer.py
from vlcf_importer.core.base import CurriculumImporter, ImportContext
from vlcf_importer.core.models import ImportResult, CurriculumData

class MyFormatImporter(CurriculumImporter):
    """Importer for MyFormat curriculum files"""

    name = "myformat"
    description = "Import MyFormat curriculum packages"
    file_extensions = [".myf", ".myformat"]

    async def validate(self, content: bytes) -> dict:
        # Validate without full parsing
        ...

    async def extract(self, content: bytes) -> dict:
        # Extract raw data structure
        ...

    async def parse(self, content: bytes) -> CurriculumData:
        # Full parse and transform to UMCF
        ...
```

---

## Deployment Targets

### Target 1: CLI Tool

```bash
# Install
pip install vlcf-importer[cli]

# Usage
vlcf-import list                           # List available importers
vlcf-import validate file.epub --format ck12
vlcf-import convert file.epub -o output.umcf --format ck12
vlcf-import import file.epub --format ck12 --storage filesystem
```

### Target 2: iOS (Pythonista/Pyto)

```python
# Inside Pythonista or Pyto
import sys
sys.path.insert(0, '/path/to/vlcf_importer')

from vlcf_importer.core.registry import ImporterRegistry
from vlcf_importer.storage.filesystem import FileSystemStorage

# Read file from iOS Files app
with open('/Documents/curriculum.epub', 'rb') as f:
    content = f.read()

# Import
storage = FileSystemStorage(base_path='/Documents/curricula/')
importer = ImporterRegistry.get('ck12')(storage=storage)
result = await importer.import_async(content)

print(f"Imported: {result.curriculum.title}")
```

### Target 3: Server (FastAPI)

```python
# server/api.py
from fastapi import FastAPI, UploadFile, File, Query
from vlcf_importer.core.registry import ImporterRegistry

app = FastAPI(title="UMCF Import API")

@app.post("/import")
async def import_curriculum(
    file: UploadFile = File(...),
    format: str = Query(..., description="Importer name")
):
    content = await file.read()
    importer = ImporterRegistry.get(format)(storage=get_storage())
    result = await importer.import_async(content)
    return result.dict()
```

### Target 4: Browser (Pyodide - Future)

```javascript
// Load Pyodide with vlcf-importer
const pyodide = await loadPyodide();
await pyodide.loadPackage("micropip");
await pyodide.runPythonAsync(`
    import micropip
    await micropip.install("vlcf-importer")
`);

// Use from JavaScript
const result = await pyodide.runPythonAsync(`
    from vlcf_importer.importers.raw import RawImporter
    from vlcf_importer.storage.memory import MemoryStorage

    content = bytes(${JSON.stringify(Array.from(fileBytes))})
    importer = RawImporter(storage=MemoryStorage())
    result = await importer.import_async(content)
    result.dict()
`);
```

---

## Core Interfaces

### CurriculumImporter (ABC)

```python
# core/base.py
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
from pathlib import Path

class ValidationResult(BaseModel):
    """Result of format validation"""
    is_valid: bool
    errors: List[str] = []
    warnings: List[str] = []
    format_version: Optional[str] = None
    metadata: Dict[str, Any] = {}

class ImportResult(BaseModel):
    """Result of curriculum import"""
    success: bool
    curriculum_id: Optional[str] = None
    curriculum: Optional["CurriculumData"] = None
    topic_count: int = 0
    assessment_count: int = 0
    errors: List[str] = []
    warnings: List[str] = []

class CurriculumImporter(ABC):
    """Abstract base class for all curriculum importers"""

    # Importer metadata (override in subclasses)
    name: str = "base"
    description: str = "Base importer"
    file_extensions: List[str] = []

    def __init__(
        self,
        storage: "StorageBackend",
        config: Optional[Dict[str, Any]] = None,
        logger: Optional["Logger"] = None
    ):
        self.storage = storage
        self.config = config or {}
        self.logger = logger or self._default_logger()

    @abstractmethod
    async def validate(self, content: bytes) -> ValidationResult:
        """
        Validate content without full parsing.

        Use for quick format checks before committing to full import.
        """
        pass

    @abstractmethod
    async def extract(self, content: bytes) -> Dict[str, Any]:
        """
        Extract raw data from format.

        Returns intermediate representation before UMCF transformation.
        Useful for debugging and format inspection.
        """
        pass

    @abstractmethod
    async def parse(self, content: bytes) -> "CurriculumData":
        """
        Parse content and transform to UMCF format.

        This is the main parsing method that produces a complete
        CurriculumData object ready for storage.
        """
        pass

    async def import_async(
        self,
        content: bytes,
        dry_run: bool = False
    ) -> ImportResult:
        """
        Full import pipeline with validation, parsing, and storage.

        Args:
            content: Raw file bytes
            dry_run: If True, parse but don't save to storage

        Returns:
            ImportResult with success status and curriculum data
        """
        # 1. Validate
        validation = await self.validate(content)
        if not validation.is_valid:
            return ImportResult(
                success=False,
                errors=validation.errors,
                warnings=validation.warnings
            )

        # 2. Parse
        try:
            curriculum = await self.parse(content)
        except Exception as e:
            self.logger.exception("Parse failed")
            return ImportResult(
                success=False,
                errors=[f"Parse error: {str(e)}"]
            )

        # 3. Store (unless dry run)
        if not dry_run:
            try:
                curriculum_id = await self.storage.save(curriculum)
            except Exception as e:
                self.logger.exception("Storage failed")
                return ImportResult(
                    success=False,
                    curriculum=curriculum,
                    errors=[f"Storage error: {str(e)}"]
                )
        else:
            curriculum_id = None

        # 4. Return result
        return ImportResult(
            success=True,
            curriculum_id=curriculum_id,
            curriculum=curriculum,
            topic_count=self._count_topics(curriculum),
            assessment_count=self._count_assessments(curriculum),
            warnings=validation.warnings
        )

    def _count_topics(self, curriculum: "CurriculumData") -> int:
        """Recursively count all topics"""
        def count_node(node):
            total = 1
            for child in node.get("children", []):
                total += count_node(child)
            return total
        return sum(count_node(n) for n in curriculum.content)

    def _count_assessments(self, curriculum: "CurriculumData") -> int:
        """Count all assessments across all nodes"""
        def count_node(node):
            total = len(node.get("assessments", []))
            for child in node.get("children", []):
                total += count_node(child)
            return total
        return sum(count_node(n) for n in curriculum.content)
```

### StorageBackend (ABC)

```python
# storage/base.py
from abc import ABC, abstractmethod
from typing import Optional, List
from uuid import UUID

class StorageBackend(ABC):
    """Abstract base class for curriculum storage"""

    @abstractmethod
    async def save(self, curriculum: "CurriculumData") -> str:
        """
        Save curriculum and return its ID.

        Args:
            curriculum: Complete curriculum data

        Returns:
            Unique identifier for the saved curriculum
        """
        pass

    @abstractmethod
    async def get(self, curriculum_id: str) -> Optional["CurriculumData"]:
        """
        Retrieve curriculum by ID.

        Args:
            curriculum_id: Unique identifier

        Returns:
            CurriculumData or None if not found
        """
        pass

    @abstractmethod
    async def list(self) -> List[dict]:
        """
        List all curricula (summary only).

        Returns:
            List of curriculum summaries (id, title, created_at)
        """
        pass

    @abstractmethod
    async def delete(self, curriculum_id: str) -> bool:
        """
        Delete curriculum by ID.

        Returns:
            True if deleted, False if not found
        """
        pass
```

---

## Implementation Guide

### Step 1: Set Up Package Structure

```bash
mkdir -p unamentis_curriculum_importer/src/vlcf_importer/{core,importers,parsers,storage}
touch unamentis_curriculum_importer/pyproject.toml
```

### Step 2: Implement Core Models

Create Pydantic models matching UMCF schema (already defined in umcf-schema.json).

### Step 3: Implement Base Classes

Create ABCs for `CurriculumImporter` and `StorageBackend`.

### Step 4: Implement First Importer

Start with the simplest importer (raw JSON) to validate architecture.

### Step 5: Add CLI

Use Typer for command-line interface.

### Step 6: Add Server (Optional)

Use FastAPI for HTTP API.

### Step 7: Add More Importers

Implement CK-12, Fast.ai, IMSCC importers.

---

## Technology Decisions

### Why Python?

| Factor | Reasoning |
|--------|-----------|
| **Education ecosystem** | Most curriculum tools, Jupyter, data science in Python |
| **Cross-platform** | Works on iOS (Pythonista/Pyto), server, browser (Pyodide) |
| **ML/AI integration** | Native integration with PyTorch, HuggingFace, Fast.ai |
| **Rapid development** | Dynamic typing, rich libraries, async support |
| **Your team** | Familiar with Python from AI/ML work |

### Why Not Alternatives?

| Language | Why Not |
|----------|---------|
| **Swift** | iOS-only, can't run on server or browser |
| **JavaScript/TypeScript** | Worse ML ecosystem, no Jupyter integration |
| **Rust** | Steeper learning curve, slower iteration |
| **Go** | Limited ML ecosystem, no Jupyter |

### Core Dependencies

| Dependency | Purpose | Pure Python? |
|------------|---------|--------------|
| `pydantic>=2.0` | Data validation & serialization | Yes |
| `aiofiles>=23.0` | Async file I/O | Yes |
| `ebooklib` | EPUB parsing | Yes |
| `nbformat` | Jupyter notebook parsing | Yes |

### Optional Dependencies

| Dependency | Purpose | When Needed |
|------------|---------|-------------|
| `fastapi` | HTTP API | Server deployment |
| `uvicorn` | ASGI server | Server deployment |
| `typer` | CLI framework | CLI tool |
| `rich` | CLI output formatting | CLI tool |
| `lxml` | Fast XML parsing | Server (performance) |
| `beautifulsoup4` | Robust HTML parsing | Complex HTML content |

---

## Next Steps

See companion specifications:
- [CK12_IMPORTER_SPEC.md](./CK12_IMPORTER_SPEC.md) - K-12 curriculum from CK-12 FlexBooks
- [FASTAI_IMPORTER_SPEC.md](./FASTAI_IMPORTER_SPEC.md) - AI/ML curriculum from Fast.ai notebooks
