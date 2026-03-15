use chrono::{DateTime, Duration, Utc};
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

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
enum GovernanceMode {
    Shadow,
    Enforce,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
enum GovernanceAction {
    ModelSwitch,
    ModelRollback,
    ModelAbTestStart,
    RolloutCandidateStart,
    HappinessSignalIngest,
}

#[derive(Debug, Deserialize)]
struct KernelRecord {
    kernel_id: String,
    authority_mode: String,
    status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct KnowledgeVector {
    sender_agent_id: String,
    insight_weights: Vec<f64>,
    context_category: String,
    timestamp_utc: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct VibeSignal {
    key: String,
    kind: String,
    value: f64,
    confidence: f64,
    #[serde(default)]
    provenance: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
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
}

#[no_mangle]
pub extern "C" fn avrai_governance_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_governance_kernel_free_string(ptr: *mut c_char) {
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
        "evaluate_kernel_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: evaluate_kernel_governance(&request.payload)?,
            error: None,
        }),
        "intercept_outgoing_vector" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: intercept_vector(&request.payload, true)?,
            error: None,
        }),
        "intercept_incoming_vector" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: intercept_vector(&request.payload, false)?,
            error: None,
        }),
        "authorize_vibe_mutation" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: authorize_vibe_mutation(&request.payload)?,
            error: None,
        }),
        "inspect_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: inspect_governance(&request.payload),
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

fn evaluate_kernel_governance(payload: &Map<String, Value>) -> Result<Value, String> {
    let mode: GovernanceMode = serde_json::from_value(
        payload
            .get("mode")
            .cloned()
            .unwrap_or_else(|| Value::String("shadow".to_string())),
    )
    .map_err(|error| format!("invalid governance mode: {error}"))?;
    let action: GovernanceAction = serde_json::from_value(
        payload
            .get("action")
            .cloned()
            .unwrap_or_else(|| Value::String("model_switch".to_string())),
    )
    .map_err(|error| format!("invalid governance action: {error}"))?;
    let model_type = payload
        .get("model_type")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let from_version = payload
        .get("from_version")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let to_version = payload
        .get("to_version")
        .and_then(Value::as_str)
        .unwrap_or_default();
    let policy_version = payload
        .get("policy_version")
        .and_then(Value::as_str)
        .unwrap_or("unknown");

    let kernels: Vec<KernelRecord> = serde_json::from_value(
        payload
            .get("kernels")
            .cloned()
            .unwrap_or_else(|| Value::Array(Vec::new())),
    )
    .unwrap_or_default();
    let required_kernel_ids: Vec<String> = serde_json::from_value(
        payload
            .get("required_kernel_ids")
            .cloned()
            .unwrap_or_else(|| Value::Array(Vec::new())),
    )
    .unwrap_or_default();

    let mut reason_codes: Vec<String> = Vec::new();
    let mut would_allow = true;

    if model_type.is_empty() && !matches!(action, GovernanceAction::HappinessSignalIngest) {
        would_allow = false;
        reason_codes.push("missing_model_type".to_string());
    }

    if matches!(action, GovernanceAction::ModelSwitch)
        && payload.contains_key("to_version")
        && to_version.is_empty()
    {
        would_allow = false;
        reason_codes.push("missing_target_version".to_string());
    }

    if matches!(action, GovernanceAction::RolloutCandidateStart)
        && (from_version.is_empty() || to_version.is_empty())
    {
        would_allow = false;
        reason_codes.push("invalid_rollout_versions".to_string());
    }

    if !from_version.is_empty() && !to_version.is_empty() && from_version == to_version {
        would_allow = false;
        reason_codes.push("no_version_change".to_string());
    }

    if required_kernel_ids.is_empty() && payload.get("kernels").is_none() {
        would_allow = false;
        reason_codes.push("kernel_registry_unavailable".to_string());
    } else {
        for kernel_id in required_kernel_ids {
            let kernel = kernels.iter().find(|entry| entry.kernel_id == kernel_id);
            match kernel {
                Some(record) => {
                    if record.authority_mode != "enforced" && record.authority_mode != "shadow" {
                        would_allow = false;
                        reason_codes.push(format!("invalid_authority_mode_{}", kernel_id));
                    }
                    if record.status != "done" {
                        would_allow = false;
                        reason_codes.push(format!("kernel_not_done_{}", kernel_id));
                    }
                }
                None => {
                    would_allow = false;
                    reason_codes.push(format!("missing_{}", kernel_id));
                }
            }
        }
    }

    let serving_allowed = matches!(mode, GovernanceMode::Shadow) || would_allow;
    let shadow_bypass_applied = matches!(mode, GovernanceMode::Shadow) && !would_allow;

    Ok(serde_json::json!({
        "mode": match mode {
            GovernanceMode::Shadow => "shadow",
            GovernanceMode::Enforce => "enforce",
        },
        "would_allow": would_allow,
        "serving_allowed": serving_allowed,
        "shadow_bypass_applied": shadow_bypass_applied,
        "reason_codes": reason_codes,
        "policy_version": policy_version,
    }))
}

