-- ============================================================
-- Migration: Create journal_insights table
-- Purpose: Store AI-generated insights with milestone versioning
-- Date: 2025-10-26
-- ============================================================

-- Create journal_insights table
CREATE TABLE IF NOT EXISTS journal_insights (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- User reference (foreign key to auth.users)
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Milestone tracking (3, 6, 9, 12, etc.)
  entry_count_milestone INT NOT NULL CHECK (entry_count_milestone > 0),

  -- Insight content
  summary TEXT NOT NULL,
  description TEXT NOT NULL,
  themes JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Metadata
  entries_analyzed INT NOT NULL CHECK (entries_analyzed > 0),
  generated_at TIMESTAMPTZ NOT NULL,
  from_cache BOOLEAN NOT NULL DEFAULT false,
  cache_expires_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Unique constraint: one insight per user per milestone
  UNIQUE(user_id, entry_count_milestone)
);

-- ============================================================
-- Indexes for performance
-- ============================================================

-- Index for querying user's insights by milestone (most common query)
CREATE INDEX IF NOT EXISTS idx_insights_user_milestone
  ON journal_insights(user_id, entry_count_milestone DESC);

-- Index for fetching latest insights (sorted by generation time)
CREATE INDEX IF NOT EXISTS idx_insights_generated_at
  ON journal_insights(generated_at DESC);

-- Index for finding insights by user (for real-time subscriptions)
CREATE INDEX IF NOT EXISTS idx_insights_user_id
  ON journal_insights(user_id);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

-- Enable RLS
ALTER TABLE journal_insights ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own insights
CREATE POLICY "Users can view their own insights"
  ON journal_insights
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own insights
CREATE POLICY "Users can insert their own insights"
  ON journal_insights
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own insights
CREATE POLICY "Users can update their own insights"
  ON journal_insights
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own insights
CREATE POLICY "Users can delete their own insights"
  ON journal_insights
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- Trigger: Auto-update updated_at timestamp
-- ============================================================

-- Create or replace function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for journal_insights
DROP TRIGGER IF EXISTS update_journal_insights_updated_at ON journal_insights;
CREATE TRIGGER update_journal_insights_updated_at
  BEFORE UPDATE ON journal_insights
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Enable Realtime for cross-device sync
-- ============================================================

-- Enable realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE journal_insights;

-- ============================================================
-- Verification queries (run these to verify the migration)
-- ============================================================

-- Verify table structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'journal_insights'
-- ORDER BY ordinal_position;

-- Verify indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'journal_insights';

-- Verify RLS policies
-- SELECT policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'journal_insights';

-- ============================================================
-- Rollback (if needed)
-- ============================================================

-- To rollback this migration, run:
-- DROP TABLE IF EXISTS journal_insights CASCADE;
-- DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
