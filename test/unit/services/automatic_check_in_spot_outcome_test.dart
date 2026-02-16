import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/reservation/automatic_check_in_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AutomaticCheckInService spot outcomes', () {
    late AutomaticCheckInService service;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      final sl = GetIt.instance;
      if (sl.isRegistered<EpisodicMemoryStore>()) {
        sl.unregister<EpisodicMemoryStore>();
      }
      sl.registerSingleton<EpisodicMemoryStore>(EpisodicMemoryStore());
      service = AutomaticCheckInService();
    });

    tearDown(() async {
      final sl = GetIt.instance;
      if (sl.isRegistered<EpisodicMemoryStore>()) {
        await sl<EpisodicMemoryStore>().clearForTesting();
        sl.unregister<EpisodicMemoryStore>();
      }
      TestHelpers.teardownTestEnvironment();
    });

    test('records single then return visit_spot outcomes for same spot',
        () async {
      final first = await service.handleGeofenceTrigger(
        userId: 'user-spot-outcome-1',
        locationId: 'spot-loc-1',
        latitude: 40.7128,
        longitude: -74.0060,
      );
      await service.checkOut(
        userId: 'user-spot-outcome-1',
        checkOutTime: first.checkInTime.add(const Duration(minutes: 8)),
      );

      final second = await service.handleGeofenceTrigger(
        userId: 'user-spot-outcome-1',
        locationId: 'spot-loc-1',
        latitude: 40.7128,
        longitude: -74.0060,
      );
      await service.checkOut(
        userId: 'user-spot-outcome-1',
        checkOutTime: second.checkInTime.add(const Duration(minutes: 12)),
      );

      final rows = await GetIt.instance<EpisodicMemoryStore>()
          .getRecent(agentId: 'user-spot-outcome-1');
      final spotRows =
          rows.where((row) => row.actionType == 'visit_spot').toList();

      expect(spotRows.length, greaterThanOrEqualTo(2));
      expect(spotRows.last.outcome.type, equals('single_visit_only'));
      expect(spotRows.first.outcome.type, equals('return_visit_within_days'));
      expect(
        spotRows.first.actionPayload['spot_features']['source'],
        equals('automatic_check_in'),
      );
    });
  });
}
