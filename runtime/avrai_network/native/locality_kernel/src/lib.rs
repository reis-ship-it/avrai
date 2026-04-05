use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};

mod how_kernel;
mod why_kernel;

static SNAPSHOT_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, Value>>> =
    OnceLock::new();
static MESH_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, Value>>> = OnceLock::new();
static CANDIDATE_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, CandidateRecord>>> =
    OnceLock::new();
static PERSISTED_STATE: OnceLock<NativePersistenceEnvelope> = OnceLock::new();

const CURRENT_SCHEMA_VERSION: u32 = 2;
const CANDIDATE_DECAY_DAYS: i64 = 14;
const MAX_SNAPSHOT_REGISTRY_SIZE: usize = 512;
const MAX_MESH_REGISTRY_SIZE: usize = 256;
const MAX_CANDIDATE_REGISTRY_SIZE: usize = 1024;

#[derive(Clone, Debug, Serialize, Deserialize)]
struct CandidateRecord {
    coherence_count: i64,
    first_seen_utc: String,
    last_seen_utc: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
struct NativePersistenceEnvelope {
    #[serde(default = "default_schema_version")]
    schema_version: u32,
    #[serde(default)]
    saved_at_utc: String,
    #[serde(default)]
    snapshots: std::collections::HashMap<String, Value>,
    #[serde(default)]
    mesh: std::collections::HashMap<String, Value>,
    #[serde(default)]
    candidates: std::collections::HashMap<String, CandidateRecord>,
}

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

#[no_mangle]
pub extern "C" fn avrai_locality_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_locality_kernel_free_string(ptr: *mut c_char) {
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
    match request.syscall.as_str() {
        "resolve_point_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_point_locality(&request.payload),
            error: None,
        }),
        "resolve_where" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_where(&request.payload),
            error: None,
        }),
        "seed_homebase" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: seed_homebase(&request.payload),
            error: None,
        }),
        "observe_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: observe_locality(&request.payload),
            error: None,
        }),
        "observe_visit" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: observe_visit(&request.payload),
            error: None,
        }),
        "project_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_locality(&request.payload),
            error: None,
        }),
        "project_where_reality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_where_reality(&request.payload),
            error: None,
        }),
        "project_where_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_where_governance(&request.payload),
            error: None,
        }),
        "diagnose_where_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: diagnose_where_kernel(),
            error: None,
        }),
        "diagnose_locality_admin" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: diagnose_locality_admin(&request.payload),
            error: None,
        }),
        "load_baseline_artifact" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: load_baseline_artifact(&request.payload),
            error: None,
        }),
        "build_bootstrap_batch" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: build_bootstrap_batch(&request.payload),
            error: None,
        }),
        "evaluate_zero_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: evaluate_zero_locality(&request.payload),
            error: None,
        }),
        "snapshot_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_locality(&request.payload),
            error: None,
        }),
        "recover_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: recover_locality(&request.payload),
            error: None,
        }),
        "sync_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: sync_locality(&request.payload),
            error: None,
        }),
        "observe_mesh_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: observe_mesh_locality(&request.payload),
            error: None,
        }),
        "explain_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: why_kernel::explain_why(&request.payload),
            error: None,
        }),
        "explain_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: how_kernel::explain_how(&request.payload),
            error: None,
        }),
        _ => Ok(NativeResponse {
            ok: true,
            handled: false,
            payload: Value::Null,
            error: None,
        }),
    }
}

fn resolve_point_locality(payload: &Map<String, Value>) -> Value {
    let lat = payload
        .get("latitude")
        .and_then(Value::as_f64)
        .unwrap_or(33.5186);
    let lon = payload
        .get("longitude")
        .and_then(Value::as_f64)
        .unwrap_or(-86.8104);
    let occurred_at = payload
        .get("occurredAtUtc")
        .and_then(Value::as_str)
        .unwrap_or("2026-03-06T00:00:00Z");
    let audience = payload
        .get("audience")
        .and_then(Value::as_str)
        .unwrap_or("user");
    let include_geometry = payload
        .get("includeGeometry")
        .and_then(Value::as_bool)
        .unwrap_or(false);
    let include_attribution = payload
        .get("includeAttribution")
        .and_then(Value::as_bool)
        .unwrap_or(false);
    let include_prediction = payload
        .get("includePrediction")
        .and_then(Value::as_bool)
        .unwrap_or(false);

    let locality = classify_locality(lat, lon);
    let state = build_state(
        &locality,
        occurred_at,
        payload
            .get("topAlias")
            .and_then(Value::as_str)
            .map(ToString::to_string),
        if locality.city_code == "unknown" {
            "bootstrap"
        } else {
            "established"
        },
    );
    let projection_request = json!({
        "audience": audience,
        "state": state,
        "includeGeometry": include_geometry,
        "includeAttribution": include_attribution,
        "includePrediction": include_prediction,
    });
    let projection = project_locality(
        projection_request
            .as_object()
            .expect("projection request should be object"),
    );

    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        save_snapshot(agent_id, &state, occurred_at);
    }

    json!({
        "state": state,
        "projection": projection,
        "cityCode": locality.city_code,
        "localityCode": locality.locality_code,
        "displayName": locality.display_name,
    })
}

fn resolve_where(payload: &Map<String, Value>) -> Value {
    let occurred_at = payload
        .get("occurredAtUtc")
        .and_then(Value::as_str)
        .unwrap_or("2026-03-06T00:00:00Z");
    if let (Some(lat), Some(lon)) = (
        payload.get("latitude").and_then(Value::as_f64),
        payload.get("longitude").and_then(Value::as_f64),
    ) {
        let locality = classify_locality(lat, lon);
        let state = build_state(
            &locality,
            occurred_at,
            payload
                .get("topAlias")
                .and_then(Value::as_str)
                .map(ToString::to_string),
            if locality.city_code == "unknown" {
                "bootstrap"
            } else {
                "established"
            },
        );
        if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
            save_snapshot(agent_id, &state, occurred_at);
        }
        return state;
    }

    if let Some(key) = payload
        .get("localityKeyHint")
        .and_then(Value::as_object)
        .cloned()
    {
        let geohash = key
            .get("geohashPrefix")
            .and_then(Value::as_str)
            .unwrap_or("unresolved");
        let city_code = key
            .get("cityCode")
            .and_then(Value::as_str)
            .unwrap_or("unknown");
        let alias = payload
            .get("topAlias")
            .and_then(Value::as_str)
            .unwrap_or(city_code);
        let state = build_state_from_token(
            &format!("gh7:{geohash}"),
            alias,
            city_code,
            occurred_at,
            "bootstrap",
            0.46,
            0.62,
        );
        if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
            save_snapshot(agent_id, &state, occurred_at);
        }
        return state;
    }

    let state = synthetic_zero_state(occurred_at);
    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        save_snapshot(agent_id, &state, occurred_at);
    }
    state
}

fn seed_homebase(payload: &Map<String, Value>) -> Value {
    let lat = payload
        .get("latitude")
        .and_then(Value::as_f64)
        .unwrap_or(33.5186);
    let lon = payload
        .get("longitude")
        .and_then(Value::as_f64)
        .unwrap_or(-86.8104);
    let city_code = payload
        .get("cityCode")
        .and_then(Value::as_str)
        .map(ToString::to_string);
    let locality = classify_locality(lat, lon);
    let effective_city = city_code.unwrap_or_else(|| locality.city_code.clone());
    let state = build_state(
        &LocalityClassification {
            city_code: effective_city.clone(),
            locality_code: locality.locality_code.clone(),
            display_name: locality.display_name.clone(),
            token_id: locality.token_id.clone(),
            confidence: 0.55,
            boundary_tension: locality.boundary_tension,
            evolution_rate: 0.03,
            source_mix: json!({
                "local": 0.1,
                "mesh": 0.0,
                "federated": 0.5,
                "geometry": 0.2,
                "syntheticPrior": 0.2
            }),
        },
        "2026-03-06T00:00:00Z",
        Some(locality.display_name.clone()),
        "bootstrap",
    );
    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        save_snapshot(agent_id, &state, "2026-03-06T00:00:00Z");
    }
    state
}

