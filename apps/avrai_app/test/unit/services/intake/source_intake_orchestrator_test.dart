/// Universal external intake orchestration tests.
///
/// Purpose: verify fit routing, publish-vs-review behavior, and automatic
/// surfacing through the existing event/community/spot paths.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_normalizer.dart';
import 'package:avrai_runtime_os/services/intake/entity_fit_router.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/source_intake_orchestrator.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/signatures/builders/bundle_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/community_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/event_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/spot_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/user_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/community_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/performer_venue_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_confidence_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_freshness_tracker.dart';
import 'package:avrai_runtime_os/services/signatures/signature_match_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import '../../../mocks/mock_storage_service.dart';

class _InMemorySpotsLocalDataSource implements SpotsLocalDataSource {
  final Map<String, Spot> _spots = <String, Spot>{};

  @override
  Future<String> createSpot(Spot spot) async {
    _spots[spot.id] = spot;
    return spot.id;
  }

  @override
  Future<void> deleteSpot(String id) async {
    _spots.remove(id);
  }

  @override
  Future<List<Spot>> getAllSpots() async => _spots.values.toList();

  @override
  Future<Spot?> getSpotById(String id) async => _spots[id];

  @override
  Future<List<Spot>> getSpotsByCategory(String category) async {
    return _spots.values.where((spot) => spot.category == category).toList();
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async => const [];

  @override
  Future<List<Spot>> searchSpots(String query) async {
    final normalized = query.toLowerCase();
    return _spots.values.where((spot) {
      if (normalized.isEmpty) {
        return true;
      }
      return spot.name.toLowerCase().contains(normalized) ||
          spot.description.toLowerCase().contains(normalized) ||
          spot.category.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    _spots[spot.id] = spot;
    return spot;
  }
}

void main() {
  group('SourceIntakeOrchestrator', () {
    late UniversalIntakeRepository intakeRepository;
    late ExpertiseEventService eventService;
    late CommunityService communityService;
    late _InMemorySpotsLocalDataSource spotsLocalDataSource;
    late EntitySignatureService signatureService;
    late SourceIntakeOrchestrator orchestrator;

    setUp(() async {
      intakeRepository = UniversalIntakeRepository();
      eventService = ExpertiseEventService();
      communityService = CommunityService();
      spotsLocalDataSource = _InMemorySpotsLocalDataSource();
      final freshnessTracker = const SignatureFreshnessTracker();
      final confidenceService = const SignatureConfidenceService();
      final userSignatureBuilder = UserSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      final spotSignatureBuilder = SpotSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      final communitySignatureBuilder = CommunitySignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      final eventSignatureBuilder = EventSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      final bundleSignatureBuilder = BundleSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      final defaultStorage =
          MockGetStorage.getInstance(boxName: 'spots_default');
      final userStorage = MockGetStorage.getInstance(boxName: 'spots_user');
      final aiStorage = MockGetStorage.getInstance(boxName: 'spots_ai');
      final analyticsStorage =
          MockGetStorage.getInstance(boxName: 'spots_analytics');
      await StorageService.instance.initForTesting(
        defaultStorage: defaultStorage,
        userStorage: userStorage,
        aiStorage: aiStorage,
        analyticsStorage: analyticsStorage,
      );
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: defaultStorage,
      );
      signatureService = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: const SignatureMatchService(),
        userSignatureBuilder: userSignatureBuilder,
        spotSignatureBuilder: spotSignatureBuilder,
        communitySignatureBuilder: communitySignatureBuilder,
        eventSignatureBuilder: eventSignatureBuilder,
        performerVenueEventBundleBuilder: PerformerVenueEventBundleBuilder(
          bundleSignatureBuilder: bundleSignatureBuilder,
          spotSignatureBuilder: spotSignatureBuilder,
          userSignatureBuilder: userSignatureBuilder,
        ),
        communityEventBundleBuilder: CommunityEventBundleBuilder(
          bundleSignatureBuilder: bundleSignatureBuilder,
          communitySignatureBuilder: communitySignatureBuilder,
          eventSignatureBuilder: eventSignatureBuilder,
        ),
        userVibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
        personalityLearning: PersonalityLearning(),
      );
      orchestrator = SourceIntakeOrchestrator(
        normalizer: const AirGapNormalizer(),
        fitRouter: const EntityFitRouter(),
        repository: intakeRepository,
        eventService: eventService,
        communityService: communityService,
        spotsLocalDataSource: spotsLocalDataSource,
        atomicClockService: AtomicClockService(),
        entitySignatureService: signatureService,
      );
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    test('routes structured dated source into event path automatically',
        () async {
      final source = ExternalSourceDescriptor(
        id: 'source-event',
        ownerUserId: 'owner-1',
        sourceProvider: 'calendar',
        sourceUrl: 'https://example.com/calendar.ics',
        connectionMode: ExternalConnectionMode.feed,
        entityHint: IntakeEntityType.event,
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );

      final result = await orchestrator.ingest(
        source: source,
        rawPayload: <String, dynamic>{
          'title': 'Avondale community run',
          'description': 'Weekly neighborhood run club meetup.',
          'category': 'Fitness',
          'organizerName': 'Avondale Run Club',
          'location': 'Avondale, Birmingham',
          'startTime': '2026-03-08T18:00:00.000Z',
          'endTime': '2026-03-08T19:00:00.000Z',
          'cityCode': 'us-bhm',
          'localityCode': 'us-bhm-avondale',
        },
      );

      expect(result.eventId, isNotNull);
      expect(result.reviewItem, isNull);

      final events = await eventService.searchEvents(category: 'Fitness');
      expect(events.any((event) => event.id == result.eventId), isTrue);
      expect(
        events
            .firstWhere((event) => event.id == result.eventId)
            .externalSyncMetadata,
        isNotNull,
      );
      expect(
        signatureService.getStoredSignature(
          entityKind: SignatureEntityKind.event,
          entityId: result.eventId!,
        ),
        isNotNull,
      );
      final sources = await intakeRepository.getSourcesForOwner('owner-1');
      expect(
        sources.first.metadata['signatureConfidence'],
        isA<double>(),
      );
    });

    test('routes recurring group with dated happening into linked bundle',
        () async {
      final source = ExternalSourceDescriptor(
        id: 'source-community',
        ownerUserId: 'owner-2',
        sourceProvider: 'facebook',
        sourceUrl: 'https://facebook.com/groups/bhm-volunteers',
        connectionMode: ExternalConnectionMode.oauth,
        entityHint: IntakeEntityType.community,
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );

      final result = await orchestrator.ingest(
        source: source,
        rawPayload: <String, dynamic>{
          'title': 'Birmingham Volunteers',
          'description': 'Community cleanups and monthly civic meetups.',
          'category': 'Volunteer',
          'organizerName': 'Birmingham Volunteers',
          'location': 'Birmingham, AL',
          'startTime': '2026-03-09T16:00:00.000Z',
          'endTime': '2026-03-09T18:00:00.000Z',
          'cityCode': 'us-bhm',
        },
      );

      expect(result.decision.primaryType, IntakeEntityType.linkedBundle);
      expect(result.communityId, isNotNull);

      final communities = await communityService.getAllCommunities();
      expect(
        communities.any((community) => community.id == result.communityId),
        isTrue,
      );
      expect(
        signatureService.getStoredSignature(
          entityKind: SignatureEntityKind.community,
          entityId: result.communityId!,
        ),
        isNotNull,
      );
    });

    test('sends incomplete imports to organizer review instead of publishing',
        () async {
      final source = ExternalSourceDescriptor(
        id: 'source-review',
        ownerUserId: 'owner-3',
        sourceProvider: 'newsletter',
        connectionMode: ExternalConnectionMode.emailList,
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );

      final result = await orchestrator.ingest(
        source: source,
        rawPayload: <String, dynamic>{
          'title': 'Something cool soon',
          'description': 'More details coming later.',
          'category': 'Community',
        },
      );

      expect(result.reviewItem, isNotNull);
      expect(result.eventId, isNull);
      expect(result.communityId, isNull);
      expect(result.reviewItem!.missingFields, contains('where'));
    });

    test('imported spots surface through hybrid search with external metadata',
        () async {
      final source = ExternalSourceDescriptor(
        id: 'source-spot',
        ownerUserId: 'owner-4',
        sourceProvider: 'website',
        sourceUrl: 'https://example.com/spot',
        connectionMode: ExternalConnectionMode.url,
        entityHint: IntakeEntityType.spot,
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );

      final result = await orchestrator.ingest(
        source: source,
        rawPayload: <String, dynamic>{
          'title': 'June Coffee pop-in',
          'description': 'Neighborhood coffee shop with reliable hours.',
          'category': 'Coffee',
          'organizerName': 'June Coffee',
          'location': 'Birmingham, AL',
          'hours': <String, dynamic>{'mon': '8-5'},
          'latitude': 33.5186,
          'longitude': -86.8104,
          'cityCode': 'us-bhm',
        },
      );

      final repository = HybridSearchRepository(
        localDataSource: spotsLocalDataSource,
        intakeRepository: intakeRepository,
      );
      final search = await repository.searchSpots(query: 'June');

      final spot =
          search.spots.firstWhere((candidate) => candidate.id == result.spotId);
      expect(spot.metadata['is_external'], isTrue);
      expect(spot.externalSyncMetadata?.sourceProvider, 'website');
      expect(
        signatureService.getStoredSignature(
          entityKind: SignatureEntityKind.spot,
          entityId: result.spotId!,
        ),
        isNotNull,
      );
    });
  });
}
