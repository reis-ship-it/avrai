import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:reality_engine/reality_engine.dart';

class ScopedContextVibeProjector {
  ScopedContextVibeProjector({
    VibeKernel? vibeKernel,
    GovernanceKernelService? governanceKernel,
  })  : _vibeKernel = vibeKernel ?? VibeKernel(),
        _governanceKernel = governanceKernel ?? GovernanceKernelService();

  final VibeKernel _vibeKernel;
  final GovernanceKernelService _governanceKernel;

  List<ScopedVibeBinding> buildBindings({
    GeographicVibeBinding? geographicBinding,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final bindings = <ScopedVibeBinding>[
      ..._explicitBindings(
        geographicBinding: geographicBinding,
        metadata: metadata,
      ),
      ..._sceneBindings(
        geographicBinding: geographicBinding,
        metadata: metadata,
      ),
    ];
    final deduped = <String, ScopedVibeBinding>{};
    for (final binding in bindings) {
      deduped['${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}'] =
          binding;
    }
    return deduped.values.toList(growable: false);
  }

  List<VibeUpdateReceipt> projectScopedObservation({
    required List<ScopedVibeBinding> bindings,
    required Map<String, double> dimensions,
    required String source,
    List<String> provenanceTags = const <String>[],
  }) {
    final receipts = <VibeUpdateReceipt>[];
    for (final binding in bindings) {
      final mutationDecision = _governanceKernel.authorizeVibeMutation(
        subjectId: binding.contextRef.subjectId,
        governanceScope: 'scoped:${binding.scopedKind.toWireValue()}',
        evidence: _dimensionsToEvidence(
          binding: binding,
          dimensions: dimensions,
          source: source,
          provenanceTags: provenanceTags,
        ),
      );
      if (!mutationDecision.stateWriteAllowed) {
        continue;
      }
      receipts.add(
        _vibeKernel.ingestEcosystemObservation(
          subjectId: binding.contextRef.subjectId,
          subjectKind: binding.contextRef.kind,
          source: source,
          dimensions: dimensions,
          provenanceTags: <String>[
            source,
            'scoped:${binding.scopedKind.toWireValue()}',
            ...provenanceTags,
          ],
        ),
      );
    }
    return receipts;
  }

  List<ScopedVibeBinding> _explicitBindings({
    required GeographicVibeBinding? geographicBinding,
    required Map<String, dynamic> metadata,
  }) {
    final anchor = geographicBinding?.localityRef;
    final bindings = <ScopedVibeBinding>[];
    void addBinding({
      required ScopedAgentKind kind,
      required String? rawId,
      String? label,
    }) {
      final scopedId = rawId?.trim();
      if (scopedId == null || scopedId.isEmpty) {
        return;
      }
      bindings.add(
        ScopedVibeBinding(
          contextRef: VibeSubjectRef.scoped(
            scopedId: scopedId,
            scopedKind: kind,
            displayLabel: label,
          ),
          scopedKind: kind,
          anchorGeographicRef: anchor,
          metadata: <String, dynamic>{
            if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
          },
        ),
      );
    }

    addBinding(
      kind: ScopedAgentKind.university,
      rawId: _readString(metadata, 'university_id') ??
          _readString(metadata, 'university_slug'),
      label: _readString(metadata, 'university_name'),
    );
    addBinding(
      kind: ScopedAgentKind.campus,
      rawId: _readString(metadata, 'campus_id') ??
          _readString(metadata, 'campus_slug'),
      label: _readString(metadata, 'campus_name'),
    );
    addBinding(
      kind: ScopedAgentKind.organization,
      rawId: _readString(metadata, 'organization_id') ??
          _readString(metadata, 'host_organization_id'),
      label: _readString(metadata, 'organization_name') ??
          _readString(metadata, 'host_organization_name'),
    );
    return bindings;
  }

  List<ScopedVibeBinding> _sceneBindings({
    required GeographicVibeBinding? geographicBinding,
    required Map<String, dynamic> metadata,
  }) {
    final anchor = geographicBinding?.localityRef;
    if (anchor == null) {
      return const <ScopedVibeBinding>[];
    }

    final sceneLabels = <String>{
      ..._readStringList(metadata, 'scene_labels'),
      ..._readStringList(metadata, 'language_scene_refs'),
      ..._readStringList(metadata, 'scene_tags'),
      if ((_readString(metadata, 'scene_label') ?? '').trim().isNotEmpty)
        _readString(metadata, 'scene_label')!.trim(),
    };

    final eventClusterScore =
        _readDouble(metadata, 'scene_event_cluster_score') ??
            _readDouble(metadata, 'event_cluster_score') ??
            _countAsScore(_readStringList(metadata, 'categories'));
    final venueOverlapScore =
        _readDouble(metadata, 'scene_venue_overlap_score') ??
            _readDouble(metadata, 'venue_overlap_score') ??
            _countAsScore(_readStringList(metadata, 'venue_ids'));
    final languageScore = _readDouble(metadata, 'scene_language_score') ??
        (sceneLabels.isEmpty ? 0.0 : 1.0);
    final ai2aiScore = _readDouble(metadata, 'scene_ai2ai_score') ??
        _readDouble(metadata, 'ai2ai_scene_votes') ??
        0.0;
    final adminSeeded = metadata['admin_seed_scene'] == true ||
        metadata['scene_admin_seeded'] == true;

    final activeFamilies = <String>{
      if (eventClusterScore >= 1.0) 'event_cluster',
      if (venueOverlapScore >= 1.0) 'venue_overlap',
      if (languageScore >= 1.0) 'language',
      if (ai2aiScore >= 1.0) 'ai2ai',
      if (adminSeeded) 'admin_seed',
    };
    if (activeFamilies.length < 2 && !adminSeeded) {
      return const <ScopedVibeBinding>[];
    }
    if (sceneLabels.isEmpty) {
      return const <ScopedVibeBinding>[];
    }

    return sceneLabels
        .map(
          (label) => ScopedVibeBinding(
            contextRef: VibeSubjectRef.scoped(
              scopedId: _sceneId(label, anchor.subjectId),
              scopedKind: ScopedAgentKind.scene,
              displayLabel: label,
            ),
            scopedKind: ScopedAgentKind.scene,
            anchorGeographicRef: anchor,
            metadata: <String, dynamic>{
              'scene_label': label,
              'evidence_families': activeFamilies.toList()..sort(),
              'admin_seeded': adminSeeded,
            },
          ),
        )
        .toList(growable: false);
  }

  VibeEvidence _dimensionsToEvidence({
    required ScopedVibeBinding binding,
    required Map<String, double> dimensions,
    required String source,
    required List<String> provenanceTags,
  }) {
    return VibeEvidence(
      summary:
          'Governed scoped observation for ${binding.contextRef.subjectId} from $source.',
      identitySignals: dimensions.entries
          .map(
            (entry) => VibeSignal(
              key: entry.key,
              kind: VibeSignalKind.identity,
              value: entry.value,
              confidence: 0.7,
              provenance: <String>[
                source,
                binding.scopedKind.toWireValue(),
                ...provenanceTags,
              ],
            ),
          )
          .toList(growable: false),
      pheromoneSignals: const <VibeSignal>[],
      behaviorSignals: const <VibeSignal>[],
      affectiveSignals: const <VibeSignal>[],
      styleSignals: const <VibeSignal>[],
    );
  }

  String? _readString(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    if (value == null) {
      return null;
    }
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  List<String> _readStringList(Map<String, dynamic> metadata, String key) {
    final raw = metadata[key];
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  double? _readDouble(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  double _countAsScore(List<String> values) => values.isEmpty ? 0.0 : 1.0;

  String _sceneId(String label, String anchorId) {
    final slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'scene:${anchorId.split(':').last}:$slug';
  }
}
