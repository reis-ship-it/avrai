// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:reality_engine/reality_engine.dart';

class TestVibeKernel extends VibeKernel {
  TestVibeKernel({
    TrajectoryKernel? trajectoryKernel,
  }) : _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel();

  final TrajectoryKernel _trajectoryKernel;
  final Map<String, VibeStateSnapshot> _subjectSnapshots =
      <String, VibeStateSnapshot>{};
  final Map<String, EntityVibeSnapshot> _entitySnapshots =
      <String, EntityVibeSnapshot>{};
  DateTime _exportedAtUtc = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  List<String> _migrationReceipts = const <String>[];
  Map<String, dynamic> _metadata = const <String, dynamic>{};
  int _schemaVersion = 1;

  @override
  void importSnapshotEnvelope(VibeSnapshotEnvelope envelope) {
    _subjectSnapshots
      ..clear()
      ..addEntries(
        envelope.subjectSnapshots.map(
          (snapshot) => MapEntry(_subjectKey(snapshot.subjectRef), snapshot),
        ),
      );
    _entitySnapshots
      ..clear()
      ..addEntries(
        envelope.entitySnapshots.map(
          (snapshot) => MapEntry(
            _entityKey(snapshot.entityId, snapshot.entityType),
            snapshot,
          ),
        ),
      );
    _exportedAtUtc = envelope.exportedAtUtc.toUtc();
    _migrationReceipts = List<String>.from(envelope.migrationReceipts);
    _metadata = Map<String, dynamic>.from(envelope.metadata);
    _schemaVersion = envelope.schemaVersion;
  }

  @override
  VibeSnapshotEnvelope exportSnapshotEnvelope() {
    return VibeSnapshotEnvelope(
      exportedAtUtc: _exportedAtUtc,
      subjectSnapshots: _subjectSnapshots.values.toList(growable: false),
      entitySnapshots: _entitySnapshots.values.toList(growable: false),
      migrationReceipts: _migrationReceipts,
      metadata: _metadata,
      schemaVersion: _schemaVersion,
    );
  }

