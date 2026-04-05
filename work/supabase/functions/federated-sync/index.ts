// Federated Sync Edge Function for Phase 11: User-AI Interaction Update
// Section 7: Federated Learning Hooks
// Hybrid federated learning sync:
// - Pattern 1 (offline): AI2AI BLE gossip exchanges deltas directly
// - Pattern 2 (online): devices upload privacy-bounded deltas for cloud aggregation

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight request
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
    const { schema_version, source, deltas, rag_feedback } = body

    if (schema_version !== 1) {
      return new Response(JSON.stringify({ error: 'Unsupported schema_version' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!deltas || !Array.isArray(deltas) || deltas.length === 0) {
      return new Response(
        JSON.stringify({ error: 'deltas array is required and must not be empty' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Optional RAG feedback (device-level aggregates, no PII). Store when present.
    const storeRagFeedback = rag_feedback && typeof rag_feedback === 'object'
      && typeof (rag_feedback.retrieved_group_counts ?? {}) === 'object'
      && typeof (rag_feedback.network_cues_used ?? 0) === 'number'
      && typeof (rag_feedback.search_used ?? 0) === 'number'

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Authenticate caller (required even though we write using service role).
    const { data: userData, error: userErr } = await supabase.auth.getUser(jwt)
    if (userErr || !userData?.user?.id) {
      return new Response(JSON.stringify({ error: 'Invalid auth token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const userId = userData.user.id

    // Validate and clamp input deltas (privacy + abuse resistance).
    const maxPerRequest = 50
    const sanitized = []
    for (const d of deltas.slice(0, maxPerRequest)) {
      if (!d || typeof d !== 'object') continue
      const category = typeof d.category === 'string' && d.category.length > 0 ? d.category : 'general'
      const ts = typeof d.timestamp === 'string' ? d.timestamp : new Date().toISOString()
      const vec = Array.isArray(d.delta) ? d.delta : null
      if (!vec || vec.length === 0 || vec.length > 64) continue
      const clamped = vec.map((x: any) => {
        const n = typeof x === 'number' ? x : 0
        // Match client-side caps; keep it bounded.
        return Math.max(-0.35, Math.min(0.35, n))
      })
      sanitized.push({
        user_id: userId,
        category,
        delta: clamped,
        created_at: ts,
        source: typeof source === 'string' ? source : 'unknown',
        metadata: d.metadata && typeof d.metadata === 'object' ? d.metadata : {},
      })
    }

    if (sanitized.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid deltas provided' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Insert rows.
    const { error: insertErr } = await supabase
      .from('federated_embedding_deltas_v1')
      .insert(sanitized)
    if (insertErr) {
      return new Response(JSON.stringify({ error: 'Insert failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let ragFeedbackStored: boolean | undefined = undefined
    if (storeRagFeedback) {
      try {
        const { error: ragErr } = await supabase
          .from('rag_feedback_aggregates_v1')
          .insert({
            retrieved_group_counts: rag_feedback.retrieved_group_counts ?? {},
            network_cues_used: Math.max(0, Math.min(1e6, Math.floor(rag_feedback.network_cues_used ?? 0))),
            search_used: Math.max(0, Math.min(1e6, Math.floor(rag_feedback.search_used ?? 0))),
            source: typeof source === 'string' ? source : 'federated_sync',
          })
        if (ragErr) {
          console.error('RAG feedback insert failed (non-blocking):', ragErr)
          ragFeedbackStored = false
        } else {
          ragFeedbackStored = true
        }
      } catch (e) {
        console.error('RAG feedback insert error:', e)
        ragFeedbackStored = false
      }
    }

    // Aggregate recent rows for a lightweight "global average" response.
    // This is intentionally simple (v1): it gives clients a network prior without
    // exposing user-level data.
    const windowHours = 24
    const cutoff = new Date(Date.now() - windowHours * 60 * 60 * 1000).toISOString()
    const { data: rows, error: readErr } = await supabase
      .from('federated_embedding_deltas_v1')
      .select('category,delta')
      .gte('created_at', cutoff)
      .limit(1000)

    if (readErr || !rows) {
      return new Response(
        JSON.stringify({
          success: true,
          inserted: sanitized.length,
          window_hours: windowHours,
          global_average_deltas: {},
          sample_counts: {},
          ...(ragFeedbackStored !== undefined && { rag_feedback_stored: ragFeedbackStored }),
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const aggregatedDeltas = aggregateDeltasByCategory(rows as any[])
    const averageDeltas = calculateAverageDeltas(aggregatedDeltas)
    const sampleCounts: Record<string, number> = {}
    for (const [category, ds] of Object.entries(aggregatedDeltas)) {
      sampleCounts[category] = ds.length
    }

    return new Response(
      JSON.stringify({
        success: true,
        inserted: sanitized.length,
        window_hours: windowHours,
        categories: Object.keys(averageDeltas),
        global_average_deltas: averageDeltas,
        sample_counts: sampleCounts,
        ...(ragFeedbackStored !== undefined && { rag_feedback_stored: ragFeedbackStored }),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    console.error('Federated sync error:', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

/// Aggregate deltas by category
function aggregateDeltasByCategory(deltas: any[]) {
  const aggregated: Record<string, any[]> = {}

  for (const delta of deltas) {
    const category = delta.category || 'general'
    if (!aggregated[category]) {
      aggregated[category] = []
    }
    aggregated[category].push(delta)
  }

  return aggregated
}

/// Calculate average deltas per category
function calculateAverageDeltas(aggregatedDeltas: Record<string, any[]>) {
  const averages: Record<string, number[]> = {}

  for (const [category, deltas] of Object.entries(aggregatedDeltas)) {
    if (deltas.length === 0) continue

    // Find maximum delta length
    let maxLength = 0
    for (const delta of deltas) {
      if (delta.delta && delta.delta.length > maxLength) {
        maxLength = delta.delta.length
      }
    }

    // Calculate average for each dimension
    const avgDelta = new Array(maxLength).fill(0)
    for (const delta of deltas) {
      if (delta.delta) {
        for (let i = 0; i < delta.delta.length && i < maxLength; i++) {
          avgDelta[i] += delta.delta[i]
        }
      }
    }

    // Divide by count to get average
    for (let i = 0; i < avgDelta.length; i++) {
      avgDelta[i] /= deltas.length
    }

    averages[category] = avgDelta
  }

  return averages
}
