
const fs = require('fs');
const path = require('path');
const https = require('https');

// Load .env manually
const envPath = path.resolve(__dirname, '.env');
if (fs.existsSync(envPath)) {
    const envConfig = fs.readFileSync(envPath, 'utf-8');
    envConfig.split('\n').forEach(line => {
        const [key, value] = line.split('=');
        if (key && value) {
            process.env[key.trim()] = value.trim();
        }
    });
}

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const FUNCTION_NAME = "chat-with-entries";

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error("Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env");
    console.error("Please create a .env file with these variables.");
    process.exit(1);
}

// 1. Mock Data
const mockEntries = [
    {
        id: "123",
        title: "Stressed at work",
        content: "I feel like I'm drowning in deadlines. My boss keeps adding more tasks.",
        date: "2024-05-20"
    },
    {
        id: "456",
        title: "Morning Walk",
        content: "Took a walk today. The fresh air helped me calm down a bit.",
        date: "2024-05-21"
    }
];

const mockMessages = [
    {
        content: "I've been feeling really overwhelmed lately.",
        isFromUser: true
    },
    {
        content: "I hear you. It sounds like there's a lot on your plate. What specifically is making you feel this way?",
        isFromUser: false
    },
    {
        content: "Mostly work. I don't know how to handle it.",
        isFromUser: true
    }
];

// 2. Prepare Payload
const payload = JSON.stringify({
    messages: mockMessages,
    entries: mockEntries
});

// 3. Request Options
const url = new URL(`${SUPABASE_URL}/functions/v1/${FUNCTION_NAME}`);
const options = {
    hostname: url.hostname,
    path: url.pathname,
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
    }
};

console.log(`\n💬 Testing '${FUNCTION_NAME}'...`);
console.log(`Payload: ${mockMessages.length} messages, ${mockEntries.length} entries\n`);

// 4. Send Request
const req = https.request(options, (res) => {
    let responseBody = '';

    res.on('data', (chunk) => {
        responseBody += chunk;
    });

    res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
            try {
                const data = JSON.parse(responseBody);
                console.log("✅ Success! AI Response:\n");
                console.log("Heading:", data.heading1);
                console.log("Body:", data.body);
                console.log("Citations:", data.citations);
            } catch (e) {
                console.error("❌ Failed to parse response:", responseBody);
            }
        } else {
            console.error(`❌ Error (${res.statusCode}):`, responseBody);
        }
    });
});

req.on('error', (e) => {
    console.error(`❌ Request Error: ${e.message}`);
});

req.write(payload);
req.end();
