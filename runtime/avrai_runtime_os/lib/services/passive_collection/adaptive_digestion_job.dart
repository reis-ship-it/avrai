import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/data/database/app_database.dart';
import 'package:avrai_runtime_os/services/passive_collection/battery_adaptive_batch_scheduler.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/archetype_learning_runtime.dart';
import 'package:avrai_runtime_os/services/transport/mesh/pheromone_mesh_routing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_core/models/personality_knot.dart' as pk;
import 'package:avrai_core/models/feed/daily_serendipity_drop.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/onboarding/bham_daily_drop_builder.dart';

/// Adaptive Digestion Job (Spike 6)
///
/// Runs when the device is idle or otherwise in an optimal batch window.
/// Cycle:
/// 1) Read the day's DwellEvents and Pheromones
/// 2) Run the TupleExtractionEngine (Air Gap) via adapter
/// 3) Update the Archetype Pattern Learner
/// 4) Generate the next DailySerendipityDrop
class AdaptiveDigestionJob extends MicroBatchJob {
  static const String _logName = 'AdaptiveDigestionJob';

  final SmartPassiveCollectionService _collectionService;
  final DwellEventIntakeAdapter _intakeAdapter;
  final AppDatabase _db;
  final PheromoneMeshRoutingService _pheromoneRoutingService;
  final ArchetypeLearningRuntime _archetypeLearner;
  final LanguageRuntimeService _languageRuntimeService;
  final SharedPreferences _prefs;

  static const String _latestDropPrefsKey =
      DailySerendipityDropStorage.latestDropKey;

  AdaptiveDigestionJob(
    this._collectionService,
    this._intakeAdapter,
    this._db,
    this._pheromoneRoutingService,
    this._archetypeLearner,
    this._languageRuntimeService,
    this._prefs,
  ) : super(
          'adaptive_digestion',
          'Adaptive Batch Digestion and Drop Generation',
        );

  @override
  Future<void> execute() async {
    developer.log('Starting adaptive digestion cycle...', name: _logName);

    // 1. Gather Physical Reality Data
    final dwells = _collectionService.flushForBatchProcessing();
    final inboxPheromones =
        _pheromoneRoutingService.flushInboxForBatchProcessing();

    developer.log(
        'Gathered ${dwells.length} Dwells and ${inboxPheromones.length} Pheromones.',
        name: _logName);

    if (dwells.isEmpty && inboxPheromones.isEmpty) {
      developer.log('No new data to digest in this cycle.', name: _logName);
      return;
    }

    // 2. Air Gap Extraction
    developer.log('Routing DwellEvents through the Air Gap...', name: _logName);
    // This internally calls _airGap.scrubAndExtract() via TupleExtractionEngine
    await _intakeAdapter.ingestBatch(dwells);

    // 3. Update the Soul (Archetype Pattern Learner)
    developer.log('Updating Archetype Patterns based on recent encounters...',
        name: _logName);
    // In a full implementation, we'd look at the Knots of people encountered today.
    // For this spike, we simulate deriving archetypes if there were any encounters.
    if (dwells.any((d) => d.encounteredAgentIds.isNotEmpty)) {
      // Simulate positive encounter logic
      final mockEncounter = pk.PersonalityKnot(
        agentId: 'some-encountered-user',
        invariants: pk.KnotInvariants(
          crossingNumber: 12,
          writhe: 2,
          jonesPolynomial: [1.0, -1.0, 1.0],
          alexanderPolynomial: [1.0],
          braidIndex: 2,
          bridgeNumber: 2,
          signature: 0,
          determinant: 1,
        ),
        braidData: [],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      _archetypeLearner.recordPositiveEncounter(mockEncounter);
    }

    final updatedArchetypes = _archetypeLearner.deriveArchetypes();

    // Save archetypes to local DB
    for (final archetype in updatedArchetypes) {
      await _db.upsertArchetype(ArchetypesCompanion.insert(
        id: archetype.label, // Using label as ID for simplicity
        name: archetype.label,
        stateJson: jsonEncode({
          'avgCrossingNumber': archetype.avgCrossingNumber,
          'avgWrithe': archetype.avgWrithe,
          'baseJonesPolynomial': archetype.baseJonesPolynomial,
          'confidenceWeight': archetype.confidenceWeight,
        }),
        lastUpdatedAt: DateTime.now(),
      ));
    }

    // 3.5 Contextual Retry Logic (Spike 2)
    // Check previous drop. If it had a wildcard, add it to the retry queue for consideration.
    developer.log('Evaluating Contextual Retry Queue...', name: _logName);
    List<Map<String, dynamic>> retryQueue = [];
    try {
      final previousDropStr = _prefs.getString(_latestDropPrefsKey);
      final retryQueueStr = _prefs.getString('avrai_retry_queue');

      if (retryQueueStr != null) {
        final List<dynamic> decoded = jsonDecode(retryQueueStr);
        retryQueue = decoded.cast<Map<String, dynamic>>();
      }

      if (previousDropStr != null) {
        final prevDrop = jsonDecode(previousDropStr) as Map<String, dynamic>;
        if (prevDrop.containsKey('wildcard') && prevDrop['wildcard'] != null) {
          // Check if not already in queue to avoid duplicates
          final wildcardTitle = prevDrop['wildcard']['title'];
          if (!retryQueue.any((item) => item['title'] == wildcardTitle)) {
            retryQueue.add(prevDrop['wildcard']);
          }
        }
      }

      // Cap queue size at 5
      if (retryQueue.length > 5) {
        retryQueue = retryQueue.sublist(retryQueue.length - 5);
      }
      await _prefs.setString('avrai_retry_queue', jsonEncode(retryQueue));
    } catch (e) {
      developer.log('Failed to process retry queue: $e', name: _logName);
    }

    // 4. Generate Tomorrow's Serendipity Drop using the canonical BHAM builder.
    developer.log(
      'Generating BHAM 5-slot Daily Drop with ${_languageRuntimeService.runtimeType} available for later enrichments...',
      name: _logName,
    );

    try {
      final builder = BhamDailyDropBuilder();
      final refreshResult = await builder.buildRefreshDrop(
        userId: 'nightly_batch',
        cityName: 'Birmingham',
        context: <String, dynamic>{
          'topic': updatedArchetypes.isNotEmpty
              ? updatedArchetypes.first.label
              : 'local momentum',
          'neighborhood': 'Birmingham',
          'dwellCount': dwells.length,
          'pheromoneCount': inboxPheromones.length,
          'retryQueueSize': retryQueue.length,
        },
      );

      if (refreshResult.isSuccess) {
        developer.log(
          'Adaptive digestion complete. New BHAM drop generated and saved at $_latestDropPrefsKey.',
          name: _logName,
        );
      } else {
        developer.log(
          'Failed to generate canonical BHAM daily drop: ${refreshResult.error}',
          name: _logName,
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to generate BHAM Daily Drop',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }
}
