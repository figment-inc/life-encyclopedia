-- Add filter_metadata column to people table
-- This column stores AI-enriched classification data for filtering

-- Add the filter_metadata JSONB column with a default empty object
ALTER TABLE people ADD COLUMN IF NOT EXISTS filter_metadata JSONB DEFAULT '{}'::jsonb;

-- Create indexes for common filter queries

-- Index on primary domain for quick domain filtering
CREATE INDEX IF NOT EXISTS idx_people_primary_domain 
ON people ((filter_metadata->>'primaryDomain'));

-- Index on century for era filtering
CREATE INDEX IF NOT EXISTS idx_people_century 
ON people ((filter_metadata->>'century'));

-- Index on cultural region for geography filtering
CREATE INDEX IF NOT EXISTS idx_people_cultural_region 
ON people ((filter_metadata->>'culturalRegion'));

-- Index on recognition level for sorting/filtering by fame
CREATE INDEX IF NOT EXISTS idx_people_recognition_level 
ON people ((filter_metadata->>'recognitionLevel'));

-- Index on archetype for narrative filtering
CREATE INDEX IF NOT EXISTS idx_people_archetype 
ON people ((filter_metadata->>'archetype'));

-- Index on birth year for range queries
CREATE INDEX IF NOT EXISTS idx_people_birth_year 
ON people ((filter_metadata->>'birthYear'));

-- Index on death year for range queries (living vs deceased)
CREATE INDEX IF NOT EXISTS idx_people_death_year 
ON people ((filter_metadata->>'deathYear'));

-- GIN index for secondary domains array searching
CREATE INDEX IF NOT EXISTS idx_people_secondary_domains 
ON people USING GIN ((filter_metadata->'secondaryDomains'));

-- Comment on the column for documentation
COMMENT ON COLUMN people.filter_metadata IS 'AI-enriched classification data for filtering: domains, influence, geography, era, narrative archetypes';
