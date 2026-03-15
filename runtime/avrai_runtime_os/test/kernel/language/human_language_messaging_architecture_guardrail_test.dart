import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readRuntimeSource(String relativePath) {
  final candidates = <String>[
    relativePath,
    'runtime/avrai_runtime_os/$relativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  throw FileSystemException(
    'Cannot open runtime source file. Tried ${candidates.join(', ')}',
    relativePath,
  );
}

void main() {
  group('Human language messaging architecture guardrails', () {
    test('friend chat keeps local and network sends behind boundary review',
        () {
      final source =
          _readRuntimeSource('lib/services/chat/friend_chat_service.dart');

      expect(source, contains('HumanLanguageBoundaryReviewLane'));
      expect(source, contains('_reviewDirectMessage('));
      expect(source, contains('BoundaryEgressPurpose.directMessage'));
      expect(source, contains('HumanLanguageBoundaryViolationException'));
      expect(source, contains('review.transportText'));
      expect(source, contains('review.toMetadata()'));
      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_ingestDirectMessageForLearning('));
      expect(source, contains('_buildAi2AiLearningMetadata('));
    });

    test('community chat keeps local and network sends behind boundary review',
        () {
      final source = _readRuntimeSource(
          'lib/services/community/community_chat_service.dart');

      expect(source, contains('HumanLanguageBoundaryReviewLane'));
      expect(source, contains('_reviewCommunityMessage('));
      expect(source, contains('BoundaryEgressPurpose.communityMessage'));
      expect(source, contains('HumanLanguageBoundaryViolationException'));
      expect(source, contains('review.transportText'));
      expect(source, contains('review.toMetadata()'));
      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_ingestCommunityMessageForLearning('));
      expect(source, contains('_buildAi2AiLearningMetadata('));
    });

    test('personality chat stores human text only after transcript approval',
        () {
      final source = _readRuntimeSource(
          'lib/services/user/personality_agent_chat_service.dart');

      expect(source, contains('processHumanText('));
      expect(source, contains('acceptedForTranscript'));
      expect(source, contains('HumanLanguageBoundaryViolationException'));
      expect(source, contains('HumanLanguageBoundaryReview.metadataKey'));
    });

    test(
        'business-expert chat keeps network sends behind boundary review and intake',
        () {
      final source = _readRuntimeSource(
        'lib/services/business/business_expert_chat_service_ai2ai.dart',
      );

      expect(source, contains('HumanLanguageBoundaryReviewLane'));
      expect(source, contains('_reviewBusinessDirectMessage('));
      expect(source, contains('BoundaryEgressPurpose.directMessage'));
      expect(source, contains('HumanLanguageBoundaryViolationException'));
      expect(source, contains('review.transportText'));
      expect(source, contains('review.toMetadata()'));
      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_ingestBusinessExpertMessageForLearning('));
      expect(source, contains('_buildAi2AiLearningMetadata('));
    });

    test(
        'business-business chat keeps network sends behind boundary review and intake',
        () {
      final source = _readRuntimeSource(
        'lib/services/business/business_business_chat_service_ai2ai.dart',
      );

      expect(source, contains('HumanLanguageBoundaryReviewLane'));
      expect(source, contains('_reviewBusinessDirectMessage('));
      expect(source, contains('BoundaryEgressPurpose.directMessage'));
      expect(source, contains('HumanLanguageBoundaryViolationException'));
      expect(source, contains('review.transportText'));
      expect(source, contains('review.toMetadata()'));
      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_ingestBusinessBusinessMessageForLearning('));
      expect(source, contains('_buildAi2AiLearningMetadata('));
    });

    test('incoming business-expert chat feeds governed learning on receipt',
        () {
      final source = _readRuntimeSource(
        'lib/ai2ai/chat/incoming_business_expert_chat_lane.dart',
      );

      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_buildInboundLearningMetadata('));
      expect(source, contains('_ingestInboundMessageForLearning('));
      expect(source, contains('buildLearningMetadata('));
      expect(source, contains('ingestDirectMessage('));
    });

    test('incoming business-business chat feeds governed learning on receipt',
        () {
      final source = _readRuntimeSource(
        'lib/ai2ai/chat/incoming_business_business_chat_lane.dart',
      );

      expect(source, contains('Ai2AiChatEventIntakeService'));
      expect(source, contains('_buildInboundLearningMetadata('));
      expect(source, contains('_ingestInboundMessageForLearning('));
      expect(source, contains('buildLearningMetadata('));
      expect(source, contains('ingestDirectMessage('));
    });
  });
}
