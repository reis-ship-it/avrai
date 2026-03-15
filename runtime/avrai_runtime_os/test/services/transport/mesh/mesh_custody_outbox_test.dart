import 'dart:convert';

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshCustodyOutbox', () {
    test('seals persisted payloads and removes entries on custody release',
        () async {
      final store = _InspectableMeshRuntimeStateStore();
      final outbox = MeshCustodyOutbox(
        store: store,
        nowUtc: () => DateTime.utc(2026, 3, 12, 20),
        defaultRetryBackoff: const Duration(minutes: 1),
      );

      final entry = await outbox.enqueue(
        receiptId: 'receipt-1',
        destinationId: 'dest-alpha',
        payloadKind: 'locality_agent_update',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{
          'kind': 'locality_agent_update',
          'secret': 'private-node-state',
        },
        payloadContext: const <String, dynamic>{
          'hop': 1,
          'context_secret': 'only-for-replay',
        },
        sourceRouteReceipt: TransportRouteReceipt(
          receiptId: 'receipt-1',
          channel: 'mesh_ble_forward',
          status: 'planned',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 20),
        ),
        geographicScope: 'locality',
      );

      expect(outbox.pendingCount(destinationId: 'dest-alpha'), 1);

      final persistedEntries =
          store.read<List<dynamic>>('mesh_custody_outbox_entries_v1');
      expect(persistedEntries, isNotNull);
      final encodedStore = jsonEncode(persistedEntries);
      expect(encodedStore.contains('private-node-state'), isFalse);
      expect(encodedStore.contains('only-for-replay'), isFalse);
      final persistedEntry =
          Map<String, dynamic>.from(persistedEntries!.single as Map);
      expect(persistedEntry.containsKey('payload'), isFalse);
      expect(persistedEntry.containsKey('payload_context'), isFalse);
      expect(persistedEntry['encrypted_payload_blob'], isA<String>());

      await outbox.markRetry(
        entryId: entry.entryId,
        reason: 'no_mesh_candidates_available',
        backoff: const Duration(minutes: 5),
        nowUtc: DateTime.utc(2026, 3, 12, 20, 1),
      );

      final dueSoon = outbox.dueEntries(
        destinationId: 'dest-alpha',
        nowUtc: DateTime.utc(2026, 3, 12, 20, 2),
      );
      expect(dueSoon, isEmpty);

      final dueLater = outbox.dueEntries(
        destinationId: 'dest-alpha',
        nowUtc: DateTime.utc(2026, 3, 12, 20, 6),
      );
      expect(dueLater, hasLength(1));
      expect(dueLater.single.attemptCount, 1);
      expect(dueLater.single.lastFailureReason, 'no_mesh_candidates_available');
      final materialized = await outbox.materialize(dueLater.single);
      expect(materialized.payload['secret'], 'private-node-state');
      expect(materialized.payloadContext['context_secret'], 'only-for-replay');

      await outbox.markReleased(entry.entryId);
      expect(outbox.pendingCount(destinationId: 'dest-alpha'), 0);
    });

    test('materialize migrates legacy plaintext entries to sealed storage',
        () async {
      final store = _InspectableMeshRuntimeStateStore(<String, dynamic>{
        'mesh_custody_outbox_entries_v1': <dynamic>[
          <String, dynamic>{
            'entry_id': 'legacy-entry',
            'receipt_id': 'legacy-receipt',
            'destination_id': 'dest-legacy',
            'payload_kind': 'organic_spot_discovery',
            'channel': 'mesh_ble_forward',
            'payload': <String, dynamic>{
              'geohash': '9q4xy',
              'secret': 'legacy-secret',
            },
            'payload_context': <String, dynamic>{
              'context_secret': 'legacy-context',
            },
            'queued_at_utc': DateTime.utc(2026, 3, 12, 20).toIso8601String(),
            'next_attempt_at_utc':
                DateTime.utc(2026, 3, 12, 20).toIso8601String(),
            'attempt_count': 0,
          },
        ],
      });
      final outbox = MeshCustodyOutbox(
        store: store,
        nowUtc: () => DateTime.utc(2026, 3, 12, 20),
      );

      final dueEntry = outbox.dueEntries(destinationId: 'dest-legacy').single;
      final materialized = await outbox.materialize(dueEntry);

      expect(materialized.payload['secret'], 'legacy-secret');
      expect(materialized.payloadContext['context_secret'], 'legacy-context');

      final persistedEntries =
          store.read<List<dynamic>>('mesh_custody_outbox_entries_v1');
      final persistedEntry =
          Map<String, dynamic>.from(persistedEntries!.single as Map);
      expect(persistedEntry.containsKey('payload'), isFalse);
      expect(persistedEntry.containsKey('payload_context'), isFalse);
      expect(persistedEntry['encrypted_payload_blob'], isA<String>());
      final encodedStore = jsonEncode(persistedEntries);
      expect(encodedStore.contains('legacy-secret'), isFalse);
      expect(encodedStore.contains('legacy-context'), isFalse);
    });
  });
}

class _InspectableMeshRuntimeStateStore implements MeshRuntimeStateStore {
  _InspectableMeshRuntimeStateStore([Map<String, dynamic>? initialState])
      : _state = initialState ?? <String, dynamic>{};

  final Map<String, dynamic> _state;

  @override
  T? read<T>(String key) => _state[key] as T?;

  @override
  Future<void> remove(String key) async {
    _state.remove(key);
  }

  @override
  Future<void> write(String key, dynamic value) async {
    _state[key] = value;
  }
}
