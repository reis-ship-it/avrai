/// Signature layer tests.
///
/// Purpose: verify deterministic DNA + pheromone builders, bundle composition,
/// Birmingham pheromone shaping, and signature-first fallback thresholds.
library;

import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
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
import 'package:flutter_test/flutter_test.dart';
import '../../../mocks/mock_storage_service.dart';

void main() {
  group('Signature layer', () {
    late SignatureConfidenceService confidenceService;
    late SignatureFreshnessTracker freshnessTracker;
    late SignatureMatchService matchService;
    late UserSignatureBuilder userSignatureBuilder;
    late SpotSignatureBuilder spotSignatureBuilder;
    late CommunitySignatureBuilder communitySignatureBuilder;
    late EventSignatureBuilder eventSignatureBuilder;
    late BundleSignatureBuilder bundleSignatureBuilder;

    setUp(() {
      confidenceService = const SignatureConfidenceService();
      freshnessTracker = const SignatureFreshnessTracker();
      matchService = const SignatureMatchService();
      userSignatureBuilder = UserSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      spotSignatureBuilder = SpotSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      communitySignatureBuilder = CommunitySignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      eventSignatureBuilder = EventSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
      bundleSignatureBuilder = BundleSignatureBuilder(
        confidenceService: confidenceService,
        freshnessTracker: freshnessTracker,
      );
    });

    test(
        'uses signature score when confidence is strong and falls back when weak',
        () {
      final userSignature = EntitySignature(
        signatureId: 'user:u1',
        entityId: 'u1',
        entityKind: SignatureEntityKind.user,
        dna: <String, double>{'exploration_eagerness': 0.9},
        pheromones: <String, double>{'community_orientation': 0.9},
        confidence: 0.9,
        freshness: 0.9,
        updatedAt: DateTime(2026, 3, 5),
        summary: 'user',
      );
      final strongEntity = EntitySignature(
        signatureId: 'spot:s1',
        entityId: 's1',
        entityKind: SignatureEntityKind.spot,
        dna: <String, double>{'exploration_eagerness': 0.9},
        pheromones: <String, double>{'community_orientation': 0.9},
        confidence: 0.9,
        freshness: 0.9,
        updatedAt: DateTime(2026, 3, 5),
        summary: 'strong',
      );
      final weakEntity = EntitySignature(
        signatureId: 'spot:s2',
        entityId: 's2',
        entityKind: SignatureEntityKind.spot,
        dna: <String, double>{'exploration_eagerness': 0.9},
        pheromones: <String, double>{'community_orientation': 0.9},
        confidence: 0.3,
        freshness: 0.9,
        updatedAt: DateTime(2026, 3, 5),
        summary: 'weak',
      );

      final strong = matchService.match(
        userSignature: userSignature,
        entitySignature: strongEntity,
        fallbackScore: 0.2,
      );
      final weak = matchService.match(
        userSignature: userSignature,
        entitySignature: weakEntity,
        fallbackScore: 0.2,
      );

      expect(strong.mode, SignatureScoreMode.signaturePrimary);
      expect(strong.finalScore, greaterThan(0.9));
      expect(weak.mode, SignatureScoreMode.fallback);
      expect(weak.finalScore, 0.2);
    });

    test('keeps Birmingham shaping in pheromones rather than DNA', () {
      final birminghamSpot = Spot(
        id: 'spot-bhm',
        name: 'Avondale coffee social',
        description: 'Neighborhood coffee meetup spot',
        latitude: 33.5186,
        longitude: -86.8104,
        category: 'Coffee',
        rating: 4.8,
        createdBy: 'owner-1',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
        cityCode: 'us-bhm',
        localityCode: 'us-bhm-avondale',
      );
      final genericSpot = birminghamSpot.copyWith(
        id: 'spot-generic',
        cityCode: null,
        localityCode: null,
      );

      final birminghamSignature =
          spotSignatureBuilder.build(spot: birminghamSpot);
      final genericSignature = spotSignatureBuilder.build(spot: genericSpot);

      expect(birminghamSignature.dna, genericSignature.dna);
      expect(
        birminghamSignature.pheromones['trust_network_reliance']!,
        greaterThan(genericSignature.pheromones['trust_network_reliance']!),
      );
    });

    test('bundle builder keeps linked entity ids and blended confidence', () {
      final spotSignature = EntitySignature(
        signatureId: 'spot:s1',
        entityId: 's1',
        entityKind: SignatureEntityKind.spot,
        dna: <String, double>{'exploration_eagerness': 0.7},
        pheromones: <String, double>{'community_orientation': 0.6},
        confidence: 0.8,
        freshness: 0.7,
        updatedAt: DateTime(2026, 3, 5),
        summary: 'spot',
      );
      final eventSignature = EntitySignature(
        signatureId: 'event:e1',
        entityId: 'e1',
        entityKind: SignatureEntityKind.event,
        dna: <String, double>{'exploration_eagerness': 0.9},
        pheromones: <String, double>{'community_orientation': 0.8},
        confidence: 0.6,
        freshness: 0.9,
        updatedAt: DateTime(2026, 3, 5),
        summary: 'event',
      );

      final bundle = bundleSignatureBuilder.build(
        BundleSignatureInput(
          bundleId: 'bundle-1',
          label: 'Performer + venue + event',
          components: <EntitySignature>[spotSignature, eventSignature],
        ),
      );

      expect(bundle, isNotNull);
      expect(bundle!.bundleEntityIds, containsAll(<String>['s1', 'e1']));
      expect(bundle.confidence, closeTo(0.7, 0.001));
    });

    test(
        'onboarding initialization seeds a persisted signature and later refreshes preserve dna baseline',
        () async {
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
      final userVibeAnalyzer = UserVibeAnalyzer(prefs: prefs);
      final service = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: matchService,
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
        userVibeAnalyzer: userVibeAnalyzer,
        personalityLearning: PersonalityLearning(),
      );

      final initialDimensions = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.2,
      }..['exploration_eagerness'] = 0.1;
      final evolvedDimensions = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.8,
      }..['exploration_eagerness'] = 0.95;
      final confidence = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.8,
      };
      final initialPersonality = PersonalityProfile(
        agentId: 'agent-1',
        userId: 'user-1',
        dimensions: initialDimensions,
        dimensionConfidence: confidence,
        archetype: 'Explorer',
        authenticity: 0.88,
        createdAt: DateTime(2026, 3, 5),
        lastUpdated: DateTime(2026, 3, 5),
        evolutionGeneration: 1,
        learningHistory: const <String, dynamic>{},
        corePersonality: initialDimensions,
      );
      final evolvedPersonality = PersonalityProfile(
        agentId: 'agent-1',
        userId: 'user-1',
        dimensions: evolvedDimensions,
        dimensionConfidence: confidence,
        archetype: 'Explorer',
        authenticity: 0.9,
        createdAt: DateTime(2026, 3, 5),
        lastUpdated: DateTime(2026, 3, 8),
        evolutionGeneration: 2,
        learningHistory: const <String, dynamic>{},
        corePersonality: evolvedDimensions,
      );
      final onboardingData = OnboardingData(
        agentId: 'agent-1',
        homebase: 'Birmingham',
        favoritePlaces: const <String>['Crestwood Park'],
        preferences: const <String, List<String>>{
          'Coffee': <String>['third wave'],
        },
        baselineLists: const <String>['Neighborhood spots'],
        openResponses: const <String, String>{
          'about_me': 'I like live music and neighborhood coffee shops.',
        },
        respectedFriends: const <String>['friend-1'],
        socialMediaConnected: const <String, bool>{'instagram': true},
        completedAt: DateTime(2026, 3, 5),
      );
      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Test User',
        location: 'Birmingham',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 8),
        hasCompletedOnboarding: true,
        tags: const <String>['live music'],
      );

      final seeded = await service.initializeUserSignatureFromOnboarding(
        userId: user.id,
        onboardingData: onboardingData,
        personality: initialPersonality,
        displayName: user.displayName,
        email: user.email,
      );
      final rawLatest = userSignatureBuilder.build(
        user: user,
        personality: evolvedPersonality,
        userVibe:
            await userVibeAnalyzer.compileUserVibe(user.id, evolvedPersonality),
      );
      final refreshed = await service.buildUserSignature(
        user: user,
        personality: evolvedPersonality,
      );

      expect(seeded.summary, contains('seeded from onboarding'));
      expect(
        seeded.sourceTrace.map((trace) => trace.label),
        contains('onboarding self-definition'),
      );
      expect(
        refreshed.dna['exploration_eagerness']!,
        greaterThan(seeded.dna['exploration_eagerness']!),
      );
      expect(
        refreshed.dna['exploration_eagerness']!,
        lessThan(rawLatest.dna['exploration_eagerness']!),
      );
      expect(
        service.getStoredSignature(
          entityKind: SignatureEntityKind.user,
          entityId: user.id,
        ),
        isNotNull,
      );
    });

    test(
        'behavioral signals update persisted signature pheromones after onboarding',
        () async {
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
      final userVibeAnalyzer = UserVibeAnalyzer(prefs: prefs);
      final service = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: matchService,
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
        userVibeAnalyzer: userVibeAnalyzer,
        personalityLearning: PersonalityLearning(),
      );
      final dimensions = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.25,
      };
      final confidence = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.8,
      };
      final personality = PersonalityProfile(
        agentId: 'agent-2',
        userId: 'user-2',
        dimensions: dimensions,
        dimensionConfidence: confidence,
        archetype: 'Explorer',
        authenticity: 0.84,
        createdAt: DateTime(2026, 3, 5),
        lastUpdated: DateTime(2026, 3, 5),
        evolutionGeneration: 1,
        learningHistory: const <String, dynamic>{},
        corePersonality: dimensions,
      );
      final onboardingData = OnboardingData(
        agentId: 'agent-2',
        homebase: 'Birmingham',
        completedAt: DateTime(2026, 3, 5),
      );
      final user = UnifiedUser(
        id: 'user-2',
        email: 'user2@example.com',
        displayName: 'User Two',
        location: 'Birmingham',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
        hasCompletedOnboarding: true,
      );
      final seeded = await service.initializeUserSignatureFromOnboarding(
        userId: user.id,
        onboardingData: onboardingData,
        personality: personality,
        displayName: user.displayName,
        email: user.email,
      );
      final spot = Spot(
        id: 'spot-learn-1',
        name: 'Late-night jazz room',
        description: 'Small live music venue with a strong local crowd.',
        latitude: 33.52,
        longitude: -86.8,
        category: 'Music',
        rating: 4.9,
        createdBy: 'owner-2',
        createdAt: DateTime(2026, 3, 6),
        updatedAt: DateTime(2026, 3, 6),
        cityCode: 'us-bhm',
        localityCode: 'us-bhm-lakeview',
      );

      final learned = await service.recordSpotViewSignal(
        user: user,
        spot: spot,
        personality: personality,
      );
      final rebuilt = await service.buildUserSignature(
        user: user,
        personality: personality,
      );

      expect(learned.pheromones, isNot(equals(seeded.pheromones)));
      expect(
        learned.sourceTrace.any(
          (trace) => trace.label.contains('behavioral learning signals'),
        ),
        isTrue,
      );
      expect(
        rebuilt.sourceTrace.any(
          (trace) => trace.label.contains('behavioral learning signals'),
        ),
        isTrue,
      );
    });

    test('chat reflection signals can nudge the persisted signature baseline',
        () async {
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
      final service = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: matchService,
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
      final dimensions = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.3,
      };
      final confidence = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.8,
      };
      final personality = PersonalityProfile(
        agentId: 'agent-chat',
        userId: 'user-chat',
        dimensions: dimensions,
        dimensionConfidence: confidence,
        archetype: 'Explorer',
        authenticity: 0.82,
        createdAt: DateTime(2026, 3, 5),
        lastUpdated: DateTime(2026, 3, 5),
        evolutionGeneration: 1,
        learningHistory: const <String, dynamic>{},
        corePersonality: dimensions,
      );
      final onboardingData = OnboardingData(
        agentId: 'agent-chat',
        homebase: 'Birmingham',
        completedAt: DateTime(2026, 3, 5),
      );

      final seeded = await service.initializeUserSignatureFromOnboarding(
        userId: 'user-chat',
        onboardingData: onboardingData,
        personality: personality,
      );
      final reflected = await service.recordChatReflectionSignal(
        userId: 'user-chat',
        messageText: 'I want more live music and community events this week.',
        personality: personality,
      );

      expect(
        reflected.pheromones['community_orientation']!,
        greaterThanOrEqualTo(seeded.pheromones['community_orientation']!),
      );
      expect(
        reflected.sourceTrace
            .any((trace) => trace.sourceId == 'chat_reflection'),
        isTrue,
      );
    });

    test('browse selection and strong intent negative signals persist learning',
        () async {
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
      final service = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: matchService,
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
      final dimensions = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.28,
      };
      final confidence = <String, double>{
        for (final dimension in VibeConstants.coreDimensions) dimension: 0.82,
      };
      final personality = PersonalityProfile(
        agentId: 'agent-browse',
        userId: 'user-browse',
        dimensions: dimensions,
        dimensionConfidence: confidence,
        archetype: 'Explorer',
        authenticity: 0.83,
        createdAt: DateTime(2026, 3, 5),
        lastUpdated: DateTime(2026, 3, 5),
        evolutionGeneration: 1,
        learningHistory: const <String, dynamic>{},
        corePersonality: dimensions,
      );
      final onboardingData = OnboardingData(
        agentId: 'agent-browse',
        homebase: 'Birmingham',
        completedAt: DateTime(2026, 3, 5),
      );

      final seeded = await service.initializeUserSignatureFromOnboarding(
        userId: 'user-browse',
        onboardingData: onboardingData,
        personality: personality,
      );
      final community = Community(
        id: 'community-browse',
        name: 'Neighborhood Garden Club',
        description: 'Weekend volunteering and social gardening.',
        category: 'Volunteer',
        originatingEventId: 'community-source-event',
        originatingEventType: OriginatingEventType.communityEvent,
        memberIds: const <String>[],
        founderId: 'founder-1',
        originalLocality: 'Birmingham',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );
      final host = UnifiedUser(
        id: 'host-browse',
        email: 'host@example.com',
        displayName: 'Host',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );
      final event = ExpertiseEvent(
        id: 'event-browse',
        title: 'Live Jazz Rooftop',
        description: 'Late-night rooftop set with local artists.',
        category: 'Music',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime(2026, 3, 7, 20),
        endTime: DateTime(2026, 3, 7, 23),
        maxAttendees: 50,
        attendeeCount: 12,
        isPaid: true,
        price: 18,
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
        location: 'Birmingham',
      );

      final afterCommunity = await service.recordCommunityBrowseSelectionSignal(
        userId: 'user-browse',
        community: community,
        personality: personality,
      );
      final afterEvent = await service.recordEventBrowseSelectionSignal(
        userId: 'user-browse',
        event: event,
        personality: personality,
      );
      final afterSoftIgnore = await service.recordNegativePreferenceSignal(
        userId: 'user-browse',
        title: 'Sports Bar Crawl',
        subtitle: 'Late-night sports bar rotation',
        category: 'Nightlife',
        tags: const <String>['sports', 'bar'],
        personality: personality,
        intent: NegativePreferenceIntent.softIgnore,
      );
      final afterNegative = await service.recordNegativePreferenceSignal(
        userId: 'user-browse',
        title: 'Sports Bar Crawl',
        subtitle: 'Late-night sports bar rotation',
        category: 'Nightlife',
        tags: const <String>['sports', 'bar'],
        personality: personality,
        intent: NegativePreferenceIntent.hardNotInterested,
      );

      final softDelta = afterSoftIgnore.pheromones.entries.fold<double>(
        0,
        (sum, entry) =>
            sum + (entry.value - (seeded.pheromones[entry.key] ?? 0)).abs(),
      );
      final hardDelta = afterNegative.pheromones.entries.fold<double>(
        0,
        (sum, entry) =>
            sum + (entry.value - (seeded.pheromones[entry.key] ?? 0)).abs(),
      );

      expect(afterCommunity.pheromones, isNot(equals(seeded.pheromones)));
      expect(
        afterEvent.sourceTrace.any(
          (trace) => trace.sourceId == 'event_browse_select',
        ),
        isTrue,
      );
      expect(
        afterSoftIgnore.sourceTrace
            .any((trace) => trace.sourceId == 'soft_ignore'),
        isTrue,
      );
      expect(
        afterNegative.sourceTrace.any(
          (trace) => trace.sourceId == 'hard_not_interested',
        ),
        isTrue,
      );
      expect(hardDelta, greaterThan(softDelta));
    });

    test(
        'entity signature service builds event bundle signatures with venue data',
        () async {
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
      final service = EntitySignatureService(
        repository: SignatureRepository(),
        storageService: StorageService.instance,
        matchService: matchService,
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

      final host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        displayName: 'Host',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );
      final venue = Spot(
        id: 'venue-1',
        name: 'Saturn',
        description: 'Live music room',
        latitude: 33.512,
        longitude: -86.799,
        category: 'Music',
        rating: 4.7,
        createdBy: 'owner-1',
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );
      final event = ExpertiseEvent(
        id: 'event-1',
        title: 'Indie night',
        description: 'Performer showcase at Saturn',
        category: 'Music',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime(2026, 3, 6, 20),
        endTime: DateTime(2026, 3, 6, 23),
        spots: <Spot>[venue],
        createdAt: DateTime(2026, 3, 5),
        updatedAt: DateTime(2026, 3, 5),
      );

      final signature = await service.buildEventSignature(event: event);

      expect(signature.bundleEntityIds,
          containsAll(<String>['host-1', 'venue-1']));
      expect(
        service.getStoredSignature(
          entityKind: SignatureEntityKind.event,
          entityId: 'event-1',
        ),
        isNotNull,
      );

      MockGetStorage.reset();
    });
  });
}
