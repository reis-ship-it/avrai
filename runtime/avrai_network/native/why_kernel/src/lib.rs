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

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum WhyRootCauseType {
    TraitDriven,
    ContextDriven,
    SocialDriven,
    Temporal,
    Locality,
    Policy,
    Pheromone,
    Mechanism,
    Mixed,
    Unknown,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct WhySignal {
    label: String,
    weight: f64,
    source: String,
    durable: bool,
}

#[no_mangle]
pub extern "C" fn avrai_why_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
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
pub extern "C" fn avrai_why_kernel_free_string(ptr: *mut c_char) {
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
        "explain_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: explain_why(&request.payload),
            error: None,
        }),
        "classify_root_cause" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({
                "root_cause_type": explain_why(&request.payload)
                    .get("root_cause_type")
                    .cloned()
                    .unwrap_or(Value::Null),
            }),
            error: None,
        }),
        "conviction_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: conviction_why(&request.payload),
            error: None,
        }),
        "counterfactual_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: counterfactual_why(&request.payload),
            error: None,
        }),
        "anomaly_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: anomaly_why(&request.payload),
            error: None,
        }),
        "snapshot_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_why(&request.payload),
            error: None,
        }),
        "replay_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: replay_why(&request.payload),
            error: None,
        }),
        "recover_why" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: recover_why(&request.payload),
            error: None,
        }),
        "project_why_reality" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_why_reality(&request.payload),
            error: None,
        }),
        "project_why_governance" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: project_why_governance(&request.payload),
            error: None,
        }),
        "score_failure_signature" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: explain_why(&request.payload)
                .get("failure_signature")
                .cloned()
                .unwrap_or(Value::Null),
            error: None,
        }),
        "diagnose_why_kernel" => Ok(NativeResponse {
            ok: true,
            handled: true,
            payload: json!({"status": "ok", "kernel": "why", "schemaVersion": 1}),
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

fn explain_why(payload: &Map<String, Value>) -> Value {
    let goal = payload
        .get("goal")
        .and_then(Value::as_str)
        .unwrap_or("explain_outcome");
    let actual_outcome = payload
        .get("actual_outcome")
        .and_then(Value::as_str)
        .unwrap_or("observed_outcome");
    let actual_outcome_score = payload
        .get("actual_outcome_score")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let bundle = payload
        .get("bundle")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let mut signals = explicit_signals(payload);
    signals.extend(bundle_signals(&bundle));

    let mut drivers = signals
        .iter()
        .filter(|signal| signal.weight > 0.0)
        .cloned()
        .collect::<Vec<_>>();
    let mut inhibitors = signals
        .iter()
        .filter(|signal| signal.weight < 0.0)
        .cloned()
        .map(|signal| WhySignal {
            weight: signal.weight.abs(),
            ..signal
        })
        .collect::<Vec<_>>();

    drivers.sort_by(|left, right| right.weight.total_cmp(&left.weight));
    inhibitors.sort_by(|left, right| right.weight.total_cmp(&left.weight));
    drivers.truncate(3);
    inhibitors.truncate(3);

    let root_cause_type = classify_root_cause(&signals);
    let confidence = estimate_confidence(&signals);
    let recommendation_action = recommendation_action(
        actual_outcome,
        inhibitors.first(),
        actual_outcome_score,
    );
    let failure_signature = if is_negative_outcome(actual_outcome, actual_outcome_score) {
        Some(failure_signature(actual_outcome, inhibitors.first(), goal))
    } else {
        None
    };

    json!({
        "goal": goal,
        "summary": build_summary(goal, actual_outcome, &root_cause_type, &drivers, &inhibitors),
        "root_cause_type": serde_json::to_value(root_cause_type).unwrap_or(json!("unknown")),
        "confidence": confidence,
        "drivers": drivers,
        "inhibitors": inhibitors,
        "counterfactuals": build_counterfactuals(&drivers, &inhibitors),
        "failure_signature": failure_signature,
        "recommendation_action": recommendation_action,
        "schema_version": 1,
        "created_at_utc": iso_timestamp_now(),
    })
}

fn conviction_why(payload: &Map<String, Value>) -> Value {
    let snapshot = explain_why(payload);
    let confidence = snapshot
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let conviction_tier = if confidence >= 0.85 {
        "high"
    } else if confidence >= 0.6 {
        "medium"
    } else {
        "low"
    };
    json!({
        "goal": snapshot.get("goal").cloned().unwrap_or_else(|| json!("explain_outcome")),
        "conviction_tier": conviction_tier,
        "confidence": confidence,
        "summary": snapshot.get("summary").cloned().unwrap_or_else(|| json!("No causal attribution available.")),
    })
}

fn counterfactual_why(payload: &Map<String, Value>) -> Value {
    let request_payload = payload
        .get("request")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_default();
    let condition = payload
        .get("condition")
        .and_then(Value::as_str)
        .unwrap_or("unknown_condition");
    let snapshot = explain_why(&request_payload);
    let matched = snapshot
        .get("counterfactuals")
        .and_then(Value::as_array)
        .and_then(|entries| {
            entries.iter().find(|entry| {
                entry.get("condition")
                    .and_then(Value::as_str)
                    == Some(condition)
            })
        })
        .cloned();
    matched.unwrap_or_else(|| {
        let confidence = snapshot
            .get("confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        json!({
            "condition": condition,
            "expected_effect": "Outcome may shift if the condition is applied",
            "confidence_delta": (confidence * 0.2).clamp(0.0, 0.25),
        })
    })
}

fn anomaly_why(payload: &Map<String, Value>) -> Value {
    let snapshot = explain_why(payload);
    let confidence = snapshot
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let actual_outcome_score = payload
        .get("actual_outcome_score")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let anomalous = snapshot.get("failure_signature").is_some()
        || actual_outcome_score < 0.0
        || confidence < 0.35;
    json!({
        "anomalous": anomalous,
        "summary": if anomalous {
            "why kernel detected a potentially abnormal reasoning pattern"
        } else {
            "why kernel did not detect abnormal reasoning"
        },
        "severity": if anomalous {
            payload.get("severity").and_then(Value::as_str).unwrap_or("medium")
        } else {
            "none"
        },
    })
}

fn snapshot_why(payload: &Map<String, Value>) -> Value {
    let goal = payload
        .get("goal_id")
        .and_then(Value::as_str)
        .unwrap_or("explain_outcome");
    explain_why(&Map::from_iter(vec![
        ("goal".to_string(), json!(goal)),
        ("bundle".to_string(), json!({})),
    ]))
}

fn replay_why(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("why");
    let snapshot = snapshot_why(&Map::from_iter(vec![(
        "goal_id".to_string(),
        json!(subject_id),
    )]));
    json!({
        "records": [
            {
                "domain": "why",
                "record_id": format!("why:{subject_id}"),
                "occurred_at_utc": snapshot.get("created_at_utc").cloned().unwrap_or_else(|| json!(iso_timestamp_now())),
                "summary": snapshot.get("summary").cloned().unwrap_or_else(|| json!("No causal attribution available.")),
                "payload": snapshot,
            }
        ]
    })
}

fn recover_why(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("why");
    let restored_count = payload
        .get("persisted_envelope")
        .and_then(Value::as_object)
        .map(|_| 1)
        .unwrap_or(0);
    json!({
        "domain": "why",
        "subject_id": subject_id,
        "restored_count": restored_count,
        "dropped_count": 0,
        "recovered_at_utc": iso_timestamp_now(),
        "summary": format!("why recovery baseline completed for {subject_id}"),
    })
}

fn project_why_reality(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("why");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_why(&Map::from_iter(vec![(
                "goal_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    json!({
        "summary": snapshot.get("summary").cloned().unwrap_or_else(|| json!("No causal attribution available.")),
        "confidence": snapshot.get("confidence").cloned().unwrap_or_else(|| json!(0.0)),
        "features": {
            "goal": snapshot.get("goal").cloned().unwrap_or(Value::Null),
            "root_cause_type": snapshot.get("root_cause_type").cloned().unwrap_or(Value::Null),
            "recommendation_action": snapshot.get("recommendation_action").cloned().unwrap_or(Value::Null),
        },
        "payload": snapshot,
    })
}

fn project_why_governance(payload: &Map<String, Value>) -> Value {
    let subject_id = payload
        .get("subject_id")
        .and_then(Value::as_str)
        .unwrap_or("why");
    let snapshot = payload
        .get("snapshot")
        .and_then(Value::as_object)
        .cloned()
        .unwrap_or_else(|| {
            snapshot_why(&Map::from_iter(vec![(
                "goal_id".to_string(),
                json!(subject_id),
            )]))
            .as_object()
            .cloned()
            .unwrap_or_default()
        });
    let mut highlights = vec![
        snapshot
            .get("root_cause_type")
            .cloned()
            .unwrap_or_else(|| json!("unknown")),
    ];
    if let Some(action) = snapshot.get("recommendation_action").cloned() {
        highlights.push(action);
    }
    json!({
        "domain": "why",
        "summary": snapshot.get("summary").cloned().unwrap_or_else(|| json!("No causal attribution available.")),
        "confidence": snapshot.get("confidence").cloned().unwrap_or_else(|| json!(0.0)),
        "highlights": highlights,
        "payload": snapshot,
    })
}

fn explicit_signals(payload: &Map<String, Value>) -> Vec<WhySignal> {
    let mut signals = Vec::new();
    signals.extend(read_signal_family(payload, "core_signals", "core", true));
    signals.extend(read_signal_family(
        payload,
        "pheromone_signals",
        "pheromone",
        false,
    ));
    signals.extend(read_signal_family(payload, "policy_signals", "policy", false));
    signals
}

fn read_signal_family(
    payload: &Map<String, Value>,
    key: &str,
    default_source: &str,
    durable: bool,
) -> Vec<WhySignal> {
    payload
        .get(key)
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default()
        .iter()
        .filter_map(|entry| entry.as_object())
        .map(|entry| WhySignal {
            label: entry
                .get("label")
                .and_then(Value::as_str)
                .unwrap_or("unknown_signal")
                .to_string(),
            weight: entry.get("weight").and_then(Value::as_f64).unwrap_or(0.0),
            source: entry
                .get("source")
                .and_then(Value::as_str)
                .unwrap_or(default_source)
                .to_string(),
            durable: entry.get("durable").and_then(Value::as_bool).unwrap_or(durable),
        })
        .collect()
}

fn bundle_signals(bundle: &Map<String, Value>) -> Vec<WhySignal> {
    let mut signals = Vec::new();

    if let Some(who) = bundle.get("who").and_then(Value::as_object) {
        let confidence = who
            .get("identity_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        signals.push(WhySignal {
            label: "identity_confidence".to_string(),
            weight: confidence - 0.5,
            source: "who".to_string(),
            durable: false,
        });
    }

    if let Some(what) = bundle.get("what").and_then(Value::as_object) {
        let confidence = what
            .get("taxonomy_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        signals.push(WhySignal {
            label: "taxonomy_confidence".to_string(),
            weight: confidence - 0.5,
            source: "what".to_string(),
            durable: false,
        });
    }

    if let Some(when) = bundle.get("when").and_then(Value::as_object) {
        let freshness = when.get("freshness").and_then(Value::as_f64).unwrap_or(0.5);
        let timing_conflicts = when
            .get("timing_conflict_flags")
            .and_then(Value::as_array)
            .map(|entries| entries.len())
            .unwrap_or(0);
        signals.push(WhySignal {
            label: "temporal_freshness".to_string(),
            weight: freshness - 0.5,
            source: "when".to_string(),
            durable: false,
        });
        if timing_conflicts > 0 {
            signals.push(WhySignal {
                label: "timing_conflict".to_string(),
                weight: -0.55,
                source: "when".to_string(),
                durable: false,
            });
        }
    }

    if let Some(where_kernel) = bundle.get("where").and_then(Value::as_object) {
        let spatial_confidence = where_kernel
            .get("spatial_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.5);
        let boundary_tension = where_kernel
            .get("boundary_tension")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        let travel_friction = where_kernel
            .get("travel_friction")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        signals.push(WhySignal {
            label: "spatial_confidence".to_string(),
            weight: spatial_confidence - 0.5,
            source: "where".to_string(),
            durable: false,
        });
        signals.push(WhySignal {
            label: "boundary_tension".to_string(),
            weight: -boundary_tension,
            source: "where".to_string(),
            durable: false,
        });
        signals.push(WhySignal {
            label: "travel_friction".to_string(),
            weight: -travel_friction,
            source: "where".to_string(),
            durable: false,
        });
    }

    if let Some(how) = bundle.get("how").and_then(Value::as_object) {
        let mechanism_confidence = how
            .get("mechanism_confidence")
            .and_then(Value::as_f64)
            .unwrap_or(0.5);
        let failure_mechanism = how
            .get("failure_mechanism")
            .and_then(Value::as_str)
            .unwrap_or("none");
        signals.push(WhySignal {
            label: "mechanism_confidence".to_string(),
            weight: mechanism_confidence - 0.5,
            source: "how".to_string(),
            durable: false,
        });
        if failure_mechanism != "none" {
            signals.push(WhySignal {
                label: failure_mechanism.to_string(),
                weight: -0.62,
                source: "how".to_string(),
                durable: false,
            });
        }
    }

    signals
}

fn classify_root_cause(signals: &[WhySignal]) -> WhyRootCauseType {
    if signals.is_empty() {
        return WhyRootCauseType::Unknown;
    }

    let mut totals = std::collections::HashMap::<String, f64>::new();
    for signal in signals {
        *totals.entry(signal.source.clone()).or_insert(0.0) += signal.weight.abs();
    }
    let mut entries = totals.into_iter().collect::<Vec<_>>();
    entries.sort_by(|left, right| right.1.total_cmp(&left.1));
    if entries.is_empty() || entries[0].1 < 0.30 {
        return WhyRootCauseType::Unknown;
    }
    if entries.len() > 1 && entries[1].1 / entries[0].1 >= 0.25 {
        return WhyRootCauseType::Mixed;
    }

    match entries[0].0.as_str() {
        "core" => WhyRootCauseType::TraitDriven,
        "pheromone" => WhyRootCauseType::Pheromone,
        "policy" => WhyRootCauseType::Policy,
        "who" => WhyRootCauseType::SocialDriven,
        "what" => WhyRootCauseType::ContextDriven,
        "when" => WhyRootCauseType::Temporal,
        "where" => WhyRootCauseType::Locality,
        "how" => WhyRootCauseType::Mechanism,
        _ => WhyRootCauseType::Unknown,
    }
}

fn estimate_confidence(signals: &[WhySignal]) -> f64 {
    if signals.is_empty() {
        return 0.0;
    }
    let strongest = signals
        .iter()
        .map(|signal| signal.weight.abs())
        .fold(0.0, f64::max)
        .clamp(0.0, 1.0);
    let coverage = (signals.len() as f64 / 8.0).clamp(0.0, 1.0);
    ((strongest * 0.7) + (coverage * 0.3)).clamp(0.0, 1.0)
}

fn is_negative_outcome(actual_outcome: &str, score: f64) -> bool {
    matches!(
        actual_outcome,
        "rejected" | "dismissed" | "failed" | "negative" | "incident"
    ) || score < 0.0
}

fn recommendation_action(
    actual_outcome: &str,
    top_inhibitor: Option<&WhySignal>,
    score: f64,
) -> Value {
    let action = if !is_negative_outcome(actual_outcome, score) {
        "rerank_entity"
    } else if matches!(top_inhibitor.map(|signal| signal.source.as_str()), Some("pheromone")) {
        "retry_after_pheromone_decay"
    } else if matches!(top_inhibitor.map(|signal| signal.source.as_str()), Some("policy")) {
        "suppress_temporarily"
    } else {
        "adjust_confidence"
    };
    json!(action)
}

fn failure_signature(
    actual_outcome: &str,
    top_inhibitor: Option<&WhySignal>,
    goal: &str,
) -> Value {
    let source = top_inhibitor
        .map(|signal| signal.source.as_str())
        .unwrap_or("unknown");
    let family = match source {
        "pheromone" => "pheromone_mismatch",
        "when" => "temporal_misalignment",
        "where" => "locality_conflict",
        "how" => "execution_path_failure",
        "policy" => "policy_conflict",
        _ => "unknown_failure",
    };
    json!({
        "signature_id": format!("{family}:{goal}:{actual_outcome}"),
        "signature_family": family,
        "novelty": "new",
        "replay_risk": "medium",
        "recommended_guardrail": recommendation_action(actual_outcome, top_inhibitor, -1.0),
    })
}

fn build_summary(
    goal: &str,
    actual_outcome: &str,
    root_cause_type: &WhyRootCauseType,
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> String {
    let lead_driver = drivers
        .first()
        .map(|signal| signal.label.as_str())
        .unwrap_or("limited positive evidence");
    let lead_inhibitor = inhibitors
        .first()
        .map(|signal| signal.label.as_str())
        .unwrap_or("limited opposing evidence");
    format!(
        "{goal} led to {actual_outcome} due to {:?}, driven by {lead_driver} and constrained by {lead_inhibitor}.",
        root_cause_type
    )
}

fn build_counterfactuals(drivers: &[WhySignal], inhibitors: &[WhySignal]) -> Value {
    let mut counterfactuals = Vec::new();
    if let Some(inhibitor) = inhibitors.first() {
        counterfactuals.push(json!({
            "condition": format!("Reduce {}", inhibitor.label),
            "expected_effect": "Outcome is more likely to improve",
            "confidence_delta": (inhibitor.weight * 0.35).clamp(0.0, 0.35),
        }));
    }
    if let Some(driver) = drivers.first() {
        counterfactuals.push(json!({
            "condition": format!("Increase {}", driver.label),
            "expected_effect": "Outcome is more likely to repeat",
            "confidence_delta": (driver.weight * 0.25).clamp(0.0, 0.25),
        }));
    }
    if let Some(inhibitor) = inhibitors
        .iter()
        .find(|signal| signal.source == "pheromone" || signal.source == "when")
    {
        counterfactuals.push(json!({
            "condition": format!("Delay until {} decays", inhibitor.label),
            "expected_effect": "Transient inhibitor pressure is reduced",
            "confidence_delta": 0.15,
        }));
    }
    Value::Array(counterfactuals)
}

fn iso_timestamp_now() -> String {
    let micros = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_micros() as i128)
        .unwrap_or(0);
    let secs = micros.div_euclid(1_000_000);
    format!("{secs}Z")
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
    fn explains_mixed_failure() {
        let payload = json!({
            "goal": "recommend_entity",
            "actual_outcome": "rejected",
            "actual_outcome_score": -1.0,
            "bundle": {
                "when": {"freshness": 0.4, "timing_conflict_flags": ["late"]},
                "where": {"spatial_confidence": 0.7, "boundary_tension": 0.2, "travel_friction": 0.1},
                "how": {"mechanism_confidence": 0.6, "failure_mechanism": "ranking_path_miss"},
            },
            "pheromone_signals": [{"label": "social_fatigue", "weight": -0.9}],
            "core_signals": [{"label": "outdoor_affinity", "weight": 0.4}]
        });

        let explained = explain_why(payload.as_object().expect("payload object"));
        assert_eq!(
            explained
                .get("root_cause_type")
                .and_then(Value::as_str)
                .unwrap_or(""),
            "mixed"
        );
        assert!(explained.get("failure_signature").is_some());
    }
}
