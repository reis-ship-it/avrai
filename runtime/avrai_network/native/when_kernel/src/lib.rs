use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

static HISTORICAL_EVIDENCE_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, StoredArtifact>>> =
    OnceLock::new();
static FORECAST_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, StoredArtifact>>> =
    OnceLock::new();
static RUNTIME_EVENT_REGISTRY: OnceLock<Mutex<std::collections::HashMap<String, StoredArtifact>>> =
    OnceLock::new();

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

#[derive(Debug, Serialize)]
struct NativeTemporalInstant {
    referenceTime: String,
    civilTime: String,
    timezoneId: String,
    provenance: NativeTemporalProvenance,
    uncertainty: NativeTemporalUncertainty,
    monotonicTicks: i64,
}

#[derive(Debug, Serialize)]
struct NativeTemporalProvenance {
    authority: &'static str,
    source: &'static str,
}

#[derive(Debug, Serialize)]
struct NativeTemporalUncertainty {
    windowMicros: i64,
    confidence: f64,
}

#[derive(Debug, Clone)]
struct StoredArtifact {
    payload: Value,
    recorded_at: Value,
}

#[no_mangle]
pub extern "C" fn avrai_when_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_when_kernel_free_string(ptr: *mut c_char) {
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
        "now" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "instant": native_instant_from_payload(&request.payload)?,
            }),
            error: None,
        }),
        "snapshot" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_payload(&request.payload)?,
            error: None,
        }),
        "freshness_of" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: freshness_payload(&request.payload)?,
            error: None,
        }),
        "compare" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: compare_payload(&request.payload)?,
            error: None,
        }),
        "compare_when" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: compare_when_payload(&request.payload)?,
            error: None,
        }),
        "validate_window" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: validate_window_payload(&request.payload)?,
            error: None,
        }),
        "snapshot_when" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_when_payload(&request.payload)?,
            error: None,
        }),
        "reconcile_timestamps" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: reconcile_timestamps_payload(&request.payload)?,
            error: None,
        }),
        "replay_when" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: replay_when_payload(&request.payload)?,
            error: None,
        }),
        "project_when_reality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_when_reality_payload(&request.payload)?,
            error: None,
        }),
        "project_when_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_when_governance_payload(&request.payload)?,
            error: None,
        }),
        "record_historical_evidence" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_historical_evidence_payload(&request.payload)?,
            error: None,
        }),
        "get_historical_evidence" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: get_historical_evidence_payload(&request.payload)?,
            error: None,
        }),
        "record_forecast" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_forecast_payload(&request.payload)?,
            error: None,
        }),
        "get_forecast" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: get_forecast_payload(&request.payload)?,
            error: None,
        }),
        "record_runtime_event" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_runtime_event_payload(&request.payload)?,
            error: None,
        }),
        "record_when_event" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_when_event_payload(&request.payload)?,
            error: None,
        }),
        "get_runtime_event" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: get_runtime_event_payload(&request.payload)?,
            error: None,
        }),
        "query_runtime_events" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: query_runtime_events_payload(&request.payload)?,
            error: None,
        }),
        "query_when_events" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: query_when_events_payload(&request.payload)?,
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

fn snapshot_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let now = native_instant_from_payload(payload)?;
    let now_value = serde_json::to_value(&now)
        .map_err(|error| format!("instant encode failed: {error}"))?;
    let effective_at = payload
        .get("effectiveAt")
        .cloned()
        .unwrap_or_else(|| now_value.clone());
    let expires_at = payload.get("expiresAt").cloned().unwrap_or(Value::Null);
    let lineage_ref = payload.get("lineageRef").cloned().unwrap_or(Value::Null);
    let cadence = payload.get("cadence").cloned().unwrap_or(Value::Null);

    Ok(json!({
        "snapshot": {
            "observedAt": now_value.clone(),
            "recordedAt": now_value,
            "effectiveAt": effective_at,
            "expiresAt": expires_at,
            "semanticBand": semantic_band_for_micros(extract_reference_micros(payload)?.unwrap_or(unix_epoch_micros()?)),
            "cadence": cadence,
            "lineageRef": lineage_ref,
        }
    }))
}

