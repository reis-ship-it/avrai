import 'package:avrai_admin_app/ui/pages/world_model_ai_page.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('WorldModelAiPage', () {
    tearDown(() async {
      if (GetIt.instance.isRegistered<RealityModelStatusService>()) {
        await GetIt.instance.unregister<RealityModelStatusService>();
      }
    });

    testWidgets('renders port-backed reality-model contract status',
        (WidgetTester tester) async {
      GetIt.instance.registerSingleton<RealityModelStatusService>(
        _FakeRealityModelStatusService(
          RealityModelStatusSnapshot(
            loadedAtUtc: DateTime.utc(2026, 3, 15, 12),
            available: true,
            contract: RealityModelContract(
              contractId: 'reality_model_wave1_bham_beta',
              version: '2026.03-wave1',
              supportedDomains: <RealityModelDomain>[
                RealityModelDomain.event,
                RealityModelDomain.locality,
              ],
              rendererKinds: <RealityExplanationRendererKind>[
                RealityExplanationRendererKind.template,
              ],
              uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
              followUpQuestionsAllowed: true,
              maxEvidenceRefs: 5,
              maxHighlights: 3,
            ),
            mode: 'kernel_backed_wave1',
            boundary: 'reality_model_port',
            summary:
                'Active contract reality_model_wave1_bham_beta (2026.03-wave1) is running in kernel_backed_wave1 mode with 5 bounded evidence refs.',
          ),
        ),
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const WorldModelAiPage(),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      expect(find.text('Reality Model'), findsOneWidget);
      expect(find.text('Active Reality Model Contract'), findsOneWidget);
      expect(find.text('Mode: Kernel Backed Wave1'), findsOneWidget);
      expect(
        find.text('Contract: reality_model_wave1_bham_beta (2026.03-wave1)'),
        findsOneWidget,
      );
    });
  });
}

class _FakeRealityModelStatusService extends RealityModelStatusService {
  _FakeRealityModelStatusService(this.snapshot);

  final RealityModelStatusSnapshot snapshot;

  @override
  Future<RealityModelStatusSnapshot> loadStatus() async => snapshot;
}
