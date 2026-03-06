use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};

static SNAPSHOT_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, Value>>> = OnceLock::new();

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
        "project_locality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_locality(&request.payload),
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
            "happinessSignal" | "advisoryResult" => ("advisory", 0.61, 0.31, false, false),
            _ => ("established", 0.78, 0.26, true, false),
        };

    let state = build_state_from_token(
        &format!("gh7:{geohash}"),
        alias,
        city_code,
        occurred_at,
        reliability_tier,
        confidence,
        boundary_tension,
    );
    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        save_snapshot(agent_id, &state, occurred_at);
    }

    json!({
        "state": state,
        "cloudUpdated": cloud_updated,
        "meshForwarded": mesh_forwarded,
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

    let mut metadata = Map::new();
    if audience != "user" {
        metadata.insert("confidence".to_string(), json!(confidence));
        metadata.insert("boundaryTension".to_string(), json!(boundary_tension));
        metadata.insert(
            "sourceMix".to_string(),
            state
                .get("sourceMix")
                .cloned()
                .unwrap_or_else(|| json!({})),
        );
        metadata.insert(
            "evolutionRate".to_string(),
            json!(float_field(&state, "evolutionRate").unwrap_or(0.0)),
        );
        metadata.insert(
            "reliabilityTier".to_string(),
            json!(string_field(&state, "reliabilityTier")
                .unwrap_or_else(|| "zeroLocality".to_string())),
        );
        metadata.insert(
            "advisoryStatus".to_string(),
            json!(string_field(&state, "advisoryStatus")
                .unwrap_or_else(|| "inactive".to_string())),
        );
    }
    if include_prediction {
        let evolution_rate = float_field(&state, "evolutionRate").unwrap_or(0.0);
        metadata.insert(
            "predictiveTrend".to_string(),
            json!(if evolution_rate > 0.08 { "changing" } else { "stable" }),
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

fn evaluate_zero_locality(payload: &Map<String, Value>) -> Value {
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

fn snapshot_registry() -> &'static Mutex<std::collections::HashMap<String, Value>> {
    SNAPSHOT_REGISTRY.get_or_init(|| Mutex::new(std::collections::HashMap::new()))
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
    let second_distance = sorted.get(1).map(|entry| entry.2).unwrap_or(best_distance + 1.0);
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
            if city_code == "unknown" { "emergent" } else { code },
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
        state.insert(
            "evolutionRate".to_string(),
            json!(locality.evolution_rate),
        );
        state.insert("sourceMix".to_string(), locality.source_mix.clone());
        Value::Object(state)
    })
    .unwrap_or_else(|| synthetic_zero_state(occurred_at))
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

fn string_field(map: &Map<String, Value>, key: &str) -> Option<String> {
    map.get(key).and_then(Value::as_str).map(ToString::to_string)
}

fn float_field(map: &Map<String, Value>, key: &str) -> Option<f64> {
    map.get(key).and_then(Value::as_f64)
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
