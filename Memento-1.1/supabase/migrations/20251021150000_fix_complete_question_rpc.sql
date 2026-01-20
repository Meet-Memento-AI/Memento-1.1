-- Migration: Fix complete_follow_up_question RPC function
-- Simplify to basic void-returning function that PostgREST can find

-- Drop the complex TABLE-returning version
DROP FUNCTION IF EXISTS complete_follow_up_question(uuid, uuid);

-- Create simple, reliable version that returns void
CREATE OR REPLACE FUNCTION complete_follow_up_question(
  p_question_id uuid,
  p_entry_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Log for debugging
  RAISE NOTICE 'complete_follow_up_question called: question_id=%, entry_id=%, auth.uid()=%',
    p_question_id, p_entry_id, auth.uid();

  -- Update the question
  UPDATE follow_up_questions
  SET
    is_completed = true,
    completed_at = now(),
    entry_id = p_entry_id,
    updated_at = now()
  WHERE id = p_question_id
    AND user_id = auth.uid();

  -- Log result
  IF FOUND THEN
    RAISE NOTICE 'Question % marked complete', p_question_id;
  ELSE
    RAISE WARNING 'Question % NOT updated - user_id mismatch or question not found', p_question_id;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION complete_follow_up_question(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_follow_up_question(uuid, uuid) TO anon;

-- Add comment
COMMENT ON FUNCTION complete_follow_up_question IS 'Mark a follow-up question as completed by the authenticated user';
