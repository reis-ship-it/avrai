import 'dart:developer' as developer;
import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/legacy/disabled_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'models/city_profile.dart';
import 'models/swarm_population_generator.dart';
import 'engine/swarm_atomic_clock.dart';
import 'engine/swarm_simulation_engine.dart';
import 'pipeline/real_world_ingestion_pipeline.dart';
import 'models/spatial/dense_poi_generator.dart';
import 'models/federated_knowledge_exchange.dart';
import 'package:reality_engine/memory/semantic_knowledge_store.dart';
import 'package:reality_engine/memory/air_gap/tuple_extraction_engine.dart';

/// Runner script for the authoritative Birmingham historical replay baseline.
///
/// This is the canonical Wave 8 replay path. It is Birmingham-only and runs on
/// one atomic replay timeline through the when kernel. Legacy multi-city swarm
/// experimentation may continue elsewhere, but it is not the authoritative
/// beta replay/training path.
Future<void> main() async {
  developer.log('=== Initializing BHAM Replay Baseline ===',
      name: 'SimulationRunner');
  developer.log(
    '=== Initializing BHAM Replay Baseline ===\nGenerating Birmingham map environment, please wait...',
    name: 'SimulationRunner',
  );

  // 1. Initialize the Birmingham city profile.
  final birmingham = CityProfile.birmingham();

  // 2. Initialize the authoritative replay clock for Birmingham.
  final startTime = DateTime.utc(2026, 3, 1, 6, 0, 0); // 6:00 AM UTC
  final whenKernel = WhenNativeKernelStub(
    nativeBridge: WhenNativeBridgeBindings(),
    fallback: const DisabledWhenFallbackKernel(),
    policy: const WhenNativeExecutionPolicy(requireNative: true),
  );
  final clock = SwarmAtomicClock(
    whenKernel: whenKernel,
    runtimeId: 'swarm_baseline_simulation',
    temporalMode: 'historical_replay',
    branchId: 'canonical',
    runId: 'wave8_bham_baseline',
    startTime: startTime,
  );

  // 3. Setup Locality Memory and Air Gap Ingestion
  final knowledgeStore = InMemorySemanticStore();
  final airGapEngine = TupleExtractionEngine(knowledgeStore);
  final pipeline = RealWorldIngestionPipeline(
    airGapEngine: airGapEngine,
    knowledgeStore: knowledgeStore,
    clock: clock,
  );

  // Pre-seed Birmingham locality agents with dense baseline POI data.
  developer.log('Building Birmingham map grid (5000 POIs)...',
      name: 'SimulationRunner');
  final mapGenerator = DensePOIGenerator(seed: 99);
  final birminghamMap =
      mapGenerator.generateCityMap(birmingham, totalPOIs: 5000);
  developer.log('Birmingham Map Generated.', name: 'SimulationRunner');

  developer.log('Ingesting to Semantic Store via Air Gap...',
      name: 'SimulationRunner');
  await pipeline.ingestBaselineData(birminghamMap);
  developer.log('Ingestion Complete.', name: 'SimulationRunner');

  // 4. Generate the Birmingham simulated population.
  final generator =
      SwarmPopulationGenerator(seed: 42); // Seeded for deterministic execution

  final birminghamPopulation = generator.generatePopulation(birmingham, 50);

  // 4.5 Initialize federated knowledge exchange for the Birmingham node.
  final globalKnowledgeExchange = FederatedKnowledgeExchange();

  // 5. Create the authoritative Birmingham replay engine.
  final birminghamEngine = SwarmSimulationEngine(
    city: birmingham,
    clock: clock,
    population: birminghamPopulation,
    mapEnvironment: birminghamMap,
    knowledgeExchange: globalKnowledgeExchange,
  );

  // 6. Execute the shared-time Birmingham replay run.
  final engines = <SwarmSimulationEngine>[birminghamEngine];
  final tickInterval = engines.first.tickInterval;
  final ticksPerDay = const Duration(hours: 24).inMinutes ~/ tickInterval.inMinutes;
  const daysToRun = 90;

  developer.log(
    'Executing Birmingham replay on one atomic timeline...',
    name: 'SimulationRunner',
  );

  for (int day = 0; day < daysToRun; day++) {
    final weatherByEngine = <SwarmSimulationEngine, WeatherState>{
      for (final engine in engines) engine: engine.currentWeather,
    };

    if (day % 10 == 0) {
      for (final engine in engines) {
        final weather = weatherByEngine[engine]!;
        developer.log(
          '${engine.city.name}: Day $day on shared atomic timeline '
          '(Weather: ${weather.season.name}, ${weather.temperatureFahrenheit}F)',
          name: 'SimulationRunner',
        );
      }
    }

    for (int tick = 0; tick < ticksPerDay; tick++) {
      clock.tick(tickInterval);
      final currentAtomicTime = await clock.getAtomicTimestamp();
      for (final engine in engines) {
        await engine.processTickAt(
          currentAtomicTime,
          weather: weatherByEngine[engine]!,
        );
      }
    }

    for (final engine in engines) {
      engine.completeDay();
    }
  }

  developer.log('=== BHAM Replay Baseline Complete ===',
      name: 'SimulationRunner');
}
