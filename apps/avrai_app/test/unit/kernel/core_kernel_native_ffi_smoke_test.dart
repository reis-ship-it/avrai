import 'dart:io';

import 'package:avrai_runtime_os/kernel/how/how_library_manager.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_priority.dart';
import 'package:avrai_runtime_os/kernel/how/legacy/disabled_how_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/what/legacy/disabled_what_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/what/what_library_manager.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:avrai_runtime_os/kernel/when/legacy/disabled_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/when/when_library_manager.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'package:avrai_runtime_os/kernel/who/legacy/disabled_who_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/who_library_manager.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_priority.dart';
import 'package:avrai_runtime_os/kernel/why/legacy/disabled_why_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_priority.dart';
import 'package:avrai_runtime_os/kernel/why/why_library_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core kernel FFI smoke', () {
    test('when kernel serves native timestamp and diagnostics', () async {
      if (!_hasKernelLibrary(
        const <String>[
          'runtime/avrai_network/native/when_kernel/macos/libavrai_when_kernel.dylib',
          'runtime/avrai_network/native/when_kernel/target/debug/libavrai_when_kernel.dylib',
          'runtime/avrai_network/native/when_kernel/target/release/libavrai_when_kernel.dylib',
        ],
      )) {
        return;
      }

      final audit = WhenNativeFallbackAudit();
      final stub = WhenNativeKernelStub(
        nativeBridge: WhenNativeBridgeBindings(
          libraryManager: WhenLibraryManager(),
        ),
        fallback: const DisabledWhenFallbackKernel(),
        policy: const WhenNativeExecutionPolicy(requireNative: true),
        audit: audit,
      );

      final timestamp = await stub.issueTimestamp(
        WhenTimestampRequest(
          referenceId: 'ffi-event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 10, 18),
        ),
      );
      final reality = await stub.projectForRealityModel(
        const KernelProjectionRequest(subjectId: 'ffi-event-1'),
      );
      final health = await stub.diagnoseWhen();

      expect(timestamp.observedAtUtc, DateTime.utc(2026, 3, 10, 18));
      expect(timestamp.quantumAtomicTick, greaterThan(0));
      expect(reality.summary, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(3));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });

    test('who kernel serves native identity continuity and diagnostics',
        () async {
      if (!_hasKernelLibrary(
        const <String>[
          'runtime/avrai_network/native/who_kernel/target/debug/libavrai_who_kernel.dylib',
          'runtime/avrai_network/native/who_kernel/target/release/libavrai_who_kernel.dylib',
        ],
      )) {
        return;
      }

      final audit = WhoNativeFallbackAudit();
      final stub = WhoNativeKernelStub(
        nativeBridge: WhoNativeBridgeBindings(
          libraryManager: WhoLibraryManager(),
        ),
        fallback: const DisabledWhoFallbackKernel(),
        policy: const WhoNativeExecutionPolicy(requireNative: true),
        audit: audit,
      );

      final binding = await stub.bindRuntime(
        const WhoRuntimeBindingRequest(
          runtimeId: 'ffi-runtime-1',
          actorId: 'ffi-agent-1',
        ),
      );
      final signature = await stub.sign(
        const WhoSigningRequest(
          actorId: 'ffi-agent-1',
          payload: <String, dynamic>{'scope': 'private'},
        ),
      );
      final verification = await stub.verify(
        WhoVerificationRequest(
          actorId: 'ffi-agent-1',
          payload: const <String, dynamic>{'scope': 'private'},
          signature: signature.signature,
        ),
      );
      final governance = await stub.projectForGovernance(
        const KernelProjectionRequest(subjectId: 'ffi-agent-1'),
      );
      final health = await stub.diagnoseWho();

      expect(binding.continuityRef, isNotEmpty);
      expect(verification.valid, isTrue);
      expect(governance.summary, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(5));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });

    test('how kernel serves native planning and diagnostics', () async {
      if (!_hasKernelLibrary(
        const <String>[
          'runtime/avrai_network/native/how_kernel/target/debug/libavrai_how_kernel.dylib',
          'runtime/avrai_network/native/how_kernel/target/release/libavrai_how_kernel.dylib',
        ],
      )) {
        return;
      }

      final audit = HowNativeFallbackAudit();
      final stub = HowNativeKernelStub(
        nativeBridge: HowNativeBridgeBindings(
          libraryManager: HowLibraryManager(),
        ),
        fallback: const DisabledHowFallbackKernel(),
        policy: const HowNativeExecutionPolicy(requireNative: true),
        audit: audit,
      );

      final plan = await stub.planHow(
        const HowPlanningRequest(
          executionId: 'ffi-exec-1',
          goal: 'recommend_event',
        ),
      );
      final trace = await stub.executeHow(plan);
      final health = await stub.diagnoseHow();

      expect(plan.path, isNotEmpty);
      expect(trace.status, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(3));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });

    test('why kernel serves native causal reasoning and diagnostics',
        () async {
      if (!_hasKernelLibrary(
        const <String>[
          'runtime/avrai_network/native/why_kernel/target/debug/libavrai_why_kernel.dylib',
          'runtime/avrai_network/native/why_kernel/target/release/libavrai_why_kernel.dylib',
        ],
      )) {
        return;
      }

      final audit = WhyNativeFallbackAudit();
      final stub = WhyNativeKernelStub(
        nativeBridge: WhyNativeBridgeBindings(
          libraryManager: WhyLibraryManager(),
        ),
        fallback: const DisabledWhyFallbackKernel(),
        policy: const WhyNativeExecutionPolicy(requireNative: true),
        audit: audit,
      );
      const request = KernelWhyRequest(
        bundle: KernelContextBundleWithoutWhy(),
        goal: 'recommend_event',
        actualOutcome: 'generated',
        actualOutcomeScore: 1.0,
      );

      final conviction = stub.convictionWhy(request);
      final anomaly = stub.anomalyWhy(request);
      final governance = await stub.projectForGovernance(
        const KernelProjectionRequest(subjectId: 'recommend_event'),
      );
      final health = await stub.diagnoseWhy();

      expect(conviction.summary, isNotEmpty);
      expect(anomaly.summary, isNotEmpty);
      expect(governance.summary, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(4));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });

    test('what kernel serves native semantic projection and diagnostics',
        () async {
      if (!_hasKernelLibrary(
        const <String>[
          'runtime/avrai_network/native/what_kernel/macos/libavrai_what_kernel.dylib',
          'runtime/avrai_network/native/what_kernel/target/debug/libavrai_what_kernel.dylib',
          'runtime/avrai_network/native/what_kernel/target/release/libavrai_what_kernel.dylib',
        ],
      )) {
        return;
      }

      final audit = WhatNativeFallbackAudit();
      final stub = WhatNativeKernelStub(
        transport: FfiPreferredWhatSyscallTransport(
          nativeBridge: WhatNativeBridgeBindings(
            libraryManager: WhatLibraryManager(),
          ),
          fallbackTransport: InProcessWhatSyscallTransport(
            delegate: const DisabledWhatFallbackKernel(),
          ),
          policy: const WhatNativeExecutionPolicy(requireNative: true),
          audit: audit,
        ),
      );

      final state = await stub.resolveWhat(
        WhatPerceptionInput(
          agentId: 'ffi-agent-1',
          observedAtUtc: DateTime.utc(2026, 3, 10, 18),
          source: 'ffi_smoke',
          entityRef: 'spot:cafe',
          candidateLabels: const <String>['coffee shop'],
        ),
      );
      final reality = await stub.projectForRealityModel(
        const WhatProjectionRequest(
          agentId: 'ffi-agent-1',
          entityRef: 'spot:cafe',
        ),
      );
      final health = await stub.diagnoseWhat();

      expect(state.canonicalType, isNotEmpty);
      expect(reality.summary, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(3));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });
  });
}

bool _hasKernelLibrary(List<String> relativePaths) {
  final currentDir = Directory.current.path;
  return relativePaths
      .map((path) => File('$currentDir/$path'))
      .any((file) => file.existsSync());
}
