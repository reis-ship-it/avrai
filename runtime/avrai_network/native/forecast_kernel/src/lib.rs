use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::ffi::{CStr, CString};

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
pub extern "C" fn avrai_forecast_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_forecast_kernel_free_string(ptr: *mut c_char) {
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
        "forecast" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: forecast(&request.payload),
            error: None,
        }),
        "diagnose_forecast_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "status": "ok",
                "kernel": "forecast",
                "schemaVersion": 1,
            }),
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

fn forecast(payload: &Map<String, Value>) -> Value {
    let forecast_id = payload
        .get("forecast_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_forecast");
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_subject");

    let run_context = payload
        .get("run_context")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let replay_envelope = payload
        .get("replay_envelope")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();

    let branch_id = run_context
        .get("branchId")
        .and_then(Value::as_str)
        .unwrap_or("unknown_branch");
    let run_id = run_context
        .get("runId")
        .and_then(Value::as_str)
        .unwrap_or("unknown_run");
    let canonical_replay_year = run_context
        .get("canonicalReplayYear")
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let replay_year = run_context
        .get("replayYear")
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let divergence_policy = run_context
        .get("divergencePolicy")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let forecast_family_id = payload
        .get("forecast_family_id")
        .and_then(Value::as_str)
        .unwrap_or("default_forecast_family");
    let outcome_kind = payload
        .get("outcome_kind")
        .and_then(Value::as_str)
        .unwrap_or("binary");
    let truth_scope = payload
        .get("truth_scope")
        .cloned()
        .unwrap_or_else(|| json!({
            "governanceStratum": "personal",
            "truthSurfaceKind": "forecast",
            "tenantScope": "avraiNative",
            "agentClass": "system",
            "sphereId": "forecast",
            "familyId": forecast_family_id,
        }));

    let demand_signal = replay_envelope
        .get("metadata")
        .and_then(Value::as_object)
        .and_then(|metadata| metadata.get("demand_signal"))
        .and_then(Value::as_f64)
        .unwrap_or(0.5);
    let uncertainty_confidence = replay_envelope
        .get("uncertainty")
        .and_then(Value::as_object)
        .and_then(|uncertainty| uncertainty.get("confidence"))
        .and_then(Value::as_f64)
        .unwrap_or(0.5);
    let temporal_authority_source = replay_envelope
        .get("temporalAuthoritySource")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let observed_at = replay_envelope
        .get("observedAt")
        .and_then(Value::as_object)
        .and_then(|instant| instant.get("referenceTime"))
        .and_then(Value::as_str)
        .unwrap_or("1970-01-01T00:00:00.000Z");

    let outcome_probability = clamp((demand_signal * 0.75) + (uncertainty_confidence * 0.25));
    let confidence = clamp((uncertainty_confidence * 0.65) + (demand_signal * 0.35));
    let predicted_outcome = if confidence >= 0.85 {
        "high-confidence-positive"
    } else if confidence >= 0.60 {
        "moderate-confidence-positive"
    } else {
        "uncertain"
    };
    let raw_predictive_distribution = json!({
        "outcomeKind": outcome_kind,
        "discreteProbabilities": {
            "positive": outcome_probability,
            "negative": clamp(1.0 - outcome_probability),
        },
        "mean": outcome_probability,
        "variance": outcome_probability * (1.0 - outcome_probability),
        "componentId": "rust_forecast_kernel",
        "representationComponent": "classical",
        "metadata": {
            "generator": "rust_forecast_kernel"
        }
    });

    json!({
        "claim": {
            "claimId": forecast_id,
            "forecastCreatedAt": observed_at,
            "targetWindow": payload.get("target_window").cloned().unwrap_or_else(|| json!({})),
            "evidenceWindow": payload.get("evidence_window").cloned().unwrap_or_else(|| json!({})),
            "confidence": confidence,
            "modelVersion": "rust_forecast_kernel_v1",
            "provenance": {
                "authority": "forecast",
                "source": "reality_engine.rust_forecast_kernel",
            },
            "outcomeProbability": outcome_probability,
            "predictedOutcome": predicted_outcome,
            "outcomeKind": outcome_kind,
            "forecastFamilyId": forecast_family_id,
            "laterOutcomeRef": subject_id,
            "truthScope": truth_scope.clone(),
        },
        "predicted_outcome": predicted_outcome,
        "confidence": confidence,
        "forecast_family_id": forecast_family_id,
        "outcome_probability": outcome_probability,
        "outcome_kind": outcome_kind,
        "truth_scope": truth_scope,
        "raw_predictive_distribution": raw_predictive_distribution,
        "calibrated_predictive_distribution": raw_predictive_distribution,
        "branch_id": branch_id,
        "run_id": run_id,
        "explanation": "Rust forecast kernel produced a replay-governed forecast from BHAM replay inputs.",
        "contradiction_hooks": [
            "live_user_behavior",
            "locality_agent_override",
            "admin_ground_truth_override"
        ],
        "metadata": {
            "canonical_replay_year": canonical_replay_year,
            "replay_year": replay_year,
            "divergence_policy": divergence_policy,
            "temporal_authority_source": temporal_authority_source,
            "truth_scope": payload.get("truth_scope").cloned().unwrap_or(Value::Null),
        }
    })
}

fn clamp(value: f64) -> f64 {
    if value < 0.0 {
        0.0
    } else if value > 1.0 {
        1.0
    } else {
        value
    }
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let serialized = serde_json::to_string(&response).unwrap_or_else(|error| {
        json!({
            "ok": false,
            "handled": false,
            "payload": Value::Null,
            "error": format!("response json encode failed: {error}"),
        })
        .to_string()
    });
    CString::new(serialized).unwrap().into_raw()
}
