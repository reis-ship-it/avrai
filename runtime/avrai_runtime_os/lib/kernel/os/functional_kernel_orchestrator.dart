import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart'
    as spatial_where;
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_bundle_store.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart' as semantic_what;
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';
import 'package:avrai_runtime_os/services/vibe/scoped_context_vibe_projector.dart';
import 'package:reality_engine/reality_engine.dart';

class FunctionalKernelOrchestrator implements FunctionalKernelOs {
  FunctionalKernelOrchestrator({
    required this.whoKernel,
    required this.whatKernel,
    required this.whenKernel,
    required this.spatialWhereKernel,
    required this.howKernel,
    required this.whyKernel,
    VibeKernel? vibeKernel,
    this.bundleStore,
  }) : vibeKernel = vibeKernel ?? VibeKernel();

  final WhoKernelContract whoKernel;
  final WhatKernelContract whatKernel;
  final WhenKernelContract whenKernel;
  final spatial_where.WhereKernelContract spatialWhereKernel;
  final HowKernelContract howKernel;
  final WhyKernelContract whyKernel;
  final VibeKernel vibeKernel;
  final KernelBundleStore? bundleStore;
  final ScopedContextVibeProjector _scopedContextVibeProjector =
      ScopedContextVibeProjector();

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    return whyKernel.explainWhy(request);
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) {
    return howKernel.resolveHow(envelope);
  }

  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) async {
    final semanticState = await whatKernel.resolveWhat(
      semantic_what.WhatPerceptionInput(
        agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
        observedAtUtc: envelope.occurredAtUtc,
        source: envelope.sourceSystem ?? 'functional_kernel_orchestrator',
        entityRef: envelope.entityId ?? envelope.eventId,
        candidateLabels: <String>[
          if (envelope.entityType != null) envelope.entityType!,
          if (envelope.eventType != null) envelope.eventType!,
          if (envelope.actionType != null) envelope.actionType!,
        ],
        socialContextHint: envelope.context['social_context'] as String?,
        activityHint: envelope.actionType,
        structuredMetadata: <String, dynamic>{
          'context': envelope.context,
          'predictionContext': envelope.predictionContext,
          'policyContext': envelope.policyContext,
          'runtimeContext': envelope.runtimeContext,
        },
        lineageRef: envelope.eventId,
      ),
    );
    return WhatKernelSnapshot(
      actionType: envelope.actionType ?? 'unknown_action',
      targetEntityType: semanticState.canonicalType,
      targetEntityId: semanticState.entityRef,
      stateTransitionType: semanticState.lifecycleState.name,
      outcomeType: semanticState.userRelation.name,
      semanticTags: <String>[
        semanticState.placeType,
        ...semanticState.activityTypes,
        ...semanticState.socialContexts,
      ],
      taxonomyConfidence: semanticState.confidence,
    );
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) {
    return whenKernel.resolveWhen(envelope);
  }

  @override
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope) async {
    final localityState = await spatialWhereKernel.resolveWhere(
      WhereKernelInput(
        agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
        latitude: (envelope.context['latitude'] as num?)?.toDouble(),
        longitude: (envelope.context['longitude'] as num?)?.toDouble(),
        occurredAtUtc: envelope.occurredAtUtc,
        topAlias: envelope.context['location_label'] as String?,
      ),
    );
    final projection = spatialWhereKernel.project(
      WhereProjectionRequest(
        audience: WhereProjectionAudience.admin,
        state: localityState,
      ),
    );
    return WhereKernelSnapshot(
      localityToken: localityState.activeToken.id,
      cityCode: _cityCodeFromState(localityState) ?? 'unknown_city',
      localityCode:
          localityState.activeToken.alias ?? localityState.activeToken.id,
      projection: <String, dynamic>{
        'label': projection.primaryLabel,
        'metadata': projection.metadata,
      },
      boundaryTension: localityState.boundaryTension,
      spatialConfidence: localityState.confidence,
      travelFriction: _travelFriction(envelope),
      placeFitFlags: <String>[
        if (projection.nearBoundary) 'boundary_volatile' else 'stable',
        localityState.confidence >= 0.65 ? 'high_confidence' : 'low_confidence',
      ],
    );
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) {
    return whoKernel.resolveWho(envelope);
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(
    KernelEventEnvelope envelope,
  ) async {
    final who = await resolveWho(envelope);
    final what = await resolveWhat(envelope);
    final when = await resolveWhen(envelope);
    final where = await resolveWhere(envelope);
    final how = await resolveHow(envelope);
    final geographicBinding = _buildGeographicVibeBinding(where);
    final scopedBindings = _scopedContextVibeProjector.buildBindings(
      geographicBinding: geographicBinding,
      metadata: _scopedMetadata(envelope),
    );
    final selectedEntityRefs = <VibeSubjectRef>[
      if (envelope.entityId != null)
        VibeSubjectRef.entity(
          entityId: envelope.entityId!,
          entityType: envelope.entityType ?? 'entity',
        ),
    ];
    final vibe = _resolveVibeSnapshot(
      envelope,
      geographicBinding: geographicBinding,
      scopedBindings: scopedBindings,
    );
    final vibeStack = vibeKernel.getHierarchicalStack(
      subjectRef: _primarySubjectRef(envelope),
      geographicBinding: geographicBinding,
      scopedBindings: scopedBindings,
      higherAgentRefs:
          geographicBinding?.higherGeographicRefs ?? const <VibeSubjectRef>[],
      selectedEntityRefs: selectedEntityRefs,
    );
    return KernelContextBundle(
      who: who,
      what: what,
      when: when,
      where: where,
      how: how,
      vibe: vibe,
      vibeStack: vibeStack,
    );
  }

  @override
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    final bundle = await resolveKernelContext(envelope);
    final why = explainWhy(
      KernelWhyRequest(
        bundle: bundle.withoutWhy(),
        goal: whyRequest.goal,
        predictedOutcome: whyRequest.predictedOutcome,
        predictedConfidence: whyRequest.predictedConfidence,
        actualOutcome: whyRequest.actualOutcome,
        actualOutcomeScore: whyRequest.actualOutcomeScore,
        coreSignals: whyRequest.coreSignals,
        pheromoneSignals: whyRequest.pheromoneSignals,
        policySignals: whyRequest.policySignals,
        memoryContext: whyRequest.memoryContext,
        severity: whyRequest.severity,
      ),
    );
    final record = KernelBundleRecord(
      recordId:
          '${envelope.eventId}:${why.createdAtUtc.microsecondsSinceEpoch}',
      eventId: envelope.eventId,
      bundle: KernelContextBundle(
        who: bundle.who,
        what: bundle.what,
        when: bundle.when,
        where: bundle.where,
        how: bundle.how,
        vibe: bundle.vibe,
        vibeStack: bundle.vibeStack,
        why: why,
      ),
      createdAtUtc: why.createdAtUtc,
    );
    await bundleStore?.put(record);
    return record;
  }

  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    final record = await resolveAndExplain(
      envelope: envelope,
      whyRequest: whyRequest,
    );
    final bundle = record.bundle;
    final whoProjection = await whoKernel.projectForRealityModel(
      KernelProjectionRequest(
        subjectId: bundle.who?.primaryActor,
        envelope: envelope,
        bundle: bundle.withoutWhy(),
        who: bundle.who,
      ),
    );
    final whatProjection = await whatKernel.projectForRealityModel(
      semantic_what.WhatProjectionRequest(
        agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
        entityRef: bundle.what?.targetEntityId ??
            envelope.entityId ??
            envelope.eventId,
      ),
    );
    final whenProjection = await whenKernel.projectForRealityModel(
      KernelProjectionRequest(
        subjectId: envelope.eventId,
        envelope: envelope,
        bundle: bundle.withoutWhy(),
        when: bundle.when,
      ),
    );
    final whereProjection = await spatialWhereKernel.projectForRealityModel(
      WhereProjectionRequest(
        audience: WhereProjectionAudience.admin,
        state: await spatialWhereKernel.resolveWhere(
          WhereKernelInput(
            agentId: envelope.agentId ?? envelope.userId ?? 'unknown_actor',
            latitude: (envelope.context['latitude'] as num?)?.toDouble(),
            longitude: (envelope.context['longitude'] as num?)?.toDouble(),
            occurredAtUtc: envelope.occurredAtUtc,
            topAlias: envelope.context['location_label'] as String?,
          ),
        ),
      ),
    );
    final whyProjection = await whyKernel.projectForRealityModel(
      KernelProjectionRequest(
        subjectId: whyRequest.goal ?? envelope.eventId,
        envelope: envelope,
        bundle: bundle.withoutWhy(),
        why: bundle.why,
      ),
    );
    final howProjection = await howKernel.projectForRealityModel(
      KernelProjectionRequest(
        subjectId: envelope.eventId,
        envelope: envelope,
        bundle: bundle.withoutWhy(),
        how: bundle.how,
      ),
    );
    final vibeProjection = _projectVibeForReality(bundle.vibe);
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: bundle,
      who: whoProjection,
      what: whatProjection,
      when: whenProjection,
      where: whereProjection,
      why: whyProjection,
      how: howProjection,
      vibe: vibeProjection,
      generatedAtUtc: record.createdAtUtc,
    );
  }

  VibeStateSnapshot _resolveVibeSnapshot(
    KernelEventEnvelope envelope, {
    GeographicVibeBinding? geographicBinding,
    List<ScopedVibeBinding> scopedBindings = const <ScopedVibeBinding>[],
  }) {
    final subjectRef = _primarySubjectRef(envelope);
    final snapshot = vibeKernel.getSnapshot(subjectRef);
    if (envelope.entityId == null) {
      return snapshot;
    }
    return vibeKernel
        .getStateEncoderSnapshot(
          subjectId: subjectRef.subjectId,
          entityId: envelope.entityId,
          entityType: envelope.entityType,
          geographicBinding: geographicBinding,
          scopedBindings: scopedBindings,
        )
        .userSnapshot;
  }

  VibeSubjectRef _primarySubjectRef(KernelEventEnvelope envelope) {
    return VibeSubjectRef.personal(
      envelope.agentId ?? envelope.userId ?? envelope.eventId,
    );
  }

  GeographicVibeBinding? _buildGeographicVibeBinding(
      WhereKernelSnapshot where) {
    final stableKey = where.localityToken.trim();
    if (stableKey.isEmpty || stableKey == 'where:bootstrap') {
      return null;
    }
    final higherAgentRefs = <VibeSubjectRef>[
      if (where.cityCode.trim().isNotEmpty && where.cityCode != 'unknown_city')
        VibeSubjectRef.city(where.cityCode),
      if ((where.projection['region_code'] as String?)?.trim().isNotEmpty ??
          false)
        VibeSubjectRef.region(where.projection['region_code'] as String),
      if ((where.projection['country_code'] as String?)?.trim().isNotEmpty ??
          false)
        VibeSubjectRef.country(where.projection['country_code'] as String),
      if ((where.projection['global_code'] as String?)?.trim().isNotEmpty ??
          false)
        VibeSubjectRef.global(where.projection['global_code'] as String),
      if ((where.projection['top_level_code'] as String?)?.trim().isNotEmpty ??
          false)
        VibeSubjectRef.topLevel(where.projection['top_level_code'] as String),
    ];
    return GeographicVibeBinding(
      localityRef: VibeSubjectRef.locality(stableKey),
      stableKey: stableKey,
      higherGeographicRefs: higherAgentRefs,
      scope: 'locality',
      districtCode: where.projection['district_code'] as String?,
      cityCode: where.cityCode == 'unknown_city' ? null : where.cityCode,
      regionCode: where.projection['region_code'] as String?,
      countryCode: where.projection['country_code'] as String?,
      globalCode: (where.projection['global_code'] ??
          where.projection['top_level_code']) as String?,
      metadata: <String, dynamic>{
        'locality_token': where.localityToken,
        'spatial_confidence': where.spatialConfidence,
      },
    );
  }

  VibeRealityProjection _projectVibeForReality(VibeStateSnapshot? snapshot) {
    if (snapshot == null) {
      return const VibeRealityProjection(
        summary: 'No canonical vibe snapshot available.',
        confidence: 0.0,
      );
    }
    return VibeRealityProjection(
      summary:
          'Canonical vibe snapshot for ${snapshot.subjectId} (${snapshot.subjectKind})',
      confidence: snapshot.confidence,
      features: <String, dynamic>{
        'freshness_hours': snapshot.freshnessHours,
        'provenance_tags': snapshot.provenanceTags,
        'tone_profile': snapshot.expressionContext.toneProfile,
      },
      payload: snapshot.toJson(),
    );
  }

  String? _cityCodeFromState(WhereState state) {
    final parentToken = state.parentToken;
    if (parentToken == null) {
      return null;
    }
    return parentToken.id;
  }

  double _travelFriction(KernelEventEnvelope envelope) {
    return (envelope.context['travel_friction'] as num?)?.toDouble() ?? 0.24;
  }

  Map<String, dynamic> _scopedMetadata(KernelEventEnvelope envelope) {
    return <String, dynamic>{
      ...envelope.context,
      ...envelope.predictionContext,
      ...envelope.policyContext,
      ...envelope.runtimeContext,
      ...envelope.adminProvenance,
      if (envelope.entityId != null) 'entity_id': envelope.entityId,
      if (envelope.entityType != null) 'entity_type': envelope.entityType,
    };
  }
}
