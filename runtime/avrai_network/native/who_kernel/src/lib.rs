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
pub extern "C" fn avrai_who_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_who_kernel_free_string(ptr: *mut c_char) {
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
        "resolve_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_who(&request.payload),
            error: None,
        }),
        "bind_runtime" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: bind_runtime(&request.payload),
            error: None,
        }),
        "sign_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: sign_who(&request.payload),
            error: None,
        }),
        "verify_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: verify_who(&request.payload),
            error: None,
        }),
        "classify_relationship_scope" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: classify_relationship_scope(&request.payload),
            error: None,
        }),
        "snapshot_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_who(&request.payload),
            error: None,
        }),
        "replay_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: replay_who(&request.payload),
            error: None,
        }),
        "recover_who" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: recover_who(&request.payload),
            error: None,
        }),
        "project_who_reality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_who_reality(&request.payload),
            error: None,
        }),
        "project_who_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_who_governance(&request.payload),
            error: None,
        }),
        "diagnose_who_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "status": "ok",
                "kernel": "who",
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

fn resolve_who(payload: &Map<String, Value>) -> Value {
    let primary_actor = payload
        .get("agent_id")
        .and_then(Value::as_str)
        .or_else(|| payload.get("user_id").and_then(Value::as_str))
        .or_else(|| payload.get("actor_id").and_then(Value::as_str))
        .unwrap_or("unknown_actor");
    let context = payload
        .get("context")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let affected_actor = context
        .get("affected_actor")
        .and_then(Value::as_str)
        .unwrap_or(primary_actor);
    let companion_actors = context
        .get("companion_actor_ids")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let actor_roles = context
        .get("actor_roles")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_else(|| vec![json!("requester")]);
    let trust_scope = payload
        .get("policy_context")
        .and_then(Value::as_object)
        .and_then(|policy| policy.get("trust_scope"))
        .and_then(Value::as_str)
        .unwrap_or("private");
    let cohort_refs = context
        .get("cohort_refs")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let identity_confidence = if primary_actor != "unknown_actor" { 0.91 } else { 0.25 };

    json!({
        "primary_actor": primary_actor,
        "affected_actor": affected_actor,
        "companion_actors": companion_actors,
        "actor_roles": actor_roles,
        "trust_scope": trust_scope,
        "cohort_refs": cohort_refs,
        "identity_confidence": identity_confidence,
    })
}

fn classify_relationship_scope(payload: &Map<String, Value>) -> Value {
    let snapshot = resolve_who(payload);
    let companion_count = snapshot
        .get("companion_actors")
        .and_then(Value::as_array)
        .map(|entries| entries.len())
        .unwrap_or(0);
    json!({
        "trust_scope": snapshot.get("trust_scope").cloned().unwrap_or(Value::Null),
        "companion_count": companion_count,
    })
}

fn bind_runtime(payload: &Map<String, Value>) -> Value {
    let runtime_id = payload
        .get("runtime_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_runtime");
    let actor_id = payload
        .get("actor_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    json!({
        "runtime_id": runtime_id,
        "actor_id": actor_id,
        "bound_at_utc": iso8601_now(),
        "continuity_ref": format!("who:{actor_id}:{runtime_id}"),
    })
}

fn sign_who(payload: &Map<String, Value>) -> Value {
    let actor_id = payload
        .get("actor_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let algorithm = payload
        .get("algorithm")
        .and_then(Value::as_str)
        .unwrap_or("avrai_local_signature_v1");
    let payload_map = payload
        .get("payload")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let mut entries = payload_map
        .iter()
        .map(|(key, value)| format!("{key}:{value}"))
        .collect::<Vec<_>>();
    entries.sort();
    json!({
        "actor_id": actor_id,
        "algorithm": algorithm,
        "signature": format!("{actor_id}:{algorithm}:{}", entries.join("|")),
        "issued_at_utc": iso8601_now(),
    })
}

fn verify_who(payload: &Map<String, Value>) -> Value {
    let actor_id = payload
        .get("actor_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let algorithm = payload
        .get("algorithm")
        .and_then(Value::as_str)
        .unwrap_or("avrai_local_signature_v1");
    let provided_signature = payload
        .get("signature")
        .and_then(Value::as_str)
        .unwrap_or("");
    let signed = sign_who(&Map::from_iter(vec![
        ("actor_id".to_string(), json!(actor_id)),
        ("algorithm".to_string(), json!(algorithm)),
        (
            "payload".to_string(),
            payload.get("payload").cloned().unwrap_or_else(|| json!({})),
        ),
    ]));
    let expected_signature = signed
        .get("signature")
        .and_then(Value::as_str)
        .unwrap_or("");
    let valid = expected_signature == provided_signature;
    json!({
        "valid": valid,
        "reason": if valid { "signature_match" } else { "signature_mismatch" },
    })
}

fn snapshot_who(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    resolve_who(&Map::from_iter(vec![
        ("actor_id".to_string(), json!(subject_id)),
        (
            "policy_context".to_string(),
            json!({"trust_scope": "private"}),
        ),
    ]))
}

fn replay_who(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let snapshot = snapshot_who(&Map::from_iter(vec![(
        "subject_id".to_string(),
        json!(subject_id),
    )]));
    json!({
        "records": [
            {
                "domain": "who",
                "record_id": format!("who:{subject_id}"),
                "occurred_at_utc": iso8601_now(),
                "summary": format!("Identity replay for {subject_id}"),
                "payload": snapshot,
            }
        ]
    })
}

fn recover_who(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let restored_count = payload
        .get("persisted_envelope")
        .and_then(Value::as_object)
        .map(|_| 1)
        .unwrap_or(0);
    json!({
        "domain": "who",
        "subject_id": subject_id,
        "restored_count": restored_count,
        "dropped_count": 0,
        "recovered_at_utc": iso8601_now(),
        "summary": format!("who recovery baseline completed for {subject_id}"),
    })
}

fn project_who_reality(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_who(&Map::from_iter(vec![(
                "subject_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    let primary_actor = snapshot
        .get("primary_actor")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let trust_scope = snapshot
        .get("trust_scope")
        .and_then(Value::as_str)
        .unwrap_or("unknown_scope");
    let confidence = snapshot
        .get("identity_confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    json!({
        "summary": format!("Actor {primary_actor} in {trust_scope} scope"),
        "confidence": confidence,
        "features": {
            "primary_actor": primary_actor,
            "affected_actor": snapshot.get("affected_actor").cloned().unwrap_or(Value::Null),
            "trust_scope": trust_scope,
            "cohort_refs": snapshot.get("cohort_refs").cloned().unwrap_or_else(|| json!([])),
        },
        "payload": snapshot,
    })
}

fn project_who_governance(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_who(&Map::from_iter(vec![(
                "subject_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    let primary_actor = snapshot
        .get("primary_actor")
        .and_then(Value::as_str)
        .unwrap_or("unknown_actor");
    let confidence = snapshot
        .get("identity_confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let trust_scope = snapshot
        .get("trust_scope")
        .and_then(Value::as_str)
        .unwrap_or("private");
    let first_role = snapshot
        .get("actor_roles")
        .and_then(Value::as_array)
        .and_then(|roles| roles.first())
        .and_then(Value::as_str)
        .unwrap_or("requester");
    json!({
        "domain": "who",
        "summary": format!("Governance identity view for {primary_actor}"),
        "confidence": confidence,
        "highlights": [trust_scope, first_role],
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
