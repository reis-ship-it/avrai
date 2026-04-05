import 'package:avrai_runtime_os/ai/perpetual_list/models/suggested_list.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';

import 'functional_kernel_models.dart';
import 'functional_kernel_os.dart';

abstract class KernelOutcomeAttributionLane {
  Future<KernelBundleRecord> recordListInteraction({
    required String userId,
    int? userAge,
    required ListInteraction interaction,
    SuggestedList? suggestedList,
  });

  Future<KernelBundleRecord> recordLocalityRecovery({
    required String agentId,
    required LocalityRecoveryRequest request,
    required LocalityRecoveryResult result,
  });

  Future<KernelBundleRecord> recordDiscoveryInteraction({
    required String userId,
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    RecommendationAttribution? attribution,
    required String sourceSurface,
    Map<String, dynamic> metadata,
  });
}

class DefaultKernelOutcomeAttributionLane
    implements KernelOutcomeAttributionLane {
  const DefaultKernelOutcomeAttributionLane({
    required FunctionalKernelOs functionalKernelOs,
  }) : _functionalKernelOs = functionalKernelOs;

  final FunctionalKernelOs _functionalKernelOs;

  @override
  Future<KernelBundleRecord> recordListInteraction({
    required String userId,
    int? userAge,
    required ListInteraction interaction,
    SuggestedList? suggestedList,
  }) {
    final occurredAtUtc = interaction.timestamp.toUtc();
    final actionType = _listActionType(interaction.type);
    final goal = actionType;
    return _functionalKernelOs.resolveAndExplain(
      envelope: KernelEventEnvelope(
        eventId:
            'list:${interaction.listId}:${interaction.type.name}:${occurredAtUtc.microsecondsSinceEpoch}',
        agentId: userId,
        userId: userId,
        occurredAtUtc: occurredAtUtc,
        sourceSystem: 'perpetual_list',
        eventType: 'list_interaction',
        actionType: actionType,
        entityId: interaction.listId,
        entityType: 'suggested_list',
        context: <String, dynamic>{
          'theme': suggestedList?.theme ?? interaction.metadata['theme'],
          'place_ids': {
            ...?suggestedList?.placeIds,
            ...interaction.involvedPlaces.map((place) => place.id),
          }.toList(),
          'trigger_reasons': suggestedList?.triggerReasons ?? const <String>[],
          'interaction_type': interaction.type.name,
          'metadata': interaction.metadata,
        },
        runtimeContext: <String, dynamic>{
          if (userAge != null) 'user_age': userAge,
          if (interaction.duration != null)
            'interaction_duration_ms': interaction.duration!.inMilliseconds,
        },
      ),
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: goal,
        actualOutcome: interaction.type.name,
        actualOutcomeScore: _interactionOutcomeScore(interaction),
        coreSignals: _listCoreSignals(interaction, suggestedList),
        pheromoneSignals: _listPheromoneSignals(interaction),
        memoryContext: <String, dynamic>{
          'list_id': interaction.listId,
          'event_family': 'perpetual_list',
        },
        severity: interaction.isNegative ? 'medium' : 'low',
      ),
    );
  }

  @override
  Future<KernelBundleRecord> recordLocalityRecovery({
    required String agentId,
    required LocalityRecoveryRequest request,
    required LocalityRecoveryResult result,
  }) {
    final occurredAtUtc = DateTime.now().toUtc();
    return _functionalKernelOs.resolveAndExplain(
      envelope: KernelEventEnvelope(
        eventId:
            'incident:locality_recovery:$agentId:${occurredAtUtc.microsecondsSinceEpoch}',
        agentId: agentId,
        occurredAtUtc: occurredAtUtc,
        sourceSystem: 'locality_kernel',
        eventType: 'incident_recovery',
        actionType: 'recover_locality',
        entityId: agentId,
        entityType: 'locality_runtime',
        context: <String, dynamic>{
          'recovered_from_snapshot': result.recoveredFromSnapshot,
          'locality_confidence': result.state.confidence,
          'boundary_tension': result.state.boundaryTension,
          'active_token': result.state.activeToken.id,
        },
        runtimeContext: <String, dynamic>{
          'recovery_agent_id': request.agentId,
        },
      ),
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: 'recover_locality',
        actualOutcome:
            result.recoveredFromSnapshot ? 'recovered' : 'degraded_recovery',
        actualOutcomeScore: result.recoveredFromSnapshot ? 0.8 : 0.45,
        coreSignals: <WhySignal>[
          WhySignal(
            label: result.recoveredFromSnapshot
                ? 'snapshot_recovery_succeeded'
                : 'recovery_without_snapshot',
            weight: result.recoveredFromSnapshot ? 0.72 : -0.28,
            source: 'how',
          ),
          WhySignal(
            label: 'locality_confidence',
            weight: result.state.confidence,
            source: 'where',
          ),
        ],
        pheromoneSignals: <WhySignal>[
          WhySignal(
            label: 'boundary_tension',
            weight: -result.state.boundaryTension,
            source: 'where',
          ),
        ],
        memoryContext: <String, dynamic>{
          'incident_type': 'locality_recovery',
          'active_token': result.state.activeToken.id,
        },
        severity: result.recoveredFromSnapshot ? 'medium' : 'high',
      ),
    );
  }

  @override
  Future<KernelBundleRecord> recordDiscoveryInteraction({
    required String userId,
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    RecommendationAttribution? attribution,
    required String sourceSurface,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final occurredAtUtc = DateTime.now().toUtc();
    final actionType = switch (action) {
      RecommendationFeedbackAction.save => 'save_recommendation',
      RecommendationFeedbackAction.dismiss => 'dismiss_recommendation',
      RecommendationFeedbackAction.moreLikeThis => 'prefer_more_like_this',
      RecommendationFeedbackAction.lessLikeThis => 'prefer_less_like_this',
      RecommendationFeedbackAction.whyDidYouShowThis =>
        'inspect_recommendation',
      RecommendationFeedbackAction.meaningful => 'mark_meaningful',
      RecommendationFeedbackAction.fun => 'mark_fun',
      RecommendationFeedbackAction.opened => 'open_recommendation',
    };
    final outcomeScore = switch (action) {
      RecommendationFeedbackAction.save => 0.86,
      RecommendationFeedbackAction.moreLikeThis => 0.78,
      RecommendationFeedbackAction.meaningful => 0.84,
      RecommendationFeedbackAction.fun => 0.8,
      RecommendationFeedbackAction.opened => 0.66,
      RecommendationFeedbackAction.whyDidYouShowThis => 0.5,
      RecommendationFeedbackAction.dismiss => 0.18,
      RecommendationFeedbackAction.lessLikeThis => 0.12,
    };

    return _functionalKernelOs.resolveAndExplain(
      envelope: KernelEventEnvelope(
        eventId:
            'discovery:${entity.type.name}:${entity.id}:${action.name}:${occurredAtUtc.microsecondsSinceEpoch}',
        agentId: userId,
        userId: userId,
        occurredAtUtc: occurredAtUtc,
        sourceSystem: sourceSurface,
        eventType: 'discovery_interaction',
        actionType: actionType,
        entityId: entity.id,
        entityType: entity.type.name,
        context: <String, dynamic>{
          'entity_title': entity.title,
          'why': attribution?.why,
          'why_details': attribution?.whyDetails,
          'recommendation_source': attribution?.recommendationSource,
          'projected_enjoyability_percent':
              attribution?.projectedEnjoyabilityPercent,
          'metadata': metadata,
        },
        runtimeContext: <String, dynamic>{
          'route_path': entity.routePath,
          'source_surface': sourceSurface,
          'has_coordinates': entity.hasCoordinates,
        },
      ),
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: actionType,
        actualOutcome: action.name,
        actualOutcomeScore: outcomeScore,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'discovery_${entity.type.name}',
            weight: 0.4,
            source: 'what',
          ),
          WhySignal(
            label: 'feedback_${action.name}',
            weight: action == RecommendationFeedbackAction.dismiss ||
                    action == RecommendationFeedbackAction.lessLikeThis
                ? -0.74
                : 0.74,
            source: 'how',
          ),
          if (attribution != null)
            WhySignal(
              label: attribution.recommendationSource,
              weight: attribution.confidence.clamp(0.0, 1.0),
              source: 'why',
            ),
        ],
        pheromoneSignals: <WhySignal>[
          if (action == RecommendationFeedbackAction.dismiss ||
              action == RecommendationFeedbackAction.lessLikeThis)
            WhySignal(
              label: 'negative_preference_${entity.type.name}',
              weight: -0.7,
              source: 'pheromone',
              durable: false,
            ),
        ],
        memoryContext: <String, dynamic>{
          'entity_id': entity.id,
          'entity_type': entity.type.name,
          'surface': sourceSurface,
        },
        severity: action == RecommendationFeedbackAction.dismiss ||
                action == RecommendationFeedbackAction.lessLikeThis
            ? 'medium'
            : 'low',
      ),
    );
  }

  String _listActionType(ListInteractionType type) {
    return switch (type) {
      ListInteractionType.viewed => 'view_list',
      ListInteractionType.saved => 'save_list',
      ListInteractionType.dismissed => 'dismiss_list',
      ListInteractionType.placeVisited => 'visit_place_from_list',
      ListInteractionType.shared => 'share_list',
      ListInteractionType.addedToCollection => 'add_list_to_collection',
    };
  }

  double _interactionOutcomeScore(ListInteraction interaction) {
    if (interaction.isPositive) return 0.82;
    if (interaction.isNegative) return 0.18;
    return 0.5;
  }

  List<WhySignal> _listCoreSignals(
    ListInteraction interaction,
    SuggestedList? suggestedList,
  ) {
    return <WhySignal>[
      WhySignal(
        label: 'list_interaction_${interaction.type.name}',
        weight: interaction.isPositive
            ? 0.72
            : interaction.isNegative
                ? -0.72
                : 0.12,
        source: 'what',
      ),
      if (suggestedList != null)
        WhySignal(
          label: 'theme_${suggestedList.theme}',
          weight: suggestedList.qualityScore.clamp(0.0, 1.0),
          source: 'what',
        ),
      if (interaction.metadata.isNotEmpty)
        WhySignal(
          label: 'interaction_metadata_present',
          weight: 0.18,
          source: 'how',
        ),
    ];
  }

  List<WhySignal> _listPheromoneSignals(ListInteraction interaction) {
    final negativeIntent = interaction
        .metadata[ListInteraction.negativePreferenceIntentMetadataKey];
    if (interaction.type != ListInteractionType.dismissed ||
        negativeIntent == null) {
      return const <WhySignal>[];
    }
    return <WhySignal>[
      WhySignal(
        label: negativeIntent.toString(),
        weight: negativeIntent == ListInteraction.hardNotInterestedIntentValue
            ? -0.82
            : -0.48,
        source: 'pheromone',
        durable: false,
      ),
    ];
  }
}
