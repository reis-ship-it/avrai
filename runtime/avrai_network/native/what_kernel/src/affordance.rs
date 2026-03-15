use serde_json::{json, Map, Value};

pub fn affordance_vector_for(canonical_type: &str, activities: &[String]) -> Map<String, Value> {
    let mut affordances = base_affordances(canonical_type);
    for activity in activities {
        match activity.as_str() {
            "deep_work" => {
                affordances.insert("focus".to_string(), json!(0.92));
                affordances.insert("quiet_presence".to_string(), json!(0.78));
            }
            "casual_socializing" => {
                affordances.insert("conversation".to_string(), json!(0.86));
                affordances.insert("group_bonding".to_string(), json!(0.58));
            }
            "date" => {
                affordances.insert("romance".to_string(), json!(0.91));
                affordances.insert("conversation".to_string(), json!(0.72));
            }
            "learning" => {
                affordances.insert("learning".to_string(), json!(0.88));
            }
            "recovery" => {
                affordances.insert("recovery".to_string(), json!(0.84));
            }
            _ => {}
        }
    }
    affordances
}

pub fn vibe_signature_for(canonical_type: &str, activities: &[String]) -> Map<String, Value> {
    let mut vibe = Map::new();
    let base = match canonical_type {
        "cafe" => (0.68, 0.46, 0.40, 0.62, 0.18, 0.74, 0.35, 0.61, 0.48, 0.39),
        "bar" => (0.24, 0.84, 0.55, 0.33, 0.52, 0.66, 0.51, 0.28, 0.43, 0.72),
        "gallery" => (0.57, 0.31, 0.52, 0.81, 0.12, 0.41, 0.59, 0.64, 0.75, 0.36),
        "park" => (0.82, 0.29, 0.27, 0.41, 0.07, 0.52, 0.44, 0.83, 0.38, 0.47),
        "workspace" => (0.61, 0.22, 0.14, 0.79, 0.09, 0.38, 0.57, 0.72, 0.58, 0.21),
        "music_venue" => (0.17, 0.89, 0.46, 0.36, 0.63, 0.58, 0.48, 0.19, 0.64, 0.74),
        "third_place" => (0.56, 0.52, 0.61, 0.45, 0.18, 0.78, 0.32, 0.59, 0.51, 0.65),
        _ => (0.50, 0.50, 0.35, 0.50, 0.20, 0.50, 0.50, 0.50, 0.50, 0.50),
    };
    let fields = [
        ("calm", base.0),
        ("lively", base.1),
        ("intimate", base.2),
        ("cerebral", base.3),
        ("chaotic", base.4),
        ("warm", base.5),
        ("cool", base.6),
        ("grounded", base.7),
        ("aspirational", base.8),
        ("playful", base.9),
    ];
    for (name, value) in fields {
        vibe.insert(name.to_string(), json!(value));
    }
    if activities.iter().any(|item| item == "date") {
        vibe.insert("intimate".to_string(), json!(0.84));
        vibe.insert("warm".to_string(), json!(0.82));
    }
    if activities.iter().any(|item| item == "deep_work") {
        vibe.insert("cerebral".to_string(), json!(0.88));
        vibe.insert("calm".to_string(), json!(0.76));
    }
    vibe
}

fn base_affordances(canonical_type: &str) -> Map<String, Value> {
    let defaults = match canonical_type {
        "cafe" => vec![
            ("focus", 0.71),
            ("conversation", 0.74),
            ("low_friction_stop", 0.79),
            ("ritual_repeatability", 0.76),
        ],
        "bar" => vec![
            ("conversation", 0.81),
            ("group_bonding", 0.68),
            ("high_energy_release", 0.65),
        ],
        "gallery" => vec![
            ("learning", 0.69),
            ("novelty", 0.77),
            ("quiet_presence", 0.63),
        ],
        "park" => vec![
            ("recovery", 0.83),
            ("novelty", 0.44),
            ("quiet_presence", 0.72),
        ],
        "workspace" => vec![
            ("focus", 0.93),
            ("learning", 0.58),
            ("ritual_repeatability", 0.70),
        ],
        "third_place" => vec![
            ("conversation", 0.78),
            ("serendipity", 0.72),
            ("ritual_repeatability", 0.69),
        ],
        _ => vec![("novelty", 0.40)],
    };
    let mut affordances = Map::new();
    for (name, value) in defaults {
        affordances.insert(name.to_string(), json!(value));
    }
    affordances
}
