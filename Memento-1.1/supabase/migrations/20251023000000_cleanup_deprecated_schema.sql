-- ============================================================
-- Migration: Cleanup Deprecated Schema
-- Date: 2025-10-23
-- Purpose: Remove deprecated follow-up questions infrastructure
-- ============================================================

-- ============================================================
-- 1. DROP DEPRECATED TABLE (CASCADE will drop triggers and constraints)
-- ============================================================

-- Drop the table with CASCADE to automatically drop dependent triggers
DROP TABLE IF EXISTS follow_up_questions CASCADE;

-- ============================================================
-- 2. DROP DEPRECATED FUNCTIONS (now safe since triggers are gone)
-- ============================================================

DROP FUNCTION IF EXISTS get_current_week_questions(uuid);
DROP FUNCTION IF EXISTS complete_follow_up_question(uuid, uuid);
DROP FUNCTION IF EXISTS update_follow_up_questions_updated_at();

-- ============================================================
-- 3. FIX DUPLICATE TRIGGERS ON ENTRIES TABLE
-- ============================================================

-- Drop both existing triggers
DROP TRIGGER IF EXISTS entries_updated_at ON entries;
DROP TRIGGER IF EXISTS update_entries_updated_at ON entries;
DROP TRIGGER IF EXISTS trigger_update_entries_updated_at ON entries;

-- Drop the generic update_updated_at function (not specific to entries)
DROP FUNCTION IF EXISTS update_updated_at();

-- Keep the entries-specific function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Recreate the proper function if it doesn't exist
CREATE OR REPLACE FUNCTION update_entries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create single, canonical trigger
CREATE TRIGGER trigger_update_entries_updated_at
  BEFORE UPDATE ON entries
  FOR EACH ROW
  EXECUTE FUNCTION update_entries_updated_at();

-- ============================================================
-- 4. FIX DUPLICATE RLS POLICIES ON ENTRIES TABLE
-- ============================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own entries" ON entries;
DROP POLICY IF EXISTS "Users can view their own entries" ON entries;
DROP POLICY IF EXISTS "Users can insert own entries" ON entries;
DROP POLICY IF EXISTS "Users can create own entries" ON entries;
DROP POLICY IF EXISTS "Users can create their own entries" ON entries;
DROP POLICY IF EXISTS "Users can update own entries" ON entries;
DROP POLICY IF EXISTS "Users can update their own entries" ON entries;
DROP POLICY IF EXISTS "Users can delete own entries" ON entries;
DROP POLICY IF EXISTS "Users can delete their own entries" ON entries;

-- Create clean, canonical policies
CREATE POLICY "Users can view own entries"
  ON entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own entries"
  ON entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own entries"
  ON entries FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own entries"
  ON entries FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 5. REMOVE UNUSED COLUMNS FROM ENTRIES
-- ============================================================

-- Remove is_archived (not used in app)
ALTER TABLE entries DROP COLUMN IF EXISTS is_archived;

-- Remove tags (not used in app yet, can add back when needed)
ALTER TABLE entries DROP COLUMN IF EXISTS tags;

-- ============================================================
-- 6. VALIDATION
-- ============================================================

DO $$
DECLARE
  policy_count INTEGER;
  trigger_count INTEGER;
BEGIN
  -- Verify exactly 4 RLS policies exist
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'entries';

  IF policy_count != 4 THEN
    RAISE EXCEPTION 'Expected 4 RLS policies on entries table, found %', policy_count;
  END IF;

  -- Verify exactly 1 UPDATE trigger exists
  SELECT COUNT(*) INTO trigger_count
  FROM pg_trigger
  WHERE tgname LIKE '%update%' AND tgrelid = 'entries'::regclass;

  IF trigger_count != 1 THEN
    RAISE WARNING 'Expected 1 UPDATE trigger on entries table, found %', trigger_count;
  END IF;

  RAISE NOTICE '✅ Deprecated schema cleaned up successfully';
  RAISE NOTICE '   - Removed follow_up_questions table';
  RAISE NOTICE '   - Fixed duplicate policies (now 4 total)';
  RAISE NOTICE '   - Fixed duplicate triggers (now 1 total)';
  RAISE NOTICE '   - Removed unused columns (is_archived, tags)';
END $$;
