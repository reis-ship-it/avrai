import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/security/security_validator.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('SecurityValidator Tests', () {
    late SecurityValidator validator;

    setUp(() {
      validator = SecurityValidator();
    });

    group('validateDataEncryption', () {
      test('validates encryption successfully', () async {
        // Act
        final result = await validator.validateDataEncryption();

        // Assert
        expect(result, isNotNull);
        expect(result.isCompliant, isTrue);
        expect(result.details, isNotEmpty);
      });
    });

    group('validateAuthenticationSecurity', () {
      test('validates authentication security', () async {
        // Act
        final result = await validator.validateAuthenticationSecurity();

        // Assert
        expect(result, isNotNull);
        expect(result.isCompliant, isTrue);
      });
    });

    group('validatePrivacyProtection', () {
      test('validates privacy protection', () async {
        // Act
        final result = await validator.validatePrivacyProtection();

        // Assert
        expect(result, isNotNull);
        expect(result.isCompliant, isTrue);
      });
    });

    group('auditSecurity', () {
      test('performs comprehensive security audit', () async {
        // Act
        final report = await validator.auditSecurity();

        // Assert
        expect(report, isNotNull);
        expect(report.overallScore, greaterThanOrEqualTo(0.0));
        expect(report.overallScore, lessThanOrEqualTo(1.0));
        expect(report.auditTimestamp, isNotNull);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
