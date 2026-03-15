import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:reality_engine/reality_engine.dart';

class CanonicalPeerCompatibilityResult {
  const CanonicalPeerCompatibilityResult({
    required this.basicCompatibility,
    required this.geographicAffinity,
    required this.scopedAffinity,
    required this.confidence,
    this.sharedScopedContextIds = const <String>[],
    this.sharedGeographicLevels = const <String>[],
    this.reasonCodes = const <String>[],
  });

  final double basicCompatibility;
  final double geographicAffinity;
  final double scopedAffinity;
  final double confidence;
  final List<String> sharedScopedContextIds;
  final List<String> sharedGeographicLevels;
  final List<String> reasonCodes;
}

class CanonicalPeerResolutionService {
  CanonicalPeerResolutionService({
    VibeKernel? vibeKernel,
    GovernanceKernelService? governanceKernelService,
  })  : _vibeKernel = vibeKernel ?? VibeKernel(),
        _governanceKernelService =
            governanceKernelService ?? GovernanceKernelService();

  static const Duration _maxPeerPayloadAge = Duration(days: 7);
  static const List<String> _compatibilityDimensions = <String>[
    'exploration_eagerness',
    'community_orientation',
    'authenticity_preference',
    'temporal_flexibility',
    'energy_preference',
    'novelty_seeking',
    'value_orientation',
    'crowd_tolerance',
  ];

  final VibeKernel _vibeKernel;
  final GovernanceKernelService _governanceKernelService;

  Ai2AiCanonicalPeerPayload buildLocalPayload({
    required PersonalityProfile localPersonality,
  }) {
    final snapshot = _vibeKernel.getUserSnapshot(localPersonality.agentId);
    final stack = _vibeKernel.getHierarchicalStack(
      subjectRef: VibeSubjectRef.personal(localPersonality.agentId),
    );
    final scopedBindings = _activeScopedBindings(stack.scopedBindings);
    final confidence = snapshot.confidence.clamp(0.0, 1.0);
    return Ai2AiCanonicalPeerPayload(
      reference: Ai2AiVibeReference(
        subjectRef: VibeSubjectRef.personal(localPersonality.agentId),
        scope: 'personal',
        confidence: confidence,
        geographicBinding: stack.geographicBinding,
        scopedBindings: scopedBindings,
        snapshotUpdatedAtUtc: snapshot.updatedAtUtc,
        metadata: <String, dynamic>{
          'subject_kind': snapshot.subjectKind,
          'canonical_peer_payload': true,
        },
      ),
      personalSurface: _surfaceFromSnapshot(snapshot),
      geographicBinding: stack.geographicBinding,
      scopedBindings: scopedBindings,
      freshnessHours: snapshot.freshnessHours,
      confidence: confidence,
      generatedAtUtc: DateTime.now().toUtc(),
      metadata: const <String, dynamic>{
        'session_only': true,
        'persistence_allowed': false,
      },
    );
  }

  ResolvedPeerVibeContext? resolveInboundPayload({
    required String localAgentId,
    required Ai2AiCanonicalPeerPayload remotePayload,
  }) {
    if (!_isValidPayload(remotePayload)) {
      return null;
    }
    final governanceMetadata = _governanceKernelService.inspectGovernance(
      scope: 'ai2ai_peer_payload',
      subjectId: localAgentId,
      metadata: <String, dynamic>{
        'remote_scope': remotePayload.reference.scope,
        'remote_subject_kind':
            remotePayload.reference.subjectRef.kind.canonicalKind.toWireValue(),
        'freshness_hours': remotePayload.freshnessHours,
        'confidence': remotePayload.confidence,
        'scoped_kinds': remotePayload.scopedBindings
            .map((entry) => entry.scopedKind.toWireValue())
            .toList(growable: false),
      },
    );
    return ResolvedPeerVibeContext(
      reference: remotePayload.reference,
      personalSurface: remotePayload.personalSurface,
      geographicBinding: remotePayload.geographicBinding,
      scopedBindings: _activeScopedBindings(remotePayload.scopedBindings),
      freshnessHours: remotePayload.freshnessHours,
      confidence: remotePayload.confidence.clamp(0.0, 1.0),
      resolvedAtUtc: DateTime.now().toUtc(),
      governanceMetadata: governanceMetadata,
      metadata: <String, dynamic>{
        'session_only': true,
        'persistence_allowed': false,
        'canonical_peer_payload_hash': _payloadHash(remotePayload),
      },
    );
  }

