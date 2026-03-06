import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/data/database/app_database.dart';
import 'package:avrai_runtime_os/services/passive_collection/battery_adaptive_batch_scheduler.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/pheromone_mesh_routing_service.dart';
import 'package:avrai_knot/services/knot/archetype_pattern_learner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_core/models/personality_knot.dart' as pk;
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';

/// Nightly Digestion Job (Spike 6)
///
/// Runs when the device is idle, charging, and on Wi-Fi.
/// Cycle:
/// 1) Read the day's DwellEvents and Pheromones
/// 2) Run the TupleExtractionEngine (Air Gap) via adapter
/// 3) Update the Archetype Pattern Learner
/// 4) Generate tomorrow's DailySerendipityDrop
class NightlyDigestionJob extends MicroBatchJob {
  static const String _logName = 'NightlyDigestionJob';

  final SmartPassiveCollectionService _collectionService;
  final DwellEventIntakeAdapter _intakeAdapter;
  final AppDatabase _db;
  final PheromoneMeshRoutingService _pheromoneRoutingService;
  final ArchetypePatternLearner _archetypeLearner;
  final LLMService _llmService;
  final SharedPreferences _prefs;

  static const String _latestDropPrefsKey = 'latest_daily_serendipity_drop';

  NightlyDigestionJob(
    this._collectionService,
    this._intakeAdapter,
    this._db,
    this._pheromoneRoutingService,
    this._archetypeLearner,
    this._llmService,
    this._prefs,
  ) : super('nightly_digestion', 'Nightly Batch Digestion and Drop Generation');

