import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GovernedUpwardLearningIntakeService', () {
    late UniversalIntakeRepository repository;
    late GovernedUpwardLearningIntakeService service;
    late KernelOfflineEvidenceReceipt receipt;
    late UpwardAirGapArtifact validArtifact;

    setUp(() {
      repository = UniversalIntakeRepository();
      service = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );
      receipt = KernelOfflineEvidenceReceipt(
        receiptId: 'kernel-receipt-1',
        receiptKind: 'offline_sync_receipt',
        sourceSystem: 'kernel_sync_lane',
        sourcePlane: 'offline_kernel',
        observedAtUtc: DateTime.utc(2026, 4, 4, 10),
        kernelId: 'kernel-1',
        requestId: 'request-1',
        lineageRef: 'lineage-1',
        environmentId: 'env-1',
        cityCode: 'bham',
        localityCode: 'bham_avondale',
        actorScope: 'bounded_actor_scope',
        boundedEvidence: const <String, dynamic>{
          'validationStatus': 'accepted',
        },
        temporalLineage: const <String, dynamic>{
          'capturedAtUtc': '2026-04-04T10:00:00.000Z',
        },
        signalTags: const <String>['offline', 'kernel'],
      );
      validArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'offline_kernel',
        sourceKind: 'kernel_offline_evidence_receipt_intake',
        sourceScope: 'kernel',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.utc(2026, 4, 4, 11),
        sanitizedPayload: <String, dynamic>{
          'ownerUserIdHashRef': 'hash:user-1',
          'sourceProvider': 'kernel_offline_evidence_receipt_intake',
          'sourceKind': 'kernel_offline_evidence_receipt_intake',
          'convictionTier': 'kernel_offline_evidence_receipt_signal',
          'hierarchyPath': <String>['kernel', 'reality_model_agent'],
          'payload': <String, dynamic>{
            'receiptId': 'kernel-receipt-1',
            'receiptKind': 'offline_sync_receipt',
          },
        },
      );
    });

    test('persists review artifacts when caller-issued receipt is valid',
        () async {
      final result = await service.stageKernelOfflineEvidenceReceiptIntake(
        ownerUserId: 'user-1',
        receipt: receipt,
        airGapArtifact: validArtifact,
      );

      final reviews = await repository.getAllReviewItems();
      final sources = await repository.getAllSources();

      expect(result.reviewItemId, isNotEmpty);
      expect(reviews, hasLength(1));
      expect(sources, hasLength(1));
      expect(
          reviews.single.payload['airGapReceiptId'], validArtifact.receiptId);
    });

    test('fails closed on expired caller-issued receipt', () async {
      final expiredArtifact = _mutateArtifact(
        validArtifact,
        <String, dynamic>{
          'expiresAtUtc': DateTime.utc(2026, 4, 4, 9).toIso8601String(),
          'attestation': <String, dynamic>{
            ...validArtifact.attestation,
            'expiresAtUtc': DateTime.utc(2026, 4, 4, 9).toIso8601String(),
          },
        },
      );

      await expectLater(
        () => service.stageKernelOfflineEvidenceReceiptIntake(
          ownerUserId: 'user-1',
          receipt: receipt,
          airGapArtifact: expiredArtifact,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('artifact expired'),
          ),
        ),
      );
      expect(await repository.getAllReviewItems(), isEmpty);
      expect(await repository.getAllSources(), isEmpty);
    });

    test('fails closed on invalid destination or next stage', () async {
      final invalidArtifact = _mutateArtifact(
        validArtifact,
        <String, dynamic>{
          'destinationCeiling': 'personal_agent',
          'allowedNextStages': const <String>['some_other_stage'],
          'attestation': <String, dynamic>{
            ...validArtifact.attestation,
            'destinationCeiling': 'personal_agent',
            'allowedNextStages': const <String>['some_other_stage'],
          },
        },
      );

      await expectLater(
        () => service.stageKernelOfflineEvidenceReceiptIntake(
          ownerUserId: 'user-1',
          receipt: receipt,
          airGapArtifact: invalidArtifact,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('destination ceiling'),
              contains('allowedNextStages missing required stage'),
            ),
          ),
        ),
      );
      expect(await repository.getAllReviewItems(), isEmpty);
    });

    test('fails closed on content hash mismatch', () async {
      final invalidArtifact = _mutateArtifact(
        validArtifact,
        <String, dynamic>{
          'sanitizedPayload': <String, dynamic>{
            ...validArtifact.sanitizedPayload,
            'payload': <String, dynamic>{
              'receiptId': 'kernel-receipt-1',
              'receiptKind': 'tampered',
            },
          },
        },
      );

      await expectLater(
        () => service.stageKernelOfflineEvidenceReceiptIntake(
          ownerUserId: 'user-1',
          receipt: receipt,
          airGapArtifact: invalidArtifact,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('contentSha256 does not match sanitizedPayload'),
              contains('receiptId does not match issued payload digest'),
            ),
          ),
        ),
      );
      expect(await repository.getAllReviewItems(), isEmpty);
    });

    test('fails closed on request-bound payload mismatch', () async {
      final mismatchedArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'offline_kernel',
        sourceKind: 'kernel_offline_evidence_receipt_intake',
        sourceScope: 'kernel',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.utc(2026, 4, 4, 11),
        sanitizedPayload: <String, dynamic>{
          'receiptId': 'kernel-receipt-1',
          'receiptKind': 'tampered_kind',
          'sourceSystem': 'kernel_sync_lane',
          'kernelId': 'kernel-1',
          'requestId': 'request-1',
        },
      );

      await expectLater(
        () => service.stageKernelOfflineEvidenceReceiptIntake(
          ownerUserId: 'user-1',
          receipt: receipt,
          airGapArtifact: mismatchedArtifact,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(
                'sanitizedPayload `receiptKind` does not match current request'),
          ),
        ),
      );
      expect(await repository.getAllReviewItems(), isEmpty);
      expect(await repository.getAllSources(), isEmpty);
    });
  });
}

UpwardAirGapArtifact _mutateArtifact(
  UpwardAirGapArtifact artifact,
  Map<String, dynamic> updates,
) {
  return UpwardAirGapArtifact.fromJson(
    <String, dynamic>{
      ...artifact.toJson(),
      ...updates,
    },
  );
}
