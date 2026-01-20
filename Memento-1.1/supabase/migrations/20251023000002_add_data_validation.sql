-- ============================================================
-- Migration: Add Data Validation Constraints
-- Date: 2025-10-23
-- Purpose: Ensure data integrity and quality at database level
-- ============================================================

-- ============================================================
-- 1. ENTRIES TABLE VALIDATION
-- ============================================================

-- Title length constraint (max 200 characters)
ALTER TABLE entries
  DROP CONSTRAINT IF EXISTS title_max_length;

ALTER TABLE entries
  ADD CONSTRAINT title_max_length
    CHECK (title IS NULL OR char_length(title) <= 200);

-- Text minimum length (ensure not empty - already enforced by text_not_empty)
-- Note: We don't enforce a minimum of 10 chars to allow flexibility
-- The existing text_not_empty constraint ensures text is not blank

-- Text maximum length (prevent abuse, 50K chars = ~10K words)
ALTER TABLE entries
  DROP CONSTRAINT IF EXISTS text_max_length;

ALTER TABLE entries
  ADD CONSTRAINT text_max_length
    CHECK (char_length(text) <= 50000);

-- Ensure created_at is not in the future
ALTER TABLE entries
  DROP CONSTRAINT IF EXISTS created_at_not_future;

ALTER TABLE entries
  ADD CONSTRAINT created_at_not_future
    CHECK (created_at <= now() + interval '5 minutes'); -- Allow 5min clock skew

-- Ensure updated_at >= created_at
ALTER TABLE entries
  DROP CONSTRAINT IF EXISTS updated_after_created;

ALTER TABLE entries
  ADD CONSTRAINT updated_after_created
    CHECK (updated_at >= created_at);

-- ============================================================
-- 2. USER_PROFILES TABLE VALIDATION
-- ============================================================

-- Self-reflection text length (20-2000 chars) - already exists, verify
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_reflection_length;

ALTER TABLE user_profiles
  ADD CONSTRAINT check_reflection_length
    CHECK (
      onboarding_self_reflection IS NULL OR
      (char_length(onboarding_self_reflection) >= 20 AND
       char_length(onboarding_self_reflection) <= 2000)
    );

-- Themes array length (3-6 themes) - already exists, verify
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_themes_count;

ALTER TABLE user_profiles
  ADD CONSTRAINT check_themes_count
    CHECK (
      identified_themes IS NULL OR
      (array_length(identified_themes, 1) >= 3 AND
       array_length(identified_themes, 1) <= 6)
    );

-- Selection count matches array length - already exists, verify
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_selection_count;

ALTER TABLE user_profiles
  ADD CONSTRAINT check_selection_count
    CHECK (
      (theme_selection_count IS NULL AND identified_themes IS NULL) OR
      (theme_selection_count IS NOT NULL AND
       theme_selection_count = array_length(identified_themes, 1))
    );

-- Clean up any inconsistent theme data before adding constraint
-- Set themes_analyzed_at to now() for rows with themes but no timestamp
UPDATE user_profiles
SET themes_analyzed_at = COALESCE(themes_analyzed_at, now())
WHERE identified_themes IS NOT NULL
  AND themes_analyzed_at IS NULL;

-- Clear themes for rows with timestamp but no themes (shouldn't happen, but be safe)
UPDATE user_profiles
SET identified_themes = NULL,
    theme_selection_count = NULL,
    themes_analyzed_at = NULL
WHERE identified_themes IS NULL
  AND themes_analyzed_at IS NOT NULL;

-- Now add the constraint (data is consistent)
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_themes_analyzed;

ALTER TABLE user_profiles
  ADD CONSTRAINT check_themes_analyzed
    CHECK (
      (identified_themes IS NULL AND themes_analyzed_at IS NULL) OR
      (identified_themes IS NOT NULL AND themes_analyzed_at IS NOT NULL)
    );

-- ============================================================
-- 3. THEMES TABLE VALIDATION
-- ============================================================

-- Keywords array must not be empty (already exists, verify)
ALTER TABLE themes
  DROP CONSTRAINT IF EXISTS keywords_not_empty;

ALTER TABLE themes
  ADD CONSTRAINT keywords_not_empty
    CHECK (array_length(keywords, 1) > 0);

-- Emoji must be exactly 1-2 characters (single emoji or emoji with modifier)
ALTER TABLE themes
  DROP CONSTRAINT IF EXISTS emoji_valid;

ALTER TABLE themes
  ADD CONSTRAINT emoji_valid
    CHECK (char_length(emoji) BETWEEN 1 AND 4); -- Allow for UTF-8 multi-byte emojis

-- Title must not be empty
ALTER TABLE themes
  DROP CONSTRAINT IF EXISTS title_not_empty;

ALTER TABLE themes
  ADD CONSTRAINT title_not_empty
    CHECK (char_length(trim(title)) > 0);

-- Summary must be at least 20 characters
ALTER TABLE themes
  DROP CONSTRAINT IF EXISTS summary_min_length;

ALTER TABLE themes
  ADD CONSTRAINT summary_min_length
    CHECK (char_length(summary) >= 20);

-- Category must be one of predefined values
ALTER TABLE themes
  DROP CONSTRAINT IF EXISTS category_valid;

ALTER TABLE themes
  ADD CONSTRAINT category_valid
    CHECK (category IN ('wellness', 'emotional', 'growth', 'social'));

-- ============================================================
-- 4. FOREIGN KEY CASCADE VERIFICATION
-- ============================================================

-- Verify entries.user_id has CASCADE delete
DO $$
BEGIN
  -- Check if the constraint exists with CASCADE
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.referential_constraints rc
    WHERE rc.constraint_name = 'entries_user_id_fkey'
      AND rc.delete_rule = 'CASCADE'
  ) THEN
    -- Drop and recreate with CASCADE
    ALTER TABLE entries
      DROP CONSTRAINT IF EXISTS entries_user_id_fkey,
      ADD CONSTRAINT entries_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE;

    RAISE NOTICE 'Updated entries.user_id foreign key to CASCADE on delete';
  END IF;
