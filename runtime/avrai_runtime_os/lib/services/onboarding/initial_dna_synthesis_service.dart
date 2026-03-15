import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/language/kernel_derived_language_dimension_mapper.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:reality_engine/reality_engine.dart';

class InitialDnaSeedResult {
  const InitialDnaSeedResult({
    required this.baselineDimensions,
    required this.turns,
    required this.mutationReceipts,
    required this.whySnapshot,
    this.seededSnapshot,
  });

  final Map<String, double> baselineDimensions;
  final List<HumanLanguageKernelTurn> turns;
  final List<TrajectoryMutationRecord> mutationReceipts;
  final WhySnapshot whySnapshot;
  final VibeStateSnapshot? seededSnapshot;
}

/// Kernel-governed onboarding synthesis for the initial 12D personality vector.
///
/// Human responses are processed through interpretation + boundary first. This
/// service only reads the sanitized artifacts that survive that pass.
class InitialDNASynthesisService {
  InitialDNASynthesisService({
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    KernelDerivedLanguageDimensionMapper? dimensionMapper,
    TrajectoryKernel? trajectoryKernel,
    VibeKernel? vibeKernel,
  })  : _languageKernelOrchestrator =
            languageKernelOrchestrator ?? LanguageKernelOrchestratorService(),
        _dimensionMapper =
            dimensionMapper ?? KernelDerivedLanguageDimensionMapper(),
        _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel(),
        _vibeKernel = vibeKernel ?? VibeKernel();

  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final KernelDerivedLanguageDimensionMapper _dimensionMapper;
  final TrajectoryKernel _trajectoryKernel;
  final VibeKernel _vibeKernel;

