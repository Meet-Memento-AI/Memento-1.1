# RAG Chatbot Setup Guide

How to deploy the RAG chatbot infrastructure for Memento.

## Prerequisites

- A Supabase project with Postgres
- Supabase CLI installed and linked (`supabase link --project-ref <ref>`)
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey)

## 1. Run the Database Migration

Push the pgvector schema (embedding columns, similarity search function,
chat_messages table, and auto-reset trigger):

```bash
supabase db push
```

Or paste the contents of `supabase_migrations/20260305_rag_chat_schema.sql`
into **Supabase Dashboard → SQL Editor** and run it.

## 2. Set the Gemini API Key

```bash
supabase secrets set GEMINI_API_KEY=your_key_here
```

## 3. Deploy Edge Functions

```bash
# sync-embedding: webhook-triggered, no JWT verification needed
supabase functions deploy sync-embedding --no-verify-jwt

# chat: called by the iOS app with a user JWT
supabase functions deploy chat
```

## 4. Create the Database Webhook

In **Supabase Dashboard → Database → Webhooks → Create a new hook**:

| Field       | Value                        |
|-------------|------------------------------|
| Name        | `embed-journal-entry`        |
| Table       | `journal_entries`            |
| Events      | `INSERT`, `UPDATE`           |
| Type        | Supabase Edge Function       |
| Function    | `sync-embedding`             |

This ensures that every time a journal entry is created or edited, the
`sync-embedding` function is called to generate and store a vector embedding.

## 5. Backfill Existing Entries

Existing journal entries won't have embeddings yet. To trigger embedding
generation for all of them, run this in the SQL Editor:

```sql
-- Mark all un-embedded entries for processing
UPDATE journal_entries
SET embedding_status = 'pending', updated_at = now()
WHERE embedding IS NULL AND is_deleted = false;
```

Then, to actually trigger the webhook for each entry, you can run a small
script that touches each row (the webhook fires on UPDATE):

```sql
-- Touch each pending entry to fire the webhook
UPDATE journal_entries
SET updated_at = now()
WHERE embedding_status = 'pending' AND is_deleted = false;
```

> Note: if you have many entries, the webhook will fire for each one. Gemini
> text-embedding-004 has generous rate limits, but monitor the Edge Function
> logs for any failures.

## 6. Verify the Pipeline

### Check that embeddings are generated

```sql
SELECT id, embedding_status, (embedding IS NOT NULL) as has_embedding
FROM journal_entries
ORDER BY created_at DESC
LIMIT 5;
```

Expected: `embedding_status = 'complete'` and `has_embedding = true` for
entries with content.

### Test the chat function

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/chat \
  -H "Authorization: Bearer YOUR_USER_JWT" \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"message": "What have I been writing about lately?"}'
```

Expected: a JSON response with `reply` (string) and `sources` (array).

### End-to-end checklist

1. Create a journal entry with text content → verify `embedding_status` = `complete`
2. Create 2-3 entries about distinct topics
3. Open the Dig Deeper tab → tap a suggestion → confirm the response references your entries
4. Ask about a specific topic → confirm it retrieves the relevant entry
5. Send several messages → confirm conversation context is maintained
6. Tap "New Chat" via the history sheet → confirm messages clear
7. Edit an entry → confirm `embedding_status` resets to `pending` → new embedding generates
8. Ask about a topic with no matching entries → confirm the AI says it doesn't have info on that

## Architecture Overview

```
Journal entry saved
  → INSERT/UPDATE on journal_entries
  → Database Webhook fires
  → sync-embedding Edge Function
  → Gemini text-embedding-004 (768 dims)
  → pgvector column updated

User asks a question
  → chat Edge Function
  → Embed question (text-embedding-004)
  → pgvector cosine similarity search (match_journal_entries RPC)
  → Top 5 entries returned as context
  → Gemini 2.5 Flash generates grounded response
  → Messages persisted to chat_messages
```

## Environment Variables

| Variable                   | Used By           | Description                       |
|----------------------------|-------------------|-----------------------------------|
| `GEMINI_API_KEY`           | Both functions    | Google AI API key                 |
| `SUPABASE_URL`             | Both functions    | Auto-set by Supabase              |
| `SUPABASE_ANON_KEY`        | `chat`            | Auto-set by Supabase              |
| `SUPABASE_SERVICE_ROLE_KEY`| `sync-embedding`  | Auto-set by Supabase              |
