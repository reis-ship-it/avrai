import 'package:avrai_runtime_os/services/admin/admin_identity_redaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminIdentityRedactionService', () {
    const service = AdminIdentityRedactionService();

    test('redacts actor IDs into pseudonymous labels', () {
      final redacted = service.redactActor('real-user-123');

      expect(redacted.displayLabel, startsWith('AG-'));
      expect(redacted.displayLabel, isNot(contains('real-user-123')));
      expect(redacted.initials.length, 2);
      expect(redacted.pseudonymous, isTrue);
    });

    test('redacts email phone and handles from text', () {
      final redacted = service.redactText(
        'Email me at test@example.com or +1 205 555 1010 and ping @reis',
      );

      expect(redacted, isNot(contains('test@example.com')));
      expect(redacted, isNot(contains('205 555 1010')));
      expect(redacted, isNot(contains('@reis')));
      expect(redacted, contains('[redacted-email]'));
      expect(redacted, contains('[redacted-phone]'));
      expect(redacted, contains('@[redacted]'));
    });
  });
}
