import 'dart:async';

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteSourceHealthService extends Mock
    implements RemoteSourceHealthService {}

void main() {
  group('SignatureHealthAdminService', () {
    late UniversalIntakeRepository repository;

    setUp(() {
      repository = UniversalIntakeRepository();
    });

    test('maps sources into health categories and review queue counts',
        () async {
      final service = SignatureHealthAdminService(intakeRepository: repository);

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'source-strong',
          ownerUserId: 'owner-1',
          sourceProvider: 'eventbrite',
          sourceLabel: 'Strong Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'event',
            'signatureConfidence': 0.91,
            'signatureFreshness': 0.84,
            'signatureSummary': 'Healthy source.',
          },
        ),
      );
      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'source-review',
          ownerUserId: 'owner-1',
          sourceProvider: 'facebook',
          sourceLabel: 'Review Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.needsReview,
          metadata: const <String, dynamic>{
            'entityType': 'community',
            'signatureConfidence': 0.48,
            'signatureFreshness': 0.32,
          },
        ),
      );
      await repository.upsertReviewItem(
        OrganizerReviewItem(
          id: 'review-1',
          sourceId: 'source-review',
          ownerUserId: 'owner-1',
          targetType: IntakeEntityType.community,
          title: 'Review needed',
          summary: 'Missing fields',
          missingFields: const <String>['description'],
          createdAt: DateTime(2026, 3, 1),
          payload: const <String, dynamic>{},
        ),
      );

      final snapshot = await service.getSnapshot();

      expect(snapshot.overview.strongCount, 1);
      expect(snapshot.overview.reviewNeededCount, 1);
      expect(snapshot.reviewQueueCount, 1);
      expect(
        snapshot.records
            .firstWhere((record) => record.sourceId == 'source-review')
            .healthCategory,
        SignatureHealthCategory.reviewNeeded,
      );
    });

    test('merges remote records and emits live updates when local data changes',
        () async {
      final remoteService = MockRemoteSourceHealthService();
      when(() => remoteService.fetchRows()).thenAnswer(
        (_) async => const <SignatureHealthRecord>[
          SignatureHealthRecord(
            sourceId: 'remote-source',
            provider: 'meetup',
            entityType: 'event',
            categoryLabel: 'music',
            sourceLabel: 'Remote Source',
            confidence: 0.88,
            freshness: 0.81,
            fallbackRate: 0.0,
            reviewNeeded: false,
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Remote record is healthy.',
          ),
        ],
      );
      when(() => remoteService.watchRows()).thenAnswer(
        (_) => const Stream<List<SignatureHealthRecord>>.empty(),
      );

      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        remoteSourceHealthService: remoteService,
      );

      final stream = service.watchSnapshot();
      final initial = await stream.first;
      expect(
        initial.records.any((record) => record.sourceId == 'remote-source'),
        isTrue,
      );

      await repository.upsertSource(
        ExternalSourceDescriptor(
          id: 'local-source',
          ownerUserId: 'owner-1',
          sourceProvider: 'manual',
          sourceLabel: 'Local Source',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
          syncState: ExternalSyncState.active,
          metadata: const <String, dynamic>{
            'entityType': 'spot',
            'signatureConfidence': 0.79,
            'signatureFreshness': 0.62,
          },
        ),
      );

      final updated = await stream.firstWhere(
        (snapshot) =>
            snapshot.records.any((record) => record.sourceId == 'local-source'),
      );

      expect(updated.records.length, 2);
    });

    test('builds feedback trend rows by entity type and recency window',
        () async {
      final remoteService = MockRemoteSourceHealthService();
      when(() => remoteService.fetchRows()).thenAnswer(
        (_) async => <SignatureHealthRecord>[
          SignatureHealthRecord(
            sourceId: 'feedback-soft',
            provider: 'user_feedback',
            entityType: 'suggested_list',
            categoryLabel: 'soft_ignore',
            sourceLabel: 'List soft ignore',
            confidence: 0.68,
            freshness: 0.9,
            fallbackRate: 0.0,
            reviewNeeded: false,
            updatedAt: DateTime(2026, 3, 6),
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Soft ignore feedback.',
          ),
          SignatureHealthRecord(
            sourceId: 'feedback-hard',
            provider: 'user_feedback',
            entityType: 'spot',
            categoryLabel: 'hard_not_interested',
            sourceLabel: 'Spot hard reject',
            confidence: 0.72,
            freshness: 0.91,
            fallbackRate: 0.0,
            reviewNeeded: false,
            updatedAt: DateTime(2026, 3, 2),
            syncState: 'active',
            healthCategory: SignatureHealthCategory.strong,
            summary: 'Hard reject feedback.',
          ),
        ],
      );
      when(() => remoteService.watchRows()).thenAnswer(
        (_) => const Stream<List<SignatureHealthRecord>>.empty(),
      );

      final service = SignatureHealthAdminService(
        intakeRepository: repository,
        remoteSourceHealthService: remoteService,
      );

      final snapshot = await service.getSnapshot();
      final trendRows = snapshot.buildFeedbackTrendRows(
        now: DateTime(2026, 3, 6, 12),
      );

      expect(trendRows.length, 2);
      expect(
        trendRows
            .firstWhere((row) => row.entityType == 'suggested_list')
            .countsByWindow['24h']!
            .softIgnoreCount,
        1,
      );
      expect(
        trendRows
            .firstWhere((row) => row.entityType == 'spot')
            .countsByWindow['7d']!
            .hardNotInterestedCount,
        1,
      );
    });
  });
}
