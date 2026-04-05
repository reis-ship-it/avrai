import 'dart:convert';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class GovernedDomainConsumerState {
  const GovernedDomainConsumerState({
    required this.sourceId,
    required this.domainId,
    required this.consumerId,
    required this.environmentId,
    required this.generatedAt,
    required this.status,
    required this.summary,
    required this.boundedUse,
    required this.targetedSystems,
    this.cityCode,
    this.learningOutcomeJsonPath,
    this.requestCount = 0,
    this.recommendationCount = 0,
    this.averageConfidence,
    this.jsonPath,
    this.sourceCreatedAt,
    this.sourceUpdatedAt,
    this.sourceLastSyncedAt,
    this.originOccurredAt,
    this.localStateCapturedAt,
    this.reviewQueuedAt,
    this.reviewResolvedAt,
    this.learningQueuedAt,
    this.learningIntegratedAt,
    this.propagationPreparedAt,
    this.propagationResolvedAt,
    this.artifactGeneratedAt,
    this.kernelExchangePhase,
  });

  final String sourceId;
  final String domainId;
  final String consumerId;
  final String environmentId;
  final DateTime generatedAt;
  final String status;
  final String summary;
  final String boundedUse;
  final List<String> targetedSystems;
  final String? cityCode;
  final String? learningOutcomeJsonPath;
  final int requestCount;
  final int recommendationCount;
  final double? averageConfidence;
  final String? jsonPath;
  final DateTime? sourceCreatedAt;
  final DateTime? sourceUpdatedAt;
  final DateTime? sourceLastSyncedAt;
  final DateTime? originOccurredAt;
  final DateTime? localStateCapturedAt;
  final DateTime? reviewQueuedAt;
  final DateTime? reviewResolvedAt;
  final DateTime? learningQueuedAt;
  final DateTime? learningIntegratedAt;
  final DateTime? propagationPreparedAt;
  final DateTime? propagationResolvedAt;
  final DateTime? artifactGeneratedAt;
  final String? kernelExchangePhase;

  DateTime get effectiveBehaviorAt =>
      localStateCapturedAt ??
      learningIntegratedAt ??
      propagationResolvedAt ??
      artifactGeneratedAt ??
      generatedAt;

  double temporalFreshnessWeight({DateTime? now}) {
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    final reference = effectiveBehaviorAt.toUtc();
    final age = effectiveNow.difference(reference);
    if (age <= Duration.zero) {
      return 1.0;
    }
    const fullWeightWindow = Duration(hours: 6);
    const firstDecayWindow = Duration(days: 7);
    const maxAgeWindow = Duration(days: 30);
    if (age <= fullWeightWindow) {
      return 1.0;
    }
    if (age <= firstDecayWindow) {
      final progress = (age - fullWeightWindow).inMilliseconds /
          (firstDecayWindow - fullWeightWindow).inMilliseconds;
      return (1.0 - (progress * 0.25)).clamp(0.0, 1.0);
    }
    if (age <= maxAgeWindow) {
      final progress = (age - firstDecayWindow).inMilliseconds /
          (maxAgeWindow - firstDecayWindow).inMilliseconds;
      return (0.75 - (progress * 0.75)).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  bool get isLiveBehaviorUsable => temporalFreshnessWeight() > 0.0;

  String get storageKey =>
      '${environmentId.trim()}|${(cityCode ?? '').trim()}|${domainId.trim()}|${consumerId.trim()}';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceId': sourceId,
      'domainId': domainId,
      'consumerId': consumerId,
      'environmentId': environmentId,
      'cityCode': cityCode,
      'generatedAt': generatedAt.toIso8601String(),
      'status': status,
      'summary': summary,
      'boundedUse': boundedUse,
      'targetedSystems': targetedSystems,
      'learningOutcomeJsonPath': learningOutcomeJsonPath,
      'requestCount': requestCount,
      'recommendationCount': recommendationCount,
      'averageConfidence': averageConfidence,
      'jsonPath': jsonPath,
      'sourceCreatedAt': sourceCreatedAt?.toIso8601String(),
      'sourceUpdatedAt': sourceUpdatedAt?.toIso8601String(),
      'sourceLastSyncedAt': sourceLastSyncedAt?.toIso8601String(),
      'originOccurredAt': originOccurredAt?.toIso8601String(),
      'localStateCapturedAt': localStateCapturedAt?.toIso8601String(),
      'reviewQueuedAt': reviewQueuedAt?.toIso8601String(),
      'reviewResolvedAt': reviewResolvedAt?.toIso8601String(),
      'learningQueuedAt': learningQueuedAt?.toIso8601String(),
      'learningIntegratedAt': learningIntegratedAt?.toIso8601String(),
      'propagationPreparedAt': propagationPreparedAt?.toIso8601String(),
      'propagationResolvedAt': propagationResolvedAt?.toIso8601String(),
      'artifactGeneratedAt': artifactGeneratedAt?.toIso8601String(),
      'kernelExchangePhase': kernelExchangePhase,
    };
  }

  static GovernedDomainConsumerState? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final payload = Map<String, dynamic>.from(raw);
    final generatedAtRaw = payload['generatedAt']?.toString();
    return GovernedDomainConsumerState(
      sourceId: payload['sourceId']?.toString() ?? 'unknown_source',
      domainId: payload['domainId']?.toString() ?? 'unknown_domain',
      consumerId: payload['consumerId']?.toString() ?? 'unknown_consumer',
      environmentId:
          payload['environmentId']?.toString() ?? 'unknown_environment',
      cityCode: payload['cityCode']?.toString(),
      generatedAt: DateTime.tryParse(generatedAtRaw ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: payload['status']?.toString() ?? 'unknown',
      summary: payload['summary']?.toString() ?? '',
      boundedUse: payload['boundedUse']?.toString() ?? '',
      targetedSystems: List<String>.from(
        payload['targetedSystems'] ?? const <String>[],
      ),
      learningOutcomeJsonPath: payload['learningOutcomeJsonPath']?.toString(),
      requestCount: (payload['requestCount'] as num?)?.toInt() ?? 0,
      recommendationCount:
          (payload['recommendationCount'] as num?)?.toInt() ?? 0,
      averageConfidence: (payload['averageConfidence'] as num?)?.toDouble(),
      jsonPath: payload['jsonPath']?.toString(),
      sourceCreatedAt: _parseDate(payload['sourceCreatedAt']),
      sourceUpdatedAt: _parseDate(payload['sourceUpdatedAt']),
      sourceLastSyncedAt: _parseDate(payload['sourceLastSyncedAt']),
      originOccurredAt: _parseDate(payload['originOccurredAt']),
      localStateCapturedAt: _parseDate(payload['localStateCapturedAt']),
      reviewQueuedAt: _parseDate(payload['reviewQueuedAt']),
      reviewResolvedAt: _parseDate(payload['reviewResolvedAt']),
      learningQueuedAt: _parseDate(payload['learningQueuedAt']),
      learningIntegratedAt: _parseDate(payload['learningIntegratedAt']),
      propagationPreparedAt: _parseDate(payload['propagationPreparedAt']),
      propagationResolvedAt: _parseDate(payload['propagationResolvedAt']),
      artifactGeneratedAt: _parseDate(payload['artifactGeneratedAt']),
      kernelExchangePhase: payload['kernelExchangePhase']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString())?.toUtc();
  }
}

