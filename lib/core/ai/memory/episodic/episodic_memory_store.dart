import 'dart:convert';

import 'package:avrai/data/database/app_database.dart';
import 'package:drift/drift.dart';

import 'episodic_tuple.dart';

class EpisodicWriteResult {
  final bool inserted;
  final String tupleHash;

  const EpisodicWriteResult({
    required this.inserted,
    required this.tupleHash,
  });
}

/// Phase 1.1 episodic store with SQLite schema via Drift runtime.
///
/// This service intentionally uses `customStatement/customSelect` to avoid
/// generated table churn while the schema stabilizes.
class EpisodicMemoryStore {
  static const String _tableName = 'episodic_memory_v1';

  final AppDatabase? _database;
  final Map<String, EpisodicTuple> _inMemoryFallback = {};
  bool _initialized = false;

  EpisodicMemoryStore({
    AppDatabase? database,
  }) : _database = database;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_database != null) {
      await _database.customStatement('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tuple_hash TEXT NOT NULL UNIQUE,
          schema_version INTEGER NOT NULL,
          agent_id TEXT NOT NULL,
          action_type TEXT NOT NULL,
          outcome_type TEXT NOT NULL,
          outcome_category TEXT NOT NULL,
          outcome_weight REAL NOT NULL,
          state_before_json TEXT NOT NULL,
          action_payload_json TEXT NOT NULL,
          next_state_json TEXT NOT NULL,
          metadata_json TEXT NOT NULL,
          recorded_at TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await _database.customStatement('''
        CREATE INDEX IF NOT EXISTS idx_episodic_agent_time
        ON $_tableName(agent_id, recorded_at DESC)
      ''');
      await _database.customStatement('''
        CREATE INDEX IF NOT EXISTS idx_episodic_action_time
        ON $_tableName(action_type, recorded_at DESC)
      ''');
    }
    _initialized = true;
  }

  Future<EpisodicWriteResult> writeTuple(EpisodicTuple tuple) async {
    await initialize();
    if (_database == null) {
      final existed = _inMemoryFallback.containsKey(tuple.tupleHash);
      if (!existed) {
        _inMemoryFallback[tuple.tupleHash] = tuple;
      }
      return EpisodicWriteResult(
          inserted: !existed, tupleHash: tuple.tupleHash);
    }

    await _database.customStatement(
      '''
      INSERT OR IGNORE INTO $_tableName (
        tuple_hash,
        schema_version,
        agent_id,
        action_type,
        outcome_type,
        outcome_category,
        outcome_weight,
        state_before_json,
        action_payload_json,
        next_state_json,
        metadata_json,
        recorded_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        tuple.tupleHash,
        tuple.schemaVersion,
        tuple.agentId,
        tuple.actionType,
        tuple.outcome.type,
        tuple.outcome.category.name,
        tuple.outcome.value,
        jsonEncode(tuple.stateBefore),
        jsonEncode(tuple.actionPayload),
        jsonEncode(tuple.nextState),
        jsonEncode(tuple.metadata),
        tuple.recordedAt.toUtc().toIso8601String(),
      ],
    );

    final insertedCount = await _database.customSelect(
      'SELECT changes() AS inserted',
      readsFrom: const {},
    ).getSingle();
    final inserted = insertedCount.read<int>('inserted') == 1;
    return EpisodicWriteResult(inserted: inserted, tupleHash: tuple.tupleHash);
  }

  Future<int> count({String? agentId}) async {
    await initialize();
    final database = _database;
    if (database == null) {
      if (agentId == null) return _inMemoryFallback.length;
      return _inMemoryFallback.values.where((t) => t.agentId == agentId).length;
    }

    final hasAgent = agentId != null && agentId.isNotEmpty;
    final result = await database.customSelect(
      hasAgent
          ? 'SELECT COUNT(*) AS c FROM $_tableName WHERE agent_id = ?'
          : 'SELECT COUNT(*) AS c FROM $_tableName',
      variables: hasAgent ? [Variable<String>(agentId)] : const [],
      readsFrom: const {},
    ).getSingle();
    return result.read<int>('c');
  }

  Future<List<EpisodicTuple>> getRecent({
    String? agentId,
    int limit = 100,
  }) async {
    await initialize();
    final database = _database;
    if (database == null) {
      final rows = _inMemoryFallback.values.where((tuple) {
        if (agentId == null) return true;
        return tuple.agentId == agentId;
      }).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return rows.take(limit).toList(growable: false);
    }

    final hasAgent = agentId != null && agentId.isNotEmpty;
    final query = hasAgent
        ? '''
          SELECT * FROM $_tableName
          WHERE agent_id = ?
          ORDER BY recorded_at DESC
          LIMIT ?
        '''
        : '''
          SELECT * FROM $_tableName
          ORDER BY recorded_at DESC
          LIMIT ?
        ''';
    final vars = hasAgent
        ? <Variable<Object>>[
            Variable<String>(agentId),
            Variable<int>(limit),
          ]
        : <Variable<Object>>[Variable<int>(limit)];
    final rows = await database.customSelect(
      query,
      variables: vars,
      readsFrom: const {},
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  /// Replay tuples oldest -> newest for deterministic training.
  Future<List<EpisodicTuple>> replay({
    required String agentId,
    DateTime? afterExclusive,
    int limit = 500,
  }) async {
    await initialize();
    final database = _database;
    if (database == null) {
      final rows = _inMemoryFallback.values
          .where((t) => t.agentId == agentId)
          .where((t) =>
              afterExclusive == null || t.recordedAt.isAfter(afterExclusive))
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      return rows.take(limit).toList(growable: false);
    }

    final useCursor = afterExclusive != null;
    final rows = await database.customSelect(
      useCursor
          ? '''
            SELECT * FROM $_tableName
            WHERE agent_id = ? AND recorded_at > ?
            ORDER BY recorded_at ASC
            LIMIT ?
          '''
          : '''
            SELECT * FROM $_tableName
            WHERE agent_id = ?
            ORDER BY recorded_at ASC
            LIMIT ?
          ''',
      variables: useCursor
          ? <Variable<Object>>[
              Variable<String>(agentId),
              Variable<String>(afterExclusive.toUtc().toIso8601String()),
              Variable<int>(limit),
            ]
          : <Variable<Object>>[
              Variable<String>(agentId),
              Variable<int>(limit),
            ],
      readsFrom: const {},
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  /// Replay tuples within a bounded window, oldest -> newest.
  Future<List<EpisodicTuple>> replayWindow({
    required String agentId,
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
    int limit = 500,
  }) async {
    await initialize();
    final database = _database;
    if (database == null) {
      final rows = _inMemoryFallback.values
          .where((t) => t.agentId == agentId)
          .where((t) => !t.recordedAt.isBefore(windowStartInclusive))
          .where((t) => t.recordedAt.isBefore(windowEndExclusive))
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      return rows.take(limit).toList(growable: false);
    }

    final rows = await database.customSelect(
      '''
      SELECT * FROM $_tableName
      WHERE agent_id = ? AND recorded_at >= ? AND recorded_at < ?
      ORDER BY recorded_at ASC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[
        Variable<String>(agentId),
        Variable<String>(windowStartInclusive.toUtc().toIso8601String()),
        Variable<String>(windowEndExclusive.toUtc().toIso8601String()),
        Variable<int>(limit),
      ],
      readsFrom: const {},
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  /// Query by action/outcome relevance for training sample selection.
  Future<List<EpisodicTuple>> queryRelevant({
    required String agentId,
    String? actionType,
    String? outcomeCategory,
    double? minOutcomeValue,
    int limit = 100,
  }) async {
    await initialize();
    final database = _database;
    if (database == null) {
      final rows = _inMemoryFallback.values.where((t) {
        if (t.agentId != agentId) return false;
        if (actionType != null && t.actionType != actionType) return false;
        if (outcomeCategory != null &&
            t.outcome.category.name != outcomeCategory) {
          return false;
        }
        if (minOutcomeValue != null && t.outcome.value < minOutcomeValue) {
          return false;
        }
        return true;
      }).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return rows.take(limit).toList(growable: false);
    }

    final query = StringBuffer('''
      SELECT * FROM $_tableName
      WHERE agent_id = ?
    ''');
    final vars = <Variable<Object>>[Variable<String>(agentId)];
    if (actionType != null && actionType.isNotEmpty) {
      query.write(' AND action_type = ?');
      vars.add(Variable<String>(actionType));
    }
    if (outcomeCategory != null && outcomeCategory.isNotEmpty) {
      query.write(' AND outcome_category = ?');
      vars.add(Variable<String>(outcomeCategory));
    }
    if (minOutcomeValue != null) {
      query.write(' AND outcome_weight >= ?');
      vars.add(Variable<double>(minOutcomeValue));
    }
    query.write(' ORDER BY recorded_at DESC LIMIT ?');
    vars.add(Variable<int>(limit));

    final rows = await database.customSelect(
      query.toString(),
      variables: vars,
      readsFrom: const {},
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  Future<void> clearForTesting() async {
    await initialize();
    _inMemoryFallback.clear();
    if (_database != null) {
      await _database.customStatement('DELETE FROM $_tableName');
    }
  }

  EpisodicTuple _mapRow(QueryRow row) {
    return EpisodicTuple.fromJson({
      'schema_version': row.read<int>('schema_version'),
      'tuple_hash': row.read<String>('tuple_hash'),
      'agent_id': row.read<String>('agent_id'),
      'state_before': jsonDecode(row.read<String>('state_before_json')),
      'action_type': row.read<String>('action_type'),
      'action_payload': jsonDecode(row.read<String>('action_payload_json')),
      'next_state': jsonDecode(row.read<String>('next_state_json')),
      'outcome': {
        'type': row.read<String>('outcome_type'),
        'category': row.read<String>('outcome_category'),
        'value': row.read<double>('outcome_weight'),
        'metadata': {},
      },
      'recorded_at': row.read<String>('recorded_at'),
      'metadata': jsonDecode(row.read<String>('metadata_json')),
    });
  }
}
