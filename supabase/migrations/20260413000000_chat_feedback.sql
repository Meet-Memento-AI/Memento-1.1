-- Chat feedback table for thumbs up/down on AI responses
-- Enables personalization of RAG retrieval based on user preferences

CREATE TABLE chat_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  feedback_type TEXT NOT NULL CHECK (feedback_type IN ('positive', 'negative')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, message_id)  -- One feedback per message per user
);

-- Indexes for query performance
CREATE INDEX idx_chat_feedback_user ON chat_feedback(user_id);
CREATE INDEX idx_chat_feedback_message ON chat_feedback(message_id);
CREATE INDEX idx_chat_feedback_type_user ON chat_feedback(user_id, feedback_type);

-- Enable Row Level Security
ALTER TABLE chat_feedback ENABLE ROW LEVEL SECURITY;

-- RLS policies: users can only access their own feedback
CREATE POLICY "Users can view own feedback"
  ON chat_feedback FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback"
  ON chat_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feedback"
  ON chat_feedback FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own feedback"
  ON chat_feedback FOR DELETE USING (auth.uid() = user_id);
