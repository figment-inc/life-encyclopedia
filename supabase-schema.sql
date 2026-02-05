-- Supabase Schema for Life Encyclopedia
-- Run this in your Supabase SQL Editor to set up the database

-- Create the people table
CREATE TABLE IF NOT EXISTS people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    birth_date TEXT,
    death_date TEXT,
    summary TEXT NOT NULL,
    events JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    view_count INTEGER NOT NULL DEFAULT 0,
    last_viewed_at TIMESTAMPTZ
);

-- Create an index for faster queries by name
CREATE INDEX IF NOT EXISTS idx_people_name ON people (name);

-- Create an index for sorting by creation date
CREATE INDEX IF NOT EXISTS idx_people_created_at ON people (created_at DESC);

-- Create an index for sorting by view count (popular)
CREATE INDEX IF NOT EXISTS idx_people_view_count ON people (view_count DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE people ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read
CREATE POLICY "Allow public read access" ON people
    FOR SELECT
    USING (true);

-- Create a policy that allows anyone to insert
CREATE POLICY "Allow public insert access" ON people
    FOR INSERT
    WITH CHECK (true);

-- Create a policy that allows anyone to delete
CREATE POLICY "Allow public delete access" ON people
    FOR DELETE
    USING (true);

-- Create a policy that allows anyone to update (for view tracking)
CREATE POLICY "Allow public update for view tracking" ON people
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- Example: Insert a sample person (optional, for testing)
-- INSERT INTO people (name, birth_date, death_date, summary, events) VALUES (
--     'Albert Einstein',
--     '1879',
--     '1955',
--     'German-born theoretical physicist who developed the theory of relativity.',
--     '[
--         {
--             "id": "550e8400-e29b-41d4-a716-446655440000",
--             "date": "March 14, 1879",
--             "title": "Birth in Ulm, Germany",
--             "description": "Albert Einstein was born in Ulm, Germany.",
--             "citation": "Wikipedia",
--             "sourceURL": "https://en.wikipedia.org/wiki/Albert_Einstein"
--         }
--     ]'::jsonb
-- );