  Future<InitialDnaSeedResult> synthesizeInitialDNA(
    Map<String, String> openResponses, {
    String actorAgentId = 'agt_onboarding_local',
    Set<String> consentScopes = const <String>{'user_runtime_learning'},
  }) async {
    if (openResponses.isEmpty) {
      return InitialDnaSeedResult(
        baselineDimensions: _getFallbackDNA(),
        turns: const <HumanLanguageKernelTurn>[],
        mutationReceipts: const <TrajectoryMutationRecord>[],
        whySnapshot: _buildInitialDnaWhySnapshot(
          baselineDimensions: _getFallbackDNA(),
          mutationReceipts: const <TrajectoryMutationRecord>[],
          turns: const <HumanLanguageKernelTurn>[],
          seededSnapshot: null,
        ),
      );
    }

    try {
      final subjectRef = VibeSubjectRef.personal(actorAgentId);
      final beforeMutationIds = _trajectoryKernel
          .replaySubject(subjectRef: subjectRef, limit: 4096)
          .map((entry) => entry.recordId)
          .toSet();
      final turns = <HumanLanguageKernelTurn>[];
      for (final entry in openResponses.entries) {
        if (entry.value.trim().isEmpty) {
          continue;
        }
        turns.add(
          await _languageKernelOrchestrator.processHumanText(
            actorAgentId: actorAgentId,
            rawText: entry.value,
            consentScopes: consentScopes,
            chatType: 'onboarding',
            surface: 'onboarding_dna',
            channel: _channelFromKey(entry.key),
          ),
        );
      }

      final dnaVector = turns.isEmpty
          ? _getFallbackDNA()
          : _dimensionMapper.synthesizeBaselineFromTurns(turns);
      final mutationReceipts = _trajectoryKernel
          .replaySubject(subjectRef: subjectRef, limit: 4096)
          .where((entry) => !beforeMutationIds.contains(entry.recordId))
          .toList()
        ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
      final seededSnapshot = mutationReceipts.isEmpty
          ? null
          : _vibeKernel.getUserSnapshot(actorAgentId);

      developer.log(
        'Synthesized initial DNA vector through the language kernel: '
        '$dnaVector',
        name: 'InitialDNASynthesisService',
      );
      return InitialDnaSeedResult(
        baselineDimensions: dnaVector,
        turns: turns,
        mutationReceipts: mutationReceipts,
        seededSnapshot: seededSnapshot,
        whySnapshot: _buildInitialDnaWhySnapshot(
          baselineDimensions: dnaVector,
          mutationReceipts: mutationReceipts,
          turns: turns,
          seededSnapshot: seededSnapshot,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to synthesize DNA through the language kernel, falling back: '
        '$e',
        error: e,
        stackTrace: st,
        name: 'InitialDNASynthesisService',
      );
      return InitialDnaSeedResult(
        baselineDimensions: _getFallbackDNA(),
        turns: const <HumanLanguageKernelTurn>[],
        mutationReceipts: const <TrajectoryMutationRecord>[],
        whySnapshot: _buildInitialDnaWhySnapshot(
          baselineDimensions: _getFallbackDNA(),
          mutationReceipts: const <TrajectoryMutationRecord>[],
          turns: const <HumanLanguageKernelTurn>[],
          seededSnapshot: null,
        ),
      );
    }
  }

  WhySnapshot _buildInitialDnaWhySnapshot({
    required Map<String, double> baselineDimensions,
    required List<TrajectoryMutationRecord> mutationReceipts,
    required List<HumanLanguageKernelTurn> turns,
    required VibeStateSnapshot? seededSnapshot,
  }) {
    final dimensionDrivers = baselineDimensions.entries
        .where((entry) => (entry.value - 0.5).abs() >= 0.08)
        .toList()
      ..sort(
        (a, b) => (b.value - 0.5).abs().compareTo((a.value - 0.5).abs()),
      );
    final receiptDrivers = mutationReceipts
        .where((entry) => entry.accepted)
        .map(
          (entry) => WhySignal(
            label: entry.evidenceSummary ?? 'onboarding language signal',
            weight: (seededSnapshot?.confidence ?? 0.7).clamp(0.2, 1.0),
            source: entry.governanceScope,
            durable: true,
            confidence: (seededSnapshot?.confidence ?? 0.7).clamp(0.0, 1.0),
            evidenceId: entry.recordId,
            kernel: WhyEvidenceSourceKernel.model,
          ),
        )
        .toList();
    final drivers = <WhySignal>[
      ...receiptDrivers.take(3),
      ...dimensionDrivers.take(3).map(
            (entry) => WhySignal(
              label: _dimensionDriverLabel(entry.key, entry.value),
              weight: ((entry.value - 0.5).abs() * 2).clamp(0.0, 1.0),
              source: 'onboarding',
              durable: true,
              confidence: (seededSnapshot?.confidence ?? 0.65).clamp(0.0, 1.0),
              evidenceId: 'dimension:${entry.key}',
              kernel: WhyEvidenceSourceKernel.model,
            ),
          ),
    ];

    final traceRefs = mutationReceipts
        .take(6)
        .map(
          (entry) => WhyTraceRef(
            traceType: 'trajectory_mutation',
            kernel: WhyEvidenceSourceKernel.model,
            timeRef: entry.occurredAtUtc.toIso8601String(),
            explanationRef: entry.recordId,
          ),
        )
        .toList(growable: false);
    final driverLabels = drivers.map((entry) => entry.label).toList();
    final summary = mutationReceipts.isEmpty
        ? 'AVRAI started from a neutral onboarding baseline because it did not have enough governed language evidence yet.'
        : 'AVRAI seeded your initial DNA from ${mutationReceipts.length} governed onboarding language updates and the strongest stable dimension shifts in your responses.';

    return WhySnapshot(
      goal: 'seed_initial_personal_dna',
      queryKind: WhyQueryKind.modelUpdate,
      drivers: drivers,
      inhibitors: const <WhySignal>[],
      confidence: (seededSnapshot?.confidence ?? 0.0).clamp(0.0, 1.0),
      rootCauseType: WhyRootCauseType.traitDriven,
      summary: summary,
      counterfactuals: mutationReceipts.isEmpty
          ? const <WhyCounterfactual>[
              WhyCounterfactual(
                condition: 'Without governed onboarding language',
                expectedEffect:
                    'AVRAI would keep a neutral baseline until stronger evidence arrives.',
                confidenceDelta: -0.25,
              ),
            ]
          : const <WhyCounterfactual>[
              WhyCounterfactual(
                condition: 'Without the open-response onboarding evidence',
                expectedEffect:
                    'AVRAI would have kept a more neutral first-session DNA baseline.',
                confidenceDelta: -0.2,
              ),
            ],
      ambiguity: mutationReceipts.isEmpty ? 0.55 : 0.18,
      traceRefs: traceRefs,
      governanceEnvelope: WhyGovernanceEnvelope(
        redacted: false,
        policyRefs: mutationReceipts
            .expand((entry) => entry.reasonCodes)
            .map((entry) => entry.toString())
            .toSet()
            .toList(growable: false),
      ),
      generatedAt: DateTime.now().toUtc(),
      attributionSummary: WhyAttributionSummary(
        driverLabels: driverLabels,
        inhibitorLabels: const <String>[],
        topKernel: WhyEvidenceSourceKernel.model.toWireValue(),
      ),
    );
  }

  String _dimensionDriverLabel(String dimension, double value) {
    final direction = value >= 0.5 ? 'higher' : 'lower';
    return '${_humanizeDimension(dimension)} trended $direction during onboarding';
  }

  String _humanizeDimension(String dimension) {
    final words = dimension.split('_').where((entry) => entry.isNotEmpty);
    return words
        .map((entry) => '${entry[0].toUpperCase()}${entry.substring(1)}')
        .join(' ');
  }

  String _channelFromKey(String key) {
    final normalized = key
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'onboarding' : 'onboarding_$normalized';
  }

  Map<String, double> _getFallbackDNA() => <String, double>{
        for (final dimension in VibeConstants.coreDimensions)
          dimension: VibeConstants.defaultDimensionValue,
      };
}
