import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
import 'package:get_it/get_it.dart';

class SavedDiscoveryService {
  static const String _storageKeyPrefix = 'bham:saved_discovery:v1:';

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final SavedDiscoveryFollowUpPromptPlannerService _followUpPlannerService;

  SavedDiscoveryService({
    SharedPreferencesCompat? prefs,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    SavedDiscoveryFollowUpPromptPlannerService? followUpPlannerService,
  })  : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _followUpPlannerService = followUpPlannerService ??
            (GetIt.instance
                    .isRegistered<SavedDiscoveryFollowUpPromptPlannerService>()
                ? GetIt.instance<SavedDiscoveryFollowUpPromptPlannerService>()
                : SavedDiscoveryFollowUpPromptPlannerService(
                    prefs: prefs ??
                        (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                            ? GetIt.instance<SharedPreferencesCompat>()
                            : null),
                  ));

  Future<void> save({
    required String userId,
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) async {
    final occurredAtUtc = DateTime.now().toUtc();
    final items = await listAll(userId);
    final next = <SavedDiscoveryEntity>[
      ...items.where(
        (item) =>
            item.entity.type != entity.type || item.entity.id != entity.id,
      ),
      SavedDiscoveryEntity(
        userId: userId,
        entity: entity,
        savedAtUtc: occurredAtUtc,
        sourceSurface: sourceSurface,
        attribution: attribution,
      ),
    ];
    await _writeAll(userId, next);
    await _stageSavedDiscoveryCurationBestEffort(
      ownerUserId: userId,
      entity: entity,
      occurredAtUtc: occurredAtUtc,
      sourceSurface: sourceSurface,
      action: 'save',
      attribution: attribution,
    );
    await _planFollowUpBestEffort(
      ownerUserId: userId,
      entity: entity,
      occurredAtUtc: occurredAtUtc,
      sourceSurface: sourceSurface,
      action: 'save',
      attribution: attribution,
    );
  }

  Future<void> unsave({
    required String userId,
    required DiscoveryEntityReference entity,
  }) async {
    final items = await listAll(userId);
    SavedDiscoveryEntity? removedItem;
    for (final item in items) {
      if (item.entity.type == entity.type && item.entity.id == entity.id) {
        removedItem = item;
        break;
      }
    }
    final next = items.where(
      (item) => item.entity.type != entity.type || item.entity.id != entity.id,
    );
    await _writeAll(userId, next.toList());
    await _stageSavedDiscoveryCurationBestEffort(
      ownerUserId: userId,
      entity: entity,
      occurredAtUtc: DateTime.now().toUtc(),
      sourceSurface: removedItem?.sourceSurface ?? 'saved_discovery',
      action: 'unsave',
      attribution: removedItem?.attribution,
    );
    await _planFollowUpBestEffort(
      ownerUserId: userId,
      entity: entity,
      occurredAtUtc: DateTime.now().toUtc(),
      sourceSurface: removedItem?.sourceSurface ?? 'saved_discovery',
      action: 'unsave',
      attribution: removedItem?.attribution,
    );
  }

  Future<bool> isSaved({
    required String userId,
    required DiscoveryEntityReference entity,
  }) async {
    final items = await listAll(userId);
    return items.any(
      (item) => item.entity.type == entity.type && item.entity.id == entity.id,
    );
  }

  Future<List<SavedDiscoveryEntity>> listSavedByType({
    required String userId,
    required DiscoveryEntityType type,
  }) async {
    final items = await listAll(userId);
    return items.where((item) => item.entity.type == type).toList()
      ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
  }

  Future<List<SavedDiscoveryEntity>> listAll(String userId) async {
    final raw = _prefs?.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) {
      return const <SavedDiscoveryEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedDiscoveryEntity>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedDiscoveryEntity.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    } catch (_) {
      return const <SavedDiscoveryEntity>[];
    }
  }

  Future<void> clearAll(String userId) async {
    await _prefs?.remove(_storageKey(userId));
  }

  Future<void> _writeAll(
    String userId,
    List<SavedDiscoveryEntity> entities,
  ) async {
    await _prefs?.setString(
      _storageKey(userId),
      jsonEncode(entities.map((entity) => entity.toJson()).toList()),
    );
  }

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';

  Future<void> _stageSavedDiscoveryCurationBestEffort({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String action,
    RecommendationAttribution? attribution,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'saved_discovery_curation_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'saved_discovery_curation_intake',
          'action': action,
          'sourceSurface': sourceSurface,
          'entityId': entity.id,
          'entityType': entity.type.name,
          if ((entity.localityLabel?.trim().isNotEmpty ?? false))
            'localityLabel': entity.localityLabel!.trim(),
          if (attribution != null)
            'recommendationSource': attribution.recommendationSource,
        },
      );
      await service.stageSavedDiscoveryCurationIntake(
        ownerUserId: ownerUserId,
        entity: entity,
        occurredAtUtc: occurredAtUtc,
        airGapArtifact: airGapArtifact,
        sourceSurface: sourceSurface,
        action: action,
        attribution: attribution,
      );
    } catch (_) {
      // Best-effort: saved discovery behavior should not fail the primary save path.
    }
  }

  Future<void> _planFollowUpBestEffort({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String action,
    RecommendationAttribution? attribution,
  }) async {
    try {
      await _followUpPlannerService.createPlan(
        ownerUserId: ownerUserId,
        entity: entity,
        action: action,
        occurredAtUtc: occurredAtUtc,
        sourceSurface: sourceSurface,
        attribution: attribution,
      );
    } catch (_) {
      // Best-effort: follow-up planning should not fail primary save/unsave.
    }
  }
}
