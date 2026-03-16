import 'dart:math';
import 'package:uuid/uuid.dart';
import 'city_profile.dart';
import 'spatial/geo_coordinate.dart';

enum RoutineState {
  sleeping,
  home,
  commuting,
  working,
  freeTime,
}

class DailyRoutine {
  final int wakeUpHour;
  final int leaveForWorkHour;
  final int arriveAtWorkHour;
  final int leaveWorkHour;
  final int arriveHomeHour;
  final int sleepHour;

  const DailyRoutine({
    required this.wakeUpHour,
    required this.leaveForWorkHour,
    required this.arriveAtWorkHour,
    required this.leaveWorkHour,
    required this.arriveHomeHour,
    required this.sleepHour,
  });
}

class FinancialProfile {
  final double discretionaryBudget; // Scale 0.1 (Tight) to 1.0 (Affluent)
  final double
      priceSensitivity; // Scale 0.1 (Low Sensitivity) to 1.0 (High Sensitivity)

  const FinancialProfile({
    required this.discretionaryBudget,
    required this.priceSensitivity,
  });
}

/// Represents a digital twin in the Swarm Simulation.
class SimulatedHuman {
  final String id;
  final CityProfile city;
  final DailyRoutine routine;
  final FinancialProfile finances;
  final double transportDependence;
  final double weatherSensitivity;
  final double accessibilitySensitivity;
  final double socialFollowThrough;
  final double nightlifeAffinity;
  final double childcareFriction;

  final GeoCoordinate homeLocation;
  final GeoCoordinate workLocation;
  GeoCoordinate currentLocation;

  /// A baseline resistance to breaking routine (0.0 to 1.0)
  /// 1.0 = highly rigid routine, very hard to break.
  double baseInertia;

  /// The dynamic willingness to accept a suggestion. Drops temporarily after a good experience.
  double currentActivationEnergy;

  /// Tracks the quality of AI suggestions. High disappointment makes friction rigid again.
  /// Scale -1.0 (deeply disappointed/distrustful) to 1.0 (highly trusting)
  double trustMeter;

  RoutineState currentState = RoutineState.sleeping;

  SimulatedHuman({
    String? id,
    required this.city,
    required this.routine,
    required this.finances,
    this.transportDependence = 0.5,
    this.weatherSensitivity = 0.5,
    this.accessibilitySensitivity = 0.2,
    this.socialFollowThrough = 0.5,
    this.nightlifeAffinity = 0.5,
    this.childcareFriction = 0.0,
    required this.homeLocation,
    required this.workLocation,
    this.baseInertia = 0.7,
    this.trustMeter = 0.0,
  })  : id = id ?? const Uuid().v4(),
        currentLocation = homeLocation,
        currentActivationEnergy = baseInertia;

  /// Simulates evaluating an AI suggestion.
  ///
  /// [value] - The perceived value of the suggestion (0.0 to 1.0)
  /// [friction] - The calculated friction to get to the event (0.0 to 1.0)
  /// [eventCost] - The relative cost of the event (0.0 to 1.0)
  ///
  /// Returns true if accepted, false if rejected.
  bool evaluateSuggestion({
    required double value,
    required double friction,
    double eventCost = 0.0,
    double weatherImpact = 0.0,
    double routeReliabilityPenalty = 0.0,
    double socialMomentumBoost = 0.0,
  }) {
    // 1. Calculate Financial Friction
    // If the event cost is high relative to their budget, add massive friction.
    double financialFriction = 0.0;
    if (eventCost > finances.discretionaryBudget) {
      financialFriction = (eventCost - finances.discretionaryBudget) *
          finances.priceSensitivity *
          2.0;
    }

    // 2. Combine frictions and apply trust modifier
    double totalFriction = friction +
        financialFriction +
        (weatherImpact * weatherSensitivity * 0.5) +
        (routeReliabilityPenalty * transportDependence * 0.4) +
        (childcareFriction * 0.35) +
        (accessibilitySensitivity * 0.2);

    // Trust significantly lowers perceived friction (up to 0.3 offset)
    double effectiveFriction = totalFriction - (trustMeter * 0.3);

    // Hard floor for friction - even with high trust, effort is required
    if (effectiveFriction < 0.1) effectiveFriction = 0.1;

    if (effectiveFriction > currentActivationEnergy) {
      return false; // Rejected due to friction (logistical or financial)
    }

    // 3. Evaluate Value Proposition
    // Does the value exceed the required effort?
    final effectiveValue =
        value + (socialMomentumBoost * socialFollowThrough * 0.25);
    return effectiveValue >= effectiveFriction;
  }

  /// Processes the outcome of an event they attended.
  ///
  /// [experiencedValue] - How good the event actually was (0.0 to 1.0)
  void processEventOutcome(double experiencedValue) {
    if (experiencedValue >= 0.7) {
      // Great experience! Trust goes up, activation energy (friction) temporarily drops.
      trustMeter = min(1.0, trustMeter + 0.1);
      currentActivationEnergy = max(0.1, currentActivationEnergy - 0.2);
    } else if (experiencedValue < 0.4) {
      // Bad experience. Trust plummets. (Fragile trust mechanic)
      trustMeter = max(-1.0, trustMeter - 0.3); // Drops 3x faster than it grows

      // They retreat into their routine. Activation energy snaps back to base, or higher.
      currentActivationEnergy = min(1.0, baseInertia + 0.1);
    } else {
      // Mediocre experience. Slight trust decay (prevent regression to mean of mediocrity).
      trustMeter = max(-1.0, trustMeter - 0.05);
      _regressToMean();
    }
  }

  /// Natural temporal decay of states over time (regression to the mean).
  void tickTime() {
    _regressToMean();
  }

  void _regressToMean() {
    // Activation energy slowly creeps back up to base inertia over time
    if (currentActivationEnergy < baseInertia) {
      currentActivationEnergy += 0.01;
    }
  }

  /// Injects a major life event that drastically alters baseline traits.
  void injectMacroLifeEvent(String eventType) {
    switch (eventType) {
      case 'got_a_dog':
        baseInertia = min(1.0, baseInertia + 0.1); // More restricted schedule
        break;
      case 'moved_neighborhoods':
        currentActivationEnergy = 0.2; // High willingness to explore initially
        break;
      case 'new_job':
        baseInertia = min(1.0, baseInertia + 0.15); // Stressed, less free time
        break;
    }
  }
}
