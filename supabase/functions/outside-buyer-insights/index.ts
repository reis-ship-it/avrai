// Supabase Edge Function: Outside Buyer Insights (v1)
// Phase: Track F (Balanced MVP DoD) - Outside data-buyer insights (safe-to-sell monetization)
// Contract: docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md
//
// Guarantees:
// - Outside buyers receive aggregate-only, delayed, coarse, DP-noised metrics
// - No stable user identifiers returned
// - Enforced: k-min + dominance + privacy budget accounting (DB function)

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

async function hashAPIKey(apiKey: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(apiKey)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

async function sha256Hex(input: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(input)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

async function checkRateLimit(
  supabase: any,
  apiKeyId: string,
  limitPerMinute: number,
  limitPerDay: number,
): Promise<{ allowed: boolean; message?: string }> {
  const now = new Date()
  const oneMinuteAgo = new Date(now.getTime() - 60 * 1000)
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

  const { count: minuteCount } = await supabase
    .from('api_request_logs')
    .select('*', { count: 'exact', head: true })
    .eq('api_key_id', apiKeyId)
    .gte('created_at', oneMinuteAgo.toISOString())

  if ((minuteCount ?? 0) >= limitPerMinute) {
    return { allowed: false, message: `Rate limit exceeded: ${limitPerMinute} requests per minute` }
  }

  const { count: dayCount } = await supabase
    .from('api_request_logs')
    .select('*', { count: 'exact', head: true })
    .eq('api_key_id', apiKeyId)
    .gte('created_at', oneDayAgo.toISOString())

  if ((dayCount ?? 0) >= limitPerDay) {
    return { allowed: false, message: `Rate limit exceeded: ${limitPerDay} requests per day` }
  }

  return { allowed: true }
}

async function logRequest(
  supabase: any,
  apiKeyId: string,
  endpoint: string,
  method: string,
  status: number,
  processingTimeMs: number,
  requestBody?: any,
  errorCode?: string,
): Promise<void> {
  await supabase.from('api_request_logs').insert({
    api_key_id: apiKeyId,
    endpoint,
    method,
    request_body: requestBody ?? null,
    response_status: status,
    processing_time_ms: processingTimeMs,
    error_code: errorCode ?? null,
  })
}

type TimeGranularity = 'day' | 'hour' | 'week'
type DoorType = 'spot' | 'event' | 'community'
type ContextBucket = 'morning' | 'midday' | 'evening' | 'weekend' | 'unknown'

interface InsightsRequest {
  time_bucket_start_utc: string
  time_bucket_end_utc: string
  time_granularity?: TimeGranularity
  reporting_delay_hours?: number
  geo_bucket_type?: string
  geo_bucket_ids?: string[]
  door_types?: DoorType[]
  categories?: string[]
  contexts?: ContextBucket[]
  k_min?: number
  dominance_max_fraction?: number
  dp_epsilon?: number
  dp_delta?: number
  budget_window_days?: number
  privacy_budget_total_epsilon?: number
  budget_cost_epsilon?: number
}

function normalizeList(values?: string[]): string[] | null {
  if (!values || values.length === 0) return null
  const out = Array.from(new Set(values.map(v => String(v).trim()).filter(Boolean)))
  out.sort()
  return out.length > 0 ? out : null
}

async function buildQueryFingerprint(
  apiKeyId: string,
  parsed: InsightsRequest,
  timeGranularity: TimeGranularity,
  geoBucketType: 'city_code' | 'geohash3' | 'locality_code',
  profile: {
    expectedDelay: number
    expectedKMin: number
    expectedDominance: number
    expectedEpsilon: number
    expectedBudgetWindowDays: number
    expectedBudgetCostEpsilon: number
  },
): Promise<string> {
  // Fingerprint uses the *effective enforced* parameters (after applying safety profile defaults),
  // so clients can't “burn” fingerprint budget via cosmetic parameter changes.
  const canonical = {
    time_granularity: timeGranularity,
    time_bucket_start_utc: parsed.time_bucket_start_utc,
    time_bucket_end_utc: parsed.time_bucket_end_utc,
    reporting_delay_hours: parsed.reporting_delay_hours ?? profile.expectedDelay,
    geo_bucket_type: geoBucketType,
    geo_bucket_ids: normalizeList(parsed.geo_bucket_ids),
    door_types: normalizeList(parsed.door_types),
    categories: normalizeList(parsed.categories),
    contexts: normalizeList(parsed.contexts),
    k_min: profile.expectedKMin,
    dominance_max_fraction: profile.expectedDominance,
    dp_epsilon: profile.expectedEpsilon,
    dp_delta: parsed.dp_delta ?? 1e-6,
    budget_window_days: profile.expectedBudgetWindowDays,
    budget_cost_epsilon: profile.expectedBudgetCostEpsilon,
  }

  return await sha256Hex(`${apiKeyId}:${JSON.stringify(canonical)}`)
}

function parseInsightsRequest(req: Request): Promise<InsightsRequest> | InsightsRequest {
  const url = new URL(req.url)
  if (req.method === 'GET') {
    const getList = (k: string): string[] | undefined => {
      const raw = url.searchParams.getAll(k)
      if (!raw || raw.length === 0) return undefined
      // Allow comma-separated in addition to repeated params
      const flattened = raw.flatMap((v) => v.split(',').map((s) => s.trim()).filter(Boolean))
      return flattened.length > 0 ? flattened : undefined
    }

    const start = url.searchParams.get('start') ?? url.searchParams.get('time_bucket_start_utc')
    const end = url.searchParams.get('end') ?? url.searchParams.get('time_bucket_end_utc')
    if (!start || !end) {
      throw new Error('time_bucket_start_utc and time_bucket_end_utc are required (or start/end)')
    }

    return {
      time_bucket_start_utc: start,
      time_bucket_end_utc: end,
      time_granularity: (url.searchParams.get('time_granularity') as TimeGranularity) ?? undefined,
      reporting_delay_hours: url.searchParams.get('reporting_delay_hours')
        ? Number(url.searchParams.get('reporting_delay_hours'))
        : undefined,
      geo_bucket_type: url.searchParams.get('geo_bucket_type') ?? undefined,
      geo_bucket_ids: getList('geo_bucket_ids'),
      door_types: getList('door_types') as DoorType[] | undefined,
      categories: getList('categories'),
      contexts: getList('contexts') as ContextBucket[] | undefined,
      k_min: url.searchParams.get('k_min') ? Number(url.searchParams.get('k_min')) : undefined,
      dominance_max_fraction: url.searchParams.get('dominance_max_fraction')
        ? Number(url.searchParams.get('dominance_max_fraction'))
        : undefined,
      dp_epsilon: url.searchParams.get('dp_epsilon') ? Number(url.searchParams.get('dp_epsilon')) : undefined,
      dp_delta: url.searchParams.get('dp_delta') ? Number(url.searchParams.get('dp_delta')) : undefined,
      budget_window_days: url.searchParams.get('budget_window_days')
        ? Number(url.searchParams.get('budget_window_days'))
        : undefined,
      privacy_budget_total_epsilon: url.searchParams.get('privacy_budget_total_epsilon')
        ? Number(url.searchParams.get('privacy_budget_total_epsilon'))
        : undefined,
      budget_cost_epsilon: url.searchParams.get('budget_cost_epsilon')
        ? Number(url.searchParams.get('budget_cost_epsilon'))
        : undefined,
    }
  }

  // POST
  return req.json()
}

serve(async (req) => {
  const startTime = Date.now()
  const endpoint = 'outside-buyer-insights'
  const supabase = supabaseAdmin()

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  let apiKeyIdForLogging: string | null = null
  let requestBodyForLogging: any = null

  try {
    // Extract API key from Authorization header
    const authHeader = req.headers.get('Authorization')
    const apiKey =
      authHeader?.replace('Bearer ', '') || authHeader?.replace('ApiKey ', '') || null

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'AUTHENTICATION_FAILED',
            message: 'API key required. Provide API key in Authorization header as "Bearer {api_key}" or "ApiKey {api_key}"',
          },
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Authenticate API key
    const { data: keyData, error: keyError } = await supabase
      .from('api_keys')
      .select('id, partner_id, rate_limit_per_minute, rate_limit_per_day, is_active, expires_at')
      .eq('api_key_hash', await hashAPIKey(apiKey))
      .eq('is_active', true)
      .single()

    if (keyError || !keyData) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'AUTHENTICATION_FAILED', message: 'Invalid API key' },
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    apiKeyIdForLogging = keyData.id

    // Enforce partner namespace (reduce blast radius if keys are reused)
    if (!String(keyData.partner_id || '').startsWith('outside_buyer_')) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'UNAUTHORIZED_KEY_SCOPE',
            message: 'API key is not authorized for outside buyer insights',
          },
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Check expiry
    if (keyData.expires_at && new Date(keyData.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'API_KEY_EXPIRED', message: 'API key has expired' },
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Rate limiting
    const rateLimit = await checkRateLimit(
      supabase,
      keyData.id,
      keyData.rate_limit_per_minute ?? 60,
      keyData.rate_limit_per_day ?? 5000,
    )
    if (!rateLimit.allowed) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'RATE_LIMIT_EXCEEDED', message: rateLimit.message || 'Rate limit exceeded' },
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Parse request
    const parsed = await parseInsightsRequest(req)
    requestBodyForLogging = parsed

    // Basic hardening: prevent huge selectors
    if (parsed.geo_bucket_ids && parsed.geo_bucket_ids.length > 50) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: 'geo_bucket_ids too large (max 50)',
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Intersection attack hardening: bound query complexity + enforce stable cache parameters.
    const filterDims = [
      parsed.geo_bucket_ids?.length ? 1 : 0,
      parsed.door_types?.length ? 1 : 0,
      parsed.categories?.length ? 1 : 0,
      parsed.contexts?.length ? 1 : 0,
    ].reduce((a, b) => a + b, 0)

    const timeGranularity: TimeGranularity = parsed.time_granularity ?? 'day'

    // Granularity-aware safety profile (keeps releases stable and reduces intersection surface).
    const profile =
      timeGranularity === 'hour'
        ? {
            expectedDelay: 168,
            expectedKMin: 300,
            expectedDominance: 0.05,
            expectedEpsilon: 0.25,
            expectedBudgetWindowDays: 30,
            expectedBudgetCostEpsilon: 0.25,
            maxRangeDays: 7,
            maxFilterDims: 2,
          }
        : timeGranularity === 'week'
          ? {
              expectedDelay: 72,
              expectedKMin: 100,
              expectedDominance: 0.05,
              expectedEpsilon: 0.5,
              expectedBudgetWindowDays: 30,
              expectedBudgetCostEpsilon: 0.5,
              maxRangeDays: 365,
              maxFilterDims: 3,
            }
          : {
              expectedDelay: 72,
              expectedKMin: 100,
              expectedDominance: 0.05,
              expectedEpsilon: 0.5,
              expectedBudgetWindowDays: 30,
              expectedBudgetCostEpsilon: 0.5,
              maxRangeDays: 90,
              maxFilterDims: 3,
            }

    if (filterDims > profile.maxFilterDims) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `Too many filter dimensions for ${timeGranularity} (max ${profile.maxFilterDims})`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Time window size hardening (also enforced in SQL; this is earlier/cheaper).
    const startMs = Date.parse(parsed.time_bucket_start_utc)
    const endMs = Date.parse(parsed.time_bucket_end_utc)
    if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'INVALID_REQUEST', message: 'Invalid ISO timestamps for time_bucket_start_utc/time_bucket_end_utc' },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if (endMs <= startMs) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'INVALID_REQUEST', message: 'time_bucket_end_utc must be greater than time_bucket_start_utc' },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    const rangeDays = (endMs - startMs) / (1000 * 60 * 60 * 24)
    if (rangeDays > profile.maxRangeDays) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `Requested range too large for ${timeGranularity} (max ${profile.maxRangeDays} days)`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Bucket alignment hardening (reduces slice drift and fingerprint churn).
    const hourMs = 1000 * 60 * 60
    const dayMs = 1000 * 60 * 60 * 24
    if (timeGranularity === 'hour') {
      if (startMs % hourMs !== 0 || endMs % hourMs !== 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For hour granularity, start/end must be aligned to UTC hour boundaries' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      const rangeHours = (endMs - startMs) / hourMs
      if (!Number.isInteger(rangeHours)) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For hour granularity, range must be a whole number of hours' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    } else if (timeGranularity === 'day') {
      if (startMs % dayMs !== 0 || endMs % dayMs !== 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For day granularity, start/end must be aligned to UTC day boundaries' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      const rangeWholeDays = (endMs - startMs) / dayMs
      if (!Number.isInteger(rangeWholeDays)) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For day granularity, range must be a whole number of days' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    } else if (timeGranularity === 'week') {
      // Weak alignment check: require day boundaries and week multiples (UTC)
      if (startMs % dayMs !== 0 || endMs % dayMs !== 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For week granularity, start/end must be aligned to UTC day boundaries' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      const rangeWholeDays = (endMs - startMs) / dayMs
      if (!Number.isInteger(rangeWholeDays) || rangeWholeDays % 7 !== 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For week granularity, range must be a whole number of weeks' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // Geo bucket: allow geohash3, city_code, or locality_code (default city_code).
    // locality_code = neighborhood/borough; requires k_min >= 200 per contract.
    const geoBucketType = (parsed.geo_bucket_type ?? 'city_code') as 'city_code' | 'geohash3' | 'locality_code'
    if (geoBucketType !== 'geohash3' && geoBucketType !== 'city_code' && geoBucketType !== 'locality_code') {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'INVALID_REQUEST', message: 'geo_bucket_type must be "city_code", "geohash3", or "locality_code"' },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if (geoBucketType === 'locality_code') {
      const kMin = parsed.k_min ?? 200
      if (kMin < 200) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For locality_code, k_min must be >= 200' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // Hour path is intentionally narrower: require city_code scoping.
    if (timeGranularity === 'hour') {
      if (geoBucketType !== 'city_code') {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For hour granularity, geo_bucket_type must be "city_code"' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }

      const normalizedGeoIds = normalizeList(parsed.geo_bucket_ids)
      if (!normalizedGeoIds) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For hour granularity, geo_bucket_ids is required (scope to city_code buckets)' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      if (normalizedGeoIds.length > 10) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'INVALID_REQUEST', message: 'For hour granularity, geo_bucket_ids too large (max 10)' },
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // Lock to contract/default parameters (per granularity).
    if ((parsed.reporting_delay_hours ?? profile.expectedDelay) < profile.expectedDelay) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `reporting_delay_hours must be >= ${profile.expectedDelay} for ${timeGranularity}`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if ((parsed.k_min ?? profile.expectedKMin) !== profile.expectedKMin) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'INVALID_REQUEST', message: `k_min must be ${profile.expectedKMin} for ${timeGranularity}` },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if ((parsed.dominance_max_fraction ?? profile.expectedDominance) !== profile.expectedDominance) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `dominance_max_fraction must be ${profile.expectedDominance} for ${timeGranularity}`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if ((parsed.dp_epsilon ?? profile.expectedEpsilon) !== profile.expectedEpsilon) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'INVALID_REQUEST', message: `dp_epsilon must be ${profile.expectedEpsilon} for ${timeGranularity}` },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if ((parsed.budget_window_days ?? profile.expectedBudgetWindowDays) !== profile.expectedBudgetWindowDays) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `budget_window_days must be ${profile.expectedBudgetWindowDays} for ${timeGranularity}`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if ((parsed.budget_cost_epsilon ?? profile.expectedBudgetCostEpsilon) !== profile.expectedBudgetCostEpsilon) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: `budget_cost_epsilon must be ${profile.expectedBudgetCostEpsilon} for ${timeGranularity}`,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Record query fingerprint and deny if too many distinct requests (intersection defense).
    const fingerprint = await buildQueryFingerprint(keyData.id, parsed, timeGranularity, geoBucketType, profile)
    const { data: fpAllowed, error: fpError } = await supabase.rpc('outside_buyer_record_query_fingerprint', {
      p_api_key_id: keyData.id,
      p_fingerprint: fingerprint,
      p_max_distinct_per_day: 200,
    })
    if (fpError || fpAllowed === false) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'QUERY_BUDGET_EXCEEDED',
            message: 'Query shape budget exceeded (too many distinct slices). Try broader aggregates.',
          },
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Call DB export function (enforces delay + DP + k-min + dominance + budget)
    const { data, error } = await supabase.rpc('outside_buyer_get_spots_insights_v1_cached', {
      p_api_key_id: keyData.id,
      p_time_bucket_start_utc: parsed.time_bucket_start_utc,
      p_time_bucket_end_utc: parsed.time_bucket_end_utc,
      p_time_granularity: timeGranularity,
      p_reporting_delay_hours: parsed.reporting_delay_hours ?? profile.expectedDelay,
      p_geo_bucket_type: geoBucketType,
      p_geo_bucket_ids: parsed.geo_bucket_ids ?? null,
      p_door_types: parsed.door_types ?? null,
      p_categories: parsed.categories ?? null,
      p_contexts: parsed.contexts ?? null,
      p_k_min: parsed.k_min ?? profile.expectedKMin,
      p_dominance_max_fraction: parsed.dominance_max_fraction ?? profile.expectedDominance,
      p_dp_epsilon: parsed.dp_epsilon ?? profile.expectedEpsilon,
      p_dp_delta: parsed.dp_delta ?? 1e-6,
      p_budget_window_days: parsed.budget_window_days ?? profile.expectedBudgetWindowDays,
      p_privacy_budget_total_epsilon: parsed.privacy_budget_total_epsilon ?? 10.0,
      p_budget_cost_epsilon: parsed.budget_cost_epsilon ?? profile.expectedBudgetCostEpsilon,
    })

    if (error) {
      // Audit log (best-effort)
      await supabase.from('audit_logs').insert({
        type: 'outside_buyer_export',
        action: 'read',
        status: 'blocked',
        metadata: {
          api_key_id: keyData.id,
          partner_id: keyData.partner_id,
          endpoint,
          reason: error.message,
          request: parsed,
        },
      })

      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'EXPORT_DENIED',
            message: error.message,
          },
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const rows = data ?? []

    // Budget alerting (best-effort; non-blocking)
    try {
      await supabase.rpc('outside_buyer_maybe_alert_budget', {
        p_api_key_id: keyData.id,
        p_threshold_fraction: 0.8,
      })
    } catch (_) {
      // ignore
    }

    // Audit log (best-effort)
    await supabase.from('audit_logs').insert({
      type: 'outside_buyer_export',
      action: 'read',
      status: 'success',
      metadata: {
        api_key_id: keyData.id,
        partner_id: keyData.partner_id,
        endpoint,
        row_count: rows.length,
        request: parsed,
      },
    })

    const processingTimeMs = Date.now() - startTime
    await logRequest(supabase, keyData.id, endpoint, req.method, 200, processingTimeMs, requestBodyForLogging)

    return new Response(
      JSON.stringify({
        success: true,
        dataset: 'spots_insights_v1',
        rows,
        metadata: {
          request_id: crypto.randomUUID(),
          processing_time_ms: processingTimeMs,
          api_version: '1.0.0',
          timestamp: new Date().toISOString(),
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e) {
    const processingTimeMs = Date.now() - startTime
    if (apiKeyIdForLogging) {
      await logRequest(
        supabase,
        apiKeyIdForLogging,
        endpoint,
        req.method,
        500,
        processingTimeMs,
        requestBodyForLogging,
        'INTERNAL_ERROR',
      )
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: { code: 'INTERNAL_ERROR', message: String(e?.message ?? e) },
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})

