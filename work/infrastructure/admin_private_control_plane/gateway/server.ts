import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

type JsonMap = Record<string, unknown>

const RUNS_TABLE = 'admin_research_runs'
const CONTROL_ACTIONS_TABLE = 'admin_research_control_actions'
const CHECKPOINTS_TABLE = 'admin_research_checkpoints'
const APPROVALS_TABLE = 'admin_research_approvals'
const ARTIFACTS_TABLE = 'admin_research_artifacts'
const ALERTS_TABLE = 'admin_research_alerts'
const SESSIONS_TABLE = 'admin_control_plane_sessions'
const AUDIT_TABLE = 'admin_control_plane_audit_events'
const POLICY_TABLE = 'admin_control_plane_policy_decisions'

const port = Number(Deno.env.get('ADMIN_CONTROL_PLANE_PORT') ?? '7443')
const policyVersion = Deno.env.get('ADMIN_CONTROL_PLANE_POLICY_VERSION') ?? 'opa-gar-beta-v1'
const brokerUrl = Deno.env.get('ADMIN_CONTROL_PLANE_RESEARCH_BROKER_URL') ?? ''
const brokerSharedKey = Deno.env.get('RESEARCH_EGRESS_BROKER_SHARED_KEY') ?? ''
const opaUrl = Deno.env.get('ADMIN_CONTROL_PLANE_OPA_URL') ?? ''
const signingSecret = Deno.env.get('ADMIN_CONTROL_PLANE_EVIDENCE_SIGNING_SECRET') ?? ''
const allowedGroups = new Set(
  (Deno.env.get('ADMIN_CONTROL_PLANE_ALLOWED_GROUPS') ?? 'admin_operator')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
)
const allowedMeshProviders = new Set(
  (Deno.env.get('ADMIN_CONTROL_PLANE_ALLOWED_MESH_PROVIDERS') ?? 'headscale_tailscale')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
)
const requireProxyMesh = (Deno.env.get('ADMIN_CONTROL_PLANE_PROXY_MESH_REQUIRED') ?? 'false') === 'true'

function requireEnv(name: string): string {
  const value = Deno.env.get(name) ?? ''
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value
}

function supabaseAdmin(): SupabaseClient {
  return createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false },
    db: { schema: 'public' },
  })
}

const sb = supabaseAdmin()

function json(status: number, body: JsonMap): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  })
}

function normalizeBody<T extends JsonMap>(body: unknown): T {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return {} as T
  }
  return body as T
}

function parseBearerToken(req: Request): string {
  const header = req.headers.get('authorization') ?? ''
  if (!header.startsWith('Bearer ')) {
    return ''
  }
  return header.slice('Bearer '.length).trim()
}

function parseGroups(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.map((entry) => String(entry).trim().toLowerCase()).filter(Boolean)
  }
  return []
}

async function sha256(value: string): Promise<string> {
  const encoded = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', encoded)
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

function nowIso(): string {
  return new Date().toISOString()
}

function randomId(prefix: string): string {
  return `${prefix}_${crypto.randomUUID().replaceAll('-', '')}`
}

async function readJson(req: Request): Promise<JsonMap> {
  try {
    return normalizeBody(await req.json())
  } catch {
    return {}
  }
}

function filterSensitive(data: JsonMap): JsonMap {
  const blockedKeys = new Set([
    'user_id',
    'userId',
    'email',
    'phone',
    'location_history',
    'locationHistory',
    'raw_payload',
    'rawPayload',
    'consumer_identifier',
    'consumerIdentifier',
  ])
  const sanitized: JsonMap = {}
  for (const [key, value] of Object.entries(data)) {
    if (blockedKeys.has(key)) {
      continue
    }
    sanitized[key] = value
  }
  return sanitized
}

async function authorize(input: JsonMap): Promise<{ allow: boolean; reason: string }> {
  if (!opaUrl) {
    return { allow: false, reason: 'OPA URL is not configured.' }
  }
  try {
    const response = await fetch(`${opaUrl}/v1/data/admin/control_plane/decision`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ input }),
    })
    if (!response.ok) {
      return { allow: false, reason: `OPA request failed: ${response.status}` }
    }
    const payload = normalizeBody<{ result?: JsonMap }>(await response.json())
    const result = normalizeBody(payload.result)
    return {
      allow: result.allow === true,
      reason: String(result.reason ?? 'OPA denied the request.'),
    }
  } catch (error) {
    return { allow: false, reason: `OPA unavailable: ${error}` }
  }
}

async function recordPolicyDecision(args: {
  sessionId?: string | null
  actorAlias: string
  action: string
  allowed: boolean
  rationale: string
  stepUpSatisfied: boolean
  secondOperatorAlias?: string | null
}) {
  await sb.from(POLICY_TABLE).insert({
    id: randomId('policy'),
    session_id: args.sessionId ?? null,
    actor_alias: args.actorAlias,
    action: args.action,
    allowed: args.allowed,
    rationale: args.rationale,
    step_up_satisfied: args.stepUpSatisfied,
    second_operator_alias: args.secondOperatorAlias ?? null,
    policy_version: policyVersion,
    created_at: nowIso(),
  })
}

