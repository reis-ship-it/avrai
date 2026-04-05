import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';

class BhamReplayPhysicalMovementService {
  const BhamReplayPhysicalMovementService({
    BhamReplayStochasticVariationService? stochasticVariationService,
  }) : _stochasticVariationService =
           stochasticVariationService ??
           const BhamReplayStochasticVariationService();

  final BhamReplayStochasticVariationService _stochasticVariationService;

  static const List<String> _flightDestinations = <String>[
    'atlanta',
    'dallas',
    'houston',
    'chicago',
    'washington_dc',
    'new_york_city',
  ];

  ReplayPhysicalMovementReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    ReplayStochasticRunConfig? stochasticRunConfig,
  }) {
    final runConfig =
        stochasticRunConfig ??
        _stochasticVariationService.buildRunConfig(environment: environment);
    final actionsByActor = <String, List<ReplayActorAction>>{};
    for (final action in dailyBehaviorBatch.actions) {
      actionsByActor.putIfAbsent(action.actorId, () => <ReplayActorAction>[]).add(action);
    }
    for (final actions in actionsByActor.values) {
      actions.sort((left, right) {
        final monthCompare = left.monthKey.compareTo(right.monthKey);
        if (monthCompare != 0) {
          return monthCompare;
        }
        return left.actionId.compareTo(right.actionId);
      });
    }

    final nodeByEntityId = <String, ReplayPlaceGraphNode>{};
    for (final node in placeGraph.nodes) {
      nodeByEntityId[node.identity.normalizedEntityId] = node;
      for (final entityId in node.associatedEntityIds) {
        nodeByEntityId[entityId] = node;
      }
    }

    final airportNode = _findAirportNode(placeGraph);

    final trackedLocations = <ReplayTrackedLocationRecord>[];
    final untrackedWindows = <ReplayUntrackedLocationWindow>[];
    final movements = <ReplayMovementRecord>[];
    final flights = <ReplayFlightRecord>[];

    for (final actor in populationProfile.actors) {
      final actorActions =
          actionsByActor[actor.actorId] ?? const <ReplayActorAction>[];
      var previousPhysicalRef = _homePhysicalRef(actor);
      var previousLocality = actor.localityAnchor;

      trackedLocations.add(
        ReplayTrackedLocationRecord(
          locationRecordId: 'location:${actor.actorId}:home',
          actorId: actor.actorId,
          monthKey: '2023-01',
          localityAnchor: actor.localityAnchor,
          trackingState: ReplayLocationTrackingState.untracked,
          locationKind: 'home_anchor',
          physicalRef: previousPhysicalRef,
          reason: 'simulated home anchor for daily life baseline',
          metadata: <String, dynamic>{
            'householdType': actor.householdType,
            'lifeStage': actor.lifeStage,
          },
        ),
      );

      for (final action in actorActions) {
        final tracked = _isTrackedDestination(action.destinationChoice);
        final node = tracked
            ? nodeByEntityId[action.destinationChoice.entityId]
            : null;
        final physicalRef = tracked
            ? _trackedPhysicalRef(
                action: action,
                node: node,
              )
            : _offGraphPhysicalRef(action: action, actor: actor);

        if (tracked) {
          trackedLocations.add(
            ReplayTrackedLocationRecord(
              locationRecordId: 'location:${action.actionId}',
              actorId: actor.actorId,
              monthKey: action.monthKey,
              localityAnchor: action.localityAnchor,
              trackingState: ReplayLocationTrackingState.tracked,
              locationKind: action.actionType,
              physicalRef: physicalRef,
              entityId: action.destinationChoice.entityId,
              entityType: action.destinationChoice.entityType,
              placeNodeId: node?.nodeId,
              reason: action.destinationChoice.reason,
              metadata: <String, dynamic>{
                'status': action.status,
                'guidedByAgentIds': action.guidedByAgentIds,
                'kernelLanes': action.kernelLanes,
              },
            ),
          );
        } else {
          untrackedWindows.add(
            ReplayUntrackedLocationWindow(
              windowId: 'window:${action.actionId}',
              actorId: actor.actorId,
              monthKey: action.monthKey,
              localityAnchor: action.localityAnchor,
              windowLabel: action.actionType,
              reason: action.destinationChoice.reason,
              metadata: <String, dynamic>{
                'physicalRef': physicalRef,
                'guidedByAgentIds': action.guidedByAgentIds,
              },
            ),
          );
        }

        if (previousPhysicalRef != physicalRef) {
          movements.add(
            ReplayMovementRecord(
              movementId: 'movement:${action.actionId}',
              actorId: actor.actorId,
              monthKey: action.monthKey,
              originPhysicalRef: previousPhysicalRef,
              destinationPhysicalRef: physicalRef,
              originLocalityAnchor: previousLocality,
              destinationLocalityAnchor: action.localityAnchor,
              mode: _movementModeFor(actor: actor, action: action, tracked: tracked),
              tracked: tracked,
              sourceActionId: action.actionId,
              metadata: <String, dynamic>{
                'actionType': action.actionType,
                'entityType': action.destinationChoice.entityType,
              },
            ),
          );
        }

        previousPhysicalRef = physicalRef;
        previousLocality = action.localityAnchor;
      }

      final actorFlights = _buildFlightsForActor(
        actor: actor,
        airportNode: airportNode,
        runConfig: runConfig,
      );
      for (final flight in actorFlights) {
        flights.add(flight);
        trackedLocations.add(
          ReplayTrackedLocationRecord(
            locationRecordId: 'location:${flight.flightId}:airport',
            actorId: actor.actorId,
            monthKey: flight.monthKey,
            localityAnchor: actor.localityAnchor,
            trackingState: ReplayLocationTrackingState.tracked,
            locationKind: 'airport_departure',
            physicalRef: flight.airportPhysicalRef,
            entityId: flight.airportNodeId,
            entityType: 'airport',
            placeNodeId: flight.airportNodeId,
            reason: flight.reason,
            metadata: <String, dynamic>{
              'destinationRegion': flight.destinationRegion,
            },
          ),
        );
        movements.add(
          ReplayMovementRecord(
            movementId: 'movement:${flight.flightId}:to_airport',
            actorId: actor.actorId,
            monthKey: flight.monthKey,
            originPhysicalRef: _homePhysicalRef(actor),
            destinationPhysicalRef: flight.airportPhysicalRef,
            originLocalityAnchor: actor.localityAnchor,
            destinationLocalityAnchor: actor.localityAnchor,
            mode: ReplayMovementMode.drive,
            tracked: true,
            sourceActionId: flight.sourceActionId,
            metadata: <String, dynamic>{
              'phase': 'departure_transfer',
              'destinationRegion': flight.destinationRegion,
            },
          ),
        );
        movements.add(
          ReplayMovementRecord(
            movementId: 'movement:${flight.flightId}:flight',
            actorId: actor.actorId,
            monthKey: flight.monthKey,
            originPhysicalRef: flight.airportPhysicalRef,
            destinationPhysicalRef: 'out_of_region:${flight.destinationRegion}',
            originLocalityAnchor: actor.localityAnchor,
            destinationLocalityAnchor: 'out_of_region',
            mode: ReplayMovementMode.flight,
            tracked: true,
            sourceActionId: flight.sourceActionId,
            metadata: <String, dynamic>{
              'phase': 'air_travel',
            },
          ),
        );
      }
    }

    return ReplayPhysicalMovementReport(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      trackedLocations: trackedLocations,
      untrackedWindows: untrackedWindows,
      movements: movements,
      flights: flights,
      metadata: <String, dynamic>{
        'trackedLocationCount': trackedLocations.length,
        'untrackedWindowCount': untrackedWindows.length,
        'movementCount': movements.length,
        'flightCount': flights.length,
      },
    );
  }

  bool _isTrackedDestination(ReplayDestinationChoice destination) {
    if (destination.entityId.isEmpty) {
      return false;
    }
    if (destination.entityId.startsWith('offgraph:')) {
      return false;
    }
    if (destination.entityType == 'offgraph' ||
        _isRoutineOnlyEntityType(destination.entityType)) {
      return false;
    }
    return true;
  }

  bool _isRoutineOnlyEntityType(String entityType) {
    return const <String>{
      'career_anchor',
      'career_shift',
      'school_anchor',
      'school_day',
      'household_anchor',
      'household_cycle',
      'retired_routine',
      'family_weekend',
      'locality_leisure',
      'reduced_circuit',
      'locality',
    }.contains(entityType);
  }

  String _trackedPhysicalRef({
    required ReplayActorAction action,
    required ReplayPlaceGraphNode? node,
  }) {
    if (node != null) {
      return 'node:${node.nodeId}';
    }
    return 'entity:${action.destinationChoice.entityId}';
  }

  String _offGraphPhysicalRef({
    required ReplayActorAction action,
    required ReplayActorProfile actor,
  }) {
    final schedule = action.metadata['scheduleSurface']?.toString() ??
        actor.metadata['defaultRoutineSurface']?.toString() ??
        'offgraph';
    return 'offgraph:${actor.localityAnchor}:$schedule:${action.actionType}';
  }

  String _homePhysicalRef(ReplayActorProfile actor) {
    return 'home:${actor.localityAnchor}:${actor.householdType}';
  }

  ReplayMovementMode _movementModeFor({
    required ReplayActorProfile actor,
    required ReplayActorAction action,
    required bool tracked,
  }) {
    if (!tracked) {
      return ReplayMovementMode.offGraph;
    }
    if (action.destinationChoice.entityType == 'event' &&
        actor.lifeStage.contains('student')) {
      return ReplayMovementMode.walk;
    }
    if (actor.workStudentStatus.contains('commuter')) {
      return ReplayMovementMode.drive;
    }
    if (actor.workStudentStatus.contains('student')) {
      return ReplayMovementMode.transit;
    }
    if (actor.lifeStage.contains('nightlife')) {
      return ReplayMovementMode.rideshare;
    }
    return ReplayMovementMode.drive;
  }

  ReplayPlaceGraphNode? _findAirportNode(ReplayPlaceGraph placeGraph) {
    for (final node in placeGraph.nodes) {
      final name = node.identity.canonicalName.toLowerCase();
      if (name.contains('airport') || name.contains('shuttlesworth')) {
        return node;
      }
    }
    return null;
  }

  List<ReplayFlightRecord> _buildFlightsForActor({
    required ReplayActorProfile actor,
    required ReplayPlaceGraphNode? airportNode,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final careerTrack = actor.metadata['careerTrack']?.toString() ?? '';
    final likelyTraveler =
        actor.workStudentStatus.contains('commuter') ||
        careerTrack.contains('commuter') ||
        actor.lifeStage.contains('civic') ||
        actor.lifeStage.contains('student');
    if (!likelyTraveler ||
        !_stochasticVariationService.chance(
          config: runConfig,
          actorId: actor.actorId,
          channel: 'movement:flight_candidate',
          probability: 0.08,
          localityAnchor: actor.localityAnchor,
        )) {
      return const <ReplayFlightRecord>[];
    }

    final flightCount = _stochasticVariationService.chance(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'movement:flight_count',
      probability: 0.42,
      localityAnchor: actor.localityAnchor,
    )
        ? 2
        : 1;
    final airportNodeId = airportNode?.nodeId ?? 'node:bhm_airport';
    final airportPhysicalRef = airportNode == null
        ? 'node:bhm_airport'
        : 'node:${airportNode.nodeId}';

    return List<ReplayFlightRecord>.generate(flightCount, (index) {
      final destinationIndex = _stochasticVariationService.index(
        config: runConfig,
        actorId: actor.actorId,
        channel: 'movement:flight_destination',
        length: _flightDestinations.length,
        localityAnchor: actor.localityAnchor,
        salt: index,
      );
      final destinationRegion = _flightDestinations[destinationIndex];
      final month = _stochasticVariationService.intInRange(
        config: runConfig,
        actorId: actor.actorId,
        channel: 'movement:flight_month',
        minInclusive: 1,
        maxInclusive: 12,
        localityAnchor: actor.localityAnchor,
        entityId: destinationRegion,
        salt: index,
      );
      return ReplayFlightRecord(
        flightId: 'flight:${actor.actorId}:$index',
        actorId: actor.actorId,
        monthKey: '2023-${month.toString().padLeft(2, '0')}',
        airportNodeId: airportNodeId,
        airportPhysicalRef: airportPhysicalRef,
        destinationRegion: destinationRegion,
        reason: 'simulated travel window from career and life-stage mobility pattern',
        sourceActionId: null,
        metadata: <String, dynamic>{
          'careerTrack': careerTrack,
          'lifeStage': actor.lifeStage,
        },
        );
    });
  }
}
