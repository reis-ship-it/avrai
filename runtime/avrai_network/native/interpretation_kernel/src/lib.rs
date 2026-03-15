use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::collections::BTreeSet;
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
enum InterpretationIntent {
    Inform,
    Ask,
    Prefer,
    Correct,
    Confirm,
    Reject,
    Reflect,
    Plan,
    Share,
    Unknown,
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
struct VibeSignal {
    key: String,
    kind: String,
    value: f64,
    confidence: f64,
    provenance: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeEvidence {
    summary: String,
    identity_signals: Vec<VibeSignal>,
    pheromone_signals: Vec<VibeSignal>,
    behavior_signals: Vec<VibeSignal>,
    affective_signals: Vec<VibeSignal>,
    style_signals: Vec<VibeSignal>,
    schema_version: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct InterpretationResult {
    intent: InterpretationIntent,
    normalized_text: String,
    request_artifact: RequestArtifact,
    learning_artifact: LearningArtifact,
    vibe_evidence: VibeEvidence,
    privacy_sensitivity: PrivacySensitivity,
    confidence: f64,
    ambiguity_flags: Vec<String>,
    needs_clarification: bool,
    safe_for_learning: bool,
    schema_version: u32,
}

#[no_mangle]
pub extern "C" fn avrai_interpretation_kernel_invoke_json(
    request_ptr: *const c_char,
) -> *mut c_char {
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
pub extern "C" fn avrai_interpretation_kernel_free_string(ptr: *mut c_char) {
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
        "interpret_human_text" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: serde_json::to_value(interpret_human_text(&request.payload)?)
                .map_err(|error| format!("interpretation encode failed: {error}"))?,
            error: None,
        }),
        "record_interaction_outcome" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: record_interaction_outcome(&request.payload),
            error: None,
        }),
        "snapshot_interpretation_profile" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_interpretation_profile(&request.payload),
            error: None,
        }),
        "diagnose_interpretation_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "status": "ok",
                "kernel": "interpretation",
                "schema_version": 1,
                "local_only": true,
                "cloud_dependency_required": false,
                "bounded_learning_only": true,
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

fn interpret_human_text(payload: &Map<String, Value>) -> Result<InterpretationResult, String> {
    let raw_text = payload
        .get("raw_text")
        .and_then(Value::as_str)
        .unwrap_or("")
        .trim();
    let normalized_text = normalize_text(raw_text);
    let semantic_text = normalized_text.to_lowercase();
    let intent = infer_intent(&semantic_text);
    let share_intent = matches!(intent, InterpretationIntent::Share)
        || contains_any(&semantic_text, &["share", "send this", "tell them"]);
    let asks_for_recommendation = contains_any(
        &semantic_text,
        &["recommend", "suggest", "where should", "what should"],
    );
    let asks_for_action = contains_any(
        &semantic_text,
        &["book", "schedule", "plan", "set up", "help me"],
    );
    let asks_for_explanation = contains_any(&semantic_text, &["why", "how come", "explain"]);
    let questions = extract_questions(&normalized_text);
    let preference_signals = extract_preference_signals(&semantic_text);
    let referenced_entities = extract_referenced_entities(&normalized_text);
    let privacy_sensitivity = infer_privacy_sensitivity(&semantic_text);
    let ambiguity_flags = infer_ambiguity_flags(&semantic_text);
    let needs_clarification = ambiguity_flags.contains(&"ambiguous_request".to_string());
    let confidence = infer_confidence(&semantic_text, &intent, ambiguity_flags.len());
    let safe_for_learning =
        !matches!(privacy_sensitivity, PrivacySensitivity::High) && normalized_text.len() > 2;

    let request_artifact = RequestArtifact {
        summary: summarize_request(&normalized_text, &intent),
        asks_for_response: !normalized_text.is_empty(),
        asks_for_recommendation,
        asks_for_action,
        asks_for_explanation,
        referenced_entities,
        questions,
        preference_signals: preference_signals.clone(),
        share_intent,
    };

    let learning_artifact = LearningArtifact {
        vocabulary: extract_vocabulary(&semantic_text),
        phrases: extract_phrases(&semantic_text),
        tone_metrics: tone_metrics(&semantic_text),
        directness_preference: directness_score(&semantic_text),
        brevity_preference: brevity_score(&semantic_text),
        schema_version: 1,
    };
    let vibe_evidence = derive_vibe_evidence(
        &semantic_text,
        &intent,
        &request_artifact,
        &learning_artifact,
    );

    Ok(InterpretationResult {
        intent,
        normalized_text,
        request_artifact,
        learning_artifact,
        vibe_evidence,
        privacy_sensitivity,
        confidence,
        ambiguity_flags,
        needs_clarification,
        safe_for_learning,
        schema_version: 1,
    })
}

