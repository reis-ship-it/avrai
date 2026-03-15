use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::ffi::{CStr, CString};
use std::time::{SystemTime, UNIX_EPOCH};

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
pub extern "C" fn avrai_how_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_how_kernel_free_string(ptr: *mut c_char) {
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
        "resolve_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_how(&request.payload),
            error: None,
        }),
        "classify_execution_path" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: classify_execution_path(&request.payload),
            error: None,
        }),
        "execute_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: execute_how(&request.payload),
            error: None,
        }),
        "trace_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: trace_how(&request.payload),
            error: None,
        }),
        "rollback_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: rollback_how(&request.payload),
            error: None,
        }),
        "intervene_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: intervene_how(&request.payload),
            error: None,
        }),
        "snapshot_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_how(&request.payload),
            error: None,
        }),
        "replay_how" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: replay_how(&request.payload),
            error: None,
        }),
        "project_how_reality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_how_reality(&request.payload),
            error: None,
        }),
        "project_how_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_how_governance(&request.payload),
            error: None,
        }),
        "score_workflow_mechanism" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_how(&request.payload),
            error: None,
        }),
        "diagnose_how_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({"status": "ok", "kernel": "how", "schemaVersion": 1}),
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

fn resolve_how(payload: &Map<String, Value>) -> Value {
    let prediction_context = payload
        .get("prediction_context")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let runtime_context = payload
        .get("runtime_context")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let execution_path = runtime_context
        .get("execution_path")
        .and_then(Value::as_str)
        .unwrap_or("native_orchestrated");
    let workflow_stage = runtime_context
        .get("workflow_stage")
        .and_then(Value::as_str)
        .unwrap_or("inference");
    let transport_mode = runtime_context
        .get("transport_mode")
        .and_then(Value::as_str)
        .unwrap_or("in_process");
    let planner_mode = prediction_context
        .get("planner_mode")
        .and_then(Value::as_str)
        .unwrap_or("heuristic");
    let model_family = prediction_context
        .get("model_family")
        .and_then(Value::as_str)
        .unwrap_or("baseline");
    let intervention_chain = runtime_context
        .get("intervention_chain")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_else(|| vec![json!("rank"), json!("filter"), json!("return")]);
    let failure_mechanism = runtime_context
        .get("failure_mechanism")
        .and_then(Value::as_str)
        .unwrap_or("none");

    json!({
        "execution_path": execution_path,
        "workflow_stage": workflow_stage,
        "transport_mode": transport_mode,
        "planner_mode": planner_mode,
        "model_family": model_family,
        "intervention_chain": intervention_chain,
        "failure_mechanism": failure_mechanism,
        "mechanism_confidence": if failure_mechanism == "none" { 0.84 } else { 0.63 },
    })
}

fn classify_execution_path(payload: &Map<String, Value>) -> Value {
    let snapshot = resolve_how(payload);
    json!({
        "execution_path": snapshot.get("execution_path").cloned().unwrap_or(Value::Null),
        "workflow_stage": snapshot.get("workflow_stage").cloned().unwrap_or(Value::Null),
    })
}

fn execute_how(payload: &Map<String, Value>) -> Value {
    let execution_id = payload
        .get("execution_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let path = payload
        .get("path")
        .and_then(Value::as_str)
        .unwrap_or("native_orchestrated");
    let capability_chain = payload
        .get("capability_chain")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    json!({
        "execution_id": execution_id,
        "path": path,
        "completed_at_utc": iso8601_now(),
        "status": "executed",
        "capability_chain": capability_chain,
    })
}

fn trace_how(payload: &Map<String, Value>) -> Value {
    let execution_id = payload
        .get("execution_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let snapshot = snapshot_how(&Map::from_iter(vec![(
        "subject_id".to_string(),
        json!(execution_id),
    )]));
    json!({
        "execution_id": execution_id,
        "path": snapshot.get("execution_path").cloned().unwrap_or_else(|| json!("native_orchestrated")),
        "completed_at_utc": iso8601_now(),
        "status": "traced",
        "capability_chain": snapshot.get("intervention_chain").cloned().unwrap_or_else(|| json!([])),
    })
}

fn rollback_how(payload: &Map<String, Value>) -> Value {
    let execution_id = payload
        .get("execution_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    json!({
        "execution_id": execution_id,
        "rolled_back": true,
        "recorded_at_utc": iso8601_now(),
    })
}

fn intervene_how(payload: &Map<String, Value>) -> Value {
    let execution_id = payload
        .get("execution_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let directive = payload
        .get("directive")
        .and_then(Value::as_str)
        .unwrap_or("observe");
    json!({
        "execution_id": execution_id,
        "directive": directive,
        "accepted": true,
        "recorded_at_utc": iso8601_now(),
    })
}

fn snapshot_how(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    resolve_how(&Map::from_iter(vec![
        (
            "runtime_context".to_string(),
            json!({
                "execution_path": format!("native:{subject_id}"),
                "workflow_stage": "snapshot",
            }),
        ),
        (
            "prediction_context".to_string(),
            json!({
                "planner_mode": "native",
                "model_family": "kernel_authority",
            }),
        ),
    ]))
}

fn replay_how(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let snapshot = snapshot_how(&Map::from_iter(vec![(
        "subject_id".to_string(),
        json!(subject_id),
    )]));
    json!({
        "records": [
            {
                "domain": "how",
                "record_id": format!("how:{subject_id}"),
                "occurred_at_utc": iso8601_now(),
                "summary": format!("Execution replay for {subject_id}"),
                "payload": snapshot,
            }
        ]
    })
}

fn project_how_reality(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_how(&Map::from_iter(vec![(
                "subject_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    json!({
        "summary": format!(
            "Execution path {} in {}",
            snapshot.get("execution_path").and_then(Value::as_str).unwrap_or("unknown"),
            snapshot.get("workflow_stage").and_then(Value::as_str).unwrap_or("unknown_stage"),
        ),
        "confidence": snapshot.get("mechanism_confidence").and_then(Value::as_f64).unwrap_or(0.0),
        "features": {
            "transport_mode": snapshot.get("transport_mode").cloned().unwrap_or(Value::Null),
            "planner_mode": snapshot.get("planner_mode").cloned().unwrap_or(Value::Null),
            "failure_mechanism": snapshot.get("failure_mechanism").cloned().unwrap_or(Value::Null),
        },
        "payload": snapshot,
    })
}

fn project_how_governance(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_execution");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_how(&Map::from_iter(vec![(
                "subject_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    json!({
        "domain": "how",
        "summary": format!("Governance execution view for {subject_id}"),
        "confidence": snapshot.get("mechanism_confidence").and_then(Value::as_f64).unwrap_or(0.0),
        "highlights": snapshot.get("intervention_chain").cloned().unwrap_or_else(|| json!([])),
        "payload": snapshot,
    })
}

fn iso8601_now() -> String {
    let micros = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_micros() as i64)
        .unwrap_or(0);
    chrono_like_iso8601(micros)
}

fn chrono_like_iso8601(unix_micros: i64) -> String {
    let total_seconds = unix_micros.div_euclid(1_000_000);
    let micros = unix_micros.rem_euclid(1_000_000);
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

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"handled":false,"payload":null,"error":"response encode failed: {error}"}}"#
        )
    });
    CString::new(json).expect("response CString").into_raw()
}
