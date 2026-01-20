// _shared/cors.ts
//
// Common CORS (Cross-Origin Resource Sharing) headers
// Used across all edge functions
//
// Purpose:
// - Define CORS headers for browser requests
// - Handle preflight OPTIONS requests
// - Allow requests from Swift app and web browsers
//
// Usage:
// import { corsHeaders } from '../_shared/cors.ts'

// TODO: Export CORS headers object
// export const corsHeaders = {
//   'Access-Control-Allow-Origin': '*',
//   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
//   'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
// }

// TODO: Export helper function for OPTIONS requests
// export function handleCorsPrelight(): Response {
//   return new Response('ok', { headers: corsHeaders })
// }

// Note: In production, you might want to restrict 'Access-Control-Allow-Origin'
// to specific domains instead of '*' for better security