async function appendAudit(args: {
  action: string
  actorAlias: string
  runId?: string | null
  checkpointId?: string | null
  modelVersion?: string | null
  sessionId?: string | null
  deviceId?: string | null
  stepUpSatisfied: boolean
  secondOperatorAlias?: string | null
  details?: JsonMap
}) {
  await sb.from(AUDIT_TABLE).insert({
    id: randomId('audit'),
    action: args.action,
    actor_alias: args.actorAlias,
    run_id: args.runId ?? null,
    checkpoint_id: args.checkpointId ?? null,
    model_version: args.modelVersion ?? null,
    policy_version: policyVersion,
    device_id: args.deviceId ?? null,
    session_id: args.sessionId ?? null,
    step_up_satisfied: args.stepUpSatisfied,
    second_operator_alias: args.secondOperatorAlias ?? null,
    details: filterSensitive(args.details ?? {}),
    created_at: nowIso(),
  })
}

async function requireSession(
  req: Request,
  action: string,
  stepUpRequired = false,
  requiresSecondOperator = false,
  bodyOverride?: JsonMap,
) {
  const token = parseBearerToken(req)
  if (!token) {
    throw new Error('Missing control-plane bearer token.')
  }
  const tokenHash = await sha256(token)
  const { data, error } = await sb
    .from(SESSIONS_TABLE)
    .select('*')
    .eq('session_token_hash', tokenHash)
    .is('revoked_at', null)
    .maybeSingle()
  if (error || !data) {
    throw new Error('Invalid or revoked control-plane session.')
  }
  const expiresAt = new Date(String(data.expires_at))
  if (expiresAt.getTime() <= Date.now()) {
    throw new Error('Control-plane session expired.')
  }
  const body = bodyOverride ?? await readJson(req.clone())
  const secondOperatorApproval = normalizeBody<JsonMap>(body.secondOperatorApproval)
  const decision = await authorize({
    action,
    actorAlias: data.actor_alias,
    role: data.role,
    session: {
      id: data.id,
      deviceId: data.device_id,
      meshIdentity: data.mesh_identity,
      clientCertificateFingerprint: data.client_certificate_fingerprint,
      expiresAt: data.expires_at,
    },
    request: body,
    stepUpRequired,
    requiresSecondOperator,
    policyVersion,
  })
  await recordPolicyDecision({
    sessionId: data.id,
    actorAlias: String(data.actor_alias),
    action,
    allowed: decision.allow,
    rationale: decision.reason,
    stepUpSatisfied: Boolean(normalizeBody<JsonMap>(body.stepUpProof).proof),
    secondOperatorAlias: secondOperatorApproval.actorAlias ? String(secondOperatorApproval.actorAlias) : null,
  })
  if (!decision.allow) {
    throw new Error(decision.reason)
  }
  return data
}

