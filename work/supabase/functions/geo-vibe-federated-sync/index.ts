// Supabase Edge Function: geo-vibe-federated-sync (v1)
//
// Accepts privacy-bounded, binned geo vibe updates from authenticated users.
// Stores rows in `public.geo_federated_vibe_updates_v1` using service role,
// after validating the caller JWT.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  return createClient(url, serviceKey, { auth: { persistSession: false } })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('authorization') ?? req.headers.get('Authorization') ?? ''
    const jwt = authHeader.startsWith('Bearer ') ? authHeader.slice('Bearer '.length) : authHeader
    if (!jwt) {
      return new Response(JSON.stringify({ error: 'Authorization required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const {
      schema_version,
      geo_id,
      geo_level,
      city_code,
      geohash_precision,
      time_bucket,
      signals,
      dp,
      source,
    } = body ?? {}

    if (schema_version !== 1) {
      return new Response(JSON.stringify({ error: 'Unsupported schema_version' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!geo_id || typeof geo_id !== 'string') {
      return new Response(JSON.stringify({ error: 'geo_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (!geo_level || typeof geo_level !== 'string') {
      return new Response(JSON.stringify({ error: 'geo_level required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (!signals || !Array.isArray(signals) || signals.length === 0) {
      return new Response(JSON.stringify({ error: 'signals must be a non-empty array' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = supabaseAdmin()

    // Authenticate caller (required even though we write using service role).
    const { data: userData, error: userErr } = await supabase.auth.getUser(jwt)
    if (userErr || !userData?.user?.id) {
      return new Response(JSON.stringify({ error: 'Invalid auth token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const userId = userData.user.id

    const sanitizedSignals: any[] = []
    const maxSignals = 200
    for (const s of signals.slice(0, maxSignals)) {
      if (!s || typeof s !== 'object') continue
      const geohash = typeof s.geohash === 'string' ? s.geohash : ''
      const vibe = Array.isArray(s.vibe_delta) ? s.vibe_delta : null
      const weight = typeof s.weight === 'number' ? s.weight : 1
      if (!geohash || !vibe || vibe.length !== 12) continue

      // Clamp deltas to a safe bounded range.
      const clamped = vibe.map((x: any) => {
        const n = typeof x === 'number' ? x : 0
        return Math.max(-0.35, Math.min(0.35, n))
      })
      sanitizedSignals.push({
        geohash,
        vibe_delta: clamped,
        weight: Math.max(0, Math.min(5, weight)),
        intent: typeof s.intent === 'string' ? s.intent : undefined,
      })
    }

    if (sanitizedSignals.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid signals provided' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const row = {
      user_id: userId,
      geo_id,
      geo_level,
      city_code: typeof city_code === 'string' ? city_code : null,
      geohash_precision: typeof geohash_precision === 'number' ? geohash_precision : 7,
      time_bucket: time_bucket && typeof time_bucket === 'object' ? time_bucket : {},
      signals: sanitizedSignals,
      dp: dp && typeof dp === 'object' ? dp : {},
      source: typeof source === 'string' ? source : 'unknown',
    }

    const { error: insertErr } = await supabase.from('geo_federated_vibe_updates_v1').insert(row)
    if (insertErr) {
      return new Response(JSON.stringify({ error: 'Insert failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true, inserted: 1, accepted_signals: sanitizedSignals.length }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

