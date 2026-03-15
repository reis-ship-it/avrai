import 'dart:async';

import 'package:avrai_admin_app/ui/widgets/temporal_kernel_diagnostics_card.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockTemporalKernelAdminService extends Mock
    implements TemporalKernelAdminService {}

void main() {
  group('TemporalKernelDiagnosticsCard', () {
    late GetIt getIt;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    tearDown(() {
      getIt = GetIt.instance;
      if (getIt.isRegistered<TemporalKernelAdminService>()) {
        getIt.unregister<TemporalKernelAdminService>();
      }
    });

    testWidgets('renders unavailable state when service is absent', (
      tester,
    ) async {
      getIt = GetIt.instance;
      if (getIt.isRegistered<TemporalKernelAdminService>()) {
        getIt.unregister<TemporalKernelAdminService>();
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalKernelDiagnosticsCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Temporal Kernel Diagnostics'), findsOneWidget);
      expect(
        find.text('Temporal kernel diagnostics are not registered.'),
        findsOneWidget,
      );
    });

    testWidgets('renders runtime snapshot details when service is present', (
      tester,
    ) async {
      getIt = GetIt.instance;
      final service = MockTemporalKernelAdminService();
      if (getIt.isRegistered<TemporalKernelAdminService>()) {
        getIt.unregister<TemporalKernelAdminService>();
      }
      getIt.registerSingleton<TemporalKernelAdminService>(service);
      when(
        () => service.watchRuntimeEventSnapshot(
          source: any(named: 'source'),
          peerId: any(named: 'peerId'),
          lookbackWindow: any(named: 'lookbackWindow'),
          refreshInterval: any(named: 'refreshInterval'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot(totalEvents: 3)));
      when(
        () => service.getRuntimeEventSnapshot(),
      ).thenAnswer(
        (_) async => _buildSnapshot(totalEvents: 3),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalKernelDiagnosticsCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Temporal Kernel Diagnostics'), findsOneWidget);
      expect(find.text('Events: 3'), findsOneWidget);
      expect(find.text('peer-a'), findsOneWidget);
      expect(
        find.text('No runtime temporal events recorded in the current window.'),
        findsOneWidget,
      );
    });

    testWidgets('updates when the runtime snapshot stream emits',
        (tester) async {
      getIt = GetIt.instance;
      final service = MockTemporalKernelAdminService();
      final controller =
          StreamController<TemporalRuntimeEventSnapshot>.broadcast();
      addTearDown(controller.close);
      if (getIt.isRegistered<TemporalKernelAdminService>()) {
        getIt.unregister<TemporalKernelAdminService>();
      }
      getIt.registerSingleton<TemporalKernelAdminService>(service);
      when(
        () => service.watchRuntimeEventSnapshot(
          source: any(named: 'source'),
          peerId: any(named: 'peerId'),
          lookbackWindow: any(named: 'lookbackWindow'),
          refreshInterval: any(named: 'refreshInterval'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => controller.stream);
      when(
        () => service.getRuntimeEventSnapshot(),
      ).thenAnswer(
          (_) async => _buildSnapshot(totalEvents: 1, peerId: 'peer-a'));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemporalKernelDiagnosticsCard(),
          ),
        ),
      );

      controller.add(_buildSnapshot(totalEvents: 5, peerId: 'peer-z'));
      await tester.pumpAndSettle();

      expect(find.text('Events: 5'), findsOneWidget);
      expect(find.text('peer-z'), findsOneWidget);
    });
  });
}

TemporalRuntimeEventSnapshot _buildSnapshot({
  required int totalEvents,
  String peerId = 'peer-a',
}) {
  return TemporalRuntimeEventSnapshot(
    generatedAt: DateTime.utc(2026, 3, 6, 12),
    windowStart: DateTime.utc(2026, 3, 6, 11, 45),
    windowEnd: DateTime.utc(2026, 3, 6, 12),
    totalEvents: totalEvents,
    encodedCount: 1,
    decodedCount: 0,
    bufferedCount: 1,
    orderedCount: 1,
    uniquePeerCount: 2,
    latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
    recentEvents: const [],
    topPeers: [
      TemporalRuntimeEventPeerSummary(
        peerId: peerId,
        eventCount: 2,
        orderedCount: 1,
        bufferedCount: 1,
        latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
      ),
    ],
  );
}
