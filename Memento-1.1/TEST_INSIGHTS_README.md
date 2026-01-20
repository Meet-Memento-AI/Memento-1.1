# Testing Generate Insights Edge Function

Quick guide for testing your edge function with Deno (no Swift app needed).

## Quick Start

```bash
# Terminal 1: Start local edge function
supabase functions serve generate-insights

# Terminal 2: Run tests
deno run --allow-net --allow-env --allow-read test-insights.ts

# Or use the shortcut (script is executable)
./test-insights.ts
```

## What Gets Tested

The script tests 3 scenarios:

1. **3 Entries** - Minimum required for insights
2. **6 Entries** - Milestone test with force refresh
3. **Force Refresh** - Tests bypassing cache

## Output Example

```
╔════════════════════════════════════════════════════╗
║  Generate Insights Edge Function Test Suite       ║
╚════════════════════════════════════════════════════╝

Endpoint: LOCAL
URL: http://localhost:54321/functions/v1/generate-insights

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test: 3 Entries - Minimum for Insights
Entries: 3 | Force Refresh: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Success (5234ms)

Summary: You're navigating presentation anxiety...

Description:
Over the past few days, you've been processing...

Themes (4):
  1. 📊 Work Performance Anxiety
     ...

Metadata:
  Entries Analyzed: 3
  Generated At: 1/27/2025, 10:30:15 AM
  From Cache: ✗
```

## Testing Against Production

Edit `test-insights.ts` and change:

```typescript
const USE_PRODUCTION = true;  // Line 18
```

Then run the same command.

## Adding Custom Test Scenarios

Edit the `testScenarios` array in `test-insights.ts`:

```typescript
{
  name: "Your Test Name",
  forceRefresh: false,
  entries: [
    {
      date: "2025-01-15T10:00:00Z",
      title: "Entry Title",
      content: "Entry content here...",
      word_count: 10,
      mood: "happy"
    },
    // Add more entries...
  ]
}
```

## What You Can Test

- ✅ Input validation (too few/many entries)
- ✅ OpenAI response quality
- ✅ Cache behavior (fromCache flag)
- ✅ Force refresh functionality
- ✅ Response time benchmarking
- ✅ Theme generation (should return 4-5 themes)
- ✅ Error handling

## Requirements

- Deno installed
- Supabase CLI installed
- `.env` file with `SUPABASE_ANON_KEY`

## Troubleshooting

**"SUPABASE_ANON_KEY not found"**
- Make sure `.env` file exists in project root
- Or set environment variable: `export SUPABASE_ANON_KEY=your-key`

**"Connection refused"**
- Edge function not running locally
- Start it: `supabase functions serve generate-insights`

**"Failed to fetch"**
- Check if edge function is running: `supabase status`
- Check endpoint URL in script

**Slow responses (>10s)**
- Normal! OpenAI API can take 5-10 seconds
- Production might be faster (better infrastructure)
