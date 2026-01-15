# TTS Pre-Generation Module
# Batch audio generation and voice profile management

from .models import (
    TTSProfile,
    TTSProfileSettings,
    TTSModuleProfile,
    TTSPregenJob,
    TTSJobItem,
    TTSComparisonSession,
    TTSComparisonVariant,
    TTSComparisonRating,
    JobStatus,
    ItemStatus,
    SessionStatus,
    VariantStatus,
)
from .repository import TTSPregenRepository
from .profile_manager import TTSProfileManager

__all__ = [
    # Models
    "TTSProfile",
    "TTSProfileSettings",
    "TTSModuleProfile",
    "TTSPregenJob",
    "TTSJobItem",
    "TTSComparisonSession",
    "TTSComparisonVariant",
    "TTSComparisonRating",
    # Enums
    "JobStatus",
    "ItemStatus",
    "SessionStatus",
    "VariantStatus",
    # Services
    "TTSPregenRepository",
    "TTSProfileManager",
]
