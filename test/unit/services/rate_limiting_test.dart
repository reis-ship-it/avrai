/// Tests for Rate Limiting Service
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests ensure rate limiting prevents abuse
/// and protects sensitive operations
/// 
/// Phase 7, Section 41 (7.4.3): Backend Completion
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/network/rate_limiting_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('RateLimitingService', () {
    late RateLimitingService service;

    setUp(() {
      service = RateLimitingService();
    });

    group('Rate Limiting Triggers', () {
      test('should allow requests within rate limit', () async {
        const userId = 'user-123';
        const operation = 'data_access';

        // Make requests within limit
        for (int i = 0; i < 10; i++) {
          final allowed = await service.checkRateLimit(userId, operation);

          expect(allowed, isTrue);
        }
      });

      test('should block requests exceeding rate limit', () async {
        const userId = 'user-456';
        const operation = 'data_access';
        const maxRequests = 100; // data_access limit is 100

        // Make requests up to limit
        for (int i = 0; i < maxRequests; i++) {
          await service.checkRateLimit(userId, operation);
        }

        // Next request should be blocked
        final allowed = await service.checkRateLimit(userId, operation);

        expect(allowed, isFalse);
      });

      test('should have different limits for different operations', () async {
        const userId = 'user-789';

        // Sensitive operations should have lower limits
        final sensitiveAllowed = await service.checkRateLimit(
          userId,
          'decrypt_email', // Sensitive - limit is 10
        );
        final normalAllowed = await service.checkRateLimit(
          userId,
          'data_access', // Normal - limit is 100
        );

        expect(sensitiveAllowed, isTrue);
        expect(normalAllowed, isTrue);

        // But sensitive operations should hit limit faster
        // Make 10 requests to sensitive operation (the limit)
        for (int i = 0; i < 10; i++) {
          await service.checkRateLimit(userId, 'decrypt_email');
        }
        // Next request should be blocked
        final sensitiveBlocked = await service.checkRateLimit(userId, 'decrypt_email');
        expect(sensitiveBlocked, isFalse);

        // Normal operation should still be allowed (only used 1 request)
        final normalStillAllowed = await service.checkRateLimit(userId, 'data_access');
        expect(normalStillAllowed, isTrue);
      });

      test('should track rate limits per user', () async {
        const user1 = 'user-1';
        const user2 = 'user-2';
        const operation = 'data_access';

        // User 1 hits limit
        for (int i = 0; i < 100; i++) {
          await service.checkRateLimit(user1, operation);
        }
        final user1Blocked = await service.checkRateLimit(user1, operation);

        // User 2 should still be allowed
        final user2Allowed = await service.checkRateLimit(user2, operation);

        expect(user1Blocked, isFalse);
        expect(user2Allowed, isTrue);
      });
    });

    group('Rate Limit Reset', () {
      test('should reset rate limit after time window', () async {
        const userId = 'user-reset';
        const operation = 'data_access';

        // Hit limit
        for (int i = 0; i < 100; i++) {
          await service.checkRateLimit(userId, operation);
        }
        final blocked = await service.checkRateLimit(userId, operation);
        expect(blocked, isFalse);

        // Manually reset
        await service.resetRateLimit(userId, operation);

        // Should be allowed again
        final allowed = await service.checkRateLimit(userId, operation);
        expect(allowed, isTrue);
      });

      test('should reset rate limit for all operations', () async {
        const userId = 'user-reset-all';

        // Hit limit on multiple operations
        for (int i = 0; i < 10; i++) {
          await service.checkRateLimit(userId, 'decrypt_email');
        }
        await service.checkRateLimit(userId, 'data_access');

        // Reset all
        await service.resetAllRateLimits(userId);

        // Both should be allowed
        expect(await service.checkRateLimit(userId, 'decrypt_email'), isTrue);
        expect(await service.checkRateLimit(userId, 'data_access'), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle rate limit errors gracefully', () async {
        const userId = 'user-error';
        const operation = 'data_access';

        // Hit limit
        for (int i = 0; i < 100; i++) {
          await service.checkRateLimit(userId, operation);
        }

        // Should throw rate limit exception
        expect(
          () => service.checkRateLimit(userId, operation, throwOnLimit: true),
          throwsA(isA<RateLimitException>()),
        );
      });

      test('should provide rate limit information', () async {
        const userId = 'user-info';
        const operation = 'data_access';

        final info = await service.getRateLimitInfo(userId, operation);

        expect(info, isNotNull);
        expect(info.remaining, greaterThanOrEqualTo(0));
        expect(info.limit, greaterThan(0));
        expect(info.resetAt, isNotNull);
      });

      test('should handle concurrent rate limit checks', () async {
        const userId = 'user-concurrent';
        const operation = 'data_access';

        // Make concurrent requests
        final futures = List.generate(10, (_) =>
            service.checkRateLimit(userId, operation));

        final results = await Future.wait(futures);

        // All should be allowed (within limit)
        expect(results.every((allowed) => allowed == true), isTrue);
      });
    });
  });
}
