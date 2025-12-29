"""
UMCF Curriculum Database Module
Provides PostgreSQL storage for curricula with normalized tables and JSON export.

This module supports both file-based storage (for development/simple deployments)
and PostgreSQL (for production/enterprise deployments).
"""

import json
import os
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import logging

logger = logging.getLogger(__name__)

# Try to import asyncpg for PostgreSQL support
try:
    import asyncpg
    HAS_ASYNCPG = True
except ImportError:
    HAS_ASYNCPG = False
    logger.info("asyncpg not installed - PostgreSQL features disabled")


@dataclass
class CurriculumSummary:
    """Summary of a curriculum for listing."""
    id: str
    title: str
    description: str
    version: str
    topic_count: int
    total_duration: str
    difficulty: str
    age_range: str
    keywords: List[str] = field(default_factory=list)
    status: str = "draft"
    updated_at: Optional[datetime] = None


@dataclass
class TopicSummary:
    """Summary of a topic within a curriculum."""
    id: str
    title: str
    description: str
    order_index: int
    duration: str = ""
    has_transcript: bool = False
    segment_count: int = 0
    assessment_count: int = 0


class CurriculumStorage:
    """
    Abstract base class for curriculum storage.
    Implementations can use files, PostgreSQL, or other backends.
    """

    async def list_curricula(
        self,
        search: Optional[str] = None,
        difficulty: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> Tuple[List[CurriculumSummary], int]:
        """List curricula with optional filtering."""
        raise NotImplementedError

    async def get_curriculum_detail(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed curriculum info including topics."""
        raise NotImplementedError

    async def get_curriculum_full(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get full UMCF JSON document."""
        raise NotImplementedError

    async def get_topic_transcript(
        self,
        curriculum_id: str,
        topic_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get transcript segments for a specific topic."""
        raise NotImplementedError

    async def save_curriculum(
        self,
        curriculum_id: str,
        data: Dict[str, Any]
    ) -> str:
        """Save or update a curriculum. Returns the curriculum ID."""
        raise NotImplementedError

    async def delete_curriculum(self, curriculum_id: str) -> bool:
        """Delete a curriculum. Returns True if deleted."""
        raise NotImplementedError

    async def reload(self) -> int:
        """Reload curricula from source. Returns count of curricula loaded."""
        raise NotImplementedError


class FileBasedStorage(CurriculumStorage):
    """
    File-based curriculum storage using UMCF JSON files.
    Suitable for development and simple deployments.
    """

    def __init__(self, curriculum_dir: Path):
        self.curriculum_dir = curriculum_dir
        self.curricula: Dict[str, CurriculumSummary] = {}
        self.curriculum_raw: Dict[str, Dict[str, Any]] = {}

    async def reload(self) -> int:
        """Load all UMCF files from the curriculum directory."""
        self.curricula.clear()
        self.curriculum_raw.clear()

        if not self.curriculum_dir.exists():
            logger.warning(f"Curriculum directory not found: {self.curriculum_dir}")
            return 0

        for umcf_file in self.curriculum_dir.glob("*.umcf"):
            try:
                self._load_file(umcf_file)
            except Exception as e:
                logger.error(f"Failed to load curriculum {umcf_file}: {e}")

        logger.info(f"Loaded {len(self.curricula)} curricula from files")
        return len(self.curricula)

    def _load_file(self, file_path: Path):
        """Load a single UMCF file."""
        with open(file_path, 'r', encoding='utf-8') as f:
            umcf = json.load(f)

        umcf_id = umcf.get("id", {}).get("value", file_path.stem)
        educational = umcf.get("educational", {})
        version_info = umcf.get("version", {})
        lifecycle = umcf.get("lifecycle", {})

        # Count topics
        content = umcf.get("content", [])
        topic_count = 0
        if content and isinstance(content, list):
            root = content[0]
            children = root.get("children", [])
            topic_count = len(children)

        summary = CurriculumSummary(
            id=umcf_id,
            title=umcf.get("title", "Untitled"),
            description=umcf.get("description", ""),
            version=version_info.get("number", "1.0.0"),
            topic_count=topic_count,
            total_duration=educational.get("typicalLearningTime", "PT4H"),
            difficulty=educational.get("difficulty", "medium"),
            age_range=educational.get("typicalAgeRange", "18+"),
            keywords=umcf.get("metadata", {}).get("keywords", []),
            status=lifecycle.get("status", "draft"),
        )

        self.curricula[umcf_id] = summary
        self.curriculum_raw[umcf_id] = umcf

    async def list_curricula(
        self,
        search: Optional[str] = None,
        difficulty: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> Tuple[List[CurriculumSummary], int]:
        """List curricula with optional filtering."""
        curricula = list(self.curricula.values())

        # Apply filters
        if search:
            search_lower = search.lower()
            curricula = [
                c for c in curricula
                if search_lower in c.title.lower()
                or search_lower in c.description.lower()
                or any(search_lower in kw.lower() for kw in c.keywords)
            ]

        if difficulty:
            curricula = [c for c in curricula if c.difficulty == difficulty]

        total = len(curricula)
        curricula = curricula[offset:offset + limit]

        return curricula, total

    async def get_curriculum_detail(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed curriculum info including topics."""
        if curriculum_id not in self.curriculum_raw:
            return None

        umcf = self.curriculum_raw[curriculum_id]
        summary = self.curricula[curriculum_id]

        # Extract topics
        content = umcf.get("content", [])
        topics = []
        if content and isinstance(content, list):
            root = content[0]
            children = root.get("children", [])
            for idx, child in enumerate(children):
                time_estimates = child.get("timeEstimates", {})
                duration = time_estimates.get("intermediate", time_estimates.get("introductory", "PT30M"))
                transcript = child.get("transcript", {})
                segments = transcript.get("segments", [])
                assessments = child.get("assessments", [])

                topics.append(TopicSummary(
                    id=child.get("id", {}).get("value", f"topic-{idx}"),
                    title=child.get("title", "Untitled"),
                    description=child.get("description", ""),
                    order_index=child.get("orderIndex", idx),
                    duration=duration,
                    has_transcript=len(segments) > 0,
                    segment_count=len(segments),
                    assessment_count=len(assessments)
                ))

        # Extract glossary and learning objectives
        glossary = umcf.get("glossary", {}).get("terms", [])
        learning_objectives = []
        if content and isinstance(content, list):
            root = content[0]
            learning_objectives = root.get("learningObjectives", [])

        return {
            "id": curriculum_id,
            "title": summary.title,
            "description": summary.description,
            "version": summary.version,
            "difficulty": summary.difficulty,
            "age_range": summary.age_range,
            "duration": summary.total_duration,
            "keywords": summary.keywords,
            "topics": [asdict(t) for t in topics],
            "glossary_terms": glossary,
            "learning_objectives": learning_objectives,
        }

    async def get_curriculum_full(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get full UMCF JSON document."""
        return self.curriculum_raw.get(curriculum_id)

    async def get_topic_transcript(
        self,
        curriculum_id: str,
        topic_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get transcript segments for a specific topic."""
        if curriculum_id not in self.curriculum_raw:
            return None

        umcf = self.curriculum_raw[curriculum_id]
        content = umcf.get("content", [])

        if not content:
            return None

        root = content[0]
        children = root.get("children", [])

        for child in children:
            child_id = child.get("id", {}).get("value", "")
            if child_id == topic_id:
                transcript = child.get("transcript", {})
                return {
                    "topic_id": topic_id,
                    "topic_title": child.get("title", ""),
                    "segments": transcript.get("segments", []),
                    "misconceptions": child.get("misconceptions", []),
                    "examples": child.get("examples", []),
                    "assessments": child.get("assessments", [])
                }

        return None

    async def save_curriculum(
        self,
        curriculum_id: str,
        data: Dict[str, Any]
    ) -> str:
        """Save or update a curriculum."""
        # Determine file path
        if curriculum_id in self.curricula:
            # Find existing file
            for umcf_file in self.curriculum_dir.glob("*.umcf"):
                with open(umcf_file, 'r', encoding='utf-8') as f:
                    existing = json.load(f)
                if existing.get("id", {}).get("value") == curriculum_id:
                    file_path = umcf_file
                    break
            else:
                safe_name = "".join(c if c.isalnum() or c in "-_" else "-" for c in data["title"].lower())
                file_path = self.curriculum_dir / f"{safe_name}.umcf"
        else:
            safe_name = "".join(c if c.isalnum() or c in "-_" else "-" for c in data["title"].lower())
            file_path = self.curriculum_dir / f"{safe_name}.umcf"

        # Write the file
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)

        # Reload this file
        self._load_file(file_path)

        return data.get("id", {}).get("value", file_path.stem)

    async def delete_curriculum(self, curriculum_id: str) -> bool:
        """Delete a curriculum."""
        if curriculum_id not in self.curricula:
            return False

        # Find and delete file
        for umcf_file in self.curriculum_dir.glob("*.umcf"):
            with open(umcf_file, 'r', encoding='utf-8') as f:
                existing = json.load(f)
            if existing.get("id", {}).get("value") == curriculum_id:
                umcf_file.unlink()
                del self.curricula[curriculum_id]
                del self.curriculum_raw[curriculum_id]
                return True

        return False


class PostgreSQLStorage(CurriculumStorage):
    """
    PostgreSQL-based curriculum storage with normalized tables.
    Provides granular editing and fast JSON export.
    """

    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.pool: Optional[asyncpg.Pool] = None

    async def connect(self):
        """Initialize the connection pool."""
        if not HAS_ASYNCPG:
            raise RuntimeError("asyncpg is required for PostgreSQL storage")

        self.pool = await asyncpg.create_pool(
            self.connection_string,
            min_size=2,
            max_size=10
        )
        logger.info("Connected to PostgreSQL")

    async def close(self):
        """Close the connection pool."""
        if self.pool:
            await self.pool.close()

    async def reload(self) -> int:
        """Refresh any caches. For PostgreSQL, this rebuilds JSON caches."""
        async with self.pool.acquire() as conn:
            # Rebuild all JSON caches
            await conn.execute("""
                UPDATE curricula
                SET json_cache = build_umcf_json(id),
                    json_cache_updated_at = NOW()
            """)

            count = await conn.fetchval("SELECT COUNT(*) FROM curricula")
            return count

    async def list_curricula(
        self,
        search: Optional[str] = None,
        difficulty: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> Tuple[List[CurriculumSummary], int]:
        """List curricula with optional filtering."""
        async with self.pool.acquire() as conn:
            # Build query
            conditions = []
            params = []
            param_idx = 1

            if search:
                conditions.append(f"search_vector @@ plainto_tsquery('english', ${param_idx})")
                params.append(search)
                param_idx += 1

            if difficulty:
                conditions.append(f"difficulty = ${param_idx}")
                params.append(difficulty)
                param_idx += 1

            where_clause = " AND ".join(conditions) if conditions else "TRUE"

            # Get total count
            count_query = f"SELECT COUNT(*) FROM curriculum_summaries WHERE {where_clause}"
            total = await conn.fetchval(count_query, *params)

            # Get curricula
            query = f"""
                SELECT id, external_id, title, description, version_number,
                       difficulty, age_range, typical_learning_time, keywords,
                       lifecycle_status, topic_count, updated_at
                FROM curriculum_summaries
                WHERE {where_clause}
                ORDER BY updated_at DESC
                LIMIT ${param_idx} OFFSET ${param_idx + 1}
            """
            params.extend([limit, offset])

            rows = await conn.fetch(query, *params)

            curricula = [
                CurriculumSummary(
                    id=row['external_id'] or str(row['id']),
                    title=row['title'],
                    description=row['description'] or "",
                    version=row['version_number'] or "1.0.0",
                    topic_count=row['topic_count'] or 0,
                    total_duration=row['typical_learning_time'] or "PT4H",
                    difficulty=row['difficulty'] or "medium",
                    age_range=row['age_range'] or "18+",
                    keywords=row['keywords'] or [],
                    status=row['lifecycle_status'] or "draft",
                    updated_at=row['updated_at']
                )
                for row in rows
            ]

            return curricula, total

    async def get_curriculum_detail(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed curriculum info including topics."""
        async with self.pool.acquire() as conn:
            # Get curriculum
            curriculum = await conn.fetchrow("""
                SELECT * FROM curriculum_summaries
                WHERE external_id = $1 OR id::text = $1
            """, curriculum_id)

            if not curriculum:
                return None

            # Get topics
            topics = await conn.fetch("""
                SELECT * FROM topic_details
                WHERE curriculum_id = $1
                ORDER BY order_index
            """, curriculum['id'])

            # Get glossary
            glossary = await conn.fetch("""
                SELECT term, pronunciation, definition, spoken_definition
                FROM glossary_terms
                WHERE curriculum_id = $1
            """, curriculum['id'])

            # Get learning objectives from root topic
            objectives = await conn.fetch("""
                SELECT statement, blooms_level
                FROM learning_objectives lo
                JOIN topics t ON lo.topic_id = t.id
                WHERE t.curriculum_id = $1 AND t.parent_id IS NULL
                ORDER BY lo.order_index
            """, curriculum['id'])

            return {
                "id": curriculum['external_id'] or str(curriculum['id']),
                "title": curriculum['title'],
                "description": curriculum['description'] or "",
                "version": curriculum['version_number'] or "1.0.0",
                "difficulty": curriculum['difficulty'] or "medium",
                "age_range": curriculum['age_range'] or "18+",
                "duration": curriculum['typical_learning_time'] or "PT4H",
                "keywords": curriculum['keywords'] or [],
                "topics": [
                    {
                        "id": t['external_id'] or str(t['id']),
                        "title": t['title'],
                        "description": t['description'] or "",
                        "order_index": t['order_index'],
                        "has_transcript": t['has_transcript'],
                        "segment_count": t['segment_count'],
                        "assessment_count": t['assessment_count']
                    }
                    for t in topics
                ],
                "glossary_terms": [dict(g) for g in glossary],
                "learning_objectives": [dict(o) for o in objectives],
            }

    async def get_curriculum_full(self, curriculum_id: str) -> Optional[Dict[str, Any]]:
        """Get full UMCF JSON document from cache or rebuild."""
        async with self.pool.acquire() as conn:
            # Try to get from cache first
            row = await conn.fetchrow("""
                SELECT json_cache, json_cache_updated_at, updated_at
                FROM curricula
                WHERE external_id = $1 OR id::text = $1
            """, curriculum_id)

            if not row:
                return None

            # Check if cache is stale
            if row['json_cache'] and row['json_cache_updated_at'] >= row['updated_at']:
                return json.loads(row['json_cache'])

            # Rebuild cache
            curriculum_uuid = await conn.fetchval("""
                SELECT id FROM curricula
                WHERE external_id = $1 OR id::text = $1
            """, curriculum_id)

            json_data = await conn.fetchval(
                "SELECT build_umcf_json($1)",
                curriculum_uuid
            )

            if json_data:
                # Update cache
                await conn.execute("""
                    UPDATE curricula
                    SET json_cache = $1, json_cache_updated_at = NOW()
                    WHERE id = $2
                """, json_data, curriculum_uuid)

                return json.loads(json_data)

            return None

    async def get_topic_transcript(
        self,
        curriculum_id: str,
        topic_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get transcript segments for a specific topic."""
        async with self.pool.acquire() as conn:
            # Get topic
            topic = await conn.fetchrow("""
                SELECT t.id, t.title
                FROM topics t
                JOIN curricula c ON t.curriculum_id = c.id
                WHERE (c.external_id = $1 OR c.id::text = $1)
                  AND (t.external_id = $2 OR t.id::text = $2)
            """, curriculum_id, topic_id)

            if not topic:
                return None

            # Get segments
            segments = await conn.fetch("""
                SELECT segment_id, segment_type, content,
                       pace, emotional_tone, pause_after,
                       checkpoint_type, checkpoint_question,
                       expected_keywords, celebration_message
                FROM transcript_segments
                WHERE topic_id = $1
                ORDER BY order_index
            """, topic['id'])

            # Get misconceptions
            misconceptions = await conn.fetch("""
                SELECT triggers, misconception, correction, explanation
                FROM misconceptions
                WHERE topic_id = $1
                ORDER BY order_index
            """, topic['id'])

            # Get examples
            examples = await conn.fetch("""
                SELECT example_type, title, content, explanation
                FROM examples
                WHERE topic_id = $1
                ORDER BY order_index
            """, topic['id'])

            # Get assessments
            assessments = await conn.fetch("""
                SELECT a.*, array_agg(
                    jsonb_build_object(
                        'id', ao.option_id,
                        'text', ao.option_text,
                        'isCorrect', ao.is_correct
                    ) ORDER BY ao.order_index
                ) as options
                FROM assessments a
                LEFT JOIN assessment_options ao ON a.id = ao.assessment_id
                WHERE a.topic_id = $1
                GROUP BY a.id
                ORDER BY a.order_index
            """, topic['id'])

            return {
                "topic_id": topic_id,
                "topic_title": topic['title'],
                "segments": [
                    {
                        "id": s['segment_id'],
                        "type": s['segment_type'],
                        "content": s['content'],
                        "speaking_notes": {
                            "pace": s['pace'],
                            "emotional_tone": s['emotional_tone'],
                            "pause_after": s['pause_after']
                        } if s['pace'] else None,
                        "checkpoint": {
                            "type": s['checkpoint_type'],
                            "question": s['checkpoint_question'],
                            "expected_keywords": s['expected_keywords'],
                            "celebration_message": s['celebration_message']
                        } if s['checkpoint_type'] else None
                    }
                    for s in segments
                ],
                "misconceptions": [dict(m) for m in misconceptions],
                "examples": [dict(e) for e in examples],
                "assessments": [dict(a) for a in assessments]
            }

    async def save_curriculum(
        self,
        curriculum_id: str,
        data: Dict[str, Any]
    ) -> str:
        """Save or update a curriculum from UMCF JSON."""
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                # Check if curriculum exists
                existing_id = await conn.fetchval("""
                    SELECT id FROM curricula
                    WHERE external_id = $1 OR id::text = $1
                """, curriculum_id)

                if existing_id:
                    # Delete existing (cascade will handle related tables)
                    await conn.execute("DELETE FROM curricula WHERE id = $1", existing_id)

                # Insert new curriculum
                umcf_id = data.get("id", {}).get("value", str(uuid.uuid4()))
                educational = data.get("educational", {})
                version_info = data.get("version", {})
                lifecycle = data.get("lifecycle", {})
                metadata = data.get("metadata", {})

                curriculum_uuid = await conn.fetchval("""
                    INSERT INTO curricula (
                        external_id, catalog, title, description,
                        version_number, version_date, version_changelog,
                        lifecycle_status, difficulty, age_range,
                        typical_learning_time, language, keywords, subjects
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
                    RETURNING id
                """,
                    umcf_id,
                    data.get("id", {}).get("catalog"),
                    data.get("title"),
                    data.get("description"),
                    version_info.get("number", "1.0.0"),
                    version_info.get("date"),
                    version_info.get("changelog"),
                    lifecycle.get("status", "draft"),
                    educational.get("difficulty"),
                    educational.get("typicalAgeRange"),
                    educational.get("typicalLearningTime"),
                    metadata.get("language", "en-US"),
                    metadata.get("keywords", []),
                    metadata.get("subject", [])
                )

                # Insert contributors
                for contributor in lifecycle.get("contributors", []):
                    await conn.execute("""
                        INSERT INTO curriculum_contributors (curriculum_id, name, role, organization)
                        VALUES ($1, $2, $3, $4)
                    """, curriculum_uuid, contributor.get("name"), contributor.get("role"),
                        contributor.get("organization"))

                # Insert glossary terms
                glossary = data.get("glossary", {}).get("terms", [])
                for term in glossary:
                    await conn.execute("""
                        INSERT INTO glossary_terms (
                            curriculum_id, term_id, term, pronunciation,
                            definition, spoken_definition, simple_definition,
                            examples, related_terms
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                    """,
                        curriculum_uuid, term.get("id"), term.get("term"),
                        term.get("pronunciation"), term.get("definition"),
                        term.get("spokenDefinition"), term.get("simpleDefinition"),
                        term.get("examples", []), term.get("relatedTerms", []))

                # Insert content hierarchy
                content = data.get("content", [])
                for node in content:
                    await self._insert_content_node(conn, curriculum_uuid, None, node, 0)

                # Rebuild JSON cache
                await conn.execute("""
                    UPDATE curricula
                    SET json_cache = build_umcf_json(id),
                        json_cache_updated_at = NOW()
                    WHERE id = $1
                """, curriculum_uuid)

                return umcf_id

    async def _insert_content_node(
        self,
        conn,
        curriculum_id: uuid.UUID,
        parent_id: Optional[uuid.UUID],
        node: Dict[str, Any],
        order_index: int
    ) -> uuid.UUID:
        """Recursively insert a content node and its children."""
        time_estimates = node.get("timeEstimates", {})
        tutoring_config = node.get("tutoringConfig", {})

        # Insert topic
        topic_id = await conn.fetchval("""
            INSERT INTO topics (
                curriculum_id, parent_id, external_id, title, description,
                content_type, order_index,
                time_overview, time_introductory, time_intermediate,
                time_advanced, time_graduate, time_research,
                content_depth, interaction_mode, checkpoint_frequency
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            RETURNING id
        """,
            curriculum_id, parent_id,
            node.get("id", {}).get("value"),
            node.get("title"),
            node.get("description"),
            node.get("type", "topic"),
            order_index,
            time_estimates.get("overview"),
            time_estimates.get("introductory"),
            time_estimates.get("intermediate"),
            time_estimates.get("advanced"),
            time_estimates.get("graduate"),
            time_estimates.get("research"),
            tutoring_config.get("contentDepth"),
            tutoring_config.get("interactionMode"),
            tutoring_config.get("checkpointFrequency")
        )

        # Insert learning objectives
        for idx, obj in enumerate(node.get("learningObjectives", [])):
            await conn.execute("""
                INSERT INTO learning_objectives (
                    topic_id, external_id, statement, abbreviated_statement,
                    blooms_level, order_index
                ) VALUES ($1, $2, $3, $4, $5, $6)
            """,
                topic_id, obj.get("id", {}).get("value"),
                obj.get("statement"), obj.get("abbreviatedStatement"),
                obj.get("bloomsLevel"), idx)

        # Insert transcript segments
        transcript = node.get("transcript", {})
        for idx, segment in enumerate(transcript.get("segments", [])):
            speaking_notes = segment.get("speakingNotes", {})
            checkpoint = segment.get("checkpoint", {})
            stopping_point = segment.get("stoppingPoint", {})
            expected_response = checkpoint.get("expectedResponse", {})

            segment_uuid = await conn.fetchval("""
                INSERT INTO transcript_segments (
                    topic_id, segment_id, segment_type, content, order_index,
                    pace, emotional_tone, pause_after, emphasis_words, pronunciations,
                    checkpoint_type, checkpoint_question, expected_response_type,
                    expected_keywords, expected_patterns, celebration_message,
                    stopping_point_type, prompt_for_continue, suggested_prompt,
                    glossary_refs
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                RETURNING id
            """,
                topic_id, segment.get("id"), segment.get("type"),
                segment.get("content"), idx,
                speaking_notes.get("pace"), speaking_notes.get("emotionalTone"),
                speaking_notes.get("pauseAfter"), speaking_notes.get("emphasis", []),
                json.dumps(speaking_notes.get("pronunciation", {})) if speaking_notes.get("pronunciation") else None,
                checkpoint.get("type"), checkpoint.get("question"),
                expected_response.get("type"), expected_response.get("keywords", []),
                expected_response.get("acceptablePatterns", []),
                checkpoint.get("celebrationMessage"),
                stopping_point.get("type"), stopping_point.get("promptForContinue"),
                stopping_point.get("suggestedPrompt"),
                segment.get("glossaryRefs", []))

            # Insert alternative explanations
            for alt_idx, alt in enumerate(segment.get("alternativeExplanations", [])):
                await conn.execute("""
                    INSERT INTO alternative_explanations (segment_id, style, content, order_index)
                    VALUES ($1, $2, $3, $4)
                """, segment_uuid, alt.get("style"), alt.get("content"), alt_idx)

        # Insert examples
        for idx, example in enumerate(node.get("examples", [])):
            await conn.execute("""
                INSERT INTO examples (
                    topic_id, external_id, example_type, title, content, explanation, order_index
                ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            """,
                topic_id, example.get("id", {}).get("value"),
                example.get("type"), example.get("title"),
                example.get("content"), example.get("explanation"), idx)

        # Insert misconceptions
        for idx, misc in enumerate(node.get("misconceptions", [])):
            await conn.execute("""
                INSERT INTO misconceptions (
                    topic_id, external_id, triggers, misconception, correction, explanation, order_index
                ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            """,
                topic_id, misc.get("id", {}).get("value"),
                misc.get("trigger", []), misc.get("misconception"),
                misc.get("correction"), misc.get("explanation"), idx)

        # Insert assessments
        for idx, assessment in enumerate(node.get("assessments", [])):
            feedback = assessment.get("feedback", {})
            assessment_uuid = await conn.fetchval("""
                INSERT INTO assessments (
                    topic_id, external_id, assessment_type, question,
                    correct_answer, hint, feedback_correct, feedback_incorrect,
                    feedback_partial, order_index
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                RETURNING id
            """,
                topic_id, assessment.get("id", {}).get("value"),
                assessment.get("type"), assessment.get("question"),
                assessment.get("correctAnswer"), assessment.get("hint"),
                feedback.get("correct"), feedback.get("incorrect"),
                feedback.get("partial"), idx)

            # Insert options
            for opt_idx, option in enumerate(assessment.get("options", [])):
                await conn.execute("""
                    INSERT INTO assessment_options (
                        assessment_id, option_id, option_text, is_correct, order_index
                    ) VALUES ($1, $2, $3, $4, $5)
                """,
                    assessment_uuid, option.get("id"),
                    option.get("text"), option.get("isCorrect", False), opt_idx)

        # Process children recursively
        for idx, child in enumerate(node.get("children", [])):
            await self._insert_content_node(conn, curriculum_id, topic_id, child, idx)

        return topic_id

    async def delete_curriculum(self, curriculum_id: str) -> bool:
        """Delete a curriculum."""
        async with self.pool.acquire() as conn:
            result = await conn.execute("""
                DELETE FROM curricula
                WHERE external_id = $1 OR id::text = $1
            """, curriculum_id)
            return "DELETE 1" in result


def create_storage(
    storage_type: str = "file",
    curriculum_dir: Optional[Path] = None,
    connection_string: Optional[str] = None
) -> CurriculumStorage:
    """
    Factory function to create the appropriate storage backend.

    Args:
        storage_type: "file" or "postgresql"
        curriculum_dir: Directory for file-based storage
        connection_string: PostgreSQL connection string for DB storage

    Returns:
        CurriculumStorage instance
    """
    if storage_type == "postgresql":
        if not connection_string:
            connection_string = os.environ.get(
                "UMCF_DATABASE_URL",
                "postgresql://localhost/unamentis"
            )
        return PostgreSQLStorage(connection_string)
    else:
        if not curriculum_dir:
            curriculum_dir = Path(__file__).parent.parent.parent / "curriculum" / "examples" / "realistic"
        return FileBasedStorage(curriculum_dir)
