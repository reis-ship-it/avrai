// Supabase Edge Function: Ledger Receipts (v0)
//
// Purpose:
// - Provide tamper-evident "receipts you can show" for v0 ledgers.
// - Mint server-held signatures over canonical ledger rows.
//
// Endpoints (single function with action router):
// - POST { action: "append_signed", insert: <ledger insert map> }
// - POST { action: "sign_existing", ledger_row_id: "<uuid>" }
//
// Security:
// - verify_jwt: enabled (default). Client must send Authorization Bearer <JWT>.
// - Ledger inserts are performed as the authenticated user (RLS enforced).
// - Signature inserts are performed as service role (server-side only).
//
// Secrets required:
// - SUPABASE_URL
// - SUPABASE_ANON_KEY
// - SUPABASE_SERVICE_ROLE_KEY
// - LEDGER_RECEIPTS_V0_KEY_ID
// - LEDGER_RECEIPTS_V0_SIGNING_KEY_B64   (base64 32-byte Ed25519 seed)

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { decodeBase64, encodeBase64 } from 'https://deno.land/std@0.224.0/encoding/base64.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as ed25519 from 'npm:@noble/ed25519@2.1.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function requireEnv(key: string): string {
  const v = Deno.env.get(key) ?? ''
  if (!v) throw new Error(`Missing env: ${key}`)
  return v
}

function supabaseAdmin() {
  const url = requireEnv('SUPABASE_URL')
  const serviceKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY')
  return createClient(url, serviceKey, { auth: { persistSession: false } })
}

function supabaseUser(authHeader: string) {
  const url = requireEnv('SUPABASE_URL')
  const anonKey = requireEnv('SUPABASE_ANON_KEY')
  return createClient(url, anonKey, {
    auth: { persistSession: false },
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  })
}

