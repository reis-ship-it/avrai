// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/data/datasources/local/onboarding_completion_service.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('🔄 Testing onboarding reset for demo-user-1...');

  // Sembast removed in Phase 26 - OnboardingCompletionService now uses StorageService

  // Check initial status
  final initialStatus =
      await OnboardingCompletionService.isOnboardingCompleted('demo-user-1');
  print(
      '📊 Initial onboarding status: ${initialStatus ? "COMPLETED" : "NOT COMPLETED"}');

  // Reset onboarding
  print('🗑️ Resetting onboarding...');
  await OnboardingCompletionService.resetOnboardingCompletion('demo-user-1');

  // Verify reset
  final afterReset =
      await OnboardingCompletionService.isOnboardingCompleted('demo-user-1');
  print('✅ After reset status: ${afterReset ? "COMPLETED" : "NOT COMPLETED"}');

  if (!afterReset) {
    print('✅ SUCCESS: Onboarding reset worked!');
  } else {
    print('❌ FAILED: Onboarding still marked as completed');
  }
}
