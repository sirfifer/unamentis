"""
UMLCF Curriculum Importer Package

This package provides tools for importing curriculum content from external sources
(MIT OCW, Stanford SEE, CK-12, etc.) into the UnaMentis UMLCF format.

Architecture:
    sources/     - Source handlers for fetching course catalogs and content
    parsers/     - Content extraction (PDF, HTML, transcripts)
    enrichment/  - AI enrichment pipeline integration
    core/        - Base classes, models, and orchestration
"""

from .core.models import (
    ImportConfig,
    ImportProgress,
    ImportResult,
    CurriculumSource,
    CourseCatalogEntry,
    CourseDetail,
)
from .core.orchestrator import ImportOrchestrator
from .core.registry import SourceRegistry

__version__ = "1.0.0"

__all__ = [
    "ImportConfig",
    "ImportProgress",
    "ImportResult",
    "CurriculumSource",
    "CourseCatalogEntry",
    "CourseDetail",
    "ImportOrchestrator",
    "SourceRegistry",
]
