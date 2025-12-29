-- ============================================================================
-- UMCF (Una Mentis Curriculum Format) Normalized Database Schema
-- PostgreSQL 15+ with pg_trgm and pg_search (ParadeDB) extensions
-- ============================================================================
--
-- Architecture: Normalized tables with JSON export capability
-- - Granular editing: Each piece of content in its own table
-- - Fast queries: Indexed metadata columns
-- - JSON export: Rebuild full UMCF documents on demand
-- - Full-text search: Using pg_trgm for fuzzy matching
--
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Curricula: Top-level container for a learning curriculum
CREATE TABLE curricula (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255) UNIQUE,  -- The UMCF id.value field
    catalog VARCHAR(100),              -- The UMCF id.catalog field

    -- Core metadata
    title VARCHAR(500) NOT NULL,
    description TEXT,

    -- Version info
    version_number VARCHAR(50) DEFAULT '1.0.0',
    version_date TIMESTAMPTZ,
    version_changelog TEXT,

    -- Lifecycle
    lifecycle_status VARCHAR(50) DEFAULT 'draft',  -- draft, review, final, deprecated
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Educational context (denormalized for fast queries)
    difficulty VARCHAR(50),            -- easy, medium, difficult
    age_range VARCHAR(50),             -- e.g., "18+", "12-14"
    typical_learning_time VARCHAR(50), -- ISO 8601 duration, e.g., "PT4H"
    language VARCHAR(10) DEFAULT 'en-US',

    -- Search optimization
    keywords TEXT[],                   -- Array of keywords for filtering
    subjects TEXT[],                   -- Subject areas

    -- JSON cache for fast export (rebuilt on changes via trigger)
    json_cache JSONB,
    json_cache_updated_at TIMESTAMPTZ,

    -- Indexes for search
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(array_to_string(keywords, ' '), '')), 'C')
    ) STORED
);

CREATE INDEX idx_curricula_search ON curricula USING GIN(search_vector);
CREATE INDEX idx_curricula_keywords ON curricula USING GIN(keywords);
CREATE INDEX idx_curricula_difficulty ON curricula(difficulty);
CREATE INDEX idx_curricula_status ON curricula(lifecycle_status);
CREATE INDEX idx_curricula_updated ON curricula(updated_at DESC);

-- Contributors to a curriculum
CREATE TABLE curriculum_contributors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    curriculum_id UUID NOT NULL REFERENCES curricula(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(100) NOT NULL,  -- author, editor, reviewer, subject matter expert
    organization VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contributors_curriculum ON curriculum_contributors(curriculum_id);

-- Educational alignment (standards, frameworks)
CREATE TABLE curriculum_alignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    curriculum_id UUID NOT NULL REFERENCES curricula(id) ON DELETE CASCADE,
    alignment_type VARCHAR(50),      -- teaches, requires, assesses
    framework_name VARCHAR(255),     -- e.g., "Common Core", "ACM Computing Curricula"
    target_name VARCHAR(500),
    target_description TEXT,
    target_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alignments_curriculum ON curriculum_alignments(curriculum_id);

-- Prerequisites for a curriculum
CREATE TABLE curriculum_prerequisites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    curriculum_id UUID NOT NULL REFERENCES curricula(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    prerequisite_type VARCHAR(50),   -- knowledge, skill, course
    is_required BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prerequisites_curriculum ON curriculum_prerequisites(curriculum_id);

-- ============================================================================
-- CONTENT HIERARCHY
-- ============================================================================

-- Topics: Main content units within a curriculum (can be nested)
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),         -- The UMCF id.value field
    curriculum_id UUID NOT NULL REFERENCES curricula(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES topics(id) ON DELETE CASCADE,  -- For nested topics

    -- Core info
    title VARCHAR(500) NOT NULL,
    description TEXT,
    content_type VARCHAR(50) DEFAULT 'topic',  -- unit, topic, subtopic, lesson
    order_index INTEGER DEFAULT 0,

    -- Time estimates by depth level
    time_overview VARCHAR(50),
    time_introductory VARCHAR(50),
    time_intermediate VARCHAR(50),
    time_advanced VARCHAR(50),
    time_graduate VARCHAR(50),
    time_research VARCHAR(50),

    -- Tutoring configuration
    content_depth VARCHAR(50),         -- overview, introductory, intermediate, etc.
    interaction_mode VARCHAR(50),      -- lecture, socratic, guided, exploratory
    checkpoint_frequency VARCHAR(50),  -- high, medium, low

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Search
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B')
    ) STORED
);