  ResolvedPeerVibeContext? resolveLegacyPersonalityProfile({
    required String localAgentId,
    required PersonalityProfile remoteProfile,
    GeographicVibeBinding? geographicBinding,
    List<ScopedVibeBinding> scopedBindings = const <ScopedVibeBinding>[],
  }) {
    final confidence = _profileConfidence(remoteProfile).clamp(0.2, 0.8);
    final freshnessHours = DateTime.now()
        .toUtc()
        .difference(remoteProfile.lastUpdated.toUtc())
        .inMinutes /
        60.0;
    final payload = Ai2AiCanonicalPeerPayload(
      reference: Ai2AiVibeReference(
        subjectRef: VibeSubjectRef.personal(remoteProfile.agentId),
        scope: 'personal',
        confidence: confidence,
        geographicBinding: geographicBinding,
        scopedBindings: _activeScopedBindings(scopedBindings),
        snapshotUpdatedAtUtc: remoteProfile.lastUpdated.toUtc(),
        metadata: const <String, dynamic>{
          'degraded_legacy_profile': true,
          'compatibility_only': true,
        },
      ),
      personalSurface: _surfaceFromPersonalityProfile(remoteProfile),
      geographicBinding: geographicBinding,
      scopedBindings: _activeScopedBindings(scopedBindings),
      freshnessHours: freshnessHours,
      confidence: confidence,
      generatedAtUtc: DateTime.now().toUtc(),
      metadata: const <String, dynamic>{
        'session_only': true,
        'persistence_allowed': false,
        'degraded_legacy_profile': true,
      },
    );
    final resolved = resolveInboundPayload(
      localAgentId: localAgentId,
      remotePayload: payload,
    );
    if (resolved == null) {
      return null;
    }
    return ResolvedPeerVibeContext(
      reference: resolved.reference,
      personalSurface: resolved.personalSurface,
      geographicBinding: resolved.geographicBinding,
      scopedBindings: resolved.scopedBindings,
      freshnessHours: resolved.freshnessHours,
      confidence: resolved.confidence,
      resolvedAtUtc: resolved.resolvedAtUtc,
      governanceMetadata: resolved.governanceMetadata,
      metadata: <String, dynamic>{
        ...resolved.metadata,
        'legacy_personality_exchange': true,
      },
    );
  }

  CanonicalPeerCompatibilityResult computeCompatibility({
    required Ai2AiCanonicalPeerPayload localPayload,
    required ResolvedPeerVibeContext remoteContext,
  }) {
    final localSurface = localPayload.personalSurface;
    final remoteSurface = remoteContext.personalSurface;

    final dimensionSimilarity = _averageSimilarity(
      _compatibilityDimensions.map(
        (dimension) => _similarity(
          localSurface.dimensionWindow[dimension] ?? 0.5,
          remoteSurface.dimensionWindow[dimension] ?? 0.5,
        ),
      ),
    );
    final energySimilarity =
        _similarity(localSurface.energy, remoteSurface.energy);
    final socialSimilarity =
        _similarity(localSurface.socialCadence, remoteSurface.socialCadence);
    final directnessSimilarity =
        _similarity(localSurface.directness, remoteSurface.directness);
    final geographicAffinity = _geographicAffinity(
      localPayload.geographicBinding,
      remoteContext.geographicBinding,
    );
    final scopedAffinity = _scopedAffinity(
      localPayload.scopedBindings,
      remoteContext.scopedBindings,
    );
    final freshnessFactor =
        (1.0 - (remoteContext.freshnessHours.clamp(0.0, 168.0) / 336.0))
            .clamp(0.5, 1.0);
    final confidence =
        ((localPayload.confidence + remoteContext.confidence) / 2.0)
            .clamp(0.0, 1.0);
    final confidenceFactor = (0.7 + confidence * 0.3).clamp(0.7, 1.0);

    final basicCompatibility = ((dimensionSimilarity * 0.58) +
                (energySimilarity * 0.12) +
                (socialSimilarity * 0.10) +
                (directnessSimilarity * 0.07) +
                (geographicAffinity * 0.08) +
                (scopedAffinity * 0.05))
            .clamp(0.0, 1.0) *
        freshnessFactor *
        confidenceFactor;

    return CanonicalPeerCompatibilityResult(
      basicCompatibility: basicCompatibility.clamp(0.0, 1.0),
      geographicAffinity: geographicAffinity,
      scopedAffinity: scopedAffinity,
      confidence: confidence,
      sharedScopedContextIds: _sharedScopedContextIds(
        localPayload.scopedBindings,
        remoteContext.scopedBindings,
      ),
      sharedGeographicLevels: _sharedGeographicLevels(
        localPayload.geographicBinding,
        remoteContext.geographicBinding,
      ),
      reasonCodes: <String>[
        if (geographicAffinity >= 0.75) 'shared_geography',
        if (scopedAffinity >= 0.6) 'shared_scoped_context',
        if (dimensionSimilarity >= 0.7) 'personal_surface_alignment',
      ],
    );
  }

