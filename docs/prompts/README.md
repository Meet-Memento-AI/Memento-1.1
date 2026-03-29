# Memento prompts

## Chat RAG product rules

Retrieval, citation caps, and env tuning are summarized in [Chat RAG product rules](../chat-rag-product-rules.md).

## `MEMENTO_SYSTEM_PROMPT.md`

Human-reviewed source for the chat Edge Function’s system instructions.

## Keeping Supabase / production in sync

The **deployed** prompt is read at runtime from `supabase/functions/chat/MEMENTO_SYSTEM_PROMPT.md` (bundled with the function). After editing this file under `docs/prompts/`, copy the same body into `supabase/functions/chat/MEMENTO_SYSTEM_PROMPT.md` and redeploy:

```bash
supabase functions deploy chat
```

Alternatively, maintain only the file under `supabase/functions/chat/` and treat `docs/prompts/` as the copy for documentation—pick one workflow and stick to it.

## Optional: pre-created Gemini cache

If explicit context caching fails at runtime (e.g. minimum token size), the function falls back to an inline `system_instruction`. You can set `GEMINI_SYSTEM_CACHE_NAME` to a `cachedContents/...` resource name from the Gemini API if you create one manually.
