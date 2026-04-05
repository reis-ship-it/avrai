import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:get_it/get_it.dart';

class RecommendationFeedbackEvent {
  final String userId;
  final DiscoveryEntityReference entity;
  final RecommendationFeedbackAction action;
  final DateTime occurredAtUtc;
  final String sourceSurface;
  final RecommendationAttribution? attribution;
  final Map<String, dynamic> metadata;

  const RecommendationFeedbackEvent({
    required this.userId,
    required this.entity,
    required this.action,
    required this.occurredAtUtc,
    required this.sourceSurface,
    this.attribution,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'entity': entity.toJson(),
      'action': action.name,
      'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      'sourceSurface': sourceSurface,
      'attribution': attribution?.toJson(),
      'metadata': metadata,
    };
  }

  factory RecommendationFeedbackEvent.fromJson(Map<String, dynamic> json) {
    return RecommendationFeedbackEvent(
      userId: json['userId'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      action: RecommendationFeedbackAction.values.firstWhere(
        (value) => value.name == json['action'],
        orElse: () => RecommendationFeedbackAction.opened,
      ),
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      attribution: json['attribution'] is Map
          ? RecommendationAttribution.fromJson(
              Map<String, dynamic>.from(json['attribution'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class RecommendationFeedbackService {
  static const String _storageKeyPrefix = 'bham:recommendation_feedback:v1:';

  final SharedPreferencesCompat? _prefs;
  final KernelOutcomeAttributionLane? _kernelLane;
  final EntitySignatureService? _entitySignatureService;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final RecommendationFeedbackPromptPlannerService _promptPlannerService;

  RecommendationFeedbackService({
    SharedPreferencesCompat? prefs,
    KernelOutcomeAttributionLane? kernelLane,
    EntitySignatureService? entitySignatureService,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    RecommendationFeedbackPromptPlannerService? promptPlannerService,
  })  : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _kernelLane = kernelLane ??
            (GetIt.instance.isRegistered<KernelOutcomeAttributionLane>()
                ? GetIt.instance<KernelOutcomeAttributionLane>()
                : null),
        _entitySignatureService = entitySignatureService ??
            (GetIt.instance.isRegistered<EntitySignatureService>()
                ? GetIt.instance<EntitySignatureService>()
                : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _promptPlannerService = promptPlannerService ??
            RecommendationFeedbackPromptPlannerService(
              prefs: prefs ??
                  (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                      ? GetIt.instance<SharedPreferencesCompat>()
                      : null),
            );

  Future<void> submitFeedback({
    required String userId,
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    required String sourceSurface,
    RecommendationAttribution? attribution,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final event = RecommendationFeedbackEvent(
      userId: userId,
      entity: entity,
      action: action,
      occurredAtUtc: DateTime.now().toUtc(),
      sourceSurface: sourceSurface,
      attribution: attribution,
      metadata: metadata,
    );

    final events = await listEvents(userId);
    await _prefs?.setString(
      _storageKey(userId),
      jsonEncode(
        <Map<String, dynamic>>[
          ...events.map((existing) => existing.toJson()),
          event.toJson(),
        ],
      ),
    );

    if (action == RecommendationFeedbackAction.dismiss ||
        action == RecommendationFeedbackAction.lessLikeThis) {
      await _entitySignatureService?.recordNegativePreferenceSignal(
        userId: userId,
        title: entity.title,
        subtitle: _preferredAttributionContext(attribution) ?? sourceSurface,
        category: entity.type.name,
        tags: <String>[
          entity.type.name,
          sourceSurface,
          if ((attribution?.recommendationSource ?? '').isNotEmpty)
            attribution!.recommendationSource,
        ],
        intent: action == RecommendationFeedbackAction.lessLikeThis
            ? NegativePreferenceIntent.hardNotInterested
            : NegativePreferenceIntent.softIgnore,
        entityType: entity.type.name,
      );
    }

    await _kernelLane?.recordDiscoveryInteraction(
      userId: userId,
      entity: entity,
      action: action,
      attribution: attribution,
      sourceSurface: sourceSurface,
      metadata: metadata,
    );

    await _stageUpwardLearningBestEffort(event);
    await _planPromptBestEffort(event);
  }

  Future<List<RecommendationFeedbackEvent>> listEvents(String userId) async {
    final raw = _prefs?.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) {
      return const <RecommendationFeedbackEvent>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <RecommendationFeedbackEvent>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => RecommendationFeedbackEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.occurredAtUtc.compareTo(a.occurredAtUtc));
    } catch (_) {
      return const <RecommendationFeedbackEvent>[];
    }
  }

  Future<void> clearAll(String userId) async {
    await _prefs?.remove(_storageKey(userId));
  }

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';

  Future<void> _stageUpwardLearningBestEffort(
    RecommendationFeedbackEvent event,
  ) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'recommendation_feedback_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'action': event.action.name,
          'entity': event.entity.toJson(),
          'sourceSurface': event.sourceSurface,
          'attribution': event.attribution?.toJson(),
          'metadata': event.metadata,
        },
      );
      await service.stageRecommendationFeedbackIntake(
        ownerUserId: event.userId,
        action: event.action,
        entity: event.entity,
        occurredAtUtc: event.occurredAtUtc,
        sourceSurface: event.sourceSurface,
        airGapArtifact: airGapArtifact,
        attribution: event.attribution,
        metadata: event.metadata,
      );
    } catch (_) {
      // Best-effort only. Feedback storage must not fail if upward staging is unavailable.
    }
  }

  Future<void> _planPromptBestEffort(RecommendationFeedbackEvent event) async {
    try {
      await _promptPlannerService.createPlan(
        ownerUserId: event.userId,
        entity: event.entity,
        action: event.action,
        occurredAtUtc: event.occurredAtUtc,
        sourceSurface: event.sourceSurface,
        attribution: event.attribution,
        metadata: event.metadata,
      );
    } catch (_) {
      // Best-effort only. Feedback storage must not fail if prompt planning is unavailable.
    }
  }

  String? _preferredAttributionContext(RecommendationAttribution? attribution) {
    if (attribution == null) {
      return null;
    }
    final headline = attribution.why.trim();
    final details = (attribution.whyDetails ?? '').trim();
    if (_isEvidenceBackedExplanation(headline)) {
      return headline;
    }
    if (details.isNotEmpty) {
      return details;
    }
    return headline.isEmpty ? null : headline;
  }

  bool _isEvidenceBackedExplanation(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.startsWith('a recent signal that ') ||
        normalized.startsWith('a recent ') &&
            (normalized.contains('boosted this recommendation') ||
                normalized.contains('helped boost this spot'));
  }
}