async function sha256Hex(input: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(input)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

function canonicalize(value: unknown): unknown {
  if (value === null) return null
  if (Array.isArray(value)) return value.map(canonicalize)
  if (typeof value === 'object') {
    const obj = value as Record<string, unknown>
    const keys = Object.keys(obj).sort()
    const out: Record<string, unknown> = {}
    for (const k of keys) {
      const v = obj[k]
      if (v === undefined) continue
      out[k] = canonicalize(v)
    }
    return out
  }
  return value
}

type LedgerRow = Record<string, unknown>

function isoMillisUtc(value: unknown): string {
  // Normalize timestamps to the exact format emitted by JS Date#toISOString:
  // YYYY-MM-DDTHH:mm:ss.SSSZ
  const d = new Date(String(value ?? ''))
  if (Number.isNaN(d.getTime())) return String(value ?? '')
  return d.toISOString()
}

function buildCanonicalLedgerReceiptV0(row: LedgerRow): Record<string, unknown> {
  // Canonical payload is the *current* state of the ledger row plus its id.
  // Any post-hoc mutation of the row breaks sha/signature verification.
  return {
    receipt_schema_version: 0,
    ledger_row_id: row['id'],
    domain: row['domain'],
    owner_user_id: row['owner_user_id'],
    owner_agent_id: row['owner_agent_id'],
    logical_id: row['logical_id'],
    revision: row['revision'],
    supersedes_id: row['supersedes_id'] ?? null,
    op: row['op'],
    event_type: row['event_type'],
    entity_type: row['entity_type'] ?? null,
    entity_id: row['entity_id'] ?? null,
    category: row['category'] ?? null,
    city_code: row['city_code'] ?? null,
    locality_code: row['locality_code'] ?? null,
    occurred_at: isoMillisUtc(row['occurred_at']),
    atomic_timestamp_id: row['atomic_timestamp_id'] ?? null,
    payload: row['payload'] ?? {},
    created_at: isoMillisUtc(row['created_at']),
  }
}

async function signCanonicalJson(canonicalJson: string): Promise<{
  sha256: string
  signature_b64: string
  key_id: string
  canon_algo: string
}> {
  const keyId = Deno.env.get('LEDGER_RECEIPTS_V0_KEY_ID') ?? 'v1'
  const signingKeyB64 = requireEnv('LEDGER_RECEIPTS_V0_SIGNING_KEY_B64')
  const signingKey = decodeBase64(signingKeyB64)
  if (signingKey.length !== 32) {
    throw new Error('LEDGER_RECEIPTS_V0_SIGNING_KEY_B64 must be a 32-byte Ed25519 seed')
  }

  const sha = await sha256Hex(canonicalJson)
  const payloadBytes = new TextEncoder().encode(canonicalJson)
  const sigBytes = await ed25519.sign(payloadBytes, signingKey)

  return {
    sha256: sha,
    signature_b64: encodeBase64(sigBytes),
    key_id: keyId,
    canon_algo: 'v0_sorted_keys_json',
  }
}

async function upsertSignatureRow(args: {
  ledger_row_id: string
  canonical_json: string
  sha256: string
  signature_b64: string
  key_id: string
  canon_algo: string
  schema_version: number
}): Promise<Record<string, unknown>> {
  const admin = supabaseAdmin()

  // Try insert first to preserve immutability (no updates).
  const insertAttempt = await admin.from('ledger_receipt_signatures_v0').insert({
    ledger_row_id: args.ledger_row_id,
    schema_version: args.schema_version,
    canon_algo: args.canon_algo,
    canonical_json: args.canonical_json,
    sha256: args.sha256,
    signature_b64: args.signature_b64,
    key_id: args.key_id,
    signed_at: new Date().toISOString(),
  })

  if (!insertAttempt.error) {
    const { data, error } = await admin
      .from('ledger_receipt_signatures_v0')
      .select('*')
      .eq('ledger_row_id', args.ledger_row_id)
      .maybeSingle()
    if (error) throw new Error(`Signature read-after-write failed: ${error.message}`)
    if (!data) throw new Error('Signature read-after-write returned null')
    return data as Record<string, unknown>
  }

  // Conflict: return existing row.
  if (insertAttempt.error.code === '23505') {
    const { data, error } = await admin
      .from('ledger_receipt_signatures_v0')
      .select('*')
      .eq('ledger_row_id', args.ledger_row_id)
      .maybeSingle()
    if (error) throw new Error(`Signature fetch failed: ${error.message}`)
    if (!data) throw new Error('Signature missing after conflict')
    return data as Record<string, unknown>
  }

  throw new Error(`Signature insert failed: ${insertAttempt.error.message}`)
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return json(401, { ok: false, error: 'MISSING_AUTH' })
    }

    const body = await req.json().catch(() => ({}))
    const action = String((body as any)?.action ?? '')
    if (!action) {
      return json(400, { ok: false, error: 'MISSING_ACTION' })
    }

    const userClient = supabaseUser(authHeader)
    const { data: userData, error: userErr } = await userClient.auth.getUser()
    if (userErr || !userData?.user?.id) {
      return json(401, { ok: false, error: 'INVALID_AUTH' })
    }
    const userId = userData.user.id

    if (action === 'append_signed') {
      const insert = (body as any)?.insert as Record<string, unknown> | undefined
      if (!insert || typeof insert !== 'object') {
        return json(400, { ok: false, error: 'MISSING_INSERT' })
      }

      const ownerUserId = String((insert as any).owner_user_id ?? '')
      if (!ownerUserId || ownerUserId !== userId) {
        return json(403, { ok: false, error: 'OWNER_MISMATCH' })
      }

      const { data: inserted, error: insErr } = await userClient
        .from('ledger_events_v0')
        .insert(insert)
        .select('*')
        .single()

      if (insErr) {
        return json(400, { ok: false, error: 'LEDGER_INSERT_FAILED', details: insErr.message })
      }

      const row = inserted as LedgerRow
      const canonical = canonicalize(buildCanonicalLedgerReceiptV0(row))
      const canonicalJson = JSON.stringify(canonical)
      const signed = await signCanonicalJson(canonicalJson)

      const sigRow = await upsertSignatureRow({
        ledger_row_id: String(row['id']),
        canonical_json: canonicalJson,
        schema_version: 0,
        ...signed,
      })

      return json(200, { ok: true, ledger_row: row, signature_row: sigRow })
    }

    if (action === 'sign_existing') {
      const rowId = String((body as any)?.ledger_row_id ?? (body as any)?.ledgerRowId ?? '')
      if (!rowId) {
        return json(400, { ok: false, error: 'MISSING_LEDGER_ROW_ID' })
      }

      // Read as user (RLS enforced). If unreadable, userClient returns null/error.
      const { data: row, error: readErr } = await userClient
        .from('ledger_events_v0')
        .select('*')
        .eq('id', rowId)
        .single()
      if (readErr) {
        return json(404, { ok: false, error: 'LEDGER_ROW_NOT_FOUND', details: readErr.message })
      }

      const ledgerRow = row as LedgerRow
      const canonical = canonicalize(buildCanonicalLedgerReceiptV0(ledgerRow))
      const canonicalJson = JSON.stringify(canonical)
      const signed = await signCanonicalJson(canonicalJson)

      const sigRow = await upsertSignatureRow({
        ledger_row_id: String(ledgerRow['id']),
        canonical_json: canonicalJson,
        schema_version: 0,
        ...signed,
      })

      return json(200, { ok: true, ledger_row: ledgerRow, signature_row: sigRow })
    }

    return json(400, { ok: false, error: 'UNKNOWN_ACTION', action })
  } catch (e) {
    return json(500, { ok: false, error: 'INTERNAL', details: String(e?.message ?? e) })
  }
})

