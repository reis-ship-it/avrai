/// SPOTS AICommandProcessor Service Tests
/// Date: November 19, 2025
/// Purpose: Test AI command processing through grounded language rendering
///
/// Test Coverage:
/// - Command Processing: grounded command handling
/// - Offline Handling: grounded offline-safe responses
/// - Rule-based Processing: List creation, spot addition, search commands
///
/// Dependencies:
/// - Mock Connectivity: Simulates network state
/// - Mock BuildContext: Simulates Flutter context
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:get_it/get_it.dart';

import 'ai_command_processor_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([LLMService, Connectivity, BuildContext])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AICommandProcessor Tests', () {
    late MockConnectivity mockConnectivity;
    late MockBuildContext mockContext;

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockContext = MockBuildContext();
      when(mockContext.mounted).thenReturn(false);
      final getIt = GetIt.instance;
      if (getIt.isRegistered<LanguageKernelOrchestratorService>()) {
        getIt.unregister<LanguageKernelOrchestratorService>();
      }
      getIt.registerSingleton<LanguageKernelOrchestratorService>(
        _TestLanguageKernelOrchestratorService(),
      );
    });

    // Removed: Property assignment tests
    // AI command processor tests focus on business logic (command processing, rule-based fallback, LLM integration), not property assignment

    group('processCommand', () {
      test(
          'should process grounded commands for lists, spots, search, help, trending, events, and unknown input',
          () async {
        // Test business logic: grounded command processing in various scenarios
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result1 = await AICommandProcessor.processCommand(
          'create a list called "Coffee Shops"',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result1, isNotEmpty);
        expect(result1, contains('Coffee Shops'));
        expect(result1.toLowerCase(), contains('list'));

        final result2 = await AICommandProcessor.processCommand(
          'add Central Park to my list',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result2, isNotEmpty);
        expect(result2.toLowerCase(), contains('add'));

        final result3 = await AICommandProcessor.processCommand(
          'find restaurants near me',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result3, isNotEmpty);
        expect(result3.toLowerCase(), contains('restaurant'));
        final result4 = await AICommandProcessor.processCommand(
          'test command',
          mockContext,
          connectivity: mockConnectivity,
          useStreaming: false,
          showThinkingIndicator: false,
          userId: null,
        );
        expect(result4, isNotEmpty);
        expect(result4.toLowerCase(), contains('help'));

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result5 = await AICommandProcessor.processCommand(
          'help',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result5, isNotEmpty);
        expect(result5.toLowerCase(), contains('help'));

        final result6 = await AICommandProcessor.processCommand(
          'show me trending spots',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result6, isNotEmpty);
        expect(
          result6.toLowerCase(),
          anyOf(
              contains('trending'), contains('popular'), contains('category')),
        );

        final result7 = await AICommandProcessor.processCommand(
          'show me weekend events',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result7, isNotEmpty);
        final lowerResult9 = result7.toLowerCase();
        expect(
            lowerResult9.contains('weekend') ||
                lowerResult9.contains('event') ||
                lowerResult9.contains('help') ||
                lowerResult9.contains('timing'),
            isTrue);

        final result8 = await AICommandProcessor.processCommand(
          'random unknown command',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result8, isNotEmpty);
        final lowerResult10 = result8.toLowerCase();
        expect(
            lowerResult10.contains('help') || lowerResult10.contains('command'),
            isTrue);
      });
    });

    group('Rule-based Processing', () {
      test(
          'should extract list name from quoted string, or extract list name from "called" keyword',
          () async {
        // Test business logic: list name extraction
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result1 = await AICommandProcessor.processCommand(
          'create a list called "My Favorite Places"',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result1, contains('My Favorite Places'));

        final result2 = await AICommandProcessor.processCommand(
          'create list called Test List',
          mockContext,
          connectivity: mockConnectivity,
        );
        expect(result2, contains('Test List'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

class _TestLanguageKernelOrchestratorService
    extends LanguageKernelOrchestratorService {
  @override
  Future<HumanLanguageKernelTurn> processHumanText({
    required String actorAgentId,
    required String rawText,
    required Set<String> consentScopes,
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    bool shareRequested = false,
    BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.none,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
  }) async {
    return HumanLanguageKernelTurn(
      interpretation: InterpretationResult(
        intent: InterpretationIntent.inform,
        normalizedText: rawText.trim(),
        requestArtifact: InterpretationRequestArtifact(
          summary: rawText.trim(),
          asksForResponse: true,
          asksForRecommendation: false,
          asksForAction: false,
          asksForExplanation: false,
          referencedEntities: const <String>[],
          questions: const <String>[],
          preferenceSignals: const <InterpretationPreferenceSignal>[],
          shareIntent: false,
        ),
        learningArtifact: const InterpretationLearningArtifact(
          vocabulary: <String>[],
          phrases: <String>[],
          toneMetrics: <String, double>{},
          directnessPreference: 0.5,
          brevityPreference: 0.5,
        ),
        privacySensitivity: InterpretationPrivacySensitivity.low,
        confidence: 0.9,
        ambiguityFlags: const <String>[],
        needsClarification: false,
        safeForLearning: true,
      ),
      boundary: BoundaryDecision(
        accepted: true,
        disposition: BoundaryDisposition.storeSanitized,
        transcriptStorageAllowed: true,
        storageAllowed: true,
        learningAllowed: true,
        egressAllowed: false,
        airGapRequired: false,
        reasonCodes: const <String>['test_accept'],
        egressPurpose: egressPurpose,
        sanitizedArtifact: BoundarySanitizedArtifact(
          pseudonymousActorRef: actorAgentId,
          summary: rawText.trim(),
          safeClaims: const <String>[],
          learningVocabulary: const <String>[],
          learningPhrases: const <String>[],
          redactedText: rawText.trim(),
          safePreferenceSignals: const <InterpretationPreferenceSignal>[],
          safeQuestions: const <String>[],
          sharePayload: shareRequested ? rawText.trim() : null,
        ),
        vibeMutationDecision: const VibeMutationDecision(
          stateWriteAllowed: false,
          dnaWriteAllowed: false,
          pheromoneWriteAllowed: false,
          behaviorWriteAllowed: false,
          affectiveWriteAllowed: false,
          styleWriteAllowed: false,
          reasonCodes: <String>['test_accept'],
        ),
      ),
    );
  }

  @override
  RenderedExpression renderGroundedOutput({
    required ExpressionSpeechAct speechAct,
    required ExpressionAudience audience,
    required ExpressionSurfaceShape surfaceShape,
    required String subjectLabel,
    required List<String> allowedClaims,
    List<String> forbiddenClaims = const <String>[],
    List<String> evidenceRefs = const <String>[],
    String confidenceBand = 'medium',
    String toneProfile = 'clear_calm',
    VibeExpressionContext? vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    final text = allowedClaims.join(' ');
    return RenderedExpression(
      text: text,
      sections: <ExpressionSection>[
        ExpressionSection(kind: 'body', text: text),
      ],
      assertedClaims: allowedClaims,
    );
  }
}