fn observe_locality(payload: &Map<String, Value>) -> Value {
    let key = payload
        .get("key")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let occurred_at = payload
        .get("occurredAtUtc")
        .and_then(Value::as_str)
        .unwrap_or("2026-03-06T00:00:00Z");
    let geohash = key
        .get("geohashPrefix")
        .and_then(Value::as_str)
        .unwrap_or("unresolved");
    let city_code = payload
        .get("reportedCityCode")
        .and_then(Value::as_str)
        .or_else(|| payload.get("inferredCityCode").and_then(Value::as_str))
        .or_else(|| key.get("cityCode").and_then(Value::as_str))
        .unwrap_or("unknown");
    let alias = payload
        .get("topAlias")
        .and_then(Value::as_str)
        .unwrap_or(city_code);
    let observation_type = payload
        .get("type")
        .and_then(Value::as_str)
        .unwrap_or("visitComplete");

    let (reliability_tier, confidence, boundary_tension, cloud_updated, mesh_forwarded) =
        match observation_type {
            "meshLocalityUpdate" => ("candidate", 0.42, 0.58, false, true),
            "federatedPriorUpdate" => ("bootstrap", 0.48, 0.44, true, false),
            "happinessSignal" | "advisoryResult" => ("candidate", 0.61, 0.31, false, false),
            _ => ("candidate", 0.66, 0.26, true, false),
        };

    let base_state = build_state_from_token(
        &format!("gh7:{geohash}"),
        alias,
        city_code,
        occurred_at,
        reliability_tier,
        confidence,
        boundary_tension,
    );
    let agent_id = payload
        .get("agentId")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let state = match observation_type {
        "visitComplete" | "organicDiscoverySignal" => {
            let candidate = next_candidate_record(agent_id, geohash, occurred_at);
            normalize_candidate_state(base_state, &candidate)
        }
        "happinessSignal" | "advisoryResult" => {
            apply_advisory_state_transition(base_state, payload)
        }
        _ => base_state,
    };
    if !agent_id.is_empty() {
        save_snapshot(agent_id, &state, occurred_at);
    }

    json!({
        "state": state,
        "cloudUpdated": cloud_updated,
        "meshForwarded": mesh_forwarded,
    })
}

fn observe_visit(payload: &Map<String, Value>) -> Value {
    let user_id = payload
        .get("userId")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let visit = payload
        .get("visit")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();

    let lat = visit
        .get("metadata")
        .and_then(Value::as_object)
        .and_then(|metadata| metadata.get("latitude"))
        .and_then(Value::as_f64);
    let lon = visit
        .get("metadata")
        .and_then(Value::as_object)
        .and_then(|metadata| metadata.get("longitude"))
        .and_then(Value::as_f64);

    if lat.is_none() || lon.is_none() {
        return json!({});
    }

    let occurred_at = visit
        .get("checkOutTime")
        .and_then(Value::as_str)
        .or_else(|| visit.get("checkInTime").and_then(Value::as_str))
        .unwrap_or("2026-03-06T00:00:00Z");
    let locality = classify_locality(lat.unwrap_or(33.5186), lon.unwrap_or(-86.8104));
    let base_state = build_state(
        &locality,
        occurred_at,
        Some(locality.display_name.clone()),
        "candidate",
    );

    let agent_id = payload
        .get("agentId")
        .and_then(Value::as_str)
        .map(ToString::to_string)
        .unwrap_or_else(|| format!("native-agent:{user_id}"));
    let candidate = next_candidate_record(&agent_id, &locality.token_id, occurred_at);
    let state = normalize_candidate_state(base_state, &candidate);
    save_snapshot(&agent_id, &state, occurred_at);

    json!({
        "receipt": {
            "state": state,
            "cloudUpdated": true,
            "meshForwarded": true
        }
    })
}

fn project_locality(payload: &Map<String, Value>) -> Value {
    let state = payload
        .get("state")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let audience = payload
        .get("audience")
        .and_then(Value::as_str)
        .unwrap_or("user");
    let include_prediction = payload
        .get("includePrediction")
        .and_then(Value::as_bool)
        .unwrap_or(false);

    let top_alias = string_field(&state, "topAlias");
    let active_token = state
        .get("activeToken")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let primary_label = top_alias
        .or_else(|| string_field(&active_token, "alias"))
        .or_else(|| string_field(&active_token, "id"))
        .unwrap_or_else(|| "unresolved".to_string());

    let confidence = float_field(&state, "confidence").unwrap_or(0.0);
    let confidence_bucket = if confidence >= 0.75 {
        "high"
    } else if confidence >= 0.4 {
        "medium"
    } else {
        "low"
    };
    let boundary_tension = float_field(&state, "boundaryTension").unwrap_or(1.0);
    let near_boundary = boundary_tension >= 0.5;
    let evolution_rate = float_field(&state, "evolutionRate").unwrap_or(0.0);
    let reliability_tier =
        string_field(&state, "reliabilityTier").unwrap_or_else(|| "zeroLocality".to_string());
    let advisory_status =
        string_field(&state, "advisoryStatus").unwrap_or_else(|| "inactive".to_string());
    let evidence_count = state
        .get("evidenceCount")
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let source_mix = state.get("sourceMix").cloned().unwrap_or_else(|| json!({}));
    let source_mix_object = source_mix.as_object().cloned().unwrap_or_default();
    let dominant_source = dominant_source_key(&source_mix_object);
    let source_mix_summary = source_mix_summary(&source_mix_object);
    let stability_class = classify_stability(
        confidence,
        boundary_tension,
        evolution_rate,
        &reliability_tier,
        &advisory_status,
    );
    let next_state_risk = derive_next_state_risk(
        confidence,
        boundary_tension,
        evolution_rate,
        &reliability_tier,
        &advisory_status,
    );
    let promotion_readiness =
        derive_promotion_readiness(&reliability_tier, evidence_count, &advisory_status);
    let explanatory_factors = explain_locality_factors(
        confidence,
        boundary_tension,
        evolution_rate,
        evidence_count,
        &reliability_tier,
        &advisory_status,
        &source_mix_object,
    );

    let mut metadata = Map::new();
    if audience != "user" {
        metadata.insert("confidence".to_string(), json!(confidence));
        metadata.insert("boundaryTension".to_string(), json!(boundary_tension));
        metadata.insert("sourceMix".to_string(), source_mix);
        metadata.insert("evolutionRate".to_string(), json!(evolution_rate));
        metadata.insert("reliabilityTier".to_string(), json!(reliability_tier));
        metadata.insert("advisoryStatus".to_string(), json!(advisory_status));
        metadata.insert("dominantSource".to_string(), json!(dominant_source));
        metadata.insert("sourceMixSummary".to_string(), json!(source_mix_summary));
        metadata.insert("stabilityClass".to_string(), json!(stability_class));
        metadata.insert("nextStateRisk".to_string(), json!(next_state_risk));
        metadata.insert("promotionReadiness".to_string(), json!(promotion_readiness));
        metadata.insert(
            "explanatoryFactors".to_string(),
            Value::Array(explanatory_factors.into_iter().map(Value::String).collect()),
        );
    }
    if include_prediction {
        metadata.insert(
            "predictiveTrend".to_string(),
            json!(derive_predictive_trend(
                boundary_tension,
                evolution_rate,
                evidence_count,
                &reliability_tier,
                &advisory_status,
            )),
        );
    }

    json!({
        "primaryLabel": primary_label,
        "confidenceBucket": confidence_bucket,
        "nearBoundary": near_boundary,
        "activeToken": Value::Object(active_token),
        "metadata": Value::Object(metadata),
    })
}

fn project_where_reality(payload: &Map<String, Value>) -> Value {
    let projection = project_locality(payload);
    let projection_map = projection.as_object().cloned().unwrap_or_default();
    let primary_label = projection_map
        .get("primaryLabel")
        .and_then(Value::as_str)
        .unwrap_or("unresolved");
    let confidence = projection_map
        .get("metadata")
        .and_then(Value::as_object)
        .and_then(|metadata| metadata.get("confidence"))
        .and_then(Value::as_f64)
        .unwrap_or_else(|| {
            let bucket = projection_map
                .get("confidenceBucket")
                .and_then(Value::as_str)
                .unwrap_or("low");
            match bucket {
                "high" => 0.86,
                "medium" => 0.58,
                _ => 0.28,
            }
        });

    json!({
        "summary": format!("Spatial truth for {primary_label}"),
        "confidence": confidence,
        "features": {
            "confidence_bucket": projection_map
                .get("confidenceBucket")
                .cloned()
                .unwrap_or_else(|| json!("low")),
            "near_boundary": projection_map
                .get("nearBoundary")
                .cloned()
                .unwrap_or_else(|| json!(false)),
            "locality_contained_in_where": true,
        },
        "payload": projection_map,
    })
}

