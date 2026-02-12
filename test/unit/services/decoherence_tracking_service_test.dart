import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/models/quantum/decoherence_pattern.dart';
import 'package:avrai/core/services/quantum/decoherence_tracking_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/domain/repositories/decoherence_pattern_repository.dart';

void main() {
  group('DecoherenceTrackingService', () {
    late MockDecoherencePatternRepository mockRepository;
    late AtomicClockService atomicClock;
    late DecoherenceTrackingService service;

    setUp(() {
      mockRepository = MockDecoherencePatternRepository();
      atomicClock = AtomicClockService();
      service = DecoherenceTrackingService(
        repository: mockRepository,
        atomicClock: atomicClock,
      );
    });

    test('should record decoherence measurement for new user', () async {
      // Arrange
      const userId = 'test_user_1';
      const decoherenceFactor = 0.15;
      mockRepository.patterns[userId] = null; // No existing pattern

      // Act
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: decoherenceFactor,
      );

      // Assert
      expect(mockRepository.saveCalled, isTrue);
      final savedPattern = mockRepository.savedPattern;
      expect(savedPattern, isNotNull);
      expect(savedPattern!.userId, equals(userId));
      expect(savedPattern.timeline.length, equals(1));
      expect(savedPattern.timeline.first.decoherenceFactor,
          closeTo(decoherenceFactor, 0.001));
      expect(savedPattern.behaviorPhase, equals(BehaviorPhase.exploration));
    });

    test('should update existing pattern with new measurement', () async {
      // Arrange
      const userId = 'test_user_2';
      final existingPattern = DecoherencePattern.initial(
        userId: userId,
        timestamp: AtomicTimestamp.now(precision: TimePrecision.millisecond),
      );
      mockRepository.patterns[userId] = existingPattern;
      const decoherenceFactor = 0.2;

      // Act
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: decoherenceFactor,
      );

      // Assert
      expect(mockRepository.saveCalled, isTrue);
      final savedPattern = mockRepository.savedPattern;
      expect(savedPattern, isNotNull);
      expect(savedPattern!.timeline.length, equals(1));
    });

    test('should calculate decoherence rate from timeline', () async {
      // Arrange
      const userId = 'test_user_3';
      final timestamp1 = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
      );
      final existingPattern = DecoherencePattern(
        userId: userId,
        decoherenceRate: 0.0,
        decoherenceStability: 1.0,
        timeline: [
          DecoherenceTimeline.fromFactor(
            timestamp: AtomicTimestamp.now(
              precision: TimePrecision.millisecond,
              serverTime: timestamp1.serverTime.subtract(
                const Duration(hours: 1),
              ),
            ),
            decoherenceFactor: 0.1,
          ),
        ],
        temporalPatterns: TemporalPatterns.empty(),
        behaviorPhase: BehaviorPhase.exploration,
        lastUpdated: timestamp1,
      );
      mockRepository.patterns[userId] = existingPattern;

      // Act
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: 0.2, // Increased decoherence
      );

      // Assert
      final savedPattern = mockRepository.savedPattern;
      expect(savedPattern, isNotNull);
      expect(savedPattern!.timeline.length, equals(2));
      // Rate should be positive (increasing decoherence)
      expect(savedPattern.decoherenceRate, greaterThan(0.0));
    });

    test('should detect behavior phase correctly', () async {
      // Arrange
      const userId = 'test_user_4';
      final existingPattern = DecoherencePattern(
        userId: userId,
        decoherenceRate: 0.15, // High rate
        decoherenceStability: 0.5, // Low stability
        timeline: [
          DecoherenceTimeline.fromFactor(
            timestamp: AtomicTimestamp.now(precision: TimePrecision.millisecond),
            decoherenceFactor: 0.2,
          ),
        ],
        temporalPatterns: TemporalPatterns.empty(),
        behaviorPhase: BehaviorPhase.exploration,
        lastUpdated: AtomicTimestamp.now(precision: TimePrecision.millisecond),
      );
      mockRepository.patterns[userId] = existingPattern;

      // Act
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: 0.25,
      );

      // Assert
      final savedPattern = mockRepository.savedPattern;
      expect(savedPattern, isNotNull);
      // Should detect exploration phase (high rate, low stability)
      expect(savedPattern!.behaviorPhase, equals(BehaviorPhase.exploration));
    });

    test('should analyze temporal patterns', () async {
      // Arrange
      const userId = 'test_user_5';
      final morningDateTime = DateTime(2024, 1, 15, 8, 0); // Monday morning
      final morningTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: morningDateTime,
        localTime: morningDateTime,
      );
      final existingPattern = DecoherencePattern(
        userId: userId,
        decoherenceRate: 0.0,
        decoherenceStability: 1.0,
        timeline: [
          DecoherenceTimeline.fromFactor(
            timestamp: morningTimestamp,
            decoherenceFactor: 0.1,
          ),
        ],
        temporalPatterns: TemporalPatterns.empty(),
        behaviorPhase: BehaviorPhase.exploration,
        lastUpdated: morningTimestamp,
      );
      mockRepository.patterns[userId] = existingPattern;

      // Act
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: 0.15,
      );

      // Assert
      final savedPattern = mockRepository.savedPattern;
      expect(savedPattern, isNotNull);
      expect(savedPattern!.temporalPatterns.timeOfDayPatterns,
          contains('morning'));
      expect(savedPattern.temporalPatterns.weekdayPatterns,
          contains('monday'));
    });

    test('should get pattern for user', () async {
      // Arrange
      const userId = 'test_user_6';
      final pattern = DecoherencePattern.initial(
        userId: userId,
        timestamp: AtomicTimestamp.now(precision: TimePrecision.millisecond),
      );
      mockRepository.patterns[userId] = pattern;

      // Act
      final result = await service.getPattern(userId);

      // Assert
      expect(result, equals(pattern));
    });

    test('should get behavior phase for user', () async {
      // Arrange
      const userId = 'test_user_7';
      final pattern = DecoherencePattern(
        userId: userId,
        decoherenceRate: 0.05,
        decoherenceStability: 0.9,
        timeline: [],
        temporalPatterns: TemporalPatterns.empty(),
        behaviorPhase: BehaviorPhase.settled,
        lastUpdated: AtomicTimestamp.now(precision: TimePrecision.millisecond),
      );
      mockRepository.patterns[userId] = pattern;

      // Act
      final result = await service.getBehaviorPhase(userId);

      // Assert
      expect(result, equals(BehaviorPhase.settled));
    });

    test('should handle errors gracefully', () async {
      // Arrange
      const userId = 'test_user_error';
      mockRepository.shouldThrow = true;

      // Act & Assert - should not throw
      await service.recordDecoherenceMeasurement(
        userId: userId,
        decoherenceFactor: 0.1,
      );
    });
  });
}

