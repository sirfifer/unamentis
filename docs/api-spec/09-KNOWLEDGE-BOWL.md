# Knowledge Bowl API

**Version:** 1.0.0
**Last Updated:** 2026-01-25
**Base URL:** `http://localhost:8766`

---

## Overview

The Knowledge Bowl API provides endpoints for managing question packs, questions, and content organization for Knowledge Bowl competition preparation. It supports full CRUD operations on packs and questions, bundle creation with deduplication, and import functionality from the Knowledge Bowl module.

---

## Data Models

### Question Pack

```json
{
  "id": "pack-a1b2c3d4",
  "name": "Science Championship 2025",
  "description": "Championship-level science questions",
  "type": "custom",
  "difficulty_tier": "championship",
  "competition_year": "2024-2025",
  "question_ids": ["sci-phys-a1b2c3", "sci-chem-d4e5f6"],
  "status": "active",
  "created_at": "2026-01-25T10:00:00Z",
  "updated_at": "2026-01-25T12:00:00Z"
}
```

### Question Pack Summary (List Response)

```json
{
  "id": "pack-a1b2c3d4",
  "name": "Science Championship 2025",
  "description": "Championship-level science questions",
  "type": "custom",
  "difficulty_tier": "championship",
  "question_count": 150,
  "domain_count": 5,
  "audio_coverage_percent": 85.5,
  "status": "active",
  "updated_at": "2026-01-25T12:00:00Z"
}
```

### Question

```json
{
  "id": "sci-phys-a1b2c3",
  "domain_id": "science",
  "subcategory": "Physics",
  "question_text": "What is the SI unit of force?",
  "answer_text": "Newton",
  "acceptable_answers": ["Newton", "N", "newtons"],
  "difficulty": 2,
  "speed_target_seconds": 5.0,
  "question_type": "toss_up",
  "hints": ["Named after a famous scientist"],
  "explanation": "The newton is the SI unit of force, named after Isaac Newton.",
  "difficulty_tier": "varsity",
  "competition_year": "2024-2025",
  "question_source": "naqt",
  "buzzable": true,
  "pack_ids": ["pack-a1b2c3d4"],
  "status": "active",
  "has_audio": false,
  "created_at": "2026-01-25T10:00:00Z",
  "updated_at": "2026-01-25T10:00:00Z"
}
```

### Domain Group

```json
{
  "domain_id": "science",
  "domain_name": "Science",
  "question_count": 50,
  "subcategories": [
    { "subcategory": "Physics", "question_count": 20 },
    { "subcategory": "Chemistry", "question_count": 15 },
    { "subcategory": "Biology", "question_count": 15 }
  ]
}
```

---

## Enumerations

### Difficulty Tiers

| Value | Description |
|-------|-------------|
| `elementary` | Grades 3-5 |
| `middle_school` | Grades 6-8 |
| `jv` | Junior Varsity (Grades 9-10) |
| `varsity` | Varsity (Grades 11-12) |
| `championship` | State/National level |
| `college` | Undergraduate |

### Question Types

| Value | Description |
|-------|-------------|
| `toss_up` | Single-answer buzzer question |
| `bonus` | Multi-part team question |
| `pyramid` | Progressive clue question |
| `lightning` | Rapid-fire question set |

### Question Sources

| Value | Description |
|-------|-------------|
| `naqt` | National Academic Quiz Tournaments |
| `nsb` | National Science Bowl |
| `qb_packets` | Quiz Bowl Packets |
| `custom` | User-created |
| `ai_generated` | AI-generated content |

### Pack Types

| Value | Description |
|-------|-------------|
| `system` | System-provided (read-only) |
| `custom` | User-created pack |
| `bundle` | Aggregation of multiple packs |

### Entity Status

| Value | Description |
|-------|-------------|
| `active` | Available for use |
| `draft` | Work in progress |
| `archived` | No longer active |

---

## Pack Endpoints

### GET /api/kb/packs

List all question packs with optional filtering.

**Authentication:** Required

