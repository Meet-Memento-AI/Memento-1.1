-- ============================================================
-- Migration: Add theme analysis columns to user_profiles
-- Purpose: Store user's self-reflection text and selected themes
-- ============================================================

-- ============================================================
-- CREATE USER_PROFILES TABLE (if doesn't exist)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure all auth users have a profile row
INSERT INTO user_profiles (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM user_profiles)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================
-- ADD THEME ANALYSIS COLUMNS
-- ============================================================
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS onboarding_self_reflection TEXT,
  ADD COLUMN IF NOT EXISTS identified_themes TEXT[],
  ADD COLUMN IF NOT EXISTS theme_selection_count INTEGER,
  ADD COLUMN IF NOT EXISTS themes_analyzed_at TIMESTAMPTZ;

-- ============================================================
-- CONSTRAINTS (handle NULL arrays correctly)
-- ============================================================

-- Text length constraint (20-2000 characters)
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_reflection_length;
ALTER TABLE user_profiles
  ADD CONSTRAINT check_reflection_length
    CHECK (
      onboarding_self_reflection IS NULL OR
      (char_length(onboarding_self_reflection) >= 20 AND
       char_length(onboarding_self_reflection) <= 2000)
    );

-- Array length constraint (3-6 themes)
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_themes_count;
ALTER TABLE user_profiles
  ADD CONSTRAINT check_themes_count
    CHECK (
      identified_themes IS NULL OR
      (array_length(identified_themes, 1) >= 3 AND
       array_length(identified_themes, 1) <= 6)
    );

-- Selection count must match array length
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS check_selection_count;
ALTER TABLE user_profiles
  ADD CONSTRAINT check_selection_count
    CHECK (
      (theme_selection_count IS NULL AND identified_themes IS NULL) OR
      (theme_selection_count IS NOT NULL AND
       theme_selection_count = array_length(identified_themes, 1))
    );

-- ============================================================
-- VALIDATION TRIGGER (ensure themes exist in themes table)
-- ============================================================
CREATE OR REPLACE FUNCTION validate_theme_names()
RETURNS TRIGGER AS $$
DECLARE
  invalid_themes TEXT[];
BEGIN
  -- Only validate if themes array is not NULL
  IF NEW.identified_themes IS NOT NULL THEN
    -- Find any themes that don't exist in themes table
    SELECT ARRAY_AGG(theme_name)
    INTO invalid_themes
    FROM unnest(NEW.identified_themes) AS theme_name
    WHERE theme_name NOT IN (SELECT name FROM themes);

    -- Raise error if invalid themes found
    IF invalid_themes IS NOT NULL THEN
      RAISE EXCEPTION 'Invalid theme names: %', array_to_string(invalid_themes, ', ');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_themes ON user_profiles;
CREATE TRIGGER trigger_validate_themes
  BEFORE INSERT OR UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION validate_theme_names();

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION update_user_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER trigger_update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_user_profiles_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

-- Users can only view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id
  ON user_profiles(user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_themes_analyzed
  ON user_profiles(themes_analyzed_at)
  WHERE themes_analyzed_at IS NOT NULL;

-- ============================================================
-- VALIDATION
-- ============================================================
DO $$
BEGIN
  RAISE NOTICE '✅ user_profiles table configured with theme analysis columns';
END $$;
