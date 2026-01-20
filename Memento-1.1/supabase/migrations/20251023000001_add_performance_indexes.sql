-- ============================================================
-- Migration: Add Performance Indexes
-- Date: 2025-10-23
-- Purpose: Add indexes for common query patterns and full-text search
-- ============================================================

-- ============================================================
-- 1. FULL-TEXT SEARCH ON ENTRIES
-- ============================================================

-- Create full-text search index on entry text (for AI insights and search)
-- This enables fast keyword matching for theme analysis
CREATE INDEX IF NOT EXISTS idx_entries_text_fts
  ON entries USING gin(to_tsvector('english', text));

-- Create full-text search index on entry title
CREATE INDEX IF NOT EXISTS idx_entries_title_fts
  ON entries USING gin(to_tsvector('english', title));

-- Combined full-text search on both title and text
CREATE INDEX IF NOT EXISTS idx_entries_full_text_search
  ON entries USING gin(
    to_tsvector('english', coalesce(title, '') || ' ' || text)
  );

-- ============================================================
-- 2. OPTIMIZE EXISTING INDEXES
-- ============================================================

-- Verify and recreate composite user + date index (most common query)
DROP INDEX IF EXISTS idx_entries_user_created;
CREATE INDEX IF NOT EXISTS idx_entries_user_created_desc
  ON entries(user_id, created_at DESC);

-- Composite index also works for date range queries
-- Note: Partial indexes with time-based predicates are not supported
-- because they require IMMUTABLE functions. The composite index above
-- is sufficient for efficient date range queries.

-- ============================================================
-- 3. USER PROFILES INDEXES
-- ============================================================

-- GIN index for array containment queries on themes
CREATE INDEX IF NOT EXISTS idx_user_profiles_themes_gin
  ON user_profiles USING gin(identified_themes);

-- Index for finding users who completed theme analysis
CREATE INDEX IF NOT EXISTS idx_user_profiles_theme_analyzed
  ON user_profiles(themes_analyzed_at)
  WHERE themes_analyzed_at IS NOT NULL;

-- ============================================================
-- 4. THEMES TABLE INDEXES
-- ============================================================

-- GIN index for keyword array searches
CREATE INDEX IF NOT EXISTS idx_themes_keywords_gin
  ON themes USING gin(keywords);

-- Index for category filtering
CREATE INDEX IF NOT EXISTS idx_themes_category
  ON themes(category);

-- ============================================================
-- 5. ADD HELPER FUNCTIONS FOR SEARCH
-- ============================================================

-- Function to search entries by keywords
CREATE OR REPLACE FUNCTION search_entries(
  p_user_id uuid,
  p_query text,
  p_limit int DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  title text,
  text text,
  created_at timestamptz,
  updated_at timestamptz,
  rank real
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.text,
    e.created_at,
    e.updated_at,
    ts_rank(
      to_tsvector('english', coalesce(e.title, '') || ' ' || e.text),
      plainto_tsquery('english', p_query)
    ) AS rank
  FROM entries e
  WHERE e.user_id = p_user_id
    AND to_tsvector('english', coalesce(e.title, '') || ' ' || e.text) @@ plainto_tsquery('english', p_query)
  ORDER BY rank DESC, e.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get entries by date range (for insights generation)
CREATE OR REPLACE FUNCTION get_entries_by_date_range(
  p_user_id uuid,
  p_start_date timestamptz,
  p_end_date timestamptz
)
RETURNS TABLE (
  id uuid,
  title text,
  text text,
  created_at timestamptz,
  word_count int
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.text,
    e.created_at,
    array_length(regexp_split_to_array(e.text, '\s+'), 1) AS word_count
  FROM entries e
  WHERE e.user_id = p_user_id
    AND e.created_at >= p_start_date
    AND e.created_at < p_end_date
  ORDER BY e.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get entries matching specific themes
CREATE OR REPLACE FUNCTION get_entries_by_themes(
  p_user_id uuid,
  p_theme_keywords text[],
  p_limit int DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  title text,
  text text,
  created_at timestamptz,
  matched_keywords text[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.title,
    e.text,
    e.created_at,
    ARRAY(
      SELECT keyword
      FROM unnest(p_theme_keywords) AS keyword
      WHERE e.text ILIKE '%' || keyword || '%'
    ) AS matched_keywords
  FROM entries e
  WHERE e.user_id = p_user_id
    AND EXISTS (
      SELECT 1
      FROM unnest(p_theme_keywords) AS keyword
      WHERE e.text ILIKE '%' || keyword || '%'
    )
  ORDER BY e.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. ANALYZE TABLES FOR QUERY PLANNER
-- ============================================================

-- Update table statistics for optimal query planning
ANALYZE entries;
ANALYZE user_profiles;
ANALYZE themes;

-- ============================================================
-- 7. VALIDATION & PERFORMANCE TESTING
-- ============================================================

DO $$
DECLARE
  entries_count INTEGER;
  index_count INTEGER;
  test_start TIMESTAMP;
  test_end TIMESTAMP;
BEGIN
  -- Count entries for baseline
  SELECT COUNT(*) INTO entries_count FROM entries;

  -- Count indexes on entries table
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE tablename = 'entries';

  -- Test search performance (if entries exist)
  IF entries_count > 0 THEN
    test_start := clock_timestamp();
    PERFORM * FROM entries
    WHERE to_tsvector('english', text) @@ plainto_tsquery('english', 'test')
    LIMIT 10;
    test_end := clock_timestamp();

    RAISE NOTICE '📊 Performance test: Full-text search took % ms',
      EXTRACT(MILLISECONDS FROM (test_end - test_start));
  END IF;

  RAISE NOTICE '✅ Performance indexes added successfully';
  RAISE NOTICE '   - Added % indexes to entries table', index_count;
  RAISE NOTICE '   - Full-text search enabled on title and text';
  RAISE NOTICE '   - Theme keyword matching optimized';
  RAISE NOTICE '   - Added 3 helper functions for search and insights';
END $$;
