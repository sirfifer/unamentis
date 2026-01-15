"""
API routes for TTS pre-generation system.

These routes power the TTS Profile and Batch Generation features in the
management dashboard, enabling users to:
- Manage TTS profiles (reusable voice configurations)
- Assign profiles to modules
- Run A/B comparison sessions
- Execute batch pre-generation jobs
"""

import logging
import os
from pathlib import Path
from typing import Optional
from uuid import UUID

from aiohttp import web

from tts_pregen import (
    TTSProfile,
    TTSProfileManager,
    TTSPregenRepository,
    JobStatus,
    SessionStatus,
)
from tts_pregen.comparison_manager import TTSComparisonManager

logger = logging.getLogger(__name__)

# Global manager instances
_profile_manager: Optional[TTSProfileManager] = None
_comparison_manager: Optional[TTSComparisonManager] = None

# Reference to the aiohttp app
_app: Optional[web.Application] = None

# Output directory for pre-generated audio
PREGEN_OUTPUT_DIR = Path(__file__).parent / "data" / "tts-pregenerated"


def _get_profile_manager() -> TTSProfileManager:
    """Get the profile manager instance."""
    global _profile_manager
    if _profile_manager is None:
        raise RuntimeError("TTS Profile Manager not initialized")
    return _profile_manager


def _get_comparison_manager() -> TTSComparisonManager:
    """Get the comparison manager instance."""
    global _comparison_manager
    if _comparison_manager is None:
        raise RuntimeError("TTS Comparison Manager not initialized")
    return _comparison_manager


def _parse_uuid(value: str, name: str = "id") -> UUID:
    """Parse a UUID from string, raising appropriate error."""
    try:
        return UUID(value)
    except ValueError:
        raise ValueError(f"Invalid {name}: {value}")


# =============================================================================
# Profile Routes
# =============================================================================


