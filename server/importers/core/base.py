"""
Base class for curriculum source handlers.

Each source (MIT OCW, Stanford SEE, etc.) implements this interface
to provide:
- Course catalog browsing
- Course detail retrieval
- Content downloading
- License validation
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from .models import (
    CourseCatalogEntry,
    CourseDetail,
    CurriculumSource,
    LicenseInfo,
)


@dataclass
class ValidationResult:
    """Result of content validation."""
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    metadata: Dict[str, Any]


@dataclass
class LicenseValidationResult:
    """Result of license validation."""
    can_import: bool
    license: Optional[LicenseInfo]
    warnings: List[str]
    attribution_text: str


class LicenseRestrictionError(Exception):
    """Raised when a course cannot be imported due to license restrictions."""
    pass


class CurriculumSourceHandler(ABC):
    """
    Abstract base class for curriculum source handlers.

    Each source (MIT OCW, Stanford SEE, CK-12, etc.) implements this
    to provide catalog browsing and content download capabilities.

    Implementations MUST:
    1. Preserve license information for all content
    2. Block restricted content (e.g., Stanford LOGIC course)
    3. Include proper attribution in all outputs
    """

    @property
    @abstractmethod
    def source_id(self) -> str:
        """Unique identifier for this source (e.g., 'mit_ocw')."""
        pass

    @property
    @abstractmethod
    def source_info(self) -> CurriculumSource:
        """Full source information for display."""
        pass

    @property
    @abstractmethod
    def default_license(self) -> LicenseInfo:
        """Default license for this source's content."""
        pass

    # =========================================================================
    # Catalog Methods
    # =========================================================================

    @abstractmethod
    async def get_course_catalog(
        self,
        page: int = 1,
        page_size: int = 20,
        filters: Optional[Dict[str, Any]] = None,
        search: Optional[str] = None,
    ) -> Tuple[List[CourseCatalogEntry], int, Dict[str, List[str]]]:
        """
        Get paginated course catalog.

        Args:
            page: Page number (1-indexed)
            page_size: Items per page
            filters: Optional filters (subject, level, features)
            search: Optional search query

        Returns:
            Tuple of:
            - List of course entries
            - Total count
            - Available filter options
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
            LicenseRestrictionError: If course cannot be imported
            ValueError: If course not found
        """
        pass

    @abstractmethod
    async def search_courses(
        self,
        query: str,
        limit: int = 20,
    ) -> List[CourseCatalogEntry]:
        """
        Search courses by query.

        Args:
            query: Search query
            limit: Maximum results

        Returns:
            List of matching courses
        """
        pass

    # =========================================================================
    # Download Methods
    # =========================================================================

    @abstractmethod
    async def download_course(
        self,
        course_id: str,
        output_dir: Path,
        progress_callback: Optional[Callable[[float, str], None]] = None,
    ) -> Path:
        """
        Download course content to local directory.

        Args:
            course_id: Course to download
            output_dir: Where to save content
            progress_callback: Called with (progress 0-100, message)

        Returns:
            Path to downloaded content (ZIP file or directory)

        Raises:
            LicenseRestrictionError: If course cannot be downloaded
        """
        pass

    @abstractmethod
    async def get_download_size(self, course_id: str) -> str:
        """
        Estimate download size for a course.

        Args:
            course_id: Course identifier

        Returns:
            Human-readable size (e.g., "2.5 MB", "1.2 GB")
        """
        pass

    # =========================================================================
    # License Methods (CRITICAL)
    # =========================================================================

    @abstractmethod
    def validate_license(self, course_id: str) -> LicenseValidationResult:
        """
        Validate that a course can be imported under its license.

        This method MUST:
        1. Check for license restrictions (e.g., Stanford LOGIC)
        2. Return the applicable license
        3. Generate required attribution text

        Args:
            course_id: Course to validate

        Returns:
            LicenseValidationResult with import permission and details
        """
        pass

    def get_license_for_course(self, course_id: str) -> LicenseInfo:
        """
        Get the license for a specific course.

        Default implementation returns the source's default license.
        Override for sources with per-course licensing.

        Args:
            course_id: Course identifier

        Returns:
            LicenseInfo for this course
        """
        return self.default_license

    # =========================================================================
    # Utility Methods
    # =========================================================================

    def get_attribution_text(self, course_id: str, course_title: str) -> str:
        """
        Generate attribution text for a course.

        Args:
            course_id: Course identifier
            course_title: Course title

        Returns:
            Attribution text to include in imported content
        """
        license_info = self.get_license_for_course(course_id)
        source_info = self.source_info

        return (
            f"This content is derived from {source_info.name} ({source_info.base_url}). "
            f'Original course: "{course_title}". '
            f"Licensed under {license_info.name}."
        )

    async def validate_content(self, content_path: Path) -> ValidationResult:
        """
        Validate downloaded content.

        Default implementation checks file exists and has content.
        Override for format-specific validation.

        Args:
            content_path: Path to downloaded content

        Returns:
            ValidationResult with any errors/warnings
        """
        errors = []
        warnings = []
        metadata = {}

        if not content_path.exists():
            errors.append(f"Content not found at {content_path}")
        elif content_path.is_file() and content_path.stat().st_size == 0:
            errors.append("Downloaded file is empty")
        else:
            metadata["path"] = str(content_path)
            if content_path.is_file():
                metadata["size"] = content_path.stat().st_size

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            metadata=metadata,
        )
