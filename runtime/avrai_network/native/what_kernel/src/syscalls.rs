use crate::errors::unsupported_syscall_response;
use crate::evolution::{build_initial_state, decay_state, evolve_state};
use crate::models::{NativeResponse, NativeWhatPersistenceEnvelope, WhatSourceMix, WhatState};
use crate::ontology::classify;
use crate::persistence;
use crate::projection::project_from_state;
use crate::sync::merge_state;
use chrono::Utc;
use serde_json::{json, Map, Value};

pub fn handle_request(request: crate::models::NativeRequest) -> Result<NativeResponse, String> {
    let response = match request.syscall.as_str() {
        "resolve_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: resolve_what(&request.payload),
            error: None,
        },
        "observe_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: observe_what(&request.payload),
            error: None,
        },
        "project_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: project_what(&request.payload),
            error: None,
        },
        "project_what_reality" => NativeResponse {
            ok: true,
            handled: true,
            payload: project_what_reality(&request.payload),
            error: None,
        },
        "project_what_governance" => NativeResponse {
            ok: true,
            handled: true,
            payload: project_what_governance(&request.payload),
            error: None,
        },
        "snapshot_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: snapshot_what(&request.payload),
            error: None,
        },
        "sync_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: sync_what(&request.payload),
            error: None,
        },
        "recover_what" => NativeResponse {
            ok: true,
            handled: true,
            payload: recover_what(&request.payload),
            error: None,
        },
        "diagnose_what_kernel" => NativeResponse {
            ok: true,
            handled: true,
            payload: diagnose_what_kernel(),
            error: None,
        },
        _ => unsupported_syscall_response(),
    };
    Ok(response)
}

fn resolve_what(payload: &Map<String, Value>) -> Value {
    let classification = classify(payload);
    let observed_at = payload
        .get("observedAtUtc")
        .and_then(Value::as_str)
        .map(ToString::to_string)
        .unwrap_or_else(|| Utc::now().to_rfc3339());
    let entity_ref = payload
        .get("entityRef")
        .and_then(Value::as_str)
        .unwrap_or("unknown_entity");
    let state = build_initial_state(
        entity_ref,
        &classification,
        &observed_at,
        source_mix_for(payload, false),
        confidence_hint(payload),
    );
    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        persistence::save_state(agent_id, state.clone());
    }
    serde_json::to_value(state).unwrap_or(Value::Null)
}

fn observe_what(payload: &Map<String, Value>) -> Value {
    let classification = classify(payload);
    let observed_at = payload
        .get("observedAtUtc")
        .and_then(Value::as_str)
        .map(ToString::to_string)
        .unwrap_or_else(|| Utc::now().to_rfc3339());
    let entity_ref = payload
        .get("entityRef")
        .and_then(Value::as_str)
        .unwrap_or("unknown_entity");
    let existing = persistence::entity_registry()
        .lock()
        .expect("entity registry lock poisoned")
        .get(entity_ref)
        .cloned();
    let mut state = evolve_state(
        existing,
        &classification,
        &observed_at,
        source_mix_for(payload, true),
        confidence_hint(payload),
        payload.get("observationKind").and_then(Value::as_str),
    );
    state.entity_ref = entity_ref.to_string();
    state = decay_state(state, &observed_at);
    if let Some(agent_id) = payload.get("agentId").and_then(Value::as_str) {
        persistence::save_state(agent_id, state.clone());
    }
    let projection = project_from_state(&state);
    persistence::save_projection(projection.clone());
    json!({
        "state": state,
        "projection": projection,
        "cloudUpdated": payload
            .get("observationKind")
            .and_then(Value::as_str)
            .map(|kind| kind != "passive_dwell")
            .unwrap_or(true),
        "meshForwarded": payload
            .get("observationKind")
            .and_then(Value::as_str)
            .map(|kind| kind == "mesh_semantic_update")
            .unwrap_or(false),
    })
}

fn project_what(payload: &Map<String, Value>) -> Value {
    if let Some(state_json) = payload.get("state") {
        let state: WhatState = serde_json::from_value(state_json.clone()).unwrap_or_default();
        return serde_json::to_value(project_from_state(&state)).unwrap_or(Value::Null);
    }
    let entity_ref = payload
        .get("entityRef")
        .and_then(Value::as_str)
        .unwrap_or_default();
    if let Some(state) = persistence::entity_registry()
        .lock()
        .expect("entity registry lock poisoned")
        .get(entity_ref)
        .cloned()
    {
        let projection = project_from_state(&state);
        persistence::save_projection(projection.clone());
        return serde_json::to_value(projection).unwrap_or(Value::Null);
    }
    Value::Null
}

