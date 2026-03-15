import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_native_bridge_bindings.dart';

class InterpretationKernelService {
  InterpretationKernelService({
    InterpretationNativeInvocationBridge? nativeBridge,
  }) : _nativeBridge = nativeBridge ?? InterpretationNativeBridgeBindings();

  final InterpretationNativeInvocationBridge _nativeBridge;

  InterpretationResult interpretHumanText({
    required String rawText,
    String surface = 'chat',
    String channel = 'in_app',
    String locale = 'en-US',
  }) {
    final payload = _invokeRequired(
      syscall: 'interpret_human_text',
      payload: <String, dynamic>{
        'raw_text': rawText,
        'surface': surface,
        'channel': channel,
        'locale': locale,
      },
    );
    return InterpretationResult.fromJson(payload);
  }

  Map<String, dynamic> recordInteractionOutcome({
    required String outcome,
    String repairType = 'none',
  }) {
    return _invokeRequired(
      syscall: 'record_interaction_outcome',
      payload: <String, dynamic>{
        'outcome': outcome,
        'repair_type': repairType,
      },
    );
  }

  Map<String, dynamic> snapshotProfile({
    String profileRef = 'default',
  }) {
    return _invokeRequired(
      syscall: 'snapshot_interpretation_profile',
      payload: <String, dynamic>{'profile_ref': profileRef},
    );
  }

  Map<String, dynamic> diagnose() {
    return _invokeRequired(
      syscall: 'diagnose_interpretation_kernel',
      payload: const <String, dynamic>{},
    );
  }

  Map<String, dynamic> _invokeRequired({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      throw StateError(
        'Native InterpretationKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native InterpretationKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
      'Native InterpretationKernel returned an invalid payload for "$syscall".',
    );
  }
}
