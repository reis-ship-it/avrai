import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/expression/expression_native_bridge_bindings.dart';

class ExpressionKernelService {
  ExpressionKernelService({
    ExpressionNativeInvocationBridge? nativeBridge,
  }) : _nativeBridge = nativeBridge ?? ExpressionNativeBridgeBindings();

  final ExpressionNativeInvocationBridge _nativeBridge;

  ExpressionPlan compileUtterancePlan({
    required ExpressionSpeechAct speechAct,
    required ExpressionAudience audience,
    required ExpressionSurfaceShape surfaceShape,
    required String subjectLabel,
    required List<String> allowedClaims,
    List<String> forbiddenClaims = const <String>[],
    List<String> evidenceRefs = const <String>[],
    String confidenceBand = 'medium',
    String toneProfile = 'clear_calm',
    VibeExpressionContext? vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    final payload = _invokeRequired(
      syscall: 'compile_utterance_plan',
      payload: <String, dynamic>{
        'speech_act': speechAct.toWireValue(),
        'audience': audience.toWireValue(),
        'surface_shape': surfaceShape.toWireValue(),
        'subject_label': subjectLabel,
        'allowed_claims': allowedClaims,
        'forbidden_claims': forbiddenClaims,
        'evidence_refs': evidenceRefs,
        'confidence_band': confidenceBand,
        'tone_profile': toneProfile,
        if (vibeContext != null) 'vibe_context': vibeContext.toJson(),
        if (uncertaintyNotice != null) 'uncertainty_notice': uncertaintyNotice,
        if (cta != null) 'cta': cta,
        if (adaptationProfileRef != null)
          'adaptation_profile_ref': adaptationProfileRef,
      },
    );
    return ExpressionPlan.fromJson(payload);
  }

  RenderedExpression renderDeterministic(ExpressionPlan plan) {
    final payload = _invokeRequired(
      syscall: 'render_deterministic',
      payload: <String, dynamic>{'plan': plan.toJson()},
    );
    return RenderedExpression.fromJson(payload);
  }

  ExpressionValidationResult validateUtterance({
    required List<String> allowedClaims,
    required List<String> assertedClaims,
    List<String> forbiddenClaims = const <String>[],
  }) {
    final payload = _invokeRequired(
      syscall: 'validate_utterance',
      payload: <String, dynamic>{
        'allowed_claims': allowedClaims,
        'asserted_claims': assertedClaims,
        'forbidden_claims': forbiddenClaims,
      },
    );
    return ExpressionValidationResult.fromJson(payload);
  }

  Map<String, dynamic> recordExpressionFeedback({
    required String feedback,
    required String surface,
    String adaptationProfileRef = 'default',
  }) {
    return _invokeRequired(
      syscall: 'record_expression_feedback',
      payload: <String, dynamic>{
        'feedback': feedback,
        'surface': surface,
        'adaptation_profile_ref': adaptationProfileRef,
      },
    );
  }

  Map<String, dynamic> diagnose() {
    return _invokeRequired(
      syscall: 'diagnose_expression_kernel',
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
        'Native ExpressionKernel is required but unavailable for "$syscall".',
      );
    }
    final response = _nativeBridge.invoke(
      syscall: syscall,
      payload: payload,
    );
    if (response['handled'] != true) {
      throw StateError('Native ExpressionKernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
      'Native ExpressionKernel returned an invalid payload for "$syscall".',
    );
  }
}
