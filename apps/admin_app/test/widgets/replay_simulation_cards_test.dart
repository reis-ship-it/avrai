import 'package:avrai_admin_app/theme/app_theme.dart';
import 'package:avrai_admin_app/ui/widgets/replay_contradiction_dashboard_card.dart';
import 'package:avrai_admin_app/ui/widgets/replay_locality_overlay_card.dart';
import 'package:avrai_admin_app/ui/widgets/replay_scenario_comparison_card.dart';
import 'package:avrai_admin_app/ui/widgets/replay_scenario_packet_card.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    if (getIt.isRegistered<ReplaySimulationAdminService>()) {
      getIt.unregister<ReplaySimulationAdminService>();
    }
    getIt.registerSingleton<ReplaySimulationAdminService>(
      ReplaySimulationAdminService(
        nowProvider: () => DateTime.utc(2026, 3, 14),
      ),
    );
  });

  tearDown(() async {
    if (getIt.isRegistered<ReplaySimulationAdminService>()) {
      await getIt.reset();
    }
  });

  testWidgets('replay simulation cards render core phase-1 content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: const <Widget>[
                ReplayScenarioPacketCard(),
                ReplayScenarioComparisonCard(),
                ReplayContradictionDashboardCard(),
                ReplayLocalityOverlayCard(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Replay Scenario Packets'), findsOneWidget);
    expect(find.text('Replay Branch Comparisons'), findsOneWidget);
    expect(find.text('Replay Contradictions'), findsOneWidget);
    expect(find.text('Birmingham Locality Overlays'), findsOneWidget);
    expect(find.text('Citywide Spring Event'), findsOneWidget);
  });
}
