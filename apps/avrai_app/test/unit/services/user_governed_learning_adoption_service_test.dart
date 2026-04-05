import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('UserGovernedLearningAdoptionService', () {
    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() async {
      await StorageService.instance.clear();
      await StorageService.instance.clear(box: 'spots_user');
      await StorageService.instance.clear(box: 'spots_ai');
      await StorageService.instance.clear(box: 'spots_analytics');
    });

    test('dedupes receipts by id and isolates users', () async {
      final service = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );

      await service.recordReceipts([
        GovernedLearningAdoptionReceipt(
          id: 'receipt_1',
          ownerUserId: 'user_123',
          envelopeId: 'env_1',
          sourceId: 'src_1',
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 5, 10),
          reason: 'accepted',
        ),
        GovernedLearningAdoptionReceipt(
          id: 'receipt_1',
          ownerUserId: 'user_123',
          envelopeId: 'env_1',
          sourceId: 'src_1',
          status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
          recordedAtUtc: DateTime.utc(2026, 4, 5, 11),
          reason: 'queued',
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
        ),
        GovernedLearningAdoptionReceipt(
          id: 'receipt_other_user',
          ownerUserId: 'user_456',
          envelopeId: 'env_2',
          sourceId: 'src_2',
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.utc(2026, 4, 5, 12),
          reason: 'accepted',
        ),
      ]);

      final user123 =
          await service.listReceiptsForUser(ownerUserId: 'user_123');
      final user456 =
          await service.listReceiptsForUser(ownerUserId: 'user_456');

      expect(user123, hasLength(1));
      expect(
        user123.single.status,
        GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
      );
      expect(user456, hasLength(1));
      expect(user456.single.envelopeId, 'env_2');
    });

    test('trims receipts outside the retention window', () async {
      final service = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );

      await service.recordReceipts([
        GovernedLearningAdoptionReceipt(
          id: 'receipt_old',
          ownerUserId: 'user_123',
          envelopeId: 'env_old',
          sourceId: 'src_old',
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc:
              DateTime.now().toUtc().subtract(const Duration(days: 31)),
          reason: 'old',
        ),
        GovernedLearningAdoptionReceipt(
          id: 'receipt_new',
          ownerUserId: 'user_123',
          envelopeId: 'env_new',
          sourceId: 'src_new',
          status: GovernedLearningAdoptionStatus.acceptedForLearning,
          recordedAtUtc: DateTime.now().toUtc(),
          reason: 'new',
        ),
      ]);

      final receipts =
          await service.listReceiptsForUser(ownerUserId: 'user_123');

      expect(receipts, hasLength(1));
      expect(receipts.single.id, 'receipt_new');
    });

    test('adoption receipt and user-visible record serialize round-trip', () {
      final receipt = GovernedLearningAdoptionReceipt(
        id: 'receipt_roundtrip',
        ownerUserId: 'user_123',
        envelopeId: 'env_123',
        sourceId: 'src_123',
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 14),
        reason: 'surfaced',
        surface: 'events_personalized',
        decisionFamily: 'event_recommendation',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event_123',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
      );
      final record = UserVisibleGovernedLearningRecord(
        envelopeId: 'env_123',
        sourceId: 'src_123',
        title: 'Nightlife preference correction',
        safeSummary: 'The user wants louder nightlife scenes.',
        sourceLabel: 'personal agent human intake',
        sourceProvider: 'explicit_correction_intake',
        convictionTier: 'explicit_correction_signal',
        occurredAtUtc: DateTime.utc(2026, 4, 5, 13),
        stagedAtUtc: DateTime.utc(2026, 4, 5, 13, 5),
        requiresHumanReview: false,
        currentAdoptionStatus:
            GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        pendingSurfaces: const <String>[],
        surfacedSurfaces: const <String>['events_personalized'],
        firstSurfacedAtUtc: DateTime.utc(2026, 4, 5, 14),
        recentAdoptionReceipts: <GovernedLearningAdoptionReceipt>[receipt],
      );

      final roundTrippedReceipt =
          GovernedLearningAdoptionReceipt.fromJson(receipt.toJson());
      final roundTrippedRecord =
          UserVisibleGovernedLearningRecord.fromJson(record.toJson());

      expect(roundTrippedReceipt.status, receipt.status);
      expect(roundTrippedReceipt.surface, 'events_personalized');
      expect(
        roundTrippedRecord.currentAdoptionStatus,
        GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
      );
      expect(
          roundTrippedRecord.surfacedSurfaces, contains('events_personalized'));
      expect(roundTrippedRecord.recentAdoptionReceipts, hasLength(1));
      expect(
        roundTrippedRecord.recentAdoptionReceipts.single.targetEntityTitle,
        'Austin After Dark',
      );
    });
  });
}
