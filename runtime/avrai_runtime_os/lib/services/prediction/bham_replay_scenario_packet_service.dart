import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';

class ReplayScenarioValidationResult {
  const ReplayScenarioValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;
}

class BhamReplayScenarioBatchItem {
  const BhamReplayScenarioBatchItem({
    required this.runId,
    required this.branchLabel,
    required this.packet,
    required this.attendanceScore,
    required this.movementScore,
    required this.deliveryScore,
    required this.safetyStress,
    required this.localityPressures,
  });

  final String runId;
  final String branchLabel;
  final ReplayScenarioPacket packet;
  final double attendanceScore;
  final double movementScore;
  final double deliveryScore;
  final double safetyStress;
  final Map<String, double> localityPressures;
}

class BhamReplayScenarioPacketService {
  const BhamReplayScenarioPacketService();

  ReplayScenarioPacket createScenarioPacket({
    required String scenarioId,
    required String name,
    required String description,
    required ReplayScenarioKind scenarioKind,
    required ReplayScopeKind scope,
    required List<String> seedEntityRefs,
    required List<String> seedLocalityCodes,
    List<String> seedObservationRefs = const <String>[],
    List<ReplayScenarioIntervention> interventions =
        const <ReplayScenarioIntervention>[],
    List<String> expectedQuestions = const <String>[],
    DateTime? createdAt,
    String createdBy = 'internal',
  }) {
    return ReplayScenarioPacket(
      scenarioId: scenarioId,
      name: name,
      description: description,
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: scenarioKind,
      scope: scope,
      seedEntityRefs: seedEntityRefs,
      seedLocalityCodes: seedLocalityCodes,
      seedObservationRefs: seedObservationRefs,
      interventions: interventions,
      expectedQuestions: expectedQuestions,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      createdBy: createdBy,
    ).normalized();
  }

  ReplayScenarioValidationResult validateScenarioPacket(
    ReplayScenarioPacket packet,
  ) {
    final errors = <String>[
      if (packet.cityCode != bhamReplayCityCode)
        'Scenario city code must remain $bhamReplayCityCode.',
      if (packet.baseReplayYear != bhamReplayBaseYear)
        'Base replay year must remain $bhamReplayBaseYear.',
      if (!packet.isReplayOnly) 'Scenario packets must remain replay-only.',
      if (packet.seedLocalityCodes.isEmpty)
        'At least one Birmingham locality is required.',
      if (packet.interventions.length < 2)
        'Phase 1 scenarios require at least two interventions.',
      for (final locality in packet.seedLocalityCodes)
        if (!bhamLocalityDisplayNames.containsKey(locality))
          'Unknown Birmingham locality code: $locality',
    ];
    return ReplayScenarioValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  List<BhamReplayScenarioBatchItem> materializeScenarioBatchItems(
    ReplayScenarioPacket packet,
  ) {
    final normalized = packet.normalized();
    final baseline = BhamReplayScenarioBatchItem(
      runId: '${normalized.scenarioId}:baseline',
      branchLabel: 'baseline',
      packet: normalized,
      attendanceScore: 0.72,
      movementScore: 0.68,
      deliveryScore: 0.76,
      safetyStress: 0.28,
      localityPressures: _baselineLocalityPressures(normalized),
    );
    final branches = normalized.interventions.map((intervention) {
      final basePressure = _baselineLocalityPressures(normalized);
      final targetLocality = intervention.targetType == 'locality'
          ? intervention.targetRef
          : normalized.seedLocalityCodes.first;
      final pressureMagnitude = (intervention.magnitude * 0.55).clamp(0.0, 1.0);
      final attendancePenalty =
          intervention.kind == ReplayInterventionKind.attendanceSurge
              ? -intervention.magnitude * 0.10
              : -intervention.magnitude * 0.18;
      final movementPenalty =
          intervention.kind == ReplayInterventionKind.transitDelay ||
                  intervention.kind == ReplayInterventionKind.routeBlock
              ? intervention.magnitude * 0.22
              : intervention.magnitude * 0.12;
      final deliveryPenalty =
          intervention.kind == ReplayInterventionKind.staffingLoss
              ? intervention.magnitude * 0.24
              : intervention.magnitude * 0.14;
      final safetyStress =
          (baseline.safetyStress + intervention.magnitude * 0.35).clamp(0.0, 1.0);
      return BhamReplayScenarioBatchItem(
        runId: '${normalized.scenarioId}:${intervention.interventionId}',
        branchLabel: intervention.kind.name,
        packet: normalized,
        attendanceScore:
            (baseline.attendanceScore + attendancePenalty).clamp(0.0, 1.0),
        movementScore:
            (baseline.movementScore - movementPenalty).clamp(0.0, 1.0),
        deliveryScore:
            (baseline.deliveryScore - deliveryPenalty).clamp(0.0, 1.0),
        safetyStress: safetyStress,
        localityPressures: <String, double>{
          for (final entry in basePressure.entries)
            entry.key: entry.key == targetLocality
                ? (entry.value + pressureMagnitude).clamp(0.0, 1.0)
                : entry.value,
        },
      );
    });
    return <BhamReplayScenarioBatchItem>[
      baseline,
      ...branches,
    ];
  }

  Map<String, double> _baselineLocalityPressures(ReplayScenarioPacket packet) {
    final pressures = <String, double>{};
    for (final locality in packet.seedLocalityCodes) {
      pressures[locality] = 0.34 + (pressures.length * 0.06);
    }
    return pressures;
  }
}
