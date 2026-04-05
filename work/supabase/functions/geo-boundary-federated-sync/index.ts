// Supabase Edge Function: geo-boundary-federated-sync (v1)
//
// Accepts privacy-bounded, binned boundary votes (geohash cell counts) from
// authenticated users, and stores them in `public.geo_federated_boundary_updates_v1`.

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
      city_code,
      locality_code,
      geohash_precision,
      cells,
      dp,
      source,
    } = body ?? {}

    if (schema_version !== 1) {
      return new Response(JSON.stringify({ error: 'Unsupported schema_version' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!city_code || typeof city_code !== 'string') {
      return new Response(JSON.stringify({ error: 'city_code required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (!locality_code || typeof locality_code !== 'string') {
      return new Response(JSON.stringify({ error: 'locality_code required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (!cells || !Array.isArray(cells) || cells.length === 0) {
      return new Response(JSON.stringify({ error: 'cells must be a non-empty array' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = supabaseAdmin()
    const { data: userData, error: userErr } = await supabase.auth.getUser(jwt)
    if (userErr || !userData?.user?.id) {
      return new Response(JSON.stringify({ error: 'Invalid auth token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const userId = userData.user.id

    const sanitizedCells: any[] = []
    const maxCells = 300
    for (const c of cells.slice(0, maxCells)) {
      if (!c || typeof c !== 'object') continue
      const geohash = typeof c.geohash === 'string' ? c.geohash : ''
      const inside = typeof c.inside_votes === 'number' ? c.inside_votes : 0
      const outside = typeof c.outside_votes === 'number' ? c.outside_votes : 0
      if (!geohash) continue
      sanitizedCells.push({
        geohash,
        inside_votes: Math.max(0, Math.min(5000, Math.floor(inside))),
        outside_votes: Math.max(0, Math.min(5000, Math.floor(outside))),
        weight_sum: typeof c.weight_sum === 'number' ? Math.max(0, Math.min(1e6, c.weight_sum)) : undefined,
      })
    }

    if (sanitizedCells.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid cells provided' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const row = {
      user_id: userId,
      city_code,
      locality_code,
      geohash_precision: typeof geohash_precision === 'number' ? geohash_precision : 7,
      cells: sanitizedCells,
      dp: dp && typeof dp === 'object' ? dp : {},
      source: typeof source === 'string' ? source : 'unknown',
    }

    const { error: insertErr } = await supabase.from('geo_federated_boundary_updates_v1').insert(row)
    if (insertErr) {
      return new Response(JSON.stringify({ error: 'Insert failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true, inserted: 1, accepted_cells: sanitizedCells.length }), {
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

