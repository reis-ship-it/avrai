// ignore_for_file: avoid_print

import 'package:avrai_runtime_os/data/datasources/local/onboarding_completion_service.dart';

/// Helper to reset onboarding for testing
Future<void> resetOnboardingForUser(String userId) async {
  print('🔄 Resetting onboarding for user: $userId');
  // Sembast removed in Phase 26 - OnboardingCompletionService now uses StorageService
  await OnboardingCompletionService.resetOnboardingCompletion(userId);
  final isCompleted =
      await OnboardingCompletionService.isOnboardingCompleted(userId);
  print(
      '✅ Onboarding reset. Status: ${isCompleted ? "COMPLETED" : "NOT COMPLETED"}');
}
