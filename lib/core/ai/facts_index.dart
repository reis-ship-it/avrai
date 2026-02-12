import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/ai/facts_local_store.dart';
import 'package:avrai/core/ai/structured_facts.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Facts Index
/// 
/// Indexes and retrieves structured facts from Supabase database.
/// Provides methods to store and retrieve facts for LLM context preparation.
/// Phase 11 Section 5: Retrieval + LLM Fusion
class FactsIndex {
  static const String _logName = 'FactsIndex';
  
  final SupabaseClient supabase;
  final AgentIdService _agentIdService;

  /// Optional local store for offline-first facts persistence.
  /// When provided, facts are written locally first and synced to cloud later.
  /// TODO(Phase 11.5): Offline-first facts architecture per Master Plan.
  final FactsLocalStore? _localStore;

  /// Optional connectivity checker for offline-first behavior.
  /// When provided with [_localStore], enables offline indexing/retrieval.
  final Connectivity? _connectivity;
  
  FactsIndex({
    required this.supabase,
    AgentIdService? agentIdService,
    FactsLocalStore? localStore,
    Connectivity? connectivity,
  }) : _agentIdService = agentIdService ?? di.sl<AgentIdService>(),
       _localStore = localStore,
       _connectivity = connectivity;
  
  /// Whether the device is currently offline.
  ///
  /// Returns `false` when no [Connectivity] was provided (assumes online).
  Future<bool> _isOffline() async {
    if (_connectivity == null) return false;
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  /// Index structured facts for a user (by userId, converts to agentId internally)
  /// 
  /// [userId] - Authenticated user ID
  /// [facts] - StructuredFacts to index
  /// Merges with existing facts if they exist.
  /// When a local store is available, writes locally first and queues a sync.
  /// When offline, skips Supabase entirely.
  Future<void> indexFacts({
    required String userId,
    required StructuredFacts facts,
  }) async {
    try {
      developer.log('Indexing facts for user: $userId', name: _logName);
      
      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // --- Local-first path ---
      if (_localStore != null) {
        final existing = await _localStore.get(agentId);
        final mergedFacts = existing != null ? existing.merge(facts) : facts;
        await _localStore.upsert(agentId, mergedFacts);
        await _localStore.addPending(agentId);

        if (await _isOffline()) {
          developer.log(
            'Offline: indexed facts locally for $userId',
            name: _logName,
          );
          return;
        }
      }

      // --- Cloud path (online or no local store) ---
      // Get existing facts (if any)
      final existingFacts = await _getExistingFacts(agentId);
      
      // Merge with existing facts
      final mergedFacts = existingFacts != null
          ? existingFacts.merge(facts)
          : facts;
      
      // Upsert merged facts
      await supabase
          .from('structured_facts')
          .upsert({
            'agent_id': agentId,
            'traits': mergedFacts.traits,
            'places': mergedFacts.places,
            'social_graph': mergedFacts.socialGraph,
            'timestamp': mergedFacts.timestamp.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'agent_id');
      
      developer.log(
        '✅ Facts indexed: ${mergedFacts.traits.length} traits, ${mergedFacts.places.length} places, ${mergedFacts.socialGraph.length} social connections',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error indexing facts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Retrieve indexed facts for LLM context (by userId, converts to agentId internally)
  /// 
  /// [userId] - Authenticated user ID
  /// Returns StructuredFacts if found, empty facts otherwise.
  /// Prefers local store when available and offline.
  Future<StructuredFacts> retrieveFacts({required String userId}) async {
    try {
      developer.log('Retrieving facts for user: $userId', name: _logName);
      
      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // --- Local-first path ---
      if (_localStore != null) {
        final local = await _localStore.get(agentId);
        if (local != null) {
          developer.log(
            '✅ Facts retrieved from local store: ${local.traits.length} traits',
            name: _logName,
          );
          return local;
        }
        if (await _isOffline()) {
          developer.log('No local facts for user: $userId (offline)', name: _logName);
          return StructuredFacts.empty();
        }
      }

      // --- Cloud path ---
      final result = await supabase
          .from('structured_facts')
          .select('*')
          .eq('agent_id', agentId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (result == null) {
        developer.log('No facts found for user: $userId', name: _logName);
        return StructuredFacts.empty();
      }
      
      final facts = StructuredFacts(
        traits: List<String>.from(result['traits'] ?? []),
        places: List<String>.from(result['places'] ?? []),
        socialGraph: List<String>.from(result['social_graph'] ?? []),
        timestamp: DateTime.parse(result['timestamp'] as String),
      );
      
      developer.log(
        '✅ Facts retrieved: ${facts.traits.length} traits, ${facts.places.length} places, ${facts.socialGraph.length} social connections',
        name: _logName,
      );
      
      return facts;
    } catch (e, stackTrace) {
      developer.log(
        'Error retrieving facts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty facts on error
      return StructuredFacts.empty();
    }
  }
  
  /// Get existing facts from database (internal helper)
  Future<StructuredFacts?> _getExistingFacts(String agentId) async {
    try {
      final result = await supabase
          .from('structured_facts')
          .select('*')
          .eq('agent_id', agentId)
          .maybeSingle();
      
      if (result == null) {
        return null;
      }
      
      return StructuredFacts(
        traits: List<String>.from(result['traits'] ?? []),
        places: List<String>.from(result['places'] ?? []),
        socialGraph: List<String>.from(result['social_graph'] ?? []),
        timestamp: DateTime.parse(result['timestamp'] as String),
      );
    } catch (e) {
      developer.log('Error getting existing facts: $e', name: _logName);
      return null;
    }
  }
  
  /// Clear facts for a user (by userId, converts to agentId internally)
  /// 
  /// [userId] - Authenticated user ID
  /// Also removes local store data and pending sync entry when available.
  Future<void> clearFacts({required String userId}) async {
    try {
      developer.log('Clearing facts for user: $userId', name: _logName);
      
      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // --- Clear local store ---
      if (_localStore != null) {
        await _localStore.remove(agentId);
        await _localStore.removePending(agentId);
      }

      if (await _isOffline()) {
        developer.log('✅ Facts cleared locally for user: $userId (offline)', name: _logName);
        return;
      }

      // --- Clear cloud ---
      await supabase
          .from('structured_facts')
          .delete()
          .eq('agent_id', agentId);
      
      developer.log('✅ Facts cleared for user: $userId', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error clearing facts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sync locally-queued facts to Supabase.
  ///
  /// No-op when offline or when no local store is configured.
  /// Processes all pending agent IDs and pushes their facts to the cloud.
  Future<void> syncToCloud() async {
    if (_localStore == null) return;
    if (await _isOffline()) {
      developer.log('syncToCloud skipped: offline', name: _logName);
      return;
    }

    final pending = _localStore.getPending();
    if (pending.isEmpty) return;

    developer.log('Syncing ${pending.length} pending facts to cloud', name: _logName);

    for (final agentId in List<String>.from(pending)) {
      try {
        final facts = await _localStore.get(agentId);
        if (facts == null) {
          await _localStore.removePending(agentId);
          continue;
        }

        await supabase
            .from('structured_facts')
            .upsert({
              'agent_id': agentId,
              'traits': facts.traits,
              'places': facts.places,
              'social_graph': facts.socialGraph,
              'timestamp': facts.timestamp.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'agent_id');

        await _localStore.removePending(agentId);
        developer.log('✅ Synced facts for agent: $agentId', name: _logName);
      } catch (e, stackTrace) {
        developer.log(
          'Error syncing facts for agent $agentId: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Leave in pending queue for retry
      }
    }
  }
}