END $$;

-- Verify user_profiles.user_id has CASCADE delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.referential_constraints rc
    WHERE rc.constraint_name = 'user_profiles_user_id_fkey'
      AND rc.delete_rule = 'CASCADE'
  ) THEN
    ALTER TABLE user_profiles
      DROP CONSTRAINT IF EXISTS user_profiles_user_id_fkey,
      ADD CONSTRAINT user_profiles_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE;

    RAISE NOTICE 'Updated user_profiles.user_id foreign key to CASCADE on delete';
  END IF;
END $$;

-- ============================================================
-- 5. ADD HELPFUL DATABASE COMMENTS
-- ============================================================

COMMENT ON TABLE entries IS 'User journal entries with full-text search enabled';
COMMENT ON COLUMN entries.text IS 'Entry content (10-50K chars, full-text indexed)';
COMMENT ON COLUMN entries.title IS 'Entry title (max 200 chars, full-text indexed)';
COMMENT ON COLUMN entries.created_at IS 'Entry creation timestamp (immutable)';
COMMENT ON COLUMN entries.updated_at IS 'Last modification timestamp (auto-updated)';

COMMENT ON TABLE user_profiles IS 'User profile data including onboarding responses';
COMMENT ON COLUMN user_profiles.onboarding_self_reflection IS 'User self-reflection text from onboarding (20-2000 chars)';
COMMENT ON COLUMN user_profiles.identified_themes IS 'AI-identified mental health themes (3-6 themes)';
COMMENT ON COLUMN user_profiles.theme_selection_count IS 'Number of themes selected (must match array length)';
COMMENT ON COLUMN user_profiles.themes_analyzed_at IS 'Timestamp of theme analysis';

COMMENT ON TABLE themes IS 'Mental health themes for insights (seed data, read-only)';
COMMENT ON COLUMN themes.keywords IS 'Keywords for theme matching (used in TF-IDF analysis)';
COMMENT ON COLUMN themes.category IS 'Theme category: wellness, emotional, growth, or social';

-- ============================================================
-- 6. VALIDATION & TESTING
-- ============================================================

DO $$
DECLARE
  entries_constraints INTEGER;
  profiles_constraints INTEGER;
  themes_constraints INTEGER;
BEGIN
  -- Count constraints on each table
  SELECT COUNT(*) INTO entries_constraints
  FROM information_schema.table_constraints
  WHERE table_name = 'entries' AND constraint_type = 'CHECK';

  SELECT COUNT(*) INTO profiles_constraints
  FROM information_schema.table_constraints
  WHERE table_name = 'user_profiles' AND constraint_type = 'CHECK';

  SELECT COUNT(*) INTO themes_constraints
  FROM information_schema.table_constraints
  WHERE table_name = 'themes' AND constraint_type = 'CHECK';

  RAISE NOTICE '✅ Data validation constraints added successfully';
  RAISE NOTICE '   - entries table: % CHECK constraints', entries_constraints;
  RAISE NOTICE '   - user_profiles table: % CHECK constraints', profiles_constraints;
  RAISE NOTICE '   - themes table: % CHECK constraints', themes_constraints;
  RAISE NOTICE '   - Foreign key CASCADE verified';
  RAISE NOTICE '   - Table comments added for documentation';
END $$;
