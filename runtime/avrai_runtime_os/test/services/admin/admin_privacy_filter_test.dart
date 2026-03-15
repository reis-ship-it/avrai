import 'package:avrai_runtime_os/services/admin/admin_privacy_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminPrivacyFilter', () {
    test('filters user ids, location history, and raw external payloads', () {
      final filtered = AdminPrivacyFilter.filterPersonalData(
        <String, dynamic>{
          'user_id': 'user-123',
          'current_location': 'Downtown',
          'location_history': <String>['Downtown', 'Midtown'],
          'raw_payload': '<html>secret</html>',
          'ai_signature': 'ai-sig',
          'research_metrics': <String, dynamic>{'promotionReadiness': 0.84},
        },
      );

      expect(filtered.containsKey('user_id'), isFalse);
      expect(filtered.containsKey('current_location'), isFalse);
      expect(filtered.containsKey('location_history'), isFalse);
      expect(filtered.containsKey('raw_payload'), isFalse);
      expect(filtered['ai_signature'], 'ai-sig');
      expect(filtered['research_metrics'], <String, dynamic>{
        'promotionReadiness': 0.84,
      });
    });

    test('sanitizeUserData keeps only redacted admin-safe fields', () {
      final sanitized = AdminPrivacyFilter.sanitizeUserData(
        <String, dynamic>{
          'id': 'agent-1',
          'user_id': 'user-123',
          'ai_signature': 'ai-sig',
          'current_location': 'Downtown',
          'visited_locations': <String>['A', 'B'],
          'location_history': <String>['A', 'B'],
          'is_active': true,
        },
      );

      expect(sanitized['id'], 'agent-1');
      expect(sanitized['ai_signature'], 'ai-sig');
      expect(sanitized['is_active'], isTrue);
      expect(sanitized.containsKey('user_id'), isFalse);
      expect(sanitized.containsKey('current_location'), isFalse);
      expect(sanitized.containsKey('visited_locations'), isFalse);
      expect(sanitized.containsKey('location_history'), isFalse);
      expect(AdminPrivacyFilter.isValid(sanitized), isTrue);
    });
  });
}