  VibeCompatibilityResult toLegacyCompatibilityResult(
    CanonicalPeerCompatibilityResult result, {
    required Ai2AiCanonicalPeerPayload localPayload,
    required ResolvedPeerVibeContext remoteContext,
  }) {
    final basicCompatibility = result.basicCompatibility.clamp(0.0, 1.0);
    final aiPleasurePotential = ((basicCompatibility * 0.8) +
            (result.scopedAffinity * 0.10) +
            (result.geographicAffinity * 0.10))
        .clamp(0.0, 1.0);
    final connectionStrength =
        ((basicCompatibility + result.confidence) / 2.0).clamp(0.0, 1.0);
    final trustBuildingPotential = ((basicCompatibility * 0.6) +
            (result.geographicAffinity * 0.2) +
            (result.scopedAffinity * 0.2))
        .clamp(0.0, 1.0);
    final learningOpportunities = _learningOpportunities(
      localPayload.personalSurface,
      remoteContext.personalSurface,
      result,
    );

    return VibeCompatibilityResult(
      basicCompatibility: basicCompatibility,
      aiPleasurePotential: aiPleasurePotential,
      learningOpportunities: learningOpportunities,
      connectionStrength: connectionStrength,
      interactionStyle: _interactionStyle(basicCompatibility),
      trustBuildingPotential: trustBuildingPotential,
      recommendedConnectionDuration: _recommendedDuration(basicCompatibility),
      connectionPriority: _connectionPriority(basicCompatibility),
    );
  }

  Map<String, dynamic> compatibilityMetadata(
    CanonicalPeerCompatibilityResult result, {
    required ResolvedPeerVibeContext remoteContext,
  }) {
    return <String, dynamic>{
      'canonical_reason_codes': result.reasonCodes,
      'peer_confidence': remoteContext.confidence,
      'peer_freshness_hours': remoteContext.freshnessHours,
      'shared_geographic_levels': result.sharedGeographicLevels,
      'shared_scoped_context_ids': result.sharedScopedContextIds,
      'legacy_profile_compatibility_only':
          remoteContext.metadata['legacy_personality_exchange'] == true,
    };
  }

