-- ============================================================
-- Migration: Fix get_cached_insight RPC Function
-- Date: 2025-10-24
-- Purpose: Add missing expires_at field to function return type
-- ============================================================

-- Issue: The get_cached_insight function was missing expires_at in its
-- RETURNS TABLE definition, causing the edge function to fail when trying
-- to access cached.expires_at.
--
-- Fix: Drop and recreate the function with expires_at included.

-- ============================================================
-- 1. DROP EXISTING FUNCTION
-- ============================================================

DROP FUNCTION IF EXISTS get_cached_insight(uuid, text, timestamptz, timestamptz);

-- ============================================================
-- 2. RECREATE FUNCTION WITH CORRECT RETURN TYPE
-- ============================================================

CREATE OR REPLACE FUNCTION get_cached_insight(
  p_user_id uuid,
  p_insight_type text,
  p_date_start timestamptz DEFAULT NULL,
  p_date_end timestamptz DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  content jsonb,
  generated_at timestamptz,
  entries_analyzed_count int,
  expires_at timestamptz  -- ✅ ADDED: This was missing!
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ui.id,
    ui.content,
    ui.generated_at,
    ui.entries_analyzed_count,
    ui.expires_at  -- ✅ ADDED: This was missing!
  FROM user_insights ui
  WHERE ui.user_id = p_user_id
    AND ui.insight_type = p_insight_type
    AND ui.is_valid = true
    AND (ui.expires_at IS NULL OR ui.expires_at > now())
    AND (p_date_start IS NULL OR ui.date_range_start = p_date_start)
    AND (p_date_end IS NULL OR ui.date_range_end = p_date_end)
  ORDER BY ui.generated_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 3. ADD HELPFUL COMMENT
-- ============================================================

COMMENT ON FUNCTION get_cached_insight IS 'Returns valid cached insight for user, now includes expires_at field';

-- ============================================================
-- 4. VALIDATION
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '✅ get_cached_insight function updated successfully';
  RAISE NOTICE '   - Added expires_at to RETURNS TABLE';
  RAISE NOTICE '   - Added ui.expires_at to SELECT statement';
  RAISE NOTICE '   - Function signature: get_cached_insight(uuid, text, timestamptz, timestamptz)';
END $$;
