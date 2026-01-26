"""
KB Questions Repository - PostgreSQL database access for Knowledge Bowl questions.

Provides async database operations for:
- Questions (CRUD, filtering, search)
- Packs (CRUD, question associations)
- Domains (reference data)
- Statistics and aggregations
"""

import logging
from datetime import datetime, timezone
from typing import Any, Optional

import asyncpg

logger = logging.getLogger(__name__)


class KBQuestionsRepository:
    """Repository for Knowledge Bowl questions database operations.

    Uses asyncpg connection pool for PostgreSQL access.
    """

    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    # =========================================================================
    # DOMAIN OPERATIONS
    # =========================================================================

    async def list_domains(self) -> list[dict]:
        """List all domains."""
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM kb_domains ORDER BY weight DESC, name ASC"
            )
            domains = [dict(row) for row in rows]
            # Serialize datetime fields
            for d in domains:
                if d.get("created_at"):
                    d["created_at"] = d["created_at"].isoformat()
                if d.get("updated_at"):
                    d["updated_at"] = d["updated_at"].isoformat()
            return domains

    async def get_domain(self, domain_id: str) -> Optional[dict]:
        """Get a domain by ID."""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM kb_domains WHERE id = $1", domain_id
            )
            if row:
                d = dict(row)
                if d.get("created_at"):
                    d["created_at"] = d["created_at"].isoformat()
                if d.get("updated_at"):
                    d["updated_at"] = d["updated_at"].isoformat()
                return d
            return None

    # =========================================================================
    # QUESTION OPERATIONS
    # =========================================================================

    async def create_question(self, question: dict) -> dict:
        """Create a new question."""
        async with self.pool.acquire() as conn:
            now = datetime.now(timezone.utc)
            await conn.execute(
                """
                INSERT INTO kb_questions (
                    id, domain_id, subcategory, question_text, answer_text,
                    acceptable_answers, difficulty, difficulty_tier, speed_target_seconds,
                    question_type, question_source, competition_year, buzzable,
                    hints, explanation, has_audio, status, created_at, updated_at
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
                )
                """,
                question["id"],
                question["domain_id"],
                question.get("subcategory", "General"),
                question["question_text"],
                question["answer_text"],
                question.get("acceptable_answers", []),
                question.get("difficulty", 2),
                question.get("difficulty_tier"),
                question.get("speed_target_seconds", 5.0),
                question.get("question_type", "toss_up"),
                question.get("question_source", "custom"),
                question.get("competition_year"),
                question.get("buzzable", True),
                question.get("hints", []),
                question.get("explanation"),
                question.get("has_audio", False),
                question.get("status", "active"),
                now,
                now,
            )
            logger.info(f"Created question: {question['id']}")
            return await self.get_question(question["id"])

    async def get_question(self, question_id: str) -> Optional[dict]:
        """Get a question by ID."""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT q.*, d.name as domain_name, d.icon_name as domain_icon
                FROM kb_questions q
                JOIN kb_domains d ON q.domain_id = d.id
                WHERE q.id = $1
                """,
                question_id,
            )
            if row:
                return self._row_to_question(row)
            return None

    async def list_questions(
        self,
        pack_id: Optional[str] = None,
        domain_id: Optional[str] = None,
        subcategory: Optional[str] = None,
        difficulties: Optional[list[int]] = None,
        question_type: Optional[str] = None,
        has_audio: Optional[bool] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[dict], int]:
        """List questions with optional filtering."""
        async with self.pool.acquire() as conn:
            # Build query conditions
            conditions = []
            params: list[Any] = []
            param_idx = 1

            # Join with pack_questions if filtering by pack
            if pack_id:
                join_clause = "JOIN kb_pack_questions pq ON q.id = pq.question_id"
                conditions.append(f"pq.pack_id = ${param_idx}")
                params.append(pack_id)
                param_idx += 1
            else:
                join_clause = ""

            if domain_id:
                conditions.append(f"q.domain_id = ${param_idx}")
                params.append(domain_id)
                param_idx += 1

            if subcategory:
                conditions.append(f"q.subcategory = ${param_idx}")
                params.append(subcategory)
                param_idx += 1

            if difficulties:
                conditions.append(f"q.difficulty = ANY(${param_idx})")
                params.append(difficulties)
                param_idx += 1

            if question_type:
                conditions.append(f"q.question_type = ${param_idx}")
                params.append(question_type)
                param_idx += 1

            if has_audio is not None:
                conditions.append(f"q.has_audio = ${param_idx}")
                params.append(has_audio)
                param_idx += 1

            if status:
                conditions.append(f"q.status = ${param_idx}")
                params.append(status)
                param_idx += 1

            if search:
                conditions.append(f"q.search_vector @@ plainto_tsquery('english', ${param_idx})")
                params.append(search)
                param_idx += 1

            where_clause = " AND ".join(conditions) if conditions else "TRUE"

            # Get total count
            count_query = f"""
                SELECT COUNT(DISTINCT q.id)
                FROM kb_questions q
                {join_clause}
                WHERE {where_clause}
            """
            total = await conn.fetchval(count_query, *params)

            # Get questions
            query = f"""
                SELECT DISTINCT q.*, d.name as domain_name, d.icon_name as domain_icon
                FROM kb_questions q
                JOIN kb_domains d ON q.domain_id = d.id
                {join_clause}
                WHERE {where_clause}
                ORDER BY q.created_at DESC
                LIMIT ${param_idx} OFFSET ${param_idx + 1}
            """
            params.extend([limit, offset])

            rows = await conn.fetch(query, *params)
            questions = [self._row_to_question(row) for row in rows]

            return questions, total

    async def update_question(self, question_id: str, updates: dict) -> Optional[dict]:
        """Update a question."""
        # Build SET clause dynamically
        allowed_fields = [
            "domain_id", "subcategory", "question_text", "answer_text",
            "acceptable_answers", "difficulty", "difficulty_tier",
            "speed_target_seconds", "question_type", "question_source",
            "competition_year", "buzzable", "hints", "explanation",
            "has_audio", "status"
        ]

        set_parts = []
        params: list[Any] = [question_id]
        param_idx = 2

        for field in allowed_fields:
            if field in updates:
                set_parts.append(f"{field} = ${param_idx}")
                params.append(updates[field])
                param_idx += 1

        if not set_parts:
            return await self.get_question(question_id)

        set_parts.append(f"updated_at = ${param_idx}")
        params.append(datetime.now(timezone.utc))

        async with self.pool.acquire() as conn:
            await conn.execute(
                f"UPDATE kb_questions SET {', '.join(set_parts)} WHERE id = $1",
                *params,
            )
            logger.info(f"Updated question: {question_id}")
            return await self.get_question(question_id)

    async def delete_question(self, question_id: str) -> bool:
        """Delete a question."""
        async with self.pool.acquire() as conn:
            result = await conn.execute(
                "DELETE FROM kb_questions WHERE id = $1", question_id
            )
            deleted = result.split()[-1] != "0"
            if deleted:
                logger.info(f"Deleted question: {question_id}")
            return deleted

    async def bulk_update_questions(
        self, question_ids: list[str], updates: dict
    ) -> int:
        """Bulk update multiple questions."""
        allowed_fields = ["difficulty", "status", "question_type", "difficulty_tier", "question_source"]

        set_parts = []
        params: list[Any] = [question_ids]
        param_idx = 2

        for field in allowed_fields:
            if field in updates:
                set_parts.append(f"{field} = ${param_idx}")
                params.append(updates[field])
                param_idx += 1

        if not set_parts:
            return 0

        set_parts.append(f"updated_at = ${param_idx}")
        params.append(datetime.now(timezone.utc))

        async with self.pool.acquire() as conn:
            result = await conn.execute(
                f"UPDATE kb_questions SET {', '.join(set_parts)} WHERE id = ANY($1)",
                *params,
            )
            count = int(result.split()[-1])
            logger.info(f"Bulk updated {count} questions")
            return count

    def _row_to_question(self, row: asyncpg.Record) -> dict:
        """Convert database row to question dict."""
        q = dict(row)
        # Convert datetime to ISO string
        if q.get("created_at"):
            q["created_at"] = q["created_at"].isoformat()
        if q.get("updated_at"):
            q["updated_at"] = q["updated_at"].isoformat()
        # Ensure arrays are lists
        q["acceptable_answers"] = list(q.get("acceptable_answers") or [])
        q["hints"] = list(q.get("hints") or [])
        return q

    # =========================================================================
    # PACK OPERATIONS
    # =========================================================================

    async def create_pack(self, pack: dict) -> dict:
        """Create a new pack."""
        async with self.pool.acquire() as conn:
            now = datetime.now(timezone.utc)
            await conn.execute(
                """
                INSERT INTO kb_packs (
                    id, name, description, type, difficulty_tier,
                    competition_year, source_pack_ids, is_reference_bundle,
                    status, created_at, updated_at, created_by
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                """,
                pack["id"],
                pack["name"],
                pack.get("description", ""),
                pack.get("type", "custom"),
                pack.get("difficulty_tier", "varsity"),
                pack.get("competition_year"),
                pack.get("source_pack_ids"),
                pack.get("is_reference_bundle", False),
                pack.get("status", "draft"),
                now,
                now,
                pack.get("created_by"),
            )
            logger.info(f"Created pack: {pack['id']} - {pack['name']}")
            return await self.get_pack(pack["id"])

    async def get_pack(self, pack_id: str) -> Optional[dict]:
        """Get a pack by ID with statistics."""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM kb_pack_summaries WHERE id = $1", pack_id
            )
            if row:
                return self._row_to_pack(row)
            return None

    async def list_packs(
        self,
        pack_type: Optional[str] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[dict], int]:
        """List packs with optional filtering."""
        async with self.pool.acquire() as conn:
            conditions = []
            params: list[Any] = []
            param_idx = 1

            if pack_type:
                conditions.append(f"type = ${param_idx}")
                params.append(pack_type)
                param_idx += 1

            if status:
                conditions.append(f"status = ${param_idx}")
                params.append(status)
                param_idx += 1

            if search:
                conditions.append(f"(name ILIKE ${param_idx} OR description ILIKE ${param_idx})")
                params.append(f"%{search}%")
                param_idx += 1

            where_clause = " AND ".join(conditions) if conditions else "TRUE"

            total = await conn.fetchval(
                f"SELECT COUNT(*) FROM kb_pack_summaries WHERE {where_clause}",
                *params,
            )

            query = f"""
                SELECT * FROM kb_pack_summaries
                WHERE {where_clause}
                ORDER BY updated_at DESC
                LIMIT ${param_idx} OFFSET ${param_idx + 1}
            """
            params.extend([limit, offset])

            rows = await conn.fetch(query, *params)
            packs = [self._row_to_pack(row) for row in rows]

            return packs, total

    async def update_pack(self, pack_id: str, updates: dict) -> Optional[dict]:
        """Update a pack."""
        allowed_fields = [
            "name", "description", "difficulty_tier",
            "competition_year", "status"
        ]

        set_parts = []
        params: list[Any] = [pack_id]
        param_idx = 2

        for field in allowed_fields:
            if field in updates:
                set_parts.append(f"{field} = ${param_idx}")
                params.append(updates[field])
                param_idx += 1

        if not set_parts:
            return await self.get_pack(pack_id)

        set_parts.append(f"updated_at = ${param_idx}")
        params.append(datetime.now(timezone.utc))

        async with self.pool.acquire() as conn:
            await conn.execute(
                f"UPDATE kb_packs SET {', '.join(set_parts)} WHERE id = $1",
                *params,
            )
            logger.info(f"Updated pack: {pack_id}")
            return await self.get_pack(pack_id)

    async def delete_pack(self, pack_id: str) -> bool:
        """Delete a pack."""
        async with self.pool.acquire() as conn:
            result = await conn.execute(
                "DELETE FROM kb_packs WHERE id = $1", pack_id
            )
            deleted = result.split()[-1] != "0"
            if deleted:
                logger.info(f"Deleted pack: {pack_id}")
            return deleted

    def _row_to_pack(self, row: asyncpg.Record) -> dict:
        """Convert database row to pack dict."""
        p = dict(row)
        if p.get("created_at"):
            p["created_at"] = p["created_at"].isoformat()
        if p.get("updated_at"):
            p["updated_at"] = p["updated_at"].isoformat()
        if p.get("source_pack_ids"):
            p["source_pack_ids"] = list(p["source_pack_ids"])
        return p

    # =========================================================================
    # PACK-QUESTION ASSOCIATIONS
    # =========================================================================

    async def add_questions_to_pack(
        self, pack_id: str, question_ids: list[str]
    ) -> int:
        """Add questions to a pack."""
        if not question_ids:
            return 0

        async with self.pool.acquire() as conn:
            # Get current max position
            max_pos = await conn.fetchval(
                "SELECT COALESCE(MAX(position), 0) FROM kb_pack_questions WHERE pack_id = $1",
                pack_id,
            )

            # Insert with ON CONFLICT to skip duplicates
            added = 0
            for i, qid in enumerate(question_ids):
                try:
                    await conn.execute(
                        """
                        INSERT INTO kb_pack_questions (pack_id, question_id, position, added_at)
                        VALUES ($1, $2, $3, $4)
                        ON CONFLICT (pack_id, question_id) DO NOTHING
                        """,
                        pack_id,
                        qid,
                        max_pos + i + 1,
                        datetime.now(timezone.utc),
                    )
                    added += 1
                except Exception as e:
                    logger.warning(f"Failed to add question {qid} to pack {pack_id}: {e}")

            # Update pack timestamp
            await conn.execute(
                "UPDATE kb_packs SET updated_at = $2 WHERE id = $1",
                pack_id,
                datetime.now(timezone.utc),
            )

            logger.info(f"Added {added} questions to pack {pack_id}")
            return added

    async def remove_question_from_pack(
        self, pack_id: str, question_id: str
    ) -> bool:
        """Remove a question from a pack."""
        async with self.pool.acquire() as conn:
            result = await conn.execute(
                "DELETE FROM kb_pack_questions WHERE pack_id = $1 AND question_id = $2",
                pack_id,
                question_id,
            )
            deleted = result.split()[-1] != "0"
            if deleted:
                await conn.execute(
                    "UPDATE kb_packs SET updated_at = $2 WHERE id = $1",
                    pack_id,
                    datetime.now(timezone.utc),
                )
                logger.info(f"Removed question {question_id} from pack {pack_id}")
            return deleted

    async def get_pack_question_ids(self, pack_id: str) -> list[str]:
        """Get all question IDs in a pack."""
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT question_id FROM kb_pack_questions WHERE pack_id = $1 ORDER BY position",
                pack_id,
            )
            return [row["question_id"] for row in rows]

    # =========================================================================
    # STATISTICS
    # =========================================================================

    async def get_pack_difficulty_distribution(self, pack_id: str) -> dict[int, int]:
        """Get difficulty distribution for a pack."""
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM kb_pack_difficulty_distribution($1)", pack_id
            )
            return {row["difficulty"]: row["count"] for row in rows}

    async def get_pack_domain_distribution(self, pack_id: str) -> list[dict]:
        """Get domain distribution for a pack."""
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT * FROM kb_pack_domain_distribution($1)", pack_id
            )
            return [dict(row) for row in rows]

    # =========================================================================
    # IMPORT
    # =========================================================================

    async def import_questions_bulk(self, questions: list[dict]) -> int:
        """Bulk import questions (upsert)."""
        if not questions:
            return 0

        async with self.pool.acquire() as conn:
            now = datetime.now(timezone.utc)
            imported = 0

            for q in questions:
                try:
                    await conn.execute(
                        """
                        INSERT INTO kb_questions (
                            id, domain_id, subcategory, question_text, answer_text,
                            acceptable_answers, difficulty, difficulty_tier, speed_target_seconds,
                            question_type, question_source, buzzable,
                            hints, explanation, has_audio, status, created_at, updated_at
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
                        ON CONFLICT (id) DO UPDATE SET
                            domain_id = EXCLUDED.domain_id,
                            subcategory = EXCLUDED.subcategory,
                            question_text = EXCLUDED.question_text,
                            answer_text = EXCLUDED.answer_text,
                            acceptable_answers = EXCLUDED.acceptable_answers,
                            difficulty = EXCLUDED.difficulty,
                            hints = EXCLUDED.hints,
                            explanation = EXCLUDED.explanation,
                            updated_at = EXCLUDED.updated_at
                        """,
                        q["id"],
                        q["domain_id"],
                        q.get("subcategory", "General"),
                        q["question_text"],
                        q["answer_text"],
                        q.get("acceptable_answers", []),
                        q.get("difficulty", 2),
                        q.get("difficulty_tier"),
                        q.get("speed_target_seconds", 5.0),
                        q.get("question_type", "toss_up"),
                        q.get("question_source", "naqt"),
                        q.get("buzzable", True),
                        q.get("hints", []),
                        q.get("explanation"),
                        q.get("has_audio", False),
                        q.get("status", "active"),
                        now,
                        now,
                    )
                    imported += 1
                except Exception as e:
                    logger.warning(f"Failed to import question {q.get('id')}: {e}")

            logger.info(f"Imported {imported} questions")
            return imported

    async def get_question_count(self) -> int:
        """Get total question count."""
        async with self.pool.acquire() as conn:
            return await conn.fetchval("SELECT COUNT(*) FROM kb_questions")

    async def get_domain_question_counts(self) -> dict[str, int]:
        """Get question count per domain."""
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                "SELECT domain_id, COUNT(*) as count FROM kb_questions GROUP BY domain_id"
            )
            return {row["domain_id"]: row["count"] for row in rows}
