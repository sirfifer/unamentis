-- ============================================================================
-- Knowledge Bowl Questions Tables Migration
-- ============================================================================
--
-- This migration adds tables for:
-- - KB Questions (complete question database with all metadata)
-- - KB Packs (question collections/bundles)
-- - KB Pack Questions (many-to-many relationship)
-- - KB Domains (reference data for domains)
--
-- Apply with: psql $DATABASE_URL < migrations/003_kb_questions_tables.sql
--
-- ============================================================================

-- Ensure required extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- KB DOMAINS (Reference Data)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kb_domains (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon_name VARCHAR(100),
    weight REAL DEFAULT 0.1,
    subcategories TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kb_domains_name ON kb_domains(name);

COMMENT ON TABLE kb_domains IS 'Knowledge Bowl domain categories (science, history, etc.)';

-- Seed default domains
INSERT INTO kb_domains (id, name, icon_name, weight, subcategories) VALUES
    ('science', 'Science', 'atom', 0.2, ARRAY['Physics', 'Chemistry', 'Biology', 'Earth Science', 'Astronomy', 'Computer Science']),
    ('mathematics', 'Mathematics', 'function', 0.15, ARRAY['Algebra', 'Geometry', 'Calculus', 'Statistics', 'Number Theory', 'Trigonometry']),
    ('literature', 'Literature', 'book', 0.12, ARRAY['American Literature', 'British Literature', 'World Literature', 'Poetry', 'Drama']),
    ('history', 'History', 'clock.arrow.circlepath', 0.12, ARRAY['US History', 'World History', 'Ancient History', 'Modern History', 'Military History']),
    ('social_studies', 'Social Studies', 'globe.americas', 0.1, ARRAY['Geography', 'Government', 'Economics', 'Civics', 'Psychology']),
    ('arts', 'Fine Arts', 'paintpalette', 0.08, ARRAY['Visual Arts', 'Music', 'Theater', 'Architecture', 'Film']),
    ('current_events', 'Current Events', 'newspaper', 0.08, ARRAY['Politics', 'International', 'Science News', 'Business']),
    ('language', 'Language', 'textformat', 0.05, ARRAY['Grammar', 'Vocabulary', 'Etymology', 'Foreign Languages']),
    ('technology', 'Technology', 'desktopcomputer', 0.04, ARRAY['Computer Science', 'Engineering', 'Inventions', 'Internet']),
    ('pop_culture', 'Pop Culture', 'star', 0.03, ARRAY['Movies', 'Television', 'Music', 'Sports']),
    ('religion_philosophy', 'Religion & Philosophy', 'sparkles', 0.02, ARRAY['World Religions', 'Philosophy', 'Mythology', 'Ethics']),
    ('miscellaneous', 'Miscellaneous', 'questionmark.diamond', 0.01, ARRAY['General Knowledge', 'Trivia', 'Cross-Domain'])
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    weight = EXCLUDED.weight,
    subcategories = EXCLUDED.subcategories,
    updated_at = NOW();

-- ============================================================================
-- KB QUESTIONS (Main Question Table)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kb_questions (
    id VARCHAR(100) PRIMARY KEY,

    -- Core content
    domain_id VARCHAR(50) NOT NULL REFERENCES kb_domains(id),
    subcategory VARCHAR(100) DEFAULT 'General',
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    acceptable_answers TEXT[] DEFAULT '{}',

    -- Difficulty and timing
    difficulty INTEGER NOT NULL CHECK (difficulty >= 1 AND difficulty <= 5),
    difficulty_tier VARCHAR(20) CHECK (difficulty_tier IN (
        'elementary', 'middle_school', 'jv', 'varsity', 'championship', 'college'
    )),
    speed_target_seconds REAL DEFAULT 5.0,

    -- Question metadata
    question_type VARCHAR(20) DEFAULT 'toss_up' CHECK (question_type IN (
        'toss_up', 'bonus', 'pyramid', 'lightning'
    )),
    question_source VARCHAR(20) DEFAULT 'custom' CHECK (question_source IN (
        'naqt', 'nsb', 'qb_packets', 'custom', 'ai_generated'
    )),
    competition_year VARCHAR(20),
    buzzable BOOLEAN DEFAULT true,

    -- Educational content
    hints TEXT[] DEFAULT '{}',
    explanation TEXT,

    -- Audio status
    has_audio BOOLEAN DEFAULT false,
    audio_question_path VARCHAR(500),
    audio_answer_path VARCHAR(500),
    audio_explanation_path VARCHAR(500),

    -- Status and audit
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'draft', 'archived')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Full-text search
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(question_text, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(answer_text, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(explanation, '')), 'C')
    ) STORED
);

-- Indexes for KB Questions
CREATE INDEX IF NOT EXISTS idx_kb_questions_domain ON kb_questions(domain_id);
CREATE INDEX IF NOT EXISTS idx_kb_questions_difficulty ON kb_questions(difficulty);
CREATE INDEX IF NOT EXISTS idx_kb_questions_difficulty_tier ON kb_questions(difficulty_tier);
CREATE INDEX IF NOT EXISTS idx_kb_questions_type ON kb_questions(question_type);
CREATE INDEX IF NOT EXISTS idx_kb_questions_source ON kb_questions(question_source);
CREATE INDEX IF NOT EXISTS idx_kb_questions_status ON kb_questions(status);
CREATE INDEX IF NOT EXISTS idx_kb_questions_has_audio ON kb_questions(has_audio);
CREATE INDEX IF NOT EXISTS idx_kb_questions_search ON kb_questions USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_kb_questions_subcategory ON kb_questions(domain_id, subcategory);
CREATE INDEX IF NOT EXISTS idx_kb_questions_created ON kb_questions(created_at DESC);

