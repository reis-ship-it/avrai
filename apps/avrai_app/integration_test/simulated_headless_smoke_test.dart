import 'dart:developer' as developer;
import 'dart:io';

import 'package:avrai/configs/firebase_options.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/services/debug/proof_run_automation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'runs simulated headless smoke via automation service',
    (tester) async {
      const platformMode = String.fromEnvironment(
        'SIMULATED_SMOKE_PLATFORM',
        defaultValue: 'unknown',
      );

      try {
        await _initializeSmokeRuntime(tester);

        final service = di.sl<ProofRunAutomationService>();
        final result = await service.runSimulatedHeadlessSmoke(
          const SimulatedHeadlessSmokeRequest(
            platformMode: platformMode,
          ),
        );

        binding.reportData = result.toJson();
        expect(result.success, isTrue, reason: result.failureSummary);
        expect(result.runId, isNotEmpty);
        expect(result.exportDirectoryPath, isNotEmpty);
        expect(Directory(result.exportDirectoryPath).existsSync(), isTrue);
      } catch (error, stackTrace) {
        final failure = <String, Object?>{
          'success': false,
          'platform_mode': platformMode,
          'failure_summary': error.toString(),
        };
        binding.reportData = failure;
        developer.log(
          'Simulated headless smoke integration run failed',
          name: 'simulated_headless_smoke_test',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    },
  );
}

Future<void> _initializeSmokeRuntime(WidgetTester tester) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // The smoke lane is allowed to proceed when Firebase is already initialized
    // or unavailable in the current simulator environment.
  }
  await di.init();
  await tester.pump(const Duration(milliseconds: 200));
}
