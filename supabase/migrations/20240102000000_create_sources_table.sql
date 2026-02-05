-- Migration: Create sources table and event_sources junction table
-- Description: Adds normalized source storage with reliability scoring and event-source relationships

-- Create sources table for storing authoritative sources
CREATE TABLE IF NOT EXISTS sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    source_type TEXT NOT NULL DEFAULT 'unknown',
    publisher TEXT,
    author TEXT,
    publish_date TEXT,
    access_date TIMESTAMPTZ DEFAULT NOW(),
    reliability_score DECIMAL(3,2) DEFAULT 0.50 CHECK (reliability_score >= 0 AND reliability_score <= 1),
    content_snippet TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique index on URL to prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_sources_url ON sources(url);

-- Create index on source_type for filtering
CREATE INDEX IF NOT EXISTS idx_sources_type ON sources(source_type);

-- Create index on reliability_score for sorting
CREATE INDEX IF NOT EXISTS idx_sources_reliability ON sources(reliability_score DESC);

-- Create event_sources junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS event_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    source_id UUID NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, source_id)
);

-- Create indexes for event_sources lookups
CREATE INDEX IF NOT EXISTS idx_event_sources_event ON event_sources(event_id);
CREATE INDEX IF NOT EXISTS idx_event_sources_source ON event_sources(source_id);
CREATE INDEX IF NOT EXISTS idx_event_sources_person ON event_sources(person_id);

-- Enable RLS on sources table
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;

-- Create policies for sources (public read, authenticated write)
CREATE POLICY "Allow public read access to sources"
    ON sources FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert access to sources"
    ON sources FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public update access to sources"
    ON sources FOR UPDATE
    USING (true);

-- Enable RLS on event_sources table
ALTER TABLE event_sources ENABLE ROW LEVEL SECURITY;

-- Create policies for event_sources
CREATE POLICY "Allow public read access to event_sources"
    ON event_sources FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert access to event_sources"
    ON event_sources FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public delete access to event_sources"
    ON event_sources FOR DELETE
    USING (true);

-- Add verification fields to people.events JSONB
-- Note: This is handled at the application level since events are stored as JSONB
-- The JSONB structure now includes:
-- - eventType: string (birth|childhood|education|career|personal|achievement|death|historical)
-- - datePrecision: string (exact|monthYear|yearOnly|approximate|decade|unknown)
-- - verificationStatus: string (verified|corroborated|unverified|disputed)
-- - confidenceScore: number (0.0 to 1.0)
-- - sources: array of source references

-- Create function to upsert sources (insert or return existing)
CREATE OR REPLACE FUNCTION upsert_source(
    p_title TEXT,
    p_url TEXT,
    p_source_type TEXT DEFAULT 'unknown',
    p_publisher TEXT DEFAULT NULL,
    p_reliability_score DECIMAL DEFAULT 0.50,
    p_content_snippet TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_source_id UUID;
BEGIN
    -- Try to find existing source by URL
    SELECT id INTO v_source_id FROM sources WHERE url = p_url;
    
    -- If not found, insert new source
    IF v_source_id IS NULL THEN
        INSERT INTO sources (title, url, source_type, publisher, reliability_score, content_snippet)
        VALUES (p_title, p_url, p_source_type, p_publisher, p_reliability_score, p_content_snippet)
        RETURNING id INTO v_source_id;
    END IF;
    
    RETURN v_source_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to get sources for a person's events
CREATE OR REPLACE FUNCTION get_person_sources(p_person_id UUID)
RETURNS TABLE (
    source_id UUID,
    title TEXT,
    url TEXT,
    source_type TEXT,
    reliability_score DECIMAL,
    event_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as source_id,
        s.title,
        s.url,
        s.source_type,
        s.reliability_score,
        COUNT(es.event_id) as event_count
    FROM sources s
    JOIN event_sources es ON s.id = es.source_id
    WHERE es.person_id = p_person_id
    GROUP BY s.id, s.title, s.url, s.source_type, s.reliability_score
    ORDER BY s.reliability_score DESC, event_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Add comment explaining the schema
COMMENT ON TABLE sources IS 'Stores authoritative sources for historical events with reliability scoring';
COMMENT ON TABLE event_sources IS 'Junction table linking events (stored in people.events JSONB) to sources';
COMMENT ON COLUMN sources.reliability_score IS 'Reliability score from 0.0 to 1.0 based on source type and domain authority';
COMMENT ON COLUMN sources.source_type IS 'Type: wikipedia, news, academic, biography, official, archive, encyclopedia, unknown';
