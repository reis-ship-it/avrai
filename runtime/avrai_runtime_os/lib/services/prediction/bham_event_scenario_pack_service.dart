import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';

class BhamEventScenarioPackService {
  const BhamEventScenarioPackService();

  List<ReplayScenarioPacket> buildScenarioPack({
    DateTime? createdAt,
    String createdBy = 'internal_beta_pack',
  }) {
    final now = (createdAt ?? DateTime.now()).toUtc();
    return <ReplayScenarioPacket>[
      _citywideSpringEvent(now, createdBy),
      _neighborhoodActivationDay(now, createdBy),
      _outdoorWeatherStress(now, createdBy),
      _venueOverload(now, createdBy),
      _transitFriction(now, createdBy),
      _staffingShortfall(now, createdBy),
    ].map((packet) => packet.normalized()).toList(growable: false);
  }

  ReplayScenarioPacket _citywideSpringEvent(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_citywide_spring_event',
      name: 'Citywide Spring Event',
      description:
          'Tests a Birmingham-wide spring celebration with strong downtown and neighborhood pull.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.eventOps,
      scope: ReplayScopeKind.city,
      seedEntityRefs: const <String>['event:spring_festival', 'venue:railroad'],
      seedLocalityCodes: const <String>[
        'bham_downtown',
        'bham_avondale',
        'bham_lakeview',
      ],
      seedObservationRefs: const <String>['obs:spring_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'attendance_surge_core',
          kind: ReplayInterventionKind.attendanceSurge,
          targetType: 'locality',
          targetRef: 'bham_downtown',
          effectiveStart: DateTime.utc(2023, 3, 20, 16),
          effectiveEnd: DateTime.utc(2023, 3, 20, 23),
          magnitude: 0.32,
          notes: 'Peak attendance pushes downtown pressure above baseline.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'route_block_southside',
          kind: ReplayInterventionKind.routeBlock,
          targetType: 'corridor',
          targetRef: 'bham_southside',
          effectiveStart: DateTime.utc(2023, 3, 20, 18),
          effectiveEnd: DateTime.utc(2023, 3, 20, 22),
          magnitude: 0.21,
          notes: 'Tests reroute sensitivity across the entertainment corridor.',
        ),
      ],
      expectedQuestions: const <String>[
        'Which localities absorb overflow most cleanly?',
        'How quickly does route friction degrade attendance delivery?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }

  ReplayScenarioPacket _neighborhoodActivationDay(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_neighborhood_activation_day',
      name: 'Neighborhood Activation Day',
      description:
          'Tests smaller neighborhood-centered programming distributed across Birmingham.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.eventOps,
      scope: ReplayScopeKind.locality,
      seedEntityRefs: const <String>['event:activation_day'],
      seedLocalityCodes: const <String>[
        'bham_avondale',
        'bham_woodlawn',
        'bham_homewood',
      ],
      seedObservationRefs: const <String>['obs:activation_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'attendance_surge_avondale',
          kind: ReplayInterventionKind.attendanceSurge,
          targetType: 'locality',
          targetRef: 'bham_avondale',
          effectiveStart: DateTime.utc(2023, 4, 8, 12),
          effectiveEnd: DateTime.utc(2023, 4, 8, 21),
          magnitude: 0.24,
          notes: 'Localized neighborhood lift with overflow risk.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'locality_caution_woodlawn',
          kind: ReplayInterventionKind.localityCaution,
          targetType: 'locality',
          targetRef: 'bham_woodlawn',
          effectiveStart: DateTime.utc(2023, 4, 8, 14),
          effectiveEnd: DateTime.utc(2023, 4, 8, 20),
          magnitude: 0.18,
          notes: 'Adds caution pressure to distributed neighborhood programming.',
        ),
      ],
      expectedQuestions: const <String>[
        'Which neighborhood handles distributed programming best?',
        'Where does caution pressure create the largest falloff?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }

  ReplayScenarioPacket _outdoorWeatherStress(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_outdoor_weather_stress',
      name: 'Outdoor Weather Stress',
      description:
          'Tests how weather shift changes turnout, movement, and safety pressure for outdoor programming.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.weather,
      scope: ReplayScopeKind.city,
      seedEntityRefs: const <String>['event:outdoor_series'],
      seedLocalityCodes: const <String>['bham_downtown', 'bham_uptown'],
      seedObservationRefs: const <String>['obs:weather_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'weather_shift_evening',
          kind: ReplayInterventionKind.weatherShift,
          targetType: 'city',
          targetRef: bhamReplayCityCode,
          effectiveStart: DateTime.utc(2023, 5, 12, 17),
          effectiveEnd: DateTime.utc(2023, 5, 12, 23),
          magnitude: 0.35,
          notes: 'Fast evening storm degrades outdoor comfort and path reliability.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'staffing_loss_weather',
          kind: ReplayInterventionKind.staffingLoss,
          targetType: 'event',
          targetRef: 'event:outdoor_series',
          effectiveStart: DateTime.utc(2023, 5, 12, 18),
          effectiveEnd: DateTime.utc(2023, 5, 12, 22),
          magnitude: 0.16,
          notes: 'Weather compounds staffing pressure during the peak window.',
        ),
      ],
      expectedQuestions: const <String>[
        'How quickly should outdoor programming collapse into contingency mode?',
        'Which localities become fragile under weather plus staffing stress?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }

  ReplayScenarioPacket _venueOverload(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_venue_overload',
      name: 'Venue Overload',
      description:
          'Tests overload at a key Birmingham venue and how it redistributes pressure.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.venueOverload,
      scope: ReplayScopeKind.venue,
      seedEntityRefs: const <String>['venue:district_stage'],
      seedLocalityCodes: const <String>['bham_downtown', 'bham_uptown'],
      seedObservationRefs: const <String>['obs:venue_overload_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'attendance_surge_venue',
          kind: ReplayInterventionKind.attendanceSurge,
          targetType: 'venue',
          targetRef: 'venue:district_stage',
          effectiveStart: DateTime.utc(2023, 6, 17, 18),
          effectiveEnd: DateTime.utc(2023, 6, 17, 23),
          magnitude: 0.38,
          notes: 'Primary venue demand exceeds expected ingress and queue capacity.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'venue_closure_partial',
          kind: ReplayInterventionKind.venueClosure,
          targetType: 'venue',
          targetRef: 'venue:district_stage',
          effectiveStart: DateTime.utc(2023, 6, 17, 20),
          effectiveEnd: DateTime.utc(2023, 6, 17, 21),
          magnitude: 0.22,
          notes: 'Tests partial shutdown and redistribution pressure.',
        ),
      ],
      expectedQuestions: const <String>[
        'Where does overload pressure reroute first?',
        'How severe is the safety-stress delta under partial closure?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }

  ReplayScenarioPacket _transitFriction(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_transit_friction',
      name: 'Transit Friction',
      description:
          'Tests route friction around clustered destinations and its effect on delivery.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.transitFriction,
      scope: ReplayScopeKind.corridor,
      seedEntityRefs: const <String>['corridor:entertainment_axis'],
      seedLocalityCodes: const <String>['bham_southside', 'bham_five_points'],
      seedObservationRefs: const <String>['obs:transit_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'transit_delay_corridor',
          kind: ReplayInterventionKind.transitDelay,
          targetType: 'corridor',
          targetRef: 'corridor:entertainment_axis',
          effectiveStart: DateTime.utc(2023, 7, 22, 17),
          effectiveEnd: DateTime.utc(2023, 7, 22, 23),
          magnitude: 0.27,
          notes: 'Clustered destinations create route lag and slower arrival.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'route_block_five_points',
          kind: ReplayInterventionKind.routeBlock,
          targetType: 'locality',
          targetRef: 'bham_five_points',
          effectiveStart: DateTime.utc(2023, 7, 22, 18),
          effectiveEnd: DateTime.utc(2023, 7, 22, 22),
          magnitude: 0.19,
          notes: 'Adds route interruption on top of transit delay.',
        ),
      ],
      expectedQuestions: const <String>[
        'Does delivery degrade before attendance, or at the same rate?',
        'Which corridor-localities absorb the largest pathflow stress?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }

  ReplayScenarioPacket _staffingShortfall(DateTime now, String createdBy) {
    return ReplayScenarioPacket(
      scenarioId: 'bham_staffing_shortfall',
      name: 'Staffing Shortfall',
      description:
          'Tests worker and volunteer attrition against a Birmingham event baseline.',
      cityCode: bhamReplayCityCode,
      baseReplayYear: bhamReplayBaseYear,
      scenarioKind: ReplayScenarioKind.staffingPressure,
      scope: ReplayScopeKind.city,
      seedEntityRefs: const <String>['event:city_showcase'],
      seedLocalityCodes: const <String>['bham_downtown', 'bham_southside'],
      seedObservationRefs: const <String>['obs:staffing_seed'],
      interventions: <ReplayScenarioIntervention>[
        ReplayScenarioIntervention(
          interventionId: 'staffing_loss_ops',
          kind: ReplayInterventionKind.staffingLoss,
          targetType: 'event',
          targetRef: 'event:city_showcase',
          effectiveStart: DateTime.utc(2023, 8, 19, 15),
          effectiveEnd: DateTime.utc(2023, 8, 19, 22),
          magnitude: 0.29,
          notes: 'Operational staffing drops below target late in the day.',
        ),
        ReplayScenarioIntervention(
          interventionId: 'locality_caution_downtown',
          kind: ReplayInterventionKind.localityCaution,
          targetType: 'locality',
          targetRef: 'bham_downtown',
          effectiveStart: DateTime.utc(2023, 8, 19, 18),
          effectiveEnd: DateTime.utc(2023, 8, 19, 22),
          magnitude: 0.17,
          notes: 'Staffing attrition compounds locality-level caution pressure.',
        ),
      ],
      expectedQuestions: const <String>[
        'How quickly does staffing loss convert into safety stress?',
        'Which localities remain stable under degraded staffing?',
      ],
      createdAt: now,
      createdBy: createdBy,
    );
  }
}
