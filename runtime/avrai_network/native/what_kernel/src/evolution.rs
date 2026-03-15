use crate::affordance;
use crate::models::{WhatSourceMix, WhatState};
use crate::ontology::Classification;
use chrono::{DateTime, Utc};

pub fn build_initial_state(
    entity_ref: &str,
    classification: &Classification,
    observed_at_utc: &str,
    source_mix: WhatSourceMix,
    confidence: f64,
) -> WhatState {
    WhatState {
        entity_ref: entity_ref.to_string(),
        canonical_type: classification.canonical_type.clone(),
        subtypes: classification.subtypes.clone(),
        aliases: classification.aliases.clone(),
        place_type: classification.place_type.clone(),
        activity_types: classification.activity_types.clone(),
        social_contexts: classification.social_contexts.clone(),
        affordance_vector: affordance::affordance_vector_for(
            &classification.canonical_type,
            &classification.activity_types,
        ),
        vibe_signature: affordance::vibe_signature_for(
            &classification.canonical_type,
            &classification.activity_types,
        ),
        user_relation: "neutral".to_string(),
        lifecycle_state: "candidate".to_string(),
        novelty: 0.86,
        familiarity: 0.14,
        trust: 0.18,
        saturation: 0.06,
        confidence,
        evidence_count: 1,
        first_observed_at_utc: observed_at_utc.to_string(),
        last_observed_at_utc: observed_at_utc.to_string(),
        source_mix,
        lineage_refs: classification.lineage_refs.clone(),
    }
}

pub fn evolve_state(
    existing: Option<WhatState>,
    classification: &Classification,
    observed_at_utc: &str,
    source_mix: WhatSourceMix,
    confidence_hint: f64,
    observation_kind: Option<&str>,
) -> WhatState {
    match existing {
        None => build_initial_state(
            classification
                .aliases
                .first()
                .map(String::as_str)
                .unwrap_or("unknown_entity"),
            classification,
            observed_at_utc,
            source_mix,
            confidence_hint.max(0.38),
        ),
        Some(mut state) => {
            merge_unique(&mut state.subtypes, &classification.subtypes);
            merge_unique(&mut state.aliases, &classification.aliases);
            merge_unique(&mut state.activity_types, &classification.activity_types);
            merge_unique(&mut state.social_contexts, &classification.social_contexts);
            merge_unique(&mut state.lineage_refs, &classification.lineage_refs);
            if classification.canonical_type != "destination_venue" {
                state.canonical_type = classification.canonical_type.clone();
            }
            if classification.place_type != "destination_venue" {
                state.place_type = classification.place_type.clone();
            }
            state.evidence_count += 1;
            state.last_observed_at_utc = observed_at_utc.to_string();
            state.confidence = (state.confidence + confidence_hint + 0.10).min(0.96);
            state.familiarity = (state.familiarity + 0.12).min(1.0);
            state.novelty = (state.novelty - 0.09).max(0.05);
            state.trust = (state.trust + 0.11).min(1.0);
            state.saturation = (state.saturation + saturation_delta(state.evidence_count)).min(1.0);
            state.source_mix = merge_source_mix(&state.source_mix, &source_mix);
            state.affordance_vector =
                affordance::affordance_vector_for(&state.canonical_type, &state.activity_types);
            state.vibe_signature =
                affordance::vibe_signature_for(&state.canonical_type, &state.activity_types);
            state.lifecycle_state = lifecycle_for(&state);
            state.user_relation = user_relation_for(&state, observation_kind);
            state
        }
    }
}

pub fn decay_state(mut state: WhatState, now_utc: &str) -> WhatState {
    let observed = parse_time(&state.last_observed_at_utc);
    let now = parse_time(now_utc);
    let age_days = now.signed_duration_since(observed).num_days();
    if age_days > 14 {
        state.novelty = (state.novelty + 0.08).min(1.0);
        state.trust = (state.trust - 0.12).max(0.0);
    }
    if age_days > 30 {
        state.lifecycle_state = "retired".to_string();
        state.confidence = (state.confidence - 0.14).max(0.0);
    }
    state
}

fn lifecycle_for(state: &WhatState) -> String {
    if state.evidence_count >= 10 && state.novelty <= 0.22 {
        return "overexposed".to_string();
    }
    if state.evidence_count >= 7 && state.trust >= 0.70 {
        return "trusted".to_string();
    }
    if state.evidence_count >= 3 && state.confidence >= 0.55 {
        return "established".to_string();
    }
    "candidate".to_string()
}

fn user_relation_for(state: &WhatState, observation_kind: Option<&str>) -> String {
    match observation_kind.unwrap_or_default() {
        "list_interaction" if state.trust >= 0.45 => "curious_about".to_string(),
        "event_attendance" | "visit" if state.evidence_count >= 4 => "prefers".to_string(),
        "passive_dwell" if state.evidence_count >= 6 => "contextual_like".to_string(),
        _ if state.saturation >= 0.86 && state.trust >= 0.65 => "used_to_like".to_string(),
        _ => state.user_relation.clone(),
    }
}

fn saturation_delta(evidence_count: i64) -> f64 {
    if evidence_count >= 8 {
        0.16
    } else if evidence_count >= 4 {
        0.08
    } else {
        0.03
    }
}

fn merge_unique(target: &mut Vec<String>, extra: &[String]) {
    for value in extra {
        if !target.iter().any(|entry| entry == value) {
            target.push(value.clone());
        }
    }
}

fn merge_source_mix(current: &WhatSourceMix, incoming: &WhatSourceMix) -> WhatSourceMix {
    WhatSourceMix {
        tuple: (current.tuple + incoming.tuple).min(1.0),
        structured: (current.structured + incoming.structured).min(1.0),
        mesh: (current.mesh + incoming.mesh).min(1.0),
        federated: (current.federated + incoming.federated).min(1.0),
    }
}

fn parse_time(value: &str) -> DateTime<Utc> {
    DateTime::parse_from_rfc3339(value)
        .map(|entry| entry.with_timezone(&Utc))
        .unwrap_or_else(|_| Utc::now())
}