fn freshness_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .ok_or_else(|| "freshness_of missing snapshot".to_string())?;
    let observed_at = snapshot
        .get("observedAt")
        .and_then(Value::as_object)
        .ok_or_else(|| "freshness_of missing observedAt".to_string())?;
    let observed_ref = observed_at
        .get("referenceTime")
        .and_then(Value::as_str)
        .ok_or_else(|| "freshness_of missing observedAt.referenceTime".to_string())?;

    let policy = payload
        .get("policy")
        .and_then(Value::as_object)
        .ok_or_else(|| "freshness_of missing policy".to_string())?;
    let max_age_micros = policy
        .get("maxAgeMicros")
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let max_future_skew_micros = policy
        .get("maxFutureSkewMicros")
        .and_then(Value::as_i64)
        .unwrap_or(0);

    let observed_micros = parse_iso8601_micros(observed_ref)?;
    let now_micros = unix_epoch_micros()?;
    let age = now_micros - observed_micros;
    let is_from_future = age < 0;
    let normalized_age = age.abs();
    let is_fresh = if is_from_future {
        normalized_age <= max_future_skew_micros
    } else {
        normalized_age <= max_age_micros
    };

    Ok(json!({
        "freshness": {
            "ageMicros": age,
            "isFresh": is_fresh,
            "isFromFuture": is_from_future,
        }
    }))
}

fn compare_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let left = payload
        .get("left")
        .and_then(Value::as_object)
        .ok_or_else(|| "compare missing left".to_string())?;
    let right = payload
        .get("right")
        .and_then(Value::as_object)
        .ok_or_else(|| "compare missing right".to_string())?;
    let left_ref = extract_snapshot_reference_micros(left)?;
    let right_ref = extract_snapshot_reference_micros(right)?;
    let delta = left_ref - right_ref;
    let relation = if delta < 0 {
        "before"
    } else if delta > 0 {
        "after"
    } else {
        "equal"
    };

    Ok(json!({
        "ordering": {
            "relation": relation,
            "deltaMicros": delta,
        }
    }))
}

fn compare_when_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let left = payload
        .get("left")
        .and_then(Value::as_object)
        .ok_or_else(|| "compare_when missing left".to_string())?;
    let right = payload
        .get("right")
        .and_then(Value::as_object)
        .ok_or_else(|| "compare_when missing right".to_string())?;
    let left_ref = left
        .get("observed_at_utc")
        .and_then(Value::as_str)
        .ok_or_else(|| "compare_when missing left.observed_at_utc".to_string())?;
    let right_ref = right
        .get("observed_at_utc")
        .and_then(Value::as_str)
        .ok_or_else(|| "compare_when missing right.observed_at_utc".to_string())?;
    let left_micros = parse_iso8601_micros(left_ref)?;
    let right_micros = parse_iso8601_micros(right_ref)?;
    let delta = right_micros - left_micros;
    Ok(json!({
        "ordered_ascending": left_micros <= right_micros,
        "delta_ms": delta / 1000,
    }))
}

fn validate_window_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let timestamp = payload
        .get("timestamp")
        .and_then(Value::as_object)
        .ok_or_else(|| "validate_window missing timestamp".to_string())?;
    let observed_at = timestamp
        .get("observed_at_utc")
        .and_then(Value::as_str)
        .ok_or_else(|| "validate_window missing timestamp.observed_at_utc".to_string())?;
    let observed_micros = parse_iso8601_micros(observed_at)?;
    let effective_micros = payload
        .get("effective_at_utc")
        .and_then(Value::as_str)
        .map(parse_iso8601_micros)
        .transpose()?
        .unwrap_or(observed_micros);
    let expires_micros = payload
        .get("expires_at_utc")
        .and_then(Value::as_str)
        .map(parse_iso8601_micros)
        .transpose()?
        .unwrap_or(observed_micros + 4 * 60 * 60 * 1_000_000);
    let allowed_drift_ms = payload
        .get("allowed_drift_ms")
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let drift_ms = ((observed_micros - effective_micros).abs()) / 1000;
    let valid = observed_micros >= effective_micros
        && observed_micros <= expires_micros
        && drift_ms <= allowed_drift_ms;
    Ok(json!({
        "valid": valid,
        "reason": if valid { "within_validity_window" } else { "outside_validity_window" },
        "observed_drift_ms": drift_ms,
    }))
}

