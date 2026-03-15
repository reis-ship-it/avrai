import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

class WhereMeshKey {
  final String geohashPrefix;
  final int precision;
  final String? cityCode;

  const WhereMeshKey({
    required this.geohashPrefix,
    required this.precision,
    this.cityCode,
  });

  factory WhereMeshKey.fromLocality(LocalityAgentKeyV1 key) {
    return WhereMeshKey(
      geohashPrefix: key.geohashPrefix,
      precision: key.precision,
      cityCode: key.cityCode,
    );
  }

  LocalityAgentKeyV1 toLocality() {
    return LocalityAgentKeyV1(
      geohashPrefix: geohashPrefix,
      precision: precision,
      cityCode: cityCode,
    );
  }
}

class WhereKernelInput {
  final String agentId;
  final double? latitude;
  final double? longitude;
  final DateTime occurredAtUtc;
  final String? topAlias;
  final String? motionContext;
  final String? meshContext;
  final String? geometryHint;
  final ({double lat, double lon})? knownHomebase;
  final WhereMeshKey? localityKeyHint;

  const WhereKernelInput({
    required this.agentId,
    required this.occurredAtUtc,
    this.latitude,
    this.longitude,
    this.topAlias,
    this.motionContext,
    this.meshContext,
    this.geometryHint,
    this.knownHomebase,
    this.localityKeyHint,
  });

  factory WhereKernelInput.fromLocality(LocalityPerceptionInput input) {
    return WhereKernelInput(
      agentId: input.agentId,
      latitude: input.latitude,
      longitude: input.longitude,
      occurredAtUtc: input.occurredAtUtc,
      topAlias: input.topAlias,
      motionContext: input.motionContext,
      meshContext: input.meshContext,
      geometryHint: input.geometryHint,
      knownHomebase: input.knownHomebase,
      localityKeyHint: input.localityKeyHint == null
          ? null
          : WhereMeshKey.fromLocality(input.localityKeyHint!),
    );
  }

  LocalityPerceptionInput toLocality() {
    return LocalityPerceptionInput(
      agentId: agentId,
      latitude: latitude,
      longitude: longitude,
      occurredAtUtc: occurredAtUtc,
      topAlias: topAlias,
      motionContext: motionContext,
      meshContext: meshContext,
      geometryHint: geometryHint,
      knownHomebase: knownHomebase,
      localityKeyHint: localityKeyHint?.toLocality(),
    );
  }
}

typedef WhereVisit = Visit;
typedef WhereWhyRequest = WhyKernelRequest;

class WhereObservation {
  final String userId;
  final String agentId;
  final String type;
  final WhereMeshKey key;
  final DateTime occurredAtUtc;
  final String source;
  final String? reportedCityCode;
  final String? inferredCityCode;
  final int? dwellMinutes;
  final double? qualityScore;
  final bool? isRepeatVisit;
  final String? topAlias;

  const WhereObservation({
    required this.userId,
    required this.agentId,
    required this.type,
    required this.key,
    required this.occurredAtUtc,
    required this.source,
    this.reportedCityCode,
    this.inferredCityCode,
    this.dwellMinutes,
    this.qualityScore,
    this.isRepeatVisit,
    this.topAlias,
  });

  factory WhereObservation.fromLocality(LocalityObservation observation) {
    return WhereObservation(
      userId: observation.userId,
      agentId: observation.agentId,
      type: observation.type.name,
      key: WhereMeshKey.fromLocality(observation.key),
      occurredAtUtc: observation.occurredAtUtc,
      source: observation.source,
      reportedCityCode: observation.reportedCityCode,
      inferredCityCode: observation.inferredCityCode,
      dwellMinutes: observation.dwellMinutes,
      qualityScore: observation.qualityScore,
      isRepeatVisit: observation.isRepeatVisit,
      topAlias: observation.topAlias,
    );
  }

  LocalityObservation toLocality() {
    return LocalityObservation(
      userId: userId,
      agentId: agentId,
      type: LocalityObservationType.values.firstWhere(
        (value) => value.name == type,
        orElse: () => LocalityObservationType.visitComplete,
      ),
      key: key.toLocality(),
      occurredAtUtc: occurredAtUtc,
      source: source,
      reportedCityCode: reportedCityCode,
      inferredCityCode: inferredCityCode,
      dwellMinutes: dwellMinutes,
      qualityScore: qualityScore,
      isRepeatVisit: isRepeatVisit,
      topAlias: topAlias,
    );
  }
}

class WhereSyncRequest {
  final String agentId;
  final bool allowCloud;
  final bool allowMesh;

  const WhereSyncRequest({
    required this.agentId,
    this.allowCloud = true,
    this.allowMesh = true,
  });

  factory WhereSyncRequest.fromLocality(LocalitySyncRequest request) {
    return WhereSyncRequest(
      agentId: request.agentId,
      allowCloud: request.allowCloud,
      allowMesh: request.allowMesh,
    );
  }

  LocalitySyncRequest toLocality() {
    return LocalitySyncRequest(
      agentId: agentId,
      allowCloud: allowCloud,
      allowMesh: allowMesh,
    );
  }
}

class WherePointQuery {
  final double latitude;
  final double longitude;
  final DateTime occurredAtUtc;
  final String? agentId;
  final String? topAlias;
  final WhereProjectionAudience audience;
  final bool includeGeometry;
  final bool includeAttribution;
  final bool includePrediction;

  const WherePointQuery({
    required this.latitude,
    required this.longitude,
    required this.occurredAtUtc,
    this.agentId,
    this.topAlias,
    this.audience = WhereProjectionAudience.user,
    this.includeGeometry = false,
    this.includeAttribution = false,
    this.includePrediction = false,
  });

  LocalityPointQuery toLocality() {
    return LocalityPointQuery(
      latitude: latitude,
      longitude: longitude,
      occurredAtUtc: occurredAtUtc,
      agentId: agentId,
      topAlias: topAlias,
      audience: LocalityProjectionAudience.values.firstWhere(
        (value) => value.name == audience.name,
        orElse: () => LocalityProjectionAudience.user,
      ),
      includeGeometry: includeGeometry,
      includeAttribution: includeAttribution,
      includePrediction: includePrediction,
    );
  }
}

class WhereRecoveryRequest {
  final String agentId;

  const WhereRecoveryRequest({required this.agentId});

  factory WhereRecoveryRequest.fromLocality(LocalityRecoveryRequest request) {
    return WhereRecoveryRequest(agentId: request.agentId);
  }

  LocalityRecoveryRequest toLocality() {
    return LocalityRecoveryRequest(agentId: agentId);
  }
}