CREATE INDEX idx_topics_curriculum ON topics(curriculum_id);
CREATE INDEX idx_topics_parent ON topics(parent_id);
CREATE INDEX idx_topics_order ON topics(curriculum_id, order_index);
CREATE INDEX idx_topics_search ON topics USING GIN(search_vector);

-- Learning objectives for a topic
CREATE TABLE learning_objectives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    statement TEXT NOT NULL,
    abbreviated_statement VARCHAR(500),
    blooms_level VARCHAR(50),  -- remember, understand, apply, analyze, evaluate, create
    order_index INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_objectives_topic ON learning_objectives(topic_id);

-- ============================================================================
-- TRANSCRIPT CONTENT
-- ============================================================================

-- Transcript segments: Individual speakable content pieces
CREATE TABLE transcript_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id VARCHAR(255),          -- The original segment ID from UMCF
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    -- Content
    segment_type VARCHAR(50) NOT NULL,  -- introduction, explanation, example, analogy, summary, checkpoint, transition
    content TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,

    -- Speaking notes
    pace VARCHAR(50),                  -- slow, moderate, normal, brisk
    emotional_tone VARCHAR(50),        -- enthusiastic, thoughtful, encouraging, serious
    pause_after VARCHAR(50),           -- e.g., "1s", "2s"
    emphasis_words TEXT[],             -- Words to emphasize
    pronunciations JSONB,              -- {"word": "pronunciation"} map

    -- Checkpoint info (if segment_type = 'checkpoint')
    checkpoint_type VARCHAR(50),       -- comprehension, reflection, recall
    checkpoint_question TEXT,
    expected_response_type VARCHAR(50),
    expected_keywords TEXT[],
    expected_patterns TEXT[],
    celebration_message TEXT,

    -- Stopping point info
    stopping_point_type VARCHAR(50),
    prompt_for_continue BOOLEAN DEFAULT false,
    suggested_prompt TEXT,

    -- Glossary references
    glossary_refs TEXT[],              -- Array of glossary term IDs

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Full-text search on content
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(content, ''))
    ) STORED
);

CREATE INDEX idx_segments_topic ON transcript_segments(topic_id);
CREATE INDEX idx_segments_order ON transcript_segments(topic_id, order_index);
CREATE INDEX idx_segments_type ON transcript_segments(segment_type);
CREATE INDEX idx_segments_search ON transcript_segments USING GIN(search_vector);

-- Alternative explanations for a segment
CREATE TABLE alternative_explanations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID NOT NULL REFERENCES transcript_segments(id) ON DELETE CASCADE,

    style VARCHAR(50),                 -- simpler, technical, analogy, visual
    content TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alternatives_segment ON alternative_explanations(segment_id);

-- ============================================================================
-- EDUCATIONAL CONTENT
-- ============================================================================

-- Glossary terms: Vocabulary definitions
CREATE TABLE glossary_terms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    term_id VARCHAR(255),             -- The original term ID from UMCF
    curriculum_id UUID NOT NULL REFERENCES curricula(id) ON DELETE CASCADE,

    term VARCHAR(255) NOT NULL,
    pronunciation VARCHAR(255),
    definition TEXT,
    spoken_definition TEXT,           -- TTS-friendly definition
    simple_definition TEXT,           -- For younger audiences

    examples TEXT[],
    related_terms TEXT[],             -- References to other term_ids

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Search
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(term, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(definition, '')), 'B')
    ) STORED
);

CREATE INDEX idx_glossary_curriculum ON glossary_terms(curriculum_id);
CREATE INDEX idx_glossary_term ON glossary_terms(term);
CREATE INDEX idx_glossary_search ON glossary_terms USING GIN(search_vector);

