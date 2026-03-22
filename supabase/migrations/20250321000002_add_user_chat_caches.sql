-- ============================================================
-- Migration: Add user_chat_caches for Gemini context caching
-- Purpose: Store cache metadata so we reuse cached content across chat turns
-- Related: Gemini Context Caching best practices
-- ============================================================

CREATE TABLE IF NOT EXISTS user_chat_caches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cache_name text NOT NULL,
  entries_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_chat_caches_user_hash
  ON user_chat_caches(user_id, entries_hash);

CREATE INDEX IF NOT EXISTS idx_user_chat_caches_expires
  ON user_chat_caches(expires_at);

ALTER TABLE user_chat_caches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own chat caches" ON user_chat_caches;
CREATE POLICY "Users can manage own chat caches"
  ON user_chat_caches FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE user_chat_caches IS 'Gemini cached content metadata for chat-with-entries context caching';