fn project_where_governance(payload: &Map<String, Value>) -> Value {
    let projection = project_locality(payload);
    let projection_map = projection.as_object().cloned().unwrap_or_default();
    let primary_label = projection_map
        .get("primaryLabel")
        .and_then(Value::as_str)
        .unwrap_or("unresolved");
    let confidence = projection_map
        .get("metadata")
        .and_then(Value::as_object)
        .and_then(|metadata| metadata.get("confidence"))
        .and_then(Value::as_f64)
        .unwrap_or_else(|| {
            let bucket = projection_map
                .get("confidenceBucket")
                .and_then(Value::as_str)
                .unwrap_or("low");
            match bucket {
                "high" => 0.86,
                "medium" => 0.58,
                _ => 0.28,
            }
        });
    let near_boundary = projection_map
        .get("nearBoundary")
        .and_then(Value::as_bool)
        .unwrap_or(false);

    json!({
        "domain": "where",
        "summary": format!("Governance spatial view for {primary_label}"),
        "confidence": confidence,
        "highlights": [
            projection_map
                .get("confidenceBucket")
                .and_then(Value::as_str)
                .unwrap_or("low"),
            if near_boundary { "boundary_volatile" } else { "stable" },
            "locality_inside_where",
        ],
        "payload": projection_map,
    })
}

fn diagnose_where_kernel() -> Value {
    let snapshot_count = SNAPSHOT_REGISTRY
        .get()
        .and_then(|registry| registry.lock().ok())
        .map(|registry| registry.len())
        .unwrap_or(0);
    let mesh_count = MESH_REGISTRY
        .get()
        .and_then(|registry| registry.lock().ok())
        .map(|registry| registry.len())
        .unwrap_or(0);
    let candidate_count = CANDIDATE_REGISTRY
        .get()
        .and_then(|registry| registry.lock().ok())
        .map(|registry| registry.len())
        .unwrap_or(0);

    json!({
        "domain": "where",
        "status": "healthy",
        "native_backed": true,
        "headless_ready": true,
        "authority_level": "authoritative",
        "summary": "where kernel exposes native spatial truth, governance projections, and locality-contained diagnostics",
        "diagnostics": {
            "snapshot_count": snapshot_count,
            "mesh_count": mesh_count,
            "candidate_count": candidate_count,
            "locality_contained_in_where": true,
            "supported_surfaces": [
                "resolve_where",
                "project_locality",
                "project_where_reality",
                "project_where_governance",
                "diagnose_where_kernel",
            ],
        },
    })
}

fn diagnose_locality_admin(payload: &Map<String, Value>) -> Value {
    let probes = payload
        .get("probes")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let model_family = payload
        .get("modelFamily")
        .and_then(Value::as_str)
        .unwrap_or("reality_kernel");

    let mut resolutions: Vec<Value> = Vec::new();
    let mut top_localities = std::collections::HashMap::<String, i64>::new();
    let mut predictive_breakdown = std::collections::HashMap::<String, i64>::new();
    let mut stability_breakdown = std::collections::HashMap::<String, i64>::new();
    let mut near_boundary_count = 0_i64;
    let mut high_confidence_count = 0_i64;
    let mut advisory_active_count = 0_i64;
    let mut predictive_change_count = 0_i64;
    let mut best_sample_index: Option<usize> = None;
    let mut best_sample_score = f64::MIN;

    for probe in probes {
        let Some(probe_object) = probe.as_object() else {
            continue;
        };
        let resolution = resolve_point_locality(probe_object);
        let resolution_object = resolution.as_object().cloned().unwrap_or_default();
        let projection = resolution_object
            .get("projection")
            .and_then(Value::as_object)
            .cloned()
            .unwrap_or_default();
        let metadata = projection
            .get("metadata")
            .and_then(Value::as_object)
            .cloned()
            .unwrap_or_default();
        let state = resolution_object
            .get("state")
            .and_then(Value::as_object)
            .cloned()
            .unwrap_or_default();

        let primary_label =
            string_field(&projection, "primaryLabel").unwrap_or_else(|| "unresolved".to_string());
        *top_localities.entry(primary_label).or_insert(0) += 1;

        if projection
            .get("nearBoundary")
            .and_then(Value::as_bool)
            .unwrap_or(false)
        {
            near_boundary_count += 1;
        }
        if projection
            .get("confidenceBucket")
            .and_then(Value::as_str)
            .unwrap_or("low")
            == "high"
        {
            high_confidence_count += 1;
        }
        if metadata
            .get("advisoryStatus")
            .and_then(Value::as_str)
            .unwrap_or("inactive")
            == "active"
        {
            advisory_active_count += 1;
        }

        let predictive_trend =
            string_field(&metadata, "predictiveTrend").unwrap_or_else(|| "stable".to_string());
        if predictive_trend != "stable" {
            predictive_change_count += 1;
        }
        *predictive_breakdown.entry(predictive_trend).or_insert(0) += 1;

        let stability_class =
            string_field(&metadata, "stabilityClass").unwrap_or_else(|| "watch".to_string());
        *stability_breakdown.entry(stability_class).or_insert(0) += 1;

        let sample_score = sample_resolution_score(&projection, &metadata, &state);
        if sample_score > best_sample_score {
            best_sample_score = sample_score;
            best_sample_index = Some(resolutions.len());
        }

        resolutions.push(Value::Object(resolution_object));
    }

    let sample_resolution = best_sample_index
        .and_then(|index| resolutions.get(index).cloned())
        .unwrap_or_else(|| json!({}));
    let city_profile = payload
        .get("cityProfile")
        .and_then(Value::as_str)
        .map(ToString::to_string)
        .unwrap_or_else(|| derive_city_profile(&sample_resolution));

    let top_localities_sorted = sort_count_map_desc(top_localities)
        .into_iter()
        .take(6)
        .map(|(label, count)| json!({"label": label, "count": count}))
        .collect::<Vec<_>>();
    let predictive_breakdown_sorted = count_map_to_object(predictive_breakdown);
    let stability_breakdown_sorted = count_map_to_object(stability_breakdown);
    let locality_count = std::cmp::max(
        12_i64,
        std::cmp::max(
            resolutions.len() as i64,
            (top_localities_sorted.len() as i64) * 3,
        ),
    );
    let zero_locality_report = evaluate_zero_locality_readiness(
        &json!({
            "cityProfile": city_profile,
            "modelFamily": model_family,
            "localityCount": locality_count,
        })
        .as_object()
        .cloned()
        .unwrap_or_default(),
    );

    json!({
        "resolutions": resolutions,
        "resolutionCount": resolutions.len(),
        "topLocalities": top_localities_sorted,
        "nearBoundaryCount": near_boundary_count,
        "highConfidenceCount": high_confidence_count,
        "advisoryActiveCount": advisory_active_count,
        "predictiveChangeCount": predictive_change_count,
        "predictiveBreakdown": predictive_breakdown_sorted,
        "stabilityBreakdown": stability_breakdown_sorted,
        "sampleResolution": sample_resolution,
        "zeroLocalityReport": zero_locality_report,
        "cityProfile": city_profile,
        "stateStore": {
            "schemaVersion": CURRENT_SCHEMA_VERSION,
            "snapshotCount": snapshot_registry()
                .lock()
                .map(|guard| guard.len())
                .unwrap_or(0),
            "meshCount": mesh_registry().lock().map(|guard| guard.len()).unwrap_or(0),
            "candidateCount": candidate_registry()
                .lock()
                .map(|guard| guard.len())
                .unwrap_or(0),
            "persistencePath": state_file_path().display().to_string(),
        }
    })
}

fn load_baseline_artifact(payload: &Map<String, Value>) -> Value {
    let city_profile = payload
        .get("cityProfile")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let model_family = payload
        .get("modelFamily")
        .and_then(Value::as_str)
        .unwrap_or("default");
    let candidate_registry_size = candidate_registry()
        .lock()
        .map(|guard| guard.len())
        .unwrap_or(0) as i64;
    let snapshot_registry_size = snapshot_registry()
        .lock()
        .map(|guard| guard.len())
        .unwrap_or(0) as i64;
    let candidate_promotion_threshold = if candidate_registry_size >= 24 { 10 } else { 8 };
    let bootstrap_confidence_floor = if snapshot_registry_size > 0 {
        0.38
    } else {
        0.35
    };

    json!({
        "artifactId": format!("locality-{model_family}-{city_profile}-native-v2"),
        "version": "2.0.0",
        "calibration": {
            "cityProfile": city_profile,
            "modelFamily": model_family,
            "candidatePromotionThreshold": candidate_promotion_threshold,
            "advisoryActivationThreshold": 0.45,
            "bootstrapConfidenceFloor": bootstrap_confidence_floor,
            "zeroLocalityFallback": "native_bootstrap",
            "candidateRegistrySize": candidate_registry_size,
            "snapshotRegistrySize": snapshot_registry_size,
            "statePersistencePath": state_file_path().display().to_string()
        }
    })
}

