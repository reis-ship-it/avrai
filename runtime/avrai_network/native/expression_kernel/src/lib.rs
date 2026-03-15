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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum SpeechAct {
    Recommend,
    Explain,
    Clarify,
    Ask,
    Decline,
    Reassure,
    Confirm,
    Warn,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum Audience {
    UserSafe,
    Agent,
    Admin,
    Governance,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum SurfaceShape {
    Card,
    ChatTurn,
    Banner,
    SettingsExplainer,
    Modal,
    Receipt,
    EmptyState,
    ErrorState,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct ExpressionSection {
    kind: String,
    text: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct ExpressionPlan {
    speech_act: SpeechAct,
    audience: Audience,
    surface_shape: SurfaceShape,
    allowed_claims: Vec<String>,
    forbidden_claims: Vec<String>,
    evidence_refs: Vec<String>,
    confidence_band: String,
    #[serde(default)]
    vibe_context: Option<VibeExpressionContext>,
    uncertainty_notice: Option<String>,
    tone_profile: String,
    sections: Vec<ExpressionSection>,
    cta: Option<String>,
    fallback_text: String,
    adaptation_profile_ref: Option<String>,
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct RenderedUtterance {
    text: String,
    sections: Vec<ExpressionSection>,
    asserted_claims: Vec<String>,
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

#[no_mangle]
pub extern "C" fn avrai_expression_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_expression_kernel_free_string(ptr: *mut c_char) {
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
        "compile_utterance_plan" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: serde_json::to_value(compile_utterance_plan(&request.payload)?) 
                .map_err(|error| format!("plan encode failed: {error}"))?,
            error: None,
        }),
        "render_deterministic" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: serde_json::to_value(render_deterministic(&request.payload)?) 
                .map_err(|error| format!("render encode failed: {error}"))?,
            error: None,
        }),
        "validate_utterance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: validate_utterance(&request.payload)?,
            error: None,
        }),
        "record_expression_feedback" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_expression_feedback(&request.payload),
            error: None,
        }),
        "snapshot_expression_profile" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_expression_profile(&request.payload),
            error: None,
        }),
        "reset_expression_profile" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: reset_expression_profile(&request.payload),
            error: None,
        }),
        "diagnose_expression_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "status": "ok",
                "kernel": "expression",
                "schema_version": 1,
                "local_only": true,
                "cloud_dependency_required": false,
                "deterministic_fallback_required": false,
                "grounding_required": true,
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

fn compile_utterance_plan(payload: &Map<String, Value>) -> Result<ExpressionPlan, String> {
    let speech_act: SpeechAct = deserialize_or_default(
        payload.get("speech_act").cloned(),
        Value::String("explain".to_string()),
    )?;
    let audience: Audience = deserialize_or_default(
        payload.get("audience").cloned(),
        Value::String("user_safe".to_string()),
    )?;
    let surface_shape: SurfaceShape = deserialize_or_default(
        payload.get("surface_shape").cloned(),
        Value::String("card".to_string()),
    )?;

    let allowed_claims = string_list(payload.get("allowed_claims"));
    let forbidden_claims = string_list(payload.get("forbidden_claims"));
    let evidence_refs = string_list(payload.get("evidence_refs"));
    let subject_label = payload
        .get("subject_label")
        .and_then(Value::as_str)
        .unwrap_or("AVRAI update");
    let confidence_band = payload
        .get("confidence_band")
        .and_then(Value::as_str)
        .unwrap_or("medium")
        .to_string();
    let vibe_context = payload
        .get("vibe_context")
        .cloned()
        .map(serde_json::from_value)
        .transpose()
        .map_err(|error| format!("invalid vibe context: {error}"))?;
    let default_tone_profile = vibe_context
        .as_ref()
        .map(|context: &VibeExpressionContext| context.tone_profile.as_str())
        .unwrap_or("clear_calm");
    let tone_profile = payload
        .get("tone_profile")
        .and_then(Value::as_str)
        .unwrap_or(default_tone_profile)
        .to_string();
    let uncertainty_notice = payload
        .get("uncertainty_notice")
        .and_then(Value::as_str)
        .map(ToOwned::to_owned);
    let cta = payload
        .get("cta")
        .and_then(Value::as_str)
        .map(ToOwned::to_owned);
    let adaptation_profile_ref = payload
        .get("adaptation_profile_ref")
        .and_then(Value::as_str)
        .map(ToOwned::to_owned);

    let body = if allowed_claims.is_empty() {
        "AVRAI has no grounded claim to express yet.".to_string()
    } else {
        allowed_claims
            .iter()
            .take(2)
            .cloned()
            .collect::<Vec<_>>()
            .join(" ")
    };

    let mut sections = if matches!(surface_shape, SurfaceShape::ChatTurn) {
        vec![ExpressionSection {
            kind: "body".to_string(),
            text: body,
        }]
    } else {
        vec![
            ExpressionSection {
                kind: "title".to_string(),
                text: expression_title(&speech_act, subject_label),
            },
            ExpressionSection {
                kind: "body".to_string(),
                text: body,
            },
        ]
    };
    if let Some(notice) = uncertainty_notice.clone() {
        sections.push(ExpressionSection {
            kind: "uncertainty".to_string(),
            text: notice,
        });
    }
    if let Some(cta_text) = cta.clone() {
        sections.push(ExpressionSection {
            kind: "cta".to_string(),
            text: cta_text,
        });
    }

    Ok(ExpressionPlan {
        speech_act,
        audience,
        surface_shape,
        allowed_claims,
        forbidden_claims,
        evidence_refs,
        confidence_band,
        vibe_context,
        uncertainty_notice,
        tone_profile,
        sections,
        cta,
        fallback_text: "I can only express what AVRAI has grounded right now.".to_string(),
        adaptation_profile_ref,
        schema_version: 1,
    })
}

