import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:get_it/get_it.dart';
import 'package:reality_engine/reality_engine.dart';

import 'canonical_vibe_signal.dart';
import 'canonical_vibe_runtime_policy.dart';

class CanonicalVibeProjectionService {
  CanonicalVibeProjectionService({
    VibeKernel? vibeKernel,
    AgentIdService? agentIdService,
  })  : _vibeKernel = vibeKernel ?? _resolveVibeKernel(),
        _agentIdService = agentIdService;

  final VibeKernel _vibeKernel;
  final AgentIdService? _agentIdService;

  Future<PersonalityProfile?> projectProfileForUser(String userId) async {
    if (!CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return null;
    }
    final agentId = await _resolveAgentId(userId);
    return projectProfileForAgent(agentId, userId: userId);
  }

  PersonalityProfile? projectProfileForAgent(
    String agentId, {
    String? userId,
  }) {
    if (!CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return null;
    }
    final snapshot = _vibeKernel.getUserSnapshot(agentId);
    if (!hasCanonicalVibeSignal(snapshot)) {
      return null;
    }
    return _profileFromSnapshot(snapshot, userId: userId);
  }

  Future<PersonalityProfile> canonicalizeUserProfile({
    required String userId,
    required PersonalityProfile profile,
  }) async {
    final agentProjected = projectProfileForAgent(
      profile.agentId,
      userId: userId,
    );
    if (agentProjected != null) {
      return agentProjected;
    }
    final projected = await projectProfileForUser(userId);
    if (projected != null) {
      return projected;
    }
    return canonicalizeProfile(profile, userId: userId);
  }

  PersonalityProfile canonicalizeProfile(
    PersonalityProfile profile, {
    String? userId,
  }) {
    return projectProfileForAgent(profile.agentId,
            userId: userId ?? profile.userId) ??
        profile;
  }

  Future<PersonalityProfile> getOrCreateProjectedProfile({
    required String userId,
    required Future<PersonalityProfile?> Function(String userId) loadFallback,
    required Future<PersonalityProfile> Function(String userId) createFallback,
  }) async {
    final projected = await projectProfileForUser(userId);
    if (projected != null) {
      return projected;
    }
    final existing = await loadFallback(userId);
    if (existing != null) {
      return canonicalizeProfile(existing, userId: userId);
    }
    final created = await createFallback(userId);
    return canonicalizeProfile(created, userId: userId);
  }

  Future<String> _resolveAgentId(String userId) async {
    if (userId.startsWith('agent_')) {
      return userId;
    }
    final agentIdService = _agentIdService ?? _tryResolveAgentIdService();
    if (agentIdService == null) {
      return userId;
    }
    return agentIdService.getUserAgentId(userId);
  }

  PersonalityProfile _profileFromSnapshot(
    VibeStateSnapshot snapshot, {
    String? userId,
  }) {
    final dimensions = _dimensionsFromSnapshot(snapshot);
    final confidence = snapshot.coreDna.dimensionConfidence.isEmpty
        ? <String, double>{
            for (final dimension in VibeConstants.coreDimensions)
              dimension: snapshot.confidence.clamp(0.0, 1.0),
          }
        : Map<String, double>.from(snapshot.coreDna.dimensionConfidence);
    return PersonalityProfile(
      agentId: snapshot.subjectId,
      userId: userId,
      dimensions: dimensions,
      dimensionConfidence: confidence,
      archetype: 'canonical_vibe_projection',
      authenticity: snapshot.affectiveState.valence.clamp(0.0, 1.0),
      createdAt: snapshot.updatedAtUtc,
      lastUpdated: snapshot.updatedAtUtc,
      evolutionGeneration: snapshot.behaviorPatterns.observationCount + 1,
      learningHistory: <String, dynamic>{
        'canonical_subject_kind': snapshot.subjectKind,
        'canonical_provenance_tags': snapshot.provenanceTags,
        'canonical_freshness_hours': snapshot.freshnessHours,
      },
      corePersonality: Map<String, double>.from(snapshot.coreDna.dimensions),
    );
  }

  Map<String, double> _dimensionsFromSnapshot(VibeStateSnapshot snapshot) {
    final dimensions = Map<String, double>.from(snapshot.coreDna.dimensions);
    for (final dimension in VibeConstants.coreDimensions) {
      dimensions.putIfAbsent(
        dimension,
        () => snapshot.pheromones.vectors[dimension] ?? 0.5,
      );
    }
    return dimensions;
  }

  static VibeKernel _resolveVibeKernel() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<VibeKernel>()) {
        return sl<VibeKernel>();
      }
    } catch (_) {}
    return VibeKernel();
  }

  AgentIdService? _tryResolveAgentIdService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        return sl<AgentIdService>();
      }
    } catch (_) {}
    return null;
  }
}
