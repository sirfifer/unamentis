"""
Source registry for discovering and accessing curriculum source handlers.
"""

from typing import Dict, List, Optional, Type

from .base import CurriculumSourceHandler
from .models import CurriculumSource


class SourceRegistry:
    """
    Registry for curriculum source handlers.

    Provides:
    - Source registration
    - Source discovery
    - Handler instantiation
    """

    _handlers: Dict[str, Type[CurriculumSourceHandler]] = {}
    _instances: Dict[str, CurriculumSourceHandler] = {}

    @classmethod
    def register(cls, handler_class: Type[CurriculumSourceHandler]) -> Type[CurriculumSourceHandler]:
        """
        Register a source handler class.

        Can be used as a decorator:
            @SourceRegistry.register
            class MITOCWHandler(CurriculumSourceHandler):
                ...

        Args:
            handler_class: Handler class to register

        Returns:
            The handler class (for decorator use)
        """
        # Instantiate to get source_id
        instance = handler_class()
        cls._handlers[instance.source_id] = handler_class
        cls._instances[instance.source_id] = instance
        return handler_class

    @classmethod
    def get_handler(cls, source_id: str) -> Optional[CurriculumSourceHandler]:
        """
        Get a handler instance by source ID.

        Args:
            source_id: Source identifier (e.g., "mit_ocw")

        Returns:
            Handler instance or None if not found
        """
        return cls._instances.get(source_id)

    @classmethod
    def get_all_handlers(cls) -> List[CurriculumSourceHandler]:
        """
        Get all registered handlers.

        Returns:
            List of handler instances
        """
        return list(cls._instances.values())

    @classmethod
    def get_all_sources(cls) -> List[CurriculumSource]:
        """
        Get source information for all registered handlers.

        Returns:
            List of CurriculumSource objects
        """
        return [handler.source_info for handler in cls._instances.values()]

    @classmethod
    def list_source_ids(cls) -> List[str]:
        """
        List all registered source IDs.

        Returns:
            List of source IDs
        """
        return list(cls._handlers.keys())

    @classmethod
    def is_registered(cls, source_id: str) -> bool:
        """
        Check if a source is registered.

        Args:
            source_id: Source identifier

        Returns:
            True if registered
        """
        return source_id in cls._handlers

    @classmethod
    def clear(cls):
        """Clear all registered handlers. Mainly for testing."""
        cls._handlers.clear()
        cls._instances.clear()


def discover_handlers():
    """
    Discover and register all available source handlers.

    This function imports handler modules to trigger registration.
    Call this at application startup.
    """
    # Import handler modules to trigger @SourceRegistry.register decorators
    try:
        from ..sources import mit_ocw
    except ImportError:
        pass

    try:
        from ..sources import stanford_see
    except ImportError:
        pass

    try:
        from ..sources import ck12
    except ImportError:
        pass

    try:
        from ..sources import fastai
    except ImportError:
        pass
