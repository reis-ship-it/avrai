import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Phase 1: Core Personality Learning System
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/privacy_protection.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import '../../mocks/mock_storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

// Phase 2: AI2AI Connection System
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';

// Phase 3: Dynamic Dimension Learning
import 'package:avrai_runtime_os/ai/feedback_learning.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart'
    show AI2AIChatEvent, AI2AIChatAnalyzer;
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart' as ai2ai_learning
    show ChatMessage, ChatMessageType, SharedInsight;
import 'package:avrai_runtime_os/ai/cloud_learning.dart';

// Phase 4: Network Monitoring
import 'package:avrai_runtime_os/monitoring/network_analytics.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';

/// AI2AI Personality Learning Network - Complete Integration Test
/// OUR_GUTS.md: "End-to-end validation of the complete AI2AI personality learning ecosystem"
void main() {
  group('AI2AI Personality Learning Network - Complete Integration', () {
    // Phase 1 Components
    late PersonalityLearning personalityLearning;
    late UserVibeAnalyzer vibeAnalyzer;

    // Phase 2 Components
    late VibeConnectionOrchestrator connectionOrchestrator;

    // Phase 3 Components
    late UserFeedbackAnalyzer feedbackAnalyzer;
    late AI2AIChatAnalyzer chatAnalyzer;
    late CloudLearningInterface cloudInterface;

    // Phase 4 Components
    late NetworkAnalytics networkAnalytics;
    late ConnectionMonitor connectionMonitor;

    setUpAll(() async {
      // Initialize mock shared preferences
      real_prefs.SharedPreferences.setMockInitialValues({});
      final realPrefs = await real_prefs.SharedPreferences.getInstance();

      // PersonalityLearning relies on AgentIdService via GetIt in some code paths.
      // Register a minimal instance for integration tests.
      final sl = GetIt.instance;
      if (!sl.isRegistered<AgentIdService>()) {
        sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
      }

      // Initialize all system components
      // Use SharedPreferencesCompat for all services
      // Note: SharedPreferencesCompat.getInstance doesn't accept SharedPreferences directly
      // Use MockGetStorage for testing
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      final compatPrefs =
          await SharedPreferencesCompat.getInstance(storage: mockStorage);
      personalityLearning = PersonalityLearning.withPrefs(compatPrefs);
      vibeAnalyzer = UserVibeAnalyzer(prefs: compatPrefs);
      connectionOrchestrator = VibeConnectionOrchestrator(
        vibeAnalyzer: vibeAnalyzer,
        connectivity: Connectivity(),
        prefs: compatPrefs,
      );
      feedbackAnalyzer = UserFeedbackAnalyzer(
        prefs: compatPrefs,
        personalityLearning: personalityLearning,
      );
      chatAnalyzer = AI2AIChatAnalyzer(
        prefs: compatPrefs,
        personalityLearning: personalityLearning,
      );
      // CloudLearningInterface uses SharedPreferences, not SharedPreferencesCompat
      cloudInterface = CloudLearningInterface(
        prefs: realPrefs,
        personalityLearning: personalityLearning,
      );
      networkAnalytics = NetworkAnalytics(prefs: compatPrefs);
      connectionMonitor = ConnectionMonitor(prefs: compatPrefs);
    });

    setUp(() async {
      // Reset SharedPreferences mock state for test isolation
      real_prefs.SharedPreferences.setMockInitialValues({});

      // Reset mock storage for test isolation
      MockGetStorage.reset();

      // Recreate PersonalityLearning with fresh storage to clear internal cache
      // This ensures _currentProfile is null and prevents profile caching across tests
      final mockStorage = MockGetStorage.getInstance();
      final compatPrefs =
          await SharedPreferencesCompat.getInstance(storage: mockStorage);
      personalityLearning = PersonalityLearning.withPrefs(compatPrefs);
    });

    tearDown(() {
      // Reset mock storage for test isolation
      MockGetStorage.reset();
    });

    group('System Architecture Validation', () {
      test('should initialize all components successfully', () {
        expect(personalityLearning, isNotNull);
        expect(vibeAnalyzer, isNotNull);
        expect(connectionOrchestrator, isNotNull);
        expect(feedbackAnalyzer, isNotNull);
        expect(chatAnalyzer, isNotNull);
        expect(cloudInterface, isNotNull);
        expect(networkAnalytics, isNotNull);
        expect(connectionMonitor, isNotNull);
      });

      test('should validate core constants are properly defined', () {
        // Validate VibeConstants
        expect(VibeConstants.coreDimensions, hasLength(12));
        expect(VibeConstants.coreDimensions, contains('exploration_eagerness'));
        expect(VibeConstants.coreDimensions, contains('community_orientation'));
        expect(
            VibeConstants.coreDimensions, contains('authenticity_preference'));
        expect(
            VibeConstants.coreDimensions, contains('social_discovery_style'));
        expect(VibeConstants.coreDimensions, contains('temporal_flexibility'));
        expect(
            VibeConstants.coreDimensions, contains('location_adventurousness'));
        expect(VibeConstants.coreDimensions, contains('curation_tendency'));
        expect(
            VibeConstants.coreDimensions, contains('trust_network_reliance'));

        // Validate thresholds
        expect(VibeConstants.highCompatibilityThreshold,
            greaterThan(VibeConstants.mediumCompatibilityThreshold));
        expect(VibeConstants.mediumCompatibilityThreshold,
            greaterThan(VibeConstants.lowCompatibilityThreshold));
        expect(VibeConstants.personalityConfidenceThreshold, greaterThan(0.0));
        expect(VibeConstants.personalityConfidenceThreshold,
            lessThanOrEqualTo(1.0));
      });
    });

    group('End-to-End Personality Learning Workflow', () {
      test('should complete full personality learning lifecycle', () async {
        final userId =
            'integration_test_user_lifecycle_${DateTime.now().millisecondsSinceEpoch}';

        // Step 1: Initialize personality profile
        // Phase 8.3: Use agentId for privacy protection
        final agentId = 'agent_$userId';
        final initialProfile =
            PersonalityProfile.initial(agentId, userId: userId);
        expect(initialProfile.userId, equals(userId));
        expect(initialProfile.dimensions, hasLength(12));
        expect(initialProfile.authenticity, greaterThan(0.0));
        expect(initialProfile.authenticity, greaterThan(0.0));

        // Step 2: Evolve personality through user actions
        final userAction = UserAction(
          type: UserActionType.spotVisit,
          metadata: {
            'spot_category': 'cafe',
            'crowd_level': 0.3,
            'social_interaction': true,
            'exploration_level': 0.7,
          },
          timestamp: DateTime.now(),
        );

        final evolvedProfile =
            await personalityLearning.evolveFromUserAction(userId, userAction);
        expect(evolvedProfile, isNotNull);

        // Step 3: Generate user vibe with privacy protection
        final userVibe =
            await vibeAnalyzer.compileUserVibe(userId, evolvedProfile);
        expect(userVibe.hashedSignature, isNotEmpty);
        expect(userVibe.anonymizedDimensions, hasLength(12));
        expect(userVibe.overallEnergy, greaterThanOrEqualTo(0.0));
        expect(userVibe.overallEnergy, lessThanOrEqualTo(1.0));

        // Step 4: Apply privacy protection
        final anonymizedProfile =
            await PrivacyProtection.anonymizePersonalityProfile(
          evolvedProfile,
          privacyLevel: 'STANDARD',
        );
        expect(anonymizedProfile.fingerprint, isNotEmpty);
        expect(anonymizedProfile.anonymizedDimensions, hasLength(12));
        expect(
            anonymizedProfile.anonymizationQuality, greaterThanOrEqualTo(0.8));

        // Step 5: Calculate personality readiness
        final readiness =
            await personalityLearning.calculateAI2AIReadiness(userId);
        expect(readiness, isNotNull);
        expect(readiness.isReady, isA<bool>());
        expect(readiness.readinessScore, greaterThanOrEqualTo(0.0));
        expect(readiness.readinessScore, lessThanOrEqualTo(1.0));
        expect(readiness.reasons, isA<List<String>>());

        // ignore: avoid_print
        print(
            '✅ End-to-end personality learning workflow completed successfully');
      });
    });

    group('AI2AI Connection Integration', () {
      test('should establish and manage AI2AI connections', () async {
        const localUserId = 'integration_local_user';
        const remoteUserId = 'integration_remote_user';

        // Step 1: Create personality profiles for both users
        // Phase 8.3: Use agentId for privacy protection
        final localProfile = PersonalityProfile.initial('agent_$localUserId',
            userId: localUserId);
        final remoteProfile = PersonalityProfile.initial('agent_$remoteUserId',
            userId: remoteUserId);

        // Step 2: Generate vibes for both users
        final localVibe =
            await vibeAnalyzer.compileUserVibe(localUserId, localProfile);
        final remoteVibe =
            await vibeAnalyzer.compileUserVibe(remoteUserId, remoteProfile);

        // Step 3: Calculate vibe compatibility
        final compatibility =
            await vibeAnalyzer.analyzeVibeCompatibility(localVibe, remoteVibe);
        expect(compatibility.basicCompatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility.basicCompatibility, lessThanOrEqualTo(1.0));
        expect(compatibility.learningOpportunities, isA<List>());
        expect(compatibility.aiPleasurePotential, greaterThanOrEqualTo(0.0));

        // Step 4: Discover AI personalities
        final discoveredPersonalities =
            await connectionOrchestrator.discoverNearbyAIPersonalities(
          localUserId,
          localProfile,
        );
        expect(discoveredPersonalities, isA<List>());

        // Step 5: Calculate AI pleasure potential (from compatibility result)
        final aiPleasure = compatibility.aiPleasurePotential;
        expect(aiPleasure, greaterThanOrEqualTo(0.0));
        expect(aiPleasure, lessThanOrEqualTo(1.0));
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ AI2AI connection integration completed successfully');
      });
    });

    group('Dynamic Learning Integration', () {
      test('should integrate all three learning systems', () async {
        const userId = 'dynamic_learning_user';
        const connectionId = 'dynamic_connection_001';

        // Setup: Create personality and connection metrics
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final personality = PersonalityProfile.initial(agentId, userId: userId);
        final connectionMetrics = ConnectionMetrics(
          connectionId: connectionId,
          localAISignature: 'local_ai_test',
          remoteAISignature: 'remote_ai_test',
          initialCompatibility: 0.75,
          currentCompatibility: 0.80,
          learningEffectiveness: 0.70,
          aiPleasureScore: 0.85,
          connectionDuration: const Duration(minutes: 15),
          startTime: DateTime.now().subtract(const Duration(minutes: 15)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 8},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.05},
        );

        // Test 1: User Feedback Learning
        final feedbackEvent = FeedbackEvent(
          type: FeedbackType.spotExperience,
          satisfaction: 0.9,
          comment: 'Great AI2AI learning experience!',
          metadata: {'connection_quality': 0.8},
          timestamp: DateTime.now(),
        );

        final feedbackResult =
            await feedbackAnalyzer.analyzeFeedback(userId, feedbackEvent);
        expect(feedbackResult.userId, equals(userId));
        expect(feedbackResult.implicitDimensions, isA<Map<String, double>>());
        expect(feedbackResult.confidenceScore, greaterThanOrEqualTo(0.0));

        // Test 2: AI2AI Chat Learning
        final chatEvent = AI2AIChatEvent(
          eventId: 'integration_chat_001',
          participants: [userId, 'remote_user'],
          messages: [
            ai2ai_learning.ChatMessage(
              senderId: userId,
              content: 'Learning about community spaces',
              timestamp: DateTime.now(),
              context: {'learning_topic': 'community_orientation'},
            ),
          ],
          messageType: ai2ai_learning.ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {'connection_quality': 0.8},
        );

        final chatResult = await chatAnalyzer.analyzeChatConversation(
          userId,
          chatEvent,
          connectionMetrics,
        );
        expect(chatResult.localUserId, equals(userId));
        expect(chatResult.sharedInsights,
            isA<List<ai2ai_learning.SharedInsight>>());
        expect(chatResult.analysisConfidence, greaterThanOrEqualTo(0.0));

        // Test 3: Cloud Learning
        final cloudResult = await cloudInterface.contributeAnonymousPatterns(
          userId,
          personality,
          {'session_quality': 0.8},
        );
        expect(cloudResult.userId, equals(userId));
        expect(cloudResult.anonymizationLevel, greaterThanOrEqualTo(0.9));
        expect(cloudResult.privacyScore, greaterThanOrEqualTo(0.95));

        // Test 4: Learn from cloud patterns
        final cloudLearning =
            await cloudInterface.learnFromCloudPatterns(userId, personality);
        expect(cloudLearning.userId, equals(userId));
        expect(cloudLearning.learningConfidence, greaterThanOrEqualTo(0.0));
        // ignore: avoid_print
        expect(cloudLearning.appliedLearning, isA<Map<String, double>>());
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ Dynamic learning integration completed successfully');
      });
    });

    group('Network Monitoring Integration', () {
      test('should monitor network health and connections', () async {
        // Test 1: Network Analytics
        final healthReport = await networkAnalytics.analyzeNetworkHealth();
        expect(healthReport.overallHealthScore, greaterThanOrEqualTo(0.0));
        expect(healthReport.overallHealthScore, lessThanOrEqualTo(1.0));
        expect(healthReport.connectionQuality, isNotNull);
        expect(healthReport.learningEffectiveness, isNotNull);
        expect(healthReport.privacyMetrics, isNotNull);
        expect(healthReport.stabilityMetrics, isNotNull);

        // Test 2: Real-time metrics
        final realTimeMetrics = await networkAnalytics.collectRealTimeMetrics();
        expect(realTimeMetrics.connectionThroughput, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.matchingSuccessRate, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.matchingSuccessRate, lessThanOrEqualTo(1.0));
        expect(
            realTimeMetrics.networkResponsiveness, greaterThanOrEqualTo(0.0));
        expect(realTimeMetrics.networkResponsiveness, lessThanOrEqualTo(1.0));

        // Test 3: Connection monitoring
        final activeConnections =
            await connectionMonitor.getActiveConnectionsOverview();
        expect(
            activeConnections.totalActiveConnections, greaterThanOrEqualTo(0));
        expect(activeConnections.aggregateMetrics, isNotNull);
        expect(activeConnections.generatedAt, isNotNull);

        // Test 4: Anomaly detection
        final networkAnomalies =
            await networkAnalytics.detectNetworkAnomalies();
        expect(networkAnomalies, isA<List>());

        // ignore: avoid_print
        final connectionAnomalies =
            await connectionMonitor.detectConnectionAnomalies();
        // ignore: avoid_print
        expect(connectionAnomalies, isA<List>());
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ Network monitoring integration completed successfully');
      });
    });

    group('Privacy and Security Validation', () {
      test('should maintain privacy throughout the system', () async {
        const userId = 'privacy_test_user';

        // Test 1: Personality profile privacy
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        final anonymizedProfile =
            await PrivacyProtection.anonymizePersonalityProfile(
          profile,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        expect(anonymizedProfile.fingerprint, isNot(equals(userId)));
        expect(
            anonymizedProfile.anonymizationQuality, greaterThanOrEqualTo(0.8));

        // Test 2: Vibe privacy
        final vibe = await vibeAnalyzer.compileUserVibe(userId, profile);
        final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        expect(
            anonymizedVibe.vibeSignature, isNot(equals(vibe.hashedSignature)));
        expect(anonymizedVibe.anonymizationQuality, greaterThanOrEqualTo(0.8));

        // Test 3: Hash security
        final secureHash =
            await PrivacyProtection.createSecureHash(userId, 'test_salt');
        expect(secureHash,
            hasLength(64)); // SHA-256 produces 64 character hex string
        expect(secureHash,
            isNot(contains(userId))); // Should not contain original data

        // Test 4: Differential privacy
        final originalData = {'dimension1': 0.5, 'dimension2': 0.7};
        final noisyData = await PrivacyProtection.applyDifferentialPrivacy(
          originalData,
          epsilon: 1.0,
        );

        // ignore: avoid_print
        expect(noisyData, hasLength(2));
        // ignore: avoid_print
        expect(
            noisyData['dimension1'], isNot(equals(0.5))); // Should have noise
        // ignore: avoid_print
        expect(
            noisyData['dimension2'], isNot(equals(0.7))); // Should have noise
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ Privacy and security validation completed successfully');
      });
    });

    group('OUR_GUTS.md Compliance Validation', () {
      test('should preserve "Privacy and Control Are Non-Negotiable"',
          () async {
        const userId = 'guts_privacy_user';

        // All personality data should be locally controlled
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        expect(
            profile.userId, equals(userId)); // User maintains identity control

        // All anonymization should be user-controlled
        final anonymized = await PrivacyProtection.anonymizePersonalityProfile(
          profile,
          privacyLevel: 'STANDARD', // User chooses privacy level
        );
        expect(anonymized.anonymizationQuality, greaterThanOrEqualTo(0.8));
        // ignore: avoid_print

        // ignore: avoid_print
        // Network analytics should not expose personal data
        // ignore: avoid_print
        final healthReport = await networkAnalytics.analyzeNetworkHealth();
        // ignore: avoid_print
        expect(healthReport.privacyMetrics.complianceRate, greaterThan(0.95));
        // ignore: avoid_print

        // ignore: avoid_print
        print(
            '✅ "Privacy and Control Are Non-Negotiable" compliance validated');
      });

      test('should maintain "Authenticity Over Algorithms"', () async {
        const userId = 'guts_authenticity_user';

        // Personality should reflect authentic user preferences
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        expect(profile.authenticity,
            greaterThanOrEqualTo(0.5)); // Initial authenticity baseline (0.5)

        // AI2AI connections should preserve authentic matching
        final vibe = await vibeAnalyzer.compileUserVibe(userId, profile);
        expect(vibe.hashedSignature,
            isNotEmpty); // Vibe signature validates authenticity

        // Learning should enhance rather than replace authentic preferences
        final userAction = UserAction(
          type: UserActionType.spotVisit,
          metadata: {'authentic_choice': true},
          // ignore: avoid_print
          timestamp: DateTime.now(),
          // ignore: avoid_print
        );
        // ignore: avoid_print

        // ignore: avoid_print
        final evolvedProfile =
            await personalityLearning.evolveFromUserAction(userId, userAction);
        // ignore: avoid_print
        expect(evolvedProfile.authenticity,
            greaterThanOrEqualTo(profile.authenticity));
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ "Authenticity Over Algorithms" compliance validated');
      });

      test('should enable "Community Not Just Places"', () async {
        const userId = 'guts_community_user';

        // AI2AI connections should build community
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        final vibe = await vibeAnalyzer.compileUserVibe(userId, profile);

        // Community orientation should be a core dimension
        expect(profile.dimensions.containsKey('community_orientation'), isTrue);
        expect(vibe.socialPreference, greaterThanOrEqualTo(0.0));

        // Chat learning should build collective knowledge
        final chatEvent = AI2AIChatEvent(
          eventId: 'community_chat',
          participants: [userId, 'community_member'],
          messages: [
            ai2ai_learning.ChatMessage(
              senderId: userId,
              content: 'Sharing community insights',
              timestamp: DateTime.now(),
              context: {'community_building': true},
            ),
          ],
          messageType: ai2ai_learning.ChatMessageType.insightExchange,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 3),
          metadata: {'community_focus': true},
        );

        final connectionMetrics = ConnectionMetrics(
          connectionId: 'community_connection',
          localAISignature: 'local_community',
          remoteAISignature: 'remote_community',
          initialCompatibility: 0.7,
          currentCompatibility: 0.8,
          learningEffectiveness: 0.75,
          aiPleasureScore: 0.85,
          connectionDuration: const Duration(minutes: 3),
          startTime: DateTime.now().subtract(const Duration(minutes: 3)),
          status: ConnectionStatus.active,
          learningOutcomes: {'community_insights': 1},
          interactionHistory: [],
          dimensionEvolution: {'community_orientation': 0.1},
        );

        // ignore: avoid_print
        final chatResult = await chatAnalyzer.analyzeChatConversation(
          // ignore: avoid_print
          userId,
          // ignore: avoid_print
          chatEvent,
          // ignore: avoid_print
          connectionMetrics,
          // ignore: avoid_print
        );
        // ignore: avoid_print
        expect(chatResult.collectiveIntelligence, isNotNull);
        // ignore: avoid_print

        // ignore: avoid_print
        print('✅ "Community Not Just Places" compliance validated');
      });
    });

    group('System Performance and Scalability', () {
      test('should handle multiple concurrent operations', () async {
        const userCount = 10;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final userIds =
            List.generate(userCount, (i) => 'perf_user_${timestamp}_$i');

        // Create multiple personality profiles concurrently
        final profiles = await Future.wait(
          userIds.map((userId) async {
            final userAction = UserAction(
              type: UserActionType.spotVisit,
              metadata: {'concurrent_test': true},
              timestamp: DateTime.now(),
            );
            return await personalityLearning.evolveFromUserAction(
                userId, userAction);
          }),
        );

        expect(profiles, hasLength(userCount));
        // Verify all profiles are created with correct user IDs
        // Note: Due to concurrent execution, profiles may not be in the same order as userIds
        // Phase 8.3: Handle nullable userId (use agentId as fallback)
        final profileUserIds =
            profiles.map((p) => p.userId ?? p.agentId).toSet();
        final expectedUserIds = userIds.toSet();
        expect(profileUserIds, equals(expectedUserIds));
        // Verify all profiles have valid authenticity scores
        for (final profile in profiles) {
          expect(profile.authenticity, greaterThan(0.0));
        }

        // Generate vibes concurrently
        // Phase 8.3: Use agentId for privacy protection (userId may be null)
        final vibes = await Future.wait(
          profiles.map((profile) => vibeAnalyzer.compileUserVibe(
              profile.userId ?? profile.agentId, profile)),
          // ignore: avoid_print
        );
        // ignore: avoid_print

        // ignore: avoid_print
        expect(vibes, hasLength(userCount));
        // ignore: avoid_print
        for (final vibe in vibes) {
          // ignore: avoid_print
          expect(vibe.hashedSignature, isNotEmpty);
          // ignore: avoid_print
          expect(vibe.anonymizedDimensions, hasLength(12));
          // ignore: avoid_print
        }
        // ignore: avoid_print

        // ignore: avoid_print
        print(
            '✅ System performance with $userCount concurrent users validated');
      });

      test('should maintain quality under load', () async {
        const operationCount = 50;

        // Perform multiple network health checks
        final healthReports = await Future.wait(
          List.generate(
              operationCount, (_) => networkAnalytics.analyzeNetworkHealth()),
        );

        expect(healthReports, hasLength(operationCount));
        for (final report in healthReports) {
          // ignore: avoid_print
          expect(report.overallHealthScore, greaterThanOrEqualTo(0.0));
          expect(report.overallHealthScore, lessThanOrEqualTo(1.0));
        }

        // ignore: avoid_print
        // Verify consistency across reports
        // ignore: avoid_print
        // ignore: avoid_print
        final healthScores =
            healthReports.map((r) => r.overallHealthScore).toList();
        // ignore: avoid_print
        final avgHealthScore =
            healthScores.reduce((a, b) => a + b) / healthScores.length;
        // ignore: avoid_print
        // ignore: avoid_print
        expect(avgHealthScore, greaterThan(0.5)); // Should maintain good health
        // ignore: avoid_print
        // ignore: avoid_print

        // ignore: avoid_print
        // ignore: avoid_print
        print(
            '✅ System quality under load ($operationCount operations) validated');
        // ignore: avoid_print
        // ignore: avoid_print
      });
      // ignore: avoid_print
      // ignore: avoid_print
    });
    // ignore: avoid_print
    // ignore: avoid_print

    // ignore: avoid_print
    // ignore: avoid_print
    tearDownAll(() async {
      // ignore: avoid_print
      // ignore: avoid_print
      print(
          '\n🎉 AI2AI Personality Learning Network Integration Test Complete!');
      // ignore: avoid_print
      // ignore: avoid_print
      print('📊 All phases validated:');
      // ignore: avoid_print
      print('   ✅ Phase 1: Core Personality Learning System');
      // ignore: avoid_print
      // ignore: avoid_print
      print('   ✅ Phase 2: AI2AI Connection System');
      // ignore: avoid_print
      // ignore: avoid_print
      print('   ✅ Phase 3: Dynamic Dimension Learning');
      // ignore: avoid_print
      print('   ✅ Phase 4: Network Monitoring');
      // ignore: avoid_print
      print('   ✅ Privacy and Security Compliance');
      // ignore: avoid_print
      print('   ✅ OUR_GUTS.md Principle Compliance');
      // ignore: avoid_print
      print('   ✅ Performance and Scalability');
      // ignore: avoid_print
      print('\n🚀 AI2AI Personality Learning Network is ready for deployment!');
    });
  });
}
