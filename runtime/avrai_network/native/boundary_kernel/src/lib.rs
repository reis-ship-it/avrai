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
enum BoundaryPrivacyMode {
    LocalSovereign,
    UserRuntime,
    Ai2aiOptIn,
    Governance,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum BoundaryDisposition {
    Block,
    LocalOnly,
    StoreSanitized,
    UserAuthorizedEgress,
    EgressViaAirGap,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum BoundaryEgressPurpose {
    None,
    DirectMessage,
    CommunityMessage,
    Ai2aiLearningArtifact,
    AdminExport,
    ExternalShare,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum PrivacySensitivity {
    Low,
    Medium,
    High,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct PreferenceSignal {
    kind: String,
    value: String,
    confidence: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct RequestArtifact {
    summary: String,
    asks_for_response: bool,
    asks_for_recommendation: bool,
    asks_for_action: bool,
    asks_for_explanation: bool,
    referenced_entities: Vec<String>,
    questions: Vec<String>,
    preference_signals: Vec<PreferenceSignal>,
    share_intent: bool,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct LearningArtifact {
    vocabulary: Vec<String>,
    phrases: Vec<String>,
    tone_metrics: Map<String, Value>,
    directness_preference: f64,
    brevity_preference: f64,
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct InterpretationResult {
    normalized_text: String,
    request_artifact: RequestArtifact,
    learning_artifact: LearningArtifact,
    privacy_sensitivity: PrivacySensitivity,
    confidence: f64,
    ambiguity_flags: Vec<String>,
    needs_clarification: bool,
    safe_for_learning: bool,
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct BoundarySanitizedArtifact {
    pseudonymous_actor_ref: String,
    summary: String,
    safe_claims: Vec<String>,
    safe_questions: Vec<String>,
    safe_preference_signals: Vec<PreferenceSignal>,
    learning_vocabulary: Vec<String>,
    learning_phrases: Vec<String>,
    redacted_text: String,
    share_payload: Option<String>,
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct BoundaryDecision {
    accepted: bool,
    disposition: BoundaryDisposition,
    #[serde(default)]
    transcript_storage_allowed: bool,
    #[serde(default)]
    storage_allowed: bool,
    #[serde(default)]
    learning_allowed: bool,
    #[serde(default)]
    egress_allowed: bool,
    #[serde(default)]
    air_gap_required: bool,
    #[serde(default)]
    reason_codes: Vec<String>,
    sanitized_artifact: BoundarySanitizedArtifact,
    #[serde(default = "default_vibe_mutation_decision")]
    vibe_mutation_decision: VibeMutationDecision,
    #[serde(default = "default_egress_purpose")]
    egress_purpose: BoundaryEgressPurpose,
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

#[no_mangle]
pub extern "C" fn avrai_boundary_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_boundary_kernel_free_string(ptr: *mut c_char) {
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
        "enforce_boundary" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: serde_json::to_value(enforce_boundary(&request.payload)?)
                .map_err(|error| format!("boundary encode failed: {error}"))?,
            error: None,
        }),
        "compile_air_gap_transfer" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: compile_air_gap_transfer(&request.payload)?,
            error: None,
        }),
        "diagnose_boundary_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "status": "ok",
                "kernel": "boundary",
                "schema_version": 1,
                "local_only": true,
                "consent_gated": true,
                "air_gap_aware": true,
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

fn enforce_boundary(payload: &Map<String, Value>) -> Result<BoundaryDecision, String> {
    let actor_agent_id = payload
        .get("actor_agent_id")
        .and_then(Value::as_str)
        .unwrap_or("agt_unknown");
    let raw_text = payload
        .get("raw_text")
        .and_then(Value::as_str)
        .unwrap_or("");
    let privacy_mode: BoundaryPrivacyMode = deserialize_or_default(
        payload.get("privacy_mode").cloned(),
        Value::String("local_sovereign".to_string()),
    )?;
    let consent_scopes = string_list(payload.get("consent_scopes"));
    let share_requested = payload
        .get("share_requested")
        .and_then(Value::as_bool)
        .unwrap_or(false);
    let egress_purpose: BoundaryEgressPurpose = deserialize_or_default(
        payload.get("egress_purpose").cloned(),
        Value::String("none".to_string()),
    )?;
    let interpretation: InterpretationResult = deserialize_or_default(
        payload.get("interpretation").cloned(),
        Value::Object(Map::new()),
    )?;

    let direct_identifiers = looks_like_direct_identifier(raw_text);
    let user_runtime_learning = consent_scopes
        .iter()
        .any(|scope| scope == "user_runtime_learning");
    let governance_runtime_learning = consent_scopes
        .iter()
        .any(|scope| scope == "governance_runtime_learning");
    let learning_consent_granted = if matches!(privacy_mode, BoundaryPrivacyMode::Governance) {
        governance_runtime_learning
    } else {
        user_runtime_learning
    };
    let ai2ai_learning = consent_scopes.iter().any(|scope| scope == "ai2ai_learning");
    let pseudonymous_actor_ref = pseudo_ref(actor_agent_id);
    let redacted_text = redact_text(raw_text);
    let learning_vocabulary = interpretation
        .learning_artifact
        .vocabulary
        .iter()
        .filter(|entry| !entry.contains('@') && !entry.chars().any(|char| char.is_ascii_digit()))
        .cloned()
        .collect::<Vec<_>>();
    let learning_phrases = interpretation
        .learning_artifact
        .phrases
        .iter()
        .filter(|entry| !entry.contains('@') && !entry.chars().any(|char| char.is_ascii_digit()))
        .cloned()
        .collect::<Vec<_>>();

    let sanitized_artifact = BoundarySanitizedArtifact {
        pseudonymous_actor_ref: pseudonymous_actor_ref.clone(),
        summary: interpretation.request_artifact.summary.clone(),
        safe_claims: safe_claims(&interpretation),
        safe_questions: interpretation.request_artifact.questions.clone(),
        safe_preference_signals: interpretation.request_artifact.preference_signals.clone(),
        learning_vocabulary,
        learning_phrases,
        redacted_text: redacted_text.clone(),
        share_payload: None,
        schema_version: 1,
    };

    if raw_text.trim().is_empty() {
        return Ok(block_decision("empty_input", sanitized_artifact));
    }

    let high_sensitivity = direct_identifiers
        || matches!(interpretation.privacy_sensitivity, PrivacySensitivity::High);
    let user_authorized_message_egress = share_requested
        && matches!(
            egress_purpose,
            BoundaryEgressPurpose::DirectMessage | BoundaryEgressPurpose::CommunityMessage
        );
    let draft_message_surface = !share_requested
        && matches!(
            egress_purpose,
            BoundaryEgressPurpose::DirectMessage | BoundaryEgressPurpose::CommunityMessage
        );

    if draft_message_surface {
        return Ok(local_only_decision(
            vec!["local_transcript_only_message_draft".to_string()],
            sanitized_artifact,
            false,
            false,
            egress_purpose,
        ));
    }

    if share_requested {
        if user_authorized_message_egress {
            return Ok(BoundaryDecision {
                accepted: true,
                disposition: BoundaryDisposition::UserAuthorizedEgress,
                transcript_storage_allowed: true,
                storage_allowed: false,
                learning_allowed: false,
                egress_allowed: true,
                air_gap_required: false,
                reason_codes: vec!["explicit_user_message_delivery".to_string()],
                sanitized_artifact,
                vibe_mutation_decision: denied_vibe_mutation("explicit_user_message_delivery"),
                egress_purpose,
                schema_version: 1,
            });
        }
        if matches!(privacy_mode, BoundaryPrivacyMode::LocalSovereign) {
            return Ok(local_only_decision(
                vec!["local_sovereign_blocks_egress".to_string()],
                sanitized_artifact,
                false,
                false,
                egress_purpose,
            ));
        }
        if !ai2ai_learning {
            return Ok(local_only_decision(
                vec!["missing_ai2ai_learning_consent".to_string()],
                sanitized_artifact,
                false,
                false,
                egress_purpose,
            ));
        }
        let mut artifact = sanitized_artifact;
        artifact.share_payload = Some(if high_sensitivity {
            artifact.summary.clone()
        } else {
            artifact.redacted_text.clone()
        });
        return Ok(BoundaryDecision {
            accepted: true,
            disposition: BoundaryDisposition::EgressViaAirGap,
            transcript_storage_allowed: true,
            storage_allowed: false,
            learning_allowed: learning_consent_granted
                && interpretation.safe_for_learning
                && !high_sensitivity,
            egress_allowed: true,
            air_gap_required: true,
            reason_codes: vec!["egress_requires_air_gap".to_string()],
            sanitized_artifact: artifact,
            vibe_mutation_decision: denied_vibe_mutation("egress_requires_air_gap"),
            egress_purpose,
            schema_version: 1,
        });
    }

    if !learning_consent_granted || !interpretation.safe_for_learning || high_sensitivity {
        let mut reasons = Vec::new();
        if !learning_consent_granted {
            reasons.push(if matches!(privacy_mode, BoundaryPrivacyMode::Governance) {
                "missing_governance_runtime_learning_consent".to_string()
            } else {
                "missing_user_runtime_learning_consent".to_string()
            });
        }
        if !interpretation.safe_for_learning {
            reasons.push("unsafe_for_learning".to_string());
        }
        if high_sensitivity {
            reasons.push("high_privacy_sensitivity".to_string());
        }
        return Ok(local_only_decision(
            reasons,
            sanitized_artifact,
            false,
            false,
            egress_purpose,
        ));
    }

    Ok(BoundaryDecision {
        accepted: true,
        disposition: BoundaryDisposition::StoreSanitized,
        transcript_storage_allowed: true,
        storage_allowed: true,
        learning_allowed: true,
        egress_allowed: false,
        air_gap_required: false,
        reason_codes: vec![if matches!(privacy_mode, BoundaryPrivacyMode::Governance) {
            "accepted_for_governance_learning".to_string()
        } else {
            "accepted_for_local_learning".to_string()
        }],
        sanitized_artifact,
        vibe_mutation_decision: allowed_vibe_mutation(&privacy_mode),
        egress_purpose,
        schema_version: 1,
    })
}

fn compile_air_gap_transfer(payload: &Map<String, Value>) -> Result<Value, String> {
    let decision: BoundaryDecision =
        deserialize_or_default(payload.get("decision").cloned(), Value::Object(Map::new()))?;
    Ok(json!({
        "required": decision.air_gap_required,
        "accepted": decision.egress_allowed,
        "payload": decision.sanitized_artifact.share_payload,
        "summary": decision.sanitized_artifact.summary,
        "actor": decision.sanitized_artifact.pseudonymous_actor_ref,
        "vibe_mutation_decision": decision.vibe_mutation_decision,
    }))
}

fn block_decision(reason: &str, sanitized_artifact: BoundarySanitizedArtifact) -> BoundaryDecision {
    BoundaryDecision {
        accepted: false,
        disposition: BoundaryDisposition::Block,
        transcript_storage_allowed: false,
        storage_allowed: false,
        learning_allowed: false,
        egress_allowed: false,
        air_gap_required: false,
        reason_codes: vec![reason.to_string()],
        sanitized_artifact,
        vibe_mutation_decision: denied_vibe_mutation(reason),
        egress_purpose: BoundaryEgressPurpose::None,
        schema_version: 1,
    }
}

fn local_only_decision(
    reason_codes: Vec<String>,
    sanitized_artifact: BoundarySanitizedArtifact,
    storage_allowed: bool,
    learning_allowed: bool,
    egress_purpose: BoundaryEgressPurpose,
) -> BoundaryDecision {
    BoundaryDecision {
        accepted: true,
        disposition: BoundaryDisposition::LocalOnly,
        transcript_storage_allowed: true,
        storage_allowed,
        learning_allowed,
        egress_allowed: false,
        air_gap_required: false,
        reason_codes,
        sanitized_artifact,
        vibe_mutation_decision: denied_vibe_mutation("local_only"),
        egress_purpose,
        schema_version: 1,
    }
}

fn allowed_vibe_mutation(privacy_mode: &BoundaryPrivacyMode) -> VibeMutationDecision {
    VibeMutationDecision {
        state_write_allowed: true,
        dna_write_allowed: true,
        pheromone_write_allowed: true,
        behavior_write_allowed: true,
        affective_write_allowed: true,
        style_write_allowed: true,
        reason_codes: vec!["boundary_approved".to_string()],
        governance_scope: if matches!(privacy_mode, BoundaryPrivacyMode::Governance) {
            "governance".to_string()
        } else {
            "personal".to_string()
        },
        air_gap_envelope_required: false,
        schema_version: 1,
    }
}

fn denied_vibe_mutation(reason: &str) -> VibeMutationDecision {
    VibeMutationDecision {
        state_write_allowed: false,
        dna_write_allowed: false,
        pheromone_write_allowed: false,
        behavior_write_allowed: false,
        affective_write_allowed: false,
        style_write_allowed: false,
        reason_codes: vec![reason.to_string()],
        governance_scope: "personal".to_string(),
        air_gap_envelope_required: false,
        schema_version: 1,
    }
}

fn default_egress_purpose() -> BoundaryEgressPurpose {
    BoundaryEgressPurpose::None
}

fn default_governance_scope() -> String {
    "personal".to_string()
}

fn default_vibe_mutation_decision() -> VibeMutationDecision {
    denied_vibe_mutation("missing_vibe_mutation_decision")
}

fn schema_version() -> u32 {
    1
}

fn safe_claims(interpretation: &InterpretationResult) -> Vec<String> {
    let mut claims = Vec::new();
    if !interpretation.request_artifact.summary.is_empty() {
        claims.push(interpretation.request_artifact.summary.clone());
    }
    for signal in interpretation
        .request_artifact
        .preference_signals
        .iter()
        .take(3)
    {
        claims.push(format!(
            "Preference signal: {} -> {}",
            signal.kind, signal.value
        ));
    }
    claims
}

fn redact_text(raw: &str) -> String {
    let mut redacted = raw.to_string();
    if raw.contains('@') {
        redacted = redacted.replace('@', "[at]");
    }
    if raw.contains("http://") || raw.contains("https://") {
        redacted = redacted
            .replace("http://", "[url]")
            .replace("https://", "[url]");
    }
    let mut chars = Vec::with_capacity(redacted.len());
    for char in redacted.chars() {
        if char.is_ascii_digit() {
            chars.push('x');
        } else {
            chars.push(char);
        }
    }
    chars.into_iter().collect()
}

fn pseudo_ref(actor_agent_id: &str) -> String {
    let tail = if actor_agent_id.len() > 6 {
        &actor_agent_id[actor_agent_id.len() - 6..]
    } else {
        actor_agent_id
    };
    format!("anon_{tail}")
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

fn looks_like_direct_identifier(text: &str) -> bool {
    let digits = text.chars().filter(|char| char.is_ascii_digit()).count();
    (text.contains('@') && text.contains('.'))
        || digits >= 10
        || text.contains("http://")
        || text.contains("https://")
}

fn deserialize_or_default<T>(value: Option<Value>, default_value: Value) -> Result<T, String>
where
    T: for<'de> Deserialize<'de>,
{
    serde_json::from_value(value.unwrap_or(default_value))
        .map_err(|error| format!("value decode failed: {error}"))
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            "{{\"ok\":false,\"handled\":false,\"payload\":null,\"error\":\"response encode failed: {error}\"}}"
        )
    });
    CString::new(json).unwrap().into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn forces_air_gap_for_opted_in_share() {
        let interpretation = json!({
            "normalized_text": "Send this to my friend later.",
            "request_artifact": {
                "summary": "User asked to share",
                "asks_for_response": true,
                "asks_for_recommendation": false,
                "asks_for_action": false,
                "asks_for_explanation": false,
                "referenced_entities": [],
                "questions": [],
                "preference_signals": [],
                "share_intent": true
            },
            "learning_artifact": {
                "vocabulary": ["send", "friend"],
                "phrases": ["send this"],
                "tone_metrics": {"directness": 0.8},
                "directness_preference": 0.8,
                "brevity_preference": 0.7,
                "schema_version": 1
            },
            "privacy_sensitivity": "medium",
            "confidence": 0.8,
            "ambiguity_flags": [],
            "needs_clarification": false,
            "safe_for_learning": true,
            "schema_version": 1
        });
        let payload = Map::from_iter(vec![
            (
                "actor_agent_id".to_string(),
                Value::String("agt_123456".to_string()),
            ),
            (
                "raw_text".to_string(),
                Value::String("Send this to my friend later.".to_string()),
            ),
            (
                "privacy_mode".to_string(),
                Value::String("ai2ai_opt_in".to_string()),
            ),
            ("share_requested".to_string(), Value::Bool(true)),
            (
                "consent_scopes".to_string(),
                Value::Array(vec![Value::String("ai2ai_learning".to_string())]),
            ),
            ("interpretation".to_string(), interpretation),
        ]);

        let decision = enforce_boundary(&payload).expect("should decide");
        assert!(decision.egress_allowed);
        assert!(decision.air_gap_required);
        assert!(matches!(
            decision.disposition,
            BoundaryDisposition::EgressViaAirGap
        ));
    }

    #[test]
    fn accepts_governance_learning_with_governance_consent() {
        let interpretation = json!({
            "normalized_text": "Group low-coherence anomalies under transport drift.",
            "request_artifact": {
                "summary": "User said: Group low-coherence anomalies under transport drift.",
                "asks_for_response": true,
                "asks_for_recommendation": false,
                "asks_for_action": false,
                "asks_for_explanation": false,
                "referenced_entities": [],
                "questions": [],
                "preference_signals": [],
                "share_intent": false
            },
            "learning_artifact": {
                "vocabulary": ["group", "coherence", "transport", "drift"],
                "phrases": ["transport drift"],
                "tone_metrics": {"directness": 0.7},
                "directness_preference": 0.7,
                "brevity_preference": 0.6,
                "schema_version": 1
            },
            "privacy_sensitivity": "low",
            "confidence": 0.86,
            "ambiguity_flags": [],
            "needs_clarification": false,
            "safe_for_learning": true,
            "schema_version": 1
        });
        let payload = Map::from_iter(vec![
            (
                "actor_agent_id".to_string(),
                Value::String("agt_governance_world".to_string()),
            ),
            (
                "raw_text".to_string(),
                Value::String("Group low-coherence anomalies under transport drift.".to_string()),
            ),
            (
                "privacy_mode".to_string(),
                Value::String("governance".to_string()),
            ),
            ("share_requested".to_string(), Value::Bool(false)),
            (
                "consent_scopes".to_string(),
                Value::Array(vec![Value::String(
                    "governance_runtime_learning".to_string(),
                )]),
            ),
            ("interpretation".to_string(), interpretation),
        ]);

        let decision = enforce_boundary(&payload).expect("should decide");
        assert!(decision.learning_allowed);
        assert!(matches!(
            decision.disposition,
            BoundaryDisposition::StoreSanitized
        ));
        assert_eq!(
            decision.reason_codes,
            vec!["accepted_for_governance_learning".to_string()]
        );
    }
}