async function listRuns(): Promise<JsonMap[]> {
  const { data: runs, error: runError } = await sb.from(RUNS_TABLE).select('*').order('updated_at', { ascending: false })
  if (runError) {
    throw new Error(runError.message)
  }
  const runRows = (runs ?? []) as JsonMap[]
  const runIds = new Set(runRows.map((row) => String(row.id ?? '')).filter(Boolean))
  const [controlsRes, checkpointsRes, approvalsRes, artifactsRes, alertsRes] = await Promise.all([
    sb.from(CONTROL_ACTIONS_TABLE).select('*').order('created_at', { ascending: true }),
    sb.from(CHECKPOINTS_TABLE).select('*').order('created_at', { ascending: true }),
    sb.from(APPROVALS_TABLE).select('*').order('created_at', { ascending: true }),
    sb.from(ARTIFACTS_TABLE).select('*').order('created_at', { ascending: true }),
    sb.from(ALERTS_TABLE).select('*').order('created_at', { ascending: false }),
  ])
  if (controlsRes.error || checkpointsRes.error || approvalsRes.error || artifactsRes.error || alertsRes.error) {
    throw new Error(
      controlsRes.error?.message ??
        checkpointsRes.error?.message ??
        approvalsRes.error?.message ??
        artifactsRes.error?.message ??
        alertsRes.error?.message ??
        'Failed to assemble research runs.',
    )
  }

  const byRun = <T extends JsonMap>(rows: T[], runKey: string) =>
    rows.reduce<Record<string, T[]>>((map, row) => {
      const runId = String(row[runKey] ?? '')
      if (!runIds.has(runId)) {
        return map
      }
      map[runId] ??= []
      map[runId].push(row)
      return map
    }, {})

  const controlsByRun = byRun((controlsRes.data ?? []) as JsonMap[], 'run_id')
  const checkpointsByRun = byRun((checkpointsRes.data ?? []) as JsonMap[], 'run_id')
  const approvalsByRun = byRun((approvalsRes.data ?? []) as JsonMap[], 'run_id')
  const artifactsByRun = byRun((artifactsRes.data ?? []) as JsonMap[], 'run_id')
  const alertsByRun = byRun((alertsRes.data ?? []) as JsonMap[], 'run_id')

  return runRows.map((row) => {
    const runId = String(row.id ?? '')
    return {
      id: runId,
      title: String(row.title ?? ''),
      hypothesis: String(row.hypothesis ?? ''),
      layer: String(row.layer ?? 'crossLayer'),
      ownerAgentAlias: String(row.owner_agent_alias ?? 'unknown_agent'),
      lifecycleState: String(row.lifecycle_state ?? 'draft'),
      humanAccess: String(row.human_access ?? 'adminOnly'),
      visibilityScope: String(row.visibility_scope ?? 'runtimeInternalProjection'),
      lane: String(row.lane ?? 'sandboxReplay'),
      charter: row.charter ?? {},
      egressMode: String(row.egress_mode ?? 'internalOnly'),
      requiresAdminApproval: Boolean(row.requires_admin_approval ?? true),
      sandboxOnly: Boolean(row.sandbox_only ?? true),
      modelVersion: String(row.model_version ?? ''),
      policyVersion: String(row.policy_version ?? policyVersion),
      metrics: row.metrics ?? {},
      tags: row.tags ?? [],
      controlActions: (controlsByRun[runId] ?? []).map((item) => ({
        id: item.id,
        runId,
        actionType: item.action_type,
        actorAlias: item.actor_alias,
        rationale: item.rationale,
        createdAt: item.created_at,
        modelVersion: item.model_version,
        policyVersion: item.policy_version,
        details: filterSensitive(normalizeBody(item.details)),
        checkpointId: item.checkpoint_id,
      })),
      checkpoints: (checkpointsByRun[runId] ?? []).map((item) => ({
        id: item.id,
        runId,
        summary: item.summary,
        state: item.state,
        createdAt: item.created_at,
        metricSnapshot: item.metric_snapshot ?? {},
        artifactIds: item.artifact_ids ?? [],
        requiresHumanReview: Boolean(item.requires_human_review ?? false),
        contradictionDetected: Boolean(item.contradiction_detected ?? false),
      })),
      approvals: (approvalsByRun[runId] ?? []).map((item) => ({
        id: item.id,
        runId,
        kind: item.kind,
        status: item.status,
        createdAt: item.created_at,
        actorAlias: item.actor_alias,
        reason: item.reason,
        decidedAt: item.decided_at,
        expiresAt: item.expires_at,
      })),
      artifacts: (artifactsByRun[runId] ?? []).map((item) => ({
        id: item.id,
        runId,
        kind: item.kind,
        storageKey: item.storage_key,
        summary: item.summary,
        createdAt: item.created_at,
        isRedacted: true,
        checksum: item.checksum,
        expiresAt: item.expires_at,
      })),
      alerts: (alertsByRun[runId] ?? []).map((item) => ({
        id: item.id,
        runId,
        severity: item.severity,
        title: item.title,
        message: item.message,
        createdAt: item.created_at,
      })),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      latestExplanation: row.latest_explanation ?? null,
      latestSandboxProjection: row.latest_sandbox_projection ?? null,
      lastHeartbeatAt: row.last_heartbeat_at ?? null,
      activeCheckpointId: row.active_checkpoint_id ?? null,
      redirectDirective: row.redirect_directive ?? null,
      contradictionDetected: Boolean(row.contradiction_detected ?? false),
      killSwitchActive: Boolean(row.kill_switch_active ?? false),
    }
  })
}

async function requireRun(runId: string): Promise<JsonMap> {
  const runs = await listRuns()
  const run = runs.find((item) => String(item.id) === runId)
  if (!run) {
    throw new Error(`Unknown research run: ${runId}`)
  }
  return run
}

async function writeRun(run: JsonMap) {
  const payload = {
    id: run.id,
    title: run.title,
    hypothesis: run.hypothesis,
    layer: run.layer,
    owner_agent_alias: run.ownerAgentAlias,
    lifecycle_state: run.lifecycleState,
    human_access: run.humanAccess,
    visibility_scope: run.visibilityScope,
    lane: run.lane,
    charter: run.charter,
    egress_mode: run.egressMode,
    requires_admin_approval: run.requiresAdminApproval,
    sandbox_only: run.sandboxOnly,
    model_version: run.modelVersion,
    policy_version: run.policyVersion,
    metrics: run.metrics,
    tags: run.tags,
    latest_explanation: run.latestExplanation ?? null,
    latest_sandbox_projection: run.latestSandboxProjection ?? null,
    last_heartbeat_at: run.lastHeartbeatAt ?? null,
    active_checkpoint_id: run.activeCheckpointId ?? null,
    redirect_directive: run.redirectDirective ?? null,
    contradiction_detected: run.contradictionDetected ?? false,
    kill_switch_active: run.killSwitchActive ?? false,
    created_at: run.createdAt,
    updated_at: run.updatedAt,
  }
  const { error } = await sb.from(RUNS_TABLE).upsert(payload)
  if (error) {
    throw new Error(error.message)
  }
}

async function writeControlAction(args: {
  run: JsonMap
  actorAlias: string
  actionType: string
  rationale: string
  checkpointId?: string | null
  details?: JsonMap
}) {
  const { error } = await sb.from(CONTROL_ACTIONS_TABLE).insert({
    id: randomId('ctl'),
    run_id: args.run.id,
    action_type: args.actionType,
    actor_alias: args.actorAlias,
    rationale: args.rationale,
    created_at: nowIso(),
    model_version: args.run.modelVersion,
    policy_version: args.run.policyVersion,
    details: filterSensitive(args.details ?? {}),
    checkpoint_id: args.checkpointId ?? null,
  })
  if (error) {
    throw new Error(error.message)
  }
}

