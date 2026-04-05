import 'dart:async';
import 'dart:convert';

import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:get_it/get_it.dart';

class PlanningTruthSurfaceAdminRow {
  const PlanningTruthSurfaceAdminRow({
    required this.signalId,
    required this.eventId,
    required this.kind,
    required this.truthScope,
    required this.evidenceEnvelope,
    required this.createdAt,
    required this.hostUserId,
    required this.tupleRefCount,
    required this.sourceKind,
    required this.confidence,
    required this.hostGoal,
    required this.candidateLocalityCode,
    required this.acceptedSuggestion,
    required this.predictedFillBand,
    required this.attendanceRate,
    required this.averageRating,
    required this.wouldAttendAgainRate,
  });

  final String signalId;
  final String eventId;
  final EventLearningSignalKind kind;
  final TruthScopeDescriptor truthScope;
  final TruthEvidenceEnvelope evidenceEnvelope;
  final DateTime createdAt;
  final String hostUserId;
  final int tupleRefCount;
  final String sourceKind;
  final String confidence;
  final String hostGoal;
  final String? candidateLocalityCode;
  final bool acceptedSuggestion;
  final String? predictedFillBand;
  final double? attendanceRate;
  final double? averageRating;
  final double? wouldAttendAgainRate;
}

class PlanningTruthSurfaceAdminSnapshot {
  const PlanningTruthSurfaceAdminSnapshot({
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.signalCount,
    required this.createdSignalCount,
    required this.completedSignalCount,
    required this.personalScopedCount,
    required this.localityScopedCount,
    required this.averageTupleRefCount,
    required this.averageAttendanceRate,
    required this.averageAverageRating,
    required this.averageWouldAttendAgainRate,
    required this.stratumCounts,
    required this.evidenceClassCounts,
    required this.privacyCounts,
    required this.hostGoalCounts,
    required this.recentSignals,
  });

  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int signalCount;
  final int createdSignalCount;
  final int completedSignalCount;
  final int personalScopedCount;
  final int localityScopedCount;
  final double averageTupleRefCount;
  final double averageAttendanceRate;
  final double averageAverageRating;
  final double averageWouldAttendAgainRate;
  final Map<String, int> stratumCounts;
  final Map<String, int> evidenceClassCounts;
  final Map<String, int> privacyCounts;
  final Map<String, int> hostGoalCounts;
  final List<PlanningTruthSurfaceAdminRow> recentSignals;
}

