use crate::models::{
    default_schema_version, NativeWhatPersistenceEnvelope, WhatKernelSnapshot, WhatProjection,
    WhatState,
};
use chrono::Utc;
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

static ENTITY_REGISTRY: OnceLock<Mutex<HashMap<String, WhatState>>> = OnceLock::new();
static SNAPSHOT_REGISTRY: OnceLock<Mutex<HashMap<String, WhatKernelSnapshot>>> = OnceLock::new();
static PROJECTION_CACHE: OnceLock<Mutex<HashMap<String, WhatProjection>>> = OnceLock::new();

pub fn entity_registry() -> &'static Mutex<HashMap<String, WhatState>> {
    ENTITY_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

pub fn snapshot_registry() -> &'static Mutex<HashMap<String, WhatKernelSnapshot>> {
    SNAPSHOT_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

pub fn projection_cache() -> &'static Mutex<HashMap<String, WhatProjection>> {
    PROJECTION_CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

pub fn save_state(agent_id: &str, state: WhatState) {
    prune_if_needed();
    entity_registry()
        .lock()
        .expect("entity registry lock poisoned")
        .insert(state.entity_ref.clone(), state.clone());
    let mut snapshots = snapshot_registry()
        .lock()
        .expect("snapshot registry lock poisoned");
    let snapshot = snapshots.entry(agent_id.to_string()).or_insert_with(|| WhatKernelSnapshot {
        agent_id: agent_id.to_string(),
        saved_at_utc: Utc::now().to_rfc3339(),
        states: Vec::new(),
        schema_version: default_schema_version(),
    });
    snapshot.saved_at_utc = Utc::now().to_rfc3339();
    snapshot.states.retain(|entry| entry.entity_ref != state.entity_ref);
    snapshot.states.push(state);
}

pub fn save_projection(projection: WhatProjection) {
    projection_cache()
        .lock()
        .expect("projection cache lock poisoned")
        .insert(projection.base_entity_ref.clone(), projection);
}

pub fn snapshot_for(agent_id: &str) -> Option<WhatKernelSnapshot> {
    snapshot_registry()
        .lock()
        .expect("snapshot registry lock poisoned")
        .get(agent_id)
        .cloned()
}

pub fn envelope() -> NativeWhatPersistenceEnvelope {
    NativeWhatPersistenceEnvelope {
        schema_version: default_schema_version(),
        saved_at_utc: Utc::now().to_rfc3339(),
        snapshots: snapshot_registry()
            .lock()
            .expect("snapshot registry lock poisoned")
            .clone(),
        entity_registry: entity_registry()
            .lock()
            .expect("entity registry lock poisoned")
            .clone(),
        relation_registry: HashMap::new(),
        projection_cache: projection_cache()
            .lock()
            .expect("projection cache lock poisoned")
            .clone(),
    }
}

pub fn restore(envelope: NativeWhatPersistenceEnvelope) -> (usize, usize) {
    let restored = envelope.entity_registry.len();
    *entity_registry().lock().expect("entity registry lock poisoned") = envelope.entity_registry;
    *snapshot_registry()
        .lock()
        .expect("snapshot registry lock poisoned") = envelope.snapshots;
    *projection_cache()
        .lock()
        .expect("projection cache lock poisoned") = envelope.projection_cache;
    (restored, 0)
}

fn prune_if_needed() {
    const MAX_ENTITY_REGISTRY_SIZE: usize = 1024;
    let mut entities = entity_registry().lock().expect("entity registry lock poisoned");
    if entities.len() < MAX_ENTITY_REGISTRY_SIZE {
        return;
    }
    let candidate = entities
        .iter()
        .min_by(|(_, left), (_, right)| {
            left.confidence
                .partial_cmp(&right.confidence)
                .unwrap_or(std::cmp::Ordering::Equal)
        })
        .map(|(key, _)| key.clone());
    if let Some(key) = candidate {
        entities.remove(&key);
    }
}
