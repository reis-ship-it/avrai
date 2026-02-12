import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/data/datasources/local/onboarding_completion_service.dart';

/// Onboarding Completion Service Tests
/// Tests onboarding completion tracking
void main() {
  group('OnboardingCompletionService', () {
    setUp(() {
      // No-op: Sembast removed in Phase 26
    });

    tearDown(() async {
      // No-op: Sembast removed in Phase 26
    });

    group('isOnboardingCompleted', () {
      test('should return false when no userId provided', () async {
        final isCompleted = await OnboardingCompletionService.isOnboardingCompleted();

        expect(isCompleted, isFalse);
      });

      test('should return false for new user', () async {
        const userId = 'new-user';

        final isCompleted = await OnboardingCompletionService.isOnboardingCompleted(userId);

        expect(isCompleted, isFalse);
      });

      test('should return true after marking as completed', () async {
        const userId = 'user-123';

        await OnboardingCompletionService.markOnboardingCompleted(userId);
        final isCompleted = await OnboardingCompletionService.isOnboardingCompleted(userId);

        expect(isCompleted, isTrue);
      });
    });

    group('markOnboardingCompleted', () {
      test('should mark onboarding as completed', () async {
        const userId = 'user-123';

        await expectLater(
          OnboardingCompletionService.markOnboardingCompleted(userId),
          completes,
        );

        final isCompleted = await OnboardingCompletionService.isOnboardingCompleted(userId);
        expect(isCompleted, isTrue);
      });

      test('should handle empty userId gracefully', () async {
        await expectLater(
          OnboardingCompletionService.markOnboardingCompleted(''),
          completes,
        );
      });
    });

    group('resetOnboardingCompletion', () {
      test('should reset onboarding completion status', () async {
        const userId = 'user-123';

        await OnboardingCompletionService.markOnboardingCompleted(userId);
        await OnboardingCompletionService.resetOnboardingCompletion(userId);

        final isCompleted = await OnboardingCompletionService.isOnboardingCompleted(userId);
        expect(isCompleted, isFalse);
      });
    });
  });
}