/// Mock repository for testing
class MockDecoherencePatternRepository
    implements DecoherencePatternRepository {
  final Map<String, DecoherencePattern?> patterns = {};
  bool saveCalled = false;
  DecoherencePattern? savedPattern;
  bool shouldThrow = false;

  @override
  Future<DecoherencePattern?> getByUserId(String userId) async {
    if (shouldThrow) {
      throw Exception('Test error');
    }
    return patterns[userId];
  }

  @override
  Future<void> save(DecoherencePattern pattern) async {
    if (shouldThrow) {
      throw Exception('Test error');
    }
    saveCalled = true;
    savedPattern = pattern;
    patterns[pattern.userId] = pattern;
  }

  @override
  Future<List<DecoherencePattern>> getByBehaviorPhase(
    BehaviorPhase phase,
  ) async {
    return patterns.values
        .whereType<DecoherencePattern>()
        .where((p) => p.behaviorPhase == phase)
        .toList();
  }

  @override
  Future<List<DecoherencePattern>> getByTimeRange({
    required DateTime start,
    required DateTime end,
  }) async {
    return patterns.values.whereType<DecoherencePattern>().where((p) {
      final lastUpdated = p.lastUpdated.serverTime;
      return lastUpdated.isAfter(start) && lastUpdated.isBefore(end);
    }).toList();
  }

  @override
  Future<void> delete(String userId) async {
    patterns.remove(userId);
  }
}

