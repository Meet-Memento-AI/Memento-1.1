
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
        const { messages, entries } = await req.json();

        if (!messages || !Array.isArray(messages)) {
            throw new Error("No messages provided.");
        }

        // Entries are optional (e.g. if chat continues without new context), but we usually expect them.
        const entriesContext = (entries && Array.isArray(entries))
            ? entries.map((e: any) => `Date: ${e.date}\nTitle: ${e.title}\nContent: ${e.content}`).join("\n\n---\n\n")
            : "No specific journal entries provided for this context.";

        if (!GEMINI_API_KEY) {
            throw new Error("Server Error: GEMINI_API_KEY is not set.");
        }

        // Convert messages to text history for the prompt
        // We only take the last few messages to save tokens/complexity, but for now take all.
        const conversationHistory = messages.map((m: any) => {
            const role = (m.isFromUser === "true" || m.isFromUser === true) ? "User" : "AI";
            return `${role}: ${m.content}`;
        }).join("\n");

        const systemPrompt = `
        You are "Memento", an empathetic and insightful mental health journaling companion.
        Your goal is to help the user understand themselves better by discussing their journal entries.
        
        CONTEXT:
        The user has provided the following journal entries from a specific time period:
        
        ${entriesContext}
        
        INSTRUCTIONS:
        1. Answer the user's latest question based *primarily* on the provided journal entries.
        2. Be warm, supportive, and non-judgmental.
        3. If you reference a specific event, try to mention the date or title if relevant contextually.
        4. If the user asks something not in the entries, politely say you don't see that in the current records but offer general support.
        
        OUTPUT FORMAT:
        You must return ONLY valid JSON matching this structure (no markdown fences):
        {
          "heading1": "Optional short title (e.g., 'A Pattern of Resilience')",
          "heading2": "Optional subtitle",
          "body": "The main response text. Use **bold** for emphasis. You can use markdown.",
          "citations": [
             {
               "entryId": "UUID of the entry if known (or null)", 
               "entryTitle": "Title of entry", 
               "entryDate": "ISO Date String", 
               "excerpt": "Short relevant quote"
             }
          ]
        }
        
        *Note on Citations*: If you explicitly reference a specific entry, include it in the 'citations' array. We will try to link it in the UI. 
        If you don't verify the UUID is correct, better to omit the ID or just use title/date.
        Actually, since you (AI) don't have the UUIDs reliably unless passed in 'entries', relying on index might be hard.
        For this version, you can return 'citations' with 'entryTitle' and 'entryDate' that matches the input.
        
        CONVERSATION HISTORY:
        ${conversationHistory}
        
        AI Response:
    `;

        // 2. Call Gemini API
        const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${GEMINI_API_KEY}`,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: systemPrompt }] }]
                })
            }
        );

        const data = await response.json();

        // 3. Parse Gemini Response
        if (data.error) {
            throw new Error(`Gemini API Error: ${JSON.stringify(data.error)}`);
        }

        if (!data.candidates || data.candidates.length === 0) {
            console.error("Gemini Failure", JSON.stringify(data));
            throw new Error("Gemini returned no candidates.");
        }

        const rawText = data.candidates[0].content.parts[0].text;
        let cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

        // Attempt parse
        let structuredResponse;
        try {
            structuredResponse = JSON.parse(cleanJson);
        } catch (e) {
            // Fallback if AI fails to return JSON (it happens)
            console.error("Failed to parse JSON", cleanJson);
            structuredResponse = {
                body: rawText // Return raw text as body
            };
        }

        return new Response(JSON.stringify(structuredResponse), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
