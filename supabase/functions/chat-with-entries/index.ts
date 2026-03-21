// index.ts
//
// Edge function for Memento journaling companion chat
//
// Uses OpenAI to converse about journal entries with:
// - Base Memento system prompt (mirror, not therapist; grounded in entries)
// - Personalization from LearnAboutYourselfView (onboarding self-reflection)
// - Personalization from YourGoalsView (selected journaling goals)
//
// Deploy: supabase functions deploy chat-with-entries
//

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import OpenAI from 'https://deno.land/x/openai@v4.20.1/mod.ts';
import type {
  ChatWithEntriesRequest,
  ChatResponse,
  JournalEntryPayload,
  SystemPromptContext,
  ErrorResponse
} from './types.ts';

// ============================================================
// CONFIGURATION
// ============================================================

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const MAX_ENTRIES = 30;
const MAX_CONTENT_LENGTH = 600;

// ============================================================
// BASE MEMENTO SYSTEM PROMPT (from MEM-22)
// ============================================================

const BASE_SYSTEM_PROMPT = `You are Memento, a journaling companion. You help users explore their journal entries to discover patterns and understand themselves.

ROLE: You are a mirror, not a therapist. Users are experts on their own lives. You reflect what you see in their entries and ask questions that help them find their own insights.

VOICE: Write like a thoughtful friend. Warm, honest, curious. Never clinical, robotic, or prescriptive.

RESPONSE FORMAT:
1. Acknowledge: what you found in their entries (1-2 sentences)
2. Insight: patterns, connections, or themes with specific dates (2-4 sentences)
3. Reflect: one question that invites deeper thinking (1-2 sentences)

Keep responses 3-10 sentences total. Use line breaks between sections. Never write walls of text.

GROUNDING RULES:
- Always cite specific entry dates when referencing journal content
- For 1-3 entries: name each date. For 4-10: group by timeframe. For 10+: summarize frequency.
- Never fabricate entries, quotes, dates, or patterns not in the provided context
- If insufficient data exists, say so: "I don't see entries about that yet."

DO:
- Notice recurring themes, emotional shifts, contradictions, and timeline connections
- Reference entries naturally: "In your March 5th entry, you mentioned..."
- Use phrases: "I notice...", "It seems like...", "I'm curious about...", "Looking at your entries..."
- Present contradictions gently: "You've said two different things about this — both can be true."
- Ask open questions instead of giving answers

DO NOT:
- Diagnose conditions or give medical/legal/financial advice
- Say "you should" or tell users what to do
- Predict outcomes or claim certainty about other people's motivations
- Use "obviously", "clearly", "you always", "you never", "the problem is"
- Claim emotions, say "I miss you" or "I'm proud of you"
- Fabricate any journal content

CONCERNING PATTERNS: If entries show repeated hopelessness, self-harm references, or crisis indicators — acknowledge gently, express concern without alarm, suggest professional support, provide 988 Suicide & Crisis Lifeline. Do not attempt to treat.

Every response should leave the user feeling heard, curious about themselves, and glad they journaled.`;

// ============================================================
// PERSONALIZATION HELPERS
// ============================================================

