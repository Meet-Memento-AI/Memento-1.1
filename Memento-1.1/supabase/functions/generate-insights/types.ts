// types.ts
//
// TypeScript type definitions for generate-insights edge function
// Defines request/response interfaces for journal insights generation
//

// ============================================================
// REQUEST TYPES (from Swift app)
// ============================================================

/**
 * A single journal entry from the Swift app
 */
export interface JournalEntry {
  date: string;          // ISO8601 format: "2025-10-23T10:30:00Z"
  title: string;         // Entry title (may be empty string)
  content: string;       // Entry text content
  word_count: number;    // Pre-calculated word count
  mood?: string;         // Optional mood tag (e.g., "anxious", "happy")
}

/**
 * Request body from Swift app
 */
export interface GenerateInsightsRequest {
  entries: JournalEntry[];
  force_refresh?: boolean;   // Optional: Skip cache and generate fresh insights
}

// ============================================================
// OPENAI RESPONSE TYPES (matches prompt schema)
// ============================================================

/**
 * Reference to a journal entry that contributed to a theme
 */
export interface SourceEntry {
  date: string;          // YYYY-MM-DD format: "2025-10-23"
  title: string;         // Exact entry title
}

/**
 * A date annotation representing a significant emotional moment
 */
export interface Annotation {
  date: string;          // YYYY-MM-DD format: "2025-10-23"
  summary: string;       // 2-3 sentence paragraph explaining what happened emotionally
}

/**
 * A single identified theme from journal analysis
 */
export interface Theme {
  name: string;          // 2-4 word specific theme name (e.g., "Work Performance Anxiety")
  icon: string;          // Single emoji (e.g., "📊")
  explanation: string;   // One sentence (max 60 words) explaining why this theme matters
  frequency: string;     // Format: "X times this week/month" with actual numbers
  source_entries: SourceEntry[];  // Array of objects with date + title
}

/**
 * OpenAI's response structure (matches your prompt schema exactly)
 */
export interface OpenAIInsightResponse {
  summary: string;         // One sentence capturing main emotional themes (max 140 chars)
  description: string;     // 150-180 word paragraph describing emotional landscape
  annotations: Annotation[]; // 3-5 significant emotional moments with context
  themes: Theme[];         // Exactly 4-5 themes (not fewer, not more)
}

// ============================================================
// DATABASE TYPES (Supabase cache)
// ============================================================

/**
 * Cached insight from user_insights table
 */
export interface CachedInsight {
  id: string;                         // UUID
  content: OpenAIInsightResponse;     // JSONB content
  generated_at: string;               // ISO8601 timestamp
  entries_analyzed_count: number;     // How many entries analyzed
  expires_at: string;                 // When cache expires
}

// ============================================================
// API RESPONSE TYPE (to Swift app)
// ============================================================

/**
 * Response sent back to Swift app
 * Matches Swift JournalInsights model
 */
export interface InsightsResponse {
  summary: string;              // From OpenAI response
  description: string;          // From OpenAI response
  annotations: Annotation[];    // From OpenAI response
  themes: Theme[];              // From OpenAI response
  entriesAnalyzed: number;      // How many entries were analyzed
  generatedAt: string;          // ISO8601 timestamp
  fromCache: boolean;           // True if served from cache, false if freshly generated
  cacheExpiresAt?: string;      // Optional: when cache expires (ISO8601)
}

// ============================================================
// ERROR TYPES
// ============================================================

/**
 * Error response sent to client
 */
export interface ErrorResponse {
  error: string;          // User-friendly error message
  code: string;           // Error code for client handling
  retryAfter?: number;    // Optional: seconds to wait before retry (for rate limits)
}

/**
 * Error codes used in responses
 */
export enum ErrorCode {
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  AUTH_FAILED = 'AUTH_FAILED',
  INVALID_JSON = 'INVALID_JSON',
  MISSING_ENTRIES = 'MISSING_ENTRIES',
  INVALID_ENTRIES = 'INVALID_ENTRIES',
  TOO_MANY_ENTRIES = 'TOO_MANY_ENTRIES',
  EMPTY_CONTENT = 'EMPTY_CONTENT',
  CACHE_ERROR = 'CACHE_ERROR',
  OPENAI_ERROR = 'OPENAI_ERROR',
  RATE_LIMIT = 'RATE_LIMIT',
  NETWORK_ERROR = 'NETWORK_ERROR',
  INVALID_RESPONSE = 'INVALID_RESPONSE',
  INTERNAL_ERROR = 'INTERNAL_ERROR'
}