class PlanningTruthSurfaceAdminService {
  PlanningTruthSurfaceAdminService({
    required EventLearningSignalService learningSignalService,
    DateTime Function()? nowProvider,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
  })  : _learningSignalService = learningSignalService,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc()),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null);

  final EventLearningSignalService _learningSignalService;
  final DateTime Function() _nowProvider;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  String? _lastAssistantObservationFingerprint;

  Future<PlanningTruthSurfaceAdminSnapshot> getPlanningSnapshot({
    Duration lookbackWindow = const Duration(hours: 24),
    int limit = 100,
  }) async {
    final now = _nowProvider().toUtc();
    final windowStart = now.subtract(lookbackWindow);
    final rows = _learningSignalService
        .recentSignals(lookbackWindow: lookbackWindow, limit: limit)
        .map(_rowFromSignal)
        .toList(growable: false);
    final stratumCounts = <String, int>{};
    final evidenceClassCounts = <String, int>{};
    final privacyCounts = <String, int>{};
    final hostGoalCounts = <String, int>{};
    var createdSignalCount = 0;
    var completedSignalCount = 0;
    var personalScopedCount = 0;
    var localityScopedCount = 0;
    for (final row in rows) {
      stratumCounts[row.truthScope.governanceStratum.name] =
          (stratumCounts[row.truthScope.governanceStratum.name] ?? 0) + 1;
      evidenceClassCounts[row.evidenceEnvelope.evidenceClass] =
          (evidenceClassCounts[row.evidenceEnvelope.evidenceClass] ?? 0) + 1;
      privacyCounts[row.evidenceEnvelope.privacyLadderTag] =
          (privacyCounts[row.evidenceEnvelope.privacyLadderTag] ?? 0) + 1;
      hostGoalCounts[row.hostGoal] = (hostGoalCounts[row.hostGoal] ?? 0) + 1;
      if (row.kind == EventLearningSignalKind.eventCreated) {
        createdSignalCount += 1;
      } else if (row.kind == EventLearningSignalKind.eventCompleted) {
        completedSignalCount += 1;
      }
      if (row.truthScope.governanceStratum == GovernanceStratum.personal) {
        personalScopedCount += 1;
      } else if (row.truthScope.governanceStratum ==
          GovernanceStratum.locality) {
        localityScopedCount += 1;
      }
    }
    final outcomeRows = rows
        .where((row) => row.kind == EventLearningSignalKind.eventCompleted)
        .toList(growable: false);
    final snapshot = PlanningTruthSurfaceAdminSnapshot(
      generatedAt: now,
      windowStart: windowStart,
      windowEnd: now,
      signalCount: rows.length,
      createdSignalCount: createdSignalCount,
      completedSignalCount: completedSignalCount,
      personalScopedCount: personalScopedCount,
      localityScopedCount: localityScopedCount,
      averageTupleRefCount: _average(
        rows.map((row) => row.tupleRefCount.toDouble()),
      ),
      averageAttendanceRate: _average(
        outcomeRows.map((row) => row.attendanceRate ?? 0.0),
      ),
      averageAverageRating: _average(
        outcomeRows.map((row) => row.averageRating ?? 0.0),
      ),
      averageWouldAttendAgainRate: _average(
        outcomeRows.map((row) => row.wouldAttendAgainRate ?? 0.0),
      ),
      stratumCounts: stratumCounts,
      evidenceClassCounts: evidenceClassCounts,
      privacyCounts: privacyCounts,
      hostGoalCounts: hostGoalCounts,
      recentSignals: rows,
    );
    await _stageAssistantObservation(snapshot);
    return snapshot;
  }

  Stream<PlanningTruthSurfaceAdminSnapshot> watchPlanningSnapshot({
    Duration lookbackWindow = const Duration(hours: 24),
    Duration refreshInterval = const Duration(seconds: 15),
    int limit = 100,
  }) {
    late final StreamController<PlanningTruthSurfaceAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(
        await getPlanningSnapshot(
          lookbackWindow: lookbackWindow,
          limit: limit,
        ),
      );
    }

    controller = StreamController<PlanningTruthSurfaceAdminSnapshot>.broadcast(
      onListen: () async {
        await emit();
        timer = Timer.periodic(refreshInterval, (_) {
          unawaited(emit());
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  PlanningTruthSurfaceAdminRow _rowFromSignal(
    EventCreationLearningSignal signal,
  ) {
    final payload = signal.boundedPayload;
    final evidenceEnvelope = signal.evidenceEnvelope ??
        TruthEvidenceEnvelope(
          scope: signal.truthScope,
          traceId: signal.signalId,
          evidenceClass: 'planning_learning_signal',
          privacyLadderTag: 'bounded_planning_learning',
          sourceRefs: signal.tupleRefs,
          metadata: const <String, dynamic>{},
        );
    return PlanningTruthSurfaceAdminRow(
      signalId: signal.signalId,
      eventId: signal.eventId,
      kind: signal.kind,
      truthScope: signal.truthScope,
      evidenceEnvelope: evidenceEnvelope,
      createdAt: signal.createdAt,
      hostUserId: signal.hostUserId,
      tupleRefCount: signal.tupleRefs.length,
      sourceKind:
          signal.planningSnapshot.docket.airGapProvenance.sourceKind.name,
      confidence:
          signal.planningSnapshot.docket.airGapProvenance.confidence.name,
      hostGoal: payload['host_goal']?.toString() ??
          signal.planningSnapshot.docket.hostGoal.name,
      candidateLocalityCode: payload['candidate_locality_code']?.toString(),
      acceptedSuggestion: payload['accepted_suggestion'] as bool? ?? false,
      predictedFillBand: payload['predicted_fill_band']?.toString(),
      attendanceRate: (payload['attendance_rate'] as num?)?.toDouble(),
      averageRating: (payload['average_rating'] as num?)?.toDouble(),
      wouldAttendAgainRate:
          (payload['would_attend_again_rate'] as num?)?.toDouble(),
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0.0;
    }
    return list.reduce((left, right) => left + right) / list.length;
  }

  Future<void> _stageAssistantObservation(
    PlanningTruthSurfaceAdminSnapshot snapshot,
  ) async {
    final intakeService = _governedUpwardLearningIntakeService;
    if (intakeService == null || snapshot.signalCount == 0) {
      return;
    }
    final fingerprint = jsonEncode(<String, dynamic>{
      'signalCount': snapshot.signalCount,
      'createdSignalCount': snapshot.createdSignalCount,
      'completedSignalCount': snapshot.completedSignalCount,
      'averageAttendanceRate':
          snapshot.averageAttendanceRate.toStringAsFixed(4),
      'averageWouldAttendAgainRate':
          snapshot.averageWouldAttendAgainRate.toStringAsFixed(4),
      'recentSignalIds': snapshot.recentSignals
          .take(5)
          .map((row) => row.signalId)
          .toList(growable: false),
    });
    if (_lastAssistantObservationFingerprint == fingerprint) {
      return;
    }
    _lastAssistantObservationFingerprint = fingerprint;

    final primaryLocalityCode = snapshot.recentSignals
        .map((row) => row.candidateLocalityCode)
        .whereType<String>()
        .firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    final localityCode =
        primaryLocalityCode.isEmpty ? null : primaryLocalityCode.trim();
    final cityCode = localityCode?.split('_').first.trim();
    final summary =
        'Planning truth surface observed ${snapshot.signalCount} signals '
        'with ${snapshot.completedSignalCount} completed outcomes in the '
        'current window. Average attendance is '
        '${snapshot.averageAttendanceRate.toStringAsFixed(2)} and would-attend-again is '
        '${snapshot.averageWouldAttendAgainRate.toStringAsFixed(2)}.';
    final upwardQuestions = <String>[
      if (snapshot.completedSignalCount > 0 &&
          snapshot.averageAttendanceRate < 0.5)
        'Why are completed planning outcomes underperforming attendance expectations?',
      if (snapshot.localityScopedCount > 0)
        'Should locality-scoped planning convictions be reinforced from these recent outcomes?',
    ];
    final boundedMetadata = <String, dynamic>{
      'surface': 'planning_truth_surface_admin',
      'windowStartUtc': snapshot.windowStart.toIso8601String(),
      'windowEndUtc': snapshot.windowEnd.toIso8601String(),
      'signalCount': snapshot.signalCount,
      'createdSignalCount': snapshot.createdSignalCount,
      'completedSignalCount': snapshot.completedSignalCount,
      'personalScopedCount': snapshot.personalScopedCount,
      'localityScopedCount': snapshot.localityScopedCount,
      'averageTupleRefCount': snapshot.averageTupleRefCount,
      'averageAttendanceRate': snapshot.averageAttendanceRate,
      'averageAverageRating': snapshot.averageAverageRating,
      'averageWouldAttendAgainRate': snapshot.averageWouldAttendAgainRate,
      'hostGoalCounts': snapshot.hostGoalCounts,
      'evidenceClassCounts': snapshot.evidenceClassCounts,
      'recentSignalKinds': snapshot.recentSignals
          .take(5)
          .map((row) => row.kind.name)
          .toList(growable: false),
    };
    final airGapArtifact = const UpwardAirGapService().issueArtifact(
      originPlane: 'admin_assistant_service',
      sourceKind: 'assistant_bounded_observation_intake',
      sourceScope: 'assistant',
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: DateTime.now().toUtc(),
      pseudonymousActorRef: 'assistant:planning_truth_surface',
      sanitizedPayload: <String, dynamic>{
        'observationKind': 'planning_truth_surface_snapshot',
        'summary': summary,
        'boundedMetadata': boundedMetadata,
      },
      allowedNextStages: const <String>[
        'governed_upward_learning_review',
        'hierarchy_synthesis',
        'reality_model_agent',
      ],
    );
    await intakeService.stageSupervisorAssistantObservationIntake(
      observerId: 'assistant_planning_truth_surface',
      observerKind: 'assistant',
      occurredAtUtc: snapshot.generatedAt,
      summary: summary,
      airGapArtifact: airGapArtifact,
      cityCode: cityCode,
      localityCode: localityCode,
      observationKind: 'planning_truth_surface_snapshot',
      upwardDomainHints: <String>[
        'admin_oversight',
        'planning_truth',
        'event',
      ],
      upwardReferencedEntities: snapshot.recentSignals
          .take(5)
          .expand((row) => <String>[row.signalId, row.eventId])
          .toSet()
          .toList(growable: false),
      upwardQuestions: upwardQuestions,
      upwardSignalTags: <String>[
        'surface:planning_truth_surface_admin',
        'signal_count:${snapshot.signalCount}',
        if (snapshot.localityScopedCount > 0) 'scope:locality',
      ],
      boundedMetadata: boundedMetadata,
    );
  }
}
