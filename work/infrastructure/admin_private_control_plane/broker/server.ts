import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type JsonMap = Record<string, unknown>

const port = Number(Deno.env.get('RESEARCH_EGRESS_BROKER_PORT') ?? '8091')
const sharedKey = Deno.env.get('RESEARCH_EGRESS_BROKER_SHARED_KEY') ?? ''
const maxBytes = Number(Deno.env.get('RESEARCH_EGRESS_BROKER_MAX_RESPONSE_BYTES') ?? '5242880')
const timeoutMs = Number(Deno.env.get('RESEARCH_EGRESS_BROKER_TIMEOUT_MS') ?? '12000')
const quarantineTtlHours = Number(Deno.env.get('RESEARCH_EGRESS_BROKER_QUARANTINE_TTL_HOURS') ?? '4')
const allowedHosts = new Set(
  (Deno.env.get('RESEARCH_EGRESS_BROKER_ALLOWED_HOSTS') ?? '')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
)
const allowedContentTypes = new Set(
  (Deno.env.get('RESEARCH_EGRESS_BROKER_ALLOWED_CONTENT_TYPES') ?? 'text/plain,text/html,application/json,application/pdf')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
)

const sb = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  {
    auth: { persistSession: false },
    db: { schema: 'public' },
  },
)

function json(status: number, body: JsonMap): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  })
}

async function sha256Bytes(value: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', value)
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

function randomId(prefix: string): string {
  return `${prefix}_${crypto.randomUUID().replaceAll('-', '')}`
}

function normalizeBody(body: unknown): JsonMap {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return {}
  }
  return body as JsonMap
}

serve(async (req) => {
  if (req.method === 'GET' && new URL(req.url).pathname === '/health') {
    return json(200, {
      status: 'ok',
      service: 'research-egress-broker',
      allowedHosts: Array.from(allowedHosts),
      allowedContentTypes: Array.from(allowedContentTypes),
    })
  }
  if (req.method !== 'POST' || new URL(req.url).pathname !== '/fetch') {
    return json(404, { error: 'Not found' })
  }
  if (!sharedKey || req.headers.get('x-broker-shared-key') !== sharedKey) {
    return json(403, { error: 'Broker shared key mismatch.' })
  }

  const body = normalizeBody(await req.json().catch(() => ({})))
  const sourceUri = String(body.sourceUri ?? '')
  if (!sourceUri) {
    return json(400, { error: 'sourceUri is required.' })
  }

  let target: URL
  try {
    target = new URL(sourceUri)
  } catch {
    return json(400, { error: 'sourceUri must be a valid URL.' })
  }

  if (!['http:', 'https:'].includes(target.protocol)) {
    return json(400, { error: 'Only outbound HTTP(S) fetches are allowed.' })
  }
  if (!allowedHosts.has(target.hostname.toLowerCase())) {
    return json(403, { error: 'Target host is not allowlisted for brokered research fetches.' })
  }

  try {
    const response = await fetch(target, {
      method: 'GET',
      redirect: 'follow',
      signal: AbortSignal.timeout(timeoutMs),
      headers: {
        'user-agent': 'AVRAI-Research-Egress-Broker/1.0',
        'accept': 'text/plain,text/html,application/json,application/pdf,text/markdown',
      },
    })
    if (!response.ok) {
      return json(502, { error: `Broker fetch failed: ${response.status}` })
    }

    const contentType = (response.headers.get('content-type') ?? '').split(';')[0].trim().toLowerCase()
    if (!allowedContentTypes.has(contentType)) {
      return json(415, { error: `Content type not allowed: ${contentType || 'unknown'}` })
    }

    const bytes = new Uint8Array(await response.arrayBuffer())
    if (bytes.byteLength > maxBytes) {
      return json(413, { error: 'Response exceeded broker size cap.' })
    }

    const checksum = await sha256Bytes(bytes)
    const sourceHash = await sha256Bytes(new TextEncoder().encode(sourceUri))
    const quarantineId = randomId('quarantine')
    const storageKey = `broker://quarantine/${String(body.runId ?? 'unknown')}/${quarantineId}`
    const preview = new TextDecoder().decode(bytes.slice(0, Math.min(bytes.byteLength, 512)))
    const expiresAt = new Date(Date.now() + quarantineTtlHours * 60 * 60 * 1000).toISOString()

    const { error } = await sb.from('admin_research_quarantined_payloads').insert({
      id: quarantineId,
      run_id: String(body.runId ?? ''),
      artifact_id: null,
      source_uri_hash: sourceHash,
      source_host: target.hostname.toLowerCase(),
      content_type: contentType,
      payload_sha256: checksum,
      size_bytes: bytes.byteLength,
      scan_status: 'static_policy_clean',
      normalized_summary: {
        preview: preview.replaceAll(/\s+/g, ' ').trim(),
        contentType,
        host: target.hostname.toLowerCase(),
      },
      storage_key: storageKey,
      expires_at: expiresAt,
      created_at: new Date().toISOString(),
    })
    if (error) {
      return json(500, { error: error.message })
    }

    return json(200, {
      quarantineId,
      storageKey,
      summary: 'Brokered outbound fetch completed and payload quarantined.',
      checksum,
      contentType,
      sizeBytes: bytes.byteLength,
      expiresAt,
    })
  } catch (error) {
    return json(502, { error: `Broker fetch error: ${error}` })
  }
}, { port })
