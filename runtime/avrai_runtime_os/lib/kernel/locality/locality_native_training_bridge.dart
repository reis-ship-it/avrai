import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';

class LocalityNativeTrainingBridge implements LocalityTrainingContract {
  final LocalityNativeInvocationBridge nativeBridge;
  final LocalityTrainingContract fallback;
  final LocalityNativeExecutionPolicy policy;
  final LocalityNativeFallbackAudit? audit;

  const LocalityNativeTrainingBridge({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const LocalityNativeExecutionPolicy(),
    this.audit,
  });

  @override
  Future<LocalityTrainingArtifact> loadBaselineArtifact({
    required String cityProfile,
    required String modelFamily,
  }) async {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(
        syscall: 'load_baseline_artifact',
        payload: {
          'cityProfile': cityProfile,
          'modelFamily': modelFamily,
        },
      );
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        return LocalityTrainingArtifact.fromJson(
          Map<String, dynamic>.from(response['payload'] as Map),
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: 'load_baseline_artifact',
        reason: LocalityNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: 'load_baseline_artifact',
        reason: LocalityNativeFallbackReason.unavailable,
      );
    }
    return fallback.loadBaselineArtifact(
      cityProfile: cityProfile,
      modelFamily: modelFamily,
    );
  }

  @override
  Future<LocalitySimulationBatch> buildBootstrapBatch({
    required String cityProfile,
    int localityCount = 12,
  }) async {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(
        syscall: 'build_bootstrap_batch',
        payload: {
          'cityProfile': cityProfile,
          'localityCount': localityCount,
        },
      );
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        return LocalitySimulationBatch.fromJson(
          Map<String, dynamic>.from(response['payload'] as Map),
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: 'build_bootstrap_batch',
        reason: LocalityNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: 'build_bootstrap_batch',
        reason: LocalityNativeFallbackReason.unavailable,
      );
    }
    return fallback.buildBootstrapBatch(
      cityProfile: cityProfile,
      localityCount: localityCount,
    );
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocality({
    required LocalityTrainingArtifact artifact,
    required LocalitySimulationBatch batch,
  }) async {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(
        syscall: 'evaluate_zero_locality',
        payload: {
          'artifact': artifact.toJson(),
          'batch': batch.toJson(),
        },
      );
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        return LocalityZeroReliabilityReport.fromJson(
          Map<String, dynamic>.from(response['payload'] as Map),
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: 'evaluate_zero_locality',
        reason: LocalityNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: 'evaluate_zero_locality',
        reason: LocalityNativeFallbackReason.unavailable,
      );
    }
    return fallback.evaluateZeroLocality(
      artifact: artifact,
      batch: batch,
    );
  }
}