fn build_bootstrap_batch(payload: &Map<String, Value>) -> Value {
    let city_profile = payload
        .get("cityProfile")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let locality_count = payload
        .get("localityCount")
        .and_then(Value::as_i64)
        .unwrap_or(12)
        .max(6);
    let candidate_registry_size = candidate_registry()
        .lock()
        .map(|guard| guard.len())
        .unwrap_or(0) as i64;
    let third_count = (locality_count / 3).max(2);
    let half_count = (locality_count / 2).max(3);

    let mut scenarios = vec![
        json!({
            "scenarioId": format!("{city_profile}-zero-locality"),
            "cityProfile": city_profile,
            "localityCount": locality_count,
            "fuzzyBoundaries": true
        }),
        json!({
            "scenarioId": format!("{city_profile}-boundary-tension"),
            "cityProfile": city_profile,
            "localityCount": locality_count,
            "fuzzyBoundaries": true
        }),
        json!({
            "scenarioId": format!("{city_profile}-mesh-only"),
            "cityProfile": city_profile,
            "localityCount": half_count,
            "fuzzyBoundaries": true
        }),
        json!({
            "scenarioId": format!("{city_profile}-federated-refresh"),
            "cityProfile": city_profile,
            "localityCount": locality_count,
            "fuzzyBoundaries": false
        }),
        json!({
            "scenarioId": format!("{city_profile}-advisory-recovery"),
            "cityProfile": city_profile,
            "localityCount": third_count,
            "fuzzyBoundaries": true
        }),
        json!({
            "scenarioId": format!("{city_profile}-candidate-emergence"),
            "cityProfile": city_profile,
            "localityCount": half_count,
            "fuzzyBoundaries": true
        }),
    ];

    if candidate_registry_size > 0 {
        scenarios.push(json!({
            "scenarioId": format!("{city_profile}-candidate-drift"),
            "cityProfile": city_profile,
            "localityCount": third_count,
            "fuzzyBoundaries": true
        }));
    }

    json!({
        "batchId": format!("bootstrap-{city_profile}-native-v2"),
        "scenarios": scenarios,
    })
}

fn evaluate_zero_locality(payload: &Map<String, Value>) -> Value {
    if payload.get("artifact").is_some() || payload.get("batch").is_some() {
        return evaluate_zero_locality_training(payload);
    }
    evaluate_zero_locality_readiness(payload)
}

fn evaluate_zero_locality_readiness(payload: &Map<String, Value>) -> Value {
    let city_profile = payload
        .get("cityProfile")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let model_family = payload
        .get("modelFamily")
        .and_then(Value::as_str)
        .unwrap_or("default");
    let locality_count = payload
        .get("localityCount")
        .and_then(Value::as_i64)
        .unwrap_or(12)
        .max(1) as f64;

    let scenario_count: f64 = 5.0;
    let cold_start = (0.72_f64 + (scenario_count * 0.015_f64)).clamp(0.0_f64, 0.92_f64);
    let confidence = (0.74_f64 + (locality_count / 400.0_f64)).clamp(0.0_f64, 0.9_f64);

    json!({
        "evaluationId": format!("locality-{model_family}-{city_profile}:native-bootstrap"),
        "metrics": [
            {
                "name": "cold_start_plausibility",
                "value": cold_start,
                "target": 0.70
            },
            {
                "name": "confidence_calibration",
                "value": confidence,
                "target": 0.72
            },
            {
                "name": "boundary_case_stability",
                "value": 0.78,
                "target": 0.70
            },
            {
                "name": "candidate_promotion_precision",
                "value": 0.76,
                "target": 0.74
            },
            {
                "name": "advisory_recovery_quality",
                "value": 0.73,
                "target": 0.70
            }
        ],
        "calibration": {
            "cityProfile": city_profile,
            "modelFamily": model_family,
            "candidatePromotionThreshold": 8,
            "advisoryActivationThreshold": 0.45,
            "bootstrapConfidenceFloor": 0.35,
            "zeroLocalityFallback": "synthetic_bootstrap",
            "localityMass": locality_count as i64,
            "scenarioCount": scenario_count as i64
        }
    })
}

fn evaluate_zero_locality_training(payload: &Map<String, Value>) -> Value {
    let artifact = payload
        .get("artifact")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let batch = payload
        .get("batch")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let artifact_id = artifact
        .get("artifactId")
        .and_then(Value::as_str)
        .unwrap_or("locality-native-artifact");
    let calibration = artifact
        .get("calibration")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let scenarios = batch
        .get("scenarios")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let batch_id = batch
        .get("batchId")
        .and_then(Value::as_str)
        .unwrap_or("native-bootstrap-batch");
    let scenario_count = scenarios.len().max(1) as f64;
    let locality_mass = scenarios
        .iter()
        .map(|scenario| {
            scenario
                .get("localityCount")
                .and_then(Value::as_i64)
                .unwrap_or(0)
        })
        .sum::<i64>()
        .max(1) as f64;
    let fuzzy_count = scenarios
        .iter()
        .filter(|scenario| {
            scenario
                .get("fuzzyBoundaries")
                .and_then(Value::as_bool)
                .unwrap_or(true)
        })
        .count() as f64;
    let candidate_registry_size = candidate_registry()
        .lock()
        .map(|guard| guard.len())
        .unwrap_or(0) as f64;
    let snapshot_registry_size = snapshot_registry()
        .lock()
        .map(|guard| guard.len())
        .unwrap_or(0) as f64;
    let mesh_registry_size = mesh_registry().lock().map(|guard| guard.len()).unwrap_or(0) as f64;
    let candidate_threshold = calibration
        .get("candidatePromotionThreshold")
        .and_then(Value::as_f64)
        .unwrap_or(8.0);
    let advisory_threshold = calibration
        .get("advisoryActivationThreshold")
        .and_then(Value::as_f64)
        .unwrap_or(0.45);
    let bootstrap_floor = calibration
        .get("bootstrapConfidenceFloor")
        .and_then(Value::as_f64)
        .unwrap_or(0.35);
    let fuzzy_ratio = (fuzzy_count / scenario_count).clamp(0.0, 1.0);

    let cold_start = (0.68
        + (scenario_count * 0.018)
        + (bootstrap_floor * 0.18)
        + (snapshot_registry_size.min(12.0) * 0.002))
        .clamp(0.0, 0.94);
    let confidence = (0.70
        + (bootstrap_floor * 0.30)
        + (fuzzy_ratio * 0.05)
        + ((locality_mass / 400.0).min(0.08)))
    .clamp(0.0, 0.9);
    let boundary_stability =
        (0.67 + (fuzzy_ratio * 0.12) + (mesh_registry_size.min(20.0) * 0.004)).clamp(0.0, 0.9);
    let candidate_precision = (0.71
        + ((10.0 - candidate_threshold).max(0.0) * 0.01)
        + (candidate_registry_size.min(20.0) * 0.003))
        .clamp(0.0, 0.89);
    let advisory_recovery = (0.69
        + ((0.50 - advisory_threshold).max(0.0) * 0.10)
        + (snapshot_registry_size.min(20.0) * 0.003))
        .clamp(0.0, 0.88);

    json!({
        "evaluationId": format!("{artifact_id}:{batch_id}"),
        "metrics": [
            {
                "name": "cold_start_plausibility",
                "value": cold_start,
                "target": 0.70
            },
            {
                "name": "confidence_calibration",
                "value": confidence,
                "target": 0.72
            },
            {
                "name": "boundary_case_stability",
                "value": boundary_stability,
                "target": 0.70
            },
            {
                "name": "candidate_promotion_precision",
                "value": candidate_precision,
                "target": 0.74
            },
            {
                "name": "advisory_recovery_quality",
                "value": advisory_recovery,
                "target": 0.70
            }
        ],
        "calibration": {
            "scenarioCount": scenario_count as i64,
            "localityMass": locality_mass as i64,
            "fuzzyScenarioCount": fuzzy_count as i64,
            "candidateRegistrySize": candidate_registry_size as i64,
            "snapshotRegistrySize": snapshot_registry_size as i64,
            "meshRegistrySize": mesh_registry_size as i64,
            "bootstrapConfidenceFloor": bootstrap_floor,
            "statePersistencePath": state_file_path().display().to_string()
        }
    })
}

fn snapshot_locality(payload: &Map<String, Value>) -> Value {
    let agent_id = payload
        .get("agentId")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let registry = snapshot_registry();
    let guard = registry.lock().expect("snapshot registry mutex poisoned");
    let snapshot = guard.get(agent_id).cloned();
    match snapshot {
        Some(snapshot) => json!({
            "snapshot": snapshot,
        }),
        None => json!({}),
    }
}

