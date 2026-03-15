use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::collections::{BTreeMap, HashMap, HashSet, VecDeque};

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum HowKernelKind {
    Procedure,
    CausalChain,
    BehaviorFlow,
    InstructionPath,
    DiagnosticTrace,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum StepKind {
    Action,
    Decision,
    Transformation,
    Validation,
    ExternalEffect,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DependencyKind {
    Input,
    Tool,
    Actor,
    Condition,
    PriorStep,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum OutcomeKind {
    Success,
    Failure,
    Partial,
    AlternatePath,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum KernelLinkKind {
    Who,
    What,
    Where,
    When,
    Why,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct KernelLink {
    pub kind: KernelLinkKind,
    pub value: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Dependency {
    pub name: String,
    pub kind: DependencyKind,
    #[serde(default)]
    pub required: bool,
    #[serde(default)]
    pub description: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct StateChange {
    pub from_state: String,
    pub to_state: String,
    #[serde(default)]
    pub reason: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FailureMode {
    pub name: String,
    pub cause: String,
    #[serde(default)]
    pub affected_step: String,
    #[serde(default)]
    pub recovery: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Outcome {
    pub kind: OutcomeKind,
    pub description: String,
    #[serde(default)]
    pub produced_by_step: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HowStep {
    pub id: String,
    pub name: String,
    pub kind: StepKind,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub inputs: Vec<String>,
    #[serde(default)]
    pub outputs: Vec<String>,
    #[serde(default)]
    pub conditions: Vec<String>,
    #[serde(default)]
    pub next: Vec<String>,
    #[serde(default)]
    pub state_changes: Vec<StateChange>,
    #[serde(default)]
    pub estimated_cost: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HowKernel {
    pub id: String,
    pub name: String,
    pub kind: HowKernelKind,
    #[serde(default)]
    pub trigger: String,
    #[serde(default)]
    pub objective: String,
    #[serde(default)]
    pub preconditions: Vec<String>,
    #[serde(default)]
    pub dependencies: Vec<Dependency>,
    #[serde(default)]
    pub steps: Vec<HowStep>,
    #[serde(default)]
    pub outcomes: Vec<Outcome>,
    #[serde(default)]
    pub failure_modes: Vec<FailureMode>,
    #[serde(default)]
    pub linked_kernels: Vec<KernelLink>,
    #[serde(default)]
    pub metadata: BTreeMap<String, String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HowKernelInput {
    #[serde(default)]
    pub kernel: Option<HowKernel>,
    #[serde(default)]
    pub id: String,
    #[serde(default)]
    pub name: String,
    #[serde(default = "default_how_kernel_kind")]
    pub kind: HowKernelKind,
    #[serde(default)]
    pub trigger: String,
    #[serde(default)]
    pub objective: String,
    #[serde(default)]
    pub preconditions: Vec<String>,
    #[serde(default)]
    pub dependencies: Vec<Dependency>,
    #[serde(default)]
    pub steps: Vec<HowStep>,
    #[serde(default)]
    pub outcomes: Vec<Outcome>,
    #[serde(default)]
    pub failure_modes: Vec<FailureMode>,
    #[serde(default)]
    pub linked_kernels: Vec<KernelLink>,
    #[serde(default)]
    pub metadata: BTreeMap<String, String>,
    #[serde(default)]
    pub start_step: String,
    #[serde(default = "default_max_depth")]
    pub max_depth: usize,
}

impl Default for HowKernelInput {
    fn default() -> Self {
        Self {
            kernel: None,
            id: String::new(),
            name: String::new(),
            kind: default_how_kernel_kind(),
            trigger: String::new(),
            objective: String::new(),
            preconditions: Vec::new(),
            dependencies: Vec::new(),
            steps: Vec::new(),
            outcomes: Vec::new(),
            failure_modes: Vec::new(),
            linked_kernels: Vec::new(),
            metadata: BTreeMap::new(),
            start_step: String::new(),
            max_depth: default_max_depth(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ValidationSeverity {
    Error,
    Warning,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ValidationIssue {
    pub severity: ValidationSeverity,
    pub message: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TraversalNode {
    pub step_id: String,
    pub depth: usize,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Bottleneck {
    pub step_id: String,
    pub inbound_paths: usize,
    pub reason: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HowSnapshot {
    pub kernel: HowKernel,
    pub summary: String,
    pub confidence: f64,
    pub entry_steps: Vec<String>,
    pub terminal_steps: Vec<String>,
    pub execution_path: Vec<TraversalNode>,
    pub bottlenecks: Vec<Bottleneck>,
    pub validation_issues: Vec<ValidationIssue>,
}

pub fn explain_how(payload: &Map<String, Value>) -> Value {
    let input = serde_json::from_value::<HowKernelInput>(Value::Object(payload.clone()))
        .unwrap_or_else(|_| HowKernelInput::default());
    let snapshot = build_snapshot(input);
    serde_json::to_value(snapshot).unwrap_or(Value::Null)
}

fn build_snapshot(input: HowKernelInput) -> HowSnapshot {
    let kernel = materialize_kernel(&input);
    let validation_issues = validate_kernel(&kernel);
    let entry_steps = entry_step_ids(&kernel);
    let terminal_steps = terminal_step_ids(&kernel);
    let execution_path = traverse_kernel(&kernel, &input.start_step, input.max_depth);
    let bottlenecks = detect_bottlenecks(&kernel);
    let confidence = estimate_confidence(&kernel, &validation_issues, &execution_path);
    let summary = build_summary(
        &kernel,
        &entry_steps,
        &terminal_steps,
        &bottlenecks,
        confidence,
    );

    HowSnapshot {
        kernel,
        summary,
        confidence,
        entry_steps,
        terminal_steps,
        execution_path,
        bottlenecks,
        validation_issues,
    }
}

fn materialize_kernel(input: &HowKernelInput) -> HowKernel {
    if let Some(kernel) = input.kernel.clone() {
        return kernel;
    }

    HowKernel {
        id: default_kernel_id(input),
        name: default_kernel_name(input),
        kind: input.kind.clone(),
        trigger: input.trigger.clone(),
        objective: input.objective.clone(),
        preconditions: input.preconditions.clone(),
        dependencies: input.dependencies.clone(),
        steps: input.steps.clone(),
        outcomes: input.outcomes.clone(),
        failure_modes: input.failure_modes.clone(),
        linked_kernels: input.linked_kernels.clone(),
        metadata: input.metadata.clone(),
    }
}

fn validate_kernel(kernel: &HowKernel) -> Vec<ValidationIssue> {
    let mut issues = Vec::new();

    if kernel.steps.is_empty() {
        issues.push(error_issue("kernel has no steps"));
        return issues;
    }

    let mut seen_ids = HashSet::new();
    let step_ids = kernel
        .steps
        .iter()
        .map(|step| step.id.as_str())
        .collect::<HashSet<_>>();

    for step in &kernel.steps {
        if step.id.trim().is_empty() {
            issues.push(error_issue("step id cannot be empty"));
        }
        if step.name.trim().is_empty() {
            issues.push(warning_issue(format!(
                "step {} is missing a name",
                printable_step_id(step)
            )));
        }
        if !seen_ids.insert(step.id.clone()) {
            issues.push(error_issue(format!("duplicate step id {}", step.id)));
        }
        for next_step in &step.next {
            if !step_ids.contains(next_step.as_str()) {
                issues.push(error_issue(format!(
                    "step {} references missing next step {}",
                    printable_step_id(step),
                    next_step
                )));
            }
        }
    }

    for outcome in &kernel.outcomes {
        if !outcome.produced_by_step.trim().is_empty()
            && !step_ids.contains(outcome.produced_by_step.as_str())
        {
            issues.push(error_issue(format!(
                "outcome references missing step {}",
                outcome.produced_by_step
            )));
        }
    }

    for failure_mode in &kernel.failure_modes {
        if !failure_mode.affected_step.trim().is_empty()
            && !step_ids.contains(failure_mode.affected_step.as_str())
        {
            issues.push(warning_issue(format!(
                "failure mode {} references missing step {}",
                failure_mode.name, failure_mode.affected_step
            )));
        }
    }

    if entry_step_ids(kernel).is_empty() {
        issues.push(error_issue("kernel has no entry step"));
    }
    if terminal_step_ids(kernel).is_empty() {
        issues.push(warning_issue("kernel has no terminal step"));
    }
    if kernel.linked_kernels.is_empty() {
        issues.push(warning_issue(
            "kernel is not linked to who/what/where/when/why context",
        ));
    }

    issues
}

fn entry_step_ids(kernel: &HowKernel) -> Vec<String> {
    let mut referenced = HashSet::new();
    for step in &kernel.steps {
        for next_step in &step.next {
            referenced.insert(next_step.as_str());
        }
    }

    kernel
        .steps
        .iter()
        .filter(|step| !referenced.contains(step.id.as_str()))
        .map(|step| step.id.clone())
        .collect()
}

fn terminal_step_ids(kernel: &HowKernel) -> Vec<String> {
    kernel
        .steps
        .iter()
        .filter(|step| step.next.is_empty())
        .map(|step| step.id.clone())
        .collect()
}

fn traverse_kernel(
    kernel: &HowKernel,
    requested_start_step: &str,
    max_depth: usize,
) -> Vec<TraversalNode> {
    let index = step_index(kernel);
    let entry_steps = entry_step_ids(kernel);
    let start_steps =
        if !requested_start_step.trim().is_empty() && index.contains_key(requested_start_step) {
            vec![requested_start_step.to_string()]
        } else if !entry_steps.is_empty() {
            entry_steps
        } else {
            kernel
                .steps
                .first()
                .map(|step| vec![step.id.clone()])
                .unwrap_or_default()
        };

    let capped_depth = max_depth.max(1);
    let mut queue = VecDeque::new();
    let mut visited = HashSet::new();
    let mut path = Vec::new();

    for start in start_steps {
        queue.push_back((start, 0usize));
    }

    while let Some((step_id, depth)) = queue.pop_front() {
        if depth > capped_depth || !visited.insert(step_id.clone()) {
            continue;
        }

        path.push(TraversalNode {
            step_id: step_id.clone(),
            depth,
        });

        if let Some(step) = index.get(step_id.as_str()) {
            for next in &step.next {
                queue.push_back((next.clone(), depth + 1));
            }
        }
    }

    path
}

fn detect_bottlenecks(kernel: &HowKernel) -> Vec<Bottleneck> {
    let mut inbound_counts: HashMap<&str, usize> = HashMap::new();
    for step in &kernel.steps {
        for next in &step.next {
            *inbound_counts.entry(next.as_str()).or_insert(0) += 1;
        }
    }

    let mut bottlenecks = kernel
        .steps
        .iter()
        .filter_map(|step| {
            let inbound_paths = inbound_counts.get(step.id.as_str()).copied().unwrap_or(0);
            if inbound_paths >= 2 || matches!(step.kind, StepKind::Decision | StepKind::Validation)
            {
                Some(Bottleneck {
                    step_id: step.id.clone(),
                    inbound_paths,
                    reason: bottleneck_reason(step, inbound_paths),
                })
            } else {
                None
            }
        })
        .collect::<Vec<_>>();

    bottlenecks.sort_by(|left, right| right.inbound_paths.cmp(&left.inbound_paths));
    bottlenecks
}

fn estimate_confidence(
    kernel: &HowKernel,
    validation_issues: &[ValidationIssue],
    execution_path: &[TraversalNode],
) -> f64 {
    if kernel.steps.is_empty() {
        return 0.0;
    }

    let step_coverage = (execution_path.len() as f64 / kernel.steps.len() as f64).clamp(0.0, 1.0);
    let dependency_bonus = if kernel.dependencies.is_empty() {
        0.0
    } else {
        0.1
    };
    let outcome_bonus = if kernel.outcomes.is_empty() { 0.0 } else { 0.1 };
    let link_bonus = (kernel.linked_kernels.len() as f64 * 0.03).clamp(0.0, 0.15);
    let error_penalty = validation_issues
        .iter()
        .filter(|issue| issue.severity == ValidationSeverity::Error)
        .count() as f64
        * 0.18;
    let warning_penalty = validation_issues
        .iter()
        .filter(|issue| issue.severity == ValidationSeverity::Warning)
        .count() as f64
        * 0.05;

    (0.55 + (step_coverage * 0.2) + dependency_bonus + outcome_bonus + link_bonus
        - error_penalty
        - warning_penalty)
        .clamp(0.0, 1.0)
}

fn build_summary(
    kernel: &HowKernel,
    entry_steps: &[String],
    terminal_steps: &[String],
    bottlenecks: &[Bottleneck],
    confidence: f64,
) -> String {
    let objective = if kernel.objective.trim().is_empty() {
        "produce an outcome"
    } else {
        kernel.objective.as_str()
    };
    let entry = entry_steps
        .first()
        .map(String::as_str)
        .unwrap_or("unknown_entry");
    let terminal = terminal_steps
        .first()
        .map(String::as_str)
        .unwrap_or("open_ended");
    let bottleneck = bottlenecks
        .first()
        .map(|item| item.step_id.as_str())
        .unwrap_or("no dominant bottleneck");

    format!(
        "{} describes how {} moves from {} to {} across {} steps; primary control point is {} and confidence is {:.2}.",
        kernel.name,
        objective,
        entry,
        terminal,
        kernel.steps.len(),
        bottleneck,
        confidence
    )
}

fn step_index(kernel: &HowKernel) -> HashMap<&str, &HowStep> {
    kernel
        .steps
        .iter()
        .map(|step| (step.id.as_str(), step))
        .collect()
}

fn bottleneck_reason(step: &HowStep, inbound_paths: usize) -> String {
    if inbound_paths >= 2 {
        return format!("{} inbound paths converge here", inbound_paths);
    }
    match step.kind {
        StepKind::Decision => "decision step can redirect execution".to_string(),
        StepKind::Validation => "validation step can block downstream execution".to_string(),
        _ => "high coordination point".to_string(),
    }
}

fn default_kernel_id(input: &HowKernelInput) -> String {
    if !input.id.trim().is_empty() {
        input.id.clone()
    } else if !input.name.trim().is_empty() {
        input.name.to_lowercase().replace(' ', "_")
    } else {
        "how_kernel".to_string()
    }
}

fn default_kernel_name(input: &HowKernelInput) -> String {
    if !input.name.trim().is_empty() {
        input.name.clone()
    } else {
        "How Kernel".to_string()
    }
}

fn default_how_kernel_kind() -> HowKernelKind {
    HowKernelKind::Procedure
}

fn default_max_depth() -> usize {
    16
}

fn printable_step_id(step: &HowStep) -> &str {
    if step.id.trim().is_empty() {
        "<empty>"
    } else {
        step.id.as_str()
    }
}

fn error_issue(message: impl Into<String>) -> ValidationIssue {
    ValidationIssue {
        severity: ValidationSeverity::Error,
        message: message.into(),
    }
}

fn warning_issue(message: impl Into<String>) -> ValidationIssue {
    ValidationIssue {
        severity: ValidationSeverity::Warning,
        message: message.into(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn explains_instruction_path_with_kernel_links() {
        let payload = json!({
            "id": "how_brew_tea",
            "name": "Brew Tea",
            "objective": "brew drinkable tea",
            "linked_kernels": [
                {"kind": "who", "value": "user"},
                {"kind": "what", "value": "tea"},
                {"kind": "where", "value": "kitchen"},
                {"kind": "when", "value": "morning"},
                {"kind": "why", "value": "restore focus"}
            ],
            "dependencies": [
                {"name": "water", "kind": "input", "required": true},
                {"name": "kettle", "kind": "tool", "required": true}
            ],
            "steps": [
                {
                    "id": "boil_water",
                    "name": "Boil Water",
                    "kind": "action",
                    "outputs": ["boiling_water"],
                    "next": ["steep_tea"]
                },
                {
                    "id": "steep_tea",
                    "name": "Steep Tea",
                    "kind": "transformation",
                    "inputs": ["boiling_water", "tea_bag"],
                    "outputs": ["tea"],
                    "next": ["serve"]
                },
                {
                    "id": "serve",
                    "name": "Serve",
                    "kind": "external_effect",
                    "outputs": ["drinkable_tea"],
                    "next": []
                }
            ],
            "outcomes": [
                {"kind": "success", "description": "tea is ready", "produced_by_step": "serve"}
            ]
        });

        let snapshot: HowSnapshot = serde_json::from_value(explain_how(
            payload.as_object().expect("payload should be an object"),
        ))
        .expect("snapshot should decode");

        assert_eq!(snapshot.entry_steps, vec!["boil_water"]);
        assert_eq!(snapshot.terminal_steps, vec!["serve"]);
        assert_eq!(snapshot.execution_path.len(), 3);
        assert!(snapshot
            .validation_issues
            .iter()
            .all(|issue| issue.severity != ValidationSeverity::Error));
        assert!(snapshot.confidence > 0.7);
    }

    #[test]
    fn flags_missing_edges_and_missing_context_links() {
        let payload = json!({
            "name": "Broken Flow",
            "steps": [
                {
                    "id": "start",
                    "name": "Start",
                    "kind": "action",
                    "next": ["missing_step"]
                }
            ],
            "outcomes": [
                {"kind": "failure", "description": "flow breaks", "produced_by_step": "missing_step"}
            ]
        });

        let snapshot: HowSnapshot = serde_json::from_value(explain_how(
            payload.as_object().expect("payload should be an object"),
        ))
        .expect("snapshot should decode");

        assert!(snapshot.validation_issues.iter().any(|issue| {
            issue.severity == ValidationSeverity::Error
                && issue.message.contains("references missing next step")
        }));
        assert!(snapshot.validation_issues.iter().any(|issue| {
            issue.severity == ValidationSeverity::Warning
                && issue
                    .message
                    .contains("not linked to who/what/where/when/why")
        }));
        assert!(snapshot.confidence < 0.6);
    }

    #[test]
    fn detects_decision_bottleneck_and_respects_start_step_query() {
        let payload = json!({
            "name": "Triage Flow",
            "start_step": "assess",
            "steps": [
                {"id": "intake", "name": "Intake", "kind": "action", "next": ["assess"]},
                {"id": "retry", "name": "Retry", "kind": "action", "next": ["assess"]},
                {"id": "assess", "name": "Assess", "kind": "decision", "next": ["resolve", "escalate"]},
                {"id": "resolve", "name": "Resolve", "kind": "external_effect", "next": []},
                {"id": "escalate", "name": "Escalate", "kind": "validation", "next": []}
            ]
        });

        let snapshot: HowSnapshot = serde_json::from_value(explain_how(
            payload.as_object().expect("payload should be an object"),
        ))
        .expect("snapshot should decode");

        assert_eq!(snapshot.execution_path[0].step_id, "assess");
        assert_eq!(snapshot.bottlenecks[0].step_id, "assess");
        assert!(snapshot.bottlenecks[0].reason.contains("inbound"));
    }
}