async function writeApproval(args: {
  runId: string
  kind: string
  status: string
  actorAlias?: string | null
  reason?: string | null
  decidedAt?: string | null
  expiresAt?: string | null
}) {
  const { error } = await sb.from(APPROVALS_TABLE).insert({
    id: randomId('apr'),
    run_id: args.runId,
    kind: args.kind,
    status: args.status,
    actor_alias: args.actorAlias ?? null,
    reason: args.reason ?? null,
    decided_at: args.decidedAt ?? null,
    expires_at: args.expiresAt ?? null,
    created_at: nowIso(),
  })
  if (error) {
    throw new Error(error.message)
  }
}

async function writeArtifact(args: {
  runId: string
  kind: string
  storageKey: string
  summary: string
  checksum?: string | null
  expiresAt?: string | null
  isRedacted?: boolean
}) {
  const artifactId = randomId('art')
  const { error } = await sb.from(ARTIFACTS_TABLE).insert({
    id: artifactId,
    run_id: args.runId,
    kind: args.kind,
    storage_key: args.storageKey,
    summary: args.summary,
    created_at: nowIso(),
    is_redacted: args.isRedacted ?? true,
    checksum: args.checksum ?? null,
    expires_at: args.expiresAt ?? null,
  })
  if (error) {
    throw new Error(error.message)
  }
  return artifactId
}

async function writeCheckpoint(args: {
  runId: string
  summary: string
  state: string
  metricSnapshot: JsonMap
  requiresHumanReview?: boolean
  contradictionDetected?: boolean
}) {
  const checkpointId = randomId('chk')
  const { error } = await sb.from(CHECKPOINTS_TABLE).insert({
    id: checkpointId,
    run_id: args.runId,
    summary: args.summary,
    state: args.state,
    metric_snapshot: args.metricSnapshot,
    artifact_ids: [],
    requires_human_review: args.requiresHumanReview ?? false,
    contradiction_detected: args.contradictionDetected ?? false,
    created_at: nowIso(),
  })
  if (error) {
    throw new Error(error.message)
  }
  return checkpointId
}

function currentStepForState(state: string): string {
  switch (state) {
    case 'running':
      return 'Executing bounded sandbox experiment.'
    case 'paused':
      return 'Waiting for operator resume.'
    case 'review':
      return 'Awaiting human review.'
    case 'redirectPending':
      return 'Awaiting redirected charter execution.'
    default:
      return 'Maintaining governed beta posture.'
  }
}

function nextStepForState(state: string): string {
  switch (state) {
    case 'draft':
      return 'Await charter approval.'
    case 'approved':
      return 'Queue the run for sandbox execution.'
    case 'running':
      return 'Checkpoint after the next safe boundary.'
    case 'paused':
      return 'Resume or redirect after review.'
    case 'review':
      return 'Approve, reject, or redirect.'
    default:
      return 'Keep the run archived unless a new revision is approved.'
  }
}

async function mutateRun(args: {
  runId: string
  actorAlias: string
  actionType: string
  rationale: string
  session: JsonMap
  mutate: (run: JsonMap) => JsonMap
  stepUpSatisfied?: boolean
  secondOperatorAlias?: string | null
}) {
  const run = await requireRun(args.runId)
  const updated = args.mutate(run)
  await writeRun(updated)
  await writeControlAction({
    run: updated,
    actorAlias: args.actorAlias,
    actionType: args.actionType,
    rationale: args.rationale,
    checkpointId: String(updated.activeCheckpointId ?? ''),
  })
  await appendAudit({
    action: args.actionType,
    actorAlias: args.actorAlias,
    runId: args.runId,
    checkpointId: updated.activeCheckpointId ? String(updated.activeCheckpointId) : null,
    modelVersion: String(updated.modelVersion ?? ''),
    sessionId: String(args.session.id ?? ''),
    deviceId: String(args.session.device_id ?? ''),
    stepUpSatisfied: args.stepUpSatisfied ?? false,
    secondOperatorAlias: args.secondOperatorAlias ?? null,
    details: { rationale: args.rationale },
  })
  return requireRun(args.runId)
}

