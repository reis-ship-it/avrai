import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_op_v0.dart';

/// A single v0 ledger row (journal entry).
///
/// This maps to `public.ledger_events_v0` in Supabase.
class LedgerEventV0 {
  final String? id;
  final LedgerDomainV0 domain;
  final String ownerUserId;
  final String ownerAgentId;

  final String logicalId;
  final int revision;
  final String? supersedesId;
  final LedgerOpV0 op;

  final String eventType;
  final String? entityType;
  final String? entityId;
  final String? category;
  final String? cityCode;
  final String? localityCode;

  final DateTime occurredAt;
  final String? atomicTimestampId;

  /// Flexible payload. Must be JSON-serializable for Supabase.
  final Map<String, Object?> payload;

  final DateTime? createdAt;

  const LedgerEventV0({
    required this.id,
    required this.domain,
    required this.ownerUserId,
    required this.ownerAgentId,
    required this.logicalId,
    required this.revision,
    required this.supersedesId,
    required this.op,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.category,
    required this.cityCode,
    required this.localityCode,
    required this.occurredAt,
    required this.atomicTimestampId,
    required this.payload,
    required this.createdAt,
  });

  /// Map suitable for `insert()` into `ledger_events_v0`.
  ///
  /// Note: `created_at` is omitted; the database will set it.
  Map<String, Object?> toInsertMap() {
    final normalizedPayload = <String, Object?>{
      // v0 payload stability keys
      'schema_version': 0,
      if (payload.containsKey('source')) 'source': payload['source'],
      if (payload.containsKey('correlation_id'))
        'correlation_id': payload['correlation_id'],
      // everything else
      ...payload,
    };

    return <String, Object?>{
      'domain': domain.wireName,
      'owner_user_id': ownerUserId,
      'owner_agent_id': ownerAgentId,
      'logical_id': logicalId,
      'revision': revision,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      'op': op.wireName,
      'event_type': eventType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (category != null) 'category': category,
      if (cityCode != null) 'city_code': cityCode,
      if (localityCode != null) 'locality_code': localityCode,
      'occurred_at': occurredAt.toIso8601String(),
      if (atomicTimestampId != null) 'atomic_timestamp_id': atomicTimestampId,
      'payload': normalizedPayload,
    };
  }

  static LedgerEventV0 fromSupabaseRow(Map<String, dynamic> row) {
    return LedgerEventV0(
      id: row['id'] as String?,
      domain: LedgerDomainV0X.fromWireName(row['domain'] as String),
      ownerUserId: row['owner_user_id'] as String,
      ownerAgentId: row['owner_agent_id'] as String,
      logicalId: row['logical_id'] as String,
      revision: (row['revision'] as num).toInt(),
      supersedesId: row['supersedes_id'] as String?,
      op: LedgerOpV0X.fromWireName(row['op'] as String),
      eventType: row['event_type'] as String,
      entityType: row['entity_type'] as String?,
      entityId: row['entity_id'] as String?,
      category: row['category'] as String?,
      cityCode: row['city_code'] as String?,
      localityCode: row['locality_code'] as String?,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      atomicTimestampId: row['atomic_timestamp_id'] as String?,
      payload: (row['payload'] as Map?)?.cast<String, Object?>() ?? const {},
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }
}