  WhySnapshot buildPeerCompatibilityWhySnapshot({
    required Ai2AiCanonicalPeerPayload localPayload,
    required ResolvedPeerVibeContext remoteContext,
    required CanonicalPeerCompatibilityResult result,
  }) {
    final drivers = <WhySignal>[
      WhySignal(
        label: 'personal_surface_alignment',
        weight: result.basicCompatibility.clamp(0.0, 1.0),
        source: 'canonical_peer_resolution',
        confidence: result.confidence,
        kernel: WhyEvidenceSourceKernel.who,
      ),
      if (result.sharedGeographicLevels.isNotEmpty)
        WhySignal(
          label: 'shared_geography:${result.sharedGeographicLevels.join("|")}',
          weight: result.geographicAffinity.clamp(0.0, 1.0),
          source: 'canonical_peer_resolution',
          confidence: remoteContext.confidence,
          kernel: WhyEvidenceSourceKernel.where,
        ),
      if (result.sharedScopedContextIds.isNotEmpty)
        WhySignal(
          label: 'shared_scoped_context:${result.sharedScopedContextIds.first}',
          weight: result.scopedAffinity.clamp(0.0, 1.0),
          source: 'canonical_peer_resolution',
          confidence: remoteContext.confidence,
          kernel: WhyEvidenceSourceKernel.what,
        ),
    ];
    final inhibitors = <WhySignal>[
      if (remoteContext.freshnessHours > 24)
        WhySignal(
          label: 'peer_context_staleness',
          weight:
              (remoteContext.freshnessHours.clamp(24.0, 168.0) / 168.0)
                  .clamp(0.0, 1.0),
          source: 'canonical_peer_resolution',
          confidence: remoteContext.confidence,
          kernel: WhyEvidenceSourceKernel.when,
        ),
      if (remoteContext.metadata['legacy_personality_exchange'] == true)
        WhySignal(
          label: 'legacy_profile_compatibility_only',
          weight: 0.35,
          source: 'canonical_peer_resolution',
          confidence: remoteContext.confidence,
          kernel: WhyEvidenceSourceKernel.policy,
        ),
    ];

    final summaryParts = <String>[
      if (result.reasonCodes.contains('personal_surface_alignment'))
        'personal vibe alignment is strong',
      if (result.sharedGeographicLevels.isNotEmpty)
        'you share ${result.sharedGeographicLevels.join(", ")} context',
      if (result.sharedScopedContextIds.isNotEmpty)
        'you overlap on scoped context',
    ];
    final summary = summaryParts
        .where((entry) => entry.isNotEmpty)
        .join('; ')
        .trim();

    return WhySnapshot(
      goal: 'Explain peer compatibility for ${remoteContext.reference.subjectRef.subjectId}',
      queryKind: WhyQueryKind.observedOutcome,
      drivers: drivers,
      inhibitors: inhibitors,
      confidence: result.confidence,
      rootCauseType: result.sharedGeographicLevels.isNotEmpty
          ? WhyRootCauseType.locality
          : WhyRootCauseType.traitDriven,
      summary: summary.isEmpty
          ? 'Peer compatibility is grounded in canonical personal context.'
          : '${summary[0].toUpperCase()}${summary.substring(1)}.',
      counterfactuals: const <WhyCounterfactual>[],
      traceRefs: <WhyTraceRef>[
        WhyTraceRef(
          traceType: 'peer_subject',
          kernel: WhyEvidenceSourceKernel.who,
          entityId: remoteContext.reference.subjectRef.subjectId,
        ),
        WhyTraceRef(
          traceType: 'local_subject',
          kernel: WhyEvidenceSourceKernel.who,
          entityId: localPayload.reference.subjectRef.subjectId,
        ),
      ],
    );
  }

  UserVibe synthesizeUserVibe(CanonicalPeerCompatibilitySurface surface) {
    final now = DateTime.now().toUtc();
    return UserVibe(
      hashedSignature: surface.signatureHash,
      anonymizedDimensions: Map<String, double>.from(surface.dimensionWindow),
      overallEnergy: surface.energy.clamp(0.0, 1.0),
      socialPreference: surface.socialCadence.clamp(0.0, 1.0),
      explorationTendency:
          (surface.dimensionWindow['exploration_eagerness'] ?? 0.5)
              .clamp(0.0, 1.0),
      createdAt: now,
      expiresAt: now.add(
        const Duration(days: VibeConstants.vibeSignatureExpiryDays),
      ),
      privacyLevel: 1.0,
      temporalContext: 'canonical_peer_session',
    );
  }

  List<ScopedVibeBinding> _activeScopedBindings(
    List<ScopedVibeBinding> bindings,
  ) {
    final seen = <String>{};
    final filtered = <ScopedVibeBinding>[];
    for (final binding in bindings) {
      if (binding.scopedKind == ScopedAgentKind.communityNetwork) {
        continue;
      }
      final key =
          '${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}';
      if (seen.add(key)) {
        filtered.add(binding);
      }
    }
    return filtered;
  }