fn snapshot_when_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_runtime");
    let snapshot = snapshot_payload(&Map::from_iter(vec![
        ("lineageRef".to_string(), json!(format!("when:{subject_id}"))),
    ]))?;
    let snapshot_map = snapshot
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let observed_at = snapshot_map
        .get("observedAt")
        .and_then(Value::as_object)
        .and_then(|instant| instant.get("referenceTime"))
        .and_then(Value::as_str)
        .unwrap_or("1970-01-01T00:00:00.000000Z");
    let effective_at = snapshot_map
        .get("effectiveAt")
        .and_then(Value::as_object)
        .and_then(|instant| instant.get("referenceTime"))
        .and_then(Value::as_str)
        .unwrap_or(observed_at);
    let expires_at = snapshot_map
        .get("expiresAt")
        .and_then(Value::as_object)
        .and_then(|instant| instant.get("referenceTime"))
        .and_then(Value::as_str)
        .unwrap_or(observed_at);
    Ok(json!({
        "observed_at": observed_at,
        "effective_at": effective_at,
        "expires_at": expires_at,
        "freshness": 1.0,
        "cadence": snapshot_map.get("cadence").cloned().unwrap_or(Value::Null),
        "recency_bucket": "immediate",
        "timing_conflict_flags": [],
        "temporal_confidence": 0.95,
    }))
}

fn reconcile_timestamps_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let timestamps = payload
        .get("timestamps")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let canonical = timestamps
        .iter()
        .filter_map(Value::as_object)
        .max_by_key(|entry| {
            entry.get("observed_at_utc")
                .and_then(Value::as_str)
                .and_then(|value| parse_iso8601_micros(value).ok())
                .unwrap_or(0)
        })
        .cloned()
        .unwrap_or_else(|| {
            let now = chrono_like_iso8601(unix_epoch_micros().unwrap_or(0));
            Map::from_iter(vec![
                ("reference_id".to_string(), json!("when:bootstrap")),
                ("observed_at_utc".to_string(), json!(now)),
                ("quantum_atomic_tick".to_string(), json!(unix_epoch_micros().unwrap_or(0))),
                ("confidence".to_string(), json!(0.0)),
            ])
        });
    Ok(json!({
        "canonical_timestamp": canonical,
        "conflict_count": if timestamps.len() <= 1 { 0 } else { timestamps.len() - 1 },
        "summary": if timestamps.len() <= 1 {
            "no reconciliation required"
        } else {
            "selected latest timestamp as canonical reference"
        },
    }))
}

fn replay_when_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_runtime");
    let snapshot = snapshot_when_payload(&Map::from_iter(vec![(
        "subject_id".to_string(),
        json!(subject_id),
    )]))?;
    Ok(json!({
        "records": [
            {
                "domain": "when",
                "record_id": format!("when:{subject_id}"),
                "occurred_at_utc": snapshot.get("observed_at").cloned().unwrap_or_else(|| json!(chrono_like_iso8601(unix_epoch_micros().unwrap_or(0)))),
                "summary": format!("Temporal replay for {subject_id}"),
                "payload": snapshot,
            }
        ]
    }))
}

fn project_when_reality_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("runtime");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .map(Value::Object)
        .unwrap_or(snapshot_when_payload(&Map::from_iter(vec![(
            "subject_id".to_string(),
            json!(subject_id),
        )]))?);
    let snapshot_obj = snapshot.as_object().cloned().unwrap_or_default();
    Ok(json!({
        "summary": format!(
            "Temporal ordering at {}",
            snapshot_obj
                .get("observed_at")
                .and_then(Value::as_str)
                .unwrap_or("unknown_time")
        ),
        "confidence": snapshot_obj
            .get("temporal_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0),
        "features": {
            "recency_bucket": snapshot_obj.get("recency_bucket").cloned().unwrap_or(Value::Null),
            "freshness": snapshot_obj.get("freshness").cloned().unwrap_or(Value::Null),
            "conflict_flags": snapshot_obj.get("timing_conflict_flags").cloned().unwrap_or_else(|| json!([])),
        },
        "payload": snapshot_obj,
    }))
}

