import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';

/// Comprehensive tests for ExpertiseLevel enum
/// Tests enum values, display names, descriptions, emojis, parsing, and level comparisons
void main() {
  group('ExpertiseLevel Enum Tests', () {
    // Removed: Enum Values group
    // These tests only verified enum definition, not business logic

    // Removed: Display Names group
    // These tests only verified property values, not business logic

    // Removed: Descriptions group
    // These tests only verified property values, not business logic

    // Removed: Emojis group
    // These tests only verified property values, not business logic

    group('Parsing from String', () {
      test('should correctly parse valid strings and handle invalid input', () {
        // Test business logic: string parsing with case handling and error cases
        expect(
            ExpertiseLevel.fromString('local'), equals(ExpertiseLevel.local));
        expect(ExpertiseLevel.fromString('city'), equals(ExpertiseLevel.city));
        expect(ExpertiseLevel.fromString('LOCAL'),
            equals(ExpertiseLevel.local)); // Case insensitive
        expect(ExpertiseLevel.fromString('City'), equals(ExpertiseLevel.city));
        expect(ExpertiseLevel.fromString('invalid'), isNull); // Invalid
        expect(ExpertiseLevel.fromString(''), isNull); // Empty
        expect(ExpertiseLevel.fromString(null), isNull); // Null
      });
    });

    group('Next Level', () {
      test(
          'should return correct progression chain ending with null for highest level',
          () {
        // Test business logic: level progression
        expect(ExpertiseLevel.local.nextLevel, equals(ExpertiseLevel.city));
        expect(ExpertiseLevel.city.nextLevel, equals(ExpertiseLevel.regional));
        expect(
            ExpertiseLevel.regional.nextLevel, equals(ExpertiseLevel.national));
        expect(
            ExpertiseLevel.national.nextLevel, equals(ExpertiseLevel.global));
        expect(
            ExpertiseLevel.global.nextLevel, equals(ExpertiseLevel.universal));
        expect(ExpertiseLevel.universal.nextLevel, isNull); // Highest level
      });
    });

    group('Level Comparisons', () {
      test('should correctly compare levels using isHigherThan and isLowerThan',
          () {
        // Test business logic: level comparison
        expect(ExpertiseLevel.city.isHigherThan(ExpertiseLevel.local), isTrue);
        expect(ExpertiseLevel.local.isHigherThan(ExpertiseLevel.local),
            isFalse); // Same
        expect(ExpertiseLevel.local.isHigherThan(ExpertiseLevel.city),
            isFalse); // Lower

        expect(ExpertiseLevel.local.isLowerThan(ExpertiseLevel.city), isTrue);
        expect(ExpertiseLevel.local.isLowerThan(ExpertiseLevel.local),
            isFalse); // Same
        expect(ExpertiseLevel.city.isLowerThan(ExpertiseLevel.local),
            isFalse); // Higher
      });
    });

    group('Level Progression', () {
      test('should progress correctly through all levels with matching indices',
          () {
        // Test business logic: complete progression chain
        var current = ExpertiseLevel.local;
        final progression = <ExpertiseLevel>[current];
        var expectedIndex = 0;

        while (current.nextLevel != null) {
          expect(current.index, equals(expectedIndex));
          current = current.nextLevel!;
          progression.add(current);
          expectedIndex++;
        }

        expect(progression, hasLength(6));
        expect(progression[0], equals(ExpertiseLevel.local));
        expect(progression[5], equals(ExpertiseLevel.universal));
        expect(current.index, equals(5)); // universal
      });
    });
  });
}
