import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_user_runtime_learning_intake_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkUserRuntimeLearningIntakeContract', () {
    late UrkUserRuntimeLearningIntakeContract contract;

    setUp(() {
      contract = UrkUserRuntimeLearningIntakeContract();
    });

    test('accepts valid pseudonymous user-runtime learning signal', () {
      final result = contract.validate(
        const UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: 'agt_123456789',
          signalType: 'recommendation_feedback',
          consentScopes: <String>{'user_runtime_learning'},
          containsSensitiveRawContent: false,
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.reasonCode, 'accepted');
      expect(result.pseudonymousActorRef, startsWith('anon_'));
    });

    test('rejects non-agent actor identifiers', () {
      final result = contract.validate(
        const UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: 'user_abc',
          signalType: 'recommendation_feedback',
          consentScopes: <String>{'user_runtime_learning'},
          containsSensitiveRawContent: false,
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'invalid_actor_agent_id');
    });

    test('rejects missing user_runtime_learning consent', () {
      final result = contract.validate(
        const UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: 'agt_123456789',
          signalType: 'in_app_behavior',
          consentScopes: <String>{'calendar_read'},
          containsSensitiveRawContent: false,
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'missing_user_runtime_learning_consent');
    });

    test('rejects sensitive raw content and unsupported signals', () {
      final sensitiveResult = contract.validate(
        const UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: 'agt_123456789',
          signalType: 'in_app_behavior',
          consentScopes: <String>{'user_runtime_learning'},
          containsSensitiveRawContent: true,
        ),
      );
      expect(sensitiveResult.accepted, isFalse);
      expect(sensitiveResult.reasonCode, 'sensitive_raw_content_blocked');

      final unsupportedResult = contract.validate(
        const UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: 'agt_123456789',
          signalType: 'unsupported',
          consentScopes: <String>{'user_runtime_learning'},
          containsSensitiveRawContent: false,
        ),
      );
      expect(unsupportedResult.accepted, isFalse);
      expect(unsupportedResult.reasonCode, 'unsupported_signal_type');
    });
  });
}