fn project_when_governance_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("runtime");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .map(Value::Object)
        .unwrap_or(snapshot_when_payload(&Map::from_iter(vec![(
            "subject_id".to_string(),
            json!(subject_id),
        )]))?);
    let snapshot_obj = snapshot.as_object().cloned().unwrap_or_default();
    Ok(json!({
        "domain": "when",
        "summary": format!("Temporal governance view for {subject_id}"),
        "confidence": snapshot_obj
            .get("temporal_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0),
        "highlights": snapshot_obj.get("timing_conflict_flags").cloned().unwrap_or_else(|| json!([])),
        "payload": snapshot_obj,
    }))
}

fn record_historical_evidence_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let evidence = payload
        .get("evidence")
        .and_then(Value::as_object)
        .ok_or_else(|| "record_historical_evidence missing evidence".to_string())?;
    let evidence_id = evidence
        .get("evidenceId")
        .and_then(Value::as_str)
        .unwrap_or("unknown_evidence");
    let instant = serde_json::to_value(native_instant()?)
        .map_err(|error| format!("instant encode failed: {error}"))?;
    historical_registry()
        .lock()
        .map_err(|_| "historical registry lock poisoned".to_string())?
        .insert(
            evidence_id.to_string(),
            StoredArtifact {
                payload: Value::Object(evidence.clone()),
                recorded_at: instant.clone(),
            },
        );
    Ok(json!({
        "evidenceId": evidence_id,
        "instant": instant,
    }))
}

fn get_historical_evidence_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let evidence_id = payload
        .get("evidenceId")
        .and_then(Value::as_str)
        .unwrap_or("");
    let registry = historical_registry()
        .lock()
        .map_err(|_| "historical registry lock poisoned".to_string())?;
    if let Some(stored) = registry.get(evidence_id) {
        return Ok(json!({
            "found": true,
            "evidence": stored.payload,
            "instant": stored.recorded_at,
        }));
    }
    Ok(json!({
        "found": false,
        "instant": native_instant()?,
    }))
}

fn record_forecast_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let claim = payload
        .get("claim")
        .and_then(Value::as_object)
        .ok_or_else(|| "record_forecast missing claim".to_string())?;
    let claim_id = claim
        .get("claimId")
        .and_then(Value::as_str)
        .unwrap_or("unknown_claim");
    let instant = serde_json::to_value(native_instant()?)
        .map_err(|error| format!("instant encode failed: {error}"))?;
    forecast_registry()
        .lock()
        .map_err(|_| "forecast registry lock poisoned".to_string())?
        .insert(
            claim_id.to_string(),
            StoredArtifact {
                payload: Value::Object(claim.clone()),
                recorded_at: instant.clone(),
            },
        );
    Ok(json!({
        "claimId": claim_id,
        "instant": instant,
    }))
}

fn get_forecast_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let claim_id = payload
        .get("claimId")
        .and_then(Value::as_str)
        .unwrap_or("");
    let registry = forecast_registry()
        .lock()
        .map_err(|_| "forecast registry lock poisoned".to_string())?;
    if let Some(stored) = registry.get(claim_id) {
        return Ok(json!({
            "found": true,
            "claim": stored.payload,
            "instant": stored.recorded_at,
        }));
    }
    Ok(json!({
        "found": false,
        "instant": native_instant()?,
    }))
}

fn record_runtime_event_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let event = payload
        .get("event")
        .and_then(Value::as_object)
        .ok_or_else(|| "record_runtime_event missing event".to_string())?;
    let event_id = event
        .get("eventId")
        .and_then(Value::as_str)
        .unwrap_or("unknown_runtime_event");
    let instant = serde_json::to_value(native_instant()?)
        .map_err(|error| format!("instant encode failed: {error}"))?;
    runtime_event_registry()
        .lock()
        .map_err(|_| "runtime event registry lock poisoned".to_string())?
        .insert(
            event_id.to_string(),
            StoredArtifact {
                payload: Value::Object(event.clone()),
                recorded_at: instant.clone(),
            },
        );
    Ok(json!({
        "eventId": event_id,
        "instant": instant,
    }))
}