fn intercept_vector(payload: &Map<String, Value>, outgoing: bool) -> Result<Value, String> {
    let vector: KnowledgeVector = serde_json::from_value(
        payload
            .get("vector")
            .cloned()
            .unwrap_or_else(|| Value::Object(Map::new())),
    )
    .map_err(|error| format!("invalid knowledge vector: {error}"))?;

    let allowed_categories = [
        "spot_affinity",
        "event_resonance",
        "community_vibe",
        "club_overlap",
        "vibe_vector",
    ];
    if !allowed_categories.contains(&vector.context_category.as_str()) {
        return Ok(json!({
            "approved": false,
            "reason": "Unauthorized category for governed knowledge-vector exchange.",
        }));
    }
    if vector.insight_weights.is_empty() {
        return Ok(json!({
            "approved": false,
            "reason": "empty_vector",
        }));
    }
    if vector.insight_weights.len() > 512 {
        return Ok(json!({
            "approved": false,
            "reason": "Knowledge vector exceeds maximum dimensionality.",
        }));
    }
    if vector
        .insight_weights
        .iter()
        .any(|weight| weight.is_nan() || weight.is_infinite())
    {
        return Ok(json!({
            "approved": false,
            "reason": "invalid_vector_math",
        }));
    }

    if !outgoing
        && vector
            .insight_weights
            .iter()
            .any(|weight| *weight > 1.0 || *weight < -1.0)
    {
        return Ok(json!({
            "approved": false,
            "reason": "Inbound poisoning attempt detected in governed vector weights.",
        }));
    }

    if !outgoing {
        if let Some(reason) = expired_reason(&vector.timestamp_utc) {
            return Ok(json!({
                "approved": false,
                "reason": reason,
            }));
        }
    }

    let mut sanitized = vector.clone();
    sanitized.insight_weights = vector
        .insight_weights
        .iter()
        .map(|weight| (*weight).clamp(-1.0, 1.0))
        .collect();

    Ok(json!({
        "approved": true,
        "reason": if outgoing { "approved_outgoing" } else { "approved_incoming" },
        "sanitized_vector": sanitized,
    }))
}

fn authorize_vibe_mutation(payload: &Map<String, Value>) -> Result<Value, String> {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("")
        .trim();
    let governance_scope = payload
        .get("governance_scope")
        .and_then(Value::as_str)
        .unwrap_or("personal");
    let evidence: VibeEvidence = serde_json::from_value(
        payload
            .get("evidence")
            .cloned()
            .unwrap_or_else(|| Value::Object(Map::new())),
    )
    .map_err(|error| format!("invalid vibe evidence: {error}"))?;

    if subject_id.is_empty() {
        return Ok(json!({
            "state_write_allowed": false,
            "dna_write_allowed": false,
            "pheromone_write_allowed": false,
            "behavior_write_allowed": false,
            "affective_write_allowed": false,
            "style_write_allowed": false,
            "reason_codes": vec!["missing_subject_id"],
            "governance_scope": governance_scope,
            "air_gap_envelope_required": false,
            "schema_version": 1,
        }));
    }

    if let Some(reason_code) = invalid_vibe_scope_reason(subject_id, governance_scope) {
        return Ok(json!({
            "state_write_allowed": false,
            "dna_write_allowed": false,
            "pheromone_write_allowed": false,
            "behavior_write_allowed": false,
            "affective_write_allowed": false,
            "style_write_allowed": false,
            "reason_codes": vec![reason_code],
            "governance_scope": governance_scope,
            "air_gap_envelope_required": false,
            "schema_version": 1,
        }));
    }

    let high_risk = evidence
        .identity_signals
        .iter()
        .chain(evidence.pheromone_signals.iter())
        .chain(evidence.behavior_signals.iter())
        .any(|signal| signal.confidence > 0.95 && signal.value.abs() > 0.95);

    let state_write_allowed = !high_risk;
    Ok(json!({
        "state_write_allowed": state_write_allowed,
        "dna_write_allowed": state_write_allowed,
        "pheromone_write_allowed": state_write_allowed,
        "behavior_write_allowed": state_write_allowed,
        "affective_write_allowed": state_write_allowed,
        "style_write_allowed": state_write_allowed,
        "reason_codes": if state_write_allowed {
            vec!["governance_approved"]
        } else {
            vec!["governance_high_risk_signal"]
        },
        "governance_scope": governance_scope,
        "air_gap_envelope_required": false,
        "schema_version": 1,
    }))
}

