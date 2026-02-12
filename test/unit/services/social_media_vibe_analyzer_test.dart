/// SPOTS SocialMediaVibeAnalyzer Tests
/// Date: December 15, 2025
/// Purpose: Test SocialMediaVibeAnalyzer service functionality
/// 
/// Test Coverage:
/// - Google Profile Analysis: Saved places, reviews, photos analysis
/// - Generic Social Profile Analysis: Instagram, Facebook, Twitter
/// - Dimension Extraction: Personality insights from social data
/// - Value Normalization: Ensuring values are in 0.0-1.0 range
/// - Edge Cases: Empty data, missing fields, invalid platforms
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/social_media/social_media_vibe_analyzer.dart';

void main() {
  group('SocialMediaVibeAnalyzer Tests', () {
    late SocialMediaVibeAnalyzer analyzer;

    setUp(() {
      analyzer = SocialMediaVibeAnalyzer();
    });

    group('Google Profile Analysis', () {
      test('should extract location adventurousness from saved parks', () async {
        // Arrange
        final savedPlaces = [
          {'name': 'Golden Gate Park', 'type': 'park'},
          {'name': 'Dolores Park', 'type': 'park'},
        ];
        final profileData = {
          'savedPlaces': savedPlaces,
          'reviews': [],
          'photos': [],
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: savedPlaces,
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights['location_adventurousness'], greaterThan(0.0));
        expect(insights['exploration_eagerness'], greaterThan(0.0));
        expect(insights['location_adventurousness'], lessThanOrEqualTo(1.0));
        expect(insights['exploration_eagerness'], lessThanOrEqualTo(1.0));
      });

      test('should extract curation tendency from saved cafes and restaurants', () async {
        // Arrange
        final savedPlaces = [
          {'name': 'Blue Bottle Coffee', 'type': 'cafe'},
          {'name': 'The French Laundry', 'type': 'restaurant'},
        ];
        final profileData = {
          'savedPlaces': savedPlaces,
          'reviews': [],
          'photos': [],
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: savedPlaces,
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights['curation_tendency'], greaterThan(0.0));
        expect(insights['authenticity_preference'], greaterThan(0.0));
        expect(insights['curation_tendency'], lessThanOrEqualTo(1.0));
      });

      test('should extract authenticity preference from reviews mentioning authentic', () async {
        // Arrange
        final reviews = [
          {'rating': 5, 'text': 'Amazing authentic experience'},
          {'rating': 4, 'text': 'Great local spot with genuine atmosphere'},
        ];
        final profileData = {
          'savedPlaces': [],
          'reviews': reviews,
          'photos': [],
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: [],
          reviews: reviews,
          photos: [],
        );

        // Assert
        expect(insights['authenticity_preference'], greaterThan(0.0));
        expect(insights['authenticity_preference'], lessThanOrEqualTo(1.0));
      });

      test('should extract curation tendency from high-rated reviews', () async {
        // Arrange
        final reviews = [
          {'rating': 5, 'text': 'Excellent'},
          {'rating': 5, 'text': 'Perfect'},
          {'rating': 5, 'text': 'Amazing'},
        ];
        final profileData = {
          'savedPlaces': [],
          'reviews': reviews,
          'photos': [],
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: [],
          reviews: reviews,
          photos: [],
        );

        // Assert
        expect(insights['curation_tendency'], greaterThan(0.0));
      });

      test('should extract exploration eagerness from photos with nature tags', () async {
        // Arrange
        final photos = [
          {'location': 'Yosemite', 'tags': ['nature', 'hiking']},
          {'location': 'Grand Canyon', 'tags': ['nature', 'adventure']},
        ];
        final profileData = {
          'savedPlaces': [],
          'reviews': [],
          'photos': photos,
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: [],
          reviews: [],
          photos: photos,
        );

        // Assert
        expect(insights['exploration_eagerness'], greaterThan(0.0));
        expect(insights['location_adventurousness'], greaterThan(0.0));
      });

      test('should extract temporal flexibility from travel photos', () async {
        // Arrange
        final photos = [
          {'location': 'Paris', 'tags': ['travel', 'adventure']},
          {'location': 'Tokyo', 'tags': ['travel']},
        ];
        final profileData = {
          'savedPlaces': [],
          'reviews': [],
          'photos': photos,
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: [],
          reviews: [],
          photos: photos,
        );

        // Assert
        expect(insights['exploration_eagerness'], greaterThan(0.0));
        expect(insights['temporal_flexibility'], greaterThan(0.0));
      });

      test('should increase exploration eagerness with multiple saved places', () async {
        // Arrange
        final savedPlaces = List.generate(10, (i) => <String, dynamic>{
          'name': 'Place $i',
          'type': 'point_of_interest',
        });
        final profileData = {
          'savedPlaces': savedPlaces,
          'reviews': [],
          'photos': [],
        };

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: profileData,
          savedPlaces: savedPlaces,
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights['exploration_eagerness'], greaterThan(0.0));
        expect(insights['location_adventurousness'], greaterThan(0.0));
      });

      test('should normalize all dimension values to 0.0-1.0 range', () async {
        // Arrange
        final savedPlaces = List.generate(20, (i) => <String, dynamic>{
          'name': 'Place $i',
          'type': 'park',
        });
        final reviews = List.generate(10, (i) => <String, dynamic>{
          'rating': 5,
          'text': 'Amazing authentic experience $i',
        });
        final photos = List.generate(15, (i) => <String, dynamic>{
          'location': 'Location $i',
          'tags': ['nature', 'hiking', 'travel'],
        });

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {
            'savedPlaces': savedPlaces,
            'reviews': reviews,
            'photos': photos,
          },
          savedPlaces: savedPlaces,
          reviews: reviews,
          photos: photos,
        );

        // Assert
        for (final value in insights.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Generic Social Profile Analysis', () {
      test('should extract social discovery style from high follow count', () async {
        // Arrange
        final follows = List.generate(600, (i) => <String, dynamic>{'id': 'user_$i'});
        final profileData = {'bio': ''};
        final connections = <Map<String, dynamic>>[];

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: profileData,
          follows: follows,
          connections: connections,
          platform: 'instagram',
        );

        // Assert
        expect(insights['social_discovery_style'], greaterThan(0.0));
        expect(insights['social_discovery_style'], lessThanOrEqualTo(1.0));
      });

      test('should extract community orientation from high connection count', () async {
        // Arrange
        final connections = List.generate(400, (i) => <String, dynamic>{'id': 'user_$i'});
        final profileData = {'bio': ''};
        final follows = <Map<String, dynamic>>[];

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: profileData,
          follows: follows,
          connections: connections,
          platform: 'facebook',
        );

        // Assert
        expect(insights['community_orientation'], greaterThan(0.0));
        expect(insights['trust_network_reliance'], greaterThan(0.0));
      });

      test('should extract exploration eagerness from bio with adventure keywords', () async {
        // Arrange
        final profileData = {
          'bio': 'Explorer and adventure seeker. Always on the move!',
        };
        final follows = <Map<String, dynamic>>[];
        final connections = <Map<String, dynamic>>[];

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: profileData,
          follows: follows,
          connections: connections,
          platform: 'twitter',
        );

        // Assert
        expect(insights['exploration_eagerness'], greaterThan(0.0));
      });

      test('should extract curation tendency from bio with food keywords', () async {
        // Arrange
        final profileData = {
          'bio': 'Foodie and coffee enthusiast. Love discovering new spots!',
        };
        final follows = <Map<String, dynamic>>[];
        final connections = <Map<String, dynamic>>[];

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: profileData,
          follows: follows,
          connections: connections,
          platform: 'instagram',
        );

        // Assert
        expect(insights['curation_tendency'], greaterThan(0.0));
      });

      test('should handle unknown platform with generic analysis', () async {
        // Arrange
        final profileData = {'bio': 'Test bio'};
        final follows = <Map<String, dynamic>>[];
        final connections = <Map<String, dynamic>>[];

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: profileData,
          follows: follows,
          connections: connections,
          platform: 'unknown_platform',
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        // Should not throw and return empty or minimal insights
      });
    });

    group('Edge Cases', () {
      test('should handle empty saved places list', () async {
        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'savedPlaces': []},
          savedPlaces: [],
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        expect(insights.isEmpty, isTrue);
      });

      test('should handle empty reviews list', () async {
        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'reviews': []},
          savedPlaces: [],
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
      });

      test('should handle empty photos list', () async {
        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'photos': []},
          savedPlaces: [],
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
      });

      test('should handle missing fields in saved places', () async {
        // Arrange
        final savedPlaces = [
          {'name': 'Place 1'}, // Missing 'type'
          {'type': 'park'}, // Missing 'name'
        ];

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'savedPlaces': savedPlaces},
          savedPlaces: savedPlaces,
          reviews: [],
          photos: [],
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        // Should not throw
      });

      test('should handle missing fields in reviews', () async {
        // Arrange
        final reviews = [
          {'rating': 5}, // Missing 'text'
          {'text': 'Great'}, // Missing 'rating'
        ];

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'reviews': reviews},
          savedPlaces: [],
          reviews: reviews,
          photos: [],
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        // Should not throw
      });

      test('should handle missing fields in photos', () async {
        // Arrange
        final photos = [
          {'location': 'Yosemite'}, // Missing 'tags'
          {'tags': ['nature']}, // Missing 'location'
        ];

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {'photos': photos},
          savedPlaces: [],
          reviews: [],
          photos: photos,
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        // Should not throw
      });

      test('should handle errors gracefully and return empty map', () async {
        // Arrange
        // Pass empty data that should be handled gracefully

        // Act
        final insights = await analyzer.analyzeProfileForVibe(
          profileData: {},
          follows: [],
          connections: [],
          platform: 'test',
        );

        // Assert
        expect(insights, isA<Map<String, double>>());
        // Should return empty or minimal insights for empty data
      });
    });

    group('Value Normalization', () {
      test('should ensure all dimension values are between 0.0 and 1.0', () async {
        // Arrange
        final savedPlaces = List.generate(100, (i) => {
          'name': 'Place $i',
          'type': 'park',
        });
        final reviews = List.generate(50, (i) => {
          'rating': 5,
          'text': 'Amazing authentic experience $i',
        });
        final photos = List.generate(75, (i) => {
          'location': 'Location $i',
          'tags': ['nature', 'hiking', 'travel', 'adventure'],
        });

        // Act
        final insights = await analyzer.analyzeGoogleProfileForVibe(
          profileData: {
            'savedPlaces': savedPlaces,
            'reviews': reviews,
            'photos': photos,
          },
          savedPlaces: savedPlaces,
          reviews: reviews,
          photos: photos,
        );

        // Assert
        for (final entry in insights.entries) {
          expect(
            entry.value,
            greaterThanOrEqualTo(0.0),
            reason: '${entry.key} should be >= 0.0',
          );
          expect(
            entry.value,
            lessThanOrEqualTo(1.0),
            reason: '${entry.key} should be <= 1.0',
          );
        }
      });
    });
  });
}

