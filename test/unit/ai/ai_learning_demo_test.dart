import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/ai_learning_demo.dart';

/// AI Learning Demo Tests
/// Tests the demo/example file that shows how to use the AI learning system
/// Note: This is a demo file, so tests focus on verifying it doesn't crash and methods execute
void main() {
  group('AILearningDemo', () {
    late AILearningDemo demo;

    setUp(() {
      demo = AILearningDemo();
    });

    group('Initialization', () {
      test('should initialize without errors', () async {
        await expectLater(
          demo.initialize(),
          completes,
        );
      });
    });

    group('Data Collection Demonstration', () {
      test('should demonstrate data collection without errors', () async {
        await demo.initialize();
        await expectLater(
          demo.demonstrateDataCollection(),
          completes,
        );
      });
    });

    group('Comprehensive Learning', () {
      test('should start comprehensive learning without errors', () async {
        await demo.initialize();
        await expectLater(
          demo.startComprehensiveLearning(),
          completes,
        );
      });

      test('should stop comprehensive learning without errors', () async {
        await demo.initialize();
        await demo.startComprehensiveLearning();
        await expectLater(
          demo.stopComprehensiveLearning(),
          completes,
        );
      });
    });

    group('Continuous Learning Demonstration', () {
      test('should demonstrate continuous learning without errors', () async {
        await demo.initialize();
        await expectLater(
          demo.demonstrateContinuousLearning(),
          completes,
        );
      });
    }, skip: 'Skipping due to 10 second delay - run manually if needed');

    group('Self-Improvement Demonstration', () {
      test('should demonstrate self-improvement without errors', () async {
        await demo.initialize();
        await expectLater(
          demo.demonstrateSelfImprovement(),
          completes,
        );
      });
    });

    group('Complete Demo', () {
      test('should run complete demo without errors', () async {
        await expectLater(
          demo.runCompleteDemo(),
          completes,
        );
      });
    }, skip: 'Skipping due to delays - run manually if needed');

    group('Integration Example', () {
      test('should show integration example without errors', () async {
        await demo.initialize();
        await expectLater(
          demo.integrateWithMainApp(),
          completes,
        );
      });
    });
  });
}