async function createSession(req: Request) {
  const body = await readJson(req)
  const deviceAttestation = normalizeBody<JsonMap>(body.deviceAttestation)
  const decision = await authorize({
    action: 'create_session',
    actorAlias: String(body.operatorAlias ?? ''),
    request: body,
    deviceAttestation,
    allowedGroups: parseGroups(body.allowedGroups),
    allowedMeshProviders: Array.from(allowedMeshProviders),
    requireProxyMesh,
    policyVersion,
  })
  await recordPolicyDecision({
    actorAlias: String(body.operatorAlias ?? 'unknown'),
    action: 'create_session',
    allowed: decision.allow,
    rationale: decision.reason,
    stepUpSatisfied: false,
  })
  if (!decision.allow) {
    return json(403, { error: decision.reason })
  }

  const token = crypto.randomUUID()
  const grant = {
    sessionToken: token,
    sessionTokenId: randomId('cp_session'),
    actorAlias: String(body.operatorAlias ?? 'admin_operator'),
    role: 'adminOperator',
    expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    issuedBy: 'private_admin_control_plane_gateway',
    policyVersion,
    deviceId: String(deviceAttestation.deviceId ?? ''),
    meshIdentity: String(deviceAttestation.meshIdentity ?? ''),
    clientCertificateFingerprint: String(deviceAttestation.clientCertificateFingerprint ?? ''),
    requiresPrivateControlPlane: true,
  }
  const tokenHash = await sha256(token)
  const { error } = await sb.from(SESSIONS_TABLE).insert({
    id: grant.sessionTokenId,
    actor_alias: grant.actorAlias,
    role: grant.role,
    issued_by: grant.issuedBy,
    policy_version: grant.policyVersion,
    device_id: grant.deviceId,
    mesh_identity: grant.meshIdentity,
    client_certificate_fingerprint: grant.clientCertificateFingerprint,
    device_attestation: deviceAttestation,
    session_token_hash: tokenHash,
    expires_at: grant.expiresAt,
    revoked_at: null,
    created_at: nowIso(),
  })
  if (error) {
    return json(500, { error: error.message })
  }
  await appendAudit({
    action: 'create_session',
    actorAlias: grant.actorAlias,
    sessionId: grant.sessionTokenId,
    deviceId: grant.deviceId,
    stepUpSatisfied: false,
    details: {
      meshIdentity: grant.meshIdentity,
      deviceId: grant.deviceId,
      role: grant.role,
    },
  })
  return json(200, grant)
}

async function revokeSession(req: Request) {
  const session = await requireSession(req, 'revoke_session', false, false)
  const { error } = await sb
    .from(SESSIONS_TABLE)
    .update({ revoked_at: nowIso() })
    .eq('id', session.id)
  if (error) {
    return json(500, { error: error.message })
  }
  await appendAudit({
    action: 'revoke_session',
    actorAlias: String(session.actor_alias),
    sessionId: String(session.id),
    deviceId: String(session.device_id),
    stepUpSatisfied: false,
    details: {},
  })
  return json(200, { revoked: true })
}