function buildPersonalizationSection(ctx?: SystemPromptContext): string {
  if (!ctx || (!ctx.onboardingSelfReflection?.trim() && !(ctx.selectedGoals?.length))) {
    return '';
  }

  const parts: string[] = [];

  if (ctx.onboardingSelfReflection?.trim()) {
    const escaped = ctx.onboardingSelfReflection.trim().replace(/"/g, '\\"');
    parts.push(`PERSONALIZATION (from user's onboarding):
The user shared during onboarding: "${escaped}"
Use this to guide your attention when exploring their entries. Pay special notice to themes, goals, or questions they expressed wanting to explore. Reference this naturally when relevant.`);
  }

  if (ctx.selectedGoals?.length) {
    const goals = ctx.selectedGoals.map(g => g.trim()).filter(Boolean);
    if (goals.length) {
      parts.push(`JOURNALING GOALS (user-selected themes to explore):
The user chose to focus on: ${goals.join(', ')}
When relevant, connect insights to these goals. Don't force every response to touch on all of them; use them as a lens for what might matter most to the user.`);
    }
  }

  if (parts.length === 0) return '';
  return `

---
${parts.join('\n\n')}`;
}

function buildSystemPrompt(ctx?: SystemPromptContext): string {
  const personalization = buildPersonalizationSection(ctx);
  return BASE_SYSTEM_PROMPT + personalization;
}

// ============================================================
// JOURNAL CONTEXT FOR PROMPT
// ============================================================

function formatEntriesForContext(entries: JournalEntryPayload[]): string {
  const truncated = entries.slice(0, MAX_ENTRIES).map(e => ({
    date: e.date,
    title: e.title || 'Untitled',
    content: e.content.substring(0, MAX_CONTENT_LENGTH)
  }));
  return JSON.stringify(truncated, null, 2);
}

// ============================================================
// MAIN HANDLER
// ============================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header', code: 'AUTH_REQUIRED' }, 401);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized', code: 'AUTH_FAILED' }, 401);
    }

    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed', code: 'INVALID_METHOD' }, 405);
    }

    let body: ChatWithEntriesRequest;
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON body', code: 'INVALID_JSON' }, 400);
    }

    const { messages, entries, systemPromptContext } = body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return jsonResponse({ error: 'Messages array required and must not be empty', code: 'MISSING_MESSAGES' }, 400);
    }

    if (!entries || !Array.isArray(entries)) {
      return jsonResponse({ error: 'Entries array required', code: 'MISSING_ENTRIES' }, 400);
    }

    const validEntries = entries
      .filter(e => e?.content?.trim())
      .map(e => ({
        date: e.date || 'unknown',
        title: e.title || 'Untitled',
        content: (e.content || '').substring(0, MAX_CONTENT_LENGTH),
        word_count: e.word_count ?? 0
      }));

    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) {
      return jsonResponse({ error: 'OpenAI API key not configured', code: 'CONFIG_ERROR' }, 500);
    }

    const openai = new OpenAI({ apiKey });
    const systemPrompt = buildSystemPrompt(systemPromptContext);
    const entriesContext = formatEntriesForContext(validEntries);

    const openAIMessages: OpenAI.ChatCompletionMessageParam[] = [
      {
        role: 'system',
        content: `${systemPrompt}

---
JOURNAL ENTRIES (context for this conversation — reference by date when citing):
${entriesContext}`
      },
      ...messages.map(m => ({
        role: (m.isFromUser === 'true' ? 'user' : 'assistant') as 'user' | 'assistant',
        content: m.content
      }))
    ];

    const completion = await openai.chat.completions.create({
      model: 'gpt-4.1-nano-2025-04-14',
      messages: openAIMessages,
      temperature: 0.7,
      max_tokens: 800
    });

    const responseText = completion.choices[0]?.message?.content?.trim();
    if (!responseText) {
      return jsonResponse({ error: 'Empty response from AI', code: 'EMPTY_RESPONSE' }, 502);
    }

    const chatResponse: ChatResponse = {
      body: responseText,
      heading1: undefined,
      heading2: undefined,
      citations: undefined
    };

    return jsonResponse(chatResponse, 200);
  } catch (error) {
    console.error('chat-with-entries error:', error);
    if (error instanceof OpenAI.APIError) {
      if (error.status === 429) {
        return jsonResponse(
          { error: 'Too many requests. Please try again in a few minutes.', code: 'RATE_LIMIT' },
          429
        );
      }
      return jsonResponse(
        { error: 'AI service temporarily unavailable.', code: 'OPENAI_ERROR' },
        502
      );
    }
    return jsonResponse(
      { error: 'Failed to generate response. Please try again.', code: 'INTERNAL_ERROR' },
      500
    );
  }
});

function jsonResponse(data: ChatResponse | ErrorResponse, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}
