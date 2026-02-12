import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/multi_path_expertise_service.dart';
import 'package:avrai/core/models/expertise/multi_path_expertise.dart';
import 'package:avrai/core/models/spots/visit.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Comprehensive tests for MultiPathExpertiseService
void main() {
  group('MultiPathExpertiseService Tests', () {
    late MultiPathExpertiseService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = MultiPathExpertiseService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Multi-path expertise tests focus on business logic (expertise calculation across different paths), not property assignment

    group('calculateExplorationExpertise', () {
      test(
          'should calculate exploration expertise from visits or calculate high exploration score for many visits',
          () async {
        // Test business logic: exploration expertise calculation
        final visits1 = [
          Visit(
            id: 'visit-1',
            userId: 'user-1',
            locationId: 'location-1',
            checkInTime: testDate.subtract(const Duration(days: 30)),
            checkOutTime: testDate.subtract(const Duration(days: 30)),
            dwellTime: const Duration(minutes: 30),
            qualityScore: 1.0,
            rating: 4.5,
            reviewId: 'review-1',
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Visit(
            id: 'visit-2',
            userId: 'user-1',
            locationId: 'location-2',
            checkInTime: testDate.subtract(const Duration(days: 20)),
            checkOutTime: testDate.subtract(const Duration(days: 20)),
            dwellTime: const Duration(minutes: 45),
            qualityScore: 1.2,
            rating: 4.8,
            reviewId: 'review-2',
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];
        final expertise1 = await service.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: visits1,
        );
        expect(expertise1.userId, equals('user-1'));
        expect(expertise1.category, equals('Coffee'));
        expect(expertise1.totalVisits, equals(2));
        expect(expertise1.uniqueLocations, equals(2));
        expect(expertise1.reviewsGiven, equals(2));
        expect(expertise1.averageRating, greaterThan(0.0));
        expect(expertise1.score, greaterThan(0.0));
        expect(expertise1.score, lessThanOrEqualTo(1.0));

        final visits2 = List.generate(50, (i) {
          return Visit(
            id: 'visit-$i',
            userId: 'user-1',
            locationId: 'location-${i % 10}',
            checkInTime: testDate.subtract(Duration(days: 50 - i)),
            checkOutTime: testDate.subtract(Duration(days: 50 - i)),
            dwellTime: const Duration(minutes: 30),
            qualityScore: 1.0,
            rating: 4.5,
            isRepeatVisit: i > 10,
            visitNumber: i > 10 ? 2 : 1,
            createdAt: testDate,
            updatedAt: testDate,
          );
        });
        final expertise2 = await service.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: visits2,
        );
        expect(expertise2.totalVisits, equals(50));
        expect(expertise2.repeatVisits, greaterThan(0));
        expect(expertise2.score, greaterThan(0.6));
      });
    });

    group('calculateCredentialExpertise', () {
      test(
          'should calculate credential expertise from degrees or from certifications',
          () async {
        // Test business logic: credential expertise calculation
        final expertise1 = await service.calculateCredentialExpertise(
          userId: 'user-1',
          category: 'Coffee',
          degrees: [
            const EducationCredential(
              degree: 'MS',
              field: 'Food Science',
              institution: 'University',
              year: 2020,
              isVerified: true,
            ),
          ],
          certifications: [],
        );
        expect(expertise1.userId, equals('user-1'));
        expect(expertise1.category, equals('Coffee'));
        expect(expertise1.degrees.length, equals(1));
        expect(expertise1.score, greaterThan(0.0));

        final expertise2 = await service.calculateCredentialExpertise(
          userId: 'user-1',
          category: 'Coffee',
          degrees: [],
          certifications: [
            CertificationCredential(
              name: 'Q Grader',
              issuer: 'Coffee Quality Institute',
              issuedDate: testDate.subtract(const Duration(days: 365)),
              isVerified: true,
            ),
          ],
        );
        expect(expertise2.certifications.length, equals(1));
        expect(expertise2.score, greaterThan(0.0));
      });
    });

    group('calculateInfluenceExpertise', () {
      test(
          'should calculate influence expertise from followers or calculate high influence score for many followers',
          () async {
        // Test business logic: influence expertise calculation
        final expertise1 = await service.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 1000,
          listSaves: 500,
          listShares: 200,
          curatedLists: 10,
        );
        expect(expertise1.userId, equals('user-1'));
        expect(expertise1.category, equals('Coffee'));
        expect(expertise1.spotsFollowers, equals(1000));
        expect(expertise1.listSaves, equals(500));
        expect(expertise1.score, greaterThan(0.0));

        final expertise2 = await service.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 5000,
          listSaves: 2000,
          listShares: 1000,
          curatedLists: 20,
        );
        expect(expertise2.score, greaterThan(0.7));
      });
    });

    group('calculateProfessionalExpertise', () {
      test('should calculate professional expertise from roles', () async {
        final expertise = await service.calculateProfessionalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          roles: [
            ProfessionalRole(
              role: 'Chef',
              title: 'Head Chef',
              employer: 'Restaurant',
              startDate: testDate.subtract(const Duration(days: 1095)),
              isCurrent: true,
              isVerified: true,
            ),
          ],
          proofOfWork: [],
          peerEndorsements: [],
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.roles.length, equals(1));
        expect(expertise.score, greaterThan(0.0));
      });
    });

    group('calculateCommunityExpertise', () {
      test('should calculate community expertise from contributions', () async {
        final expertise = await service.calculateCommunityExpertise(
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 50,
          curatedLists: 20,
          eventsHosted: 15,
          averageEventRating: 4.7,
          peerEndorsements: 25,
          communityContributions: 100,
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.questionsAnswered, equals(50));
        expect(expertise.eventsHosted, equals(15));
        expect(expertise.score, greaterThan(0.0));
      });
    });

    group('calculateLocalExpertise', () {
      test(
          'should calculate local expertise from local visits or identify Golden Local Expert',
          () async {
        // Test business logic: local expertise calculation
        final firstVisitDate1 = testDate.subtract(const Duration(days: 365));
        final localVisits1 = List.generate(
            50,
            (i) => Visit(
                  id: 'visit-$i',
                  userId: 'user-1',
                  locationId: 'location-${i % 30}',
                  checkInTime: firstVisitDate1.add(Duration(days: i)),
                  qualityScore: 1.0,
                  rating: 4.5,
                  createdAt: testDate,
                  updatedAt: testDate,
                ));
        final expertise1 = await service.calculateLocalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          locality: 'NYC',
          localVisits: localVisits1,
          firstLocalVisit: firstVisitDate1,
        );
        expect(expertise1.userId, equals('user-1'));
        expect(expertise1.category, equals('Coffee'));
        expect(expertise1.locality, equals('NYC'));
        expect(expertise1.localVisits, equals(50));
        expect(expertise1.score, greaterThan(0.0));

        final firstVisitDate2 = testDate.subtract(const Duration(days: 9125));
        final localVisits2 = List.generate(
            200,
            (i) => Visit(
                  id: 'visit-$i',
                  userId: 'user-1',
                  locationId: 'location-${i % 50}',
                  checkInTime: firstVisitDate2.add(Duration(days: i * 45)),
                  qualityScore: 1.2,
                  rating: 4.8,
                  createdAt: testDate,
                  updatedAt: testDate,
                ));
        final expertise2 = await service.calculateLocalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          locality: 'NYC',
          localVisits: localVisits2,
          firstLocalVisit: firstVisitDate2,
          continuousResidency: const Duration(days: 9125),
        );
        expect(expertise2.isGoldenLocalExpert, isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
