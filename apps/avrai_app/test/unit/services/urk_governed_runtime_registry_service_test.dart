import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('UrkGovernedRuntimeRegistryService', () {
    late SharedPreferencesCompat prefs;
    late UrkGovernedRuntimeRegistryService service;

    setUp(() async {
      await cleanupTestStorage();
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'urk_governed_runtime_registry_test'),
      );
      service = UrkGovernedRuntimeRegistryService(prefs: prefs);
    });

    test('upserts and retrieves governed runtime bindings', () async {
      await service.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: 'runtime-world-1',
          stratum: GovernanceStratum.world,
          userId: 'user-1',
          aiSignature: 'ai_sig_1',
          agentId: 'agent-1',
          source: 'manual_test',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: DateTime.utc(2026, 3, 6, 12),
          ),
        ),
      );

      final binding = await service.getBinding('runtime-world-1');
      expect(binding, isNotNull);
      expect(binding!.userId, 'user-1');
      expect(binding.aiSignature, 'ai_sig_1');
      expect(binding.source, 'manual_test');
    });

    test('returns recent bindings in descending timestamp order', () async {
      await service.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: 'runtime-a',
          stratum: GovernanceStratum.personal,
          userId: 'user-a',
          aiSignature: 'ai-a',
          agentId: 'agent-a',
          source: 'older',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: DateTime.utc(2026, 3, 6, 10),
          ),
        ),
      );
      await service.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: 'runtime-b',
          stratum: GovernanceStratum.personal,
          userId: 'user-b',
          aiSignature: 'ai-b',
          agentId: 'agent-b',
          source: 'newer',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: DateTime.utc(2026, 3, 6, 11),
          ),
        ),
      );

      final bindings = await service.listBindings(
        limit: 10,
        stratum: GovernanceStratum.personal,
      );
      expect(bindings, hasLength(2));
      expect(bindings.first.runtimeId, 'runtime-b');
      expect(bindings.last.runtimeId, 'runtime-a');
    });
  });
}