async def handle_create_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles

    Create a new TTS profile.

    Body:
    {
        "name": "Knowledge Bowl Tutor",
        "provider": "chatterbox",
        "voice_id": "nova",
        "settings": {"speed": 1.1, "exaggeration": 0.7},
        "description": "Optimized for quiz delivery",
        "tags": ["tutor", "knowledge-bowl"],
        "use_case": "questions",
        "is_default": false,
        "generate_sample": true,
        "sample_text": "Custom sample text"
    }
    """
    try:
        data = await request.json()
        manager = _get_profile_manager()

        # Validate required fields
        name = data.get("name")
        provider = data.get("provider")
        voice_id = data.get("voice_id")

        if not name:
            return web.json_response({"success": False, "error": "name is required"}, status=400)
        if not provider:
            return web.json_response({"success": False, "error": "provider is required"}, status=400)
        if not voice_id:
            return web.json_response({"success": False, "error": "voice_id is required"}, status=400)

        profile = await manager.create_profile(
            name=name,
            provider=provider,
            voice_id=voice_id,
            settings=data.get("settings"),
            description=data.get("description"),
            tags=data.get("tags"),
            use_case=data.get("use_case"),
            is_default=data.get("is_default", False),
            generate_sample=data.get("generate_sample", True),
            sample_text=data.get("sample_text"),
        )

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error creating profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_list_profiles(request: web.Request) -> web.Response:
    """
    GET /api/tts/profiles

    List TTS profiles with optional filtering.

    Query parameters:
    - provider: Filter by provider (chatterbox, vibevoice, piper)
    - tags: Comma-separated list of tags (any match)
    - use_case: Filter by use case
    - is_active: Filter by active status (default true)
    - limit: Max results (default 100)
    - offset: Pagination offset (default 0)
    """
    try:
        manager = _get_profile_manager()

        provider = request.query.get("provider")
        tags_param = request.query.get("tags")
        tags = [t.strip() for t in tags_param.split(",")] if tags_param else None
        use_case = request.query.get("use_case")
        is_active_param = request.query.get("is_active", "true")
        is_active = is_active_param.lower() != "false" if is_active_param else True
        limit = int(request.query.get("limit", "100"))
        offset = int(request.query.get("offset", "0"))

        profiles, total = await manager.list_profiles(
            provider=provider,
            tags=tags,
            use_case=use_case,
            is_active=is_active,
            limit=limit,
            offset=offset,
        )

        return web.json_response({
            "success": True,
            "profiles": [p.to_dict() for p in profiles],
            "total": total,
            "limit": limit,
            "offset": offset,
        })

    except Exception as e:
        logger.exception("Error listing profiles")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_profile(request: web.Request) -> web.Response:
    """
    GET /api/tts/profiles/{profile_id}

    Get a specific TTS profile.
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        profile = await manager.get_profile(profile_id)
        if not profile:
            return web.json_response({"success": False, "error": "Profile not found"}, status=404)

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error getting profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_update_profile(request: web.Request) -> web.Response:
    """
    PUT /api/tts/profiles/{profile_id}

    Update a TTS profile.

    Body (all fields optional):
    {
        "name": "New Name",
        "description": "Updated description",
        "provider": "chatterbox",
        "voice_id": "nova",
        "settings": {"speed": 1.2},
        "tags": ["updated", "tags"],
        "use_case": "explanations",
        "regenerate_sample": false,
        "sample_text": "New sample text"
    }
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        data = await request.json()
        manager = _get_profile_manager()

        profile = await manager.update_profile(
            profile_id=profile_id,
            name=data.get("name"),
            description=data.get("description"),
            provider=data.get("provider"),
            voice_id=data.get("voice_id"),
            settings=data.get("settings"),
            tags=data.get("tags"),
            use_case=data.get("use_case"),
            regenerate_sample=data.get("regenerate_sample", False),
            sample_text=data.get("sample_text"),
        )

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error updating profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_delete_profile(request: web.Request) -> web.Response:
    """
    DELETE /api/tts/profiles/{profile_id}

    Delete a TTS profile.

    Query parameters:
    - hard: If "true", permanently delete; otherwise soft delete (default)
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        hard = request.query.get("hard", "false").lower() == "true"
        manager = _get_profile_manager()

        deleted = await manager.delete_profile(profile_id, soft=not hard)

        if not deleted:
            return web.json_response({"success": False, "error": "Profile not found"}, status=404)

        return web.json_response({
            "success": True,
            "deleted": True,
            "permanent": hard,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error deleting profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_set_default_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles/{profile_id}/set-default

    Set a profile as the system default.
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        await manager.set_default_profile(profile_id)

        return web.json_response({
            "success": True,
            "default_profile_id": str(profile_id),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error setting default profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_preview_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles/{profile_id}/preview

    Generate or regenerate sample audio for a profile.

    Body (optional):
    {
        "sample_text": "Custom text for preview"
    }
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        data = {}
        if request.body_exists:
            data = await request.json()

        sample_text = data.get("sample_text")
        profile = await manager.regenerate_sample(profile_id, sample_text=sample_text)

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
            "sample_audio_path": profile.sample_audio_path,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error generating preview")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_profile_audio(request: web.Request) -> web.Response:
    """
    GET /api/tts/profiles/{profile_id}/audio

    Stream the sample audio for a profile.
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        profile = await manager.get_profile(profile_id)
        if not profile:
            return web.json_response({"success": False, "error": "Profile not found"}, status=404)

        if not profile.sample_audio_path:
            return web.json_response({"success": False, "error": "No sample audio available"}, status=404)

        audio_path = Path(profile.sample_audio_path)
        if not audio_path.exists():
            return web.json_response({"success": False, "error": "Sample audio file not found"}, status=404)

        return web.FileResponse(
            audio_path,
            headers={"Content-Type": "audio/wav"},
        )

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error streaming profile audio")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_duplicate_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles/{profile_id}/duplicate

    Duplicate a profile with a new name.

    Body:
    {
        "name": "New Profile Name",
        "description": "Optional new description"
    }
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        data = await request.json()
        manager = _get_profile_manager()

        name = data.get("name")
        if not name:
            return web.json_response({"success": False, "error": "name is required"}, status=400)

        profile = await manager.duplicate_profile(
            profile_id=profile_id,
            new_name=name,
            description=data.get("description"),
        )

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error duplicating profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_export_profile(request: web.Request) -> web.Response:
    """
    GET /api/tts/profiles/{profile_id}/export

    Export a profile to portable JSON format.
    """
    try:
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        export_data = await manager.export_profile(profile_id)

        return web.json_response({
            "success": True,
            "export": export_data,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error exporting profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_import_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles/import

    Import a profile from exported JSON.

    Body:
    {
        "export": { ... exported profile data ... },
        "name": "Optional name override"
    }
    """
    try:
        data = await request.json()
        manager = _get_profile_manager()

        export_data = data.get("export")
        if not export_data:
            return web.json_response({"success": False, "error": "export data is required"}, status=400)

        profile = await manager.import_profile(
            data=export_data,
            name_override=data.get("name"),
        )

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error importing profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


# =============================================================================
# Module Profile Association Routes
# =============================================================================


async def handle_get_module_profiles(request: web.Request) -> web.Response:
    """
    GET /api/tts/modules/{module_id}/profiles

    Get profiles assigned to a module.

    Query parameters:
    - context: Optional context filter (questions, explanations, etc.)
    """
    try:
        module_id = request.match_info["module_id"]
        context = request.query.get("context")
        manager = _get_profile_manager()

        results = await manager.get_module_profiles(module_id, context)

        return web.json_response({
            "success": True,
            "module_id": module_id,
            "profiles": [
                {
                    "association": {
                        "id": str(assoc.id),
                        "context": assoc.context,
                        "priority": assoc.priority,
                        "created_at": assoc.created_at.isoformat(),
                    },
                    "profile": profile.to_dict(),
                }
                for assoc, profile in results
            ],
        })

    except Exception as e:
        logger.exception("Error getting module profiles")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_assign_module_profile(request: web.Request) -> web.Response:
    """
    POST /api/tts/modules/{module_id}/profiles

    Assign a profile to a module.

    Body:
    {
        "profile_id": "uuid",
        "context": "questions",  // optional
        "priority": 10          // optional, default 0
    }
    """
    try:
        module_id = request.match_info["module_id"]
        data = await request.json()
        manager = _get_profile_manager()

        profile_id_str = data.get("profile_id")
        if not profile_id_str:
            return web.json_response({"success": False, "error": "profile_id is required"}, status=400)

        profile_id = _parse_uuid(profile_id_str, "profile_id")

        assoc = await manager.assign_to_module(
            profile_id=profile_id,
            module_id=module_id,
            context=data.get("context"),
            priority=data.get("priority", 0),
        )

        return web.json_response({
            "success": True,
            "association": {
                "id": str(assoc.id),
                "module_id": assoc.module_id,
                "profile_id": str(assoc.profile_id),
                "context": assoc.context,
                "priority": assoc.priority,
            },
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error assigning profile to module")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_remove_module_profile(request: web.Request) -> web.Response:
    """
    DELETE /api/tts/modules/{module_id}/profiles/{profile_id}

    Remove a profile assignment from a module.
    """
    try:
        module_id = request.match_info["module_id"]
        profile_id = _parse_uuid(request.match_info["profile_id"], "profile_id")
        manager = _get_profile_manager()

        removed = await manager.remove_from_module(profile_id, module_id)

        if not removed:
            return web.json_response({"success": False, "error": "Assignment not found"}, status=404)

        return web.json_response({
            "success": True,
            "removed": True,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error removing profile from module")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_best_module_profile(request: web.Request) -> web.Response:
    """
    GET /api/tts/modules/{module_id}/best-profile

    Get the best profile for a module context.

    Query parameters:
    - context: Optional context (questions, explanations, etc.)
    """
    try:
        module_id = request.match_info["module_id"]
        context = request.query.get("context")
        manager = _get_profile_manager()

        profile = await manager.get_best_profile_for_module(module_id, context)

        if not profile:
            return web.json_response({
                "success": True,
                "profile": None,
                "message": "No profile found for this module",
            })

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except Exception as e:
        logger.exception("Error getting best profile")
        return web.json_response({"success": False, "error": str(e)}, status=500)


# =============================================================================
# Profile from Variant Routes
# =============================================================================


async def handle_create_profile_from_variant(request: web.Request) -> web.Response:
    """
    POST /api/tts/profiles/from-variant/{variant_id}

    Create a profile from a comparison session variant.

    Body:
    {
        "name": "Winning Voice",
        "description": "Optional description",
        "tags": ["comparison-winner"],
        "use_case": "questions"
    }
    """
    try:
        variant_id = _parse_uuid(request.match_info["variant_id"], "variant_id")
        data = await request.json()
        manager = _get_profile_manager()

        name = data.get("name")
        if not name:
            return web.json_response({"success": False, "error": "name is required"}, status=400)

        profile = await manager.create_from_variant(
            variant_id=variant_id,
            name=name,
            description=data.get("description"),
            tags=data.get("tags"),
            use_case=data.get("use_case"),
        )

        return web.json_response({
            "success": True,
            "profile": profile.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error creating profile from variant")
        return web.json_response({"success": False, "error": str(e)}, status=500)


# =============================================================================
# Comparison Session Routes
# =============================================================================


async def handle_create_session(request: web.Request) -> web.Response:
    """Create a new comparison session."""
    try:
        manager = _get_comparison_manager()
        data = await request.json()

        name = data.get("name")
        if not name:
            return web.json_response(
                {"success": False, "error": "name is required"}, status=400
            )

        samples = data.get("samples", [])
        configurations = data.get("configurations", [])

        session = await manager.create_session(
            name=name,
            samples=samples,
            configurations=configurations,
            description=data.get("description"),
        )

        return web.json_response({
            "success": True,
            "session": session.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error creating comparison session")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_list_sessions(request: web.Request) -> web.Response:
    """List comparison sessions."""
    try:
        manager = _get_comparison_manager()

        # Parse query parameters
        status_str = request.query.get("status")
        status = SessionStatus(status_str) if status_str else None
        limit = int(request.query.get("limit", "50"))
        offset = int(request.query.get("offset", "0"))

        sessions, total = await manager.list_sessions(
            status=status,
            limit=limit,
            offset=offset,
        )

        return web.json_response({
            "success": True,
            "sessions": [s.to_dict() for s in sessions],
            "total": total,
            "limit": limit,
            "offset": offset,
        })

    except Exception as e:
        logger.exception("Error listing comparison sessions")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_session(request: web.Request) -> web.Response:
    """Get a comparison session with its variants and ratings."""
    try:
        manager = _get_comparison_manager()
        session_id = _parse_uuid(request.match_info["session_id"], "session_id")

        session, variants, ratings = await manager.get_session_with_variants(session_id)

        if not session:
            return web.json_response(
                {"success": False, "error": "Session not found"}, status=404
            )

        # Convert ratings dict to be JSON-serializable
        ratings_dict = {
            str(k): v.to_dict() for k, v in ratings.items()
        }

        return web.json_response({
            "success": True,
            "session": session.to_dict(),
            "variants": [v.to_dict() for v in variants],
            "ratings": ratings_dict,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error getting comparison session")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_delete_session(request: web.Request) -> web.Response:
    """Delete a comparison session."""
    try:
        manager = _get_comparison_manager()
        session_id = _parse_uuid(request.match_info["session_id"], "session_id")

        deleted = await manager.delete_session(session_id)

        if not deleted:
            return web.json_response(
                {"success": False, "error": "Session not found"}, status=404
            )

        return web.json_response({"success": True})

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error deleting comparison session")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_generate_session_variants(request: web.Request) -> web.Response:
    """Generate audio for all variants in a session."""
    try:
        manager = _get_comparison_manager()
        session_id = _parse_uuid(request.match_info["session_id"], "session_id")

        data = await request.json() if request.body_exists else {}
        regenerate = data.get("regenerate", False)

        session = await manager.generate_variants(session_id, regenerate=regenerate)

        return web.json_response({
            "success": True,
            "session": session.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error generating session variants")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_session_summary(request: web.Request) -> web.Response:
    """Get session summary with configuration rankings."""
    try:
        manager = _get_comparison_manager()
        session_id = _parse_uuid(request.match_info["session_id"], "session_id")

        summary = await manager.get_session_summary(session_id)

        if not summary:
            return web.json_response(
                {"success": False, "error": "Session not found"}, status=404
            )

        return web.json_response({
            "success": True,
            "summary": summary,
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error getting session summary")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_rate_variant(request: web.Request) -> web.Response:
    """Rate a comparison variant."""
    try:
        manager = _get_comparison_manager()
        variant_id = _parse_uuid(request.match_info["variant_id"], "variant_id")
        data = await request.json()

        rating_value = data.get("rating")
        if rating_value is None:
            return web.json_response(
                {"success": False, "error": "rating is required"}, status=400
            )

        rating = await manager.rate_variant(
            variant_id=variant_id,
            rating=int(rating_value),
            notes=data.get("notes"),
        )

        return web.json_response({
            "success": True,
            "rating": rating.to_dict(),
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error rating variant")
        return web.json_response({"success": False, "error": str(e)}, status=500)


async def handle_get_variant_audio(request: web.Request) -> web.Response:
    """Stream audio for a comparison variant."""
    try:
        manager = _get_comparison_manager()
        variant_id = _parse_uuid(request.match_info["variant_id"], "variant_id")

        audio_path = await manager.get_audio_file_path(variant_id)

        if not audio_path:
            return web.json_response(
                {"success": False, "error": "Audio not found"}, status=404
            )

        # Stream the file
        return web.FileResponse(audio_path, headers={
            "Content-Type": "audio/wav",
            "Cache-Control": "max-age=3600",
        })

    except ValueError as e:
        return web.json_response({"success": False, "error": str(e)}, status=400)
    except Exception as e:
        logger.exception("Error streaming variant audio")
        return web.json_response({"success": False, "error": str(e)}, status=500)


# =============================================================================
# Initialization and Route Registration
# =============================================================================


def init_tts_pregen_system(app: web.Application):
    """Initialize the TTS pre-generation system.

    Args:
        app: aiohttp application with db_pool and optional tts_resource_pool
    """
    global _profile_manager, _comparison_manager, _app
    _app = app

    # Ensure output directory exists
    PREGEN_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Get the database pool
    db_pool = app.get("db_pool")
    if not db_pool:
        logger.warning("Database pool not available, TTS pre-generation will not work")
        return

    # Get optional TTS resource pool for sample generation
    tts_pool = app.get("tts_resource_pool")

    # Create repository
    repo = TTSPregenRepository(db_pool)

    # Initialize profile manager
    _profile_manager = TTSProfileManager(db_pool, tts_pool)

    # Initialize comparison manager
    _comparison_manager = TTSComparisonManager(
        repo=repo,
        tts_pool=tts_pool,
        storage_dir=str(PREGEN_OUTPUT_DIR / "comparisons"),
    )

    logger.info("TTS pre-generation system initialized")


def register_tts_pregen_routes(app: web.Application):
    """Register all TTS pre-generation routes on the application."""
    # Initialize the system
    init_tts_pregen_system(app)

    # Profile CRUD routes
    app.router.add_post("/api/tts/profiles", handle_create_profile)
    app.router.add_get("/api/tts/profiles", handle_list_profiles)
    app.router.add_get("/api/tts/profiles/{profile_id}", handle_get_profile)
    app.router.add_put("/api/tts/profiles/{profile_id}", handle_update_profile)
    app.router.add_delete("/api/tts/profiles/{profile_id}", handle_delete_profile)

    # Profile actions
    app.router.add_post("/api/tts/profiles/{profile_id}/set-default", handle_set_default_profile)
    app.router.add_post("/api/tts/profiles/{profile_id}/preview", handle_preview_profile)
    app.router.add_get("/api/tts/profiles/{profile_id}/audio", handle_get_profile_audio)
    app.router.add_post("/api/tts/profiles/{profile_id}/duplicate", handle_duplicate_profile)
    app.router.add_get("/api/tts/profiles/{profile_id}/export", handle_export_profile)

    # Profile import
    app.router.add_post("/api/tts/profiles/import", handle_import_profile)

    # Profile from variant
    app.router.add_post("/api/tts/profiles/from-variant/{variant_id}", handle_create_profile_from_variant)

    # Module profile associations
    app.router.add_get("/api/tts/modules/{module_id}/profiles", handle_get_module_profiles)
    app.router.add_post("/api/tts/modules/{module_id}/profiles", handle_assign_module_profile)
    app.router.add_delete("/api/tts/modules/{module_id}/profiles/{profile_id}", handle_remove_module_profile)
    app.router.add_get("/api/tts/modules/{module_id}/best-profile", handle_get_best_module_profile)

    # Comparison session routes
    app.router.add_post("/api/tts/pregen/sessions", handle_create_session)
    app.router.add_get("/api/tts/pregen/sessions", handle_list_sessions)
    app.router.add_get("/api/tts/pregen/sessions/{session_id}", handle_get_session)
    app.router.add_delete("/api/tts/pregen/sessions/{session_id}", handle_delete_session)
    app.router.add_post("/api/tts/pregen/sessions/{session_id}/generate", handle_generate_session_variants)
    app.router.add_get("/api/tts/pregen/sessions/{session_id}/summary", handle_get_session_summary)
    app.router.add_post("/api/tts/pregen/variants/{variant_id}/rate", handle_rate_variant)
    app.router.add_get("/api/tts/pregen/variants/{variant_id}/audio", handle_get_variant_audio)

    logger.info("TTS pre-generation API routes registered")