fn record_when_event_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let event_id = payload
        .get("event_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_when_event");
    let instant = serde_json::to_value(native_instant()?)
        .map_err(|error| format!("instant encode failed: {error}"))?;
    runtime_event_registry()
        .lock()
        .map_err(|_| "runtime event registry lock poisoned".to_string())?
        .insert(
            event_id.to_string(),
            StoredArtifact {
                payload: Value::Object(payload.clone()),
                recorded_at: instant.clone(),
            },
        );
    Ok(json!({
        "event_id": event_id,
        "runtime_id": payload.get("runtime_id").cloned().unwrap_or_else(|| json!("unknown_runtime")),
        "occurred_at_utc": payload.get("occurred_at_utc").cloned().unwrap_or_else(|| json!(chrono_like_iso8601(unix_epoch_micros().unwrap_or(0)))),
        "stratum": payload.get("stratum").cloned().unwrap_or_else(|| json!("personal")),
        "payload": payload.get("payload").cloned().unwrap_or_else(|| json!({})),
    }))
}

fn get_runtime_event_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let event_id = payload
        .get("eventId")
        .and_then(Value::as_str)
        .unwrap_or("");
    let registry = runtime_event_registry()
        .lock()
        .map_err(|_| "runtime event registry lock poisoned".to_string())?;
    if let Some(stored) = registry.get(event_id) {
        return Ok(json!({
            "found": true,
            "event": stored.payload,
            "instant": stored.recorded_at,
        }));
    }
    Ok(json!({
        "found": false,
        "instant": native_instant()?,
    }))
}

fn query_runtime_events_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let source = payload.get("source").and_then(Value::as_str);
    let stage = payload.get("stage").and_then(Value::as_str);
    let peer_id = payload.get("peerId").and_then(Value::as_str);
    let occurred_after = payload
        .get("occurredAfter")
        .and_then(Value::as_str)
        .map(parse_iso8601_micros)
        .transpose()?;
    let occurred_before = payload
        .get("occurredBefore")
        .and_then(Value::as_str)
        .map(parse_iso8601_micros)
        .transpose()?;
    let limit = payload.get("limit").and_then(Value::as_u64).unwrap_or(50) as usize;

    let registry = runtime_event_registry()
        .lock()
        .map_err(|_| "runtime event registry lock poisoned".to_string())?;

    let mut matches: Vec<Value> = registry
        .values()
        .filter_map(|stored| {
            let event = stored.payload.as_object()?;
            if let Some(source_filter) = source {
                if event.get("source").and_then(Value::as_str) != Some(source_filter) {
                    return None;
                }
            }
            if let Some(stage_filter) = stage {
                if event.get("stage").and_then(Value::as_str) != Some(stage_filter) {
                    return None;
                }
            }
            if let Some(peer_filter) = peer_id {
                if event.get("peerId").and_then(Value::as_str) != Some(peer_filter) {
                    return None;
                }
            }
            let occurred_at = event
                .get("occurredAt")
                .and_then(Value::as_str)
                .and_then(|value| parse_iso8601_micros(value).ok())?;
            if let Some(after) = occurred_after {
                if occurred_at <= after {
                    return None;
                }
            }
            if let Some(before) = occurred_before {
                if occurred_at >= before {
                    return None;
                }
            }
            Some(json!({
                "event": stored.payload,
                "recordedAt": stored.recorded_at,
                "occurredAtMicros": occurred_at,
            }))
        })
        .collect();

    matches.sort_by(|a, b| {
        let a_micros = a.get("occurredAtMicros").and_then(Value::as_i64).unwrap_or(0);
        let b_micros = b.get("occurredAtMicros").and_then(Value::as_i64).unwrap_or(0);
        b_micros.cmp(&a_micros)
    });
    matches.truncate(limit);

    Ok(json!({
        "events": matches
            .into_iter()
            .map(|entry| {
                let mut object = entry.as_object().cloned().unwrap_or_default();
                object.remove("occurredAtMicros");
                Value::Object(object)
            })
            .collect::<Vec<Value>>(),
        "instant": native_instant()?,
    }))
}