class GovernedDomainConsumerStateService {
  static const String _storageKey = 'governed_domain_consumer_states_v1';

  final StorageService _storageService;

  GovernedDomainConsumerStateService({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService.instance;

  Future<void> upsertState(GovernedDomainConsumerState state) async {
    final statesByKey = _readStateMap();
    statesByKey[state.storageKey] = state.toJson();
    await _storageService.setString(
      _storageKey,
      const JsonEncoder().convert(statesByKey),
    );
  }

  List<GovernedDomainConsumerState> getAllStates() {
    final states = _readStateMap()
        .values
        .map(GovernedDomainConsumerState.fromJson)
        .whereType<GovernedDomainConsumerState>()
        .toList(growable: false);
    states
        .sort((a, b) => b.effectiveBehaviorAt.compareTo(a.effectiveBehaviorAt));
    return states;
  }

  List<GovernedDomainConsumerState> getStates({
    String? cityCode,
    String? environmentId,
    String? domainId,
  }) {
    return getAllStates().where((state) {
      if (cityCode != null &&
          cityCode.isNotEmpty &&
          state.cityCode != cityCode) {
        return false;
      }
      if (environmentId != null &&
          environmentId.isNotEmpty &&
          state.environmentId != environmentId) {
        return false;
      }
      if (domainId != null &&
          domainId.isNotEmpty &&
          state.domainId != domainId) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  GovernedDomainConsumerState? latestStateFor({
    String? cityCode,
    String? environmentId,
    required String domainId,
  }) {
    final states = getStates(
      cityCode: cityCode,
      environmentId: environmentId,
      domainId: domainId,
    );
    return states.isEmpty ? null : states.first;
  }

  GovernedDomainConsumerState? latestLiveStateFor({
    String? cityCode,
    String? environmentId,
    required String domainId,
    DateTime? now,
  }) {
    final states = getStates(
      cityCode: cityCode,
      environmentId: environmentId,
      domainId: domainId,
    ).where((state) => state.temporalFreshnessWeight(now: now) > 0.0).toList(
          growable: false,
        );
    return states.isEmpty ? null : states.first;
  }

  Map<String, dynamic> _readStateMap() {
    final raw = _storageService.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(decoded);
  }
}
