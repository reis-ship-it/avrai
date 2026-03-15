use chrono::Utc;
use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::collections::{BTreeMap, HashMap};
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};

static USER_STATE: OnceLock<Mutex<HashMap<String, VibeStateSnapshot>>> = OnceLock::new();
static ENTITY_STATE: OnceLock<Mutex<HashMap<String, EntityVibeSnapshot>>> = OnceLock::new();

#[derive(Debug, Deserialize)]
struct NativeRequest {
    syscall: String,
    payload: Map<String, Value>,
}

#[derive(Debug, Serialize)]
struct NativeResponse {
    ok: bool,
    handled: bool,
    payload: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeSubjectRef {
    subject_id: String,
    kind: String,
    #[serde(default)]
    geographic_level: Option<String>,
    #[serde(default)]
    scoped_kind: Option<String>,
    #[serde(default)]
    entity_type: Option<String>,
    #[serde(default)]
    display_label: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeSignal {
    key: String,
    kind: String,
    value: f64,
    confidence: f64,
    #[serde(default)]
    provenance: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeEvidence {
    summary: String,
    #[serde(default)]
    identity_signals: Vec<VibeSignal>,
    #[serde(default)]
    pheromone_signals: Vec<VibeSignal>,
    #[serde(default)]
    behavior_signals: Vec<VibeSignal>,
    #[serde(default)]
    affective_signals: Vec<VibeSignal>,
    #[serde(default)]
    style_signals: Vec<VibeSignal>,
    #[serde(default = "schema_version")]
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeMutationDecision {
    #[serde(default)]
    state_write_allowed: bool,
    #[serde(default)]
    dna_write_allowed: bool,
    #[serde(default)]
    pheromone_write_allowed: bool,
    #[serde(default)]
    behavior_write_allowed: bool,
    #[serde(default)]
    affective_write_allowed: bool,
    #[serde(default)]
    style_write_allowed: bool,
    #[serde(default)]
    reason_codes: Vec<String>,
    #[serde(default = "default_governance_scope")]
    governance_scope: String,
    #[serde(default)]
    air_gap_envelope_required: bool,
    #[serde(default = "schema_version")]
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct CoreDnaState {
    dimensions: BTreeMap<String, f64>,
    dimension_confidence: BTreeMap<String, f64>,
    drift_budget_remaining: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct QuantumVibeState {
    amplitudes: BTreeMap<String, f64>,
    phase_alignment: f64,
    coherence: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct PheromoneState {
    vectors: BTreeMap<String, f64>,
    decay_rate: f64,
    last_decay_at_utc: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct BehaviorPatternState {
    pattern_weights: BTreeMap<String, f64>,
    observation_count: u32,
    cadence_hours: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct AffectiveState {
    valence: f64,
    arousal: f64,
    dominance: f64,
    label: String,
    confidence: f64,
    expires_at_utc: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct KnotInvariantState {
    crossing_number: f64,
    tension: f64,
    symmetry: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct WorldsheetState {
    temporal_phase: f64,
    momentum: f64,
    curvature: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct StringEvolutionState {
    coupling: f64,
    mutation_velocity: f64,
    harmonics: BTreeMap<String, f64>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct DecoherenceState {
    noise: f64,
    stability: f64,
    decoherence: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeExpressionContext {
    tone_profile: String,
    pacing_profile: String,
    uncertainty_profile: String,
    social_cadence: f64,
    energy: f64,
    directness: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeStateSnapshot {
    subject_id: String,
    subject_kind: String,
    core_dna: CoreDnaState,
    quantum_vibe: QuantumVibeState,
    pheromones: PheromoneState,
    behavior_patterns: BehaviorPatternState,
    affective_state: AffectiveState,
    knot_invariants: KnotInvariantState,
    worldsheet: WorldsheetState,
    string_evolution: StringEvolutionState,
    decoherence_state: DecoherenceState,
    expression_context: VibeExpressionContext,
    confidence: f64,
    freshness_hours: f64,
    provenance_tags: Vec<String>,
    updated_at_utc: String,
    #[serde(default = "schema_version")]
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct EntityVibeSnapshot {
    entity_id: String,
    entity_type: String,
    vibe: VibeStateSnapshot,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeSnapshotEnvelope {
    exported_at_utc: String,
    #[serde(default)]
    subject_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    entity_snapshots: Vec<EntityVibeSnapshot>,
    #[serde(default)]
    migration_receipts: Vec<String>,
    #[serde(default)]
    metadata: BTreeMap<String, Value>,
    #[serde(default = "schema_version")]
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct GeographicVibeBinding {
    locality_ref: VibeSubjectRef,
    stable_key: String,
    #[serde(default)]
    higher_geographic_refs: Vec<VibeSubjectRef>,
    #[serde(default)]
    higher_agent_refs: Vec<VibeSubjectRef>,
    #[serde(default = "default_locality_scope")]
    scope: String,
    #[serde(default)]
    district_code: Option<String>,
    #[serde(default)]
    city_code: Option<String>,
    #[serde(default)]
    region_code: Option<String>,
    #[serde(default)]
    country_code: Option<String>,
    #[serde(default)]
    global_code: Option<String>,
    #[serde(default)]
    top_level_code: Option<String>,
    #[serde(default)]
    metadata: BTreeMap<String, Value>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct LocalityVibeBinding {
    locality_ref: VibeSubjectRef,
    stable_key: String,
    #[serde(default)]
    higher_agent_refs: Vec<VibeSubjectRef>,
    #[serde(default = "default_locality_scope")]
    scope: String,
    #[serde(default)]
    city_code: Option<String>,
    #[serde(default)]
    region_code: Option<String>,
    #[serde(default)]
    top_level_code: Option<String>,
    #[serde(default)]
    metadata: BTreeMap<String, Value>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct ScopedVibeBinding {
    context_ref: VibeSubjectRef,
    scoped_kind: String,
    #[serde(default)]
    anchor_geographic_ref: Option<VibeSubjectRef>,
    #[serde(default)]
    metadata: BTreeMap<String, Value>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct HierarchicalVibeStack {
    primary_snapshot: VibeStateSnapshot,
    #[serde(default)]
    geographic_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    scoped_context_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    geographic_binding: Option<GeographicVibeBinding>,
    #[serde(default)]
    scoped_bindings: Vec<ScopedVibeBinding>,
    #[serde(default)]
    active_locality_snapshot: Option<VibeStateSnapshot>,
    #[serde(default)]
    higher_agent_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    selected_entity_snapshots: Vec<EntityVibeSnapshot>,
    #[serde(default)]
    locality_binding: Option<LocalityVibeBinding>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeUpdateReceipt {
    subject_id: String,
    accepted: bool,
    reason_codes: Vec<String>,
    updated_at_utc: String,
    snapshot: VibeStateSnapshot,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct StateEncoderInputSnapshot {
    user_snapshot: VibeStateSnapshot,
    #[serde(default)]
    entity_snapshot: Option<EntityVibeSnapshot>,
    #[serde(default)]
    geographic_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    scoped_context_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    geographic_binding: Option<GeographicVibeBinding>,
    #[serde(default)]
    scoped_bindings: Vec<ScopedVibeBinding>,
    #[serde(default)]
    active_locality_snapshot: Option<VibeStateSnapshot>,
    #[serde(default)]
    higher_agent_snapshots: Vec<VibeStateSnapshot>,
    #[serde(default)]
    selected_entity_snapshots: Vec<EntityVibeSnapshot>,
    #[serde(default)]
    hierarchical_stack: Option<HierarchicalVibeStack>,
    metadata: BTreeMap<String, Value>,
}

#[no_mangle]
pub extern "C" fn avrai_vibe_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
    let response = match parse_request(request_ptr).and_then(handle_request) {
        Ok(response) => response,
        Err(error) => NativeResponse {
            ok: false,
            handled: false,
            payload: Value::Null,
            error: Some(error),
        },
    };
    into_c_string(response)
}

#[no_mangle]
pub extern "C" fn avrai_vibe_kernel_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

fn parse_request(request_ptr: *const c_char) -> Result<NativeRequest, String> {
    if request_ptr.is_null() {
        return Err("request pointer was null".to_string());
    }
    let request_json = unsafe { CStr::from_ptr(request_ptr) }
        .to_str()
        .map_err(|error| format!("request utf8 decode failed: {error}"))?;
    serde_json::from_str::<NativeRequest>(request_json)
        .map_err(|error| format!("request json decode failed: {error}"))
}

fn handle_request(request: NativeRequest) -> Result<NativeResponse, String> {
    let payload = match request.syscall.as_str() {
        "seed_user_state_from_onboarding" => {
            serde_json::to_value(seed_user_state_from_onboarding(&request.payload)?)
        }
        "ingest_language_evidence" => {
            serde_json::to_value(ingest_language_evidence(&request.payload)?)
        }
        "ingest_behavior_observation" => {
            serde_json::to_value(ingest_behavior_observation(&request.payload)?)
        }
        "ingest_ecosystem_observation" => {
            serde_json::to_value(ingest_ecosystem_observation(&request.payload)?)
        }
        "ingest_entity_observation" => {
            serde_json::to_value(ingest_entity_observation(&request.payload)?)
        }
        "record_outcome" => serde_json::to_value(record_outcome(&request.payload)?),
        "advance_decay_window" => {
            serde_json::to_value(advance_decay_window(&request.payload)?)
        }
        "get_user_snapshot" => serde_json::to_value(get_user_snapshot(&request.payload)?),
        "get_entity_snapshot" => serde_json::to_value(get_entity_snapshot(&request.payload)?),
        "get_state_encoder_snapshot" => {
            serde_json::to_value(get_state_encoder_snapshot(&request.payload)?)
        }
        "get_hierarchical_stack" => {
            serde_json::to_value(get_hierarchical_stack(&request.payload)?)
        }
        "get_expression_context" => {
            serde_json::to_value(get_expression_context(&request.payload)?)
        }
        "export_snapshot_envelope" => {
            serde_json::to_value(export_snapshot_envelope())
        }
        "import_snapshot_envelope" => {
            serde_json::to_value(import_snapshot_envelope(&request.payload)?)
        }
        "diagnostics" => Ok(diagnostics()),
        _ => {
            return Ok(NativeResponse {
                ok: true,
                handled: false,
                payload: Value::Null,
                error: None,
            })
        }
    }
    .map_err(|error| format!("vibe payload encode failed: {error}"))?;

    Ok(NativeResponse {
        ok: true,
        handled: true,
        payload,
        error: None,
    })
}

fn seed_user_state_from_onboarding(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let dimensions = numeric_map(payload.get("dimensions"));
    let dimension_confidence = numeric_map(payload.get("dimension_confidence"));
    let provenance_tags = string_list(payload.get("provenance_tags"));
    let mut snapshot = default_snapshot(&subject_id, &subject_kind);
    for (key, value) in dimensions {
        snapshot.core_dna.dimensions.insert(key, value);
    }
    for (key, value) in dimension_confidence {
        snapshot.core_dna.dimension_confidence.insert(key, value);
    }
    snapshot.provenance_tags.extend(provenance_tags);
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["seeded_from_onboarding".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn ingest_language_evidence(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let evidence: VibeEvidence = deserialize_or_default(
        payload.get("evidence").cloned(),
        json!({
            "summary": "",
            "identity_signals": [],
            "pheromone_signals": [],
            "behavior_signals": [],
            "affective_signals": [],
            "style_signals": [],
        }),
    )?;
    let decision: VibeMutationDecision = deserialize_or_default(
        payload.get("mutation_decision").cloned(),
        json!({
            "state_write_allowed": false,
            "dna_write_allowed": false,
            "pheromone_write_allowed": false,
            "behavior_write_allowed": false,
            "affective_write_allowed": false,
            "style_write_allowed": false,
            "reason_codes": [],
        }),
    )?;
    let mut snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    if !decision.state_write_allowed {
        recompute_snapshot(&mut snapshot);
        return Ok(VibeUpdateReceipt {
            subject_id,
            accepted: false,
            reason_codes: {
                let mut reasons = decision.reason_codes.clone();
                reasons.push("state_write_denied".to_string());
                reasons
            },
            updated_at_utc: snapshot.updated_at_utc.clone(),
            snapshot,
        });
    }

    if decision.dna_write_allowed {
        for signal in &evidence.identity_signals {
            blend_dimension(
                &mut snapshot.core_dna.dimensions,
                &mut snapshot.core_dna.dimension_confidence,
                &signal.key,
                signal.value,
                0.04 * signal.confidence.max(0.15),
            );
        }
    }
    if decision.pheromone_write_allowed {
        for signal in &evidence.pheromone_signals {
            blend_fast(
                &mut snapshot.pheromones.vectors,
                &signal.key,
                signal.value,
                0.24 * signal.confidence.max(0.2),
            );
        }
    }
    if decision.behavior_write_allowed {
        for signal in &evidence.behavior_signals {
            blend_fast(
                &mut snapshot.behavior_patterns.pattern_weights,
                &signal.key,
                signal.value,
                0.16 * signal.confidence.max(0.2),
            );
            snapshot.behavior_patterns.observation_count += 1;
        }
    }
    if decision.affective_write_allowed {
        update_affective_state(&mut snapshot.affective_state, &evidence.affective_signals);
    }
    if decision.style_write_allowed {
        for signal in &evidence.style_signals {
            blend_fast(
                &mut snapshot.behavior_patterns.pattern_weights,
                &format!("style:{}", signal.key),
                signal.value,
                0.12 * signal.confidence.max(0.2),
            );
        }
    }
    snapshot
        .provenance_tags
        .extend(string_list(payload.get("provenance_tags")));
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["language_evidence_applied".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn ingest_behavior_observation(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let behavior_signals = numeric_map(payload.get("behavior_signals"));
    let mut snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    for (key, value) in behavior_signals {
        blend_fast(
            &mut snapshot.behavior_patterns.pattern_weights,
            &key,
            value,
            0.22,
        );
        blend_fast(&mut snapshot.pheromones.vectors, &key, value, 0.1);
        snapshot.behavior_patterns.observation_count += 1;
    }
    snapshot
        .provenance_tags
        .extend(string_list(payload.get("provenance_tags")));
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["behavior_observation_applied".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn ingest_ecosystem_observation(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let mut snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    let dimensions = numeric_map(payload.get("dimensions"));
    for (key, value) in dimensions {
        blend_dimension(
            &mut snapshot.core_dna.dimensions,
            &mut snapshot.core_dna.dimension_confidence,
            &key,
            value,
            0.08,
        );
    }
    let source = string_field(payload, "source", "ecosystem");
    snapshot.provenance_tags.push(format!("ecosystem:{source}"));
    snapshot
        .provenance_tags
        .extend(string_list(payload.get("provenance_tags")));
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["ecosystem_observation_applied".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn ingest_entity_observation(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let entity_id = string_field(payload, "entity_id", "unknown_entity");
    let entity_type = string_field(payload, "entity_type", "entity");
    let dimensions = numeric_map(payload.get("dimensions"));
    let mut vibe = default_snapshot(&entity_id, "entity");
    vibe.core_dna.dimensions = dimensions;
    vibe.provenance_tags = {
        let mut tags = string_list(payload.get("provenance_tags"));
        tags.push(format!("entity_type:{entity_type}"));
        tags
    };
    recompute_snapshot(&mut vibe);
    let entity_snapshot = EntityVibeSnapshot {
        entity_id: entity_id.clone(),
        entity_type: entity_type.clone(),
        vibe: vibe.clone(),
    };
    put_entity_snapshot(entity_snapshot);
    Ok(VibeUpdateReceipt {
        subject_id: entity_id,
        accepted: true,
        reason_codes: vec!["entity_observation_applied".to_string()],
        updated_at_utc: vibe.updated_at_utc.clone(),
        snapshot: vibe,
    })
}

fn record_outcome(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let outcome = string_field(payload, "outcome", "unknown");
    let outcome_score = payload
        .get("outcome_score")
        .and_then(Value::as_f64)
        .unwrap_or(0.5);
    let mut snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    blend_fast(
        &mut snapshot.behavior_patterns.pattern_weights,
        &format!("outcome:{outcome}"),
        outcome_score,
        0.18,
    );
    blend_fast(
        &mut snapshot.pheromones.vectors,
        &format!("outcome:{outcome}"),
        outcome_score,
        0.14,
    );
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["outcome_recorded".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn advance_decay_window(payload: &Map<String, Value>) -> Result<VibeUpdateReceipt, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let elapsed_hours = payload
        .get("elapsed_hours")
        .and_then(Value::as_f64)
        .unwrap_or(24.0)
        .max(0.0);
    let mut snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    let decay_multiplier = (1.0 - snapshot.pheromones.decay_rate).powf(elapsed_hours / 24.0);
    for value in snapshot.pheromones.vectors.values_mut() {
        *value = clamp_unit((*value) * decay_multiplier);
    }
    snapshot.pheromones.last_decay_at_utc = now_iso();
    snapshot.freshness_hours += elapsed_hours;
    recompute_snapshot(&mut snapshot);
    put_user_snapshot(snapshot.clone());
    Ok(VibeUpdateReceipt {
        subject_id,
        accepted: true,
        reason_codes: vec!["decay_window_advanced".to_string()],
        updated_at_utc: snapshot.updated_at_utc.clone(),
        snapshot,
    })
}

fn get_user_snapshot(payload: &Map<String, Value>) -> Result<VibeStateSnapshot, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    Ok(take_or_default_user_snapshot(&subject_id, &subject_kind))
}

fn get_entity_snapshot(payload: &Map<String, Value>) -> Result<EntityVibeSnapshot, String> {
    let entity_id = string_field(payload, "entity_id", "unknown_entity");
    let entity_type = string_field(payload, "entity_type", "entity");
    Ok(take_or_default_entity_snapshot(&entity_id, &entity_type))
}

fn get_state_encoder_snapshot(payload: &Map<String, Value>) -> Result<StateEncoderInputSnapshot, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    let entity_id = payload.get("entity_id").and_then(Value::as_str);
    let entity_type = payload.get("entity_type").and_then(Value::as_str).unwrap_or("entity");
    let user_snapshot = take_or_default_user_snapshot(&subject_id, &subject_kind);
    let entity_snapshot = entity_id.map(|id| take_or_default_entity_snapshot(id, entity_type));
    let selected_entity_snapshots = resolve_selected_entity_snapshots(payload, entity_snapshot.clone());
    let geographic_binding = geographic_binding_from_payload(payload)?;
    let scoped_bindings: Vec<ScopedVibeBinding> = ((payload.get("scoped_bindings").cloned()).unwrap_or(Value::Array(vec![])))
        .as_array()
        .cloned()
        .unwrap_or_default()
        .into_iter()
        .filter_map(|entry| serde_json::from_value(entry).ok())
        .collect();
    let active_locality_snapshot = geographic_binding
        .as_ref()
        .map(|binding: &GeographicVibeBinding| {
            take_or_default_user_snapshot(
                &binding.locality_ref.subject_id,
                &binding.locality_ref.kind,
            )
        });
    let higher_agent_snapshots =
        resolve_higher_agent_snapshots(payload, geographic_binding.as_ref());
    let geographic_snapshots = {
        let mut snapshots = Vec::new();
        if let Some(active) = active_locality_snapshot.clone() {
            snapshots.push(active);
        }
        snapshots.extend(higher_agent_snapshots.clone());
        snapshots
    };
    let scoped_context_snapshots = scoped_bindings
        .iter()
        .map(|binding| take_or_default_user_snapshot(&binding.context_ref.subject_id, &binding.context_ref.kind))
        .collect::<Vec<_>>();
    let hierarchical_stack = Some(HierarchicalVibeStack {
        primary_snapshot: user_snapshot.clone(),
        geographic_snapshots: geographic_snapshots.clone(),
        scoped_context_snapshots: scoped_context_snapshots.clone(),
        geographic_binding: geographic_binding.clone(),
        scoped_bindings: scoped_bindings.clone(),
        active_locality_snapshot: active_locality_snapshot.clone(),
        higher_agent_snapshots: higher_agent_snapshots.clone(),
        selected_entity_snapshots: selected_entity_snapshots.clone(),
        locality_binding: geographic_binding.as_ref().map(legacy_locality_binding_from_geographic),
    });
    Ok(StateEncoderInputSnapshot {
        user_snapshot,
        entity_snapshot,
        geographic_snapshots,
        scoped_context_snapshots,
        geographic_binding,
        scoped_bindings,
        active_locality_snapshot,
        higher_agent_snapshots,
        selected_entity_snapshots,
        hierarchical_stack,
        metadata: BTreeMap::from([
            ("kernel".to_string(), Value::String("vibe".to_string())),
            ("mode".to_string(), Value::String("canonical".to_string())),
        ]),
    })
}

fn get_hierarchical_stack(payload: &Map<String, Value>) -> Result<HierarchicalVibeStack, String> {
    let subject_ref: VibeSubjectRef = deserialize_or_default(
        payload.get("subject_ref").cloned(),
        json!({
            "subject_id": "unknown_subject",
            "kind": "personal_agent",
        }),
    )?;
    let geographic_binding = geographic_binding_from_payload(payload)?;
    let scoped_bindings: Vec<ScopedVibeBinding> = ((payload.get("scoped_bindings").cloned()).unwrap_or(Value::Array(vec![])))
        .as_array()
        .cloned()
        .unwrap_or_default()
        .into_iter()
        .filter_map(|entry| serde_json::from_value(entry).ok())
        .collect();
    let primary_snapshot =
        take_or_default_user_snapshot(&subject_ref.subject_id, &subject_ref.kind);
    let active_locality_snapshot = geographic_binding
        .as_ref()
        .map(|binding: &GeographicVibeBinding| {
            take_or_default_user_snapshot(
                &binding.locality_ref.subject_id,
                &binding.locality_ref.kind,
            )
        });
    let higher_agent_snapshots =
        resolve_higher_agent_snapshots(payload, geographic_binding.as_ref());
    let selected_entity_snapshots = resolve_selected_entity_snapshots(payload, None);
    let geographic_snapshots = {
        let mut snapshots = Vec::new();
        if let Some(active) = active_locality_snapshot.clone() {
            snapshots.push(active);
        }
        snapshots.extend(higher_agent_snapshots.clone());
        snapshots
    };
    let scoped_context_snapshots = scoped_bindings
        .iter()
        .map(|binding| take_or_default_user_snapshot(&binding.context_ref.subject_id, &binding.context_ref.kind))
        .collect::<Vec<_>>();
    Ok(HierarchicalVibeStack {
        primary_snapshot,
        geographic_snapshots,
        scoped_context_snapshots,
        geographic_binding: geographic_binding.clone(),
        scoped_bindings: scoped_bindings.clone(),
        active_locality_snapshot,
        higher_agent_snapshots,
        selected_entity_snapshots,
        locality_binding: geographic_binding.as_ref().map(legacy_locality_binding_from_geographic),
    })
}

fn get_expression_context(payload: &Map<String, Value>) -> Result<VibeExpressionContext, String> {
    let subject_id = string_field(payload, "subject_id", "unknown_subject");
    let subject_kind = subject_kind_field(payload, "personal_agent");
    Ok(take_or_default_user_snapshot(&subject_id, &subject_kind).expression_context)
}

fn export_snapshot_envelope() -> VibeSnapshotEnvelope {
    let subject_snapshots = USER_STATE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("subject state lock")
        .values()
        .cloned()
        .collect::<Vec<_>>();
    let entity_snapshots = ENTITY_STATE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("entity state lock")
        .values()
        .cloned()
        .collect::<Vec<_>>();
    VibeSnapshotEnvelope {
        exported_at_utc: now_iso(),
        subject_snapshots,
        entity_snapshots,
        migration_receipts: vec!["native_snapshot_export".to_string()],
        metadata: BTreeMap::from([
            ("kernel".to_string(), Value::String("vibe".to_string())),
            ("mode".to_string(), Value::String("canonical".to_string())),
        ]),
        schema_version: schema_version(),
    }
}

fn import_snapshot_envelope(payload: &Map<String, Value>) -> Result<Value, String> {
    let envelope: VibeSnapshotEnvelope =
        deserialize_required(payload.get("envelope").cloned(), "missing envelope")?;
    {
        let mut subject_store = USER_STATE
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .expect("subject state lock");
        subject_store.clear();
        for snapshot in envelope.subject_snapshots.iter().cloned() {
            subject_store.insert(snapshot.subject_id.clone(), snapshot);
        }
    }
    {
        let mut entity_store = ENTITY_STATE
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .expect("entity state lock");
        entity_store.clear();
        for snapshot in envelope.entity_snapshots.iter().cloned() {
            entity_store.insert(snapshot.entity_id.clone(), snapshot);
        }
    }
    Ok(json!({
        "imported_subject_snapshots": envelope.subject_snapshots.len(),
        "imported_entity_snapshots": envelope.entity_snapshots.len(),
    }))
}

fn diagnostics() -> Value {
    let user_count = USER_STATE
        .get()
        .and_then(|store| store.lock().ok())
        .map(|store| store.len())
        .unwrap_or(0);
    let entity_count = ENTITY_STATE
        .get()
        .and_then(|store| store.lock().ok())
        .map(|store| store.len())
        .unwrap_or(0);
    json!({
        "status": "ok",
        "kernel": "vibe",
        "native_only": true,
        "schema_version": 1,
        "subject_state_count": user_count,
        "entity_state_count": entity_count,
        "math_stack": [
            "dna",
            "pheromones",
            "quantum_vibe",
            "behavior_patterns",
            "affective_state",
            "knot",
            "worldsheet",
            "string_evolution",
            "decoherence"
        ],
    })
}

fn take_or_default_user_snapshot(subject_id: &str, subject_kind: &str) -> VibeStateSnapshot {
    let store = USER_STATE.get_or_init(|| Mutex::new(HashMap::new()));
    let mut store = store.lock().expect("user state lock");
    store
        .entry(subject_id.to_string())
        .or_insert_with(|| default_snapshot(subject_id, subject_kind))
        .clone()
}

fn put_user_snapshot(snapshot: VibeStateSnapshot) {
    let store = USER_STATE.get_or_init(|| Mutex::new(HashMap::new()));
    store
        .lock()
        .expect("user state lock")
        .insert(snapshot.subject_id.clone(), snapshot);
}

fn take_or_default_entity_snapshot(entity_id: &str, entity_type: &str) -> EntityVibeSnapshot {
    let store = ENTITY_STATE.get_or_init(|| Mutex::new(HashMap::new()));
    let mut store = store.lock().expect("entity state lock");
    store
        .entry(entity_id.to_string())
        .or_insert_with(|| EntityVibeSnapshot {
            entity_id: entity_id.to_string(),
            entity_type: entity_type.to_string(),
            vibe: default_snapshot(entity_id, "entity"),
        })
        .clone()
}

fn put_entity_snapshot(snapshot: EntityVibeSnapshot) {
    let store = ENTITY_STATE.get_or_init(|| Mutex::new(HashMap::new()));
    store
        .lock()
        .expect("entity state lock")
        .insert(snapshot.entity_id.clone(), snapshot);
}

fn default_snapshot(subject_id: &str, subject_kind: &str) -> VibeStateSnapshot {
    let dimensions = BTreeMap::from([
        ("exploration_eagerness".to_string(), 0.5),
        ("community_orientation".to_string(), 0.5),
        ("authenticity_preference".to_string(), 0.5),
        ("social_discovery_style".to_string(), 0.5),
        ("temporal_flexibility".to_string(), 0.5),
        ("location_adventurousness".to_string(), 0.5),
        ("curation_tendency".to_string(), 0.5),
        ("trust_network_reliance".to_string(), 0.5),
        ("energy_preference".to_string(), 0.5),
        ("novelty_seeking".to_string(), 0.5),
        ("value_orientation".to_string(), 0.5),
        ("crowd_tolerance".to_string(), 0.5),
    ]);
    let confidence = dimensions
        .keys()
        .map(|key| (key.clone(), 0.0))
        .collect::<BTreeMap<_, _>>();
    let now = now_iso();
    let mut snapshot = VibeStateSnapshot {
        subject_id: subject_id.to_string(),
        subject_kind: subject_kind.to_string(),
        core_dna: CoreDnaState {
            dimensions,
            dimension_confidence: confidence,
            drift_budget_remaining: 0.3,
        },
        quantum_vibe: QuantumVibeState {
            amplitudes: BTreeMap::new(),
            phase_alignment: 0.0,
            coherence: 0.0,
        },
        pheromones: PheromoneState {
            vectors: BTreeMap::new(),
            decay_rate: 0.08,
            last_decay_at_utc: now.clone(),
        },
        behavior_patterns: BehaviorPatternState {
            pattern_weights: BTreeMap::new(),
            observation_count: 0,
            cadence_hours: 24.0,
        },
        affective_state: AffectiveState {
            valence: 0.0,
            arousal: 0.0,
            dominance: 0.0,
            label: "neutral".to_string(),
            confidence: 0.0,
            expires_at_utc: None,
        },
        knot_invariants: KnotInvariantState {
            crossing_number: 0.0,
            tension: 0.0,
            symmetry: 0.0,
        },
        worldsheet: WorldsheetState {
            temporal_phase: 0.0,
            momentum: 0.0,
            curvature: 0.0,
        },
        string_evolution: StringEvolutionState {
            coupling: 0.0,
            mutation_velocity: 0.0,
            harmonics: BTreeMap::new(),
        },
        decoherence_state: DecoherenceState {
            noise: 0.0,
            stability: 1.0,
            decoherence: 0.0,
        },
        expression_context: VibeExpressionContext {
            tone_profile: "clear_calm".to_string(),
            pacing_profile: "steady".to_string(),
            uncertainty_profile: "explicit".to_string(),
            social_cadence: 0.5,
            energy: 0.5,
            directness: 0.5,
        },
        confidence: 0.0,
        freshness_hours: 0.0,
        provenance_tags: vec!["kernel_seed".to_string()],
        updated_at_utc: now,
        schema_version: schema_version(),
    };
    recompute_snapshot(&mut snapshot);
    snapshot
}

fn geographic_binding_from_payload(
    payload: &Map<String, Value>,
) -> Result<Option<GeographicVibeBinding>, String> {
    if let Some(value) = payload.get("geographic_binding").cloned() {
        let mut binding: GeographicVibeBinding =
            deserialize_or_default(Some(value), Value::Null)?;
        if binding.higher_geographic_refs.is_empty() && !binding.higher_agent_refs.is_empty() {
            binding.higher_geographic_refs = binding.higher_agent_refs.clone();
        }
        if binding.global_code.is_none() {
            binding.global_code = binding.top_level_code.clone();
        }
        return Ok(Some(binding));
    }

    let legacy = payload
        .get("locality_binding")
        .cloned()
        .map(|value| deserialize_or_default(Some(value), Value::Null))
        .transpose()?;
    Ok(legacy.map(|binding: LocalityVibeBinding| GeographicVibeBinding {
        locality_ref: binding.locality_ref,
        stable_key: binding.stable_key,
        higher_geographic_refs: binding.higher_agent_refs.clone(),
        higher_agent_refs: binding.higher_agent_refs,
        scope: binding.scope,
        district_code: None,
        city_code: binding.city_code,
        region_code: binding.region_code,
        country_code: None,
        global_code: binding.top_level_code.clone(),
        top_level_code: binding.top_level_code,
        metadata: binding.metadata,
    }))
}

fn legacy_locality_binding_from_geographic(
    binding: &GeographicVibeBinding,
) -> LocalityVibeBinding {
    LocalityVibeBinding {
        locality_ref: binding.locality_ref.clone(),
        stable_key: binding.stable_key.clone(),
        higher_agent_refs: if !binding.higher_geographic_refs.is_empty() {
            binding.higher_geographic_refs.clone()
        } else {
            binding.higher_agent_refs.clone()
        },
        scope: binding.scope.clone(),
        city_code: binding.city_code.clone(),
        region_code: binding.region_code.clone(),
        top_level_code: binding
            .global_code
            .clone()
            .or_else(|| binding.top_level_code.clone()),
        metadata: binding.metadata.clone(),
    }
}

fn resolve_higher_agent_snapshots(
    payload: &Map<String, Value>,
    geographic_binding: Option<&GeographicVibeBinding>,
) -> Vec<VibeStateSnapshot> {
    let payload_refs = subject_ref_list(payload.get("higher_agent_refs"));
    let mut refs = geographic_binding
        .map(|binding| {
            if !binding.higher_geographic_refs.is_empty() {
                binding.higher_geographic_refs.clone()
            } else {
                binding.higher_agent_refs.clone()
            }
        })
        .unwrap_or_default();
    refs.extend(payload_refs);
    refs.into_iter()
        .map(|subject_ref| {
            take_or_default_user_snapshot(&subject_ref.subject_id, &subject_ref.kind)
        })
        .collect()
}

fn resolve_selected_entity_snapshots(
    payload: &Map<String, Value>,
    entity_snapshot: Option<EntityVibeSnapshot>,
) -> Vec<EntityVibeSnapshot> {
    let mut snapshots = subject_ref_list(payload.get("selected_entity_refs"))
        .into_iter()
        .filter(|subject_ref| subject_ref.kind == "entity")
        .map(|subject_ref| {
            take_or_default_entity_snapshot(
                &subject_ref.subject_id,
                subject_ref.entity_type.as_deref().unwrap_or("entity"),
            )
        })
        .collect::<Vec<_>>();
    if let Some(snapshot) = entity_snapshot {
        let already_present = snapshots
            .iter()
            .any(|entry| entry.entity_id == snapshot.entity_id);
        if !already_present {
            snapshots.push(snapshot);
        }
    }
    snapshots
}

fn recompute_snapshot(snapshot: &mut VibeStateSnapshot) {
    let dimensions = &snapshot.core_dna.dimensions;
    let average = average_map(dimensions);
    let variance = variance_map(dimensions, average);
    let energy = *dimensions.get("energy_preference").unwrap_or(&average);
    let directness = *dimensions.get("curation_tendency").unwrap_or(&average);
    let social = *dimensions
        .get("community_orientation")
        .or_else(|| dimensions.get("social_discovery_style"))
        .unwrap_or(&average);

    snapshot.quantum_vibe = QuantumVibeState {
        amplitudes: dimensions
            .iter()
            .map(|(key, value)| (key.clone(), (value - 0.5) * 2.0))
            .collect(),
        phase_alignment: clamp_unit(1.0 - variance),
        coherence: clamp_unit(1.0 - variance * 1.4),
    };
    snapshot.knot_invariants = KnotInvariantState {
        crossing_number: 2.0 + average * 10.0,
        tension: clamp_unit((snapshot.pheromones.vectors.len() as f64 / 12.0) + variance),
        symmetry: clamp_unit(1.0 - variance * 1.8),
    };
    snapshot.worldsheet = WorldsheetState {
        temporal_phase: clamp_unit(snapshot.behavior_patterns.cadence_hours / 48.0),
        momentum: clamp_unit(average_map(&snapshot.pheromones.vectors)),
        curvature: clamp_unit(variance + snapshot.affective_state.arousal.abs() * 0.25),
    };
    snapshot.string_evolution = StringEvolutionState {
        coupling: clamp_unit((snapshot.quantum_vibe.coherence + social) / 2.0),
        mutation_velocity: clamp_unit(
            (snapshot.behavior_patterns.observation_count as f64 / 50.0)
                + average_map(&snapshot.pheromones.vectors) * 0.4,
        ),
        harmonics: BTreeMap::from([
            ("identity".to_string(), average),
            ("social".to_string(), social),
            ("energy".to_string(), energy),
        ]),
    };
    snapshot.decoherence_state = DecoherenceState {
        noise: clamp_unit(variance + average_map(&snapshot.pheromones.vectors) * 0.2),
        stability: clamp_unit(snapshot.quantum_vibe.coherence),
        decoherence: clamp_unit(1.0 - snapshot.quantum_vibe.coherence),
    };
    snapshot.expression_context = VibeExpressionContext {
        tone_profile: if energy >= 0.66 {
            "clear_energetic".to_string()
        } else if social <= 0.34 {
            "measured_private".to_string()
        } else {
            "clear_calm".to_string()
        },
        pacing_profile: if snapshot.worldsheet.momentum >= 0.6 {
            "quick".to_string()
        } else {
            "steady".to_string()
        },
        uncertainty_profile: if snapshot.decoherence_state.decoherence >= 0.45 {
            "explicit".to_string()
        } else {
            "light".to_string()
        },
        social_cadence: social,
        energy,
        directness,
    };
    snapshot.confidence = clamp_unit(
        average_map(&snapshot.core_dna.dimension_confidence)
            .max(snapshot.affective_state.confidence),
    );
    snapshot.freshness_hours = 0.0;
    snapshot.updated_at_utc = now_iso();
}

fn update_affective_state(state: &mut AffectiveState, signals: &[VibeSignal]) {
    if signals.is_empty() {
        return;
    }
    for signal in signals {
        match signal.key.as_str() {
            "valence" => state.valence = blend_scalar(state.valence, signal.value, 0.35),
            "arousal" => state.arousal = blend_scalar(state.arousal, signal.value, 0.35),
            "dominance" => {
                state.dominance = blend_scalar(state.dominance, signal.value, 0.35)
            }
            _ => {}
        }
        if signal.confidence >= state.confidence {
            state.label = if signal.value >= 0.4 {
                "elevated".to_string()
            } else if signal.value <= -0.4 {
                "muted".to_string()
            } else {
                "neutral".to_string()
            };
            state.confidence = signal.confidence;
        }
    }
    state.expires_at_utc = Some((Utc::now() + chrono::Duration::hours(6)).to_rfc3339());
}

fn blend_dimension(
    dimensions: &mut BTreeMap<String, f64>,
    confidence_map: &mut BTreeMap<String, f64>,
    key: &str,
    target: f64,
    alpha: f64,
) {
    let current = *dimensions.get(key).unwrap_or(&0.5);
    dimensions.insert(key.to_string(), blend_scalar(current, target, alpha));
    let current_confidence = *confidence_map.get(key).unwrap_or(&0.0);
    confidence_map.insert(
        key.to_string(),
        clamp_unit(current_confidence + alpha * 1.6),
    );
}

fn blend_fast(store: &mut BTreeMap<String, f64>, key: &str, target: f64, alpha: f64) {
    let current = *store.get(key).unwrap_or(&0.0);
    store.insert(key.to_string(), blend_scalar(current, target, alpha));
}

fn blend_scalar(current: f64, target: f64, alpha: f64) -> f64 {
    clamp_unit(current + (target - current) * alpha.clamp(0.0, 1.0))
}

fn average_map(map: &BTreeMap<String, f64>) -> f64 {
    if map.is_empty() {
        return 0.0;
    }
    map.values().sum::<f64>() / map.len() as f64
}

fn variance_map(map: &BTreeMap<String, f64>, average: f64) -> f64 {
    if map.is_empty() {
        return 0.0;
    }
    map.values()
        .map(|value| (value - average).powi(2))
        .sum::<f64>()
        / map.len() as f64
}

fn clamp_unit(value: f64) -> f64 {
    value.clamp(0.0, 1.0)
}

fn numeric_map(value: Option<&Value>) -> BTreeMap<String, f64> {
    match value {
        Some(Value::Object(map)) => map
            .iter()
            .map(|(key, value)| (key.clone(), value.as_f64().unwrap_or(0.0)))
            .collect(),
        _ => BTreeMap::new(),
    }
}

fn subject_ref_list(value: Option<&Value>) -> Vec<VibeSubjectRef> {
    match value {
        Some(Value::Array(entries)) => entries
            .iter()
            .filter_map(|entry| serde_json::from_value(entry.clone()).ok())
            .collect(),
        _ => Vec::new(),
    }
}

fn string_list(value: Option<&Value>) -> Vec<String> {
    match value {
        Some(Value::Array(entries)) => entries
            .iter()
            .map(|entry| entry.as_str().unwrap_or_default().to_string())
            .filter(|entry| !entry.is_empty())
            .collect(),
        _ => Vec::new(),
    }
}

fn string_field(payload: &Map<String, Value>, key: &str, default: &str) -> String {
    payload
        .get(key)
        .and_then(Value::as_str)
        .unwrap_or(default)
        .to_string()
}

fn subject_kind_field(payload: &Map<String, Value>, default: &str) -> String {
    payload
        .get("subject_kind")
        .and_then(Value::as_str)
        .unwrap_or(default)
        .to_string()
}

fn schema_version() -> u32 {
    1
}

fn default_governance_scope() -> String {
    "personal".to_string()
}

fn default_locality_scope() -> String {
    "locality".to_string()
}

fn now_iso() -> String {
    Utc::now().to_rfc3339()
}

fn deserialize_or_default<T>(value: Option<Value>, fallback: Value) -> Result<T, String>
where
    T: for<'de> Deserialize<'de>,
{
    serde_json::from_value(value.unwrap_or(fallback))
        .map_err(|error| format!("vibe decode failed: {error}"))
}

fn deserialize_required<T>(value: Option<Value>, missing_message: &str) -> Result<T, String>
where
    T: for<'de> Deserialize<'de>,
{
    serde_json::from_value(value.ok_or_else(|| missing_message.to_string())?)
        .map_err(|error| format!("vibe decode failed: {error}"))
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"handled":false,"payload":null,"error":"response encode failed: {error}"}}"#
        )
    });
    CString::new(json).expect("response CString").into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn reset_state() {
        if let Some(store) = USER_STATE.get() {
            store.lock().expect("user state reset lock").clear();
        }
        if let Some(store) = ENTITY_STATE.get() {
            store.lock().expect("entity state reset lock").clear();
        }
    }

    fn allowed_mutation_decision() -> VibeMutationDecision {
        VibeMutationDecision {
            state_write_allowed: true,
            dna_write_allowed: true,
            pheromone_write_allowed: true,
            behavior_write_allowed: true,
            affective_write_allowed: true,
            style_write_allowed: true,
            reason_codes: vec!["test_allowed".to_string()],
            governance_scope: "personal".to_string(),
            air_gap_envelope_required: false,
            schema_version: schema_version(),
        }
    }

    #[test]
    fn onboarding_seed_creates_canonical_snapshot() {
        reset_state();
        let payload = Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_seed_test".to_string()),
            ),
            (
                "dimensions".to_string(),
                json!({
                    "energy_preference": 0.2,
                    "community_orientation": 0.75,
                }),
            ),
            (
                "dimension_confidence".to_string(),
                json!({
                    "energy_preference": 0.8,
                    "community_orientation": 0.6,
                }),
            ),
        ]);

        let receipt = seed_user_state_from_onboarding(&payload).expect("seed receipt");

        assert!(receipt.accepted);
        assert_eq!(
            receipt.snapshot.core_dna.dimensions.get("energy_preference"),
            Some(&0.2)
        );
        assert_eq!(
            receipt
                .snapshot
                .core_dna
                .dimension_confidence
                .get("energy_preference"),
            Some(&0.8)
        );
        assert_eq!(
            receipt.snapshot.core_dna.dimensions.get("community_orientation"),
            Some(&0.75)
        );
        assert_eq!(
            get_user_snapshot(&Map::from_iter(vec![(
                "subject_id".to_string(),
                Value::String("user_seed_test".to_string()),
            )]))
            .expect("snapshot")
            .core_dna
            .dimensions
            .get("community_orientation"),
            Some(&0.75)
        );
    }

    #[test]
    fn language_evidence_respects_governance_gate_and_updates_state_conservatively() {
        reset_state();
        seed_user_state_from_onboarding(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_language_test".to_string()),
            ),
            (
                "dimensions".to_string(),
                json!({
                    "energy_preference": 0.5,
                    "community_orientation": 0.5,
                }),
            ),
        ]))
        .expect("seed");

        let evidence = VibeEvidence {
            summary: "quiet preference".to_string(),
            identity_signals: vec![VibeSignal {
                key: "energy_preference".to_string(),
                kind: "identity".to_string(),
                value: 0.2,
                confidence: 0.7,
                provenance: vec!["test".to_string()],
            }],
            pheromone_signals: vec![VibeSignal {
                key: "quiet_bias".to_string(),
                kind: "pheromone".to_string(),
                value: 0.8,
                confidence: 0.8,
                provenance: vec!["test".to_string()],
            }],
            behavior_signals: vec![],
            affective_signals: vec![],
            style_signals: vec![],
            schema_version: schema_version(),
        };

        let denied = ingest_language_evidence(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_language_test".to_string()),
            ),
            ("evidence".to_string(), serde_json::to_value(&evidence).unwrap()),
            (
                "mutation_decision".to_string(),
                json!({
                    "state_write_allowed": false,
                    "dna_write_allowed": false,
                    "pheromone_write_allowed": false,
                    "behavior_write_allowed": false,
                    "affective_write_allowed": false,
                    "style_write_allowed": false,
                    "reason_codes": ["denied_in_test"],
                }),
            ),
        ]))
        .expect("denied receipt");

        assert!(!denied.accepted);
        assert_eq!(
            denied.snapshot.core_dna.dimensions.get("energy_preference"),
            Some(&0.5)
        );

        let allowed = ingest_language_evidence(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_language_test".to_string()),
            ),
            ("evidence".to_string(), serde_json::to_value(&evidence).unwrap()),
            (
                "mutation_decision".to_string(),
                serde_json::to_value(allowed_mutation_decision()).unwrap(),
            ),
        ]))
        .expect("allowed receipt");

        let energy = allowed
            .snapshot
            .core_dna
            .dimensions
            .get("energy_preference")
            .copied()
            .unwrap_or(0.5);
        let pheromone = allowed
            .snapshot
            .pheromones
            .vectors
            .get("quiet_bias")
            .copied()
            .unwrap_or(0.0);

        assert!(allowed.accepted);
        assert!(energy < 0.5);
        assert!(energy > 0.45);
        assert!(pheromone > 0.0);
    }

    #[test]
    fn decay_window_and_state_encoder_snapshot_use_canonical_state() {
        reset_state();
        ingest_behavior_observation(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_decay_test".to_string()),
            ),
            (
                "behavior_signals".to_string(),
                json!({
                    "late_night_bias": 0.9,
                }),
            ),
        ]))
        .expect("behavior receipt");

        let before = get_user_snapshot(&Map::from_iter(vec![(
            "subject_id".to_string(),
            Value::String("user_decay_test".to_string()),
        )]))
        .expect("before snapshot");
        let before_signal = before
            .pheromones
            .vectors
            .get("late_night_bias")
            .copied()
            .unwrap_or(0.0);

        let receipt = advance_decay_window(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_decay_test".to_string()),
            ),
            ("elapsed_hours".to_string(), Value::from(48.0)),
        ]))
        .expect("decay receipt");

        let after_signal = receipt
            .snapshot
            .pheromones
            .vectors
            .get("late_night_bias")
            .copied()
            .unwrap_or(0.0);
        assert!(after_signal < before_signal);

        ingest_entity_observation(&Map::from_iter(vec![
            (
                "entity_id".to_string(),
                Value::String("spot_decay_test".to_string()),
            ),
            (
                "entity_type".to_string(),
                Value::String("spot".to_string()),
            ),
            (
                "dimensions".to_string(),
                json!({
                    "community_orientation": 0.4,
                }),
            ),
        ]))
        .expect("entity receipt");

        let encoder = get_state_encoder_snapshot(&Map::from_iter(vec![
            (
                "subject_id".to_string(),
                Value::String("user_decay_test".to_string()),
            ),
            (
                "entity_id".to_string(),
                Value::String("spot_decay_test".to_string()),
            ),
            (
                "entity_type".to_string(),
                Value::String("spot".to_string()),
            ),
        ]))
        .expect("encoder snapshot");

        assert_eq!(
            encoder.metadata.get("kernel"),
            Some(&Value::String("vibe".to_string()))
        );
        assert!(encoder.entity_snapshot.is_some());
        assert_eq!(encoder.user_snapshot.subject_id, "user_decay_test");
    }
}
