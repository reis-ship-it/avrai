// Edge Function: Rooms Coordinator (server-only)
// - Creates rooms
// - Manages room_memberships
// - Seeds/moderates room_messages

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

async function handleCreateRoom(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as { metadata?: JsonRecord }
  const metadata = body?.metadata ?? {}
  const { data, error } = await sb.rpc('create_room', { p_metadata: metadata })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ room_id: data as string })
}

async function handleJoinRoom(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as { room_id: string; user_id: string }
  if (!body?.room_id || !body?.user_id) {
    return Response.json({ error: 'room_id and user_id required' }, { status: 400 })
  }
  const { error } = await sb.rpc('add_membership', {
    p_room_id: body.room_id,
    p_user_id: body.user_id,
  })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ ok: true })
}

async function handlePostRoomMessage(req: Request) {
  const sb = supabaseAdmin()
  const body = (await req.json()) as { room_id: string; sender_id: string; payload: JsonRecord }
  if (!body?.room_id || !body?.sender_id || !body?.payload) {
    return Response.json({ error: 'room_id, sender_id, payload required' }, { status: 400 })
  }
  // Only members can post; rely on RLS + service role insert here for moderation
  const { error } = await sb.rpc('post_room_message', {
    p_room_id: body.room_id,
    p_sender_id: body.sender_id,
    p_payload: body.payload,
  })
  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ ok: true })
}

serve(async (req) => {
  if (!isAuthorized(req)) return new Response('Forbidden', { status: 403 })
  const url = new URL(req.url)
  const segments = url.pathname.split('/').filter(Boolean)
  const last = segments.length > 0 ? segments[segments.length - 1] : ''
  if (req.method === 'GET') {
    return Response.json({ status: 'ok', agent: 'rooms-coordinator' })
  }
  if (req.method === 'POST' && (last === 'create')) {
    return await handleCreateRoom(req)
  }
  if (req.method === 'POST' && (last === 'join')) {
    return await handleJoinRoom(req)
  }
  if (req.method === 'POST' && (last === 'post')) {
    return await handlePostRoomMessage(req)
  }
  return new Response('Not Found', { status: 404 })
})


