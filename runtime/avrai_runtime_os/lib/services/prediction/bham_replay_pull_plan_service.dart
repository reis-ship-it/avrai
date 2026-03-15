import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';

class BhamReplayPullPlanBatch {
  const BhamReplayPullPlanBatch({
    required this.replayYear,
    required this.plans,
    this.notes = const <String>[],
  });

  final int replayYear;
  final List<ReplaySourcePullPlan> plans;
  final List<String> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'replayYear': replayYear,
      'plans': plans.map((plan) => plan.toJson()).toList(),
      'notes': notes,
    };
  }
}

class BhamReplayPullPlanService {
  const BhamReplayPullPlanService();

  BhamReplayPullPlanBatch buildPullPlan({
    required ReplayIngestionManifest manifest,
    BhamReplaySourceRegistry? registry,
  }) {
    final sourceOverrides = <String, ReplaySourceDescriptor>{
      for (final source in registry?.sources ?? const <ReplaySourceDescriptor>[])
        source.sourceName: source,
    };
    final plans = manifest.sourcePlans
        .where((plan) => plan.readiness != ReplayIngestionReadiness.blocked)
        .map(
          (plan) => _buildPlan(
            _overlaySource(plan, sourceOverrides[plan.source.sourceName]),
          ),
        )
        .toList(growable: false);

    return BhamReplayPullPlanBatch(
      replayYear: manifest.replayYear,
      plans: plans,
      notes: <String>[
        'Pull plan is governed from the replay ingestion manifest.',
        'Automated does not mean executed yet; it only means the source has enough metadata for scripted pull attempts.',
      ],
    );
  }

  ReplaySourcePullPlan _buildPlan(ReplayIngestionSourcePlan plan) {
    final metadata = plan.source.metadata;
    final sourceName = plan.source.sourceName;
    final acquisitionMode = _modeFor(plan);
    final endpointRef =
        metadata['endpointRef']?.toString() ?? plan.source.sourceUrl;
    final rawOutputKey = _slugify(sourceName);

    final notes = <String>[
      if (plan.readiness == ReplayIngestionReadiness.pendingReview)
        'Source remains pending review before authoritative ingestion.',
      if (metadata['legalUsageNotes'] != null)
        metadata['legalUsageNotes'].toString(),
      if ((plan.source.ageSafetyNotes ?? '').isNotEmpty) plan.source.ageSafetyNotes!,
    ];

    return ReplaySourcePullPlan(
      sourceName: sourceName,
      replayYear: plan.replayYear,
      acquisitionMode: acquisitionMode,
      rawOutputKey: rawOutputKey,
      sourceUrl: plan.source.sourceUrl,
      endpointRef: endpointRef,
      requiresReview: plan.readiness == ReplayIngestionReadiness.pendingReview,
      notes: notes,
      metadata: <String, dynamic>{
        'sourceType': plan.source.sourceType,
        'accessMethod': plan.source.accessMethod.name,
        'ingestPriority': plan.ingestPriority,
        'normalizationTargetTypes': plan.normalizationTargetTypes,
      },
    );
  }

  ReplayIngestionSourcePlan _overlaySource(
    ReplayIngestionSourcePlan plan,
    ReplaySourceDescriptor? overrideSource,
  ) {
    if (overrideSource == null) {
      return plan;
    }
    return ReplayIngestionSourcePlan(
      source: overrideSource,
      replayYear: plan.replayYear,
      readiness: plan.readiness,
      ingestPriority: plan.ingestPriority,
      normalizationTargetTypes: plan.normalizationTargetTypes,
      dedupeKeys: plan.dedupeKeys,
      notes: plan.notes,
      metadata: plan.metadata,
    );
  }

  ReplaySourceAcquisitionMode _modeFor(ReplayIngestionSourcePlan plan) {
    final metadata = plan.source.metadata;
    final legalStatus = plan.source.legalStatus.toLowerCase();
    if (legalStatus.contains('review')) {
      return ReplaySourceAcquisitionMode.partnerReview;
    }
    if (metadata['apiKeyRequired'] == true) {
      return ReplaySourceAcquisitionMode.apiKeyRequired;
    }
    if (metadata['manualImportRequired'] == true ||
        plan.source.accessMethod == ReplaySourceAccessMethod.manual ||
        plan.source.accessMethod == ReplaySourceAccessMethod.partnerExport ||
        plan.source.sourceUrl == null) {
      return ReplaySourceAcquisitionMode.manualImport;
    }
    return ReplaySourceAcquisitionMode.automated;
  }

  String _slugify(String sourceName) {
    final normalized = sourceName.toLowerCase().replaceAll('&', 'and');
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