fn query_when_events_payload(payload: &Map<String, Value>) -> Result<Value, String> {
    let runtime_id = payload
        .get("runtime_id")
        .and_then(Value::as_str)
        .unwrap_or("");
    let limit = payload.get("limit").and_then(Value::as_u64).unwrap_or(20) as usize;
    let registry = runtime_event_registry()
        .lock()
        .map_err(|_| "runtime event registry lock poisoned".to_string())?;

    let mut matches = registry
        .values()
        .filter_map(|stored| {
            let event = stored.payload.as_object()?;
            if !runtime_id.is_empty()
                && event.get("runtime_id").and_then(Value::as_str) != Some(runtime_id)
            {
                return None;
            }
            Some(Value::Object(event.clone()))
        })
        .collect::<Vec<_>>();

    matches.sort_by(|left, right| {
        let left_time = left
            .get("occurred_at_utc")
            .and_then(Value::as_str)
            .and_then(|value| parse_iso8601_micros(value).ok())
            .unwrap_or(0);
        let right_time = right
            .get("occurred_at_utc")
            .and_then(Value::as_str)
            .and_then(|value| parse_iso8601_micros(value).ok())
            .unwrap_or(0);
        right_time.cmp(&left_time)
    });
    matches.truncate(limit);

    Ok(json!({
        "events": matches,
        "instant": native_instant()?,
    }))
}

fn extract_snapshot_reference_micros(snapshot: &Map<String, Value>) -> Result<i64, String> {
    let observed_at = snapshot
        .get("observedAt")
        .and_then(Value::as_object)
        .ok_or_else(|| "snapshot missing observedAt".to_string())?;
    let observed_ref = observed_at
        .get("referenceTime")
        .and_then(Value::as_str)
        .ok_or_else(|| "snapshot missing observedAt.referenceTime".to_string())?;
    parse_iso8601_micros(observed_ref)
}

fn native_instant() -> Result<NativeTemporalInstant, String> {
    native_instant_from_micros(unix_epoch_micros()?)
}

fn native_instant_from_payload(payload: &Map<String, Value>) -> Result<NativeTemporalInstant, String> {
    let micros = extract_reference_micros(payload)?.unwrap_or(unix_epoch_micros()?);
    native_instant_from_micros(micros)
}

fn native_instant_from_micros(micros: i64) -> Result<NativeTemporalInstant, String> {
    let iso = chrono_like_iso8601(micros);
    Ok(NativeTemporalInstant {
        referenceTime: iso.clone(),
        civilTime: iso,
        timezoneId: "UTC".to_string(),
        provenance: NativeTemporalProvenance {
            authority: "device",
            source: "native_when_kernel",
        },
        uncertainty: NativeTemporalUncertainty {
            windowMicros: 0,
            confidence: 1.0,
        },
        monotonicTicks: micros,
    })
}

fn semantic_band_for_micros(unix_micros: i64) -> &'static str {
    let secs = if unix_micros <= 0 { 0 } else { unix_micros / 1_000_000 };
    let hour = ((secs / 3600) % 24) as i32;
    match hour {
        5..=6 => "dawn",
        7..=11 => "morning",
        12 => "noon",
        13..=16 => "afternoon",
        17..=18 => "dusk",
        19 => "goldenHour",
        _ => "night",
    }
}

fn unix_epoch_micros() -> Result<i64, String> {
    Ok(SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|error| format!("system time before epoch: {error}"))?
        .as_micros() as i64)
}

fn parse_iso8601_micros(input: &str) -> Result<i64, String> {
    let dt = input
        .parse::<chrono_shim::DateTime>()
        .map_err(|error| format!("invalid iso8601 time: {error}"))?;
    Ok(dt.unix_micros)
}

fn extract_reference_micros(payload: &Map<String, Value>) -> Result<Option<i64>, String> {
    for key in ["occurred_at_utc", "occurredAtUtc", "reference_time", "referenceTime", "observed_at_utc"] {
        if let Some(value) = payload.get(key).and_then(Value::as_str) {
            return Ok(Some(parse_iso8601_micros(value)?));
        }
    }

    if let Some(context) = payload.get("context").and_then(Value::as_object) {
        for key in ["occurred_at_utc", "occurredAtUtc", "reference_time", "referenceTime"] {
            if let Some(value) = context.get(key).and_then(Value::as_str) {
                return Ok(Some(parse_iso8601_micros(value)?));
            }
        }
    }

    Ok(None)
}

