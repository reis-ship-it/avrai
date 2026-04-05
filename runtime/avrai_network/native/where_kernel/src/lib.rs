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
pub extern "C" fn avrai_where_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_where_kernel_free_string(ptr: *mut c_char) {
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
        "resolve_where" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_where(&request.payload),
            error: None,
        }),
        "project_where" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_where(&request.payload),
            error: None,
        }),
        "snapshot_where" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({"snapshot": resolve_where(&request.payload)}),
            error: None,
        }),
        "diagnose_where_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({"status": "ok", "kernel": "where", "schemaVersion": 1}),
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

fn resolve_where(payload: &Map<String, Value>) -> Value {
    let context = payload
        .get("context")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let latitude = context
        .get("latitude")
        .and_then(Value::as_f64)
        .or_else(|| payload.get("latitude").and_then(Value::as_f64))
        .unwrap_or(0.0);
    let longitude = context
        .get("longitude")
        .and_then(Value::as_f64)
        .or_else(|| payload.get("longitude").and_then(Value::as_f64))
        .unwrap_or(0.0);
    let city_code = context
        .get("city_code")
        .and_then(Value::as_str)
        .unwrap_or("unknown_city");
    let locality_code = context
        .get("locality_code")
        .and_then(Value::as_str)
        .unwrap_or("unknown_locality");
    let locality_token = if locality_code == "unknown_locality" {
        "where:bootstrap".to_string()
    } else {
        format!("where:{locality_code}")
    };
    let boundary_tension = context
        .get("boundary_tension")
        .and_then(Value::as_f64)
        .unwrap_or(if locality_code == "unknown_locality" { 0.72 } else { 0.31 });
    let spatial_confidence = if locality_code == "unknown_locality" { 0.42 } else { 0.84 };
    let travel_friction = context
        .get("travel_friction")
        .and_then(Value::as_f64)
        .unwrap_or(if latitude == 0.0 && longitude == 0.0 { 0.5 } else { 0.24 });

    json!({
        "locality_token": locality_token,
        "city_code": city_code,
        "locality_code": locality_code,
        "projection": {
            "latitude": latitude,
            "longitude": longitude,
            "label": context.get("location_label").cloned().unwrap_or_else(|| json!(locality_code)),
        },
        "boundary_tension": boundary_tension,
        "spatial_confidence": spatial_confidence,
        "travel_friction": travel_friction,
        "place_fit_flags": [
            if boundary_tension > 0.65 { "boundary_volatile" } else { "stable" },
            if travel_friction > 0.45 { "high_friction" } else { "reachable" },
        ],
    })
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"handled":false,"payload":null,"error":"response encode failed: {error}"}}"#
        )
    });
    CString::new(json).expect("response CString").into_raw()
}
