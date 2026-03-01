import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/business/brand_discovery.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BrandDiscovery model
void main() {
  group('BrandDiscovery Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor property test
    // This only verified Dart constructor behavior, not business logic

    test(
        'should filter viable matches above 70% threshold and serialize correctly',
        () {
      // Test business logic: match filtering and JSON serialization
      const match1 = BrandMatch(
        brandId: 'brand-1',
        brandName: 'Brand 1',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85.0,
          valueAlignment: 90.0,
          styleCompatibility: 80.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
      );

      const match2 = BrandMatch(
        brandId: 'brand-2',
        brandName: 'Brand 2',
        compatibilityScore: 65.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 65.0,
          valueAlignment: 70.0,
          styleCompatibility: 60.0,
          qualityFocus: 65.0,
          audienceAlignment: 65.0,
        ),
      );

      final discovery = BrandDiscovery(
        id: 'discovery-123',
        eventId: 'event-456',
        searchCriteria: const {'category': 'Food & Beverage'},
        matchingResults: const [match1, match2],
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Test match filtering logic
      expect(discovery.matchCount, equals(2));
      expect(discovery.highCompatibilityMatches, equals(1));
      expect(discovery.hasViableMatches, isTrue);
      expect(discovery.viableMatches.length, equals(1));
      expect(discovery.viableMatches.first.brandId, equals('brand-1'));

      // Test JSON serialization
      final json = discovery.toJson();
      final restored = BrandDiscovery.fromJson(json);
      expect(restored.matchCount, equals(discovery.matchCount));
      expect(restored.hasViableMatches, equals(discovery.hasViableMatches));
      expect(restored.matchingResults.first.compatibilityScore,
          equals(discovery.matchingResults.first.compatibilityScore));
    });
  });
}
