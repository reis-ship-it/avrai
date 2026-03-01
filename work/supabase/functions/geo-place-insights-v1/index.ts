// Supabase Edge Function: geo-place-insights-v1 (v1)
//
// Tiered place insights API.
// - First-party app: authenticated JWT (returns general synco by default)
// - Third parties: x-api-key (hashed lookup) determines tier:
//     - general: general synco only
//     - full: general synco + vibe signatures
//     - everything: full + knot signatures

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-api-key',
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  return createClient(url, serviceKey, { auth: { persistSession: false } })
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('')
}

type Tier = 'general' | 'full' | 'everything'

function normalizeTier(t: unknown): Tier {
  const s = (typeof t === 'string' ? t : '').toLowerCase()
  if (s === 'everything') return 'everything'
  if (s === 'full') return 'full'
  return 'general'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = supabaseAdmin()

    const body = await req.json().catch(() => ({}))
    const geo_id = (body.geo_id ?? body.geoId ?? '').toString()
    const geo_level = (body.geo_level ?? body.geoLevel ?? '').toString()
    const include = (body.include && typeof body.include === 'object') ? body.include : {}

    if (!geo_id || !geo_level) {
      return new Response(JSON.stringify({ error: 'geo_id and geo_level required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Determine caller tier.
    const apiKey = req.headers.get('x-api-key') ?? ''
    let tier: Tier = 'general'
    let caller: 'first_party' | 'third_party' = 'first_party'

    if (apiKey) {
      caller = 'third_party'
      const keyHash = await sha256Hex(apiKey)
      const { data, error } = await supabase
        .from('api_keys_v1')
        .select('tier,is_active,rate_limit_per_min')
        .eq('key_hash', keyHash)
        .limit(1)
        .maybeSingle()

      if (error || !data || data.is_active !== true) {
        return new Response(JSON.stringify({ error: 'Invalid API key' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      tier = normalizeTier(data.tier)

      // Enforce per-minute rate limit (server-side, atomic).
      const limit = typeof data.rate_limit_per_min === 'number' ? data.rate_limit_per_min : 60
      const { data: allowed, error: rlErr } = await supabase.rpc('api_key_rate_limit_check_v1', {
        p_key_hash: keyHash,
        p_limit_per_min: limit,
      })
      if (rlErr || allowed !== true) {
        return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Best-effort: update last_used_at (ignore failures).
      await supabase
        .from('api_keys_v1')
        .update({ last_used_at: new Date().toISOString() })
        .eq('key_hash', keyHash)
    } else {
      // First-party requires auth (keeps paywall meaningful).
      const authHeader = req.headers.get('authorization') ?? req.headers.get('Authorization') ?? ''
      const jwt = authHeader.startsWith('Bearer ') ? authHeader.slice('Bearer '.length) : authHeader
      if (!jwt) {
        return new Response(JSON.stringify({ error: 'Authorization required' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      const { data: userData, error: userErr } = await supabase.auth.getUser(jwt)
      if (userErr || !userData?.user?.id) {
        return new Response(JSON.stringify({ error: 'Invalid auth token' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      tier = 'general'
    }

    // Enforce include flags based on tier.
    const wantSummary = include.summary !== false // default true
    const wantVibe = include.vibe === true
    const wantKnot = include.knot === true
    const wantDebug = include.debug === true

    const allowVibe = tier === 'full' || tier === 'everything'
    const allowKnot = tier === 'everything'
    const allowDebug = wantDebug && caller === 'first_party' // reserved for internal

    const response: Record<string, unknown> = {
      geo_id,
      geo_level,
      tier,
    }

    if (wantSummary) {
      // Prefer audience-specific rows if present; fall back to general.
      const preferredAudience =
        caller === 'third_party'
          ? (tier === 'general' ? 'third_party_general' : tier === 'full' ? 'third_party_full' : 'third_party_everything')
          : 'general_synco'

      const { data: row } = await supabase
        .from('geo_synco_summaries_v1')
        .select('audience,summary_json,summary_text,updated_at')
        .eq('geo_id', geo_id)
        .in('audience', [preferredAudience, 'general_synco'])
        .order('updated_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (row) {
        response['summary'] = {
          audience: row.audience,
          summary_json: row.summary_json,
          summary_text: row.summary_text,
          updated_at: row.updated_at,
        }
      } else {
        response['summary'] = null
      }
    }

    if (wantVibe && allowVibe) {
      const { data: row } = await supabase
        .from('geo_vibe_signatures_v1')
        .select('schema_version,base_vibe,time_modulations,confidence,source,updated_at')
        .eq('geo_id', geo_id)
        .limit(1)
        .maybeSingle()
      response['vibe'] = row ?? null
    } else if (wantVibe) {
      response['vibe'] = null
    }

    if (wantKnot && allowKnot) {
      const { data: row } = await supabase
        .from('geo_knot_signatures_v1')
        .select('schema_version,knot_invariants,knot_metadata,updated_at')
        .eq('geo_id', geo_id)
        .limit(1)
        .maybeSingle()
      response['knot'] = row ?? null
    } else if (wantKnot) {
      response['knot'] = null
    }

    if (allowDebug) {
      response['debug'] = {
        note: 'debug fields are reserved for internal callers',
      }
    }

    return new Response(JSON.stringify(response), {
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

