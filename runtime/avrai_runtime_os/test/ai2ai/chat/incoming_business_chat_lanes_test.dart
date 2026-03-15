import 'dart:io';

import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/chat/incoming_business_business_chat_lane.dart';
import 'package:avrai_runtime_os/ai2ai/chat/incoming_business_expert_chat_lane.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../../support/fake_language_kernels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
    storageRoot =
        await Directory.systemTemp.createTemp('incoming_business_chat_test_');
    await GetStorage('business_expert_messages', storageRoot.path).initStorage;
    await GetStorage('business_business_messages', storageRoot.path)
        .initStorage;
    await GetStorage('incoming_business_chat_intake', storageRoot.path)
        .initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await storageRoot.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort temp cleanup.
    }
  });

  group('Incoming business chat lanes', () {
    late SharedPreferencesCompat prefs;
    late AI2AIChatAnalyzer analyzer;
    late HumanLanguageBoundaryReviewLane boundaryLane;
    late Ai2AiChatEventIntakeService intakeService;

    setUp(() async {
      await GetStorage('business_expert_messages').erase();
      await GetStorage('business_business_messages').erase();
      final storage = GetStorage('incoming_business_chat_intake');
      await storage.erase();
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      await prefs.setBool('user_runtime_learning_enabled', true);
      await prefs.setBool('ai2ai_learning_enabled', true);
      analyzer = AI2AIChatAnalyzer(
        prefs: prefs,
        personalityLearning: PersonalityLearning.withPrefs(prefs),
      );
      boundaryLane = TestHumanLanguageBoundaryReviewLane();
      intakeService = Ai2AiChatEventIntakeService(
        chatAnalyzer: analyzer,
        humanLanguageBoundaryReviewLane: boundaryLane,
      );
    });

    test('business-expert inbound stores learning metadata and feeds analyzer',
        () async {
      await IncomingBusinessExpertChatLane.handle(
        payload: <String, dynamic>{
          'message_category': 'user_chat',
          'message_id': 'msg-be-1',
          'conversation_id': 'conv_be_1',
          'sender_type': 'business',
          'sender_id': 'business_1',
          'sender_agent_id': 'agt_business_1',
          'recipient_type': 'expert',
          'recipient_id': 'expert_1',
          'recipient_agent_id': 'agt_expert_1',
          'content':
              'I prefer coordinated planning with reliable follow-through.',
          'message_type': 'text',
          'created_at': DateTime.utc(2026, 3, 12, 13).toIso8601String(),
        },
        ai2aiChatEventIntakeService: intakeService,
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'test',
      );

      final stored = GetStorage('business_expert_messages')
              .read<List<dynamic>>('messages_conv_be_1') ??
          const <dynamic>[];
      expect(stored, hasLength(1));
      final metadata =
          Map<String, dynamic>.from(stored.single as Map)['metadata'] as Map?;
      expect(
        metadata?[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map>(),
      );

      final history = await analyzer.getChatHistoryForAdmin('expert_1');
      expect(history, hasLength(1));
      expect(
        history.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });

    test(
        'business-business inbound stores learning metadata and feeds analyzer',
        () async {
      await IncomingBusinessBusinessChatLane.handle(
        payload: <String, dynamic>{
          'message_category': 'user_chat',
          'message_id': 'msg-bb-1',
          'conversation_id': 'conv_bb_1',
          'sender_business_id': 'business_1',
          'sender_agent_id': 'agt_business_1',
          'recipient_business_id': 'business_2',
          'recipient_agent_id': 'agt_business_2',
          'content': 'We should coordinate vendor planning and city rollout.',
          'message_type': 'text',
          'created_at': DateTime.utc(2026, 3, 12, 14).toIso8601String(),
        },
        ai2aiChatEventIntakeService: intakeService,
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'test',
      );

      final stored = GetStorage('business_business_messages')
              .read<List<dynamic>>('messages_conv_bb_1') ??
          const <dynamic>[];
      expect(stored, hasLength(1));
      final metadata =
          Map<String, dynamic>.from(stored.single as Map)['metadata'] as Map?;
      expect(
        metadata?[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map>(),
      );

      final history = await analyzer.getChatHistoryForAdmin('business_2');
      expect(history, hasLength(1));
      expect(
        history.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });
  });
}