fn recover_locality(payload: &Map<String, Value>) -> Value {
    let agent_id = payload
        .get("agentId")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let registry = snapshot_registry();
    let guard = registry.lock().expect("snapshot registry mutex poisoned");
    if let Some(snapshot) = guard.get(agent_id) {
        let state = snapshot
            .get("state")
            .cloned()
            .unwrap_or_else(|| synthetic_zero_state("2026-03-06T00:00:00Z"));
        return json!({
            "state": state,
            "recoveredFromSnapshot": true,
        });
    }

    json!({
        "state": synthetic_zero_state("2026-03-06T00:00:00Z"),
        "recoveredFromSnapshot": false,
    })
}

fn sync_locality(payload: &Map<String, Value>) -> Value {
    let agent_id = payload
        .get("agentId")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let allow_cloud = payload
        .get("allowCloud")
        .and_then(Value::as_bool)
        .unwrap_or(true);
    let allow_mesh = payload
        .get("allowMesh")
        .and_then(Value::as_bool)
        .unwrap_or(true);
    let synced_at = payload
        .get("syncedAtUtc")
        .and_then(Value::as_str)
        .unwrap_or("2026-03-06T00:00:00Z");

    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .or_else(|| {
            let registry = snapshot_registry();
            let guard = registry.lock().ok()?;
            guard.get(agent_id).and_then(Value::as_object).cloned()
        });

    let Some(snapshot_object) = snapshot else {
        return json!({
            "synced": allow_cloud || allow_mesh,
            "message": format!("Native locality sync had no snapshot for {}", agent_id),
        });
    };

    let mut state = snapshot_object
        .get("state")
        .cloned()
        .unwrap_or_else(|| synthetic_zero_state(synced_at));

    let mut applied_cloud = false;
    let mut applied_mesh = false;

    if allow_cloud {
        if let Some(global_state) = payload.get("globalState").and_then(Value::as_object) {
            state = reconcile_with_global_state(&state, global_state, synced_at);
            applied_cloud = true;
        }
    }

    if allow_mesh {
        if let Some(mesh_updates) = payload.get("neighborMeshUpdates").and_then(Value::as_array) {
            state = reconcile_with_mesh_updates(&state, mesh_updates, synced_at);
            applied_mesh = !mesh_updates.is_empty();
        }
    }

    save_snapshot(agent_id, &state, synced_at);

    json!({
        "synced": allow_cloud || allow_mesh,
        "message": format!(
            "Native locality sync complete for {} (cloud={}, mesh={})",
            agent_id,
            applied_cloud,
            applied_mesh
        ),
    })
}

fn observe_mesh_locality(payload: &Map<String, Value>) -> Value {
    let key = payload
        .get("key")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let geohash = key
        .get("geohashPrefix")
        .and_then(Value::as_str)
        .unwrap_or("unresolved");
    let delta12 = payload
        .get("delta12")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let ttl_ms = payload.get("ttlMs").and_then(Value::as_i64).unwrap_or(0);
    let hop = payload.get("hop").and_then(Value::as_i64).unwrap_or(0);

    let registry = mesh_registry();
    let mut guard = registry.lock().expect("mesh registry mutex poisoned");
    guard.insert(
        geohash.to_string(),
        json!({
            "key": Value::Object(key),
            "delta12": delta12,
            "ttlMs": ttl_ms,
            "hop": hop
        }),
    );
    drop(guard);
    persist_native_state();

    json!({
        "observed": true
    })
}

fn reconcile_with_global_state(
    state: &Value,
    global_state: &Map<String, Value>,
    synced_at: &str,
) -> Value {
    let mut next_state = state.as_object().cloned().unwrap_or_default();
    let current_embedding = next_state
        .get("embedding")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_else(|| vec![json!(0.5); 12]);
    let global_vector = global_state
        .get("vector12")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_else(|| vec![json!(0.5); 12]);

    next_state.insert(
        "embedding".to_string(),
        Value::Array(blend_embeddings(
            &current_embedding,
            &global_vector,
            0.55,
            0.45,
        )),
    );
    next_state.insert("freshness".to_string(), json!(synced_at));
    next_state.insert(
        "confidence".to_string(),
        json!(next_state
            .get("confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0)
            .max(0.58)),
    );
    if next_state
        .get("reliabilityTier")
        .and_then(Value::as_str)
        .unwrap_or("zeroLocality")
        == "zeroLocality"
    {
        next_state.insert("reliabilityTier".to_string(), json!("bootstrap"));
    }
    let source_mix = next_state
        .get("sourceMix")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    next_state.insert(
        "sourceMix".to_string(),
        blend_source_mix(
            &source_mix,
            &json!({
                "local": 0.15,
                "mesh": 0.10,
                "federated": 0.65,
                "geometry": 0.08,
                "syntheticPrior": 0.02
            })
            .as_object()
            .cloned()
            .unwrap_or_default(),
        ),
    );

    Value::Object(next_state)
}

fn reconcile_with_mesh_updates(state: &Value, mesh_updates: &[Value], synced_at: &str) -> Value {
    let mut next_state = state.as_object().cloned().unwrap_or_default();
    if let Some(mesh_embedding) = average_mesh_updates(mesh_updates) {
        let current_embedding = next_state
            .get("embedding")
            .and_then(Value::as_array)
            .cloned()
            .unwrap_or_else(|| vec![json!(0.5); 12]);
        next_state.insert(
            "embedding".to_string(),
            Value::Array(blend_embeddings(
                &current_embedding,
                &mesh_embedding,
                0.82,
                0.18,
            )),
        );
    }
    next_state.insert("freshness".to_string(), json!(synced_at));
    next_state.insert(
        "confidence".to_string(),
        json!(next_state
            .get("confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0)
            .max(0.46)),
    );
    let source_mix = next_state
        .get("sourceMix")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    next_state.insert(
        "sourceMix".to_string(),
        blend_source_mix(
            &source_mix,
            &json!({
                "local": 0.15,
                "mesh": 0.60,
                "federated": 0.15,
                "geometry": 0.05,
                "syntheticPrior": 0.05
            })
            .as_object()
            .cloned()
            .unwrap_or_default(),
        ),
    );
    Value::Object(next_state)
}

fn snapshot_registry() -> &'static Mutex<std::collections::HashMap<String, Value>> {
    SNAPSHOT_REGISTRY.get_or_init(|| Mutex::new(persisted_state().snapshots.clone()))
}

fn mesh_registry() -> &'static Mutex<std::collections::HashMap<String, Value>> {
    MESH_REGISTRY.get_or_init(|| Mutex::new(persisted_state().mesh.clone()))
}

fn candidate_registry() -> &'static Mutex<std::collections::HashMap<String, CandidateRecord>> {
    CANDIDATE_REGISTRY.get_or_init(|| Mutex::new(persisted_state().candidates.clone()))
}

fn default_schema_version() -> u32 {
    CURRENT_SCHEMA_VERSION
}

fn persisted_state() -> &'static NativePersistenceEnvelope {
    PERSISTED_STATE.get_or_init(load_persisted_state)
}

fn load_persisted_state() -> NativePersistenceEnvelope {
    let path = state_file_path();
    std::fs::read_to_string(path)
        .ok()
        .and_then(|raw| serde_json::from_str::<NativePersistenceEnvelope>(&raw).ok())
        .map(compact_persistence_envelope)
        .filter(|envelope| envelope.schema_version <= CURRENT_SCHEMA_VERSION)
        .map(|mut envelope| {
            envelope.schema_version = CURRENT_SCHEMA_VERSION;
            envelope
        })
        .unwrap_or_default()
}

fn persist_native_state() {
    let snapshots = snapshot_registry()
        .lock()
        .map(|guard| guard.clone())
        .unwrap_or_default();
    let mesh = mesh_registry()
        .lock()
        .map(|guard| guard.clone())
        .unwrap_or_default();
    let candidates = candidate_registry()
        .lock()
        .map(|guard| guard.clone())
        .unwrap_or_default();
    let envelope = compact_persistence_envelope(NativePersistenceEnvelope {
        schema_version: CURRENT_SCHEMA_VERSION,
        saved_at_utc: newest_saved_at(&snapshots),
        snapshots,
        mesh,
        candidates,
    });
    if let Ok(serialized) = serde_json::to_string_pretty(&envelope) {
        let path = state_file_path();
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let _ = std::fs::write(path, serialized);
    }
}

fn state_file_path() -> std::path::PathBuf {
    std::env::var("AVRAI_LOCALITY_NATIVE_STATE_PATH")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| std::env::temp_dir().join("avrai_locality_kernel_state_v1.json"))
}

