-- ============================================================
-- Migration: Add selected_goals to user_profiles
-- Purpose: Persist YourGoalsView chip selections for system prompt personalization
-- Related: MEM-22 System Prompt Implementation
-- ============================================================

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS selected_goals TEXT[];

COMMENT ON COLUMN user_profiles.selected_goals IS 'User-selected journaling goals from YourGoalsView (e.g. Self awareness, Emotion mapping) for AI personalization';
