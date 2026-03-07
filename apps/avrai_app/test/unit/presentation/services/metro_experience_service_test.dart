import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/services/metro_experience_service.dart';

void main() {
  group('MetroExperienceService', () {
    test('resolveMetroKey maps NYC labels and city codes to nyc', () {
      expect(
        MetroExperienceService.resolveMetroKey(
          cityCode: 'us-nyc',
          displayName: 'Brooklyn',
        ),
        equals('nyc'),
      );

      expect(
        MetroExperienceService.resolveMetroKey(
          displayName: 'New York City',
        ),
        equals('nyc'),
      );
    });

    test(
        'resolveMetroKey maps Denver, Atlanta, and Birmingham labels correctly',
        () {
      expect(
        MetroExperienceService.resolveMetroKey(
          displayName: 'Denver',
        ),
        equals('denver'),
      );

      expect(
        MetroExperienceService.resolveMetroKey(
          displayName: 'Buckhead, Atlanta',
        ),
        equals('atlanta'),
      );

      expect(
        MetroExperienceService.resolveMetroKey(
          displayName: 'Homewood, Birmingham',
        ),
        equals('birmingham'),
      );
    });

    test('resolveMetroKey falls back to default for unrelated labels', () {
      expect(
        MetroExperienceService.resolveMetroKey(
          displayName: 'Seattle',
        ),
        equals('default'),
      );
    });

    test('profileForMetroKey exposes city-specific priors and prompts', () {
      final profile = MetroExperienceService.profileForMetroKey(
        metroKey: 'denver',
        cityCode: 'us-denver',
      );

      expect(profile.displayName, equals('Denver'));
      expect(profile.summary.toLowerCase(), contains('outdoors'));
      expect(profile.spotPriors, isNotEmpty);
      expect(profile.eventPriors, isNotEmpty);
      expect(profile.communityPriors, isNotEmpty);
      expect(profile.promptSuggestions.first.toLowerCase(), contains('denver'));
    });

    test('profileForMetroKey exposes Birmingham-specific priors', () {
      final profile = MetroExperienceService.profileForMetroKey(
        metroKey: 'birmingham',
        cityCode: 'us-bhm',
      );

      expect(profile.displayName, equals('Birmingham'));
      expect(profile.summary.toLowerCase(), contains('neighborhood'));
      expect(profile.spotPriors, isNotEmpty);
      expect(profile.eventPriors, isNotEmpty);
      expect(profile.communityPriors.join(' ').toLowerCase(),
          contains('volunteer'));
    });
  });
}
