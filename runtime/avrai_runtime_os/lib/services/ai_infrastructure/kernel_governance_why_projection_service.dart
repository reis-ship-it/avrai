import 'package:avrai_core/models/temporal/semantic_time_band.dart';
import 'package:avrai_core/models/temporal/temporal_instant.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';
import 'package:avrai_core/models/temporal/temporal_snapshot.dart';
import 'package:avrai_core/models/temporal/temporal_uncertainty.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/why/why_evidence_adapters.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_support.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_telemetry_service.dart';

class KernelGovernanceWhyProjectionService {
  const KernelGovernanceWhyProjectionService({
    this.whySupport = const DefaultWhyKernelSupport(),
    this.temporalEvidenceAdapter = const TemporalWhyEvidenceAdapter(
      sourceSubsystem: 'kernel_governance_telemetry',
    ),
    this.howEvidenceAdapter = const HowMechanismWhyEvidenceAdapter(
      sourceSubsystem: 'kernel_governance_telemetry',
    ),
  });

  final DefaultWhyKernelSupport whySupport;
  final TemporalWhyEvidenceAdapter temporalEvidenceAdapter;
  final HowMechanismWhyEvidenceAdapter howEvidenceAdapter;

  WhySnapshot explainEvent(
    KernelGovernanceTelemetryEvent event, {
    WhyRequestedPerspective perspective = WhyRequestedPerspective.admin,
  }) {
    final outcomeRef = WhyRef(
      id: _outcomeId(event),
      label: _outcomeLabel(event),
      kind: 'governance_outcome',
    );
    final evidence = <WhyEvidence>[
      _primaryDecisionEvidence(event),
      _modeEvidence(event),
      temporalEvidenceAdapter.toWhyEvidence(
        TemporalSnapshot(
          observedAt: TemporalInstant(
            referenceTime: event.timestamp,
            civilTime: event.timestamp,
            timezoneId: 'UTC',
            provenance: const TemporalProvenance(
              authority: TemporalAuthority.device,
              source: 'kernel_governance_telemetry',
            ),
            uncertainty: const TemporalUncertainty.zero(),
          ),
          recordedAt: TemporalInstant(
            referenceTime: event.timestamp,
            civilTime: event.timestamp,
            timezoneId: 'UTC',
            provenance: const TemporalProvenance(
              authority: TemporalAuthority.device,
              source: 'kernel_governance_telemetry',
            ),
            uncertainty: const TemporalUncertainty.zero(),
          ),
          effectiveAt: TemporalInstant(
            referenceTime: event.timestamp,
            civilTime: event.timestamp,
            timezoneId: 'UTC',
            provenance: const TemporalProvenance(
              authority: TemporalAuthority.device,
              source: 'kernel_governance_telemetry',
            ),
            uncertainty: const TemporalUncertainty.zero(),
          ),
          semanticBand: _semanticBandFor(event.timestamp),
          lineageRef: 'governance_${event.decisionId}',
        ),
      ),
      howEvidenceAdapter.toWhyEvidence(
        HowMechanismContext(
          executionPath: 'kernel_governance_telemetry_projection',
          workflowStage: event.servingAllowed ? 'decision_recorded' : 'blocked',
          failureMechanism:
              event.servingAllowed ? null : event.reasonCodes.join(','),
          mechanismConfidence: event.reasonCodes.isEmpty ? 0.68 : 0.86,
          interventionChain: <String>[
            'policy_eval',
            if (!event.wouldAllow) 'deny_candidate',
            if (event.shadowBypassApplied) 'shadow_bypass',
            'telemetry_record',
          ],
          modelFamily: event.modelType ?? 'kernel_governance',
        ),
      ),
      ...event.reasonCodes.map(
        (reason) => WhyEvidence(
          id: 'reason_${event.decisionId}_$reason',
          label: 'governance reason: $reason',
          weight: 0.82,
          polarity: WhyEvidencePolarity.negative,
          sourceKernel: WhyEvidenceSourceKernel.policy,
          sourceSubsystem: 'kernel_governance_telemetry',
          durability: 'durable',
          confidence: 0.9,
          observed: true,
          inferred: false,
          provenance: event.policyVersion,
          timeRef: event.timestamp.toIso8601String(),
          subjectRef: event.modelType,
          scope: event.action,
          tags: <String>['governance', reason, event.mode],
        ),
      ),
    ];

    return whySupport.explain(
      WhyKernelRequest(
        goal: 'inspect_governance_decision',
        actionRef: WhyRef(
          id: event.action,
          label: event.action,
          kind: 'kernel_governance_action',
        ),
        outcomeRef: outcomeRef,
        queryKind: WhyQueryKind.policyAction,
        requestedPerspective: perspective,
        evidenceBundle: WhyEvidenceBundle(entries: evidence),
        policyContext: <String, dynamic>{
          'policyRefs': <String>[event.policyVersion],
          'escalationThresholds': event.reasonCodes,
        },
        linkedWhatRefs: <WhyRef>[
          if (event.modelType != null)
            WhyRef(
              id: event.modelType!,
              label: event.modelType!,
              kind: 'model_type',
            ),
        ],
        linkedWhenRefs: <WhyRef>[
          WhyRef(
            id: event.timestamp.toIso8601String(),
            label: _semanticBandFor(event.timestamp).name,
            kind: 'decision_time',
          ),
        ],
        linkedHowRefs: const <WhyRef>[
          WhyRef(
            id: 'kernel_governance_telemetry_projection',
            label: 'kernel_governance_telemetry_projection',
            kind: 'execution_path',
          ),
        ],
        maxCounterfactuals: 2,
        explanationDepth: 3,
      ),
    );
  }

