import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminRoutePaths', () {
    test('builds encoded deep links for command-center handoffs', () {
      expect(
        AdminRoutePaths.worldSimulationLab,
        '/admin/world-simulation-lab',
      );

      expect(
        AdminRoutePaths.launchSafetyFocusLink(
          focus: 'launch_gate',
          attention: 'launch_safety_blocked',
        ),
        '/admin/launch-safety?focus=launch_gate&attention=launch_safety_blocked',
      );

      expect(
        AdminRoutePaths.ai2AiFocusLink(
          focus: 'mesh rejects',
          attention: 'mesh/rejected',
        ),
        '/admin/ai2ai?focus=mesh+rejects&attention=mesh%2Frejected',
      );

      expect(
        AdminRoutePaths.signatureHealthFocusLink(
          focus: 'upward_learning_source_user_123_msg_1',
          attention: 'source',
        ),
        '/admin/signature-health?focus=upward_learning_source_user_123_msg_1&attention=source',
      );

      expect(
        AdminRoutePaths.worldSimulationLabFocusLink(
          focus: 'atx-replay-world-2024',
          attention: 'served_basis_recovery:restore_review',
        ),
        '/admin/world-simulation-lab?focus=atx-replay-world-2024&attention=served_basis_recovery%3Arestore_review',
      );

      expect(
        AdminRoutePaths.urkKernelsFocusLink(
          view: 'governance',
          focus: 'kernel_availability',
          attention: 'headless_kernel_unavailable',
        ),
        '/admin/urk-kernels?view=governance&focus=kernel_availability&attention=headless_kernel_unavailable',
      );

      expect(
        AdminRoutePaths.kernelGraphRunDetail(
          'kernel_graph:personal_agent_human_intake:user_123:message_123:run',
        ),
        '/admin/kernel-graph-run/kernel_graph%3Apersonal_agent_human_intake%3Auser_123%3Amessage_123%3Arun',
      );
    });
  });
}
