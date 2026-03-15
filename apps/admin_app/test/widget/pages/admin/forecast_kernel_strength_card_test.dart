import 'package:avrai_admin_app/ui/widgets/forecast_kernel_strength_card.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/forecast_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockForecastKernelAdminService extends Mock
    implements ForecastKernelAdminService {}

void main() {
  group('ForecastKernelStrengthCard', () {
    late GetIt getIt;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
    });

    tearDown(() {
      getIt = GetIt.instance;
      if (getIt.isRegistered<ForecastKernelAdminService>()) {
        getIt.unregister<ForecastKernelAdminService>();
      }
    });

    testWidgets('renders unavailable state when service is absent', (
      tester,
    ) async {
      getIt = GetIt.instance;
      if (getIt.isRegistered<ForecastKernelAdminService>()) {
        getIt.unregister<ForecastKernelAdminService>();
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForecastKernelStrengthCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forecast Strength Kernel'), findsOneWidget);
      expect(
        find.text('Forecast kernel diagnostics are not registered.'),
        findsOneWidget,
      );
    });

    testWidgets('renders forecast snapshot details when service is present', (
      tester,
    ) async {
      getIt = GetIt.instance;
      final service = MockForecastKernelAdminService();
      if (getIt.isRegistered<ForecastKernelAdminService>()) {
        getIt.unregister<ForecastKernelAdminService>();
      }
      getIt.registerSingleton<ForecastKernelAdminService>(service);

      when(
        () => service.watchForecastSnapshot(
          lookbackWindow: any(named: 'lookbackWindow'),
          refreshInterval: any(named: 'refreshInterval'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => Stream.value(_buildSnapshot()));
      when(
        () => service.getForecastSnapshot(),
      ).thenAnswer((_) async => _buildSnapshot());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ForecastKernelStrengthCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forecast Strength Kernel'), findsOneWidget);
      expect(find.textContaining('Issued: 1'), findsOneWidget);
      expect(find.textContaining('family • positive'), findsOneWidget);
    });
  });
}

ForecastKernelAdminSnapshot _buildSnapshot() {
  const truthScope = TruthScopeDescriptor.defaultForecast(
    governanceStratum: GovernanceStratum.locality,
    agentClass: TruthAgentClass.business,
    sphereId: 'bham_replay',
    familyId: 'family',
  );
  return ForecastKernelAdminSnapshot(
    generatedAt: DateTime.utc(2025, 4, 2, 12),
    windowStart: DateTime.utc(2025, 4, 1, 12),
    windowEnd: DateTime.utc(2025, 4, 2, 12),
    issuedCount: 1,
    resolvedCount: 1,
    averageOutcomeProbability: 0.74,
    averageForecastStrength: 0.68,
    averageActionability: 0.41,
    averageSupportQuality: 0.84,
    averageCalibrationGap: 0.14,
    averageChangeRisk: 0.12,
    averageSkillLowerConfidenceBound: 0.11,
    bandCounts: const <String, int>{'Guarded': 1},
    dispositionCounts: const <String, int>{'admittedWithCaution': 1},
    strengthTrend: const <double>[0.68],
    recentForecasts: <ForecastKernelAdminForecastRow>[
      ForecastKernelAdminForecastRow(
        forecastId: 'forecast-1',
        subjectId: 'venue:saturn',
        forecastFamilyId: 'family',
        truthScope: truthScope,
        sphereId: 'bham_replay',
        governanceStratum: GovernanceStratum.locality,
        agentClass: TruthAgentClass.business,
        tenantScope: TruthTenantScope.avraiNative,
        tenantId: null,
        predictedOutcome: 'positive',
        band: ForecastStrengthBand.guarded,
        disposition: 'admittedWithCaution',
        issuedAt: DateTime.utc(2025, 4, 2, 11),
        outcomeProbability: 0.74,
        forecastStrength: 0.68,
        actionability: 0.41,
        supportQuality: 0.84,
        calibrationGap: 0.14,
        changeRisk: 0.12,
        skillLowerConfidenceBound: 0.11,
        warmingUp: true,
        representationMix: const <String, int>{'classical': 1},
      ),
    ],
  );
}
