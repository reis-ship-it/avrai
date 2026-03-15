use crate::models::{WhatProjection, WhatState};
use serde_json::json;

pub fn project_from_state(state: &WhatState) -> WhatProjection {
    let mut opportunities = Vec::new();
    if state.canonical_type == "cafe" && state.activity_types.iter().any(|item| item == "deep_work") {
        opportunities.push("solo work refuge".to_string());
        opportunities.push("low-pressure meeting space".to_string());
    }
    if state.activity_types.iter().any(|item| item == "date") {
        opportunities.push("repeatable date ritual".to_string());
    }
    if state.social_contexts.iter().any(|item| item == "small_group") {
        opportunities.push("group bonding anchor".to_string());
    }
    if opportunities.is_empty() {
        opportunities.push("adjacent exploration opportunity".to_string());
    }

    let mut projected_affordances = state.affordance_vector.clone();
    projected_affordances
        .entry("ritual_repeatability".to_string())
        .or_insert(json!(0.67));

    WhatProjection {
        base_entity_ref: state.entity_ref.clone(),
        projected_types: vec![state.canonical_type.clone()],
        projected_affordances,
        projected_vibe_signature: state.vibe_signature.clone(),
        adjacent_opportunities: opportunities,
        confidence: (state.confidence + state.trust) / 2.0,
        basis: format!("{}:{}:{}", state.canonical_type, state.lifecycle_state, state.user_relation),
    }
}
