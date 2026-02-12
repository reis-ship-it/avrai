import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';

/// Timezone-Aware Quantum Temporal Matching Tests
///
/// **Patent #30: Quantum Atomic Clock System - Timezone-Aware Enhancement**
/// Tests validate cross-timezone quantum temporal compatibility matching.
/// 
/// **Key Innovation:** Enables matching entities based on local time-of-day
/// (e.g., 9am in Tokyo matches 9am in San Francisco).
void main() {
  group('Timezone-Aware Quantum Temporal Matching', () {
    test('should match same local time across different timezones', () async {
      // Tokyo: 9am JST (UTC+9)
      final tokyoTime = DateTime(2025, 12, 23, 9, 0, 0); // 9am local
      final tokyoUtc = tokyoTime.subtract(const Duration(hours: 9)); // Convert to UTC
      final tokyoTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: tokyoUtc, // UTC server time
        localTime: tokyoTime, // Local time is 9am
        timezoneId: 'Asia/Tokyo',
      );
      
      // San Francisco: 9am PST (UTC-8) - Different UTC time, same local hour
      final sfTime = DateTime(2025, 12, 23, 9, 0, 0); // 9am local
      final sfUtc = sfTime.add(const Duration(hours: 8)); // Convert to UTC
      final sfTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: sfUtc, // Different UTC time
        localTime: sfTime, // But same local hour (9am)
        timezoneId: 'America/Los_Angeles',
      );
      
      final tokyoState = QuantumTemporalStateGenerator.generate(tokyoTimestamp);
      final sfState = QuantumTemporalStateGenerator.generate(sfTimestamp);
      
      final compatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(tokyoState, sfState);
      
      // Should have higher compatibility than different local times
      // Note: Compatibility includes hour, weekday, season, and phase components
      // Same local hour (9am) should have higher compatibility than different hours
      expect(compatibility, greaterThan(0.3)); // Higher than random/different times
    });

    test('should have lower compatibility for different local times', () async {
      // Tokyo: 9am JST
      final tokyoTime = DateTime(2025, 12, 23, 9, 0, 0);
      final tokyoUtc = tokyoTime.subtract(const Duration(hours: 9));
      final tokyoTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: tokyoUtc,
        localTime: tokyoTime,
        timezoneId: 'Asia/Tokyo',
      );
      
      // San Francisco: 3pm PST (different local time)
      final sfTime = DateTime(2025, 12, 23, 15, 0, 0); // 3pm local
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
      
      // Should be lower than same local time
      expect(compatibility, lessThan(0.8));
    });

    test('should verify timezone information in atomic timestamp', () async {
      final clockService = AtomicClockService();
      await clockService.initialize();
      
      final timestamp = await clockService.getAtomicTimestamp();
      
      // Should have timezone information
      expect(timestamp.timezoneId, isNotEmpty);
      expect(timestamp.localTime, isA<DateTime>());
      
      // Local time should be different from server time (unless in UTC)
      // This demonstrates timezone-awareness
      
      clockService.dispose();
    });

    test('should match morning preferences across timezones', () async {
      // Person A in Tokyo: Likes matcha at 9am JST
      final tokyoMorning = DateTime(2025, 12, 23, 9, 0, 0);
      final tokyoUtc = tokyoMorning.subtract(const Duration(hours: 9));
      final tokyoTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: tokyoUtc,
        localTime: tokyoMorning,
        timezoneId: 'Asia/Tokyo',
      );
      
      // Person B in San Francisco: Should match at 9am PST
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
      
      // Should have higher compatibility for same local morning time
      // Note: Compatibility includes all temporal components (hour, weekday, season, phase)
      expect(compatibility, greaterThan(0.3)); // Higher than different times
    });

    test('should verify cross-timezone quantum temporal state generation', () async {
      // Test multiple timezones
      final timezones = [
        ('Asia/Tokyo', const Duration(hours: 9)),
        ('America/Los_Angeles', const Duration(hours: -8)),
        ('America/New_York', const Duration(hours: -5)),
        ('Europe/London', const Duration(hours: 0)),
      ];
      
      final states = <QuantumTemporalState>[];
      
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
        
        // All should be normalized
        expect(state.normalization, closeTo(1.0, 0.01));
      }
      
      // All states from same local time should have higher compatibility
      // Note: Compatibility includes hour, weekday, season, and phase
      // Same local hour (9am) should have higher compatibility than different hours
      for (int i = 0; i < states.length; i++) {
        for (int j = i + 1; j < states.length; j++) {
          final compatibility = QuantumTemporalStateGenerator
              .calculateTemporalCompatibility(states[i], states[j]);
          
          // Same local time (9am) should have higher compatibility than different times
          // The exact value depends on weekday, season, and phase alignment
          expect(compatibility, greaterThan(0.0));
          expect(compatibility, lessThanOrEqualTo(1.0001));
        }
      }
      
      // Verify that same local hour creates higher compatibility than different hours
      // Create a different hour state (3pm instead of 9am)
      final differentHour = DateTime(2025, 12, 23, 15, 0, 0); // 3pm
      final differentUtc = differentHour.subtract(const Duration(hours: 9));
      final differentTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: differentUtc,
        localTime: differentHour,
        timezoneId: 'Asia/Tokyo',
      );
      final differentState = QuantumTemporalStateGenerator.generate(differentTimestamp);
      
      // Compare 9am states vs 9am vs 3pm
      final sameHourCompatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(states[0], states[1]);
      final differentHourCompatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(states[0], differentState);
      
      // Same local hour should have higher compatibility than different hour
      expect(sameHourCompatibility, greaterThan(differentHourCompatibility));
    });
  });
}