async function routeAction(req: Request, runId: string, action: string) {
  const body = await readJson(req)
  const sensitive = new Set([
    'stop_run',
    'redirect_run',
    'approve_open_web',
    'review_candidate',
    'trigger_kill_switch',
    'download_evidence_pack',
  ])
  const dual = new Set(['approve_open_web', 'trigger_kill_switch'])
  const session = await requireSession(
    req,
    action,
    sensitive.has(action),
    dual.has(action),
    body,
  )
  const actorAlias = String(body.actorAlias ?? session.actor_alias ?? 'admin_operator')
  try {
    switch (action) {
      case 'approve_charter': {
        const run = await requireRun(runId)
        const updated = {
          ...run,
          lifecycleState: 'approved',
          charter: {
            ...normalizeBody<JsonMap>(run.charter),
            approvedBy: actorAlias,
            approvedAt: nowIso(),
            updatedAt: nowIso(),
          },
          updatedAt: nowIso(),
        }
        await writeApproval({
          runId,
          kind: 'charter',
          status: 'approved',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'approveCharter',
          rationale: String(body.rationale ?? 'Charter approved.'),
          session,
          mutate: () => updated,
        })
        return json(200, { run: next })
      }
      case 'reject_charter': {
        await writeApproval({
          runId,
          kind: 'charter',
          status: 'rejected',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'reviewCandidate',
          rationale: String(body.rationale ?? 'Charter rejected.'),
          session,
          mutate: (run) => ({ ...run, lifecycleState: 'archived', updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'queue_run': {
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'queueRun',
          rationale: 'Queued for sandbox execution.',
          session,
          mutate: (run) => ({ ...run, lifecycleState: 'queued', updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'start_sandbox_run': {
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'startSandboxRun',
          rationale: 'Sandbox run started.',
          session,
          mutate: (run) => ({ ...run, lifecycleState: 'running', lastHeartbeatAt: nowIso(), updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'pause_run': {
        const checkpointId = await writeCheckpoint({
          runId,
          summary: 'Operator pause checkpoint',
          state: 'paused',
          metricSnapshot: normalizeBody(await requireRun(runId).then((run) => normalizeBody(run.metrics))),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'pauseRun',
          rationale: String(body.rationale ?? 'Paused at the next safe checkpoint.'),
          session,
          mutate: (run) => ({
            ...run,
            lifecycleState: 'paused',
            activeCheckpointId: checkpointId,
            updatedAt: nowIso(),
          }),
        })
        return json(200, { run: next })
      }
      case 'resume_run': {
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'resumeRun',
          rationale: 'Resumed from checkpoint.',
          session,
          mutate: (run) => ({ ...run, lifecycleState: 'running', lastHeartbeatAt: nowIso(), updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'stop_run': {
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'stopRun',
          rationale: String(body.rationale ?? 'Stopped by admin.'),
          session,
          stepUpSatisfied: true,
          mutate: (run) => ({ ...run, lifecycleState: 'stopped', updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'redirect_run': {
        const directive = String(body.directive ?? '')
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'redirectRun',
          rationale: directive,
          session,
          stepUpSatisfied: true,
          mutate: (run) => ({
            ...run,
            lifecycleState: 'redirectPending',
            redirectDirective: directive,
            updatedAt: nowIso(),
          }),
        })
        return json(200, { run: next })
      }
      case 'get_explanation': {
        const run = await requireRun(runId)
        const explanation = {
          id: randomId('exp'),
          runId,
          summary: `${run.title} is in ${run.lifecycleState} and remains sandbox-only.`,
          currentStep: currentStepForState(String(run.lifecycleState)),
          rationale: String(run.redirectDirective ?? normalizeBody<JsonMap>(run.charter).objective ?? ''),
          nextStep: nextStepForState(String(run.lifecycleState)),
          evidenceSummary: String(run.egressMode) === 'brokeredOpenWeb'
            ? 'Using internal evidence plus approved brokered outbound fetches.'
            : 'Using internal replay, ledgers, and approved local artifacts.',
          createdAt: nowIso(),
          checkpointId: run.activeCheckpointId ?? null,
        }
        await writeRun({ ...run, latestExplanation: explanation, updatedAt: nowIso() })
        await writeControlAction({
          run,
          actorAlias,
          actionType: 'requestExplanation',
          rationale: 'Generated explanation.',
        })
        await appendAudit({
          action: 'requestExplanation',
          actorAlias,
          runId,
          checkpointId: explanation.checkpointId ? String(explanation.checkpointId) : null,
          modelVersion: String(run.modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: false,
          details: { summary: explanation.summary },
        })
        return json(200, { explanation })
      }
      case 'review_candidate': {
        const approved = body.approved === true
        await writeApproval({
          runId,
          kind: 'reviewDisposition',
          status: approved ? 'approved' : 'rejected',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'reviewCandidate',
          rationale: String(body.rationale ?? ''),
          session,
          stepUpSatisfied: true,
          secondOperatorAlias: body.secondOperatorApproval ? String(normalizeBody<JsonMap>(body.secondOperatorApproval).actorAlias ?? '') : null,
          mutate: (run) => ({
            ...run,
            lifecycleState: approved ? 'completed' : 'archived',
            updatedAt: nowIso(),
          }),
        })
        return json(200, { run: next })
      }
      case 'add_operator_note': {
        const note = String(body.note ?? '')
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'appendNote',
          rationale: note,
          session,
          mutate: (run) => ({ ...run, updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'checkpoint_run': {
        const metricSnapshot = normalizeBody<JsonMap>(body.metricSnapshot)
        const requiresHumanReview = body.requiresHumanReview === true
        const contradictionDetected = body.contradictionDetected === true
        const run = await requireRun(runId)
        const checkpointId = await writeCheckpoint({
          runId,
          summary: String(body.summary ?? ''),
          state: requiresHumanReview || contradictionDetected ? 'review' : String(run.lifecycleState),
          metricSnapshot,
          requiresHumanReview,
          contradictionDetected,
        })
        const updated = {
          ...run,
          latestSandboxProjection: {
            runId,
            checkpointId,
            summary: String(body.summary ?? ''),
            metrics: metricSnapshot,
            createdAt: nowIso(),
            promotionCandidate: Number(metricSnapshot.promotionReadiness ?? 0) >= 0.8,
            safeForModelConsumption: true,
            violationCount: contradictionDetected ? 1 : 0,
          },
          activeCheckpointId: checkpointId,
          contradictionDetected,
          lifecycleState: requiresHumanReview || contradictionDetected ? 'review' : run.lifecycleState,
          lastHeartbeatAt: nowIso(),
          updatedAt: nowIso(),
        }
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'checkpointRun',
          rationale: String(body.summary ?? ''),
          session,
          mutate: () => updated,
        })
        return json(200, {
          checkpoint: {
            id: checkpointId,
            runId,
            summary: String(body.summary ?? ''),
            state: requiresHumanReview || contradictionDetected ? 'review' : String(run.lifecycleState),
            createdAt: nowIso(),
            metricSnapshot,
            artifactIds: [],
            requiresHumanReview,
            contradictionDetected,
          },
          run: next,
        })
      }
      case 'append_artifact': {
        const expiresAt =
          String(body.kind ?? '') === 'evidenceBundle'
            ? new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString()
            : null
        const artifactId = await writeArtifact({
          runId,
          kind: String(body.kind ?? 'auditLedger'),
          storageKey: String(body.storageKey ?? ''),
          summary: String(body.summary ?? ''),
          checksum: body.checksum ? String(body.checksum) : null,
          expiresAt,
          isRedacted: body.isRedacted !== false,
        })
        const artifact = {
          id: artifactId,
          runId,
          kind: String(body.kind ?? 'auditLedger'),
          storageKey: String(body.storageKey ?? ''),
          summary: String(body.summary ?? ''),
          createdAt: nowIso(),
          isRedacted: body.isRedacted !== false,
          checksum: body.checksum ? String(body.checksum) : null,
          expiresAt,
        }
        await appendAudit({
          action: 'appendArtifact',
          actorAlias,
          runId,
          modelVersion: String((await requireRun(runId)).modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: false,
          details: { kind: artifact.kind, storageKey: artifact.storageKey },
        })
        return json(200, { artifact })
      }
      case 'emit_alert': {
        const alert = normalizeBody<JsonMap>(body.alert)
        const { error } = await sb.from(ALERTS_TABLE).insert({
          id: String(alert.id ?? randomId('alert')),
          run_id: String(alert.runId ?? runId),
          severity: String(alert.severity ?? 'warning'),
          title: String(alert.title ?? 'Alert'),
          message: String(alert.message ?? ''),
          created_at: String(alert.createdAt ?? nowIso()),
        })
        if (error) {
          return json(500, { error: error.message })
        }
        await appendAudit({
          action: 'emitAlert',
          actorAlias,
          runId,
          modelVersion: String((await requireRun(runId)).modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: false,
          details: {
            severity: String(alert.severity ?? 'warning'),
            title: String(alert.title ?? 'Alert'),
          },
        })
        return json(200, { ok: true })
      }
      case 'request_open_web': {
        const ttlMinutes = Number(body.ttlMinutes ?? 240)
        const expiresAt = new Date(Date.now() + ttlMinutes * 60 * 1000).toISOString()
        await writeApproval({
          runId,
          kind: 'egressOpenWeb',
          status: 'pending',
          actorAlias,
          reason: String(body.rationale ?? ''),
          expiresAt,
        })
        await appendAudit({
          action: 'request_open_web_approval',
          actorAlias,
          runId,
          modelVersion: String((await requireRun(runId)).modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: true,
          details: { ttlMinutes, rationale: String(body.rationale ?? '') },
        })
        return json(200, {
          approval: {
            runId,
            kind: 'egressOpenWeb',
            status: 'pending',
            actorAlias,
            reason: String(body.rationale ?? ''),
            createdAt: nowIso(),
            expiresAt,
          },
        })
      }
      case 'approve_open_web': {
        const ttlMinutes = Number(body.ttlMinutes ?? 240)
        const expiresAt = new Date(Date.now() + ttlMinutes * 60 * 1000).toISOString()
        await writeApproval({
          runId,
          kind: 'egressOpenWeb',
          status: 'approved',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
          expiresAt,
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'reviewCandidate',
          rationale: String(body.rationale ?? 'Brokered open-web access approved by dual control.'),
          session,
          stepUpSatisfied: true,
          secondOperatorAlias: String(normalizeBody<JsonMap>(body.secondOperatorApproval).actorAlias ?? ''),
          mutate: (run) => ({ ...run, egressMode: 'brokeredOpenWeb', updatedAt: nowIso() }),
        })
        return json(200, {
          approval: {
            runId,
            kind: 'egressOpenWeb',
            status: 'approved',
            actorAlias,
            reason: String(body.rationale ?? ''),
            createdAt: nowIso(),
            decidedAt: nowIso(),
            expiresAt,
          },
          run: next,
        })
      }
      case 'reject_open_web': {
        await writeApproval({
          runId,
          kind: 'egressOpenWeb',
          status: 'rejected',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'reviewCandidate',
          rationale: String(body.rationale ?? 'Brokered open-web access denied.'),
          session,
          stepUpSatisfied: true,
          mutate: (run) => ({ ...run, egressMode: 'internalOnly', updatedAt: nowIso() }),
        })
        return json(200, {
          approval: {
            runId,
            kind: 'egressOpenWeb',
            status: 'rejected',
            actorAlias,
            reason: String(body.rationale ?? ''),
            createdAt: nowIso(),
            decidedAt: nowIso(),
          },
          run: next,
        })
      }
      case 'fetch_evidence': {
        const run = await requireRun(runId)
        const sourceUri = String(body.sourceUri ?? '')
        if (String(run.egressMode) !== 'brokeredOpenWeb' && /^https?:/i.test(sourceUri)) {
          return json(403, { error: 'Open-web access has not been approved for this run.' })
        }
        if (!brokerUrl || !brokerSharedKey) {
          return json(503, { error: 'Research egress broker is not configured.' })
        }
        const brokerResponse = await fetch(`${brokerUrl}/fetch`, {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            'x-broker-shared-key': brokerSharedKey,
          },
          body: JSON.stringify({
            runId,
            actorAlias,
            sourceUri,
          }),
        })
        const brokerPayload = normalizeBody<JsonMap>(await brokerResponse.json())
        if (!brokerResponse.ok) {
          return json(brokerResponse.status, { error: String(brokerPayload.error ?? 'Broker fetch failed.') })
        }
        const artifactId = await writeArtifact({
          runId,
          kind: 'evidenceBundle',
          storageKey: String(brokerPayload.storageKey ?? ''),
          summary: String(brokerPayload.summary ?? ''),
          checksum: brokerPayload.checksum ? String(brokerPayload.checksum) : null,
          expiresAt: brokerPayload.expiresAt ? String(brokerPayload.expiresAt) : null,
          isRedacted: true,
        })
        const { error } = await sb
          .from('admin_research_quarantined_payloads')
          .update({ artifact_id: artifactId })
          .eq('id', String(brokerPayload.quarantineId ?? ''))
        if (error) {
          return json(500, { error: error.message })
        }
        await appendAudit({
          action: 'fetchEvidence',
          actorAlias,
          runId,
          modelVersion: String(run.modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: false,
          details: { sourceUri, brokered: true },
        })
        return json(200, {
          artifact: {
            id: artifactId,
            runId,
            kind: 'evidenceBundle',
            storageKey: String(brokerPayload.storageKey ?? ''),
            summary: String(brokerPayload.summary ?? ''),
            createdAt: nowIso(),
            isRedacted: true,
            checksum: brokerPayload.checksum ? String(brokerPayload.checksum) : null,
            expiresAt: brokerPayload.expiresAt ? String(brokerPayload.expiresAt) : null,
          },
        })
      }
      case 'revoke_access': {
        await writeApproval({
          runId,
          kind: 'egressOpenWeb',
          status: 'revoked',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'revokeEgressApproval',
          rationale: String(body.rationale ?? 'Brokered access revoked.'),
          session,
          mutate: (run) => ({ ...run, egressMode: 'internalOnly', updatedAt: nowIso() }),
        })
        return json(200, { run: next })
      }
      case 'record_disposition': {
        const approved = body.approved === true
        await writeApproval({
          runId,
          kind: 'reviewDisposition',
          status: approved ? 'approved' : 'rejected',
          actorAlias,
          reason: String(body.rationale ?? ''),
          decidedAt: nowIso(),
        })
        return json(200, {
          approval: {
            runId,
            kind: 'reviewDisposition',
            status: approved ? 'approved' : 'rejected',
            actorAlias,
            reason: String(body.rationale ?? ''),
            createdAt: nowIso(),
            decidedAt: nowIso(),
          },
        })
      }
      case 'trigger_kill_switch': {
        const next = await mutateRun({
          runId,
          actorAlias,
          actionType: 'triggerKillSwitch',
          rationale: String(body.rationale ?? 'Break-glass kill switch.'),
          session,
          stepUpSatisfied: true,
          secondOperatorAlias: String(normalizeBody<JsonMap>(body.secondOperatorApproval).actorAlias ?? ''),
          mutate: (run) => ({
            ...run,
            killSwitchActive: true,
            lifecycleState: 'stopped',
            updatedAt: nowIso(),
          }),
        })
        return json(200, { run: next })
      }
      case 'download_evidence_pack': {
        const artifactIds = Array.isArray(body.artifactIds) ? body.artifactIds.map((item) => String(item)) : []
        const checksum = await sha256(`${runId}:${artifactIds.join(',')}:${signingSecret || 'unsigned'}`)
        const storageKey = `evidence-pack://${runId}/${randomId('pack')}`
        const artifactId = await writeArtifact({
          runId,
          kind: 'signedEvidencePack',
          storageKey,
          summary: `Signed redacted evidence pack for ${artifactIds.length} artifacts.`,
          checksum,
          isRedacted: true,
        })
        await appendAudit({
          action: 'downloadEvidencePack',
          actorAlias,
          runId,
          modelVersion: String((await requireRun(runId)).modelVersion ?? ''),
          sessionId: String(session.id),
          deviceId: String(session.device_id),
          stepUpSatisfied: true,
          details: { artifactIds },
        })
        return json(200, {
          artifact: {
            id: artifactId,
            runId,
            kind: 'signedEvidencePack',
            storageKey,
            summary: `Signed redacted evidence pack for ${artifactIds.length} artifacts.`,
            createdAt: nowIso(),
            isRedacted: true,
            checksum,
          },
        })
      }
      default:
        return json(404, { error: `Unknown action: ${action}` })
    }
  } catch (error) {
    return json(400, { error: String(error) })
  }
}

serve(async (req) => {
  try {
    const url = new URL(req.url)
    if (req.method === 'GET' && url.pathname === '/health') {
      return json(200, {
        status: 'ok',
        service: 'admin-control-plane-gateway',
        policyVersion,
        brokerConfigured: Boolean(brokerUrl),
        opaConfigured: Boolean(opaUrl),
        privateMeshRequired: requireProxyMesh,
      })
    }

    if (req.method === 'POST' && url.pathname === '/v1/sessions') {
      return createSession(req)
    }
    if (req.method === 'POST' && url.pathname === '/v1/sessions/revoke') {
      return revokeSession(req)
    }
    if (req.method === 'GET' && url.pathname === '/v1/research/runs') {
      await requireSession(req, 'list_runs', false, false)
      return json(200, { runs: await listRuns() })
    }
    if (req.method === 'GET' && url.pathname === '/v1/research/alerts') {
      await requireSession(req, 'list_alerts', false, false)
      const { data, error } = await sb.from(ALERTS_TABLE).select('*').order('created_at', { ascending: false })
      if (error) {
        return json(500, { error: error.message })
      }
      return json(200, {
        alerts: (data ?? []).map((item: JsonMap) => ({
          id: item.id,
          runId: item.run_id,
          severity: item.severity,
          title: item.title,
          message: item.message,
          createdAt: item.created_at,
        })),
      })
    }
    const runMatch = url.pathname.match(/^\/v1\/research\/runs\/([^/]+)$/)
    if (req.method === 'GET' && runMatch) {
      await requireSession(req, 'watch_run', false, false)
      const run = await requireRun(decodeURIComponent(runMatch[1]))
      return json(200, { run })
    }
    const actionMatch = url.pathname.match(/^\/v1\/research\/runs\/([^/]+)\/actions\/([^/]+)$/)
    if (req.method === 'POST' && actionMatch) {
      return routeAction(req, decodeURIComponent(actionMatch[1]), decodeURIComponent(actionMatch[2]))
    }

    return json(404, { error: 'Not found' })
  } catch (error) {
    return json(500, { error: String(error) })
  }
}, { port })
