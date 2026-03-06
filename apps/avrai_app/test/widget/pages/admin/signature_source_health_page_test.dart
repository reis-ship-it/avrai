import 'dart:async';

import 'package:avrai/apps/admin_app/ui/pages/signature_source_health_page.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSignatureHealthAdminService extends Mock
    implements SignatureHealthAdminService {}

void main() {
  group('SignatureSourceHealthPage', () {
    late GetIt getIt;
    late MockSignatureHealthAdminService service;
    late StreamController<SignatureHealthSnapshot> controller;

    final snapshot = SignatureHealthSnapshot(
      generatedAt: DateTime(2026, 3, 6),
      overview: const SignatureHealthOverview(
        strongCount: 1,
        weakDataCount: 1,
        staleCount: 0,
        fallbackCount: 1,
        reviewNeededCount: 0,
        bundleCount: 0,
        softIgnoreCount: 0,
        hardNotInterestedCount: 0,
      ),
      reviewQueueCount: 2,
      records: const <SignatureHealthRecord>[
        SignatureHealthRecord(
          sourceId: 'source-1',
          provider: 'eventbrite',
          entityType: 'event',
          categoryLabel: 'music',
          sourceLabel: 'Source One',
          confidence: 0.91,
          freshness: 0.83,
          fallbackRate: 0.0,
          reviewNeeded: false,
          syncState: 'active',
          healthCategory: SignatureHealthCategory.strong,
          summary: 'Strong source summary.',
        ),
        SignatureHealthRecord(
          sourceId: 'source-2',
          provider: 'manual',
          entityType: 'spot',
          categoryLabel: 'coffee',
          sourceLabel: 'Source Two',
          confidence: 0.52,
          freshness: 0.71,
          fallbackRate: 0.2,
          reviewNeeded: false,
          syncState: 'active',
          healthCategory: SignatureHealthCategory.fallback,
          summary: 'Fallback source summary.',
        ),
      ],
    );

    setUp(() {
      getIt = GetIt.instance;
      service = MockSignatureHealthAdminService();
      controller = StreamController<SignatureHealthSnapshot>.broadcast();

      if (getIt.isRegistered<SignatureHealthAdminService>()) {
        getIt.unregister<SignatureHealthAdminService>();
      }
      getIt.registerSingleton<SignatureHealthAdminService>(service);

      when(() => service.watchSnapshot()).thenAnswer((_) => controller.stream);
      when(() => service.getSnapshot()).thenAnswer((_) async => snapshot);
    });

    tearDown(() async {
      await controller.close();
      if (getIt.isRegistered<SignatureHealthAdminService>()) {
        getIt.unregister<SignatureHealthAdminService>();
      }
    });

    testWidgets('renders live signature health sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignatureSourceHealthPage(),
        ),
      );

      controller.add(snapshot);
      await tester.pumpAndSettle();

      expect(find.text('Signature + Source Health'), findsOneWidget);
      expect(find.text('Live signature + intake health'), findsOneWidget);
      expect(find.textContaining('Strong: 1'), findsOneWidget);
      expect(find.textContaining('Soft ignore: 0'), findsWidgets);
    });
  });
}