**Query Parameters:**
- `type` (string): Filter by pack type (system, custom, bundle)
- `status` (string): Filter by status (active, draft, archived)
- `search` (string): Search in name/description
- `limit` (integer): Max results (default: 50, max: 100)
- `offset` (integer): Pagination offset (default: 0)

**Response (200 OK):**
```json
{
  "success": true,
  "packs": [
    {
      "id": "pack-a1b2c3d4",
      "name": "Science Championship 2025",
      "description": "Championship-level science questions",
      "type": "custom",
      "difficulty_tier": "championship",
      "question_count": 150,
      "domain_count": 5,
      "audio_coverage_percent": 85.5,
      "status": "active",
      "updated_at": "2026-01-25T12:00:00Z"
    }
  ],
  "total": 25,
  "limit": 50,
  "offset": 0
}
```

---

### POST /api/kb/packs

Create a new question pack.

**Authentication:** Required

**Request Body:**
```json
{
  "name": "Science Championship 2025",
  "description": "Championship-level science questions",
  "type": "custom",
  "difficulty_tier": "championship",
  "competition_year": "2024-2025",
  "status": "draft"
}
```

**Required Fields:**
- `name` (string): Pack name

**Optional Fields:**
- `description` (string): Pack description
- `type` (string): Pack type (default: "custom")
- `difficulty_tier` (string): Difficulty tier (default: "varsity")
- `competition_year` (string): Competition year
- `status` (string): Pack status (default: "draft")

**Response (200 OK):**
```json
{
  "success": true,
  "pack": {
    "id": "pack-e5f6g7h8",
    "name": "Science Championship 2025",
    "description": "Championship-level science questions",
    "type": "custom",
    "difficulty_tier": "championship",
    "competition_year": "2024-2025",
    "question_ids": [],
    "status": "draft",
    "created_at": "2026-01-25T14:00:00Z",
    "updated_at": "2026-01-25T14:00:00Z"
  }
}
```

**Errors:**
- `400`: Missing required field or invalid enum value

---

### GET /api/kb/packs/{pack_id}

Get detailed information about a pack including domain groups.

**Authentication:** Required

**Parameters:**
- `pack_id` (path): Pack identifier

**Response (200 OK):**
```json
{
  "success": true,
  "pack": {
    "id": "pack-a1b2c3d4",
    "name": "Science Championship 2025",
    "description": "Championship-level science questions",
    "type": "custom",
    "difficulty_tier": "championship",
    "competition_year": "2024-2025",
    "question_ids": ["sci-phys-a1b2c3", "sci-chem-d4e5f6"],
    "status": "active",
    "question_count": 150,
    "domain_count": 5,
    "difficulty_distribution": { "1": 20, "2": 40, "3": 50, "4": 30, "5": 10 },
    "domain_distribution": { "science": 80, "mathematics": 70 },
    "question_types": ["toss_up", "bonus"],
    "audio_coverage_percent": 85.5,
    "missing_audio_count": 22,
    "created_at": "2026-01-25T10:00:00Z",
    "updated_at": "2026-01-25T12:00:00Z"
  },
  "domain_groups": [
    {
      "domain_id": "science",
      "domain_name": "Science",
      "question_count": 80,
      "subcategories": [
        { "subcategory": "Physics", "question_count": 30 },
        { "subcategory": "Chemistry", "question_count": 25 },
        { "subcategory": "Biology", "question_count": 25 }
      ]
    }
  ]
}
```

**Errors:**
- `400`: Invalid pack_id format
- `404`: Pack not found

---

### PATCH /api/kb/packs/{pack_id}

Update pack metadata.

**Authentication:** Required

**Parameters:**
- `pack_id` (path): Pack identifier

**Request Body:**
```json
{
  "name": "Updated Pack Name",
  "description": "Updated description",
  "difficulty_tier": "varsity",
  "competition_year": "2025-2026",
  "status": "active"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "pack": {
    "id": "pack-a1b2c3d4",
    "name": "Updated Pack Name",
    "updated_at": "2026-01-25T15:00:00Z"
  }
}
```

