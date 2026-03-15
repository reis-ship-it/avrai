use serde_json::{Map, Value};

#[derive(Clone, Debug)]
pub struct Classification {
    pub canonical_type: String,
    pub place_type: String,
    pub subtypes: Vec<String>,
    pub aliases: Vec<String>,
    pub activity_types: Vec<String>,
    pub social_contexts: Vec<String>,
    pub lineage_refs: Vec<String>,
}

pub fn classify(payload: &Map<String, Value>) -> Classification {
    let entity_ref = payload
        .get("entityRef")
        .and_then(Value::as_str)
        .unwrap_or("unknown_entity");
    let mut labels = payload
        .get("candidateLabels")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default()
        .into_iter()
        .filter_map(|entry| entry.as_str().map(|value| value.to_lowercase()))
        .collect::<Vec<_>>();

    if let Some(activity_hint) = payload.get("activityHint").and_then(Value::as_str) {
        labels.push(activity_hint.to_lowercase());
    }
    if let Some(social_hint) = payload.get("socialContextHint").and_then(Value::as_str) {
        labels.push(social_hint.to_lowercase());
    }
    if let Some(tuple_entries) = payload.get("semanticTuples").and_then(Value::as_array) {
        for tuple in tuple_entries {
            if let Some(object) = tuple.get("object").and_then(Value::as_str) {
                labels.push(object.to_lowercase());
            }
            if let Some(predicate) = tuple.get("predicate").and_then(Value::as_str) {
                labels.push(predicate.to_lowercase());
            }
        }
    }

    let mut canonical_type = "destination_venue".to_string();
    let mut place_type = "destination_venue".to_string();
    let mut subtypes = Vec::new();
    let mut aliases = vec![entity_ref.to_string()];
    let mut activity_types = Vec::new();
    let mut social_contexts = Vec::new();

    for label in &labels {
        match label.as_str() {
            "coffee shop" | "cafe" | "location_category_cafe" => {
                canonical_type = "cafe".to_string();
                place_type = "cafe".to_string();
                push_once(&mut aliases, "coffee shop");
                push_once(&mut activity_types, "deep_work");
                push_once(&mut activity_types, "casual_socializing");
            }
            "study spot" | "workspace" | "coworking" => {
                canonical_type = "workspace".to_string();
                place_type = "workspace".to_string();
                push_once(&mut activity_types, "deep_work");
                push_once(&mut subtypes, "study_spot");
            }
            "date spot" => {
                canonical_type = "third_place".to_string();
                place_type = "third_place".to_string();
                push_once(&mut activity_types, "date");
            }
            "hangout" => push_once(&mut activity_types, "casual_socializing"),
            "bar" => {
                canonical_type = "bar".to_string();
                place_type = "bar".to_string();
                push_once(&mut activity_types, "casual_socializing");
            }
            "gallery" => {
                canonical_type = "gallery".to_string();
                place_type = "gallery".to_string();
                push_once(&mut activity_types, "learning");
                push_once(&mut activity_types, "exploration");
            }
            "park" => {
                canonical_type = "park".to_string();
                place_type = "park".to_string();
                push_once(&mut activity_types, "recovery");
                push_once(&mut activity_types, "movement");
            }
            "music venue" | "music_venue" => {
                canonical_type = "music_venue".to_string();
                place_type = "music_venue".to_string();
                push_once(&mut activity_types, "celebration");
            }
            "restaurant" => {
                canonical_type = "restaurant".to_string();
                place_type = "restaurant".to_string();
                push_once(&mut activity_types, "casual_socializing");
            }
            "solo" => push_once(&mut social_contexts, "solo"),
            "dyad" => push_once(&mut social_contexts, "dyad"),
            "small_group" => push_once(&mut social_contexts, "small_group"),
            "crowd" => push_once(&mut social_contexts, "crowd"),
            "meeting" => push_once(&mut activity_types, "meeting"),
            "learning" => push_once(&mut activity_types, "learning"),
            "exploration" => push_once(&mut activity_types, "exploration"),
            "lingering" | "dwelled_at" => push_once(&mut activity_types, "lingering"),
            _ => {}
        }
    }

    if activity_types.is_empty() {
        push_once(&mut activity_types, "exploration");
    }
    if social_contexts.is_empty() {
        push_once(&mut social_contexts, "ambient_social");
    }
    let lineage_refs = payload
        .get("lineageRef")
        .and_then(Value::as_str)
        .map(|value| vec![value.to_string()])
        .unwrap_or_default();

    Classification {
        canonical_type,
        place_type,
        subtypes,
        aliases,
        activity_types,
        social_contexts,
        lineage_refs,
    }
}

fn push_once(target: &mut Vec<String>, value: &str) {
    if !target.iter().any(|entry| entry == value) {
        target.push(value.to_string());
    }
}
