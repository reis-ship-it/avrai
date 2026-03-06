import 'dart:developer' as developer;
import '../models/city_profile.dart';
import '../models/simulated_human.dart';
import 'swarm_atomic_clock.dart';
import '../models/spatial/swarm_map_environment.dart';
import '../models/spatial/pathfinding_service.dart';
import '../models/spatial/interstitial_gap_finder.dart';
import '../models/federated_knowledge_exchange.dart';

/// Orchestrates the Multi-City Synthetic Swarm Simulation.
class SwarmSimulationEngine {
  static const String _logName = 'SwarmSimulationEngine';

  final CityProfile city;
  final SwarmAtomicClock clock;
  final List<SimulatedHuman> population;
  final List<WeatherState> annualWeather;

  /// Defines how much simulation time passes per tick.
  final Duration tickInterval;

  final SwarmMapEnvironment mapEnvironment;
  final InterstitialGapFinder gapFinder;
  final PathfindingService pathfinder;

  final FederatedKnowledgeExchange knowledgeExchange;

  int _currentDayIndex = 0;

  SwarmSimulationEngine({
    required this.city,
    required this.clock,
    required this.population,
    required this.mapEnvironment,
    required this.knowledgeExchange,
    this.tickInterval = const Duration(minutes: 15), // Default 15 min ticks
  })  : annualWeather = city.generateAnnualWeather(),
        pathfinder = PathfindingService(),
        gapFinder = InterstitialGapFinder(
          environment: mapEnvironment,
          pathfinder: PathfindingService(),
          knowledgeExchange: knowledgeExchange,
        );

  /// Starts the simulation and runs it for a specified number of days.
  Future<void> runSimulation({int daysToRun = 90}) async {
    developer.log(
        'Starting Swarm Simulation for ${city.name} ($daysToRun days) with ${mapEnvironment.allPOIs.length} POIs',
        name: _logName);
    developer.log(
      'Executing Swarm Node: ${city.name} (${population.length} Agents) for $daysToRun days...',
      name: _logName,
    );

    final startTicks = DateTime.now();

    for (int day = 0; day < daysToRun; day++) {
      if (_currentDayIndex >= annualWeather.length) {
        // Loop back if we exceed the generated 360 days
        _currentDayIndex = 0;
      }

      final currentWeather = annualWeather[_currentDayIndex];
      if (day % 10 == 0) {
        // Only log every 10 days to reduce console spam
        developer.log(
            'Day $day: Season=${currentWeather.season.name}, Temp=${currentWeather.temperatureFahrenheit}F',
            name: _logName);
        developer.log(
          '${city.name}: Simulating Day $day (Weather: ${currentWeather.season.name})',
          name: _logName,
        );
      }

      // Run all ticks for a single 24-hour period
      final ticksPerDay =
          const Duration(hours: 24).inMinutes ~/ tickInterval.inMinutes;
      for (int t = 0; t < ticksPerDay; t++) {
        await _tick(currentWeather);
      }

      // End of day updates
      _endOfDayProcessing();
      _currentDayIndex++;
    }

    final endTicks = DateTime.now();
    final duration = endTicks.difference(startTicks);

    developer.log(
        'Simulation complete for ${city.name} in ${duration.inSeconds}s',
        name: _logName);
    developer.log('✅ ${city.name} Simulation Complete (${duration.inSeconds}s)',
        name: _logName);
  }

  /// Processes a single time step in the simulation.
  Future<void> _tick(WeatherState weather) async {
    // 1. Advance the atomic clock
    clock.tick(tickInterval);
    final currentAtomicTime = await clock.getAtomicTimestamp();

    // 2. Determine general macro routine state based on time of day
    // (A very simplified routine logic for baseline training)
    final hour = currentAtomicTime.localTime.hour;

    for (final human in population) {
      _updateHumanRoutine(human, hour);

      // Explore interstitial gaps (Routine Enhancement)
      _exploreInterstitialGaps(human);

      human.tickTime();
    }
  }

  /// Extremely basic routine logic using the human's personalized DailyRoutine.
  void _updateHumanRoutine(SimulatedHuman human, int hour) {
    final r = human.routine;
    // Helper to handle hours that wrap past midnight
    bool isBetween(int h, int start, int end) {
      if (start == end) return false;
      if (start < end) {
        return h >= start && h < end;
      } else {
        return h >= start || h < end;
      }
    }

    if (isBetween(hour, r.sleepHour, r.wakeUpHour)) {
      human.currentState = RoutineState.sleeping;
      human.currentLocation = human.homeLocation;
    } else if (isBetween(hour, r.wakeUpHour, r.leaveForWorkHour)) {
      human.currentState = RoutineState.home;
      human.currentLocation = human.homeLocation;
    } else if (isBetween(hour, r.leaveForWorkHour, r.arriveAtWorkHour)) {
      human.currentState = RoutineState.commuting;
    } else if (isBetween(hour, r.arriveAtWorkHour, r.leaveWorkHour)) {
      human.currentState = RoutineState.working;
      human.currentLocation = human.workLocation;
    } else if (isBetween(hour, r.leaveWorkHour, r.arriveHomeHour)) {
      human.currentState = RoutineState.commuting;
    } else {
      human.currentState = RoutineState.freeTime;
    }
  }

  void _exploreInterstitialGaps(SimulatedHuman human) {
    // Only explore gaps during commutes or free time for now
    if (human.currentState != RoutineState.commuting &&
        human.currentState != RoutineState.freeTime) {
      return;
    }

    // Determine the route
    RoutePath currentRoute;
    if (human.currentState == RoutineState.commuting) {
      currentRoute =
          pathfinder.calculateRoute(human.homeLocation, human.workLocation);
    } else {
      // Free time: Random walk around current location
      currentRoute = RoutePath(
          start: human.currentLocation,
          end: human.currentLocation,
          waypoints: [],
          totalDistanceKm: 0);
    }

    // Find gaps.
    // Skip spatial check entirely if there are no valid categories
    // (optimization to prevent O(N) map scans when sleeping/home).
    final relevantCategories =
        gapFinder.getRelevantCategories(human.currentState);
    if (relevantCategories.isEmpty) {
      return;
    }

    final suggestions = gapFinder.findEnhancementsAlongRoute(
      human,
      currentRoute,
      maxDeviationKm: 1.5,
      limit: 3,
    );

    // If suggestions found, see if the human takes one
    for (final suggestion in suggestions) {
      double friction =
          currentRoute.start.distanceTo(suggestion.location) * 0.5;

      final accepted = human.evaluateSuggestion(
          value: suggestion.baseQuality,
          friction: friction,
          eventCost: suggestion.cost);

      if (accepted) {
        // They went to the POI
        human.currentLocation = suggestion.location;
        human.processEventOutcome(suggestion.baseQuality);

        // Report success back to the swarm
        if (suggestion.baseQuality > 0.6) {
          knowledgeExchange.recordSuccess(
              human, suggestion, suggestion.baseQuality);
        }

        // developer.log('Agent ${human.id.substring(0,4)} discovered gap: ${suggestion.name} (${suggestion.category.name})', name: _logName);
        break; // Only take one suggestion per tick
      }
    }
  }

  /// Nightly processing for the simulated humans
  void _endOfDayProcessing() {
    for (final _ in population) {
      // Regress activation energy/friction back to baseline happens during standard tickTime now
    }
  }
}
