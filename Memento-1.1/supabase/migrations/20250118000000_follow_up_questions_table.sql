-- Migration: Create follow_up_questions table
-- This stores generated questions with completion tracking

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS follow_up_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Question content
  question_text text NOT NULL,
  relevance_score float NOT NULL, -- TF-IDF similarity score

  -- Generation metadata
  generated_at timestamp with time zone NOT NULL DEFAULT now(),
  week_number int NOT NULL, -- Week of year (1-52)
  year int NOT NULL, -- Year (2025, 2026, etc.)

  -- Completion tracking
  is_completed boolean NOT NULL DEFAULT false,
  completed_at timestamp with time zone,
  entry_id uuid REFERENCES entries(id) ON DELETE SET NULL, -- Link to answer entry

  -- Timestamps
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- ============================================================
-- 2. CREATE INDEXES
-- ============================================================

-- Index for fetching user's questions
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_user_id ON follow_up_questions(user_id);

-- Index for fetching current week's questions
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_week ON follow_up_questions(user_id, year, week_number);

-- Index for fetching incomplete questions
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_incomplete ON follow_up_questions(user_id, is_completed) WHERE is_completed = false;

-- ============================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE follow_up_questions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own follow-up questions" ON follow_up_questions;
DROP POLICY IF EXISTS "Users can update their own follow-up questions" ON follow_up_questions;
DROP POLICY IF EXISTS "Service role can insert follow-up questions" ON follow_up_questions;

-- Users can only see their own questions
CREATE POLICY "Users can view their own follow-up questions"
  ON follow_up_questions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update completion status
CREATE POLICY "Users can update their own follow-up questions"
  ON follow_up_questions
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Service role can insert (for cron job)
CREATE POLICY "Service role can insert follow-up questions"
  ON follow_up_questions
  FOR INSERT
  WITH CHECK (true); -- Service role bypasses RLS anyway

-- ============================================================
-- 4. UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_follow_up_questions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_follow_up_questions_updated_at ON follow_up_questions;
CREATE TRIGGER trigger_update_follow_up_questions_updated_at
  BEFORE UPDATE ON follow_up_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_follow_up_questions_updated_at();

-- ============================================================
-- 5. HELPER FUNCTION: Get Current Week's Questions
-- ============================================================

CREATE OR REPLACE FUNCTION get_current_week_questions(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  question_text text,
  relevance_score float,
  is_completed boolean,
  completed_at timestamp with time zone,
  generated_at timestamp with time zone
) AS $$
DECLARE
  current_week int := EXTRACT(WEEK FROM now());
  current_year int := EXTRACT(YEAR FROM now());
BEGIN
  RETURN QUERY
  SELECT
    fq.id,
    fq.question_text,
    fq.relevance_score,
    fq.is_completed,
    fq.completed_at,
    fq.generated_at
  FROM follow_up_questions fq
  WHERE fq.user_id = p_user_id
    AND fq.year = current_year
    AND fq.week_number = current_week
  ORDER BY fq.relevance_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. HELPER FUNCTION: Mark Question as Completed
-- ============================================================

CREATE OR REPLACE FUNCTION complete_follow_up_question(
  p_question_id uuid,
  p_entry_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE follow_up_questions
  SET
    is_completed = true,
    completed_at = now(),
    entry_id = p_entry_id
  WHERE id = p_question_id
    AND user_id = auth.uid(); -- Security check
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