**Errors:**
- `400`: Invalid pack_id or enum value
- `403`: Cannot modify system pack
- `404`: Pack not found

---

### DELETE /api/kb/packs/{pack_id}

Delete a pack.

**Authentication:** Required

**Parameters:**
- `pack_id` (path): Pack identifier

**Response (200 OK):**
```json
{
  "success": true,
  "pack_id": "pack-a1b2c3d4"
}
```

**Errors:**
- `400`: Invalid pack_id
- `403`: Cannot delete system pack
- `404`: Pack not found

---

## Pack Question Management

### POST /api/kb/packs/{pack_id}/questions

Add questions to a pack.

**Authentication:** Required

**Parameters:**
- `pack_id` (path): Pack identifier

**Request Body:**
```json
{
  "question_ids": ["sci-phys-a1b2c3", "sci-chem-d4e5f6"]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "added_count": 2,
  "added_ids": ["sci-phys-a1b2c3", "sci-chem-d4e5f6"]
}
```

**Errors:**
- `400`: Invalid pack_id or no question_ids provided
- `400`: Invalid question IDs (shows up to 5)
- `403`: Cannot modify system pack
- `404`: Pack not found

---

### DELETE /api/kb/packs/{pack_id}/questions/{question_id}

Remove a question from a pack.

**Authentication:** Required

**Parameters:**
- `pack_id` (path): Pack identifier
- `question_id` (path): Question identifier

**Response (200 OK):**
```json
{
  "success": true
}
```

**Errors:**
- `400`: Invalid pack_id or question_id
- `403`: Cannot modify system pack
- `404`: Pack or question not found in pack

---

## Bundle Operations

### POST /api/kb/packs/bundle

Create a bundle pack from multiple existing packs.

**Authentication:** Required

**Request Body:**
```json
{
  "name": "Combined Science Bundle",
  "description": "All science packs combined",
  "source_pack_ids": ["pack-1", "pack-2", "pack-3"],
  "is_reference_bundle": false,
  "deduplication_strategy": "keep_first",
  "excluded_question_ids": [],
  "difficulty_tier": "varsity",
  "competition_year": "2024-2025"
}
```

**Required Fields:**
- `name` (string): Bundle name
- `source_pack_ids` (array): Source pack IDs

**Optional Fields:**
- `description` (string): Bundle description
- `is_reference_bundle` (boolean): If true, bundle references questions rather than copying
- `deduplication_strategy` (string): "keep_first" to skip duplicates (default)
- `excluded_question_ids` (array): Question IDs to exclude
- `difficulty_tier` (string): Default "varsity"
- `competition_year` (string): Competition year

**Response (200 OK):**
```json
{
  "success": true,
  "pack": {
    "id": "pack-bundle-xyz",
    "name": "Combined Science Bundle",
    "type": "bundle",
    "source_pack_ids": ["pack-1", "pack-2", "pack-3"],
    "question_count": 350,
    "domain_count": 6,
    "difficulty_distribution": { "1": 50, "2": 100, "3": 100, "4": 75, "5": 25 },
    "audio_coverage_percent": 72.5
  },
  "duplicates_skipped": 15,
  "duplicates": [
    { "question_id": "q-123", "duplicate_of": "q-456" }
  ]
}
```

**Errors:**
- `400`: Missing name or source_pack_ids
- `400`: Invalid source pack IDs

---

### POST /api/kb/packs/preview-dedup

Preview duplicates before creating a bundle.

**Authentication:** Required

**Request Body:**
```json
{
  "source_pack_ids": ["pack-1", "pack-2", "pack-3"]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "duplicate_groups": [
    {
      "question_text": "What is the SI unit of force?...",
      "occurrences": [
        { "question_id": "q-123", "pack_id": "pack-1", "pack_name": "Physics Basics" },
        { "question_id": "q-789", "pack_id": "pack-2", "pack_name": "Science Review" }
      ]
    }
  ],
  "total_duplicates": 15,
  "unique_questions_after_dedup": 320
}
```

---

## Question Endpoints

### GET /api/kb/questions

List questions with optional filtering.

**Authentication:** Required