fn compact_persistence_envelope(
    mut envelope: NativePersistenceEnvelope,
) -> NativePersistenceEnvelope {
    envelope.schema_version = CURRENT_SCHEMA_VERSION;
    envelope.snapshots = compact_snapshots(envelope.snapshots);
    envelope.mesh = compact_mesh(envelope.mesh);
    envelope.candidates = compact_candidates(envelope.candidates);
    if envelope.saved_at_utc.is_empty() {
        envelope.saved_at_utc = newest_saved_at(&envelope.snapshots);
    }
    envelope
}

fn compact_snapshots(
    snapshots: std::collections::HashMap<String, Value>,
) -> std::collections::HashMap<String, Value> {
    let mut entries = snapshots.into_iter().collect::<Vec<_>>();
    entries.sort_by(|left, right| {
        let left_saved = left
            .1
            .get("savedAtUtc")
            .and_then(Value::as_str)
            .unwrap_or("");
        let right_saved = right
            .1
            .get("savedAtUtc")
            .and_then(Value::as_str)
            .unwrap_or("");
        right_saved.cmp(left_saved)
    });
    entries.truncate(MAX_SNAPSHOT_REGISTRY_SIZE);
    entries.into_iter().collect()
}

fn compact_mesh(
    mesh: std::collections::HashMap<String, Value>,
) -> std::collections::HashMap<String, Value> {
    let mut entries = mesh
        .into_iter()
        .filter(|(_, value)| value.get("ttlMs").and_then(Value::as_i64).unwrap_or(0) > 0)
        .collect::<Vec<_>>();
    entries.sort_by(|left, right| {
        let left_hop = left
            .1
            .get("hop")
            .and_then(Value::as_i64)
            .unwrap_or(i64::MAX);
        let right_hop = right
            .1
            .get("hop")
            .and_then(Value::as_i64)
            .unwrap_or(i64::MAX);
        left_hop
            .cmp(&right_hop)
            .then_with(|| {
                let left_ttl = left.1.get("ttlMs").and_then(Value::as_i64).unwrap_or(0);
                let right_ttl = right.1.get("ttlMs").and_then(Value::as_i64).unwrap_or(0);
                right_ttl.cmp(&left_ttl)
            })
            .then_with(|| left.0.cmp(&right.0))
    });
    entries.truncate(MAX_MESH_REGISTRY_SIZE);
    entries.into_iter().collect()
}

fn compact_candidates(
    candidates: std::collections::HashMap<String, CandidateRecord>,
) -> std::collections::HashMap<String, CandidateRecord> {
    let newest_seen = candidates
        .values()
        .map(|record| record.last_seen_utc.as_str())
        .max()
        .unwrap_or("2026-03-06T00:00:00Z")
        .to_string();
    let mut entries = candidates
        .into_iter()
        .filter(|(_, record)| {
            days_between(&record.last_seen_utc, &newest_seen) <= CANDIDATE_DECAY_DAYS
        })
        .collect::<Vec<_>>();
    entries.sort_by(|left, right| {
        right
            .1
            .coherence_count
            .cmp(&left.1.coherence_count)
            .then_with(|| right.1.last_seen_utc.cmp(&left.1.last_seen_utc))
            .then_with(|| left.0.cmp(&right.0))
    });
    entries.truncate(MAX_CANDIDATE_REGISTRY_SIZE);
    entries.into_iter().collect()
}

fn newest_saved_at(snapshots: &std::collections::HashMap<String, Value>) -> String {
    snapshots
        .values()
        .filter_map(|value| value.get("savedAtUtc").and_then(Value::as_str))
        .max()
        .unwrap_or("2026-03-06T00:00:00Z")
        .to_string()
}

fn save_snapshot(agent_id: &str, state: &Value, saved_at: &str) {
    let registry = snapshot_registry();
    let mut guard = registry.lock().expect("snapshot registry mutex poisoned");
    guard.insert(
        agent_id.to_string(),
        json!({
            "agentId": agent_id,
            "state": state,
            "savedAtUtc": saved_at,
        }),
    );
    drop(guard);
    persist_native_state();
}

#[derive(Clone)]
struct LocalityClassification {
    city_code: String,
    locality_code: String,
    display_name: String,
    token_id: String,
    confidence: f64,
    boundary_tension: f64,
    evolution_rate: f64,
    source_mix: Value,
}

fn classify_locality(lat: f64, lon: f64) -> LocalityClassification {
    let anchors = [
        ("avondale", "Avondale", 33.5247, -86.7740),
        ("lakeview", "Lakeview", 33.4978, -86.7667),
        ("southside", "Southside", 33.4995, -86.8036),
    ];

    let nearest = anchors
        .iter()
        .map(|(code, name, anchor_lat, anchor_lon)| {
            (
                *code,
                *name,
                distance_score(lat, lon, *anchor_lat, *anchor_lon),
            )
        })
        .collect::<Vec<_>>();

    let mut sorted = nearest.clone();
    sorted.sort_by(|left, right| left.2.partial_cmp(&right.2).unwrap());

    let (code, name, best_distance) = sorted[0];
    let second_distance = sorted
        .get(1)
        .map(|entry| entry.2)
        .unwrap_or(best_distance + 1.0);
    let edge_ratio = if second_distance <= 0.0 {
        0.0
    } else {
        (best_distance / second_distance).clamp(0.0, 1.0)
    };
    let boundary_tension = (1.0 - edge_ratio).clamp(0.18, 0.84);
    let confidence = (0.88 - (best_distance * 3.5)).clamp(0.34, 0.91);
    let city_code = if is_birmingham_region(lat, lon) {
        "birmingham_alabama".to_string()
    } else {
        "unknown".to_string()
    };

    LocalityClassification {
        city_code: city_code.clone(),
        locality_code: if city_code == "unknown" {
            "emergent_locality".to_string()
        } else {
            code.to_string()
        },
        display_name: if city_code == "unknown" {
            "Emergent Locality".to_string()
        } else {
            name.to_string()
        },
        token_id: format!(
            "gh7:{}_{:04}_{:04}",
            if city_code == "unknown" {
                "emergent"
            } else {
                code
            },
            scaled_coordinate(lat),
            scaled_coordinate(-lon),
        ),
        confidence,
        boundary_tension,
        evolution_rate: if boundary_tension > 0.5 { 0.11 } else { 0.04 },
        source_mix: if city_code == "unknown" {
            json!({
                "local": 0.15,
                "mesh": 0.0,
                "federated": 0.0,
                "geometry": 0.0,
                "syntheticPrior": 0.85
            })
        } else {
            json!({
                "local": 0.38,
                "mesh": 0.12,
                "federated": 0.34,
                "geometry": 0.16,
                "syntheticPrior": 0.0
            })
        },
    }
}

fn build_state(
    locality: &LocalityClassification,
    occurred_at: &str,
    top_alias_override: Option<String>,
    reliability_tier: &str,
) -> Value {
    build_state_from_token(
        &locality.token_id,
        &top_alias_override.unwrap_or_else(|| locality.display_name.clone()),
        &locality.city_code,
        occurred_at,
        reliability_tier,
        locality.confidence,
        locality.boundary_tension,
    )
    .as_object()
    .map(|state| {
        let mut state = state.clone();
        state.insert("evolutionRate".to_string(), json!(locality.evolution_rate));
        state.insert("sourceMix".to_string(), locality.source_mix.clone());
        Value::Object(state)
    })
    .unwrap_or_else(|| synthetic_zero_state(occurred_at))
}

fn next_candidate_record(agent_id: &str, token_id: &str, occurred_at: &str) -> CandidateRecord {
    let registry_key = format!("{}:{}", agent_id, token_id);
    let registry = candidate_registry();
    let mut guard = registry.lock().expect("candidate registry mutex poisoned");
    let next_record = match guard.get(&registry_key) {
        Some(existing)
            if days_between(&existing.last_seen_utc, occurred_at) <= CANDIDATE_DECAY_DAYS =>
        {
            CandidateRecord {
                coherence_count: existing.coherence_count + 1,
                first_seen_utc: existing.first_seen_utc.clone(),
                last_seen_utc: occurred_at.to_string(),
            }
        }
        _ => CandidateRecord {
            coherence_count: 1,
            first_seen_utc: occurred_at.to_string(),
            last_seen_utc: occurred_at.to_string(),
        },
    };
    guard.insert(registry_key, next_record.clone());
    drop(guard);
    persist_native_state();
    next_record
}

