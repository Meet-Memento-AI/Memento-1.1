// types.ts
//
// TypeScript type definitions for new-user-insights edge function
//

export interface Theme {
  id?: string;  // Optional - database UUID, not sent in response
  name: string;
  title: string;
  summary: string;
  keywords: string[];
  emoji: string;
  category: string;
}

export interface ThemeScore {
  theme: Theme;
  score: number;
  matchedKeywords: string[];
}

export interface AnalysisRequest {
  selfReflectionText: string;
}

export interface AnalysisResponse {
  themes: Theme[];
  recommendedCount: number;
  analyzedAt: string;
  themeCount: number;
}

export interface ErrorResponse {
  error: string;
  code?: string;
  retryAfter?: string;
}