**Query Parameters:**
- `pack_id` (string): Filter by pack
- `domain_id` (string): Filter by domain
- `subcategory` (string): Filter by subcategory
- `difficulty` (string): Comma-separated difficulties (e.g., "1,2,3")
- `question_type` (string): Filter by question type
- `has_audio` (string): "true" or "false"
- `status` (string): Filter by status
- `search` (string): Search in question/answer text
- `limit` (integer): Max results (default: 20, max: 100)
- `offset` (integer): Pagination offset

**Response (200 OK):**
```json
{
  "success": true,
  "questions": [
    {
      "id": "sci-phys-a1b2c3",
      "domain_id": "science",
      "subcategory": "Physics",
      "question_text": "What is the SI unit of force?",
      "answer_text": "Newton",
      "acceptable_answers": ["Newton", "N"],
      "difficulty": 2,
      "question_type": "toss_up",
      "status": "active",
      "has_audio": false
    }
  ],
  "total": 150,
  "limit": 20,
  "offset": 0
}
```

---

### POST /api/kb/questions

Create a new question.

**Authentication:** Required

**Request Body:**
```json
{
  "domain_id": "science",
  "subcategory": "Physics",
  "question_text": "What is the SI unit of force?",
  "answer_text": "Newton",
  "acceptable_answers": ["Newton", "N", "newtons"],
  "difficulty": 2,
  "speed_target_seconds": 5.0,
  "question_type": "toss_up",
  "hints": ["Named after a famous scientist"],
  "explanation": "The newton is the SI unit of force, named after Isaac Newton.",
  "difficulty_tier": "varsity",
  "competition_year": "2024-2025",
  "question_source": "custom",
  "buzzable": true,
  "pack_ids": ["pack-a1b2c3d4"],
  "status": "active"
}
```

**Required Fields:**
- `domain_id` (string): Domain identifier
- `question_text` (string): The question
- `answer_text` (string): Primary answer

**Response (200 OK):**
```json
{
  "success": true,
  "question": {
    "id": "sci-phys-e5f6g7",
    "domain_id": "science",
    "question_text": "What is the SI unit of force?",
    "created_at": "2026-01-25T16:00:00Z"
  }
}
```

**Errors:**
- `400`: Missing required fields
- `400`: Invalid enum values (question_type, question_source)
- `400`: Difficulty must be 1-5

---

### GET /api/kb/questions/{question_id}

Get a question by ID.

**Authentication:** Required

**Parameters:**
- `question_id` (path): Question identifier

**Response (200 OK):**
```json
{
  "success": true,
  "question": {
    "id": "sci-phys-a1b2c3",
    "domain_id": "science",
    "subcategory": "Physics",
    "question_text": "What is the SI unit of force?",
    "answer_text": "Newton",
    "acceptable_answers": ["Newton", "N"],
    "difficulty": 2,
    "question_type": "toss_up",
    "hints": ["Named after a famous scientist"],
    "explanation": "The newton is the SI unit of force...",
    "pack_ids": ["pack-a1b2c3d4"],
    "status": "active",
    "has_audio": false
  }
}
```

**Errors:**
- `400`: Invalid question_id
- `404`: Question not found

---

### PATCH /api/kb/questions/{question_id}

Update a question.

**Authentication:** Required

**Parameters:**
- `question_id` (path): Question identifier

**Request Body:**
```json
{
  "question_text": "Updated question text",
  "difficulty": 3,
  "status": "active"
}
```

**Updatable Fields:**
- `domain_id`, `subcategory`, `question_text`, `answer_text`
- `acceptable_answers`, `difficulty`, `speed_target_seconds`
- `question_type`, `hints`, `explanation`
- `difficulty_tier`, `competition_year`, `question_source`
- `buzzable`, `status`

**Response (200 OK):**
```json
{
  "success": true,
  "question": {
    "id": "sci-phys-a1b2c3",
    "question_text": "Updated question text",
    "difficulty": 3,
    "updated_at": "2026-01-25T17:00:00Z"
  }
}
```

