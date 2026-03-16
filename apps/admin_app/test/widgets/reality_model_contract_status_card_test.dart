import 'package:avrai_admin_app/theme/app_theme.dart';
import 'package:avrai_admin_app/ui/widgets/reality_model_contract_status_card.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders active contract mode and domains',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RealityModelContractStatusCard(
            surfaceLabel: 'Reality Oversight',
            service: _FakeRealityModelStatusService(
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
                  uncertaintyDisposition:
                      RealityUncertaintyDisposition.neverBluff,
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
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Active Reality Model Contract'), findsOneWidget);
    expect(find.textContaining('kernel_backed_wave1 mode'), findsOneWidget);
    expect(find.text('Mode: Kernel Backed Wave1'), findsOneWidget);
    expect(find.textContaining('Supported domains: Event, Locality'),
        findsOneWidget);
    expect(
      find.text('Contract: reality_model_wave1_bham_beta (2026.03-wave1)'),
      findsOneWidget,
    );
  });
}

class _FakeRealityModelStatusService extends RealityModelStatusService {
  _FakeRealityModelStatusService(this.snapshot);

  final RealityModelStatusSnapshot snapshot;

  @override
  Future<RealityModelStatusSnapshot> loadStatus() async => snapshot;
}
