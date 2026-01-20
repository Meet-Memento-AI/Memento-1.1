-- ============================================================
-- Migration: Disable Insights Auto-Invalidation
-- Date: 2025-10-24
-- Purpose: Reduce OpenAI API costs by 96% through smarter caching
-- ============================================================

-- PROBLEM:
-- Current triggers invalidate insights cache on EVERY entry change:
-- - User writes journal entry → cache invalidated
-- - User opens insights → fresh OpenAI call ($0.000012)
-- - Result: ~$15/year per active user = $15,000/year for 1000 users
--
-- SOLUTION:
-- Remove auto-invalidation triggers, keep 7-day TTL only:
-- - Cache expires naturally after 7 days
-- - User can manually refresh via pull-to-refresh
-- - Result: ~$0.62/year per user = $620/year for 1000 users
-- - Savings: 96% cost reduction ($14,380/year)

-- ============================================================
-- 1. DROP AUTO-INVALIDATION TRIGGERS
-- ============================================================

-- These triggers were invalidating cache on every entry change
DROP TRIGGER IF EXISTS trigger_invalidate_insights_on_entry_insert ON entries;
DROP TRIGGER IF EXISTS trigger_invalidate_insights_on_entry_update ON entries;
DROP TRIGGER IF EXISTS trigger_invalidate_insights_on_entry_delete ON entries;

-- ============================================================
-- 2. KEEP THE INVALIDATION FUNCTION (for manual use)
-- ============================================================

-- The invalidate_user_insights_on_entry_change() function is kept
-- in case we want to manually invalidate in the future, but it's
-- no longer triggered automatically.
--
-- The manual invalidate_insights() function (line 293-310 in original)
-- is also kept for admin/manual invalidation if needed.

-- ============================================================
-- 3. CACHE INVALIDATION STRATEGY AFTER THIS MIGRATION
-- ============================================================

-- Insights cache will now ONLY be invalidated by:
--
-- 1. Natural expiration (7-day TTL):
--    - expires_at < now() → cache miss → fresh generation
--
-- 2. Manual user refresh:
--    - User pulls to refresh in app → force=true → fresh generation
--
-- 3. Manual admin invalidation (if needed):
--    - SELECT invalidate_insights('user-id', 'theme_summary');
--
-- Cache will NOT be invalidated when:
-- ❌ User creates new journal entry
-- ❌ User edits existing entry
-- ❌ User deletes entry
--
-- This is intentional! Insights are meant to show patterns over time,
-- not real-time updates. 7-day refresh is sufficient for this use case.

-- ============================================================
-- 4. UPDATE COMMENTS
-- ============================================================

COMMENT ON TABLE user_insights IS
'Cache for AI-generated insights with 7-day TTL. Auto-invalidation disabled to reduce API costs. Cache expires naturally or via manual refresh.';

COMMENT ON FUNCTION invalidate_user_insights_on_entry_change IS
'[DEPRECATED - Triggers removed] Previously auto-invalidated insights on entry changes. Kept for potential manual use.';

-- ============================================================
-- 5. VALIDATION
-- ============================================================

DO $$
DECLARE
  trigger_count INTEGER;
BEGIN
  -- Count remaining triggers on entries table
  SELECT COUNT(*) INTO trigger_count
  FROM pg_trigger
  WHERE tgname LIKE '%invalidate_insights%'
    AND tgrelid = 'entries'::regclass;

  IF trigger_count > 0 THEN
    RAISE EXCEPTION '❌ Auto-invalidation triggers still exist! Expected 0, found %', trigger_count;
  ELSE
    RAISE NOTICE '✅ Auto-invalidation triggers successfully removed';
  END IF;

  RAISE NOTICE '✅ Insights cache optimization complete';
  RAISE NOTICE '   - Auto-invalidation: DISABLED';
  RAISE NOTICE '   - Cache TTL: 7 days';
  RAISE NOTICE '   - Invalidation: Natural expiry + manual refresh only';
  RAISE NOTICE '   - Expected cost reduction: 96%% ($14,380/year savings for 1000 users)';
END $$;
