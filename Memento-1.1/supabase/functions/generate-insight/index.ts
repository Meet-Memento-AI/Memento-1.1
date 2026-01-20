
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { entries } = await req.json();

    if (!entries || !Array.isArray(entries) || entries.length === 0) {
      throw new Error("No journal entries provided for analysis.");
    }

    if (!GEMINI_API_KEY) {
      throw new Error("Server Error: GEMINI_API_KEY is not set.");
    }

    // 1. Construct Prompt
    const entriesText = entries.map((e: any) =>
      `Date: ${e.date || 'Unknown'}\nTitle: ${e.title}\nContent: ${e.content}`
    ).join("\n\n---\n\n");

    const prompt = `
        You are an empathetic, insightful mental health journaling assistant.
        Analyze the following user journal entries and generate a structured insight.
        
        The user is speaking to you effectively. Use "You" language. Be warm but professional.
        
        Return ONLY valid JSON with this structure, no code fences:
        {
            "headline": "A short, punchy 1-sentence summary of their emotional landscape",
            "observation": "A 2-3 sentence paragraph analyzing patterns, shifts in tone, or growth.",
            "themes": ["Theme1", "Theme2", "Theme3"],
            "suggestions": ["Actionable suggestion 1", "Actionable suggestion 2"],
            "sentiment": [
                { "label": "Emotion Name (e.g. Hope)", "score": 0-100 }
            ],
            "keywords": ["Keyword1", "Keyword2", "Keyword3"],
            "questions": ["Follow-up question 1?", "Follow-up question 2?"]
        }
        
        Entries:
        ${entriesText}
    `;

    // 2. Call Gemini API
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }]
        })
      }
    );

    const data = await response.json();

    // 3. Parse Gemini Response
    if (data.error) {
      throw new Error(`Gemini API Error: ${JSON.stringify(data.error)}`);
    }

    if (!data.candidates || data.candidates.length === 0) {
      console.error("Gemini Response:", JSON.stringify(data));
      throw new Error(`Gemini returned no candidates. Raw response: ${JSON.stringify(data)}`);
    }

    const rawText = data.candidates[0].content.parts[0].text;

    // Clean potential markdown fences if Gemini adds them
    let cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    const structuredInsight = JSON.parse(cleanJson);

    return new Response(JSON.stringify(structuredInsight), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
