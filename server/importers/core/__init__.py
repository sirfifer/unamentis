"""
Core importer components: models, base classes, orchestration.
"""

from .models import (
    LicenseInfo,
    CurriculumSource,
    CourseFeature,
    CourseCatalogEntry,
    CourseDetail,
    LectureInfo,
    AssignmentInfo,
    ExamInfo,
    ImportConfig,
    ImportStage,
    ImportLogEntry,
    ImportProgress,
    ImportResult,
    ImportStatus,
)
from .base import CurriculumSourceHandler
from .orchestrator import ImportOrchestrator
from .registry import SourceRegistry

__all__ = [
    # Models
    "LicenseInfo",
    "CurriculumSource",
    "CourseFeature",
    "CourseCatalogEntry",
    "CourseDetail",
    "LectureInfo",
    "AssignmentInfo",
    "ExamInfo",
    "ImportConfig",
    "ImportStage",
    "ImportLogEntry",
    "ImportProgress",
    "ImportResult",
    "ImportStatus",
    # Classes
    "CurriculumSourceHandler",
    "ImportOrchestrator",
    "SourceRegistry",
]
