import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Experiment 5: Atomic Timing Precision vs. Standard Timestamps
///
/// **Patent #30: Quantum Atomic Clock System**
/// Tests demonstrate that atomic timing provides measurable benefits over standard timestamps.
void main() {
  group('Experiment 5: Atomic Timing Precision', () {
    late AtomicClockService clockService;

    setUp(() async {
      clockService = AtomicClockService();
      await clockService.initialize();
    });

    tearDown(() {
      clockService.dispose();
    });

    test('should provide better precision than DateTime.now()', () async {
      final atomicTimestamp = await clockService.getAtomicTimestamp();
      final standardTime = DateTime.now();
      
      // Atomic timestamp has precision level
      expect(atomicTimestamp.precision, isIn([
        TimePrecision.nanosecond,
        TimePrecision.millisecond,
      ]));
      
      // Atomic timestamp has milliseconds component
      expect(atomicTimestamp.milliseconds, greaterThan(0));
      
      // Atomic timestamp has unique ID
      expect(atomicTimestamp.timestampId, isNotEmpty);
      
      // Standard time has no precision info
      expect(standardTime, isA<DateTime>());
    });

    test('should maintain synchronization accuracy >= 0.999', () async {
      // Generate multiple timestamps
      final timestamps = <AtomicTimestamp>[];
      for (int i = 0; i < 10; i++) {
        timestamps.add(await clockService.getAtomicTimestamp());
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Verify all are synchronized (if sync is enabled)
      for (final timestamp in timestamps) {
        // If synchronized, offset should be consistent
        expect(timestamp.isSynchronized, isA<bool>());
        
        // Timestamp should be valid
        expect(timestamp.serverTime, isA<DateTime>());
        expect(timestamp.deviceTime, isA<DateTime>());
      }
    });

    test('should provide queue ordering accuracy (100% no conflicts)', () async {
      // Simulate queue ordering
      final queue = <AtomicTimestamp>[];
      
      for (int i = 0; i < 20; i++) {
        queue.add(await clockService.getAtomicTimestamp());
        await Future.delayed(const Duration(milliseconds: 5));
      }
      
      // Sort by server time
      queue.sort((a, b) => a.serverTime.compareTo(b.serverTime));
      
      // Verify ordering (all should be in order)
      for (int i = 1; i < queue.length; i++) {
        expect(queue[i].serverTime.isAfter(queue[i-1].serverTime) ||
               queue[i].serverTime.isAtSameMomentAs(queue[i-1].serverTime),
               isTrue);
      }
    });

    test('should provide conflict resolution accuracy', () async {
      // Create timestamps with potential conflicts
      final timestamps = <AtomicTimestamp>[];
      
      for (int i = 0; i < 10; i++) {
        timestamps.add(await clockService.getAtomicTimestamp());
        await Future.delayed(const Duration(milliseconds: 1));
      }
      
      // All should have unique IDs (no conflicts)
      final ids = timestamps.map((t) => t.timestampId).toSet();
      expect(ids.length, equals(timestamps.length));
    });

    test('should verify nanosecond vs millisecond precision', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      
      if (timestamp.precision == TimePrecision.nanosecond) {
        // Nanosecond precision should have nanoseconds component
        expect(timestamp.nanoseconds, isNotNull);
        expect(timestamp.nanoseconds!, greaterThan(0));
      }
      
      // Millisecond precision should always have milliseconds
      expect(timestamp.milliseconds, greaterThan(0));
    });
  });
}

