// Edge Function: Global AI2AI Coordinator
// - Runs with service role
// - Posts private profile summaries to users' AIs via `private_messages`
// - Provides minimal secure endpoints for backend-only use

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type JsonRecord = Record<string, unknown>

function isAuthorized(req: Request): boolean {
  const headerSecret = req.headers.get('x-service-key') ?? ''
  const bearer = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '')
  const envSecret = Deno.env.get('SERVICE_CALL_SECRET') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const bySecret = envSecret.length > 0 && headerSecret === envSecret
  const byBearer = serviceKey.length > 0 && bearer === serviceKey
  return bySecret || byBearer
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
    db: { schema: 'api' },
  })
}

async function handleProfileSummary(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as {
    recipient_id: string
    summary: JsonRecord
  }

  if (!body?.recipient_id || !body?.summary) {
    return Response.json({ error: 'recipient_id and summary required' }, { status: 400 })
  }

  const { error } = await sb.rpc('send_private_message', {
    p_recipient: body.recipient_id,
    p_payload: { type: 'profile_summary', ...body.summary },
  })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ ok: true })
}

async function handleDirectMessage(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as {
    recipient_id: string
    payload: JsonRecord
  }

  if (!body?.recipient_id || !body?.payload) {
    return Response.json({ error: 'recipient_id and payload required' }, { status: 400 })
  }

  const { error } = await sb.rpc('send_private_message', {
    p_recipient: body.recipient_id,
    p_payload: body.payload,
  })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ ok: true })
}

async function handleProfileSummaryByEmail(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as {
    recipient_email: string
    summary: JsonRecord
  }

  if (!body?.recipient_email || !body?.summary) {
    return Response.json({ error: 'recipient_email and summary required' }, { status: 400 })
  }

  // Try Admin API first (auth schema)
  let userId: string | null = null
  try {
    const { data, error } = await sb.auth.admin.listUsers({ page: 1, perPage: 1000 })
    if (!error && data?.users?.length) {
      const found = data.users.find((u: any) => (u.email ?? '').toLowerCase() === body.recipient_email.toLowerCase())
      if (found?.id) userId = found.id
    }
  } catch (_) {}

  // No public fallback: api-only lockdown
  if (!userId) {
    return Response.json({ error: `User not found for ${body.recipient_email}` }, { status: 404 })
  }

  const { error } = await sb.rpc('send_private_message', {
    p_recipient: userId,
    p_payload: { type: 'profile_summary', ...body.summary },
  })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ ok: true, to_user_id: userId })
}

serve(async (req) => {
  try {
    if (!isAuthorized(req)) return new Response('Forbidden', { status: 403 })

    const url = new URL(req.url)
    const segments = url.pathname.split('/').filter(Boolean)
    const last = segments.length > 0 ? segments[segments.length - 1] : ''

    if (req.method === 'GET') {
      return Response.json({ status: 'ok', agent: 'global-coordinator' })
    }

    if (req.method === 'POST' && (last === 'profile-summary')) {
      return await handleProfileSummary(req)
    }
    if (req.method === 'POST' && (last === 'profile-summary-by-email')) {
      return await handleProfileSummaryByEmail(req)
    }

    if (req.method === 'POST' && last === 'dm') {
      return await handleDirectMessage(req)
    }

    return new Response('Not Found', { status: 404 })
  } catch (e) {
    console.error('Coordinator error', e)
    return Response.json({ error: (e as Error).message ?? 'internal' }, { status: 500 })
  }
})


