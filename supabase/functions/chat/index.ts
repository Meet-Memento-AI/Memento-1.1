// index.ts
//
// Edge function: chat
//
// RAG chatbot endpoint. The iOS app sends a user message. This
// function embeds the question, retrieves similar journal entries
// via pgvector, builds a prompt with that context, calls Gemini
// 2.5 Flash, persists the conversation, and returns the response.
//
// Deploy: supabase functions deploy chat
//

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ============================================================
// CONFIGURATION
// ============================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const GEMINI_EMBEDDING_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';

const GEMINI_CHAT_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

const SYSTEM_PROMPT = `You are Memento, a thoughtful AI companion who knows the user through their journal entries. You help them reflect on their experiences and notice patterns in their life.

Be warm and conversational, like a trusted friend who happens to have a great memory. Reference journal entries naturally when relevant — say things like "A couple weeks ago you wrote about..." rather than citing entry IDs or dates mechanically.

If the user asks about something their journal entries don't cover, say so honestly: "I don't see anything about that in your journal yet."

Never invent or assume journal content that wasn't provided to you in the context.

Keep responses to 2-3 paragraphs. Write in natural, flowing paragraphs. End with one follow-up question to encourage deeper reflection.

If the user seems distressed, be supportive and suggest they talk to someone they trust.`;

const MATCH_COUNT = 5;
const MATCH_THRESHOLD = 0.3;
const HISTORY_LIMIT = 10;

// ============================================================
// TYPES
// ============================================================

interface ChatRequest {
  message: string;
}

interface GeminiEmbeddingResponse {
  embedding: { values: number[] };
}

interface MatchedEntry {
  id: string;
  content: string;
  created_at: string;
  similarity: number;
}

interface ChatMessageRow {
  role: string;
  content: string;
}

interface ChatSource {
  id: string;
  created_at: string;
  preview: string;
}

// ============================================================
// MAIN HANDLER
// ============================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ============================================================
    // 1. AUTHENTICATE
    // ============================================================

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
      console.error('Auth error:', userError);
      return jsonResponse({ error: 'Unauthorized', code: 'AUTH_FAILED' }, 401);
    }

    // ============================================================
    // 2. PARSE REQUEST
    // ============================================================

    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    let body: ChatRequest;
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON body' }, 400);
    }

    const userMessage = body.message?.trim();
    if (!userMessage) {
      return jsonResponse({ error: 'Message is required' }, 400);
    }

    console.log(`💬 Chat request from user ${user.id.substring(0, 8)}...`);

    // ============================================================
    // 3. EMBED THE USER'S QUESTION
    // ============================================================

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    const queryEmbedding = await generateEmbedding(userMessage, geminiApiKey);

    // ============================================================
    // 4. PGVECTOR SIMILARITY SEARCH
    // ============================================================

    const vectorLiteral = `[${queryEmbedding.join(',')}]`;

    const { data: matchedEntries, error: rpcError } = await supabase.rpc('match_journal_entries', {
      query_embedding: vectorLiteral,
      match_user_id: user.id,
      match_count: MATCH_COUNT,
      match_threshold: MATCH_THRESHOLD,
    });

    if (rpcError) {
      console.error('RPC error:', rpcError);
    }

    const entries: MatchedEntry[] = matchedEntries ?? [];
    console.log(`📚 Found ${entries.length} matching journal entries`);

    // ============================================================
    // 5. LOAD CONVERSATION HISTORY
    // ============================================================

    const { data: historyRows } = await supabase
      .from('chat_messages')
      .select('role, content')
      .eq('user_id', user.id)
      .order('created_at', { ascending: true })
      .limit(HISTORY_LIMIT);

    const history: ChatMessageRow[] = historyRows ?? [];

    // ============================================================
    // 6. BUILD CONTEXT BLOCK
    // ============================================================

    const contextBlock = buildContextBlock(entries);

    // ============================================================
    // 7. ASSEMBLE & CALL GEMINI 2.5 FLASH
    // ============================================================

    const geminiContents = buildGeminiContents(history, contextBlock, userMessage);

    const geminiResponse = await fetch(`${GEMINI_CHAT_URL}?key=${geminiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: geminiContents,
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 800,
        },
      }),
    });

    let replyText: string;

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error(`Gemini API error ${geminiResponse.status}: ${errText}`);
      replyText = "I'm having trouble connecting right now. Please try again in a moment.";
    } else {
      const geminiData = await geminiResponse.json();
      replyText =
        geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ??
        "I'm having trouble connecting right now. Please try again in a moment.";
    }

    // ============================================================
    // 8. PERSIST MESSAGES
    // ============================================================

    const { error: insertError } = await supabase.from('chat_messages').insert([
      { user_id: user.id, role: 'user', content: userMessage },
      { user_id: user.id, role: 'assistant', content: replyText },
    ]);

    if (insertError) {
      console.error('Failed to persist messages:', insertError);
    }

    // ============================================================
    // 9. RETURN RESPONSE
    // ============================================================

    const sources: ChatSource[] = entries.map((e) => ({
      id: e.id,
      created_at: e.created_at,
      preview: e.content.substring(0, 100),
    }));

    return jsonResponse({ reply: replyText, sources }, 200);

  } catch (error) {
    console.error('❌ Chat function error:', error);
    return jsonResponse(
      {
        reply: "I'm having trouble connecting right now. Please try again in a moment.",
        sources: [],
      },
      200
    );
  }
});

// ============================================================
// HELPERS
// ============================================================

async function generateEmbedding(text: string, apiKey: string): Promise<number[]> {
  const response = await fetch(`${GEMINI_EMBEDDING_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'models/gemini-embedding-001',
      content: { parts: [{ text }] },
      outputDimensionality: 768,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Embedding API error ${response.status}: ${errText}`);
  }

  const data: GeminiEmbeddingResponse = await response.json();
  const values = data.embedding?.values;
  if (!values || values.length < 768) {
    throw new Error(`Unexpected embedding dimensions: ${values?.length ?? 0}`);
  }
  // Use first 768 dimensions if outputDimensionality was ignored (e.g., 3072 from gemini-embedding-001)
  return values.length === 768 ? values : values.slice(0, 768);
}

function buildContextBlock(entries: MatchedEntry[]): string {
  if (entries.length === 0) {
    return '[No journal entries matched this topic]';
  }

  const formatted = entries.map((e) => {
    const date = new Date(e.created_at);
    const label = date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    return `[${label}] ${e.content}`;
  });

  return [
    '[Journal context — reference these naturally, do not quote them verbatim]',
    '',
    ...formatted,
    '',
    '[End of journal context]',
  ].join('\n');
}

function buildGeminiContents(
  history: ChatMessageRow[],
  contextBlock: string,
  currentMessage: string
): Array<{ role: string; parts: Array<{ text: string }> }> {
  const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

  for (const msg of history) {
    contents.push({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }],
    });
  }

  // Current message with context prepended
  contents.push({
    role: 'user',
    parts: [{ text: `${contextBlock}\n\n${currentMessage}` }],
  });

  return contents;
}

function jsonResponse(data: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
