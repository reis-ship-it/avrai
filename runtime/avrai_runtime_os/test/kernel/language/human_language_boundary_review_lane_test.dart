import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_language_kernels.dart';

void main() {
  group('HumanLanguageBoundaryReviewLane', () {
    late HumanLanguageBoundaryReviewLane lane;

    setUp(() {
      lane = HumanLanguageBoundaryReviewLane(
        languageKernelOrchestrator: TestLanguageKernelOrchestratorService(),
      );
    });

    test('keeps direct-message drafts local while allowing transcript storage',
        () async {
      final review = await lane.reviewOutboundText(
        actorAgentId: 'agt_user123456',
        rawText: 'Draft this for my friend.',
        egressPurpose: BoundaryEgressPurpose.directMessage,
        egressRequested: false,
        consentScopes: const <String>{},
      );

      expect(review.transcriptStorageAllowed, isTrue);
      expect(review.egressAllowed, isTrue);
      expect(review.turn.boundary.disposition, BoundaryDisposition.localOnly);
      expect(
        review.turn.boundary.reasonCodes,
        contains('local_transcript_only_message_draft'),
      );
    });

    test('allows explicit direct-message egress in local sovereign mode',
        () async {
      final review = await lane.reviewOutboundText(
        actorAgentId: 'agt_user123456',
        rawText: 'Send this exact note to Taylor.',
        egressPurpose: BoundaryEgressPurpose.directMessage,
        egressRequested: true,
        consentScopes: const <String>{},
      );

      expect(review.transcriptStorageAllowed, isTrue);
      expect(review.egressAllowed, isTrue);
      expect(
        review.turn.boundary.disposition,
        BoundaryDisposition.userAuthorizedEgress,
      );
      expect(
        review.toMetadata()[HumanLanguageBoundaryReview.metadataKey]
            ['egress_purpose'],
        BoundaryEgressPurpose.directMessage.toWireValue(),
      );
      expect(
        review.toMetadata()[HumanLanguageBoundaryReview.metadataKey]
            ['sanitized_artifact'],
        isA<Map<String, dynamic>>(),
      );
    });

    test('keeps ai2ai learning artifact egress blocked in local sovereign mode',
        () async {
      final review = await lane.reviewOutboundText(
        actorAgentId: 'agt_user123456',
        rawText: 'Share what you learned from my last week with the network.',
        egressPurpose: BoundaryEgressPurpose.ai2aiLearningArtifact,
        egressRequested: true,
        consentScopes: const <String>{'ai2ai_learning'},
      );

      expect(review.transcriptStorageAllowed, isTrue);
      expect(review.turn.boundary.egressAllowed, isFalse);
      expect(review.turn.boundary.disposition, BoundaryDisposition.localOnly);
      expect(
        review.turn.boundary.reasonCodes,
        contains('local_sovereign_blocks_egress'),
      );
    });

    test('local learning review produces learnable metadata without egress',
        () async {
      final review = await lane.reviewLocalLearningText(
        actorAgentId: 'agt_user123456',
        rawText: 'I prefer collaborative planning and trying new local spots.',
        userId: 'user-123',
      );

      expect(review.turn.boundary.learningAllowed, isTrue);
      expect(review.turn.boundary.storageAllowed, isTrue);
      expect(
        review.toMetadata(
          metadataKey: HumanLanguageBoundaryReview.learningMetadataKey,
        )[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );
    });
  });
}
