-- ============================================================
-- Migration: Migrate existing onboarding data from auth.users
-- Purpose: Copy user_personalization_node from auth.users.raw_user_meta_data to user_profiles
-- ============================================================

-- ============================================================
-- MIGRATE PERSONALIZATION TEXT
-- ============================================================

-- Copy existing personalization text from auth.users metadata
UPDATE user_profiles up
SET onboarding_self_reflection = (
  SELECT u.raw_user_meta_data->>'user_personalization_node'
  FROM auth.users u
  WHERE u.id = up.user_id
)
WHERE EXISTS (
  SELECT 1 FROM auth.users u
  WHERE u.id = up.user_id
  AND u.raw_user_meta_data->>'user_personalization_node' IS NOT NULL
  AND char_length(u.raw_user_meta_data->>'user_personalization_node') BETWEEN 20 AND 2000
)
AND onboarding_self_reflection IS NULL;  -- Only update if not already set

-- ============================================================
-- LOG MIGRATION RESULTS
-- ============================================================
DO $$
DECLARE
  migrated_count INTEGER;
  total_users INTEGER;
BEGIN
  SELECT COUNT(*) INTO migrated_count
  FROM user_profiles
  WHERE onboarding_self_reflection IS NOT NULL;

  SELECT COUNT(*) INTO total_users
  FROM user_profiles;

  RAISE NOTICE '✅ Migration complete:';
  RAISE NOTICE '   - Total users: %', total_users;
  RAISE NOTICE '   - Users with onboarding data: %', migrated_count;
END $$;