  @override
  VibeUpdateReceipt seedSubjectStateFromOnboarding({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    Map<String, double> dimensionConfidence = const <String, double>{},
    List<String> provenanceTags = const <String>[],
  }) {
    final now = DateTime.now().toUtc();
    final snapshot = _buildSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      dimensionConfidence: dimensionConfidence,
      provenanceTags: provenanceTags,
      updatedAtUtc: now,
    );
    _subjectSnapshots[_subjectKey(subjectRef)] = snapshot;
    _exportedAtUtc = now;
    _appendMutation(
      category: 'seed_from_onboarding',
      subjectRef: subjectRef,
      snapshot: snapshot,
      evidenceSummary: 'Seeded canonical vibe state from onboarding.',
    );
    return VibeUpdateReceipt(
      subjectId: subjectRef.subjectId,
      accepted: true,
      reasonCodes: const <String>[],
      updatedAtUtc: now,
      snapshot: snapshot,
    );
  }

  @override
  VibeUpdateReceipt seedUserStateFromOnboarding({
    required String subjectId,
    required Map<String, double> dimensions,
    Map<String, double> dimensionConfidence = const <String, double>{},
    List<String> provenanceTags = const <String>[],
  }) {
    return seedSubjectStateFromOnboarding(
      subjectRef: VibeSubjectRef.personal(subjectId),
      dimensions: dimensions,
      dimensionConfidence: dimensionConfidence,
      provenanceTags: provenanceTags,
    );
  }

  @override
  VibeUpdateReceipt ingestBehaviorObservation({
    required String subjectId,
    required Map<String, double> behaviorSignals,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
    List<String> provenanceTags = const <String>[],
  }) {
    final subjectRef = VibeSubjectRef(subjectId: subjectId, kind: subjectKind);
    final now = DateTime.now().toUtc();
    final existing = getSnapshot(subjectRef);
    final updatedPatternWeights = <String, double>{
      ...existing.behaviorPatterns.patternWeights,
    };
    final updatedPheromones = <String, double>{...existing.pheromones.vectors};
    for (final entry in behaviorSignals.entries) {
      updatedPatternWeights[entry.key] =
          (updatedPatternWeights[entry.key] ?? 0.0) + entry.value;
      updatedPheromones[entry.key] =
          ((updatedPheromones[entry.key] ?? 0.0) + entry.value)
              .clamp(-1.0, 1.0);
    }
    final snapshot = _buildSnapshot(
      subjectRef: subjectRef,
      dimensions: existing.coreDna.dimensions,
      dimensionConfidence: existing.coreDna.dimensionConfidence,
      pheromones: updatedPheromones,
      patternWeights: updatedPatternWeights,
      observationCount: existing.behaviorPatterns.observationCount + 1,
      provenanceTags: <String>[
        ...existing.provenanceTags,
        ...provenanceTags,
      ],
      updatedAtUtc: now,
    );
    _subjectSnapshots[_subjectKey(subjectRef)] = snapshot;
    _exportedAtUtc = now;
    _appendMutation(
      category: 'behavior_observation',
      subjectRef: subjectRef,
      snapshot: snapshot,
      evidenceSummary: 'Behavior observation applied.',
    );
    return VibeUpdateReceipt(
      subjectId: subjectId,
      accepted: true,
      reasonCodes: const <String>[],
      updatedAtUtc: now,
      snapshot: snapshot,
    );
  }

  @override
  VibeUpdateReceipt ingestEcosystemObservation({
    required String subjectId,
    required String source,
    required Map<String, double> dimensions,
    VibeSubjectKind subjectKind = VibeSubjectKind.personalAgent,
    List<String> provenanceTags = const <String>[],
  }) {
    final subjectRef = VibeSubjectRef(subjectId: subjectId, kind: subjectKind);
    final now = DateTime.now().toUtc();
    final existing = getSnapshot(subjectRef);
    final snapshot = _buildSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      dimensionConfidence: existing.coreDna.dimensionConfidence,
      pheromones: existing.pheromones.vectors,
      patternWeights: existing.behaviorPatterns.patternWeights,
      observationCount: existing.behaviorPatterns.observationCount,
      provenanceTags: <String>[
        ...existing.provenanceTags,
        source,
        ...provenanceTags,
      ],
      updatedAtUtc: now,
    );
    _subjectSnapshots[_subjectKey(subjectRef)] = snapshot;
    _exportedAtUtc = now;
    _appendMutation(
      category: 'ecosystem_observation',
      subjectRef: subjectRef,
      snapshot: snapshot,
      evidenceSummary: 'Ecosystem observation from $source.',
    );
    return VibeUpdateReceipt(
      subjectId: subjectId,
      accepted: true,
      reasonCodes: const <String>[],
      updatedAtUtc: now,
      snapshot: snapshot,
    );
  }

  @override
  VibeUpdateReceipt ingestEntityObservation({
    required String entityId,
    required String entityType,
    required Map<String, double> dimensions,
    List<String> provenanceTags = const <String>[],
  }) {
    final subjectRef = VibeSubjectRef.entity(
      entityId: entityId,
      entityType: entityType,
    );
    final now = DateTime.now().toUtc();
    final snapshot = _buildSnapshot(
      subjectRef: subjectRef,
      dimensions: dimensions,
      provenanceTags: provenanceTags,
      updatedAtUtc: now,
    );
    final entitySnapshot = EntityVibeSnapshot(
      entityId: entityId,
      entityType: entityType,
      vibe: snapshot,
    );
    _entitySnapshots[_entityKey(entityId, entityType)] = entitySnapshot;
    _exportedAtUtc = now;
    _appendMutation(
      category: 'entity_observation',
      subjectRef: subjectRef,
      snapshot: snapshot,
      evidenceSummary: 'Entity vibe synchronized for $entityType.',
    );
    return VibeUpdateReceipt(
      subjectId: entityId,
      accepted: true,
      reasonCodes: const <String>[],
      updatedAtUtc: now,
      snapshot: snapshot,
    );
  }

  @override
  VibeStateSnapshot getSnapshot(VibeSubjectRef subjectRef) {
    return _subjectSnapshots[_subjectKey(subjectRef)] ??
        _buildSnapshot(subjectRef: subjectRef);
  }

  @override
  VibeStateSnapshot getUserSnapshot(String subjectId) {
    return getSnapshot(VibeSubjectRef.personal(subjectId));
  }

  @override
  EntityVibeSnapshot getEntitySnapshot({
    required String entityId,
    String entityType = 'entity',
  }) {
    return _entitySnapshots[_entityKey(entityId, entityType)] ??
        EntityVibeSnapshot(
          entityId: entityId,
          entityType: entityType,
          vibe: _buildSnapshot(
            subjectRef: VibeSubjectRef.entity(
              entityId: entityId,
              entityType: entityType,
            ),
          ),
        );
  }

  VibeStateSnapshot _buildSnapshot({
    required VibeSubjectRef subjectRef,
    Map<String, double> dimensions = const <String, double>{},
    Map<String, double> dimensionConfidence = const <String, double>{},
    Map<String, double> pheromones = const <String, double>{},
    Map<String, double> patternWeights = const <String, double>{},
    int observationCount = 0,
    List<String> provenanceTags = const <String>[],
    DateTime? updatedAtUtc,
  }) {
    final now = (updatedAtUtc ?? DateTime.now()).toUtc();
    final normalizedDimensions = <String, double>{
      for (final dimension in VibeConstants.coreDimensions)
        dimension: dimensions[dimension] ?? VibeConstants.defaultDimensionValue,
    };
    final normalizedConfidence = <String, double>{
      for (final dimension in VibeConstants.coreDimensions)
        dimension: dimensionConfidence[dimension] ?? 0.5,
    };
    return VibeStateSnapshot(
      subjectId: subjectRef.subjectId,
      subjectKind: subjectRef.kind.toWireValue(),
      coreDna: CoreDnaState(
        dimensions: normalizedDimensions,
        dimensionConfidence: normalizedConfidence,
        driftBudgetRemaining: 0.3,
      ),
      quantumVibe: const QuantumVibeState(
        amplitudes: <String, double>{},
        phaseAlignment: 0.5,
        coherence: 0.5,
      ),
      pheromones: PheromoneState(
        vectors: Map<String, double>.from(pheromones),
        decayRate: 0.08,
        lastDecayAtUtc: now,
      ),
      behaviorPatterns: BehaviorPatternState(
        patternWeights: Map<String, double>.from(patternWeights),
        observationCount: observationCount,
        cadenceHours: observationCount > 0 ? 1.0 : 0.0,
      ),
      affectiveState: const AffectiveState(
        valence: 0.0,
        arousal: 0.0,
        dominance: 0.0,
        label: 'neutral',
        confidence: 0.5,
      ),
      knotInvariants: const KnotInvariantState(
        crossingNumber: 0.0,
        tension: 0.0,
        symmetry: 0.0,
      ),
      worldsheet: const WorldsheetState(
        temporalPhase: 0.0,
        momentum: 0.0,
        curvature: 0.0,
      ),
      stringEvolution: const StringEvolutionState(
        coupling: 0.0,
        mutationVelocity: 0.0,
        harmonics: <String, double>{},
      ),
      decoherenceState: const DecoherenceState(
        noise: 0.0,
        stability: 1.0,
        decoherence: 0.0,
      ),
      expressionContext: const VibeExpressionContext(
        toneProfile: 'clear_calm',
        pacingProfile: 'steady',
        uncertaintyProfile: 'explicit',
        socialCadence: 0.5,
        energy: 0.5,
        directness: 0.5,
      ),
      confidence: 0.85,
      freshnessHours: 0.0,
      provenanceTags: List<String>.from(provenanceTags),
      updatedAtUtc: now,
    );
  }

  void _appendMutation({
    required String category,
    required VibeSubjectRef subjectRef,
    required VibeStateSnapshot snapshot,
    required String evidenceSummary,
  }) {
    _trajectoryKernel.appendMutation(
      record: TrajectoryMutationRecord(
        recordId:
            '$category:${subjectRef.subjectId}:${snapshot.updatedAtUtc.microsecondsSinceEpoch}',
        subjectRef: subjectRef,
        category: category,
        occurredAtUtc: snapshot.updatedAtUtc,
        evidenceSummary: evidenceSummary,
        snapshotUpdatedAtUtc: snapshot.updatedAtUtc,
        metadata: <String, dynamic>{
          'subject_kind': subjectRef.kind.toWireValue(),
        },
      ),
      checkpointSnapshot: snapshot,
    );
  }

  String _subjectKey(VibeSubjectRef subjectRef) {
    return '${subjectRef.kind.toWireValue()}:${subjectRef.subjectId}';
  }

  String _entityKey(String entityId, String entityType) {
    return '$entityType:$entityId';
  }
}