fn inspect_governance(payload: &Map<String, Value>) -> Value {
    json!({
        "status": "ok",
        "scope": payload.get("scope").and_then(Value::as_str).unwrap_or("runtime"),
        "subject_id": payload.get("subject_id").and_then(Value::as_str),
        "metadata": payload.get("metadata").cloned().unwrap_or_else(|| Value::Object(Map::new())),
        "policy": "native_only_governance",
    })
}

fn invalid_vibe_scope_reason(subject_id: &str, governance_scope: &str) -> Option<&'static str> {
    match governance_scope {
        "personal" => {
            if is_geographic_subject(subject_id) || subject_id.starts_with("scene:") {
                Some("subject_scope_mismatch")
            } else {
                None
            }
        }
        "entity" => {
            if is_geographic_subject(subject_id) {
                Some("subject_scope_mismatch")
            } else {
                None
            }
        }
        "geographic:locality" => expect_geographic_subject(subject_id, "locality-agent:"),
        "geographic:district" => expect_geographic_subject(subject_id, "district-agent:"),
        "geographic:city" => expect_geographic_subject(subject_id, "city-agent:"),
        "geographic:region" => expect_geographic_subject(subject_id, "region-agent:"),
        "geographic:country" => expect_geographic_subject(subject_id, "country-agent:"),
        "geographic:global" => {
            if subject_id.starts_with("global-agent:") || subject_id.starts_with("top-level-agent:")
            {
                None
            } else {
                Some("subject_scope_mismatch")
            }
        }
        "scoped:university" | "scoped:campus" | "scoped:organization" => {
            if is_geographic_subject(subject_id) {
                Some("subject_scope_mismatch")
            } else {
                None
            }
        }
        "scoped:scene" => {
            if is_geographic_subject(subject_id) {
                Some("subject_scope_mismatch")
            } else if !subject_id.starts_with("scene:") {
                Some("subject_scope_mismatch")
            } else {
                None
            }
        }
        _ => Some("unsupported_governance_scope"),
    }
}

fn expect_geographic_subject(subject_id: &str, prefix: &str) -> Option<&'static str> {
    if subject_id.starts_with(prefix) {
        None
    } else {
        Some("subject_scope_mismatch")
    }
}

fn is_geographic_subject(subject_id: &str) -> bool {
    [
        "locality-agent:",
        "district-agent:",
        "city-agent:",
        "region-agent:",
        "country-agent:",
        "global-agent:",
        "top-level-agent:",
    ]
    .iter()
    .any(|prefix| subject_id.starts_with(prefix))
}

fn expired_reason(timestamp_utc: &str) -> Option<&'static str> {
    let parsed = DateTime::parse_from_rfc3339(timestamp_utc).ok()?;
    let age = Utc::now().signed_duration_since(parsed.with_timezone(&Utc));
    if age > Duration::days(7) {
        Some("Governed knowledge vector expired before intake.")
    } else {
        None
    }
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

    fn authorize(subject_id: &str, governance_scope: &str) -> Value {
        authorize_vibe_mutation(&Map::from_iter([
            (
                "subject_id".to_string(),
                Value::String(subject_id.to_string()),
            ),
            (
                "governance_scope".to_string(),
                Value::String(governance_scope.to_string()),
            ),
            (
                "evidence".to_string(),
                json!({
                    "summary": "test evidence",
                    "identity_signals": [{
                        "key": "exploration_eagerness",
                        "kind": "identity",
                        "value": 0.7,
                        "confidence": 0.8,
                        "provenance": ["test"],
                    }],
                }),
            ),
        ]))
        .expect("authorize_vibe_mutation should succeed")
    }

    #[test]
    fn rejects_unsupported_governance_scope() {
        let payload = authorize("scene:loc:indie", "scoped:community_network");
        assert_eq!(payload["state_write_allowed"], Value::Bool(false));
        assert_eq!(
            payload["reason_codes"],
            Value::Array(vec![Value::String(
                "unsupported_governance_scope".to_string()
            )])
        );
    }

    #[test]
    fn rejects_geographic_scope_subject_mismatch() {
        let payload = authorize("city-agent:bham", "geographic:locality");
        assert_eq!(payload["state_write_allowed"], Value::Bool(false));
        assert_eq!(
            payload["reason_codes"],
            Value::Array(vec![Value::String("subject_scope_mismatch".to_string())])
        );
    }

    #[test]
    fn allows_scene_scope_for_scene_subjects() {
        let payload = authorize("scene:locality-agent:bham:indie-music", "scoped:scene");
        assert_eq!(payload["state_write_allowed"], Value::Bool(true));
        assert_eq!(
            payload["reason_codes"],
            Value::Array(vec![Value::String("governance_approved".to_string())])
        );
    }
}