-- Examples for a topic
CREATE TABLE examples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    example_type VARCHAR(50),          -- real_world, analogy, worked_problem, counter_example
    title VARCHAR(500),
    content TEXT NOT NULL,
    explanation TEXT,
    order_index INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_examples_topic ON examples(topic_id);

-- Misconceptions: Common misunderstandings to address
CREATE TABLE misconceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    triggers TEXT[],                   -- Phrases that indicate this misconception
    misconception TEXT NOT NULL,       -- The incorrect belief
    correction TEXT NOT NULL,          -- The correct understanding
    explanation TEXT,                  -- Why this misconception occurs
    order_index INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_misconceptions_topic ON misconceptions(topic_id);
CREATE INDEX idx_misconceptions_triggers ON misconceptions USING GIN(triggers);

-- Assessments: Questions and quizzes
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,

    assessment_type VARCHAR(50),       -- multiple_choice, text_entry, verbal, true_false
    question TEXT NOT NULL,
    correct_answer TEXT,
    hint TEXT,

    -- Feedback messages
    feedback_correct TEXT,
    feedback_incorrect TEXT,
    feedback_partial TEXT,

    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_assessments_topic ON assessments(topic_id);

-- Assessment options (for multiple choice)
CREATE TABLE assessment_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,

    option_id VARCHAR(50),             -- e.g., "a", "b", "c"
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_options_assessment ON assessment_options(assessment_id);

-- ============================================================================
-- FUNCTIONS FOR JSON EXPORT
-- ============================================================================