fn record_interaction_outcome(payload: &Map<String, Value>) -> Value {
    json!({
        "accepted": true,
        "local_only": true,
        "outcome": payload.get("outcome").cloned().unwrap_or(Value::String("unknown".to_string())),
        "repair_type": payload.get("repair_type").cloned().unwrap_or(Value::String("none".to_string())),
    })
}

fn snapshot_interpretation_profile(payload: &Map<String, Value>) -> Value {
    json!({
        "profile_ref": payload.get("profile_ref").cloned().unwrap_or(Value::String("default".to_string())),
        "status": "local_profile_only",
        "tracks": ["vocabulary", "phrases", "tone", "repair_history"],
    })
}

fn normalize_text(raw: &str) -> String {
    raw.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn infer_intent(text: &str) -> InterpretationIntent {
    if text.is_empty() {
        return InterpretationIntent::Unknown;
    }
    if text.contains('?') || text.starts_with("what ") || text.starts_with("why ") {
        return InterpretationIntent::Ask;
    }
    if contains_any(
        text,
        &["i like", "i love", "i prefer", "favorite", "i want more"],
    ) {
        return InterpretationIntent::Prefer;
    }
    if contains_any(text, &["actually", "that's wrong", "no,", "not that"]) {
        return InterpretationIntent::Correct;
    }
    if contains_any(text, &["yes", "that's right", "correct"]) {
        return InterpretationIntent::Confirm;
    }
    if contains_any(text, &["don't", "do not", "stop", "no thanks", "hate"]) {
        return InterpretationIntent::Reject;
    }
    if contains_any(text, &["plan", "let's", "i want to go", "schedule"]) {
        return InterpretationIntent::Plan;
    }
    if contains_any(text, &["share", "send this", "tell them"]) {
        return InterpretationIntent::Share;
    }
    if contains_any(text, &["i feel", "i've been", "lately"]) {
        return InterpretationIntent::Reflect;
    }
    InterpretationIntent::Inform
}

fn infer_privacy_sensitivity(text: &str) -> PrivacySensitivity {
    if looks_like_direct_identifier(text)
        || contains_any(
            text,
            &[
                "my address",
                "my email",
                "my phone",
                "ssn",
                "social security",
            ],
        )
    {
        return PrivacySensitivity::High;
    }
    if contains_any(
        text,
        &["my friend", "my mom", "my dad", "meet me", "text me"],
    ) {
        return PrivacySensitivity::Medium;
    }
    PrivacySensitivity::Low
}

fn infer_ambiguity_flags(text: &str) -> Vec<String> {
    let mut flags = Vec::new();
    if text.len() < 3 {
        flags.push("too_short".to_string());
    }
    if contains_any(text, &["maybe", "something", "whatever", "idk"]) {
        flags.push("ambiguous_request".to_string());
    }
    flags
}

fn infer_confidence(text: &str, intent: &InterpretationIntent, ambiguity_count: usize) -> f64 {
    if text.is_empty() {
        return 0.0;
    }
    let mut score = match intent {
        InterpretationIntent::Ask => 0.84,
        InterpretationIntent::Prefer => 0.88,
        InterpretationIntent::Correct => 0.86,
        InterpretationIntent::Plan => 0.78,
        InterpretationIntent::Share => 0.74,
        InterpretationIntent::Unknown => 0.32,
        _ => 0.66,
    };
    score -= ambiguity_count as f64 * 0.12;
    score.clamp(0.0, 0.99)
}

fn derive_vibe_evidence(
    text: &str,
    intent: &InterpretationIntent,
    request_artifact: &RequestArtifact,
    learning_artifact: &LearningArtifact,
) -> VibeEvidence {
    let mut identity_signals = Vec::new();
    let mut pheromone_signals = Vec::new();
    let mut behavior_signals = Vec::new();
    let mut affective_signals = Vec::new();
    let mut style_signals = Vec::new();

    if contains_any(text, &["quiet", "cozy", "slow", "calm"]) {
        identity_signals.push(vibe_signal(
            "energy_preference",
            "identity",
            0.28,
            0.62,
        ));
    }
    if contains_any(text, &["lively", "active", "late night", "buzzing"]) {
        identity_signals.push(vibe_signal(
            "energy_preference",
            "identity",
            0.78,
            0.62,
        ));
    }
    if contains_any(text, &["group", "friends", "community", "together"]) {
        identity_signals.push(vibe_signal(
            "community_orientation",
            "identity",
            0.76,
            0.6,
        ));
    }
    if contains_any(text, &["solo", "alone", "private", "by myself"]) {
        identity_signals.push(vibe_signal(
            "community_orientation",
            "identity",
            0.24,
            0.6,
        ));
    }
    if contains_any(text, &["new", "discover", "explore", "different"]) {
        identity_signals.push(vibe_signal(
            "novelty_seeking",
            "identity",
            0.78,
            0.58,
        ));
        pheromone_signals.push(vibe_signal(
            "novelty_bias",
            "pheromone",
            0.72,
            0.55,
        ));
    }
    if contains_any(text, &["favorite", "usual", "routine", "familiar"]) {
        identity_signals.push(vibe_signal(
            "novelty_seeking",
            "identity",
            0.22,
            0.58,
        ));
    }
    if request_artifact.asks_for_action || matches!(intent, InterpretationIntent::Plan) {
        behavior_signals.push(vibe_signal(
            "action_readiness",
            "behavior",
            0.74,
            0.65,
        ));
    }
    if request_artifact.asks_for_recommendation {
        pheromone_signals.push(vibe_signal(
            "recommendation_receptivity",
            "pheromone",
            0.68,
            0.62,
        ));
    }
    if matches!(intent, InterpretationIntent::Reflect) {
        affective_signals.push(vibe_signal("valence", "affective", 0.45, 0.44));
        affective_signals.push(vibe_signal("arousal", "affective", 0.3, 0.44));
    }

    style_signals.push(vibe_signal(
        "directness",
        "style",
        learning_artifact.directness_preference,
        0.6,
    ));
    style_signals.push(vibe_signal(
        "brevity",
        "style",
        learning_artifact.brevity_preference,
        0.6,
    ));

    VibeEvidence {
        summary: summarize_request(text, intent),
        identity_signals,
        pheromone_signals,
        behavior_signals,
        affective_signals,
        style_signals,
        schema_version: 1,
    }
}

fn vibe_signal(key: &str, kind: &str, value: f64, confidence: f64) -> VibeSignal {
    VibeSignal {
        key: key.to_string(),
        kind: kind.to_string(),
        value,
        confidence,
        provenance: vec!["interpretation_kernel".to_string()],
    }
}

fn summarize_request(text: &str, intent: &InterpretationIntent) -> String {
    let preview = if text.len() > 96 {
        format!("{}...", &text[..96])
    } else {
        text.to_string()
    };
    let prefix = match intent {
        InterpretationIntent::Ask => "User asked",
        InterpretationIntent::Prefer => "User expressed a preference",
        InterpretationIntent::Correct => "User corrected AVRAI",
        InterpretationIntent::Confirm => "User confirmed",
        InterpretationIntent::Reject => "User rejected",
        InterpretationIntent::Plan => "User asked AVRAI to help plan",
        InterpretationIntent::Share => "User asked to share",
        InterpretationIntent::Reflect => "User reflected on their state",
        InterpretationIntent::Unknown => "User input needs clarification",
        InterpretationIntent::Inform => "User informed AVRAI",
    };
    format!("{prefix}: {preview}")
}

fn extract_questions(text: &str) -> Vec<String> {
    if !text.contains('?') {
        return Vec::new();
    }
    text.split('?')
        .map(str::trim)
        .filter(|entry| !entry.is_empty())
        .map(|entry| format!("{entry}?"))
        .collect()
}

fn extract_referenced_entities(text: &str) -> Vec<String> {
    let mut entities = BTreeSet::new();
    for token in text.split_whitespace() {
        let cleaned = token.trim_matches(|char: char| !char.is_alphanumeric());
        if cleaned.len() > 2
            && cleaned
                .chars()
                .next()
                .map(char::is_uppercase)
                .unwrap_or(false)
        {
            entities.insert(cleaned.to_string());
        }
    }
    entities.into_iter().collect()
}

fn extract_preference_signals(text: &str) -> Vec<PreferenceSignal> {
    let mut signals = Vec::new();
    for marker in ["i like", "i love", "i prefer", "i want", "hate"] {
        if let Some(index) = text.find(marker) {
            let tail = text[index + marker.len()..].trim();
            let value = tail
                .split(|char: char| char == ',' || char == '.' || char == '!')
                .next()
                .unwrap_or("")
                .trim()
                .to_string();
            if !value.is_empty() {
                signals.push(PreferenceSignal {
                    kind: marker.replace("i ", "").replace(' ', "_"),
                    value,
                    confidence: 0.8,
                });
            }
        }
    }
    signals
}

fn extract_vocabulary(text: &str) -> Vec<String> {
    let stopwords = [
        "the", "and", "for", "that", "with", "this", "have", "just", "like", "want", "your",
        "about", "would", "could", "should", "from", "into", "they", "them",
    ];
    let mut vocab = BTreeSet::new();
    for token in text.split_whitespace() {
        let cleaned = token
            .trim_matches(|char: char| !char.is_alphanumeric())
            .to_lowercase();
        if cleaned.len() > 3
            && !stopwords.contains(&cleaned.as_str())
            && !cleaned.chars().any(|c| c.is_ascii_digit())
        {
            vocab.insert(cleaned);
        }
    }
    vocab.into_iter().take(12).collect()
}

fn extract_phrases(text: &str) -> Vec<String> {
    let words: Vec<&str> = text
        .split_whitespace()
        .filter(|entry| entry.len() > 2)
        .collect();
    if words.len() < 2 {
        return Vec::new();
    }
    let mut phrases = BTreeSet::new();
    for window in words.windows(2).take(4) {
        phrases.insert(window.join(" ").to_lowercase());
    }
    phrases.into_iter().collect()
}

fn tone_metrics(text: &str) -> Map<String, Value> {
    let enthusiasm = (text.matches('!').count() as f64 / 3.0).clamp(0.0, 1.0);
    let polite_hits = contains_any(text, &["please", "thanks", "thank you"]);
    let formal_hits = contains_any(text, &["would", "could", "appreciate"]);
    let mut metrics = Map::new();
    metrics.insert(
        "formality".to_string(),
        Value::from(if formal_hits { 0.72 } else { 0.46 }),
    );
    metrics.insert(
        "enthusiasm".to_string(),
        Value::from(if polite_hits {
            enthusiasm.max(0.35)
        } else {
            enthusiasm
        }),
    );
    metrics.insert(
        "directness".to_string(),
        Value::from(directness_score(text)),
    );
    metrics
}

fn directness_score(text: &str) -> f64 {
    if contains_any(text, &["please", "could you", "would you"]) {
        0.38
    } else if contains_any(text, &["do this", "show me", "find me", "tell me"]) {
        0.82
    } else {
        0.58
    }
}

fn brevity_score(text: &str) -> f64 {
    let words = text.split_whitespace().count();
    if words <= 6 {
        0.9
    } else if words <= 16 {
        0.62
    } else {
        0.28
    }
}

fn contains_any(text: &str, needles: &[&str]) -> bool {
    needles.iter().any(|needle| text.contains(needle))
}

fn looks_like_direct_identifier(text: &str) -> bool {
    let digits = text.chars().filter(|char| char.is_ascii_digit()).count();
    (text.contains('@') && text.contains('.'))
        || digits >= 10
        || text.contains("http://")
        || text.contains("https://")
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
    fn interprets_preference_text() {
        let payload = Map::from_iter(vec![(
            "raw_text".to_string(),
            Value::String("I like low-key jazz bars and quieter nights.".to_string()),
        )]);

        let result = interpret_human_text(&payload).expect("should interpret");
        assert!(matches!(result.intent, InterpretationIntent::Prefer));
        assert!(result.safe_for_learning);
        assert!(!result.request_artifact.preference_signals.is_empty());
    }
}
