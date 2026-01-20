-- Migration: Improve complete_follow_up_question RPC function
-- Adds better diagnostics and error handling to help debug completion issues

-- ============================================================
-- Drop and recreate the function with better diagnostics
-- ============================================================

DROP FUNCTION IF EXISTS complete_follow_up_question(uuid, uuid);

CREATE OR REPLACE FUNCTION complete_follow_up_question(
  p_question_id uuid,
  p_entry_id uuid
)
RETURNS TABLE(
  success boolean,
  rows_updated integer,
  current_user_id uuid,
  question_exists boolean,
  question_user_id uuid
) AS $$
DECLARE
  v_rows_updated integer;
  v_current_user_id uuid;
  v_question_exists boolean;
  v_question_user_id uuid;
BEGIN
  -- Get current authenticated user
  v_current_user_id := auth.uid();

  -- Check if question exists and get its user_id
  SELECT EXISTS(SELECT 1 FROM follow_up_questions WHERE id = p_question_id),
         fq.user_id
  INTO v_question_exists, v_question_user_id
  FROM follow_up_questions fq
  WHERE fq.id = p_question_id;

  -- Log diagnostic information
  RAISE NOTICE 'complete_follow_up_question called:';
  RAISE NOTICE '  question_id: %', p_question_id;
  RAISE NOTICE '  entry_id: %', p_entry_id;
  RAISE NOTICE '  auth.uid(): %', v_current_user_id;
  RAISE NOTICE '  question_exists: %', v_question_exists;
  RAISE NOTICE '  question_user_id: %', v_question_user_id;

  -- Perform the update
  UPDATE follow_up_questions
  SET
    is_completed = true,
    completed_at = now(),
    entry_id = p_entry_id
  WHERE id = p_question_id
    AND user_id = auth.uid();

  -- Get number of rows updated
  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  RAISE NOTICE '  rows_updated: %', v_rows_updated;

  -- If no rows updated, log why
  IF v_rows_updated = 0 THEN
    IF NOT v_question_exists THEN
      RAISE NOTICE '  REASON: Question does not exist';
    ELSIF v_question_user_id != v_current_user_id THEN
      RAISE NOTICE '  REASON: User ID mismatch (question belongs to different user)';
    ELSIF v_current_user_id IS NULL THEN
      RAISE NOTICE '  REASON: auth.uid() is NULL (not authenticated)';
    ELSE
      RAISE NOTICE '  REASON: Unknown (possibly already completed)';
    END IF;
  END IF;

  -- Return diagnostic information
  RETURN QUERY SELECT
    (v_rows_updated > 0),
    v_rows_updated,
    v_current_user_id,
    v_question_exists,
    v_question_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION complete_follow_up_question(uuid, uuid) TO authenticated;
