import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'outcome_taxonomy.dart';

/// Canonical `(state_before, action, next_state, outcome)` record.
class EpisodicTuple {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String tupleHash;
  final String agentId;
  final Map<String, dynamic> stateBefore;
  final String actionType;
  final Map<String, dynamic> actionPayload;
  final Map<String, dynamic> nextState;
  final OutcomeSignal outcome;
  final DateTime recordedAt;
  final Map<String, dynamic> metadata;

  EpisodicTuple({
    required this.agentId,
    required this.stateBefore,
    required this.actionType,
    required this.actionPayload,
    required this.nextState,
    required this.outcome,
    DateTime? recordedAt,
    this.metadata = const {},
    int? schemaVersion,
    String? tupleHash,
  })  : schemaVersion = schemaVersion ?? currentSchemaVersion,
        recordedAt = recordedAt ?? DateTime.now().toUtc(),
        tupleHash = tupleHash ??
            _computeTupleHash(
              agentId: agentId,
              stateBefore: stateBefore,
              actionType: actionType,
              actionPayload: actionPayload,
              nextState: nextState,
              outcome: outcome,
              recordedAt: recordedAt ?? DateTime.now().toUtc(),
            );

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'tuple_hash': tupleHash,
      'agent_id': agentId,
      'state_before': stateBefore,
      'action_type': actionType,
      'action_payload': actionPayload,
      'next_state': nextState,
      'outcome': outcome.toJson(),
      'recorded_at': recordedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory EpisodicTuple.fromJson(Map<String, dynamic> json) {
    return EpisodicTuple(
      schemaVersion: (json['schema_version'] as num?)?.toInt(),
      tupleHash: json['tuple_hash'] as String?,
      agentId: json['agent_id'] as String? ?? '',
      stateBefore: Map<String, dynamic>.from(
        json['state_before'] as Map? ?? const <String, dynamic>{},
      ),
      actionType: json['action_type'] as String? ?? 'unknown_action',
      actionPayload: Map<String, dynamic>.from(
        json['action_payload'] as Map? ?? const <String, dynamic>{},
      ),
      nextState: Map<String, dynamic>.from(
        json['next_state'] as Map? ?? const <String, dynamic>{},
      ),
      outcome: OutcomeSignal.fromJson(
        Map<String, dynamic>.from(
          json['outcome'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? ''),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  static String _computeTupleHash({
    required String agentId,
    required Map<String, dynamic> stateBefore,
    required String actionType,
    required Map<String, dynamic> actionPayload,
    required Map<String, dynamic> nextState,
    required OutcomeSignal outcome,
    required DateTime recordedAt,
  }) {
    final canonical = <String, dynamic>{
      'agent_id': agentId,
      'state_before': _canonicalize(stateBefore),
      'action_type': actionType,
      'action_payload': _canonicalize(actionPayload),
      'next_state': _canonicalize(nextState),
      'outcome': _canonicalize(outcome.toJson()),
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(canonical)));
    return digest.toString();
  }

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return {
        for (final entry in entries)
          entry.key.toString(): _canonicalize(entry.value),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}
