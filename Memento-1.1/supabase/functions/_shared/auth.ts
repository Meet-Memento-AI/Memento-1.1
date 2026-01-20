// _shared/auth.ts
//
// Authentication helper functions shared across edge functions
//
// Purpose:
// - Extract and validate JWT tokens from requests
// - Create authenticated Supabase clients
// - Get current user from JWT
// - Return standardized error responses for auth failures
//
// Usage:
// import { authenticateUser, createAuthenticatedClient } from '../_shared/auth.ts'

// TODO: Import dependencies
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// TODO: Implement createAuthenticatedClient()
// export function createAuthenticatedClient(authHeader: string) {
//   return createClient(
//     Deno.env.get('SUPABASE_URL') ?? '',
//     Deno.env.get('SUPABASE_ANON_KEY') ?? '',
//     { global: { headers: { Authorization: authHeader } } }
//   )
// }

// TODO: Implement authenticateUser()
// export async function authenticateUser(req: Request) {
//   const authHeader = req.headers.get('Authorization')
//
//   if (!authHeader) {
//     throw new Error('Missing authorization header')
//   }
//
//   const supabase = createAuthenticatedClient(authHeader)
//   const { data: { user }, error } = await supabase.auth.getUser()
//
//   if (error || !user) {
//     throw new Error('Unauthorized')
//   }
//
//   return { user, supabase }
// }

// TODO: Export auth error response helper
// export function authErrorResponse(message: string): Response {
//   return new Response(
//     JSON.stringify({ error: message }),
//     { status: 401, headers: { 'Content-Type': 'application/json' } }
//   )
// }
