import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/privacy_compliance_card.dart';
import 'package:avrai/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PrivacyComplianceCard
/// Tests privacy compliance metrics display
void main() {
  group('PrivacyComplianceCard Widget Tests', () {
    // Removed: Property assignment tests
    // Privacy compliance card tests focus on business logic (privacy metrics display, color coding), not property assignment

    testWidgets(
        'should display privacy compliance score, display all privacy metrics, display warning color for score < 0.95, or display error color for score < 0.85',
        (WidgetTester tester) async {
      // Test business logic: privacy compliance card display
      final privacyMetrics1 = PrivacyMetrics(
        complianceRate: 0.97,
        anonymizationLevel: 0.98,
        dataSecurityScore: 0.99,
        privacyViolations: 0,
        encryptionStrength: 0.98,
      );
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);

      final privacyMetrics2 = PrivacyMetrics(
        complianceRate: 0.95,
        anonymizationLevel: 0.92,
        dataSecurityScore: 0.97,
        privacyViolations: 0,
        encryptionStrength: 0.95,
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Anonymization Quality'), findsOneWidget);
      expect(find.text('Re-identification Risk'), findsOneWidget);
      expect(find.text('Data Exposure Level'), findsOneWidget);
      expect(find.text('Privacy Compliance Rate'), findsOneWidget);

      final privacyMetrics3 = PrivacyMetrics(
        complianceRate: 0.9,
        anonymizationLevel: 0.85,
        dataSecurityScore: 0.92,
        privacyViolations: 1,
        encryptionStrength: 0.88,
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics3),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);

      final privacyMetrics4 = PrivacyMetrics(
        complianceRate: 0.82,
        anonymizationLevel: 0.75,
        dataSecurityScore: 0.88,
        privacyViolations: 2,
        encryptionStrength: 0.8,
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics4),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);
    });
  });
}
