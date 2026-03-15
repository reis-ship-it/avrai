import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai/configs/firebase_options.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/services/background/background_platform_wake_bridge.dart';
import 'package:avrai_runtime_os/services/background/headless_background_runtime_coordinator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

const String _logName = 'HeadlessBackgroundRuntimeEntryPoint';

@pragma('vm:entry-point')
Future<void> runAvraiBackgroundWake() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platformWakeBridge = MethodChannelBackgroundPlatformWakeBridge();
  var handledInvocationCount = 0;
  String? failureSummary;

  try {
    await _initializeBackgroundRuntime();
    final invocations =
        await platformWakeBridge.consumePendingWakeInvocations();
    if (invocations.isEmpty) {
      await platformWakeBridge.notifyHeadlessExecutionComplete(
        success: true,
        handledInvocationCount: 0,
      );
      return;
    }

    final coordinator = di.sl<HeadlessBackgroundRuntimeCoordinator>();
    await coordinator.startHeadlessRuntimeEnvelope();

    for (final invocation in invocations) {
      try {
        await coordinator.handleInvocation(invocation);
      } catch (error, stackTrace) {
        failureSummary = error.toString();
        developer.log(
          'Headless background wake execution failed for ${invocation.reason.name}',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
      handledInvocationCount += 1;
    }
  } catch (error, stackTrace) {
    failureSummary = error.toString();
    developer.log(
      'Headless background runtime bootstrap failed',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await platformWakeBridge.notifyHeadlessExecutionComplete(
      success: failureSummary == null,
      handledInvocationCount: handledInvocationCount,
      failureSummary: failureSummary,
    );
  }
}

Future<void> _initializeBackgroundRuntime() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Best-effort in headless mode. The runtime can still proceed if Firebase
    // is already initialized or unavailable on a constrained wake path.
  }
  await di.init();
}