fn chrono_like_iso8601(unix_micros: i64) -> String {
    chrono_shim::DateTime { unix_micros }.to_iso8601()
}

fn historical_registry() -> &'static Mutex<std::collections::HashMap<String, StoredArtifact>> {
    HISTORICAL_EVIDENCE_REGISTRY
        .get_or_init(|| Mutex::new(std::collections::HashMap::new()))
}

fn forecast_registry() -> &'static Mutex<std::collections::HashMap<String, StoredArtifact>> {
    FORECAST_REGISTRY.get_or_init(|| Mutex::new(std::collections::HashMap::new()))
}

fn runtime_event_registry() -> &'static Mutex<std::collections::HashMap<String, StoredArtifact>> {
    RUNTIME_EVENT_REGISTRY.get_or_init(|| Mutex::new(std::collections::HashMap::new()))
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"handled":false,"payload":null,"error":"response json encode failed: {error}"}}"#
        )
    });
    CString::new(json).unwrap().into_raw()
}

mod chrono_shim {
    use std::fmt::{Display, Formatter};
    use std::str::FromStr;

    #[derive(Debug, Clone)]
    pub struct DateTime {
        pub unix_micros: i64,
    }

    #[derive(Debug, Clone)]
    pub struct ParseError;

    impl Display for ParseError {
        fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
            write!(f, "unsupported datetime format")
        }
    }

    impl FromStr for DateTime {
        type Err = ParseError;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            let trimmed = s.trim_end_matches('Z');
            let (date, time) = trimmed.split_once('T').ok_or(ParseError)?;
            let mut date_parts = date.split('-');
            let year: i32 = date_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;
            let month: i32 = date_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;
            let day: i32 = date_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;

            let (clock, fractional) = match time.split_once('.') {
                Some((clock, fractional)) => (clock, fractional),
                None => (time, "0"),
            };
            let mut time_parts = clock.split(':');
            let hour: i32 = time_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;
            let minute: i32 = time_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;
            let second: i32 = time_parts.next().ok_or(ParseError)?.parse().map_err(|_| ParseError)?;

            let micros = fractional
                .chars()
                .take(6)
                .collect::<String>()
                .parse::<i64>()
                .unwrap_or(0);
            let micros = micros * 10_i64.pow((6usize.saturating_sub(fractional.len().min(6))) as u32);

            let days = days_from_civil(year, month, day);
            let total_seconds =
                days * 86_400 + (hour as i64 * 3600) + (minute as i64 * 60) + second as i64;

            Ok(DateTime {
                unix_micros: total_seconds * 1_000_000 + micros,
            })
        }
    }

    impl DateTime {
        pub fn to_iso8601(&self) -> String {
            let total_seconds = self.unix_micros.div_euclid(1_000_000);
            let micros = self.unix_micros.rem_euclid(1_000_000);
            let days = total_seconds.div_euclid(86_400);
            let seconds_of_day = total_seconds.rem_euclid(86_400);
            let (year, month, day) = civil_from_days(days);
            let hour = seconds_of_day / 3600;
            let minute = (seconds_of_day % 3600) / 60;
            let second = seconds_of_day % 60;

            format!(
                "{year:04}-{month:02}-{day:02}T{hour:02}:{minute:02}:{second:02}.{micros:06}Z"
            )
        }
    }

    fn days_from_civil(year: i32, month: i32, day: i32) -> i64 {
        let y = year - if month <= 2 { 1 } else { 0 };
        let era = if y >= 0 { y } else { y - 399 } / 400;
        let yoe = y - era * 400;
        let doy = (153 * (month + if month > 2 { -3 } else { 9 }) + 2) / 5 + day - 1;
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
        (era * 146097 + doe - 719468) as i64
    }

    fn civil_from_days(days: i64) -> (i32, i32, i32) {
        let z = days + 719468;
        let era = if z >= 0 { z } else { z - 146096 } / 146097;
        let doe = z - era * 146097;
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        let y = yoe as i32 + era as i32 * 400;
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        let mp = (5 * doy + 2) / 153;
        let day = (doy - (153 * mp + 2) / 5 + 1) as i32;
        let month = (mp + if mp < 10 { 3 } else { -9 }) as i32;
        let year = y + if month <= 2 { 1 } else { 0 };
        (year, month, day)
    }
}
