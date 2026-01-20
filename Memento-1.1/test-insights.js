const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// 1. Load .env manually
const env = {};
try {
    const envPath = path.join(__dirname, '.env');
    if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        envContent.split('\n').forEach(line => {
            const parts = line.split('=');
            if (parts.length >= 2) {
                const key = parts[0].trim();
                const value = parts.slice(1).join('=').trim();
                if (key && !key.startsWith('#')) {
                    env[key] = value;
                }
            }
        });
    }
} catch (e) {
    console.error('Failed to read .env file:', e);
}

// 2. Configuration
const USE_PRODUCTION = true;
const LOCAL_URL = 'http://localhost:54321/functions/v1/generate-insight';
const PRODUCTION_URL = 'https://fhsgvlbedqwxwpubtlls.supabase.co/functions/v1/generate-insight';
const ENDPOINT_URL = USE_PRODUCTION ? PRODUCTION_URL : LOCAL_URL;

const USER_TOKEN = env.USER_ACCESS_TOKEN || process.env.USER_ACCESS_TOKEN;
const ANON_KEY = env.SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY;

if (!ANON_KEY) {
    console.error('❌ Error: SUPABASE_ANON_KEY not found in .env');
    process.exit(1);
}

if (!USER_TOKEN) {
    console.warn('⚠️ Warning: USER_ACCESS_TOKEN not found in .env');
    console.warn('   Using SUPABASE_ANON_KEY instead. This may fail if the function enforces User JWT.');
}

const TOKEN_TO_USE = USER_TOKEN || ANON_KEY;

// ANSI Colors
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
};

// 3. Test Scenarios
const testScenarios = [
    {
        name: "3 Entries - Minimum for Insights",
        forceRefresh: false,
        entries: [
            {
                date: "2025-01-15T10:00:00Z",
                title: "Morning Anxiety",
                content: "Woke up feeling anxious about the presentation today. Can't shake this feeling of dread. Keep replaying worst-case scenarios in my head.",
                word_count: 22,
                mood: "anxious"
            },
            {
                date: "2025-01-16T14:30:00Z",
                title: "Presentation Relief",
                content: "The presentation went better than expected! Everyone seemed engaged and I got positive feedback. Still can't believe I pulled it off.",
                word_count: 24,
                mood: "relieved"
            },
            {
                date: "2025-01-17T09:00:00Z",
                title: "Weekend Reset",
                content: "Planning a solo hike this weekend. Nature always helps me process emotions and gain perspective. Looking forward to some quiet time.",
                word_count: 23,
                mood: "hopeful"
            }
        ]
    }
];

// Helper to make HTTP request
function makeRequest(urlStr, options, body) {
    return new Promise((resolve, reject) => {
        const lib = urlStr.startsWith('https') ? https : http;
        const req = lib.request(urlStr, options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    resolve({ statusCode: res.statusCode, data: json });
                } catch (e) {
                    resolve({ statusCode: res.statusCode, data: data, error: e });
                }
            });
        });

        req.on('error', (e) => reject(e));
        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

// 4. Test Runner
async function runTests() {
    console.log(`\n${colors.bright}${colors.blue}╔════════════════════════════════════════════════════╗${colors.reset}`);
    console.log(`${colors.bright}${colors.blue}║  Generate Insights Node.js Test Runner            ║${colors.reset}`);
    console.log(`${colors.bright}${colors.blue}╚════════════════════════════════════════════════════╝${colors.reset}`);

    console.log(`Target: ${ENDPOINT_URL}`);
    console.log(`Token: ${TOKEN_TO_USE ? TOKEN_TO_USE.substring(0, 10) + '...' : 'NONE'}\n`);

    for (const scenario of testScenarios) {
        console.log(`${colors.cyan}Running: ${scenario.name}${colors.reset}`);
        const start = Date.now();

        try {
            const response = await makeRequest(ENDPOINT_URL, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${TOKEN_TO_USE}`,
                    'apikey': ANON_KEY,
                    'Content-Type': 'application/json'
                }
            }, {
                entries: scenario.entries,
                force_refresh: scenario.forceRefresh
            });

            const duration = Date.now() - start;

            if (response.statusCode >= 200 && response.statusCode < 300) {
                console.log(`${colors.green}✅ Success (${duration}ms)${colors.reset}`);
                console.log('Response Headline:', response.data.headline);
                if (response.data.themes) {
                    console.log('Themes found:', response.data.themes.length);
                }
            } else {
                console.log(`${colors.red}❌ Failed (${response.statusCode})${colors.reset}`);
                console.log('Error:', JSON.stringify(response.data, null, 2));
            }
        } catch (err) {
            console.log(`${colors.red}❌ Network Error${colors.reset}`, err);
        }
        console.log('');
    }
}

runTests();
