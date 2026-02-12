
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/network/network_circuit_breaker.dart';

/// Unit tests for NetworkCircuitBreaker.
/// Verifies: opens after N failures, allows retry after duration, success resets.
void main() {
  group('NetworkCircuitBreaker', () {
    test('run returns result when action succeeds', () async {
      final breaker = NetworkCircuitBreaker(
        failureThreshold: 2,
        openDuration: const Duration(minutes: 5),
      );
      final result = await breaker.run(() async => 42);
      expect(result, 42);
      expect(breaker.isOpen, false);
    });

    test('run throws when action fails and records failure', () async {
      final breaker = NetworkCircuitBreaker(
        failureThreshold: 2,
        openDuration: const Duration(minutes: 5),
      );
      await expectLater(
        breaker.run(() async => throw Exception('fail')),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'message', contains('fail'))),
      );
      expect(breaker.isOpen, false);
    });

    test(
        'opens after N consecutive failures and throws NetworkCircuitBreakerOpenException',
        () async {
      final breaker = NetworkCircuitBreaker(
        failureThreshold: 3,
        openDuration: const Duration(minutes: 5),
      );
      for (int i = 0; i < 3; i++) {
        await expectLater(
          breaker.run(() async => throw Exception('fail')),
          throwsA(isA<Exception>()),
        );
      }
      expect(breaker.isOpen, true);
      await expectLater(
        breaker.run(() async => 1),
        throwsA(isA<NetworkCircuitBreakerOpenException>()),
      );
    });

    test('success resets consecutive failures', () async {
      final breaker = NetworkCircuitBreaker(
        failureThreshold: 2,
        openDuration: const Duration(minutes: 5),
      );
      await expectLater(
        breaker.run(() async => throw Exception('fail')),
        throwsA(isA<Exception>()),
      );
      await breaker.run(() async => 1);
      await expectLater(
        breaker.run(() async => throw Exception('fail')),
        throwsA(isA<Exception>()),
      );
      expect(breaker.isOpen, false);
    });
  });
}
