# Gemini Context Caching Plan for chat-with-entries

## Overview
Per [Gemini Context Caching](https://ai.google.dev/gemini-api/docs/caching), we use **explicit caching** to reduce cost and latency when the same large context (system prompt + journal entries) is reused across multiple chat turns.

## Best Practices Applied

### 1. When to Use Explicit Caching
> "Context caching is particularly well suited to scenarios where a substantial initial context is referenced repeatedly by shorter requests."

**Memento fits**: Chatbot with extensive system instructions + recurring queries against journal entries.

### 2. What to Cache
- **systemInstruction**: Base Memento prompt + personalization (LearnAboutYourselfView, YourGoalsView)
- **contents**: Journal entries as a single user-content block (the large, static corpus)

### 3. What NOT to Cache
- Conversation history (messages) — changes every turn; sent in each `generateContent` request

### 4. Cache Lifecycle
- **Create**: When user sends first message, or when entries/context change (entries_hash differs)
- **TTL**: 1 hour (`3600s`) — balances cost vs. typical active chat session
- **Invalidate**: When entries change (new entry, edit, delete) — create new cache

### 5. Minimum Token Requirements
- Gemini 2.5 Flash: 1024 min tokens
- Our payload: ~1500+ tokens (system prompt ~800 + 30 entries × ~50 tokens)

### 6. Implicit Caching (Automatic)
- Put large common content at beginning (we do — system + entries in cache)
- Similar request prefixes in short time (conversation continuity)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Request: messages + entries + systemPromptContext               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. Compute entries_hash (SHA-256 of sorted entry IDs + dates)   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Check user_chat_caches: user_id + entries_hash, not expired  │
└─────────────────────────────────────────────────────────────────┘
                    │                           │
              HIT   │                           │   MISS
                    ▼                           ▼
┌──────────────────────────┐    ┌──────────────────────────────────┐
│ 3a. generateContent      │    │ 3b. Create cache via REST         │
│     cachedContent=name   │    │     POST cachedContents           │
│     contents=messages    │    │     Save to user_chat_caches       │
└──────────────────────────┘    │     Then generateContent          │
                                └──────────────────────────────────┘
```

## Database: user_chat_caches

| Column      | Type        | Description                                      |
|------------|-------------|--------------------------------------------------|
| id         | uuid        | PK                                               |
| user_id    | uuid        | FK auth.users                                    |
| cache_name | text        | `cachedContents/xxx` from Gemini                 |
| entries_hash | text      | SHA-256 of (entry ids + content signatures)      |
| expires_at | timestamptz | When cache expires (from Gemini response)        |
| created_at | timestamptz |                                                  |

## API Flow

### Create Cache (REST)
```
POST https://generativelanguage.googleapis.com/v1beta/cachedContents?key=KEY
{
  "model": "models/gemini-2.5-flash",
  "systemInstruction": { "parts": [{ "text": "<base prompt + personalization>" }] },
  "contents": [{
    "role": "user",
    "parts": [{ "text": "<journal entries JSON>" }]
  }],
  "ttl": "3600s"
}
→ Response: { "name": "cachedContents/abc123", "expireTime": "..." }
```

### Generate with Cache
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=KEY
{
  "contents": [ /* conversation messages */ ],
  "cachedContent": "cachedContents/abc123",
  "generationConfig": { "temperature": 0.7, "maxOutputTokens": 800 }
}
```

## Environment
- `GEMINI_API_KEY` — required (replaces or supplements OPENAI_API_KEY)
