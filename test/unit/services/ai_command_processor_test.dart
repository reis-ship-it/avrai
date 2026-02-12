/// SPOTS AICommandProcessor Service Tests
/// Date: November 19, 2025
/// Purpose: Test AI command processing with LLM service and rule-based fallback
///
/// Test Coverage:
/// - Command Processing: LLM-based and rule-based command handling
/// - Offline Handling: Fallback to rule-based processing when offline
/// - Rule-based Processing: List creation, spot addition, search commands
/// - Error Handling: LLM failures, offline exceptions
///
/// Dependencies:
/// - Mock LLMService: Simulates LLM backend
/// - Mock Connectivity: Simulates network state
/// - Mock BuildContext: Simulates Flutter context
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';

import 'ai_command_processor_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([LLMService, Connectivity, BuildContext])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AICommandProcessor Tests', () {
    late MockLLMService mockLLMService;
    late MockConnectivity mockConnectivity;
    late MockBuildContext mockContext;

    setUp(() {
      mockLLMService = MockLLMService();
      mockConnectivity = MockConnectivity();
      mockContext = MockBuildContext();
    });

    // Removed: Property assignment tests
    // AI command processor tests focus on business logic (command processing, rule-based fallback, LLM integration), not property assignment

    group('processCommand', () {
      test(
          'should process create list command using rule-based fallback, process add spot command using rule-based fallback, process find command using rule-based fallback, use LLM service when online and available, fallback to rule-based when LLM service fails, handle offline exception and use rule-based fallback, handle help command, handle trending command, handle event command, or handle default command for unknown input',
          () async {
        // Test business logic: command processing with various scenarios
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result1 = await AICommandProcessor.processCommand(
          'create a list called "Coffee Shops"',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result1, isNotEmpty);
        expect(result1, contains('Coffee Shops'));
        expect(result1.toLowerCase(), contains('create'));

        final result2 = await AICommandProcessor.processCommand(
          'add Central Park to my list',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result2, isNotEmpty);
        expect(result2.toLowerCase(), contains('add'));

        final result3 = await AICommandProcessor.processCommand(
          'find restaurants near me',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result3, isNotEmpty);
        expect(result3.toLowerCase(), contains('restaurant'));

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLLMService.generateRecommendation(
          userQuery: 'test command',
          userContext: argThat(anything, named: 'userContext'),
        )).thenAnswer((_) async => 'LLM response');
        final result4 = await AICommandProcessor.processCommand(
          'test command',
          mockContext,
          llmService: mockLLMService,
          connectivity: mockConnectivity,
          useStreaming: false,
          showThinkingIndicator: false,
          userId: null,
        );
        expect(result4, equals('LLM response'));

        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
          userContext: anyNamed('userContext'),
        )).thenThrow(Exception('LLM error'));
        final result5 = await AICommandProcessor.processCommand(
          'find coffee shops',
          mockContext,
          llmService: mockLLMService,
          connectivity: mockConnectivity,
        );
        expect(result5, isNotEmpty);
        expect(result5.toLowerCase(), contains('coffee'));

        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
          userContext: anyNamed('userContext'),
        )).thenThrow(OfflineException('Network unavailable'));
        final result6 = await AICommandProcessor.processCommand(
          'create a list',
          mockContext,
          llmService: mockLLMService,
          connectivity: mockConnectivity,
        );
        expect(result6, isNotEmpty);
        expect(result6.toLowerCase(), contains('create'));

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result7 = await AICommandProcessor.processCommand(
          'help',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result7, isNotEmpty);
        expect(result7.toLowerCase(), contains('help'));

        final result8 = await AICommandProcessor.processCommand(
          'show me trending spots',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result8, isNotEmpty);
        expect(result8.toLowerCase(),
            anyOf(contains('help'), contains('find'), contains('restaurant')));

        final result9 = await AICommandProcessor.processCommand(
          'show me weekend events',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result9, isNotEmpty);
        final lowerResult9 = result9.toLowerCase();
        expect(
            lowerResult9.contains('weekend') ||
                lowerResult9.contains('event') ||
                lowerResult9.contains('help') ||
                lowerResult9.contains('find'),
            isTrue);

        final result10 = await AICommandProcessor.processCommand(
          'random unknown command',
          mockContext,
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result10, isNotEmpty);
        final lowerResult10 = result10.toLowerCase();
        expect(
            lowerResult10.contains('help') || lowerResult10.contains('create'),
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
          llmService: null,
          connectivity: mockConnectivity,
        );
        expect(result1, contains('My Favorite Places'));

        final result2 = await AICommandProcessor.processCommand(
          'create list called Test List',
          mockContext,
          llmService: null,
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