COMMENT ON TABLE kb_questions IS 'Knowledge Bowl questions with full metadata and search support';
COMMENT ON COLUMN kb_questions.difficulty IS 'Numeric difficulty 1-5 (1=easiest, 5=hardest)';
COMMENT ON COLUMN kb_questions.difficulty_tier IS 'Competition level: elementary through college';
COMMENT ON COLUMN kb_questions.acceptable_answers IS 'Array of acceptable answer variations';
COMMENT ON COLUMN kb_questions.buzzable IS 'Whether question can be interrupted for early answer';

-- ============================================================================
-- KB PACKS (Question Collections)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kb_packs (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Pack metadata
    type VARCHAR(20) DEFAULT 'custom' CHECK (type IN ('system', 'custom', 'bundle')),
    difficulty_tier VARCHAR(20) CHECK (difficulty_tier IN (
        'elementary', 'middle_school', 'jv', 'varsity', 'championship', 'college'
    )),
    competition_year VARCHAR(20),

    -- For bundles
    source_pack_ids TEXT[],
    is_reference_bundle BOOLEAN DEFAULT false,

    -- Status and audit
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('active', 'draft', 'archived')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_kb_packs_type ON kb_packs(type);
CREATE INDEX IF NOT EXISTS idx_kb_packs_status ON kb_packs(status);
CREATE INDEX IF NOT EXISTS idx_kb_packs_difficulty_tier ON kb_packs(difficulty_tier);
CREATE INDEX IF NOT EXISTS idx_kb_packs_created ON kb_packs(created_at DESC);

COMMENT ON TABLE kb_packs IS 'Question packs/bundles for organizing questions';
COMMENT ON COLUMN kb_packs.type IS 'system=built-in, custom=user-created, bundle=aggregated from other packs';
COMMENT ON COLUMN kb_packs.source_pack_ids IS 'For bundles: IDs of packs this bundle was created from';

-- ============================================================================
-- KB PACK QUESTIONS (Many-to-Many)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kb_pack_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pack_id VARCHAR(100) NOT NULL REFERENCES kb_packs(id) ON DELETE CASCADE,
    question_id VARCHAR(100) NOT NULL REFERENCES kb_questions(id) ON DELETE CASCADE,
    position INTEGER DEFAULT 0,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(pack_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_kb_pack_questions_pack ON kb_pack_questions(pack_id);
CREATE INDEX IF NOT EXISTS idx_kb_pack_questions_question ON kb_pack_questions(question_id);
CREATE INDEX IF NOT EXISTS idx_kb_pack_questions_position ON kb_pack_questions(pack_id, position);

COMMENT ON TABLE kb_pack_questions IS 'Association between packs and questions with ordering';

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Questions with domain info and pack count
CREATE OR REPLACE VIEW kb_questions_view AS
SELECT
    q.*,
    d.name as domain_name,
    d.icon_name as domain_icon,
    (SELECT COUNT(*) FROM kb_pack_questions pq WHERE pq.question_id = q.id) as pack_count
FROM kb_questions q
JOIN kb_domains d ON q.domain_id = d.id;

-- Pack summaries with question stats
CREATE OR REPLACE VIEW kb_pack_summaries AS
SELECT
    p.*,
    COALESCE(stats.question_count, 0) as question_count,
    COALESCE(stats.domain_count, 0) as domain_count,
    COALESCE(stats.audio_count, 0) as audio_count,
    CASE WHEN COALESCE(stats.question_count, 0) > 0
         THEN ROUND((stats.audio_count::numeric / stats.question_count) * 100, 1)
         ELSE 0
    END as audio_coverage_percent
FROM kb_packs p
LEFT JOIN LATERAL (
    SELECT
        COUNT(DISTINCT pq.question_id) as question_count,
        COUNT(DISTINCT q.domain_id) as domain_count,
        COUNT(DISTINCT CASE WHEN q.has_audio THEN q.id END) as audio_count
    FROM kb_pack_questions pq
    JOIN kb_questions q ON pq.question_id = q.id
    WHERE pq.pack_id = p.id
) stats ON true;

COMMENT ON VIEW kb_questions_view IS 'Questions with domain details and pack membership count';
COMMENT ON VIEW kb_pack_summaries IS 'Packs with computed statistics';

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get difficulty distribution for a pack
CREATE OR REPLACE FUNCTION kb_pack_difficulty_distribution(p_pack_id VARCHAR)
RETURNS TABLE(difficulty INTEGER, count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT q.difficulty, COUNT(*)
    FROM kb_pack_questions pq
    JOIN kb_questions q ON pq.question_id = q.id
    WHERE pq.pack_id = p_pack_id
    GROUP BY q.difficulty
    ORDER BY q.difficulty;
END;
$$ LANGUAGE plpgsql;

-- Function to get domain distribution for a pack
CREATE OR REPLACE FUNCTION kb_pack_domain_distribution(p_pack_id VARCHAR)
RETURNS TABLE(domain_id VARCHAR, domain_name VARCHAR, count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT q.domain_id, d.name, COUNT(*)
    FROM kb_pack_questions pq
    JOIN kb_questions q ON pq.question_id = q.id
    JOIN kb_domains d ON q.domain_id = d.id
    WHERE pq.pack_id = p_pack_id
    GROUP BY q.domain_id, d.name
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at
CREATE TRIGGER update_kb_questions_updated_at
    BEFORE UPDATE ON kb_questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kb_packs_updated_at
    BEFORE UPDATE ON kb_packs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kb_domains_updated_at
    BEFORE UPDATE ON kb_domains
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Migration complete
-- ============================================================================

DO $$ BEGIN RAISE NOTICE 'KB Questions tables migration complete'; END $$;