  CanonicalPeerCompatibilitySurface _surfaceFromSnapshot(
    VibeStateSnapshot snapshot,
  ) {
    final dimensionWindow = <String, double>{
      for (final dimension in _compatibilityDimensions)
        dimension: (snapshot.coreDna.dimensions[dimension] ??
                snapshot.pheromones.vectors[dimension] ??
                VibeConstants.defaultDimensionValue)
            .clamp(0.0, 1.0),
    };
    final energy = snapshot.expressionContext.energy.clamp(0.0, 1.0);
    final socialCadence =
        snapshot.expressionContext.socialCadence.clamp(0.0, 1.0);
    final directness = snapshot.expressionContext.directness.clamp(0.0, 1.0);
    final signatureSeed = <Object?>[
      for (final entry
          in dimensionWindow.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)))
        '${entry.key}:${entry.value.toStringAsFixed(3)}',
      energy.toStringAsFixed(3),
      socialCadence.toStringAsFixed(3),
      directness.toStringAsFixed(3),
      snapshot.updatedAtUtc.toIso8601String(),
    ].join('|');

    return CanonicalPeerCompatibilitySurface(
      signatureHash: sha256.convert(utf8.encode(signatureSeed)).toString(),
      archetype: _archetypeFromSurface(
        dimensionWindow: dimensionWindow,
        energy: energy,
        socialCadence: socialCadence,
      ),
      dimensionWindow: dimensionWindow,
      energy: energy,
      socialCadence: socialCadence,
      directness: directness,
      confidence: snapshot.confidence.clamp(0.0, 1.0),
      metadata: <String, dynamic>{
        'subject_kind': snapshot.subjectKind,
      },
    );
  }

  CanonicalPeerCompatibilitySurface _surfaceFromPersonalityProfile(
    PersonalityProfile profile,
  ) {
    final dimensionWindow = <String, double>{
      for (final dimension in _compatibilityDimensions)
        dimension: (profile.dimensions[dimension] ??
                profile.corePersonality[dimension] ??
                VibeConstants.defaultDimensionValue)
            .clamp(0.0, 1.0),
    };
    final energy = (dimensionWindow['energy_preference'] ?? 0.5).clamp(0.0, 1.0);
    final socialCadence =
        (dimensionWindow['community_orientation'] ?? 0.5).clamp(0.0, 1.0);
    final directness =
        (dimensionWindow['authenticity_preference'] ?? 0.5).clamp(0.0, 1.0);
    final signatureSeed = <Object?>[
      profile.agentId,
      for (final entry
          in dimensionWindow.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)))
        '${entry.key}:${entry.value.toStringAsFixed(3)}',
      profile.lastUpdated.toIso8601String(),
    ].join('|');

    return CanonicalPeerCompatibilitySurface(
      signatureHash: sha256.convert(utf8.encode(signatureSeed)).toString(),
      archetype: profile.archetype,
      dimensionWindow: dimensionWindow,
      energy: energy,
      socialCadence: socialCadence,
      directness: directness,
      confidence: _profileConfidence(profile),
      metadata: const <String, dynamic>{
        'legacy_profile_compatibility_only': true,
      },
    );
  }

  double _profileConfidence(PersonalityProfile profile) {
    if (profile.dimensionConfidence.isEmpty) {
      return 0.5;
    }
    final total = profile.dimensionConfidence.values
        .fold<double>(0.0, (sum, value) => sum + value.clamp(0.0, 1.0));
    return (total / profile.dimensionConfidence.length).clamp(0.0, 1.0);
  }

  bool _isValidPayload(Ai2AiCanonicalPeerPayload payload) {
    if (payload.reference.subjectRef.kind.canonicalKind !=
        VibeSubjectKind.personalAgent) {
      return false;
    }
    if (payload.reference.scope != 'personal') {
      return false;
    }
    if (payload.confidence.isNaN ||
        payload.confidence.isInfinite ||
        payload.confidence < 0.0 ||
        payload.confidence > 1.0) {
      return false;
    }
    if (payload.freshnessHours.isNaN ||
        payload.freshnessHours.isInfinite ||
        payload.freshnessHours < 0.0) {
      return false;
    }
    final generatedAge =
        DateTime.now().toUtc().difference(payload.generatedAtUtc);
    if (generatedAge > _maxPeerPayloadAge) {
      return false;
    }
    final snapshotAge = payload.reference.snapshotUpdatedAtUtc == null
        ? Duration.zero
        : DateTime.now()
            .toUtc()
            .difference(payload.reference.snapshotUpdatedAtUtc!.toUtc());
    if (snapshotAge > _maxPeerPayloadAge) {
      return false;
    }
    if (payload.personalSurface.signatureHash.trim().isEmpty) {
      return false;
    }
    for (final value in payload.personalSurface.dimensionWindow.values) {
      if (value.isNaN || value.isInfinite || value < 0.0 || value > 1.0) {
        return false;
      }
    }
    if (payload.scopedBindings.any(
      (binding) => binding.scopedKind == ScopedAgentKind.communityNetwork,
    )) {
      return false;
    }
    return true;
  }

  String _payloadHash(Ai2AiCanonicalPeerPayload payload) {
    return sha256.convert(utf8.encode(jsonEncode(payload.toJson()))).toString();
  }

  double _geographicAffinity(
    GeographicVibeBinding? localBinding,
    GeographicVibeBinding? remoteBinding,
  ) {
    if (localBinding == null || remoteBinding == null) {
      return 0.45;
    }
    if (localBinding.stableKey == remoteBinding.stableKey) {
      return 1.0;
    }
    if (localBinding.districtCode != null &&
        localBinding.districtCode == remoteBinding.districtCode) {
      return 0.95;
    }
    if (localBinding.cityCode != null &&
        localBinding.cityCode == remoteBinding.cityCode) {
      return 0.88;
    }
    if (localBinding.regionCode != null &&
        localBinding.regionCode == remoteBinding.regionCode) {
      return 0.76;
    }
    if (localBinding.countryCode != null &&
        localBinding.countryCode == remoteBinding.countryCode) {
      return 0.66;
    }
    if (localBinding.globalCode != null &&
        localBinding.globalCode == remoteBinding.globalCode) {
      return 0.58;
    }
    return 0.35;
  }

  double _scopedAffinity(
    List<ScopedVibeBinding> localBindings,
    List<ScopedVibeBinding> remoteBindings,
  ) {
    final localIds = localBindings
        .map((binding) =>
            '${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}')
        .toSet();
    final remoteIds = remoteBindings
        .map((binding) =>
            '${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}')
        .toSet();
    if (localIds.isEmpty || remoteIds.isEmpty) {
      return 0.0;
    }
    final intersection = localIds.intersection(remoteIds).length.toDouble();
    final denominator = localIds.union(remoteIds).length.toDouble();
    if (denominator == 0.0) {
      return 0.0;
    }
    return (intersection / denominator).clamp(0.0, 1.0);
  }

  List<String> _sharedScopedContextIds(
    List<ScopedVibeBinding> localBindings,
    List<ScopedVibeBinding> remoteBindings,
  ) {
    final localIds = localBindings
        .map((binding) =>
            '${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}')
        .toSet();
    final remoteIds = remoteBindings
        .map((binding) =>
            '${binding.scopedKind.toWireValue()}:${binding.contextRef.subjectId}')
        .toSet();
    return localIds.intersection(remoteIds).toList()..sort();
  }

  List<String> _sharedGeographicLevels(
    GeographicVibeBinding? localBinding,
    GeographicVibeBinding? remoteBinding,
  ) {
    if (localBinding == null || remoteBinding == null) {
      return const <String>[];
    }
    final levels = <String>[];
    if (localBinding.stableKey == remoteBinding.stableKey) {
      levels.add('locality');
    }
    if (localBinding.districtCode != null &&
        localBinding.districtCode == remoteBinding.districtCode) {
      levels.add('district');
    }
    if (localBinding.cityCode != null &&
        localBinding.cityCode == remoteBinding.cityCode) {
      levels.add('city');
    }
    if (localBinding.regionCode != null &&
        localBinding.regionCode == remoteBinding.regionCode) {
      levels.add('region');
    }
    if (localBinding.countryCode != null &&
        localBinding.countryCode == remoteBinding.countryCode) {
      levels.add('country');
    }
    if (localBinding.globalCode != null &&
        localBinding.globalCode == remoteBinding.globalCode) {
      levels.add('global');
    }
    return levels;
  }

  String _archetypeFromSurface({
    required Map<String, double> dimensionWindow,
    required double energy,
    required double socialCadence,
  }) {
    final exploration = dimensionWindow['exploration_eagerness'] ?? 0.5;
    final community = dimensionWindow['community_orientation'] ?? 0.5;
    if (exploration >= 0.78 && energy >= 0.72) {
      return 'adventurous_explorer';
    }
    if (community >= 0.78 && socialCadence >= 0.68) {
      return 'social_connector';
    }
    if (community >= 0.72 && exploration <= 0.35) {
      return 'community_curator';
    }
    if (exploration >= 0.72 && socialCadence <= 0.4) {
      return 'authentic_seeker';
    }
    if (energy >= 0.82) {
      return 'spontaneous_wanderer';
    }
    return 'balanced_explorer';
  }

  List<LearningOpportunity> _learningOpportunities(
    CanonicalPeerCompatibilitySurface localSurface,
    CanonicalPeerCompatibilitySurface remoteSurface,
    CanonicalPeerCompatibilityResult result,
  ) {
    final opportunities = <LearningOpportunity>[
      for (final scopedId in result.sharedScopedContextIds.take(2))
        LearningOpportunity(
          dimension: scopedId,
          learningPotential:
              (0.55 + result.scopedAffinity * 0.35).clamp(0.0, 1.0),
          learningType: LearningType.discovery,
        ),
    ];

    final rankedDimensions = _compatibilityDimensions.map((dimension) {
      final localValue = localSurface.dimensionWindow[dimension] ?? 0.5;
      final remoteValue = remoteSurface.dimensionWindow[dimension] ?? 0.5;
      return MapEntry(dimension, (localValue - remoteValue).abs());
    }).toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    for (final entry in rankedDimensions.take(2)) {
      if (entry.value < 0.12) {
        continue;
      }
      opportunities.add(
        LearningOpportunity(
          dimension: entry.key,
          learningPotential: (0.45 + entry.value).clamp(0.0, 1.0),
          learningType: entry.value >= 0.3
              ? LearningType.expansion
              : LearningType.refinement,
        ),
      );
    }

    if (opportunities.isEmpty &&
        result.basicCompatibility >=
            VibeConstants.minimumCompatibilityThreshold) {
      opportunities.add(
        LearningOpportunity(
          dimension: 'personal_surface_alignment',
          learningPotential:
              (0.4 + result.basicCompatibility * 0.4).clamp(0.0, 1.0),
          learningType: LearningType.refinement,
        ),
      );
    }

    return opportunities;
  }

  AI2AIInteractionStyle _interactionStyle(double compatibility) {
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return AI2AIInteractionStyle.deepLearning;
    }
    if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return AI2AIInteractionStyle.moderateLearning;
    }
    if (compatibility >= VibeConstants.lowCompatibilityThreshold) {
      return AI2AIInteractionStyle.focusedExchange;
    }
    return AI2AIInteractionStyle.lightInteraction;
  }

  Duration _recommendedDuration(double compatibility) {
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return const Duration(seconds: 300);
    }
    if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return const Duration(seconds: 180);
    }
    if (compatibility >= VibeConstants.lowCompatibilityThreshold) {
      return const Duration(seconds: 90);
    }
    return const Duration(seconds: VibeConstants.minInteractionDurationSeconds);
  }

  ConnectionPriority _connectionPriority(double compatibility) {
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return ConnectionPriority.high;
    }
    if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return ConnectionPriority.medium;
    }
    if (compatibility >= VibeConstants.lowCompatibilityThreshold) {
      return ConnectionPriority.low;
    }
    return ConnectionPriority.minimal;
  }

  double _averageSimilarity(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0.0;
    }
    final total = list.fold<double>(0.0, (sum, value) => sum + value);
    return (total / list.length).clamp(0.0, 1.0);
  }

  double _similarity(double left, double right) {
    return (1.0 - (left - right).abs()).clamp(0.0, 1.0);
  }
}
