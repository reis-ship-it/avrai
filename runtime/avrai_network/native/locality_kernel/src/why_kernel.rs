use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::collections::HashSet;

const WHY_SCHEMA_VERSION: u32 = 2;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WhyQueryKind {
    ObservedOutcome,
    Recommendation,
    Rejection,
    PolicyAction,
    BehaviorPattern,
    ModelUpdate,
}

impl Default for WhyQueryKind {
    fn default() -> Self {
        Self::ObservedOutcome
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WhyRequestedPerspective {
    System,
    Agent,
    UserSafe,
    Admin,
    Governance,
}

impl Default for WhyRequestedPerspective {
    fn default() -> Self {
        Self::System
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WhyRootCauseType {
    TraitDriven,
    ContextDriven,
    SocialDriven,
    Temporal,
    Locality,
    Mechanistic,
    PolicyDriven,
    Pheromone,
    Mixed,
    Unknown,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WhyEvidencePolarity {
    Positive,
    Negative,
    Neutral,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub enum WhyEvidenceSourceKernel {
    Who,
    What,
    Where,
    When,
    How,
    Social,
    Policy,
    Memory,
    Model,
    External,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WhyValidationSeverity {
    Warning,
    Error,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyRef {
    pub id: String,
    #[serde(default)]
    pub label: String,
    #[serde(default)]
    pub kind: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhySignal {
    pub label: String,
    pub weight: f64,
    #[serde(default)]
    pub source: String,
    #[serde(default)]
    pub durable: bool,
    #[serde(default)]
    pub confidence: f64,
    #[serde(default)]
    pub evidence_id: String,
    #[serde(default)]
    pub kernel: Option<WhyEvidenceSourceKernel>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyEvidence {
    pub id: String,
    pub label: String,
    pub weight: f64,
    pub polarity: WhyEvidencePolarity,
    pub source_kernel: WhyEvidenceSourceKernel,
    #[serde(default)]
    pub source_subsystem: String,
    #[serde(default)]
    pub durability: String,
    #[serde(default)]
    pub confidence: f64,
    #[serde(default)]
    pub observed: bool,
    #[serde(default)]
    pub inferred: bool,
    #[serde(default)]
    pub provenance: String,
    #[serde(default)]
    pub time_ref: String,
    #[serde(default)]
    pub subject_ref: String,
    #[serde(default)]
    pub scope: String,
    #[serde(default)]
    pub tags: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhyEvidenceBundle {
    #[serde(default)]
    pub entries: Vec<WhyEvidence>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyCounterfactual {
    pub condition: String,
    pub expected_effect: String,
    pub confidence_delta: f64,
    #[serde(default = "default_true")]
    pub speculative: bool,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyHypothesis {
    pub id: String,
    pub label: String,
    pub root_cause_type: WhyRootCauseType,
    pub confidence: f64,
    #[serde(default)]
    pub supporting_evidence_ids: Vec<String>,
    #[serde(default)]
    pub opposing_evidence_ids: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyTraceRef {
    pub trace_type: String,
    pub kernel: WhyEvidenceSourceKernel,
    #[serde(default)]
    pub entity_id: String,
    #[serde(default)]
    pub event_id: String,
    #[serde(default)]
    pub time_ref: String,
    #[serde(default)]
    pub explanation_ref: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyConflict {
    pub label: String,
    pub message: String,
    #[serde(default)]
    pub evidence_ids: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhyGovernanceEnvelope {
    #[serde(default)]
    pub redacted: bool,
    #[serde(default)]
    pub redaction_reason: String,
    #[serde(default)]
    pub policy_refs: Vec<String>,
    #[serde(default)]
    pub escalation_thresholds: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyAttributionSummary {
    pub driver_labels: Vec<String>,
    pub inhibitor_labels: Vec<String>,
    pub top_kernel: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhyValidationIssue {
    pub severity: WhyValidationSeverity,
    pub code: String,
    pub message: String,
    #[serde(default)]
    pub field: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WhySnapshot {
    pub goal: String,
    pub query_kind: WhyQueryKind,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub primary_hypothesis: Option<WhyHypothesis>,
    pub alternate_hypotheses: Vec<WhyHypothesis>,
    pub drivers: Vec<WhySignal>,
    pub inhibitors: Vec<WhySignal>,
    pub counterfactuals: Vec<WhyCounterfactual>,
    pub confidence: f64,
    pub ambiguity: f64,
    pub root_cause_type: WhyRootCauseType,
    pub summary: String,
    pub trace_refs: Vec<WhyTraceRef>,
    pub conflicts: Vec<WhyConflict>,
    pub governance_envelope: WhyGovernanceEnvelope,
    #[serde(default)]
    pub generated_at: String,
    pub schema_version: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attribution_summary: Option<WhyAttributionSummary>,
    pub validation_issues: Vec<WhyValidationIssue>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct WhyKernelInput {
    #[serde(default)]
    pub goal: String,
    #[serde(default)]
    pub subject_ref: Option<WhyRef>,
    #[serde(default)]
    pub action_ref: Option<WhyRef>,
    #[serde(default)]
    pub outcome_ref: Option<WhyRef>,
    #[serde(default)]
    pub query_kind: WhyQueryKind,
    #[serde(default)]
    pub evidence_bundle: WhyEvidenceBundle,
    #[serde(default)]
    pub linked_who_refs: Vec<WhyRef>,
    #[serde(default)]
    pub linked_what_refs: Vec<WhyRef>,
    #[serde(default)]
    pub linked_where_refs: Vec<WhyRef>,
    #[serde(default)]
    pub linked_when_refs: Vec<WhyRef>,
    #[serde(default)]
    pub linked_how_refs: Vec<WhyRef>,
    #[serde(default)]
    pub policy_context: Map<String, Value>,
    #[serde(default)]
    pub requested_perspective: WhyRequestedPerspective,
    #[serde(default = "default_max_counterfactuals")]
    pub max_counterfactuals: usize,
    #[serde(default = "default_explanation_depth")]
    pub explanation_depth: usize,
    // Legacy fields.
    #[serde(default)]
    pub action: String,
    #[serde(default)]
    pub outcome: String,
    #[serde(default)]
    pub entity_id: String,
    #[serde(default)]
    pub core_signals: Vec<WhySignal>,
    #[serde(default)]
    pub pheromone_signals: Vec<WhySignal>,
    #[serde(default)]
    pub temporal_signals: Vec<WhySignal>,
    #[serde(default)]
    pub locality_signals: Vec<WhySignal>,
    #[serde(default)]
    pub social_signals: Vec<WhySignal>,
}

pub fn explain_why(payload: &Map<String, Value>) -> Value {
    let input = serde_json::from_value::<WhyKernelInput>(Value::Object(payload.clone()))
        .unwrap_or_else(|_| WhyKernelInput::default());
    let snapshot = build_snapshot(input);
    serde_json::to_value(snapshot).unwrap_or(Value::Null)
}

fn build_snapshot(input: WhyKernelInput) -> WhySnapshot {
    let evidence = normalized_evidence(&input);
    let validation_issues = validate_input(&input, &evidence);
    let drivers = rank_signals(&evidence, WhyEvidencePolarity::Positive);
    let inhibitors = rank_signals(&evidence, WhyEvidencePolarity::Negative);
    let root_cause_type = classify_root_cause(&evidence, &drivers, &inhibitors);
    let confidence = estimate_confidence(&evidence, &drivers, &inhibitors);
    let ambiguity = estimate_ambiguity(&drivers, &inhibitors);
    let counterfactuals = build_counterfactuals(&drivers, &inhibitors, input.max_counterfactuals);
    let conflicts = build_conflicts(&drivers, &inhibitors);
    let trace_refs = build_trace_refs(&input, &evidence);
    let governance_envelope = build_governance_envelope(&input, &evidence);
    let goal = resolved_goal(&input);
    let primary_hypothesis =
        build_primary_hypothesis(&root_cause_type, confidence, &drivers, &inhibitors);
    let alternate_hypotheses =
        build_alternate_hypotheses(&root_cause_type, confidence, &drivers, &inhibitors);
    let attribution_summary = Some(WhyAttributionSummary {
        driver_labels: drivers.iter().map(|entry| entry.label.clone()).collect(),
        inhibitor_labels: inhibitors.iter().map(|entry| entry.label.clone()).collect(),
        top_kernel: top_kernel_label(&drivers, &inhibitors),
    });

    let snapshot = WhySnapshot {
        goal,
        query_kind: input.query_kind.clone(),
        primary_hypothesis,
        alternate_hypotheses,
        drivers,
        inhibitors,
        counterfactuals,
        confidence,
        ambiguity,
        root_cause_type: root_cause_type.clone(),
        summary: build_summary(
            &input,
            &root_cause_type,
            confidence,
            &attribution_summary,
            &conflicts,
        ),
        trace_refs,
        conflicts,
        governance_envelope,
        generated_at: String::new(),
        schema_version: WHY_SCHEMA_VERSION,
        attribution_summary,
        validation_issues,
    };

    apply_perspective_redaction(snapshot, &input.requested_perspective)
}

fn validate_input(input: &WhyKernelInput, evidence: &[WhyEvidence]) -> Vec<WhyValidationIssue> {
    let mut issues = Vec::new();
    if evidence.is_empty() {
        issues.push(WhyValidationIssue {
            severity: WhyValidationSeverity::Error,
            code: "empty_evidence".to_string(),
            message: "No evidence was provided to explain why.".to_string(),
            field: "evidence_bundle".to_string(),
        });
    }
    if input.max_counterfactuals > 8 {
        issues.push(WhyValidationIssue {
            severity: WhyValidationSeverity::Warning,
            code: "counterfactual_cap_reduced".to_string(),
            message: "max_counterfactuals exceeds engine bound; it will be capped.".to_string(),
            field: "max_counterfactuals".to_string(),
        });
    }
    for entry in evidence {
        if !entry.weight.is_finite() {
            issues.push(WhyValidationIssue {
                severity: WhyValidationSeverity::Error,
                code: "invalid_weight".to_string(),
                message: "Evidence weight must be finite.".to_string(),
                field: format!("evidence.{}.weight", entry.id),
            });
        }
        if !(0.0..=1.0).contains(&entry.confidence) && entry.confidence != 0.0 {
            issues.push(WhyValidationIssue {
                severity: WhyValidationSeverity::Warning,
                code: "confidence_out_of_range".to_string(),
                message: "Evidence confidence should be between 0 and 1.".to_string(),
                field: format!("evidence.{}.confidence", entry.id),
            });
        }
    }
    issues
}

fn normalized_evidence(input: &WhyKernelInput) -> Vec<WhyEvidence> {
    let mut evidence = input.evidence_bundle.entries.clone();
    evidence.extend(legacy_signals_to_evidence(
        &input.core_signals,
        WhyEvidenceSourceKernel::Who,
        "core",
        "durable",
    ));
    evidence.extend(legacy_signals_to_evidence(
        &input.pheromone_signals,
        WhyEvidenceSourceKernel::Social,
        "pheromone",
        "transient",
    ));
    evidence.extend(legacy_signals_to_evidence(
        &input.temporal_signals,
        WhyEvidenceSourceKernel::When,
        "temporal",
        "transient",
    ));
    evidence.extend(legacy_signals_to_evidence(
        &input.locality_signals,
        WhyEvidenceSourceKernel::Where,
        "locality",
        "transient",
    ));
    evidence.extend(legacy_signals_to_evidence(
        &input.social_signals,
        WhyEvidenceSourceKernel::Social,
        "social",
        "transient",
    ));
    evidence
}

fn legacy_signals_to_evidence(
    signals: &[WhySignal],
    source_kernel: WhyEvidenceSourceKernel,
    source_subsystem: &str,
    durability: &str,
) -> Vec<WhyEvidence> {
    signals
        .iter()
        .map(|signal| WhyEvidence {
            id: if signal.evidence_id.trim().is_empty() {
                format!("{}_{}", source_subsystem, signal.label)
            } else {
                signal.evidence_id.clone()
            },
            label: signal.label.clone(),
            weight: signal.weight.abs(),
            polarity: if signal.weight < 0.0 {
                WhyEvidencePolarity::Negative
            } else {
                WhyEvidencePolarity::Positive
            },
            source_kernel: signal.kernel.clone().unwrap_or(source_kernel.clone()),
            source_subsystem: if signal.source.trim().is_empty() {
                source_subsystem.to_string()
            } else {
                signal.source.clone()
            },
            durability: if signal.durable {
                "durable".to_string()
            } else {
                durability.to_string()
            },
            confidence: signal.confidence,
            observed: true,
            inferred: false,
            provenance: String::new(),
            time_ref: String::new(),
            subject_ref: String::new(),
            scope: source_subsystem.to_string(),
            tags: vec![source_subsystem.to_string()],
        })
        .collect()
}

fn rank_signals(evidence: &[WhyEvidence], polarity: WhyEvidencePolarity) -> Vec<WhySignal> {
    let mut signals = evidence
        .iter()
        .filter(|entry| entry.polarity == polarity)
        .map(|entry| WhySignal {
            label: entry.label.clone(),
            weight: entry.weight,
            source: if entry.source_subsystem.trim().is_empty() {
                source_kernel_label(&entry.source_kernel)
            } else {
                entry.source_subsystem.clone()
            },
            durable: entry.durability == "durable",
            confidence: entry.confidence,
            evidence_id: entry.id.clone(),
            kernel: Some(entry.source_kernel.clone()),
        })
        .collect::<Vec<_>>();
    signals.sort_by(|left, right| right.weight.total_cmp(&left.weight));
    signals.truncate(3);
    signals
}

fn classify_root_cause(
    evidence: &[WhyEvidence],
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> WhyRootCauseType {
    let active_kernel_count = evidence
        .iter()
        .map(|entry| entry.source_kernel.clone())
        .collect::<HashSet<_>>()
        .len();
    if active_kernel_count > 1 {
        return WhyRootCauseType::Mixed;
    }

    match top_kernel(drivers, inhibitors) {
        Some(WhyEvidenceSourceKernel::Who) => WhyRootCauseType::TraitDriven,
        Some(WhyEvidenceSourceKernel::Where) => WhyRootCauseType::Locality,
        Some(WhyEvidenceSourceKernel::When) => WhyRootCauseType::Temporal,
        Some(WhyEvidenceSourceKernel::How) => WhyRootCauseType::Mechanistic,
        Some(WhyEvidenceSourceKernel::Policy) => WhyRootCauseType::PolicyDriven,
        Some(WhyEvidenceSourceKernel::Social) => WhyRootCauseType::SocialDriven,
        Some(WhyEvidenceSourceKernel::What)
        | Some(WhyEvidenceSourceKernel::Memory)
        | Some(WhyEvidenceSourceKernel::Model)
        | Some(WhyEvidenceSourceKernel::External) => WhyRootCauseType::ContextDriven,
        None => WhyRootCauseType::Unknown,
    }
}

fn top_kernel(drivers: &[WhySignal], inhibitors: &[WhySignal]) -> Option<WhyEvidenceSourceKernel> {
    let mut strongest: Option<&WhySignal> = None;
    for signal in drivers.iter().chain(inhibitors.iter()) {
        if strongest
            .map(|current| signal.weight > current.weight)
            .unwrap_or(true)
        {
            strongest = Some(signal);
        }
    }
    strongest.and_then(|signal| signal.kernel.clone())
}

fn top_kernel_label(drivers: &[WhySignal], inhibitors: &[WhySignal]) -> String {
    top_kernel(drivers, inhibitors)
        .map(|kernel| source_kernel_label(&kernel))
        .unwrap_or_else(|| "unknown".to_string())
}

fn estimate_confidence(
    evidence: &[WhyEvidence],
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> f64 {
    if evidence.is_empty() {
        return 0.0;
    }
    let top_driver = drivers.first().map(|entry| entry.weight).unwrap_or(0.0);
    let top_inhibitor = inhibitors.first().map(|entry| entry.weight).unwrap_or(0.0);
    let dominant = top_driver.max(top_inhibitor).clamp(0.0, 1.0);
    let coverage = (evidence.len() as f64 / 8.0).clamp(0.0, 1.0);
    let explicit_confidence = evidence
        .iter()
        .map(|entry| {
            if entry.confidence == 0.0 {
                0.5
            } else {
                entry.confidence
            }
        })
        .sum::<f64>()
        / evidence.len() as f64;
    ((dominant * 0.55) + (coverage * 0.2) + (explicit_confidence * 0.25)).clamp(0.0, 1.0)
}

fn estimate_ambiguity(drivers: &[WhySignal], inhibitors: &[WhySignal]) -> f64 {
    if drivers.is_empty() || inhibitors.is_empty() {
        return if drivers.is_empty() && inhibitors.is_empty() {
            1.0
        } else {
            0.15
        };
    }
    (1.0 - (drivers[0].weight - inhibitors[0].weight)
        .abs()
        .clamp(0.0, 1.0))
    .clamp(0.0, 1.0)
}

fn build_counterfactuals(
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
    requested_max: usize,
) -> Vec<WhyCounterfactual> {
    let max_counterfactuals = requested_max.clamp(0, 8);
    let mut counterfactuals = Vec::new();
    if max_counterfactuals == 0 {
        return counterfactuals;
    }
    if let Some(signal) = inhibitors.first() {
        counterfactuals.push(WhyCounterfactual {
            condition: format!("Reduce {}", signal.label),
            expected_effect: "Outcome is more likely to improve".to_string(),
            confidence_delta: (signal.weight * 0.35).clamp(0.0, 0.35),
            speculative: true,
        });
    }
    if counterfactuals.len() < max_counterfactuals {
        if let Some(signal) = drivers.first() {
            counterfactuals.push(WhyCounterfactual {
                condition: format!("Increase {}", signal.label),
                expected_effect: "Outcome is more likely to repeat".to_string(),
                confidence_delta: (signal.weight * 0.25).clamp(0.0, 0.25),
                speculative: true,
            });
        }
    }
    counterfactuals.truncate(max_counterfactuals);
    counterfactuals
}

fn build_conflicts(drivers: &[WhySignal], inhibitors: &[WhySignal]) -> Vec<WhyConflict> {
    match (drivers.first(), inhibitors.first()) {
        (Some(driver), Some(inhibitor)) => vec![WhyConflict {
            label: "dominant_tension".to_string(),
            message: format!("{} is being opposed by {}.", driver.label, inhibitor.label),
            evidence_ids: vec![driver.evidence_id.clone(), inhibitor.evidence_id.clone()]
                .into_iter()
                .filter(|entry| !entry.trim().is_empty())
                .collect(),
        }],
        _ => Vec::new(),
    }
}

fn build_trace_refs(input: &WhyKernelInput, evidence: &[WhyEvidence]) -> Vec<WhyTraceRef> {
    let entity_id = if !input.entity_id.trim().is_empty() {
        input.entity_id.clone()
    } else {
        input
            .subject_ref
            .as_ref()
            .map(|entry| entry.id.clone())
            .unwrap_or_default()
    };

    evidence
        .iter()
        .take(4)
        .map(|entry| WhyTraceRef {
            trace_type: "evidence".to_string(),
            kernel: entry.source_kernel.clone(),
            entity_id: if !entry.subject_ref.trim().is_empty() {
                entry.subject_ref.clone()
            } else {
                entity_id.clone()
            },
            event_id: entry.id.clone(),
            time_ref: entry.time_ref.clone(),
            explanation_ref: input.goal.clone(),
        })
        .collect()
}

fn build_governance_envelope(
    input: &WhyKernelInput,
    evidence: &[WhyEvidence],
) -> WhyGovernanceEnvelope {
    let mut policy_refs = extract_string_list(&input.policy_context, "policyRefs");
    policy_refs.extend(
        evidence
            .iter()
            .filter(|entry| entry.source_kernel == WhyEvidenceSourceKernel::Policy)
            .map(|entry| entry.id.clone()),
    );

    WhyGovernanceEnvelope {
        redacted: false,
        redaction_reason: String::new(),
        policy_refs,
        escalation_thresholds: extract_string_list(&input.policy_context, "escalationThresholds"),
    }
}

fn build_primary_hypothesis(
    root_cause_type: &WhyRootCauseType,
    confidence: f64,
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> Option<WhyHypothesis> {
    if drivers.is_empty() && inhibitors.is_empty() {
        return None;
    }
    Some(WhyHypothesis {
        id: "primary".to_string(),
        label: top_hypothesis_label(root_cause_type, drivers, inhibitors),
        root_cause_type: root_cause_type.clone(),
        confidence,
        supporting_evidence_ids: drivers
            .iter()
            .filter_map(|entry| non_empty_string(&entry.evidence_id))
            .take(3)
            .collect(),
        opposing_evidence_ids: inhibitors
            .iter()
            .filter_map(|entry| non_empty_string(&entry.evidence_id))
            .take(3)
            .collect(),
    })
}

fn build_alternate_hypotheses(
    root_cause_type: &WhyRootCauseType,
    confidence: f64,
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> Vec<WhyHypothesis> {
    let alternate_label = if drivers.len() > 1 {
        Some(format!("Alternate driver {}", drivers[1].label))
    } else if inhibitors.len() > 1 {
        Some(format!("Alternate inhibitor {}", inhibitors[1].label))
    } else {
        None
    };

    alternate_label
        .map(|label| {
            vec![WhyHypothesis {
                id: "alternate_1".to_string(),
                label,
                root_cause_type: root_cause_type.clone(),
                confidence: (confidence * 0.82).clamp(0.0, 1.0),
                supporting_evidence_ids: drivers
                    .iter()
                    .skip(1)
                    .filter_map(|entry| non_empty_string(&entry.evidence_id))
                    .take(2)
                    .collect(),
                opposing_evidence_ids: inhibitors
                    .iter()
                    .skip(1)
                    .filter_map(|entry| non_empty_string(&entry.evidence_id))
                    .take(2)
                    .collect(),
            }]
        })
        .unwrap_or_default()
}

fn build_summary(
    input: &WhyKernelInput,
    root_cause_type: &WhyRootCauseType,
    confidence: f64,
    attribution_summary: &Option<WhyAttributionSummary>,
    conflicts: &[WhyConflict],
) -> String {
    let action = input
        .action_ref
        .as_ref()
        .and_then(|entry| non_empty_string(&entry.label))
        .or_else(|| non_empty_string(&input.action))
        .unwrap_or_else(|| "decision".to_string());
    let outcome = input
        .outcome_ref
        .as_ref()
        .and_then(|entry| non_empty_string(&entry.label))
        .or_else(|| non_empty_string(&input.outcome))
        .unwrap_or_else(|| "observed outcome".to_string());
    let top_driver = attribution_summary
        .as_ref()
        .and_then(|entry| entry.driver_labels.first())
        .cloned()
        .unwrap_or_else(|| "limited positive evidence".to_string());
    let top_inhibitor = attribution_summary
        .as_ref()
        .and_then(|entry| entry.inhibitor_labels.first())
        .cloned()
        .unwrap_or_else(|| "limited opposing evidence".to_string());
    let conflict_summary = conflicts
        .first()
        .map(|entry| format!(" {}", entry.message))
        .unwrap_or_default();

    format!(
        "{action} produced {outcome} primarily due to {} signals, led by {top_driver}, with {top_inhibitor} as the main inhibitor. Confidence {:.2}.{conflict_summary}",
        source_root_cause_label(root_cause_type),
        confidence
    )
}

fn apply_perspective_redaction(
    mut snapshot: WhySnapshot,
    perspective: &WhyRequestedPerspective,
) -> WhySnapshot {
    match perspective {
        WhyRequestedPerspective::System
        | WhyRequestedPerspective::Admin
        | WhyRequestedPerspective::Governance => snapshot,
        WhyRequestedPerspective::Agent => {
            snapshot.trace_refs.clear();
            snapshot.conflicts.clear();
            snapshot.governance_envelope.redacted = true;
            snapshot.governance_envelope.redaction_reason = "agent_redaction".to_string();
            snapshot.governance_envelope.policy_refs.clear();
            snapshot
        }
        WhyRequestedPerspective::UserSafe => {
            snapshot.trace_refs.clear();
            snapshot.conflicts.clear();
            snapshot.governance_envelope.redacted = true;
            snapshot.governance_envelope.redaction_reason = "user_safe_redaction".to_string();
            snapshot.governance_envelope.policy_refs.clear();
            snapshot.governance_envelope.escalation_thresholds.clear();
            snapshot
        }
    }
}

fn resolved_goal(input: &WhyKernelInput) -> String {
    non_empty_string(&input.goal)
        .or_else(|| {
            input
                .action_ref
                .as_ref()
                .and_then(|entry| non_empty_string(&entry.label))
        })
        .or_else(|| non_empty_string(&input.action))
        .map(|label| format!("optimize_{label}"))
        .unwrap_or_else(|| "explain_outcome".to_string())
}

fn extract_string_list(payload: &Map<String, Value>, key: &str) -> Vec<String> {
    payload
        .get(key)
        .and_then(Value::as_array)
        .map(|entries| {
            entries
                .iter()
                .filter_map(Value::as_str)
                .map(ToString::to_string)
                .collect()
        })
        .unwrap_or_default()
}

fn source_kernel_label(kernel: &WhyEvidenceSourceKernel) -> String {
    match kernel {
        WhyEvidenceSourceKernel::Who => "who",
        WhyEvidenceSourceKernel::What => "what",
        WhyEvidenceSourceKernel::Where => "where",
        WhyEvidenceSourceKernel::When => "when",
        WhyEvidenceSourceKernel::How => "how",
        WhyEvidenceSourceKernel::Social => "social",
        WhyEvidenceSourceKernel::Policy => "policy",
        WhyEvidenceSourceKernel::Memory => "memory",
        WhyEvidenceSourceKernel::Model => "model",
        WhyEvidenceSourceKernel::External => "external",
    }
    .to_string()
}

fn source_root_cause_label(root_cause_type: &WhyRootCauseType) -> &'static str {
    match root_cause_type {
        WhyRootCauseType::TraitDriven => "trait_driven",
        WhyRootCauseType::ContextDriven => "context_driven",
        WhyRootCauseType::SocialDriven => "social_driven",
        WhyRootCauseType::Temporal => "temporal",
        WhyRootCauseType::Locality => "locality",
        WhyRootCauseType::Mechanistic => "mechanistic",
        WhyRootCauseType::PolicyDriven => "policy_driven",
        WhyRootCauseType::Pheromone => "pheromone",
        WhyRootCauseType::Mixed => "mixed",
        WhyRootCauseType::Unknown => "unknown",
    }
}

fn top_hypothesis_label(
    root_cause_type: &WhyRootCauseType,
    drivers: &[WhySignal],
    inhibitors: &[WhySignal],
) -> String {
    let lead_driver = drivers
        .first()
        .map(|entry| entry.label.as_str())
        .unwrap_or("weak support");
    let lead_inhibitor = inhibitors
        .first()
        .map(|entry| entry.label.as_str())
        .unwrap_or("weak opposition");
    format!(
        "{} attribution driven by {} and opposed by {}",
        source_root_cause_label(root_cause_type),
        lead_driver,
        lead_inhibitor
    )
}

fn non_empty_string(value: &str) -> Option<String> {
    if value.trim().is_empty() {
        None
    } else {
        Some(value.to_string())
    }
}

fn default_max_counterfactuals() -> usize {
    2
}

fn default_explanation_depth() -> usize {
    2
}

fn default_true() -> bool {
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn explains_legacy_mixed_attribution() {
        let payload = json!({
            "action": "recommend_park",
            "outcome": "rejected",
            "core_signals": [
                {"label": "outdoor_affinity", "weight": 0.35}
            ],
            "pheromone_signals": [
                {"label": "social_fatigue", "weight": -0.91}
            ],
            "temporal_signals": [
                {"label": "late_day_energy_drop", "weight": -0.44}
            ]
        });

        let snapshot: WhySnapshot = serde_json::from_value(explain_why(
            payload.as_object().expect("payload should be object"),
        ))
        .expect("snapshot should decode");

        assert!(matches!(snapshot.root_cause_type, WhyRootCauseType::Mixed));
        assert_eq!(snapshot.inhibitors[0].source, "pheromone");
        assert_eq!(snapshot.schema_version, WHY_SCHEMA_VERSION);
        assert!(snapshot.primary_hypothesis.is_some());
    }

    #[test]
    fn explains_canonical_policy_attribution() {
        let payload = json!({
            "goal": "enforce_policy",
            "query_kind": "policy_action",
            "requested_perspective": "governance",
            "policy_context": {
                "policyRefs": ["policy-7"],
                "escalationThresholds": ["severity>0.9"]
            },
            "evidence_bundle": {
                "entries": [
                    {
                        "id": "policy_block",
                        "label": "policy threshold exceeded",
                        "weight": 0.93,
                        "polarity": "positive",
                        "source_kernel": "policy",
                        "source_subsystem": "safety_gate",
                        "durability": "durable",
                        "confidence": 0.91,
                        "observed": true
                    }
                ]
            }
        });

        let snapshot: WhySnapshot = serde_json::from_value(explain_why(
            payload.as_object().expect("payload should be object"),
        ))
        .expect("snapshot should decode");

        assert!(matches!(
            snapshot.root_cause_type,
            WhyRootCauseType::PolicyDriven
        ));
        assert_eq!(snapshot.governance_envelope.policy_refs[0], "policy-7");
        assert_eq!(
            snapshot.trace_refs[0].kernel,
            WhyEvidenceSourceKernel::Policy
        );
    }

    #[test]
    fn explains_mechanistic_attribution_and_redacts_user_safe() {
        let payload = json!({
            "requested_perspective": "user_safe",
            "query_kind": "observed_outcome",
            "evidence_bundle": {
                "entries": [
                    {
                        "id": "step_failure",
                        "label": "validation blocked execute",
                        "weight": 0.88,
                        "polarity": "negative",
                        "source_kernel": "how",
                        "source_subsystem": "execution_path",
                        "durability": "transient",
                        "confidence": 0.72,
                        "observed": true
                    }
                ]
            }
        });

        let snapshot: WhySnapshot = serde_json::from_value(explain_why(
            payload.as_object().expect("payload should be object"),
        ))
        .expect("snapshot should decode");

        assert!(matches!(
            snapshot.root_cause_type,
            WhyRootCauseType::Mechanistic
        ));
        assert!(snapshot.trace_refs.is_empty());
        assert!(snapshot.governance_envelope.redacted);
        assert_eq!(
            snapshot.governance_envelope.redaction_reason,
            "user_safe_redaction"
        );
    }

    #[test]
    fn records_validation_issue_for_empty_request() {
        let payload = json!({});
        let snapshot: WhySnapshot = serde_json::from_value(explain_why(
            payload.as_object().expect("payload should be object"),
        ))
        .expect("snapshot should decode");

        assert_eq!(snapshot.validation_issues[0].code, "empty_evidence");
        assert_eq!(snapshot.confidence, 0.0);
        assert!(matches!(
            snapshot.root_cause_type,
            WhyRootCauseType::Unknown
        ));
    }

    #[test]
    fn caps_counterfactuals_and_preserves_alternates() {
        let payload = json!({
            "max_counterfactuals": 1,
            "evidence_bundle": {
                "entries": [
                    {
                        "id": "driver_primary",
                        "label": "strong preference",
                        "weight": 0.9,
                        "polarity": "positive",
                        "source_kernel": "who",
                        "source_subsystem": "profile",
                        "durability": "durable"
                    },
                    {
                        "id": "driver_secondary",
                        "label": "habit memory",
                        "weight": 0.6,
                        "polarity": "positive",
                        "source_kernel": "memory",
                        "source_subsystem": "habit_store",
                        "durability": "durable"
                    }
                ]
            }
        });

        let snapshot: WhySnapshot = serde_json::from_value(explain_why(
            payload.as_object().expect("payload should be object"),
        ))
        .expect("snapshot should decode");

        assert_eq!(snapshot.counterfactuals.len(), 1);
        assert_eq!(snapshot.alternate_hypotheses.len(), 1);
        assert!(snapshot.summary.contains("trait_driven") || snapshot.summary.contains("mixed"));
    }
}