  @override
  Future<void> execute() async {
    developer.log('Starting Nightly Digestion Cycle...', name: _logName);

    // 1. Gather Physical Reality Data
    final dwells = _collectionService.flushForBatchProcessing();
    final inboxPheromones =
        _pheromoneRoutingService.flushInboxForBatchProcessing();

    developer.log(
        'Gathered ${dwells.length} Dwells and ${inboxPheromones.length} Pheromones.',
        name: _logName);

    if (dwells.isEmpty && inboxPheromones.isEmpty) {
      developer.log('No new data to digest tonight.', name: _logName);
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

    // 4. Generate Tomorrow's Serendipity Drop via LLM Prompt Chain
    developer.log('Generating Daily Serendipity Drop...', name: _logName);

    final retryContext = retryQueue.isNotEmpty
        ? '\n- User ignored these previous wildcards (Retry Queue): ${jsonEncode(retryQueue.map((e) => e['title']).toList())}\nConsider suggesting one of these AGAIN if the current context (weather, day of week) makes it a better fit now.'
        : '';

    final prompt = '''
You are the local AVRAI intelligence running directly on the user's device.
Your job is to generate exactly 4 personalized serendipity recommendations for tomorrow based on today's physical encounters and learned archetypes.

Today's context:
- User dwelled at ${dwells.length} locations.
- User received ${inboxPheromones.length} pheromones (insights) from nearby devices.
- User's primary resonance archetype has an average crossing number of ${updatedArchetypes.isNotEmpty ? updatedArchetypes.first.avgCrossingNumber : 'unknown'} (indicating their vibe).$retryContext

Generate a strict JSON object with this structure:
{
  "llmContextualInsight": "A 1-sentence friendly insight explaining why these were chosen based on yesterday's encounters.",
  "event": {
    "title": "Event Name",
    "subtitle": "Short description",
    "locationName": "Location",
    "signatureSummary": "Why this fits the user's DNA and live pheromones in one short sentence.",
    "archetypeAffinity": 0.95
  },
  "spot": {
    "title": "Spot Name",
    "subtitle": "Short description",
    "category": "Hidden Cafe",
    "distanceMiles": 1.2,
    "signatureSummary": "Why this spot fits the user's DNA and current pull.",
    "archetypeAffinity": 0.88
  },
  "community": {
    "title": "Community Name",
    "subtitle": "Short description",
    "memberCount": 42,
    "commonInterests": ["Art", "Tech"],
    "signatureSummary": "Why this community matches the user's stable pattern and current season.",
    "archetypeAffinity": 0.92
  },
  "club": {
    "title": "Club Name",
    "subtitle": "Short description",
    "applicationStatus": "Open",
    "vibe": "Chill",
    "signatureSummary": "Why this club is a strong fit right now.",
    "archetypeAffinity": 0.85
  },
  "wildcard": {
    "title": "Orthogonal Wildcard",
    "subtitle": "High friction but high latent match",
    "doubtReasoning": "I know this is weird because you hate mornings, but...",
    "latentVibeMatch": "The underground grunge scene here perfectly matches your DNA.",
    "archetypeAffinity": 0.99
  },
  "latentCommunity": {
    "title": "Latent Vibe Cluster",
    "subtitle": "A group of people matching your DNA is waiting.",
    "discoveredMemberCount": 15,
    "founderPrompt": "Would you like to open the door and officially start this group?",
    "archetypeAffinity": 0.95
  }
}
Respond ONLY with the JSON. No markdown formatting.
''';

    try {
      final jsonSchema = '''
{
  "type": "object",
  "properties": {
    "llmContextualInsight": {"type": "string"},
    "event": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "locationName": {"type": "string"},
        "signatureSummary": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "locationName", "signatureSummary", "archetypeAffinity"]
    },
    "spot": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "category": {"type": "string"},
        "distanceMiles": {"type": "number"},
        "signatureSummary": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "category", "distanceMiles", "signatureSummary", "archetypeAffinity"]
    },
    "community": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "memberCount": {"type": "number"},
        "commonInterests": {
          "type": "array",
          "items": {"type": "string"}
        },
        "signatureSummary": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "memberCount", "commonInterests", "signatureSummary", "archetypeAffinity"]
    },
    "club": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "applicationStatus": {"type": "string"},
        "vibe": {"type": "string"},
        "signatureSummary": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "applicationStatus", "vibe", "signatureSummary", "archetypeAffinity"]
    },
    "wildcard": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "doubtReasoning": {"type": "string"},
        "latentVibeMatch": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "doubtReasoning", "latentVibeMatch", "archetypeAffinity"]
    },
    "latentCommunity": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "subtitle": {"type": "string"},
        "discoveredMemberCount": {"type": "number"},
        "founderPrompt": {"type": "string"},
        "archetypeAffinity": {"type": "number"}
      },
      "required": ["title", "subtitle", "discoveredMemberCount", "founderPrompt", "archetypeAffinity"]
    }
  },
  "required": ["llmContextualInsight", "event", "spot", "community", "club"]
}''';

      final responseStr = await _llmService.chat(
        messages: [ChatMessage(role: ChatRole.user, content: prompt)],
        temperature: 0.7,
        maxTokens: 1000,
        responseFormat: jsonSchema,
      );

      final cleanJson =
          responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final dropData = jsonDecode(cleanJson) as Map<String, dynamic>;

      // Hydrate missing fields needed by DropItem
      dropData['date'] =
          DateTime.now().add(const Duration(days: 1)).toIso8601String();
      dropData['event']['id'] = 'ev_${DateTime.now().millisecondsSinceEpoch}';
      dropData['event']['time'] = DateTime.now()
          .add(const Duration(days: 1, hours: 10))
          .toIso8601String(); // Tomorrow 10am
      dropData['spot']['id'] = 'sp_${DateTime.now().millisecondsSinceEpoch}';
      dropData['community']['id'] =
          'co_${DateTime.now().millisecondsSinceEpoch}';
      dropData['club']['id'] = 'cl_${DateTime.now().millisecondsSinceEpoch}';

      if (dropData.containsKey('wildcard') && dropData['wildcard'] != null) {
        dropData['wildcard']['id'] =
            'wc_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (dropData.containsKey('latentCommunity') &&
          dropData['latentCommunity'] != null) {
        dropData['latentCommunity']['id'] =
            'lc_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Save to SharedPreferences for the UI to load
      await _prefs.setString(_latestDropPrefsKey, jsonEncode(dropData));

      developer.log('Nightly Digestion Complete. New drop generated and saved.',
          name: _logName);
    } catch (e, st) {
      developer.log('Failed to generate Daily Drop',
          error: e, stackTrace: st, name: _logName);
    }
  }
}
