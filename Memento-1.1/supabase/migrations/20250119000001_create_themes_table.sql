-- ============================================================
-- Migration: Create themes table for new user insights
-- Purpose: Store mental health themes with keywords for analysis
-- ============================================================

-- ============================================================
-- CREATE THEMES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS themes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  keywords TEXT[] NOT NULL CHECK (array_length(keywords, 1) > 0),
  emoji TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_themes_name ON themes(name);
CREATE INDEX IF NOT EXISTS idx_themes_category ON themes(category);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Anyone can view themes" ON themes;

-- Everyone can read themes (needed for app to display)
CREATE POLICY "Anyone can view themes"
  ON themes FOR SELECT
  USING (true);

-- No INSERT/UPDATE/DELETE policies = only admin (service role) can modify

-- ============================================================
-- SEED THEMES DATA (10 mental health themes)
-- ============================================================
INSERT INTO themes (name, title, summary, keywords, emoji, category) VALUES

('stress-energy', 'Stress & Energy',
 'Understanding how stress affects your energy levels and finding balance in demanding times.',
 ARRAY['stress', 'stressed', 'tired', 'exhausted', 'overwhelmed', 'burnout', 'energy', 'rest', 'fatigue', 'drained'],
 '⚡', 'wellness'),

('anxiety-worry', 'Anxiety & Worry',
 'Exploring anxious thoughts and worry patterns to find calm and clarity.',
 ARRAY['anxiety', 'anxious', 'worry', 'worried', 'nervous', 'panic', 'fear', 'scared', 'uneasy', 'tense'],
 '🌊', 'emotional'),

('career-purpose', 'Career & Purpose',
 'Reflecting on work, career goals, and finding meaning in what you do.',
 ARRAY['work', 'job', 'career', 'purpose', 'goals', 'productivity', 'professional', 'ambition', 'direction', 'calling'],
 '🎯', 'growth'),

('relationships-connection', 'Relationships & Connection',
 'Navigating relationships, building connections, and understanding interpersonal dynamics.',
 ARRAY['relationship', 'relationships', 'family', 'friends', 'partner', 'lonely', 'connection', 'social', 'love', 'people'],
 '💛', 'social'),

('confidence-mindset', 'Confidence & Mindset',
 'Building self-confidence and developing a growth-oriented mindset.',
 ARRAY['confidence', 'confident', 'self-esteem', 'insecure', 'doubt', 'worthy', 'believe', 'mindset', 'growth', 'capable'],
 '✨', 'growth'),

('habits-routine', 'Habits & Routine',
 'Creating consistency through daily habits and sustainable routines.',
 ARRAY['habit', 'habits', 'routine', 'daily', 'consistency', 'schedule', 'morning', 'evening', 'pattern', 'ritual'],
 '📋', 'wellness'),

('self-compassion', 'Self-Compassion',
 'Practicing kindness toward yourself and letting go of harsh self-criticism.',
 ARRAY['self-compassion', 'kind', 'kindness', 'harsh', 'critical', 'forgive', 'gentle', 'compassion', 'self-care', 'acceptance'],
 '🤍', 'emotional'),

('meaning-values', 'Meaning & Values',
 'Discovering what matters most and aligning your life with your core values.',
 ARRAY['meaning', 'values', 'purpose', 'fulfillment', 'direction', 'important', 'matter', 'priorities', 'authentic', 'integrity'],
 '🧭', 'growth'),

('sleep-rest', 'Sleep & Rest',
 'Understanding your sleep patterns and the importance of rest and recovery.',
 ARRAY['sleep', 'sleeping', 'insomnia', 'rest', 'tired', 'exhausted', 'fatigue', 'recovery', 'recharge', 'night'],
 '🌙', 'wellness'),

('life-transitions', 'Life Transitions',
 'Navigating change, endings, and new beginnings with resilience.',
 ARRAY['change', 'transition', 'ending', 'beginning', 'new', 'moving', 'leaving', 'starting', 'uncertain', 'adapt'],
 '🌱', 'growth')

-- Use ON CONFLICT to make migration idempotent
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- VALIDATION
-- ============================================================
-- Verify all themes were inserted
DO $$
DECLARE
  theme_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO theme_count FROM themes;
  IF theme_count < 10 THEN
    RAISE EXCEPTION 'Failed to insert all themes. Expected 10, got %', theme_count;
  END IF;
  RAISE NOTICE '✅ Successfully inserted/verified % themes', theme_count;
END $$;