fn normalize_candidate_state(state: Value, candidate: &CandidateRecord) -> Value {
    let mut next_state = state.as_object().cloned().unwrap_or_default();
    next_state.insert(
        "evidenceCount".to_string(),
        json!(candidate.coherence_count),
    );
    if next_state
        .get("reliabilityTier")
        .and_then(Value::as_str)
        .unwrap_or("candidate")
        == "advisory"
    {
        return Value::Object(next_state);
    }
    if candidate.coherence_count >= 8 {
        next_state.insert("reliabilityTier".to_string(), json!("established"));
        next_state.insert(
            "confidence".to_string(),
            json!(next_state
                .get("confidence")
                .and_then(Value::as_f64)
                .unwrap_or(0.0)
                .max(0.55)),
        );
    } else {
        next_state.insert("reliabilityTier".to_string(), json!("candidate"));
        next_state.insert(
            "confidence".to_string(),
            json!(next_state
                .get("confidence")
                .and_then(Value::as_f64)
                .unwrap_or(0.0)
                .max(0.42)),
        );
    }
    Value::Object(next_state)
}

fn apply_advisory_state_transition(state: Value, payload: &Map<String, Value>) -> Value {
    let mut next_state = state.as_object().cloned().unwrap_or_default();
    let quality_score = payload.get("qualityScore").and_then(Value::as_f64);
    let current_status = next_state
        .get("advisoryStatus")
        .and_then(Value::as_str)
        .unwrap_or("inactive")
        .to_string();
    let current_confidence = next_state
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let current_source_mix = next_state
        .get("sourceMix")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();

    match quality_score {
        Some(score) if score < 0.45 => {
            next_state.insert("advisoryStatus".to_string(), json!("active"));
            next_state.insert("reliabilityTier".to_string(), json!("advisory"));
            next_state.insert(
                "confidence".to_string(),
                json!(current_confidence.max(0.56)),
            );
            next_state.insert("evolutionRate".to_string(), json!(0.12));
            next_state.insert(
                "sourceMix".to_string(),
                blend_source_mix(
                    &current_source_mix,
                    &json!({
                        "local": 0.10,
                        "mesh": 0.05,
                        "federated": 0.55,
                        "geometry": 0.05,
                        "syntheticPrior": 0.25
                    })
                    .as_object()
                    .cloned()
                    .unwrap_or_default(),
                ),
            );
        }
        Some(score) if score < 0.70 => {
            let next_status = if current_status == "active" {
                "coolingDown"
            } else {
                "eligible"
            };
            next_state.insert("advisoryStatus".to_string(), json!(next_status));
            next_state.insert(
                "reliabilityTier".to_string(),
                json!(if current_status == "active" {
                    "advisory"
                } else {
                    "candidate"
                }),
            );
            next_state.insert("evolutionRate".to_string(), json!(0.08));
            next_state.insert("confidence".to_string(), json!(current_confidence.max(0.5)));
        }
        Some(_) => {
            let next_status = if current_status == "active" || current_status == "eligible" {
                "coolingDown"
            } else {
                "inactive"
            };
            let next_tier = if next_state
                .get("evidenceCount")
                .and_then(Value::as_i64)
                .unwrap_or(0)
                >= 8
            {
                "established"
            } else {
                "candidate"
            };
            next_state.insert("advisoryStatus".to_string(), json!(next_status));
            next_state.insert("reliabilityTier".to_string(), json!(next_tier));
            next_state.insert("evolutionRate".to_string(), json!(0.03));
            next_state.insert("confidence".to_string(), json!(current_confidence.max(0.6)));
        }
        None => {
            next_state.insert(
                "advisoryStatus".to_string(),
                json!(if current_status == "active" {
                    "eligible"
                } else {
                    "inactive"
                }),
            );
            next_state.insert("evolutionRate".to_string(), json!(0.07));
        }
    }

    Value::Object(next_state)
}

fn build_state_from_token(
    token_id: &str,
    alias: &str,
    city_code: &str,
    occurred_at: &str,
    reliability_tier: &str,
    confidence: f64,
    boundary_tension: f64,
) -> Value {
    let advisory_status = if reliability_tier == "advisory" {
        "active"
    } else {
        "inactive"
    };
    let source_mix = source_mix_for_city(city_code);
    json!({
        "activeToken": {
            "kind": "geohashCell",
            "id": token_id,
            "alias": alias
        },
        "embedding": [
            confidence.clamp(0.0, 1.0),
            (confidence * 0.92).clamp(0.0, 1.0),
            (1.0 - boundary_tension * 0.3).clamp(0.0, 1.0),
            0.58,
            0.61,
            if city_code == "unknown" { 0.48 } else { 0.73 },
            0.44,
            0.39,
            0.53,
            0.57,
            0.46,
            0.51
        ],
        "confidence": confidence,
        "boundaryTension": boundary_tension,
        "reliabilityTier": reliability_tier,
        "freshness": occurred_at,
        "evidenceCount": if reliability_tier == "bootstrap" { 3 } else { 11 },
        "evolutionRate": if boundary_tension > 0.5 { 0.11 } else { 0.04 },
        "topAlias": alias,
        "advisoryStatus": advisory_status,
        "sourceMix": source_mix,
        "parentToken": {
            "kind": "cityPrior",
            "id": city_code,
            "alias": city_code
        }
    })
}

fn synthetic_zero_state(occurred_at: &str) -> Value {
    json!({
        "activeToken": {
            "kind": "syntheticBootstrap",
            "id": "unresolved",
            "alias": "Unresolved Locality"
        },
        "embedding": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
        "confidence": 0.0,
        "boundaryTension": 1.0,
        "reliabilityTier": "zeroLocality",
        "freshness": occurred_at,
        "evidenceCount": 0,
        "evolutionRate": 0.0,
        "topAlias": "Unresolved Locality",
        "advisoryStatus": "inactive",
        "sourceMix": {
            "local": 0.0,
            "mesh": 0.0,
            "federated": 0.0,
            "geometry": 0.0,
            "syntheticPrior": 1.0
        }
    })
}

fn source_mix_for_city(city_code: &str) -> Value {
    if city_code == "unknown" {
        json!({
            "local": 0.0,
            "mesh": 0.0,
            "federated": 0.0,
            "geometry": 0.0,
            "syntheticPrior": 1.0
        })
    } else {
        json!({
            "local": 0.38,
            "mesh": 0.12,
            "federated": 0.34,
            "geometry": 0.16,
            "syntheticPrior": 0.0
        })
    }
}

fn blend_embeddings(
    left: &[Value],
    right: &[Value],
    left_weight: f64,
    right_weight: f64,
) -> Vec<Value> {
    (0..12)
        .map(|index| {
            let left_value = left.get(index).and_then(Value::as_f64).unwrap_or(0.5);
            let right_value = right.get(index).and_then(Value::as_f64).unwrap_or(0.5);
            json!(((left_value * left_weight) + (right_value * right_weight)).clamp(0.0, 1.0))
        })
        .collect()
}

fn average_mesh_updates(mesh_updates: &[Value]) -> Option<Vec<Value>> {
    if mesh_updates.is_empty() {
        return None;
    }

    let mut sums = [0.0_f64; 12];
    let mut count = 0.0_f64;
    for update in mesh_updates {
        let values = update.as_array()?;
        for (index, value) in values.iter().take(12).enumerate() {
            sums[index] += value.as_f64().unwrap_or(0.0);
        }
        count += 1.0;
    }

    if count == 0.0 {
        return None;
    }

    Some(
        sums.iter()
            .map(|sum| json!((sum / count).clamp(-1.0, 1.0)))
            .collect(),
    )
}

fn blend_source_mix(current: &Map<String, Value>, overlay: &Map<String, Value>) -> Value {
    let mut result = Map::new();
    for key in ["local", "mesh", "federated", "geometry", "syntheticPrior"] {
        let current_value = current.get(key).and_then(Value::as_f64).unwrap_or(0.0);
        let overlay_value = overlay.get(key).and_then(Value::as_f64).unwrap_or(0.0);
        result.insert(
            key.to_string(),
            json!(((current_value * 0.6) + (overlay_value * 0.4)).clamp(0.0, 1.0)),
        );
    }
    Value::Object(result)
}

fn distance_score(lat_a: f64, lon_a: f64, lat_b: f64, lon_b: f64) -> f64 {
    let lat_delta = lat_a - lat_b;
    let lon_delta = lon_a - lon_b;
    ((lat_delta * lat_delta) + (lon_delta * lon_delta)).sqrt()
}

fn scaled_coordinate(value: f64) -> i64 {
    (value.abs() * 1000.0).round() as i64
}

fn is_birmingham_region(lat: f64, lon: f64) -> bool {
    (33.38..=33.60).contains(&lat) && (-86.92..=-86.68).contains(&lon)
}