-- Function to build full UMCF JSON for a curriculum
CREATE OR REPLACE FUNCTION build_umcf_json(p_curriculum_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_curriculum RECORD;
    v_topics JSONB;
    v_glossary JSONB;
BEGIN
    -- Get curriculum
    SELECT * INTO v_curriculum FROM curricula WHERE id = p_curriculum_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Build topics array with nested content
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', jsonb_build_object('catalog', 'UUID', 'value', t.external_id),
            'title', t.title,
            'type', t.content_type,
            'orderIndex', t.order_index,
            'description', t.description,
            'timeEstimates', jsonb_build_object(
                'overview', t.time_overview,
                'introductory', t.time_introductory,
                'intermediate', t.time_intermediate,
                'advanced', t.time_advanced,
                'graduate', t.time_graduate,
                'research', t.time_research
            ),
            'tutoringConfig', jsonb_build_object(
                'contentDepth', t.content_depth,
                'interactionMode', t.interaction_mode,
                'checkpointFrequency', t.checkpoint_frequency
            ),
            'learningObjectives', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', jsonb_build_object('catalog', 'UUID', 'value', lo.external_id),
                        'statement', lo.statement,
                        'abbreviatedStatement', lo.abbreviated_statement,
                        'bloomsLevel', lo.blooms_level
                    ) ORDER BY lo.order_index
                )
                FROM learning_objectives lo
                WHERE lo.topic_id = t.id
            ),
            'transcript', jsonb_build_object(
                'segments', (
                    SELECT jsonb_agg(
                        jsonb_build_object(
                            'id', ts.segment_id,
                            'type', ts.segment_type,
                            'content', ts.content,
                            'speakingNotes', CASE WHEN ts.pace IS NOT NULL THEN
                                jsonb_build_object(
                                    'pace', ts.pace,
                                    'emotionalTone', ts.emotional_tone,
                                    'pauseAfter', ts.pause_after,
                                    'emphasis', ts.emphasis_words,
                                    'pronunciation', ts.pronunciations
                                )
                            ELSE NULL END,
                            'checkpoint', CASE WHEN ts.checkpoint_type IS NOT NULL THEN
                                jsonb_build_object(
                                    'type', ts.checkpoint_type,
                                    'question', ts.checkpoint_question,
                                    'expectedResponse', jsonb_build_object(
                                        'type', ts.expected_response_type,
                                        'keywords', ts.expected_keywords,
                                        'acceptablePatterns', ts.expected_patterns
                                    ),
                                    'celebrationMessage', ts.celebration_message
                                )
                            ELSE NULL END,
                            'stoppingPoint', CASE WHEN ts.stopping_point_type IS NOT NULL THEN
                                jsonb_build_object(
                                    'type', ts.stopping_point_type,
                                    'promptForContinue', ts.prompt_for_continue,
                                    'suggestedPrompt', ts.suggested_prompt
                                )
                            ELSE NULL END,
                            'glossaryRefs', ts.glossary_refs,
                            'alternativeExplanations', (
                                SELECT jsonb_agg(
                                    jsonb_build_object(
                                        'style', ae.style,
                                        'content', ae.content
                                    ) ORDER BY ae.order_index
                                )
                                FROM alternative_explanations ae
                                WHERE ae.segment_id = ts.id
                            )
                        ) ORDER BY ts.order_index
                    )
                    FROM transcript_segments ts
                    WHERE ts.topic_id = t.id
                )
            ),
            'examples', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', jsonb_build_object('catalog', 'UUID', 'value', e.external_id),
                        'type', e.example_type,
                        'title', e.title,
                        'content', e.content,
                        'explanation', e.explanation
                    ) ORDER BY e.order_index
                )
                FROM examples e
                WHERE e.topic_id = t.id
            ),
            'misconceptions', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', jsonb_build_object('catalog', 'UUID', 'value', m.external_id),
                        'trigger', m.triggers,
                        'misconception', m.misconception,
                        'correction', m.correction,
                        'explanation', m.explanation
                    ) ORDER BY m.order_index
                )
                FROM misconceptions m
                WHERE m.topic_id = t.id
            ),
            'assessments', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', jsonb_build_object('catalog', 'UUID', 'value', a.external_id),
                        'type', a.assessment_type,
                        'question', a.question,
                        'correctAnswer', a.correct_answer,
                        'hint', a.hint,
                        'feedback', jsonb_build_object(
                            'correct', a.feedback_correct,
                            'incorrect', a.feedback_incorrect,
                            'partial', a.feedback_partial
                        ),
                        'options', (
                            SELECT jsonb_agg(
                                jsonb_build_object(
                                    'id', ao.option_id,
                                    'text', ao.option_text,
                                    'isCorrect', ao.is_correct
                                ) ORDER BY ao.order_index
                            )
                            FROM assessment_options ao
                            WHERE ao.assessment_id = a.id
                        )
                    ) ORDER BY a.order_index
                )
                FROM assessments a
                WHERE a.topic_id = t.id
            )
        ) ORDER BY t.order_index
    )
    INTO v_topics
    FROM topics t
    WHERE t.curriculum_id = p_curriculum_id AND t.parent_id IS NULL;

    -- Build glossary
    SELECT jsonb_build_object(
        'terms', jsonb_agg(
            jsonb_build_object(
                'id', gt.term_id,
                'term', gt.term,
                'pronunciation', gt.pronunciation,
                'definition', gt.definition,
                'spokenDefinition', gt.spoken_definition,
                'simpleDefinition', gt.simple_definition,
                'examples', gt.examples,
                'relatedTerms', gt.related_terms
            )
        )
    )
    INTO v_glossary
    FROM glossary_terms gt
    WHERE gt.curriculum_id = p_curriculum_id;

    -- Build full UMCF document
    v_result := jsonb_build_object(
        'umcf', '1.0.0',
        'id', jsonb_build_object(
            'catalog', v_curriculum.catalog,
            'value', v_curriculum.external_id
        ),
        'title', v_curriculum.title,
        'description', v_curriculum.description,
        'version', jsonb_build_object(
            'number', v_curriculum.version_number,
            'date', v_curriculum.version_date,
            'changelog', v_curriculum.version_changelog
        ),
        'lifecycle', jsonb_build_object(
            'status', v_curriculum.lifecycle_status,
            'created', v_curriculum.created_at,
            'modified', v_curriculum.updated_at,
            'contributors', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'name', cc.name,
                        'role', cc.role,
                        'organization', cc.organization
                    )
                )
                FROM curriculum_contributors cc
                WHERE cc.curriculum_id = p_curriculum_id
            )
        ),
        'metadata', jsonb_build_object(
            'language', v_curriculum.language,
            'keywords', v_curriculum.keywords,
            'subject', v_curriculum.subjects
        ),
        'educational', jsonb_build_object(
            'difficulty', v_curriculum.difficulty,
            'typicalAgeRange', v_curriculum.age_range,
            'typicalLearningTime', v_curriculum.typical_learning_time,
            'alignment', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'alignmentType', ca.alignment_type,
                        'educationalFramework', ca.framework_name,
                        'targetName', ca.target_name,
                        'targetDescription', ca.target_description,
                        'targetUrl', ca.target_url
                    )
                )
                FROM curriculum_alignments ca
                WHERE ca.curriculum_id = p_curriculum_id
            ),
            'prerequisites', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'description', cp.description,
                        'type', cp.prerequisite_type,
                        'required', cp.is_required
                    )
                )
                FROM curriculum_prerequisites cp
                WHERE cp.curriculum_id = p_curriculum_id
            )
        ),
        'content', COALESCE(v_topics, '[]'::jsonb),
        'glossary', COALESCE(v_glossary, jsonb_build_object('terms', '[]'::jsonb))
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to update JSON cache
CREATE OR REPLACE FUNCTION update_curriculum_json_cache()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the curriculum's JSON cache
    UPDATE curricula
    SET json_cache = build_umcf_json(NEW.curriculum_id),
        json_cache_updated_at = NOW()
    WHERE id = NEW.curriculum_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update JSON cache when content changes
