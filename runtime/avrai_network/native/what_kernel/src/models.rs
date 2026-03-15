use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

#[derive(Debug, Deserialize)]
pub struct NativeRequest {
    pub syscall: String,
    #[serde(default)]
    pub payload: Map<String, Value>,
}

#[derive(Debug, Serialize)]
pub struct NativeResponse {
    pub ok: bool,
    pub handled: bool,
    pub payload: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhatSourceMix {
    #[serde(default)]
    pub tuple: f64,
    #[serde(default)]
    pub structured: f64,
    #[serde(default)]
    pub mesh: f64,
    #[serde(default)]
    pub federated: f64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhatState {
    pub entity_ref: String,
    pub canonical_type: String,
    #[serde(default)]
    pub subtypes: Vec<String>,
    #[serde(default)]
    pub aliases: Vec<String>,
    pub place_type: String,
    #[serde(default)]
    pub activity_types: Vec<String>,
    #[serde(default)]
    pub social_contexts: Vec<String>,
    #[serde(default)]
    pub affordance_vector: Map<String, Value>,
    #[serde(default)]
    pub vibe_signature: Map<String, Value>,
    pub user_relation: String,
    pub lifecycle_state: String,
    pub novelty: f64,
    pub familiarity: f64,
    pub trust: f64,
    pub saturation: f64,
    pub confidence: f64,
    pub evidence_count: i64,
    pub first_observed_at_utc: String,
    pub last_observed_at_utc: String,
    #[serde(default)]
    pub source_mix: WhatSourceMix,
    #[serde(default)]
    pub lineage_refs: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhatKernelSnapshot {
    pub agent_id: String,
    pub saved_at_utc: String,
    #[serde(default)]
    pub states: Vec<WhatState>,
    pub schema_version: u32,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhatProjection {
    pub base_entity_ref: String,
    #[serde(default)]
    pub projected_types: Vec<String>,
    #[serde(default)]
    pub projected_affordances: Map<String, Value>,
    #[serde(default)]
    pub projected_vibe_signature: Map<String, Value>,
    #[serde(default)]
    pub adjacent_opportunities: Vec<String>,
    pub confidence: f64,
    pub basis: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct NativeWhatPersistenceEnvelope {
    #[serde(default = "default_schema_version")]
    pub schema_version: u32,
    #[serde(default)]
    pub saved_at_utc: String,
    #[serde(default)]
    pub snapshots: std::collections::HashMap<String, WhatKernelSnapshot>,
    #[serde(default)]
    pub entity_registry: std::collections::HashMap<String, WhatState>,
    #[serde(default)]
    pub relation_registry: std::collections::HashMap<String, String>,
    #[serde(default)]
    pub projection_cache: std::collections::HashMap<String, WhatProjection>,
}

pub fn default_schema_version() -> u32 {
    1
}