fn project_what_reality(payload: &Map<String, Value>) -> Value {
    let projection = project_what(payload);
    let projection_map = projection.as_object().cloned().unwrap_or_default();
    let entity_ref = projection_map
        .get("baseEntityRef")
        .and_then(Value::as_str)
        .unwrap_or("unknown_entity");
    let confidence = projection_map
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let projected_types = projection_map
        .get("projectedTypes")
        .cloned()
        .unwrap_or_else(|| json!([]));
    let adjacent_opportunities = projection_map
        .get("adjacentOpportunities")
        .cloned()
        .unwrap_or_else(|| json!([]));
    json!({
        "summary": format!("Semantic state for {entity_ref}"),
        "confidence": confidence,
        "features": {
            "projected_types": projected_types,
            "adjacent_opportunities": adjacent_opportunities,
        },
        "payload": projection_map,
    })
}

fn project_what_governance(payload: &Map<String, Value>) -> Value {
    let projection = project_what(payload);
    let projection_map = projection.as_object().cloned().unwrap_or_default();
    let entity_ref = projection_map
        .get("baseEntityRef")
        .and_then(Value::as_str)
        .unwrap_or("unknown_entity");
    let confidence = projection_map
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);
    let projected_types = projection_map
        .get("projectedTypes")
        .cloned()
        .unwrap_or_else(|| json!([]));
    json!({
        "domain": "what",
        "summary": format!("Governance semantic view for {entity_ref}"),
        "confidence": confidence,
        "highlights": projected_types,
        "payload": projection_map,
    })
}

fn snapshot_what(payload: &Map<String, Value>) -> Value {
    let agent_id = payload.get("agentId").and_then(Value::as_str).unwrap_or("");
    match persistence::snapshot_for(agent_id) {
        Some(snapshot) => json!({
            "snapshot": snapshot,
            "persistedEnvelope": persistence::envelope(),
        }),
        None => json!({}),
    }
}

fn sync_what(payload: &Map<String, Value>) -> Value {
    let agent_id = payload.get("agentId").and_then(Value::as_str).unwrap_or("");
    let mut accepted = 0;
    let mut rejected = 0;
    let mut merged = Vec::new();
    if let Some(deltas) = payload.get("deltas").and_then(Value::as_array) {
        for delta in deltas {
            if let Ok(incoming) = serde_json::from_value::<WhatState>(delta.clone()) {
                let current = persistence::entity_registry()
                    .lock()
                    .expect("entity registry lock poisoned")
                    .get(&incoming.entity_ref)
                    .cloned();
                let (merged_state, accepted_delta) = merge_state(current, incoming);
                if accepted_delta {
                    accepted += 1;
                } else {
                    rejected += 1;
                }
                merged.push(merged_state.entity_ref.clone());
                persistence::save_state(agent_id, merged_state);
            }
        }
    }
    json!({
        "acceptedCount": accepted,
        "rejectedCount": rejected,
        "mergedEntityRefs": merged,
        "savedAtUtc": Utc::now().to_rfc3339(),
    })
}

fn recover_what(payload: &Map<String, Value>) -> Value {
    let envelope_value = payload
        .get("persistedEnvelope")
        .cloned()
        .unwrap_or_else(|| serde_json::to_value(persistence::envelope()).unwrap_or(Value::Null));
    let envelope: NativeWhatPersistenceEnvelope =
        serde_json::from_value(envelope_value).unwrap_or_default();
    let schema_version = envelope.schema_version;
    let (restored_count, dropped_count) = persistence::restore(envelope);
    json!({
        "restoredCount": restored_count,
        "droppedCount": dropped_count,
        "schemaVersion": schema_version,
        "savedAtUtc": Utc::now().to_rfc3339(),
    })
}

fn diagnose_what_kernel() -> Value {
    json!({
        "domain": "what",
        "status": "healthy",
        "native_backed": true,
        "headless_ready": true,
        "authority_level": "authoritative",
        "summary": "what kernel exposes semantic authority, recovery, and projection surfaces",
        "diagnostics": {
            "kernel": "what",
            "schema_version": 1,
        }
    })
}

fn source_mix_for(payload: &Map<String, Value>, structured: bool) -> WhatSourceMix {
    let tuple_count = payload
        .get("semanticTuples")
        .and_then(Value::as_array)
        .map(|entries| entries.len())
        .unwrap_or(0);
    let observation_kind = payload.get("observationKind").and_then(Value::as_str).unwrap_or("");
    WhatSourceMix {
        tuple: if tuple_count > 0 { 0.65 } else { 0.0 },
        structured: if structured { 0.75 } else { 0.25 },
        mesh: if observation_kind == "mesh_semantic_update" { 0.8 } else { 0.0 },
        federated: if observation_kind == "plugin_semantic_event" { 0.35 } else { 0.0 },
    }
}

fn confidence_hint(payload: &Map<String, Value>) -> f64 {
    payload
        .get("confidence")
        .and_then(Value::as_f64)
        .unwrap_or(0.42)
        .clamp(0.0, 1.0)
}
