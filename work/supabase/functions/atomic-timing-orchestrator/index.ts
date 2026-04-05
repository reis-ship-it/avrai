// Supabase Edge Function: Atomic Timing Orchestrator (Option B)
//
// Purpose:
// - Central “job runner” that reads timing policies and executes scheduled work.
// - This is the backend counterpart to the on-device Quantum Atomic Time system:
//   policies can be updated by learning systems, then executed here on schedule.
//
// Scheduling:
// - Recommended: Supabase Scheduled Edge Functions (cron) invoking this function.
// - Fallback: manual invoke (service role).
//
// Security:
// - `verify_jwt` is **disabled** for this function (so it can be called by schedulers).
// - Uses service role client internally.
// - Requires Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import JSZip from 'npm:jszip@3.10.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  return createClient(url, serviceKey, { auth: { persistSession: false } })
}

function isAuthorized(req: Request): boolean {
  const auth = req.headers.get('authorization') ?? ''
  const token = auth.startsWith('Bearer ') ? auth.slice('Bearer '.length) : ''
  const expected = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  return token.length > 0 && expected.length > 0 && token === expected
}

type RunTarget =
  | 'all'
  | 'outside_buyer_precompute'
  | 'city_code_population'
  | 'geo_boundary_aggregate'
  | 'geo_vibe_aggregate'
  | 'geo_knot_build'
  | 'geo_synco_build'
  | 'geo_city_pack_build'

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const started = Date.now()
  const url = new URL(req.url)
  const hasTargetQP = url.searchParams.has('target')
  const hasCityQP = url.searchParams.has('city_code')

  let target = (url.searchParams.get('target') ?? 'all') as RunTarget
  let cityCodeParam = url.searchParams.get('city_code') ?? ''

  // Dashboard “Test” uses JSON body. Accept body params when query params are absent.
  if (!hasTargetQP || !hasCityQP) {
    try {
      const body = await req.json()
      if (body && typeof body === 'object') {
        if (!hasTargetQP && typeof body.target === 'string') {
          target = body.target as RunTarget
        }
        if (!hasCityQP && typeof body.city_code === 'string') {
          cityCodeParam = body.city_code
        } else if (!hasCityQP && typeof body.cityCode === 'string') {
          cityCodeParam = body.cityCode
        }
      }
    } catch (_) {
      // Ignore body parse failures; query params remain authoritative.
    }
  }

  if (!isAuthorized(req)) {
    return new Response(JSON.stringify({ ok: false, error: 'UNAUTHORIZED' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = supabaseAdmin()

  const results: Record<string, unknown> = {}

  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz'
  function encodeGeohash(latitude: number, longitude: number, precision: number): string {
    let latMin = -90.0, latMax = 90.0
    let lonMin = -180.0, lonMax = 180.0
    let hash = ''
    let bit = 0
    let ch = 0
    let even = true

    while (hash.length < precision) {
      if (even) {
        const mid = (lonMin + lonMax) / 2
        if (longitude >= mid) {
          ch |= 1 << (4 - bit)
          lonMin = mid
        } else {
          lonMax = mid
        }
      } else {
        const mid = (latMin + latMax) / 2
        if (latitude >= mid) {
          ch |= 1 << (4 - bit)
          latMin = mid
        } else {
          latMax = mid
        }
      }
      even = !even
      if (bit < 4) {
        bit++
      } else {
        hash += base32[ch]
        bit = 0
        ch = 0
      }
    }
    return hash
  }

  type GeoJsonGeometry = { type: string; coordinates: any }

  function ringContains(ring: number[][], lat: number, lon: number): boolean {
    // ring: [[lon,lat], ...]
    let inside = false
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const xi = ring[i][0], yi = ring[i][1]
      const xj = ring[j][0], yj = ring[j][1]
      const denom = (yj - yi) === 0 ? 1e-12 : (yj - yi)
      const intersect = ((yi > lat) !== (yj > lat)) && (lon < ((xj - xi) * (lat - yi)) / denom + xi)
      if (intersect) inside = !inside
    }
    return inside
  }

  function polygonContains(rings: number[][][], lat: number, lon: number): boolean {
    if (!rings || rings.length === 0) return false
    if (!ringContains(rings[0], lat, lon)) return false
    for (let i = 1; i < rings.length; i++) {
      if (ringContains(rings[i], lat, lon)) return false
    }
    return true
  }

  function geometryContains(geom: GeoJsonGeometry, lat: number, lon: number): boolean {
    if (!geom || typeof geom.type !== 'string') return false
    if (geom.type === 'Polygon') {
      return polygonContains(geom.coordinates as number[][][], lat, lon)
    }
    if (geom.type === 'MultiPolygon') {
      const polys = geom.coordinates as number[][][][]
      for (const rings of polys) {
        if (polygonContains(rings, lat, lon)) return true
      }
      return false
    }
    return false
  }

  function geometryBbox(geom: GeoJsonGeometry): { minLat: number; maxLat: number; minLon: number; maxLon: number } | null {
    const push = (pt: number[]) => {
      const lon = pt[0], lat = pt[1]
      minLat = Math.min(minLat, lat)
      maxLat = Math.max(maxLat, lat)
      minLon = Math.min(minLon, lon)
      maxLon = Math.max(maxLon, lon)
    }

    let minLat = Number.POSITIVE_INFINITY
    let maxLat = Number.NEGATIVE_INFINITY
    let minLon = Number.POSITIVE_INFINITY
    let maxLon = Number.NEGATIVE_INFINITY

    const walkRing = (ring: number[][]) => {
      for (const pt of ring) push(pt)
    }

    if (!geom || !geom.coordinates) return null

    if (geom.type === 'Polygon') {
      for (const ring of geom.coordinates as number[][][]) walkRing(ring)
    } else if (geom.type === 'MultiPolygon') {
      for (const poly of geom.coordinates as number[][][][]) {
        for (const ring of poly) walkRing(ring)
      }
    } else {
      return null
    }

    if (!isFinite(minLat) || !isFinite(minLon) || !isFinite(maxLat) || !isFinite(maxLon)) return null
    return { minLat, maxLat, minLon, maxLon }
  }

  async function getPolicy(policyKey: string): Promise<any> {
    const { data, error } = await supabase.rpc('atomic_timing_get_policy_v1', {
      p_policy_key: policyKey,
    })
    if (error) throw error
    return data ?? {}
  }

  async function policyEnabled(policyKey: string): Promise<{ enabled: boolean; payload: any }> {
    const payload = await getPolicy(policyKey)
    const enabled = payload?.enabled !== false
    return { enabled, payload }
  }

  async function runOutsideBuyerPrecompute() {
    const { data, error } = await supabase.rpc('outside_buyer_run_scheduled_precompute_v1_policy')
    if (error) throw error
    return data
  }

  async function runCityCodePopulation() {
    const { data, error } = await supabase.rpc('populate_city_geohash3_map_from_definitions')
    if (error) throw error
    return data
  }

  async function runGeoBoundaryAggregate(cityCode: string) {
    const { enabled, payload } = await policyEnabled('geo_boundary_aggregate_v1')
    if (!enabled) return { skipped: true }
    const daysBack = typeof payload?.days_back === 'number' ? payload.days_back : 30
    const threshold = typeof payload?.threshold === 'number' ? payload.threshold : 0.6
    const { data, error } = await supabase.rpc('geo_boundary_aggregate_v1', {
      p_city_code: cityCode,
      p_locality_code: null,
      p_days_back: daysBack,
    })
    if (error) throw error

    // Polygon rebuild step (best-effort): for each locality in the city,
    // attempt to derive a polygon from the current boundary field.
    const { data: localities, error: lErr } = await supabase.rpc('geo_list_city_localities_v1', {
      p_city_code: cityCode,
    })
    if (lErr) throw lErr

    const list = Array.isArray(localities) ? localities : []
    let rebuilt = 0
    for (const l of list as any[]) {
      const localityCode = (l.locality_code ?? '').toString()
      if (!localityCode) continue
      const { data: ok, error: rErr } = await supabase.rpc(
        'geo_rebuild_locality_shape_from_boundary_field_v1',
        {
          p_city_code: cityCode,
          p_locality_code: localityCode,
          p_geohash_precision: 7,
          p_threshold: threshold,
          p_source: 'federated_v1',
        },
      )
      if (rErr) continue
      if (ok === true) rebuilt++
    }

    return { aggregated_rows: data ?? 0, polygons_rebuilt: rebuilt }
  }

  async function runGeoVibeAggregate(cityCode: string) {
    const { enabled, payload } = await policyEnabled('geo_vibe_aggregate_v1')
    if (!enabled) return { skipped: true }

    const daysBack = typeof payload?.days_back === 'number' ? payload.days_back : 30
    const maxRows = typeof payload?.max_rows === 'number' ? payload.max_rows : 5000

    const sinceIso = new Date(Date.now() - Math.max(1, daysBack) * 24 * 60 * 60 * 1000).toISOString()
    const { data: rows, error } = await supabase
      .from('geo_federated_vibe_updates_v1')
      .select('geo_id,geo_level,signals,created_at')
      .eq('city_code', cityCode)
      .gte('created_at', sinceIso)
      .order('created_at', { ascending: false })
      .limit(maxRows)

    if (error) throw error
    if (!rows || rows.length === 0) return { upserted: 0, source_rows: 0 }

    type Agg = { geo_level: string; sum: number[]; wsum: number; samples: number }
    const agg: Record<string, Agg> = {}

    for (const r of rows as any[]) {
      const geoId = typeof r.geo_id === 'string' ? r.geo_id : ''
      const geoLevel = typeof r.geo_level === 'string' ? r.geo_level : ''
      const signals = Array.isArray(r.signals) ? r.signals : []
      if (!geoId || !geoLevel || signals.length === 0) continue
      if (!agg[geoId]) {
        agg[geoId] = { geo_level: geoLevel, sum: new Array(12).fill(0), wsum: 0, samples: 0 }
      }
      for (const s of signals) {
        const v = Array.isArray(s?.vibe_delta) ? s.vibe_delta : null
        const w = typeof s?.weight === 'number' ? s.weight : 1
        if (!v || v.length !== 12) continue
        const ww = Math.max(0, Math.min(5, w))
        for (let i = 0; i < 12; i++) {
          const n = typeof v[i] === 'number' ? v[i] : 0
          agg[geoId].sum[i] += n * ww
        }
        agg[geoId].wsum += ww
        agg[geoId].samples += 1
      }
    }

    const upserts: any[] = []
    for (const [geoId, a] of Object.entries(agg)) {
      const base = a.wsum > 0 ? a.sum.map((x) => x / a.wsum) : new Array(12).fill(0)
      upserts.push({
        geo_id: geoId,
        geo_level: a.geo_level,
        schema_version: 1,
        base_vibe: base,
        time_modulations: {},
        confidence: { sample_count: a.samples, days_back },
        source: 'federated_v1',
        updated_at: new Date().toISOString(),
      })
    }

    if (upserts.length === 0) return { upserted: 0, source_rows: rows.length }

    const { error: upErr } = await supabase
      .from('geo_vibe_signatures_v1')
      .upsert(upserts, { onConflict: 'geo_id' })
    if (upErr) throw upErr
    return { upserted: upserts.length, source_rows: rows.length }
  }

  async function runGeoKnotBuild(cityCode: string) {
    const { enabled } = await policyEnabled('geo_knot_build_v1')
    if (!enabled) return { skipped: true }

    const { data: vibes, error } = await supabase
      .from('geo_vibe_signatures_v1')
      .select('geo_id,geo_level,base_vibe,updated_at')
      .like('geo_id', `${cityCode}%`)
      .limit(5000)

    if (error) throw error
    if (!vibes || vibes.length === 0) return { upserted: 0 }

    async function sha256Hex(input: string): Promise<string> {
      const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input))
      return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('')
    }

    const upserts: any[] = []
    for (const v of vibes as any[]) {
      const geoId = v.geo_id
      const geoLevel = v.geo_level
      const base = Array.isArray(v.base_vibe) ? v.base_vibe : []
      const hash = await sha256Hex(JSON.stringify(base))
      upserts.push({
        geo_id: geoId,
        geo_level: geoLevel,
        schema_version: 1,
        knot_invariants: { vibe_hash: hash, method: 'placeholder_v1' },
        knot_metadata: { builder: 'atomic-timing-orchestrator', version: 1 },
        updated_at: new Date().toISOString(),
      })
    }

    const { error: upErr } = await supabase
      .from('geo_knot_signatures_v1')
      .upsert(upserts, { onConflict: 'geo_id' })
    if (upErr) throw upErr
    return { upserted: upserts.length }
  }

  async function runGeoSyncoBuild(cityCode: string) {
    const { enabled, payload } = await policyEnabled('geo_synco_summaries_build_v1')
    if (!enabled) return { skipped: true }

    const minSample = typeof payload?.min_sample_count === 'number' ? payload.min_sample_count : 50

    // Deterministic, safe v1 summaries (LLM hook can replace later).
    const { data: localities, error } = await supabase
      .rpc('geo_list_city_localities_v1', { p_city_code: cityCode })
    if (error) throw error
    const list = Array.isArray(localities) ? localities : []

    const upserts: any[] = []
    for (const l of list as any[]) {
      const geoId = (l.locality_code ?? '').toString()
      const display = (l.display_name ?? '').toString()
      if (!geoId) continue

      const summaryJson = {
        one_liner: display ? `${display}: signals are still forming.` : 'Signals are still forming.',
        good_for: [],
        not_great_for: [],
        timing_notes: [],
        reasons: [
          {
            signal_source: 'aggregate_v1',
            weight: 0.5,
            confidence: 0.2,
          },
        ],
        confidence: 0.2,
        sample_count_bucket: 'low',
        min_sample_count_required: minSample,
      }

      upserts.push({
        geo_id: geoId,
        geo_level: 'locality',
        schema_version: 1,
        audience: 'general_synco',
        summary_json: summaryJson,
        summary_text: null,
        llm_metadata: { mode: 'deterministic_v1' },
        updated_at: new Date().toISOString(),
      })
    }

    if (upserts.length === 0) return { upserted: 0 }

    const { error: upErr } = await supabase
      .from('geo_synco_summaries_v1')
      .upsert(upserts, { onConflict: 'geo_id,audience' })
    if (upErr) throw upErr
    return { upserted: upserts.length }
  }

  async function runGeoCityPackBuild(cityCode: string) {
    const { enabled, payload } = await policyEnabled('geo_city_pack_build_v1')
    if (!enabled) return { skipped: true }

    const simplify = typeof payload?.simplify_tolerance === 'number' ? payload.simplify_tolerance : 0.01
    const includeVibes = payload?.include_vibes !== false
    const includeKnots = payload?.include_knots !== false
    const includeSummaries = payload?.include_summaries !== false

    // Determine next pack version.
    const { data: existing, error: mErr } = await supabase
      .from('geo_city_pack_manifest_v1')
      .select('latest_pack_version')
      .eq('city_code', cityCode)
      .limit(1)
      .maybeSingle()
    if (mErr) throw mErr
    const nextVersion = (existing?.latest_pack_version ?? 0) + 1

    const { data: localities, error: lErr } = await supabase
      .rpc('geo_list_city_localities_v1', { p_city_code: cityCode })
    if (lErr) throw lErr

    const list = Array.isArray(localities) ? localities : []
    const features: any[] = []
    const localityCodes: string[] = []
    for (const l of list as any[]) {
      const localityCode = (l.locality_code ?? '').toString()
      if (!localityCode) continue
      localityCodes.push(localityCode)

      const displayName = (l.display_name ?? '').toString()
      const isNeighborhood = !!l.is_neighborhood

      const { data: geojson, error: gErr } = await supabase.rpc('geo_get_locality_shape_geojson_v1', {
        p_locality_code: localityCode,
        p_simplify_tolerance: simplify,
      })
      if (gErr || !geojson) continue

      features.push({
        type: 'Feature',
        properties: {
          locality_code: localityCode,
          display_name: displayName,
          is_neighborhood: isNeighborhood,
        },
        geometry: geojson,
      })
    }

    const localitiesGeoJson = {
      type: 'FeatureCollection',
      features,
    }

    // Build offline acceleration index:
    // geohash_prefix -> candidate locality_codes
    // This is intentionally conservative: it only narrows candidates; final truth is point-in-polygon on device.
    const indexPrecision = 6
    const stepLat = 0.004
    const stepLon = 0.004
    const maxSamplesPerLocality = 12000
    const indexMap: Record<string, string[]> = {}

    for (const f of features as any[]) {
      const localityCode = (f?.properties?.locality_code ?? '').toString()
      const geom = f?.geometry as GeoJsonGeometry
      if (!localityCode || !geom) continue

      const bbox = geometryBbox(geom)
      if (!bbox) continue

      let samples = 0
      for (let lat = bbox.minLat; lat <= bbox.maxLat; lat += stepLat) {
        for (let lon = bbox.minLon; lon <= bbox.maxLon; lon += stepLon) {
          if (!geometryContains(geom, lat, lon)) continue
          const gh = encodeGeohash(lat, lon, indexPrecision)
          const arr = indexMap[gh] ?? (indexMap[gh] = [])
          if (!arr.includes(localityCode)) arr.push(localityCode)
          samples++
          if (samples >= maxSamplesPerLocality) break
        }
        if (samples >= maxSamplesPerLocality) break
      }

      // Fallback: ensure at least one entry exists (centroid-ish).
      if (samples === 0) {
        const midLat = (bbox.minLat + bbox.maxLat) / 2
        const midLon = (bbox.minLon + bbox.maxLon) / 2
        const gh = encodeGeohash(midLat, midLon, indexPrecision)
        const arr = indexMap[gh] ?? (indexMap[gh] = [])
        if (!arr.includes(localityCode)) arr.push(localityCode)
      }
    }

    const indexJson = indexMap

    const vibesJson: Record<string, unknown> = {}
    if (includeVibes && localityCodes.length > 0) {
      const { data: vibes } = await supabase
        .from('geo_vibe_signatures_v1')
        .select('geo_id,geo_level,base_vibe,time_modulations,confidence,source,updated_at')
        .in('geo_id', localityCodes)
      if (Array.isArray(vibes)) {
        for (const v of vibes as any[]) {
          vibesJson[v.geo_id] = v
        }
      }
    }

    const knotsJson: Record<string, unknown> = {}
    if (includeKnots && localityCodes.length > 0) {
      const { data: knots } = await supabase
        .from('geo_knot_signatures_v1')
        .select('geo_id,geo_level,knot_invariants,knot_metadata,updated_at')
        .in('geo_id', localityCodes)
      if (Array.isArray(knots)) {
        for (const k of knots as any[]) {
          knotsJson[k.geo_id] = k
        }
      }
    }

    const summariesJson: Record<string, unknown> = {}
    if (includeSummaries && localityCodes.length > 0) {
      const { data: synco } = await supabase
        .from('geo_synco_summaries_v1')
        .select('geo_id,audience,summary_json,updated_at')
        .in('geo_id', localityCodes)
        .eq('audience', 'general_synco')
      if (Array.isArray(synco)) {
        for (const s of synco as any[]) {
          summariesJson[s.geo_id] = { general_synco: s.summary_json, updated_at: s.updated_at }
        }
      }
    }

    const metadata = {
      city_code: cityCode,
      pack_version: nextVersion,
      built_at: new Date().toISOString(),
      source: 'atomic-timing-orchestrator',
      index_precision: indexPrecision,
      index_step_lat: stepLat,
      index_step_lon: stepLon,
    }

    const zip = new JSZip()
    zip.file('metadata.json', JSON.stringify(metadata))
    zip.file('localities.geojson', JSON.stringify(localitiesGeoJson))
    zip.file('index.json', JSON.stringify(indexJson))
    zip.file('vibes.json', JSON.stringify(vibesJson))
    zip.file('knots.json', JSON.stringify(knotsJson))
    zip.file('summaries.json', JSON.stringify(summariesJson))

    const zipBytes = await zip.generateAsync({ type: 'uint8array', compression: 'DEFLATE' })
    const shaDigest = await crypto.subtle.digest('SHA-256', zipBytes)
    const shaHex = [...new Uint8Array(shaDigest)].map((b) => b.toString(16).padStart(2, '0')).join('')

    const objectPath = `${cityCode}/v${nextVersion}.zip`
    const { error: upErr } = await supabase.storage
      .from('geo-packs')
      .upload(objectPath, new Blob([zipBytes]), {
        contentType: 'application/zip',
        upsert: true,
      })
    if (upErr) throw upErr

    const { error: manErr } = await supabase.from('geo_city_pack_manifest_v1').upsert(
      {
        city_code: cityCode,
        latest_pack_version: nextVersion,
        storage_path: `geo-packs/${objectPath}`,
        sha256: shaHex,
        size_bytes: zipBytes.length,
      },
      { onConflict: 'city_code' },
    )
    if (manErr) throw manErr

    return { city_code: cityCode, pack_version: nextVersion, sha256: shaHex, size_bytes: zipBytes.length }
  }

  try {
    if (target === 'all' || target === 'outside_buyer_precompute') {
      results.outside_buyer_precompute = await runOutsideBuyerPrecompute()
    }
    if (target === 'all' || target === 'city_code_population') {
      results.city_code_population = await runCityCodePopulation()
    }

    const cityCode = cityCodeParam || 'us-nyc'

    // Geo pipeline (dependency order).
    if (target === 'all' || target === 'geo_boundary_aggregate') {
      results.geo_boundary_aggregate = await runGeoBoundaryAggregate(cityCode)
    }
    if (target === 'all' || target === 'geo_vibe_aggregate') {
      results.geo_vibe_aggregate = await runGeoVibeAggregate(cityCode)
    }
    if (target === 'all' || target === 'geo_knot_build') {
      results.geo_knot_build = await runGeoKnotBuild(cityCode)
    }
    if (target === 'all' || target === 'geo_synco_build') {
      results.geo_synco_build = await runGeoSyncoBuild(cityCode)
    }
    if (target === 'all' || target === 'geo_city_pack_build') {
      results.geo_city_pack_build = await runGeoCityPackBuild(cityCode)
    }

    // Best-effort audit log
    try {
      await supabase.from('audit_logs').insert({
        type: 'atomic_timing_orchestrator',
        action: 'run',
        status: 'success',
        metadata: {
          target,
          city_code: cityCodeParam || null,
          duration_ms: Date.now() - started,
          results,
        },
      })
    } catch (_) {
      // ignore audit failure
    }

    return new Response(JSON.stringify({ ok: true, target, results }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    // Best-effort audit log
    try {
      await supabase.from('audit_logs').insert({
        type: 'atomic_timing_orchestrator',
        action: 'run',
        status: 'error',
        metadata: {
          target,
          duration_ms: Date.now() - started,
          error: String(e?.message ?? e),
        },
      })
    } catch (_) {
      // ignore audit failure
    }

    return new Response(JSON.stringify({ ok: false, error: 'RUN_FAILED', detail: String(e?.message ?? e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