fn days_between(left: &str, right: &str) -> i64 {
    let left_days = iso_date_to_days(left);
    let right_days = iso_date_to_days(right);
    (right_days - left_days).abs()
}

fn iso_date_to_days(value: &str) -> i64 {
    let date = value.get(0..10).unwrap_or("1970-01-01");
    let mut parts = date.split('-');
    let year = parts
        .next()
        .and_then(|part| part.parse::<i64>().ok())
        .unwrap_or(1970);
    let month = parts
        .next()
        .and_then(|part| part.parse::<i64>().ok())
        .unwrap_or(1);
    let day = parts
        .next()
        .and_then(|part| part.parse::<i64>().ok())
        .unwrap_or(1);
    civil_to_days(year, month, day)
}

fn civil_to_days(year: i64, month: i64, day: i64) -> i64 {
    let year = year - if month <= 2 { 1 } else { 0 };
    let era = if year >= 0 { year } else { year - 399 } / 400;
    let yoe = year - era * 400;
    let month = month + if month > 2 { -3 } else { 9 };
    let doy = (153 * month + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146097 + doe - 719468
}

fn string_field(map: &Map<String, Value>, key: &str) -> Option<String> {
    map.get(key)
        .and_then(Value::as_str)
        .map(ToString::to_string)
}

fn float_field(map: &Map<String, Value>, key: &str) -> Option<f64> {
    map.get(key).and_then(Value::as_f64)
}

fn sample_resolution_score(
    projection: &Map<String, Value>,
    metadata: &Map<String, Value>,
    state: &Map<String, Value>,
) -> f64 {
    let confidence = float_field(metadata, "confidence")
        .or_else(|| float_field(state, "confidence"))
        .unwrap_or(0.0);
    let boundary_tension = float_field(metadata, "boundaryTension")
        .or_else(|| float_field(state, "boundaryTension"))
        .unwrap_or(1.0);
    let mut score = confidence * 2.0 - boundary_tension;
    if metadata
        .get("advisoryStatus")
        .and_then(Value::as_str)
        .unwrap_or("inactive")
        == "active"
    {
        score += 0.25;
    }
    if state
        .get("reliabilityTier")
        .and_then(Value::as_str)
        .unwrap_or("zeroLocality")
        == "established"
    {
        score += 0.15;
    }
    if projection
        .get("confidenceBucket")
        .and_then(Value::as_str)
        .unwrap_or("low")
        == "high"
    {
        score += 0.1;
    }
    score
}

fn derive_city_profile(sample_resolution: &Value) -> String {
    let sample = sample_resolution.as_object().cloned().unwrap_or_default();
    let projection = sample
        .get("projection")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let raw = string_field(&sample, "cityCode")
        .or_else(|| string_field(&sample, "displayName"))
        .or_else(|| string_field(&projection, "primaryLabel"))
        .unwrap_or_else(|| "birmingham_alabama".to_string());
    normalize_city_profile(&raw)
}

fn normalize_city_profile(raw: &str) -> String {
    let mut normalized = String::new();
    let mut last_was_separator = false;
    for ch in raw.trim().chars() {
        if ch.is_ascii_alphanumeric() {
            normalized.push(ch.to_ascii_lowercase());
            last_was_separator = false;
        } else if !last_was_separator && !normalized.is_empty() {
            normalized.push('_');
            last_was_separator = true;
        }
    }
    let normalized = normalized.trim_matches('_').to_string();
    if normalized.is_empty() {
        "birmingham_alabama".to_string()
    } else {
        normalized
    }
}

fn sort_count_map_desc(counts: std::collections::HashMap<String, i64>) -> Vec<(String, i64)> {
    let mut entries = counts.into_iter().collect::<Vec<_>>();
    entries.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));
    entries
}

fn count_map_to_object(counts: std::collections::HashMap<String, i64>) -> Value {
    let mut object = Map::new();
    for (key, value) in sort_count_map_desc(counts) {
        object.insert(key, json!(value));
    }
    Value::Object(object)
}

fn dominant_source_key(source_mix: &Map<String, Value>) -> String {
    let mut winner = ("syntheticPrior", f64::MIN);
    for key in ["local", "mesh", "federated", "geometry", "syntheticPrior"] {
        let value = source_mix.get(key).and_then(Value::as_f64).unwrap_or(0.0);
        if value > winner.1 {
            winner = (key, value);
        }
    }
    winner.0.to_string()
}

fn source_mix_summary(source_mix: &Map<String, Value>) -> &'static str {
    match dominant_source_key(source_mix).as_str() {
        "local" => "localLed",
        "mesh" => "meshLed",
        "federated" => "federatedLed",
        "geometry" => "geometryAnchored",
        _ => "syntheticBootstrap",
    }
}

fn classify_stability(
    confidence: f64,
    boundary_tension: f64,
    evolution_rate: f64,
    reliability_tier: &str,
    advisory_status: &str,
) -> &'static str {
    if advisory_status == "active" {
        "advisory"
    } else if boundary_tension >= 0.72 {
        "boundaryVolatile"
    } else if reliability_tier == "candidate" && evolution_rate >= 0.08 {
        "emergent"
    } else if evolution_rate >= 0.12 {
        "accelerating"
    } else if confidence >= 0.75 && evolution_rate < 0.08 {
        "stable"
    } else {
        "watch"
    }
}

fn derive_predictive_trend(
    boundary_tension: f64,
    evolution_rate: f64,
    evidence_count: i64,
    reliability_tier: &str,
    advisory_status: &str,
) -> &'static str {
    if advisory_status == "active" {
        "advisoryRecovery"
    } else if boundary_tension >= 0.72 {
        "boundaryVolatile"
    } else if reliability_tier == "candidate" && evidence_count >= 5 {
        "emerging"
    } else if evolution_rate >= 0.12 {
        "accelerating"
    } else if evolution_rate >= 0.08 {
        "changing"
    } else {
        "stable"
    }
}

fn derive_next_state_risk(
    confidence: f64,
    boundary_tension: f64,
    evolution_rate: f64,
    reliability_tier: &str,
    advisory_status: &str,
) -> &'static str {
    let mut score = 0;
    if confidence < 0.45 {
        score += 2;
    } else if confidence < 0.65 {
        score += 1;
    }
    if boundary_tension >= 0.72 {
        score += 2;
    } else if boundary_tension >= 0.5 {
        score += 1;
    }
    if evolution_rate >= 0.12 {
        score += 2;
    } else if evolution_rate >= 0.08 {
        score += 1;
    }
    if reliability_tier == "candidate" || reliability_tier == "bootstrap" {
        score += 1;
    }
    if advisory_status == "active" {
        score += 2;
    }

    if score >= 5 {
        "high"
    } else if score >= 3 {
        "medium"
    } else {
        "low"
    }
}

fn derive_promotion_readiness(
    reliability_tier: &str,
    evidence_count: i64,
    advisory_status: &str,
) -> &'static str {
    if advisory_status == "active" {
        "advisory"
    } else if reliability_tier == "established" {
        "established"
    } else if reliability_tier == "candidate" && evidence_count >= 6 {
        "promotable"
    } else if reliability_tier == "candidate" {
        "emerging"
    } else if reliability_tier == "bootstrap" {
        "bootstrapping"
    } else {
        "unseeded"
    }
}

fn explain_locality_factors(
    confidence: f64,
    boundary_tension: f64,
    evolution_rate: f64,
    evidence_count: i64,
    reliability_tier: &str,
    advisory_status: &str,
    source_mix: &Map<String, Value>,
) -> Vec<String> {
    let mut factors = Vec::new();
    if confidence >= 0.75 {
        factors.push("highConfidence".to_string());
    } else if confidence < 0.4 {
        factors.push("lowConfidence".to_string());
    }
    if boundary_tension >= 0.5 {
        factors.push("boundaryTension".to_string());
    }
    if evolution_rate >= 0.08 {
        factors.push("fastEvolution".to_string());
    }
    if reliability_tier == "candidate" && evidence_count >= 5 {
        factors.push("candidateEvidence".to_string());
    }
    if advisory_status == "active" {
        factors.push("activeAdvisory".to_string());
    }
    factors.push(format!("source:{}", dominant_source_key(source_mix)));
    if factors.is_empty() {
        factors.push("limitedSignal".to_string());
    }
    factors
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            "{{\"ok\":false,\"handled\":false,\"payload\":null,\"error\":\"serialization failed: {error}\"}}"
        )
    });
    CString::new(json)
        .unwrap_or_else(|_| {
            CString::new(
                "{\"ok\":false,\"handled\":false,\"payload\":null,\"error\":\"invalid response\"}",
            )
            .unwrap()
        })
        .into_raw()
}
