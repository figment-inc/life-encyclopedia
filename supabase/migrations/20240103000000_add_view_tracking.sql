-- Add view tracking columns to people table
-- This migration adds view_count and last_viewed_at for sorting by popularity and trending

-- Add view_count column with default of 0
ALTER TABLE people ADD COLUMN view_count INTEGER NOT NULL DEFAULT 0;

-- Add last_viewed_at timestamp for tracking when entry was last viewed
ALTER TABLE people ADD COLUMN last_viewed_at TIMESTAMPTZ;

-- Create index for popular sorting (by view count descending)
CREATE INDEX idx_people_view_count ON people (view_count DESC);

-- Create policy to allow public updates for view tracking
-- This allows incrementing view_count without authentication
CREATE POLICY "Allow public update for view tracking" ON people
    FOR UPDATE
    USING (true)
    WITH CHECK (true);
