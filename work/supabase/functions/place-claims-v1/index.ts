import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type PlaceClaimsAction =
  | 'claim'
  | 'unclaim'
  | 'list_claimed_places'
  | 'get_claim_by_place_id'
  | 'get_claiming_business'
  | 'update_attraction_override'

type PlaceClaimsBody = {
  action?: PlaceClaimsAction
  sessionId?: string
  requestedBusinessId?: string
  googlePlaceId?: string
  verificationMethod?: string | null
  attractionOverride?: Record<string, unknown> | null
}

type BusinessSessionRow = {
  id: string
  business_id: string
  expires_at: string
}

class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message)
    this.name = 'HttpError'
  }
}

function adminClient() {
  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!url || !serviceKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  }
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
    db: { schema: 'public' },
  })
}

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function requireTrimmedString(value: unknown, fieldName: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${fieldName} is required`)
  }
  return value.trim()
}

function normalizeVerificationMethod(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null
  }
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

function normalizeAttractionOverride(
  value: unknown,
): Record<string, number> | null {
  if (value === null || value === undefined) {
    return null
  }
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'attractionOverride must be an object or null')
  }

  const normalized: Record<string, number> = {}
  for (const [key, raw] of Object.entries(value)) {
    if (typeof raw !== 'number' || !Number.isFinite(raw)) {
      throw new HttpError(
        400,
        `attractionOverride.${key} must be a finite number`,
      )
    }
    normalized[key] = raw
  }
  return normalized
}

async function validateBusinessSession(
  admin: ReturnType<typeof adminClient>,
  body: PlaceClaimsBody,
): Promise<BusinessSessionRow> {
  const sessionId = requireTrimmedString(body.sessionId, 'sessionId')
  const requestedBusinessId =
    typeof body.requestedBusinessId === 'string'
      ? body.requestedBusinessId.trim()
      : ''

  const { data, error } = await admin
    .from('business_sessions')
    .select('id, business_id, expires_at')
    .eq('id', sessionId)
    .maybeSingle()

  if (error || !data) {
    throw new HttpError(401, 'Business session not found')
  }

  const session = data as BusinessSessionRow

  if (new Date(session.expires_at).getTime() <= Date.now()) {
    throw new HttpError(401, 'Business session expired')
  }

  if (requestedBusinessId && session.business_id !== requestedBusinessId) {
    throw new HttpError(
      403,
      'Business session does not match requested business',
    )
  }

  return session
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json(405, { ok: false, error: 'Method not allowed' })
  }

  try {
    const body = (await req.json()) as PlaceClaimsBody
    const action = body.action

    if (!action) {
      return json(400, { ok: false, error: 'action is required' })
    }

    const admin = adminClient()
    const session = await validateBusinessSession(admin, body)

    switch (action) {
      case 'claim': {
        const googlePlaceId = requireTrimmedString(
          body.googlePlaceId,
          'googlePlaceId',
        )
        const verificationMethod = normalizeVerificationMethod(
          body.verificationMethod,
        )

        const { data, error } = await admin
          .from('claimed_places')
          .insert({
            business_id: session.business_id,
            google_place_id: googlePlaceId,
            verification_method: verificationMethod,
          })
          .select()
          .single()

        if (error) {
          if (error.code === '23505') {
            return json(409, {
              ok: false,
              error: 'Place is already claimed',
            })
          }
          return json(400, {
            ok: false,
            error: `Claim failed: ${error.message}`,
          })
        }

        return json(200, { ok: true, claim: data })
      }

      case 'unclaim': {
        const googlePlaceId = requireTrimmedString(
          body.googlePlaceId,
          'googlePlaceId',
        )

        const { data, error } = await admin
          .from('claimed_places')
          .delete()
          .eq('business_id', session.business_id)
          .eq('google_place_id', googlePlaceId)
          .select('id')

        if (error) {
          return json(400, {
            ok: false,
            error: `Unclaim failed: ${error.message}`,
          })
        }

        return json(200, {
          ok: true,
          deleted: Array.isArray(data) && data.length > 0,
        })
      }

      case 'list_claimed_places': {
        const { data, error } = await admin
          .from('claimed_places')
          .select()
          .eq('business_id', session.business_id)
          .order('claimed_at', { ascending: false })

        if (error) {
          return json(400, {
            ok: false,
            error: `List failed: ${error.message}`,
          })
        }

        return json(200, { ok: true, claims: data ?? [] })
      }

      case 'get_claim_by_place_id': {
        const googlePlaceId = requireTrimmedString(
          body.googlePlaceId,
          'googlePlaceId',
        )

        const { data, error } = await admin
          .from('claimed_places')
          .select()
          .eq('google_place_id', googlePlaceId)
          .maybeSingle()

        if (error) {
          return json(400, {
            ok: false,
            error: `Lookup failed: ${error.message}`,
          })
        }

        return json(200, { ok: true, claim: data })
      }

      case 'get_claiming_business': {
        const googlePlaceId = requireTrimmedString(
          body.googlePlaceId,
          'googlePlaceId',
        )

        const { data, error } = await admin
          .from('claimed_places')
          .select('business_id')
          .eq('google_place_id', googlePlaceId)
          .maybeSingle()

        if (error) {
          return json(400, {
            ok: false,
            error: `Lookup failed: ${error.message}`,
          })
        }

        return json(200, {
          ok: true,
          businessId: data?.business_id ?? null,
        })
      }

      case 'update_attraction_override': {
        const googlePlaceId = requireTrimmedString(
          body.googlePlaceId,
          'googlePlaceId',
        )
        const attractionOverride = normalizeAttractionOverride(
          body.attractionOverride,
        )

        const { data, error } = await admin
          .from('claimed_places')
          .update({
            attraction_override: attractionOverride,
          })
          .eq('business_id', session.business_id)
          .eq('google_place_id', googlePlaceId)
          .select()
          .maybeSingle()

        if (error) {
          return json(400, {
            ok: false,
            error: `Update failed: ${error.message}`,
          })
        }

        if (!data) {
          return json(404, {
            ok: false,
            error: 'Claim not found',
          })
        }

        return json(200, { ok: true, claim: data })
      }
    }
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500
    return json(status, {
      ok: false,
      error: e instanceof Error ? e.message : String(e),
    })
  }
})
