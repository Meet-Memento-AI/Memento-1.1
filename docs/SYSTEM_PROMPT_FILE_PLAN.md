# System Prompt .md File Plan

## Goal
Store the Memento system prompt in a `.md` file that can be edited independently and dynamically modified with user input from onboarding (LearnAboutYourselfView, YourGoalsView).

## Structure

### Single File: `system_prompt.md`
One markdown file split into two sections by a delimiter:

1. **Base prompt** — Static content up to the delimiter. Never contains user data.
2. **Personalization template** — Optional section with placeholders. Only injected when user has onboarding data.

### Delimiter
`<!-- PERSONALIZATION_TEMPLATE -->` — HTML comment, invisible to the model, clear for editors.

### Placeholders (in personalization template)
| Placeholder | Source | Example |
|-------------|--------|---------|
| `{{onboarding_reflection}}` | LearnAboutYourselfView | "I want to understand my stress patterns" |
| `{{selected_goals}}` | YourGoalsView | "Self awareness, Emotion mapping, Stress relief" |

### Logic
1. Read `system_prompt.md`
2. Split on `<!-- PERSONALIZATION_TEMPLATE -->`
3. Base = part before delimiter (trimmed)
4. Template = part after delimiter (trimmed)
5. If `systemPromptContext` has onboarding_reflection OR selected_goals:
   - Replace placeholders in template (empty → omit that block)
   - Append filled template to base
6. Else: use base only

### File Location
`supabase/functions/chat-with-entries/system_prompt.md` — colocated with the function, deployed with it.

### Loading
- Deno: `Deno.readTextFile(new URL('./system_prompt.md', import.meta.url))`
- Cache the parsed result in a module-level variable (lazy init) to avoid re-reading on every request
- Edge functions are stateless but same process may serve multiple requests — in-memory cache is fine for the cold-start duration

### Editing Workflow
- Product/writing team edits `system_prompt.md` directly
- No code changes needed for prompt tweaks
- Personalization template can be updated (wording, structure) without touching TypeScript

### Cache Key
- Cache key = `sha256(entries_hash + context_hash)` so personalization changes invalidate the cache
