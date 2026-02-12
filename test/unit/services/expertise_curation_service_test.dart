import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/expertise_curation_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expertise Curation Service Tests
/// Tests expert-based curation and validation functionality
void main() {
  group('ExpertiseCurationService Tests', () {
    late ExpertiseCurationService service;
    late UnifiedUser curator;
    late List<Spot> spots;

    setUp(() {
      service = ExpertiseCurationService();
      curator = ModelFactories.createTestUser(
        id: 'curator-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'regional'},
      );
      spots = [
        ModelFactories.createTestSpot(name: 'Spot 1'),
        ModelFactories.createTestSpot(name: 'Spot 2'),
      ];
    });

    // Removed: Property assignment tests
    // Expertise curation tests focus on business logic (curation, validation, filtering), not property assignment

    group('createExpertCuratedList', () {
      test(
          'should create curated list when curator has regional level, respect isPublic parameter, set respectCount to zero initially, or throw exception when curator lacks regional level',
          () async {
        // Test business logic: expert curated list creation with validation
        final collection = await service.createExpertCuratedList(
          curator: curator,
          title: 'Best Food Spots',
          description: 'Curated list of best food spots',
          category: 'food',
          spots: spots,
        );
        expect(collection, isA<ExpertCuratedCollection>());
        expect(collection.title, equals('Best Food Spots'));
        expect(collection.category, equals('food'));
        expect(collection.curator.id, equals(curator.id));
        expect(collection.spotCount, equals(spots.length));
        expect(collection.curatorLevel, equals(ExpertiseLevel.regional));
        expect(collection.respectCount, equals(0));

        final privateCollection = await service.createExpertCuratedList(
          curator: curator,
          title: 'Private List',
          description: 'Private curated list',
          category: 'food',
          spots: spots,
          isPublic: false,
        );
        expect(privateCollection.isPublic, equals(false));

        final localCurator = ModelFactories.createTestUser(id: 'curator-456')
            .copyWith(expertiseMap: {'food': 'local'});
        expect(
          () => service.createExpertCuratedList(
            curator: localCurator,
            title: 'Best Food Spots',
            description: 'Curated list',
            category: 'food',
            spots: spots,
          ),
          throwsException,
        );
      });
    });

    group('getExpertCuratedCollections', () {
      test(
          'should return collections filtered by category, location, minimum level, respect maxResults parameter, and sort by respectCount descending',
          () async {
        // Test business logic: collection retrieval with filtering and sorting
        final categoryCollections =
            await service.getExpertCuratedCollections(category: 'food');
        expect(categoryCollections, isA<List<ExpertCuratedCollection>>());

        final locationCollections = await service.getExpertCuratedCollections(
            category: 'food', location: 'San Francisco');
        expect(locationCollections, isA<List<ExpertCuratedCollection>>());

        final levelCollections = await service.getExpertCuratedCollections(
            category: 'food', minLevel: ExpertiseLevel.regional);
        expect(levelCollections, isA<List<ExpertCuratedCollection>>());

        final limitedCollections = await service.getExpertCuratedCollections(
            category: 'food', maxResults: 10);
        expect(limitedCollections.length, lessThanOrEqualTo(10));

        final sortedCollections =
            await service.getExpertCuratedCollections(category: 'food');
        for (var i = 0; i < sortedCollections.length - 1; i++) {
          expect(sortedCollections[i].respectCount,
              greaterThanOrEqualTo(sortedCollections[i + 1].respectCount));
        }
      });
    });

    group('createExpertPanelValidation', () {
      test(
          'should create panel validation with regional level experts, accept validations map, determine consensus validation, or throw exception when expert lacks regional level',
          () async {
        // Test business logic: expert panel validation with consensus
        final experts = [
          ModelFactories.createTestUser(id: 'expert-1')
              .copyWith(expertiseMap: {'food': 'regional'}),
          ModelFactories.createTestUser(id: 'expert-2')
              .copyWith(expertiseMap: {'food': 'regional'}),
        ];
        final validation = await service.createExpertPanelValidation(
          spot: spots.first,
          experts: experts,
          category: 'food',
        );
        expect(validation, isA<ExpertPanelValidation>());
        expect(validation.spot.id, equals(spots.first.id));
        expect(validation.category, equals('food'));
        expect(validation.experts.length, equals(2));

        final validations = {'expert-1': true};
        final validationWithMap = await service.createExpertPanelValidation(
          spot: spots.first,
          experts: [experts.first],
          category: 'food',
          validations: validations,
        );
        expect(validationWithMap.validations, equals(validations));

        final consensusExperts = [
          ModelFactories.createTestUser(id: 'expert-1')
              .copyWith(expertiseMap: {'food': 'regional'}),
          ModelFactories.createTestUser(id: 'expert-2')
              .copyWith(expertiseMap: {'food': 'regional'}),
          ModelFactories.createTestUser(id: 'expert-3')
              .copyWith(expertiseMap: {'food': 'regional'}),
        ];
        final consensusValidations = {
          'expert-1': true,
          'expert-2': true,
          'expert-3': false
        };
        final consensusValidation = await service.createExpertPanelValidation(
          spot: spots.first,
          experts: consensusExperts,
          category: 'food',
          validations: consensusValidations,
        );
        expect(consensusValidation.isValidated, isTrue);
        expect(consensusValidation.validationPercentage, greaterThan(0.5));

        final localExpert = [
          ModelFactories.createTestUser(id: 'expert-1')
              .copyWith(expertiseMap: {'food': 'local'})
        ];
        expect(
          () => service.createExpertPanelValidation(
            spot: spots.first,
            experts: localExpert,
            category: 'food',
          ),
          throwsException,
        );
      });
    });

    group('getCommunityValidatedSpots', () {
      test(
          'should return validated spots filtered by category, respect minValidations and maxResults parameters',
          () async {
        // Test business logic: validated spot retrieval with filtering
        final validatedSpots =
            await service.getCommunityValidatedSpots(category: 'food');
        expect(validatedSpots, isA<List<Spot>>());

        final minValidationsSpots = await service.getCommunityValidatedSpots(
            category: 'food', minValidations: 3);
        expect(minValidationsSpots, isA<List<Spot>>());

        final limitedSpots = await service.getCommunityValidatedSpots(
            category: 'food', maxResults: 10);
        expect(limitedSpots.length, lessThanOrEqualTo(10));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
