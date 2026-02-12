-- Add search and discovery performance indexes for server-side filtering.

-- Trigram support improves fuzzy/partial name matching.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Case-insensitive partial search on name.
CREATE INDEX IF NOT EXISTS idx_people_name_trgm
ON people USING GIN (lower(name) gin_trgm_ops);

-- Ranked full-text search across name + summary.
CREATE INDEX IF NOT EXISTS idx_people_name_summary_tsv
ON people USING GIN (
    to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(summary, ''))
);

-- Keep common sort and high-signal filters fast.
CREATE INDEX IF NOT EXISTS idx_people_created_at_desc
ON people (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_people_historical_period
ON people ((filter_metadata->>'historicalPeriod'));

CREATE INDEX IF NOT EXISTS idx_people_moral_valence
ON people ((filter_metadata->>'moralValence'));

CREATE INDEX IF NOT EXISTS idx_people_life_arc
ON people ((filter_metadata->>'lifeArc'));