  WhyEvidence _primaryDecisionEvidence(KernelGovernanceTelemetryEvent event) {
    return WhyEvidence(
      id: 'decision_${event.decisionId}',
      label: _outcomeLabel(event),
      weight: event.servingAllowed ? 0.74 : 0.9,
      polarity: event.servingAllowed
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.negative,
      sourceKernel: WhyEvidenceSourceKernel.policy,
      sourceSubsystem: 'kernel_governance_telemetry',
      durability: 'durable',
      confidence: 0.92,
      observed: true,
      inferred: false,
      provenance: event.policyVersion,
      timeRef: event.timestamp.toIso8601String(),
      subjectRef: event.modelType,
      scope: event.action,
      tags: <String>[
        event.mode,
        if (event.shadowBypassApplied) 'shadow_bypass',
      ],
    );
  }

  WhyEvidence _modeEvidence(KernelGovernanceTelemetryEvent event) {
    return WhyEvidence(
      id: 'mode_${event.decisionId}',
      label: 'mode ${event.mode}',
      weight: event.mode == 'enforce' ? 0.71 : 0.58,
      polarity: event.shadowBypassApplied
          ? WhyEvidencePolarity.negative
          : WhyEvidencePolarity.positive,
      sourceKernel: WhyEvidenceSourceKernel.policy,
      sourceSubsystem: 'kernel_governance_telemetry',
      durability: 'durable',
      confidence: 0.84,
      observed: true,
      inferred: false,
      provenance: event.policyVersion,
      timeRef: event.timestamp.toIso8601String(),
      subjectRef: event.modelType,
      scope: event.action,
      tags: <String>[event.mode],
    );
  }

  String _outcomeId(KernelGovernanceTelemetryEvent event) {
    if (!event.servingAllowed) {
      return 'blocked';
    }
    if (event.shadowBypassApplied) {
      return 'shadow_bypass';
    }
    return 'allowed';
  }

  String _outcomeLabel(KernelGovernanceTelemetryEvent event) {
    if (!event.servingAllowed) {
      return 'governance decision blocked serving';
    }
    if (event.shadowBypassApplied) {
      return 'governance decision allowed via shadow bypass';
    }
    return 'governance decision allowed serving';
  }

  SemanticTimeBand _semanticBandFor(DateTime timestamp) {
    final hour = timestamp.toUtc().hour;
    if (hour >= 5 && hour < 8) {
      return SemanticTimeBand.dawn;
    }
    if (hour >= 8 && hour < 12) {
      return SemanticTimeBand.morning;
    }
    if (hour == 12) {
      return SemanticTimeBand.noon;
    }
    if (hour > 12 && hour < 17) {
      return SemanticTimeBand.afternoon;
    }
    if (hour >= 17 && hour < 19) {
      return SemanticTimeBand.dusk;
    }
    if (hour >= 19 && hour < 20) {
      return SemanticTimeBand.goldenHour;
    }
    if (hour >= 20 || hour < 5) {
      return SemanticTimeBand.night;
    }
    return SemanticTimeBand.unknown;
  }
}