CREATE TRIGGER trg_update_cache_on_topic_change
    AFTER INSERT OR UPDATE OR DELETE ON topics
    FOR EACH ROW
    EXECUTE FUNCTION update_curriculum_json_cache();

CREATE TRIGGER trg_update_cache_on_segment_change
    AFTER INSERT OR UPDATE OR DELETE ON transcript_segments
    FOR EACH ROW
    EXECUTE FUNCTION update_curriculum_json_cache();

CREATE TRIGGER trg_update_cache_on_objective_change
    AFTER INSERT OR UPDATE OR DELETE ON learning_objectives
    FOR EACH ROW
    EXECUTE FUNCTION update_curriculum_json_cache();

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- View for curriculum summaries (fast listing)
CREATE VIEW curriculum_summaries AS
SELECT
    c.id,
    c.external_id,
    c.title,
    c.description,
    c.version_number,
    c.difficulty,
    c.age_range,
    c.typical_learning_time,
    c.keywords,
    c.lifecycle_status,
    c.updated_at,
    (SELECT COUNT(*) FROM topics t WHERE t.curriculum_id = c.id) as topic_count,
    (SELECT COUNT(*) FROM glossary_terms gt WHERE gt.curriculum_id = c.id) as glossary_count,
    (SELECT COUNT(*) FROM transcript_segments ts
     JOIN topics t ON ts.topic_id = t.id
     WHERE t.curriculum_id = c.id) as segment_count
FROM curricula c;

-- View for topic details with segment counts
CREATE VIEW topic_details AS
SELECT
    t.id,
    t.external_id,
    t.curriculum_id,
    t.title,
    t.description,
    t.content_type,
    t.order_index,
    t.content_depth,
    (SELECT COUNT(*) FROM transcript_segments ts WHERE ts.topic_id = t.id) as segment_count,
    (SELECT COUNT(*) FROM assessments a WHERE a.topic_id = t.id) as assessment_count,
    (SELECT COUNT(*) FROM examples e WHERE e.topic_id = t.id) as example_count,
    EXISTS(SELECT 1 FROM transcript_segments ts WHERE ts.topic_id = t.id) as has_transcript
FROM topics t;

-- ============================================================================
-- SAMPLE DATA (for testing)
-- ============================================================================

-- Insert a sample curriculum for testing
-- (This would be populated by importing existing UMCF files)

COMMENT ON TABLE curricula IS 'Top-level curriculum containers for UMCF documents';
COMMENT ON TABLE topics IS 'Hierarchical content units within a curriculum';
COMMENT ON TABLE transcript_segments IS 'Individual speakable content pieces with TTS metadata';
COMMENT ON TABLE glossary_terms IS 'Vocabulary definitions for a curriculum';
COMMENT ON TABLE assessments IS 'Questions and quizzes for learner assessment';
COMMENT ON FUNCTION build_umcf_json IS 'Reconstructs full UMCF JSON from normalized tables';
