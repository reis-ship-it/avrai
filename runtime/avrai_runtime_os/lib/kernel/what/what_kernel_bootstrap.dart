import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/kernel/what/legacy/dart_what_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/what/legacy/disabled_what_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/what/what_library_manager.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/what/what_observation_intake_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_recovery_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> registerWhatKernelServices(
  GetIt sl, {
  bool ensureNativeReady = true,
}) async {
  const bool isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  const bool enableDartWhatFallback = bool.fromEnvironment(
    'AVRAI_ENABLE_DART_WHAT_FALLBACK',
    defaultValue: false,
  );
  const bool useDartWhatFallback = isFlutterTest || enableDartWhatFallback;

  if (!sl.isRegistered<WhatObservationIntakeService>()) {
    sl.registerLazySingleton<WhatObservationIntakeService>(
      () => const WhatObservationIntakeService(),
    );
  }
  if (useDartWhatFallback && !sl.isRegistered<DartWhatFallbackKernel>()) {
    sl.registerLazySingleton<DartWhatFallbackKernel>(
      () => DartWhatFallbackKernel(),
    );
  }
  if (!sl.isRegistered<WhatKernelFallbackSurface>()) {
    sl.registerLazySingleton<WhatKernelFallbackSurface>(
      () => useDartWhatFallback
          ? sl<DartWhatFallbackKernel>()
          : const DisabledWhatFallbackKernel(),
    );
  }
  if (!sl.isRegistered<WhatLibraryManager>()) {
    sl.registerLazySingleton<WhatLibraryManager>(() => WhatLibraryManager());
  }
  if (!sl.isRegistered<WhatNativeInvocationBridge>()) {
    sl.registerLazySingleton<WhatNativeInvocationBridge>(
      () => WhatNativeBridgeBindings(
        libraryManager: sl<WhatLibraryManager>(),
      ),
    );
  }
  if (!sl.isRegistered<WhatNativeExecutionPolicy>()) {
    sl.registerLazySingleton<WhatNativeExecutionPolicy>(
      () => WhatNativeExecutionPolicy(
        requireNative: !useDartWhatFallback,
      ),
    );
  }
  if (!sl.isRegistered<WhatNativeFallbackAudit>()) {
    sl.registerLazySingleton<WhatNativeFallbackAudit>(
      () => WhatNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<InProcessWhatSyscallTransport>()) {
    sl.registerLazySingleton<InProcessWhatSyscallTransport>(
      () => InProcessWhatSyscallTransport(
        delegate: sl<WhatKernelFallbackSurface>(),
      ),
    );
  }
  if (!sl.isRegistered<WhatSyscallTransport>()) {
    sl.registerLazySingleton<WhatSyscallTransport>(
      () => FfiPreferredWhatSyscallTransport(
        nativeBridge: sl<WhatNativeInvocationBridge>(),
        fallbackTransport: sl<InProcessWhatSyscallTransport>(),
        policy: sl<WhatNativeExecutionPolicy>(),
        audit: sl<WhatNativeFallbackAudit>(),
      ),
    );
  }
  if (!sl.isRegistered<WhatNativeKernelStub>()) {
    sl.registerLazySingleton<WhatNativeKernelStub>(
      () => WhatNativeKernelStub(
        transport: sl<WhatSyscallTransport>(),
      ),
    );
  }
  if (!sl.isRegistered<WhatKernelContract>()) {
    sl.registerLazySingleton<WhatKernelContract>(
      () => sl<WhatNativeKernelStub>(),
    );
  }
  if (!sl.isRegistered<WhatRuntimeIngestionService>()) {
    sl.registerLazySingleton<WhatRuntimeIngestionService>(
      () => DefaultWhatRuntimeIngestionService(
        kernel: sl<WhatKernelContract>(),
        intake: sl<WhatObservationIntakeService>(),
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        supabaseService:
            sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
      ),
    );
  }
  if (!sl.isRegistered<WhatRuntimeRecoveryService>() &&
      sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<WhatRuntimeRecoveryService>(
      () => WhatRuntimeRecoveryService(
        kernel: sl<WhatKernelContract>(),
        prefs: sl<SharedPreferences>(),
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        supabaseService:
            sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
      ),
    );
  }

  if (ensureNativeReady) {
    WhatNativeStartupGate.ensureReady(
      nativeBridge: sl<WhatNativeInvocationBridge>(),
      policy: sl<WhatNativeExecutionPolicy>(),
    );
  }
}
