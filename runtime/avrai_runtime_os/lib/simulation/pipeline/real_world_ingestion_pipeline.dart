import 'dart:developer' as developer;
import 'package:reality_engine/memory/semantic_knowledge_store.dart';
import 'package:reality_engine/memory/air_gap/tuple_extraction_engine.dart';
import '../models/spatial/swarm_map_environment.dart';
import 'raw_city_event_payload.dart';
import '../engine/swarm_atomic_clock.dart';

/// Pipeline that ingests spatial POIs, passes them through the Air Gap,
/// and stores the resulting semantic knowledge to pre-seed Locality Agents.
class RealWorldIngestionPipeline {
  static const String _logName = 'RealWorldIngestionPipeline';

  final TupleExtractionEngine _airGapEngine;
  final SemanticKnowledgeStore _knowledgeStore;
  final SwarmAtomicClock _clock;

  RealWorldIngestionPipeline({
    required TupleExtractionEngine airGapEngine,
    required SemanticKnowledgeStore knowledgeStore,
    required SwarmAtomicClock clock,
  })  : _airGapEngine = airGapEngine,
        _knowledgeStore = knowledgeStore,
        _clock = clock;

  Future<void> ingestBaselineData(SwarmMapEnvironment environment) async {
    developer.log('Starting ingestion pipeline for city: ${environment.cityId}',
        name: _logName);
    developer.log(
      'Starting ingestion pipeline for city: ${environment.cityId} (${environment.allPOIs.length} POIs)',
      name: _logName,
    );

    final cityPOIs = environment.allPOIs;
    developer.log('Found ${cityPOIs.length} generated POIs for baseline.',
        name: _logName);

    // Get timestamp once per city to avoid millions of async calls
    final atomicTime = await _clock.getAtomicTimestamp();

    // Limit ingestion to a small subset for testing/speed if needed,
    // For local dev, 10 POIs is enough to test the flow without hanging.
    final ingestLimit = 10; // was: cityPOIs.length
    developer.log(
      'Taking sample of $ingestLimit POIs to prevent simulation lockup...',
      name: _logName,
    );

    int count = 0;
    for (final poi in cityPOIs.take(ingestLimit)) {
      count++;
      if (count % 2 == 0) {
        developer.log('Ingesting POI $count / $ingestLimit...', name: _logName);
        developer.log(
          'Ingested $count / $ingestLimit POIs for ${environment.cityId}...',
          name: _logName,
        );
      }

      // Wrap in radioactive payload using the atomic clock timestamp
      final payload = RawCityEventPayload(
        capturedAt: atomicTime.serverTime,
        poi: poi,
      );

      try {
        // Pass through the Air Gap
        final semanticTuples = await _airGapEngine.scrubAndExtract(payload);
        await _knowledgeStore.saveTuples(semanticTuples);
      } catch (e, st) {
        developer.log('Failed to ingest POI ${poi.id}: $e',
            name: _logName, error: e, stackTrace: st);
      }
    }

    developer.log('✅ Baseline ingestion complete for ${environment.cityId}.',
        name: _logName);
  }
}
