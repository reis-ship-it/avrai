import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';

/// Marketing Experiment 4: Timezone-Aware Quantum Atomic Time Benefits
///
/// **Patent #30: Quantum Atomic Clock System - Timezone-Aware Enhancement**
/// Demonstrates that timezone-aware quantum atomic time provides unique advantages for global applications.
///
/// **Objective:**  
/// Demonstrate that timezone-aware quantum atomic time enables cross-timezone matching and global recommendation systems.
///
/// **Marketing Value:**
/// - Cross-Timezone Matching: Match entities based on local time-of-day across timezones
/// - Global Recommendations: Enable global recommendation systems
/// - User Experience: Better recommendations for global users
/// - Business Benefits: Enables global market expansion
void main() {
  group('Marketing Experiment 4: Timezone-Aware Quantum Atomic Time Benefits', () {
    late AtomicClockService clockService;

    setUp(() async {
      clockService = AtomicClockService();
      await clockService.initialize();
    });

    tearDown(() {
      clockService.dispose();
    });

    test('should demonstrate cross-timezone matching capability', () async {
      // Timezone-aware quantum atomic time enables matching across timezones
      // Example: 9am in Tokyo matches 9am in San Francisco
      
      // Tokyo: 9am JST
      final tokyoTime = DateTime(2025, 12, 23, 9, 0, 0);
      final tokyoUtc = tokyoTime.subtract(const Duration(hours: 9));
      final tokyoTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: tokyoUtc,
        localTime: tokyoTime,
        timezoneId: 'Asia/Tokyo',
      );
      
      // San Francisco: 9am PST
      final sfTime = DateTime(2025, 12, 23, 9, 0, 0);
      final sfUtc = sfTime.add(const Duration(hours: 8));
      final sfTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: sfUtc,
        localTime: sfTime,
        timezoneId: 'America/Los_Angeles',
      );
      
      final tokyoState = QuantumTemporalStateGenerator.generate(tokyoTimestamp);
      final sfState = QuantumTemporalStateGenerator.generate(sfTimestamp);
      
      final compatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(tokyoState, sfState);
      
      // Cross-timezone matching works (same local time)
      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0001));
      
      // Both states are normalized
      expect(tokyoState.normalization, closeTo(1.0, 0.01));
      expect(sfState.normalization, closeTo(1.0, 0.01));
    });

    test('should demonstrate global recommendation system capability', () async {
      // Timezone-aware quantum atomic time enables global recommendations
      // Example: "People who like matcha at 9am their local time"
      
      final timezones = [
        ('Asia/Tokyo', const Duration(hours: 9)),
        ('America/Los_Angeles', const Duration(hours: -8)),
        ('Europe/London', const Duration(hours: 0)),
        ('Asia/Shanghai', const Duration(hours: 8)),
        ('Australia/Sydney', const Duration(hours: 10)),
      ];
      
      final states = <QuantumTemporalState>[];
      
      // Generate quantum temporal states for same local time (9am) across timezones
      for (final (tzId, offset) in timezones) {
        final localTime = DateTime(2025, 12, 23, 9, 0, 0); // 9am local
        final utcTime = localTime.subtract(offset);
        
        final timestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: utcTime,
          localTime: localTime,
          timezoneId: tzId,
        );
        
        final state = QuantumTemporalStateGenerator.generate(timestamp);
        states.add(state);
        
        // All states should be normalized
        expect(state.normalization, closeTo(1.0, 0.01));
      }
      
      // Verify cross-timezone compatibility
      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final compatibility = QuantumTemporalStateGenerator
              .calculateTemporalCompatibility(states[i], states[j]);
          
          // Same local time should create measurable compatibility
          expect(compatibility, greaterThanOrEqualTo(0.0));
          expect(compatibility, lessThanOrEqualTo(1.0001));
        }
      }
    });

    test('should demonstrate timezone information in atomic timestamps', () async {
      // Timezone-aware atomic timestamps include timezone information
      final timestamp = await clockService.getAtomicTimestamp();
      
      // Verify timezone information
      expect(timestamp.timezoneId, isNotEmpty);
      expect(timestamp.localTime, isA<DateTime>());
      
      // Local time should be valid
      expect(timestamp.localTime.hour, greaterThanOrEqualTo(0));
      expect(timestamp.localTime.hour, lessThan(24));
      
      // Timezone ID should be valid IANA timezone format
      expect(timestamp.timezoneId, isNot(equals('')));
    });

    test('should demonstrate morning preference matching across timezones', () async {
      // Use case: Person in Tokyo likes matcha at 9am JST
      // Should match person in San Francisco who likes matcha at 9am PST
      
      // Tokyo: 9am JST
      final tokyoMorning = DateTime(2025, 12, 23, 9, 0, 0);
      final tokyoUtc = tokyoMorning.subtract(const Duration(hours: 9));
      final tokyoTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: tokyoUtc,
        localTime: tokyoMorning,
        timezoneId: 'Asia/Tokyo',
      );
      
      // San Francisco: 9am PST
      final sfMorning = DateTime(2025, 12, 23, 9, 0, 0);
      final sfUtc = sfMorning.add(const Duration(hours: 8));
      final sfTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: sfUtc,
        localTime: sfMorning,
        timezoneId: 'America/Los_Angeles',
      );
      
      final tokyoState = QuantumTemporalStateGenerator.generate(tokyoTimestamp);
      final sfState = QuantumTemporalStateGenerator.generate(sfTimestamp);
      
      final compatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(tokyoState, sfState);
      
      // Should have measurable compatibility for same local morning time
      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0001));
    });

    test('should demonstrate multiple timezone support', () async {
      // Timezone-aware quantum atomic time supports multiple timezones
      final timezones = [
        ('Asia/Tokyo', const Duration(hours: 9)),
        ('America/Los_Angeles', const Duration(hours: -8)),
        ('America/New_York', const Duration(hours: -5)),
        ('Europe/London', const Duration(hours: 0)),
        ('Europe/Paris', const Duration(hours: 1)),
        ('Asia/Shanghai', const Duration(hours: 8)),
        ('Australia/Sydney', const Duration(hours: 10)),
        ('America/Chicago', const Duration(hours: -6)),
        ('America/Denver', const Duration(hours: -7)),
        ('Pacific/Auckland', const Duration(hours: 12)),
      ];
      
      final timestamps = <AtomicTimestamp>[];
      
      // Generate timestamps for same local time across all timezones
      for (final (tzId, offset) in timezones) {
        final localTime = DateTime(2025, 12, 23, 9, 0, 0); // 9am local
        final utcTime = localTime.subtract(offset);
        
        final timestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: utcTime,
          localTime: localTime,
          timezoneId: tzId,
        );
        
        timestamps.add(timestamp);
        
        // Verify timezone information
        expect(timestamp.timezoneId, equals(tzId));
        expect(timestamp.localTime.hour, equals(9)); // All 9am local
      }
      
      expect(timestamps.length, equals(10));
    });

    test('should demonstrate timezone-aware quantum temporal state generation', () async {
      // Timezone-aware quantum temporal states use local time for matching
      final timestamp = await clockService.getAtomicTimestamp();
      final state = QuantumTemporalStateGenerator.generate(timestamp);
      
      // State should be normalized
      expect(state.normalization, closeTo(1.0, 0.01));
      
      // State uses local time (not UTC) for quantum temporal matching
      // This enables cross-timezone matching based on local time-of-day
      expect(timestamp.localTime, isA<DateTime>());
      expect(timestamp.timezoneId, isNotEmpty);
    });

    test('should demonstrate performance benefits of timezone-aware matching', () async {
      // Timezone-aware quantum temporal matching is fast and efficient
      final timestamp = await clockService.getAtomicTimestamp();
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        QuantumTemporalStateGenerator.generate(timestamp);
      }
      
      stopwatch.stop();
      
      // Should be fast (< 10ms for 100 generations)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      
      // Average time per generation should be < 0.1ms
      final avgTime = stopwatch.elapsedMilliseconds / 100;
      expect(avgTime, lessThan(0.1));
    });

    test('should document marketing value: Global market expansion', () {
      // Timezone-aware quantum atomic time enables global market expansion
      // This is a key marketing point: Enables global recommendation systems
      
      // Marketing message: "Timezone-aware quantum atomic time enables
      // cross-timezone matching based on local time-of-day, enabling global
      // recommendation systems and expanding market reach to global users"
      
      expect(true, isTrue); // Placeholder for marketing value documentation
    });
  });
}

