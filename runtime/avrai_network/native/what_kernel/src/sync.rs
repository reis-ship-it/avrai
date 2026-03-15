use crate::models::WhatState;

pub fn merge_state(local: Option<WhatState>, incoming: WhatState) -> (WhatState, bool) {
    match local {
        None => (incoming, true),
        Some(mut current) => {
            let incoming_should_win = incoming.confidence > current.confidence
                || incoming.last_observed_at_utc > current.last_observed_at_utc;
            if incoming_should_win {
                current.canonical_type = incoming.canonical_type;
                current.place_type = incoming.place_type;
            }
            merge_unique(&mut current.subtypes, &incoming.subtypes);
            merge_unique(&mut current.aliases, &incoming.aliases);
            merge_unique(&mut current.activity_types, &incoming.activity_types);
            merge_unique(&mut current.social_contexts, &incoming.social_contexts);
            merge_unique(&mut current.lineage_refs, &incoming.lineage_refs);
            current.confidence = current.confidence.max(incoming.confidence);
            current.trust = current.trust.max(incoming.trust);
            current.familiarity = current.familiarity.max(incoming.familiarity);
            current.novelty = current.novelty.min(incoming.novelty);
            current.saturation = current.saturation.max(incoming.saturation);
            current.evidence_count = current.evidence_count.max(incoming.evidence_count);
            if incoming.last_observed_at_utc > current.last_observed_at_utc {
                current.last_observed_at_utc = incoming.last_observed_at_utc;
            }
            (current, incoming_should_win)
        }
    }
}

fn merge_unique(target: &mut Vec<String>, extra: &[String]) {
    for value in extra {
        if !target.iter().any(|entry| entry == value) {
            target.push(value.clone());
        }
    }
}
