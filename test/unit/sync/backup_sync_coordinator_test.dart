import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/sync/backup_sync_coordinator.dart';
import 'package:avrai/core/services/network/enhanced_connectivity_service.dart';

class MockEnhancedConnectivityService extends Mock
    implements EnhancedConnectivityService {}

void main() {
  late BackupSyncCoordinator coordinator;
  late MockEnhancedConnectivityService mockConnectivity;
  final backOnlineController = StreamController<void>.broadcast();

  setUpAll(() {
    registerFallbackValue(const Duration());
  });

  setUp(() async {
    mockConnectivity = MockEnhancedConnectivityService();
    when(() => mockConnectivity.onBackOnline).thenAnswer((_) {
      return backOnlineController.stream;
    });
    when(() => mockConnectivity.hasInternetAccess())
        .thenAnswer((_) async => false);
    coordinator = BackupSyncCoordinator(connectivityService: mockConnectivity);
  });

  tearDown(() {
    if (!backOnlineController.isClosed) {
      backOnlineController.close();
    }
    if (GetIt.instance.isRegistered<BackupSyncCoordinator>()) {
      GetIt.instance.unregister<BackupSyncCoordinator>();
    }
  });

  group('BackupSyncCoordinator', () {
    test('start subscribes to onBackOnline and runs sync once if online',
        () async {
      when(() => mockConnectivity.hasInternetAccess())
          .thenAnswer((_) async => true);
      await coordinator.start();
      verify(() => mockConnectivity.onBackOnline).called(1);
      verify(() => mockConnectivity.hasInternetAccess()).called(1);
    });

    test('start does not run sync if offline', () async {
      when(() => mockConnectivity.hasInternetAccess())
          .thenAnswer((_) async => false);
      await coordinator.start();
      verify(() => mockConnectivity.hasInternetAccess()).called(1);
    });

    test('runSync completes without throwing when no sync services registered',
        () async {
      await coordinator.runSync();
    });

    test('stop cancels subscription', () async {
      when(() => mockConnectivity.hasInternetAccess())
          .thenAnswer((_) async => false);
      await coordinator.start();
      coordinator.stop();
      coordinator.stop();
      verify(() => mockConnectivity.onBackOnline).called(1);
    });
  });
}