fn render_deterministic(payload: &Map<String, Value>) -> Result<RenderedUtterance, String> {
    let plan_value = payload
        .get("plan")
        .cloned()
        .unwrap_or_else(|| Value::Object(payload.clone()));
    let plan: ExpressionPlan = serde_json::from_value(plan_value)
        .map_err(|error| format!("invalid expression plan: {error}"))?;

    let text = plan
        .sections
        .iter()
        .map(|section| section.text.trim())
        .filter(|entry| !entry.is_empty())
        .collect::<Vec<_>>()
        .join("\n\n");

    Ok(RenderedUtterance {
        text,
        sections: plan.sections,
        asserted_claims: plan.allowed_claims,
    })
}

fn validate_utterance(payload: &Map<String, Value>) -> Result<Value, String> {
    let allowed_claims = string_list(payload.get("allowed_claims"));
    let asserted_claims = string_list(payload.get("asserted_claims"));
    let forbidden_claims = string_list(payload.get("forbidden_claims"));

    let unsupported_claims = asserted_claims
        .iter()
        .filter(|claim| !allowed_claims.contains(*claim))
        .cloned()
        .collect::<Vec<_>>();
    let forbidden_hits = asserted_claims
        .iter()
        .filter(|claim| forbidden_claims.contains(*claim))
        .cloned()
        .collect::<Vec<_>>();
    let valid = unsupported_claims.is_empty() && forbidden_hits.is_empty();

    Ok(json!({
        "valid": valid,
        "unsupported_claims": unsupported_claims,
        "forbidden_hits": forbidden_hits,
        "fallback_required": !valid,
    }))
}

fn record_expression_feedback(payload: &Map<String, Value>) -> Value {
    let feedback = payload
        .get("feedback")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let surface = payload
        .get("surface")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let adaptation_profile_ref = payload
        .get("adaptation_profile_ref")
        .and_then(Value::as_str)
        .unwrap_or("default");

    json!({
        "accepted": true,
        "feedback": feedback,
        "surface": surface,
        "adaptation_profile_ref": adaptation_profile_ref,
        "local_learning_only": true,
    })
}

fn snapshot_expression_profile(payload: &Map<String, Value>) -> Value {
    let adaptation_profile_ref = payload
        .get("adaptation_profile_ref")
        .and_then(Value::as_str)
        .unwrap_or("default");

    json!({
        "adaptation_profile_ref": adaptation_profile_ref,
        "tone_preference": "clear_calm",
        "verbosity_preference": "medium",
        "uncertainty_style": "explicit",
        "schema_version": 1,
    })
}

fn reset_expression_profile(payload: &Map<String, Value>) -> Value {
    let adaptation_profile_ref = payload
        .get("adaptation_profile_ref")
        .and_then(Value::as_str)
        .unwrap_or("default");

    json!({
        "reset": true,
        "adaptation_profile_ref": adaptation_profile_ref,
        "local_learning_state_cleared": true,
    })
}

fn expression_title(speech_act: &SpeechAct, subject_label: &str) -> String {
    match speech_act {
        SpeechAct::Recommend => format!("Recommended: {subject_label}"),
        SpeechAct::Explain => format!("Why AVRAI is surfacing {subject_label}"),
        SpeechAct::Clarify => format!("Clarifying {subject_label}"),
        SpeechAct::Ask => format!("A question about {subject_label}"),
        SpeechAct::Decline => format!("AVRAI cannot confirm {subject_label}"),
        SpeechAct::Reassure => format!("What AVRAI can say about {subject_label}"),
        SpeechAct::Confirm => format!("Confirmed: {subject_label}"),
        SpeechAct::Warn => format!("Use care with {subject_label}"),
    }
}

fn string_list(value: Option<&Value>) -> Vec<String> {
    match value {
        Some(Value::Array(entries)) => entries
            .iter()
            .filter_map(Value::as_str)
            .map(ToOwned::to_owned)
            .collect(),
        _ => Vec::new(),
    }
}

fn deserialize_or_default<T>(value: Option<Value>, default: Value) -> Result<T, String>
where
    T: for<'de> Deserialize<'de>,
{
    serde_json::from_value(value.unwrap_or(default))
        .map_err(|error| format!("enum decode failed: {error}"))
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

    #[test]
    fn compile_utterance_plan_uses_grounded_claims() {
        let payload = Map::from_iter(vec![
            ("speech_act".to_string(), json!("explain")),
            ("audience".to_string(), json!("user_safe")),
            ("surface_shape".to_string(), json!("card")),
            ("subject_label".to_string(), json!("today's recommendation")),
            (
                "allowed_claims".to_string(),
                json!(["This event matches your current social energy."]),
            ),
        ]);

        let plan = compile_utterance_plan(&payload).expect("plan should compile");
        assert_eq!(plan.allowed_claims.len(), 1);
        assert_eq!(plan.sections[0].kind, "title");
        assert!(plan.sections[1]
            .text
            .contains("matches your current social energy"));
    }

    #[test]
    fn validate_utterance_rejects_unsupported_claims() {
        let payload = Map::from_iter(vec![
            (
                "allowed_claims".to_string(),
                json!(["This event matches your current social energy."]),
            ),
            (
                "asserted_claims".to_string(),
                json!([
                    "This event matches your current social energy.",
                    "The host is definitely your best match."
                ]),
            ),
        ]);

        let result = validate_utterance(&payload).expect("validation should succeed");
        assert_eq!(result["valid"], json!(false));
        assert_eq!(result["fallback_required"], json!(true));
    }
}
