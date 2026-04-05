import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  setUp(() async {
    await StorageService.instance.clear();
    await StorageService.instance.clear(box: 'spots_user');
  });

  test('round-trips receipts and dedupes by id', () async {
    final service = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final receipt = GovernedLearningChatObservationReceipt(
      id: 'obs-1',
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
      sourceId: 'source-1',
      kind: GovernedLearningChatObservationKind.explanation,
      outcome: GovernedLearningChatObservationOutcome.pending,
      recordedAtUtc: DateTime.utc(2026, 4, 5, 12),
      chatId: 'chat-1',
      userMessageId: 'user-msg-1',
      assistantMessageId: 'assistant-msg-1',
      focus: 'impact',
      userQuestion: 'What changed?',
      renderedResponse: 'It changed nightlife.',
    );

    await service.recordReceipts([receipt, receipt]);

    final stored = await service.listReceiptsForUser(ownerUserId: 'user-1');
    expect(stored, hasLength(1));
    expect(stored.single.toJson(), receipt.toJson());
  });

  test('marks the latest pending receipt for an envelope with an outcome',
      () async {
    final service = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    await service.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs-older',
        ownerUserId: 'user-1',
        envelopeId: 'env-1',
        sourceId: 'source-1',
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.pending,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 11),
        chatId: 'chat-1',
        userMessageId: 'user-msg-1',
      ),
      GovernedLearningChatObservationReceipt(
        id: 'obs-newer',
        ownerUserId: 'user-1',
        envelopeId: 'env-1',
        sourceId: 'source-1',
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.pending,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 12),
        chatId: 'chat-1',
        userMessageId: 'user-msg-2',
      ),
    ]);

    final updated = await service.markLatestPendingOutcome(
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
      outcome: GovernedLearningChatObservationOutcome.correctedRecord,
    );

    expect(updated, isNotNull);
    expect(
      updated!.outcome,
      GovernedLearningChatObservationOutcome.correctedRecord,
    );

    final stored = await service.listReceiptsForEnvelope(
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
    );
    expect(stored.first.id, 'obs-newer');
    expect(
      stored.first.outcome,
      GovernedLearningChatObservationOutcome.correctedRecord,
    );
    expect(
      stored.last.outcome,
      GovernedLearningChatObservationOutcome.pending,
    );
  });

  test('marks the latest unvalidated receipt as surfaced adoption', () async {
    final service = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    await service.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs-1',
        ownerUserId: 'user-1',
        envelopeId: 'env-1',
        sourceId: 'source-1',
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.acknowledged,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 11),
        chatId: 'chat-1',
        userMessageId: 'user-msg-1',
      ),
    ]);

    final updated = await service.markLatestUnvalidatedAsSurfacedAdoption(
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
      validatedAtUtc: DateTime.utc(2026, 4, 5, 12),
      surface: 'events_personalized',
      targetEntityTitle: 'Austin After Dark',
    );

    expect(updated, isNotNull);
    expect(
      updated!.validationStatus,
      GovernedLearningChatObservationValidationStatus
          .validatedBySurfacedAdoption,
    );
    expect(updated.validatedSurface, 'events_personalized');
    expect(updated.validatedTargetEntityTitle, 'Austin After Dark');
  });

  test('marks the latest receipt as governed by hierarchy outcome', () async {
    final service = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    await service.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs-governance-1',
        ownerUserId: 'user-1',
        envelopeId: 'env-1',
        sourceId: 'source-1',
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.acknowledged,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 11),
        chatId: 'chat-1',
        userMessageId: 'user-msg-1',
      ),
    ]);

    final updated = await service.markLatestWithoutGovernanceAsGoverned(
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
      governanceStatus: GovernedLearningChatObservationGovernanceStatus
          .constrainedByGovernance,
      governanceUpdatedAtUtc: DateTime.utc(2026, 4, 5, 12),
      governanceStage: 'reality_model_truth_review',
      governanceReason: 'Held for more evidence.',
    );

    expect(updated, isNotNull);
    expect(
      updated!.governanceStatus,
      GovernedLearningChatObservationGovernanceStatus.constrainedByGovernance,
    );
    expect(updated.governanceStage, 'reality_model_truth_review');
    expect(updated.governanceReason, 'Held for more evidence.');
  });

  test('marks follow-up pressure as satisfied when governance reinforces it',
      () async {
    final service = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    await service.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs-pressure-1',
        ownerUserId: 'user-1',
        envelopeId: 'env-1',
        sourceId: 'source-1',
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.requestedFollowUp,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 11),
        chatId: 'chat-1',
        userMessageId: 'user-msg-1',
      ),
    ]);

    final updated = await service.markLatestWithoutGovernanceAsGoverned(
      ownerUserId: 'user-1',
      envelopeId: 'env-1',
      governanceStatus: GovernedLearningChatObservationGovernanceStatus
          .reinforcedByGovernance,
      governanceUpdatedAtUtc: DateTime.utc(2026, 4, 5, 12),
      governanceStage: 'upward_learning_review',
      governanceReason: 'Approved for hierarchy synthesis.',
    );

    expect(updated, isNotNull);
    expect(
      updated!.attentionStatus,
      GovernedLearningChatObservationAttentionStatus.satisfiedByGovernance,
    );
    expect(updated.attentionUpdatedAtUtc, isNotNull);
  });
}
