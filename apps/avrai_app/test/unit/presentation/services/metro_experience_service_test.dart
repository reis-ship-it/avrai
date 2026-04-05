import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/services/metro_experience_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';

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

    test('profileForMetroKey merges governed downstream consumer priors', () {
      final occurredAt = DateTime.utc(2026, 4, 1, 9);
      final capturedAt = DateTime.utc(2026, 4, 1, 10);
      final integratedAt = DateTime.utc(2026, 4, 1, 11);
      final syncedAt = DateTime.utc(2026, 4, 1, 12);
      final profile = MetroExperienceService.profileForMetroKey(
        metroKey: 'denver',
        cityCode: 'us-denver',
        governedConsumerStates: <GovernedDomainConsumerState>[
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_den',
            domainId: 'locality',
            consumerId: 'locality_intelligence_lane',
            environmentId: 'denver-replay-world-2024',
            cityCode: 'us-denver',
            generatedAt: DateTime.utc(2026, 4, 1, 12),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Locality priors are ready.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['locality_priors'],
            originOccurredAt: occurredAt,
            localStateCapturedAt: capturedAt,
            learningIntegratedAt: integratedAt,
            sourceLastSyncedAt: syncedAt,
            kernelExchangePhase: 'locality_personal_visit_captured',
          ),
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_den',
            domainId: 'mobility',
            consumerId: 'mobility_guidance_lane',
            environmentId: 'denver-replay-world-2024',
            cityCode: 'us-denver',
            generatedAt: DateTime.utc(2026, 4, 1, 12),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Mobility guidance is ready.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['mobility_route_priors'],
          ),
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_den',
            domainId: 'community',
            consumerId: 'community_coordination_lane',
            environmentId: 'denver-replay-world-2024',
            cityCode: 'us-denver',
            generatedAt: DateTime.utc(2026, 4, 1, 12),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Community coordination is ready.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['community_coordination_priors'],
          ),
        ],
      );

      expect(
          profile.spotPriors, contains('Governed locality priors for Denver'));
      expect(
        profile.eventPriors,
        contains('Governed mobility guidance for Denver'),
      );
      expect(
        profile.communityPriors,
        contains('Governed community coordination for Denver'),
      );
      expect(
        profile.promptSuggestions.join(' '),
        contains('governed locality learning update'),
      );
      expect(profile.categoryKeywords, contains('mobility'));
      expect(profile.governedKnowledgeOccurredAtUtc, equals(occurredAt));
      expect(profile.governedKnowledgeCapturedAtUtc, equals(capturedAt));
      expect(profile.governedKnowledgeIntegratedAtUtc, equals(integratedAt));
      expect(profile.governedKnowledgeSyncedAtUtc, equals(syncedAt));
      expect(
        profile.governedKnowledgePhase,
        equals('locality_personal_visit_captured'),
      );
      expect(
        profile.governedKnowledgeTimingSummary,
        contains('effective knowledge'),
      );
    });
  });
}
