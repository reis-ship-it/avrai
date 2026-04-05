import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_runtime_os/kernel/boundary/boundary_native_bridge_bindings.dart';

class BoundaryKernelService {
  BoundaryKernelService({
    BoundaryNativeInvocationBridge? nativeBridge,
  }) : _nativeBridge = nativeBridge ?? BoundaryNativeBridgeBindings();

  final BoundaryNativeInvocationBridge _nativeBridge;

  BoundaryDecision enforceBoundary({
    required String actorAgentId,
    required String rawText,
    required InterpretationResult interpretation,
    required Set<String> consentScopes,
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    bool shareRequested = false,
    BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.none,
  }) {
    final payload = _invokeRequired(
      syscall: 'enforce_boundary',
      payload: <String, dynamic>{
        'actor_agent_id': actorAgentId,
        'raw_text': rawText,
        'interpretation': interpretation.toJson(),
        'consent_scopes': consentScopes.toList(growable: false),
        'privacy_mode': privacyMode.toWireValue(),
        'share_requested': shareRequested,
        'egress_purpose': egressPurpose.toWireValue(),
      },
    );
    return BoundaryDecision.fromJson(payload);
  }

  Map<String, dynamic> compileAirGapTransfer(BoundaryDecision decision) {
    return _invokeRequired(
      syscall: 'compile_air_gap_transfer',
      payload: <String, dynamic>{'decision': decision.toJson()},
    );
  }

  Map<String, dynamic> diagnose() {
    return _invokeRequired(
      syscall: 'diagnose_boundary_kernel',
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
        'Native BoundaryKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      throw StateError('Native BoundaryKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
      'Native BoundaryKernel returned an invalid payload for "$syscall".',
    );
  }
}