**Errors:**
- `400`: Invalid question_id or enum value
- `400`: Difficulty must be 1-5
- `404`: Question not found

---

### DELETE /api/kb/questions/{question_id}

Delete a question.

**Authentication:** Required

**Parameters:**
- `question_id` (path): Question identifier

**Response (200 OK):**
```json
{
  "success": true,
  "question_id": "sci-phys-a1b2c3"
}
```

**Notes:**
- Question is automatically removed from all packs

**Errors:**
- `400`: Invalid question_id
- `404`: Question not found

---

### POST /api/kb/questions/bulk-update

Bulk update multiple questions.

**Authentication:** Required

**Request Body:**
```json
{
  "question_ids": ["q-1", "q-2", "q-3"],
  "updates": {
    "difficulty": 3,
    "status": "active"
  }
}
```

**Updatable Fields in Bulk:**
- `difficulty`, `status`, `question_type`
- `difficulty_tier`, `question_source`

**Response (200 OK):**
```json
{
  "success": true,
  "affected_count": 3,
  "errors": null
}
```

**Partial Success Response:**
```json
{
  "success": true,
  "affected_count": 2,
  "errors": [
    { "question_id": "q-3", "error": "Not found" }
  ]
}
```

---

## Import Endpoints

### POST /api/kb/import-from-module

Import questions from the Knowledge Bowl module into a pack.

**Authentication:** Required

**Request Body:**
```json
{
  "pack_id": "pack-a1b2c3d4",
  "domains": ["science", "mathematics"],
  "difficulties": [1, 2, 3]
}
```

**Required Fields:**
- `pack_id` (string): Target pack ID

**Optional Fields:**
- `domains` (array): Filter by domains (all if not specified)
- `difficulties` (array): Filter by difficulties (all if not specified)

**Response (200 OK):**
```json
{
  "success": true,
  "imported_count": 45,
  "skipped_count": 5
}
```

**Errors:**
- `400`: Missing pack_id or invalid pack_id
- `404`: Pack not found or Knowledge Bowl module not found

---

## Domain Reference

The Knowledge Bowl system supports the following domains:

| Domain ID | Name | Subcategories |
|-----------|------|---------------|
| `science` | Science | biology, chemistry, physics, earth_science, astronomy, computer_science |
| `mathematics` | Mathematics | arithmetic, algebra, geometry, trigonometry, calculus, statistics |
| `literature` | Literature | american, british, world, poetry, drama, mythology |
| `history` | History | us_history, world_history, ancient, medieval, modern, military |
| `social_studies` | Social Studies | geography, government, economics, sociology, psychology, anthropology |
| `fine_arts` | Fine Arts | visual_arts, music, theater, dance, architecture, film |
| `current_events` | Current Events | politics, science_news, culture, sports, technology, business |
| `language` | Language | grammar, vocabulary, etymology, foreign_language, linguistics |
| `religion_philosophy` | Religion & Philosophy | world_religions, philosophy, ethics, mythology |
| `pop_culture` | Pop Culture | entertainment, media, sports_culture, games, internet |
| `technology` | Technology | inventions, engineering, computing, space_exploration |
| `miscellaneous` | Miscellaneous | general_trivia, cross_domain, puzzles, wordplay |

---

## Client Implementation Notes

### Caching Strategy

1. Cache pack list with 1-minute TTL
2. Cache individual pack details with 5-minute TTL
3. Invalidate pack cache on any modification
4. Cache question list results per filter combination

### Pagination Best Practices

1. Default to 20 questions per page for browsing
2. Use 50 questions per page for bulk operations
3. Implement infinite scroll for question browsing
4. Pre-fetch next page for smooth UX

### Error Handling

All endpoints return consistent error format:
```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

---

## Related Documentation

- [Knowledge Bowl Module](../modules/KNOWLEDGE_BOWL_MODULE.md)
- [Knowledge Bowl Answer Validation](../modules/KNOWLEDGE_BOWL_ANSWER_VALIDATION.md)
- [TTS API](04-TTS.md) - Audio generation for questions
- [Curricula API](02-CURRICULA.md) - Content management patterns
