import 'dart:developer' as developer;
import 'models/city_profile.dart';
import 'models/swarm_population_generator.dart';
import 'engine/swarm_atomic_clock.dart';
import 'engine/swarm_simulation_engine.dart';
import 'pipeline/real_world_ingestion_pipeline.dart';
import 'models/spatial/dense_poi_generator.dart';
import 'models/federated_knowledge_exchange.dart';
import 'package:reality_engine/memory/semantic_knowledge_store.dart';
import 'package:reality_engine/memory/air_gap/tuple_extraction_engine.dart';

/// Runner script for the Multi-City Synthetic Swarm Simulation (Spike 1 & 2).
///
/// Initializes the simulation environments for NYC, Denver, and Atlanta,
/// populates them with digital twin humans, and runs the baseline temporal loop.
Future<void> main() async {
  developer.log('=== Initializing Swarm Baseline Simulation ===',
      name: 'SimulationRunner');
  developer.log(
    '=== Initializing Swarm Baseline Simulation ===\nGenerating dense map environments, please wait...',
    name: 'SimulationRunner',
  );

  // 1. Initialize the City Profiles
  final nyc = CityProfile.newYork();
  final denver = CityProfile.denver();
  final atlanta = CityProfile.atlanta();

  // 2. Initialize the Atomic Clock for the simulation (Starts Spring 2026)
  final startTime = DateTime.utc(2026, 3, 1, 6, 0, 0); // 6:00 AM UTC
  final clock = SwarmAtomicClock(startTime: startTime);

  // 3. Setup Locality Memory and Air Gap Ingestion
  final knowledgeStore = InMemorySemanticStore();
  final airGapEngine = TupleExtractionEngine(knowledgeStore);
  final pipeline = RealWorldIngestionPipeline(
    airGapEngine: airGapEngine,
    knowledgeStore: knowledgeStore,
    clock: clock,
  );

  // Pre-seed Locality Agents with dense real-world POI baseline data
  developer.log('Building Map Grids (5000 POIs each)...',
      name: 'SimulationRunner');
  final mapGenerator = DensePOIGenerator(seed: 99);
  final nycMap = mapGenerator.generateCityMap(nyc, totalPOIs: 5000);
  developer.log('NYC Map Generated.', name: 'SimulationRunner');
  final denverMap = mapGenerator.generateCityMap(denver, totalPOIs: 5000);
  developer.log('Denver Map Generated.', name: 'SimulationRunner');
  final atlantaMap = mapGenerator.generateCityMap(atlanta, totalPOIs: 5000);
  developer.log('Atlanta Map Generated.', name: 'SimulationRunner');

  developer.log('Ingesting to Semantic Store via Air Gap...',
      name: 'SimulationRunner');
  await pipeline.ingestBaselineData(nycMap);
  await pipeline.ingestBaselineData(denverMap);
  await pipeline.ingestBaselineData(atlantaMap);
  developer.log('Ingestion Complete.', name: 'SimulationRunner');

  // 4. Generate Simulated Populations with Variance
  final generator =
      SwarmPopulationGenerator(seed: 42); // Seeded for deterministic execution

  final nycPopulation = generator.generatePopulation(nyc, 50);
  final denverPopulation = generator.generatePopulation(denver, 50);
  final atlantaPopulation = generator.generatePopulation(atlanta, 50);

  // 4.5 Initialize Swarm Federated Knowledge
  final globalKnowledgeExchange = FederatedKnowledgeExchange();

  // 5. Create the Simulation Engines (concurrent swarms)
  final nycEngine = SwarmSimulationEngine(
    city: nyc,
    clock: clock,
    population: nycPopulation,
    mapEnvironment: nycMap,
    knowledgeExchange: globalKnowledgeExchange,
    tickInterval: const Duration(minutes: 15), // 15 minute temporal resolution
  );

  final denverEngine = SwarmSimulationEngine(
    city: denver,
    clock: clock,
    population: denverPopulation,
    mapEnvironment: denverMap,
    knowledgeExchange: globalKnowledgeExchange,
  );

  final atlantaEngine = SwarmSimulationEngine(
    city: atlanta,
    clock: clock,
    population: atlantaPopulation,
    mapEnvironment: atlantaMap,
    knowledgeExchange: globalKnowledgeExchange,
  );

  // 6. Execute Simulation Runs
  // Running the initial baseline for 90 days (1 full season).
  // In production, this can loop to 360 days to train across all weather profiles.
  developer.log('Executing NYC Swarm Node...', name: 'SimulationRunner');
  await nycEngine.runSimulation(daysToRun: 90);

  developer.log('Executing Denver Swarm Node...', name: 'SimulationRunner');
  await denverEngine.runSimulation(daysToRun: 90);

  developer.log('Executing Atlanta Swarm Node...', name: 'SimulationRunner');
  await atlantaEngine.runSimulation(daysToRun: 90);

  developer.log('=== Swarm Baseline Simulation Complete ===',
      name: 'SimulationRunner');
}
