import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/trust_network.dart';

/// Tests for AI2AI Trust Network Management
/// OUR_GUTS.md: "Trust network establishment without identity exposure"
/// 
/// These tests ensure robust trust relationships between anonymous AI agents
/// for optimal development debugging and deployment performance
void main() {
  group('TrustNetworkManager', () {
    late TrustNetworkManager trustManager;
    
    setUp(() {
      trustManager = TrustNetworkManager();
    });

    group('Trust Relationship Establishment', () {
      test('should establish trust relationship with valid context', () async {
        final trustContext = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: true,
          hasCommunityEndorsement: true,
          hasRecentActivity: true,
          behaviorSignature: 'anon-behavior-sig-123',
          activityLevel: 0.8,
          communityScore: 0.7,
        );

        final relationship = await trustManager.establishTrust(
          'test-agent-123',
          trustContext,
        );

        expect(relationship.agentId, equals('test-agent-123'));
        expect(relationship.trustScore, greaterThan(0.5));
        expect(relationship.trustScore, lessThanOrEqualTo(1.0));
        expect(relationship.trustLevel, isNot(equals(TrustLevel.unverified)));
        expect(relationship.interactionCount, equals(1));
        expect(relationship.anonymousFactors, isNotEmpty);
      });

      test('should reject trust establishment with user data present', () async {
        final invalidContext = TrustContext(
          hasUserData: true, // Invalid - contains user data
          hasValidatedBehavior: false,
          hasCommunityEndorsement: false,
          hasRecentActivity: false,
          behaviorSignature: 'behavior-sig',
          activityLevel: 0.5,
          communityScore: 0.5,
        );

        expect(
          () => trustManager.establishTrust('agent-with-user-data', invalidContext),
          throwsA(isA<TrustNetworkException>()),
        );
      });

      test('should store anonymous factors without exposing identity', () async {
        final context = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: true,
          hasCommunityEndorsement: false,
          hasRecentActivity: true,
          behaviorSignature: 'anon-sig-456',
          activityLevel: 0.6,
          communityScore: 0.5,
        );

        final relationship = await trustManager.establishTrust('anon-agent', context);

        expect(relationship.anonymousFactors['behaviorPattern'], equals('anon-sig-456'));
        expect(relationship.anonymousFactors['activityLevel'], equals(0.6));
        expect(relationship.anonymousFactors['communityScore'], equals(0.5));
        expect(relationship.anonymousFactors['timestamp'], isNotNull);
        
        // Should not contain any user-identifying information
        final factorsString = relationship.anonymousFactors.toString();
        expect(factorsString.toLowerCase(), isNot(contains('user')));
        expect(factorsString.toLowerCase(), isNot(contains('email')));
        expect(factorsString.toLowerCase(), isNot(contains('name')));
      });
    });

    group('Trust Score Updates', () {
      test('should update trust score based on positive interactions', () async {
        final initialContext = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: true,
          hasCommunityEndorsement: false,
          hasRecentActivity: true,
          behaviorSignature: 'update-test-sig',
          activityLevel: 0.5,
          communityScore: 0.5,
        );

        final initial = await trustManager.establishTrust('update-agent', initialContext);
        final initialScore = initial.trustScore;

        final positiveInteraction = TrustInteraction(
          type: InteractionType.successfulRecommendation,
          impactScore: 0.8,
          timestamp: DateTime.now(),
          context: {'recommendation_accuracy': 0.9},
        );

        final updated = await trustManager.updateTrustScore('update-agent', positiveInteraction);

        expect(updated.trustScore, greaterThan(initialScore));
        expect(updated.interactionCount, equals(initial.interactionCount + 1));
        expect(updated.lastInteraction.isAfter(initial.lastInteraction), isTrue);
      });

      test('should enforce trust score bounds during updates', () async {
        final context = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: false,
          hasCommunityEndorsement: false,
          hasRecentActivity: false,
          behaviorSignature: 'bounds-test-sig',
          activityLevel: 0.1,
          communityScore: 0.1,
        );

      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
        final initial = await trustManager.establishTrust('bounds-agent', context);

        final extremeNegative = TrustInteraction(
          type: InteractionType.trustViolation,
          impactScore: 0.0,
          timestamp: DateTime.now(),
          context: {'extreme': true},
        );

        final updated = await trustManager.updateTrustScore('bounds-agent', extremeNegative);

        expect(updated.trustScore, greaterThanOrEqualTo(0.0));
        expect(updated.trustScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Trusted Agent Discovery', () {
      test('should find trusted agents meeting minimum trust level', () async {
        final trustedAgents = await trustManager.findTrustedAgents(
          TrustLevel.verified,
          maxResults: 10,
        );

        for (final agent in trustedAgents) {
          expect(agent.trustLevel.index, greaterThanOrEqualTo(TrustLevel.verified.index));
        }
      });

      test('should respect maximum results limit', () async {
        const maxResults = 3;
        final trustedAgents = await trustManager.findTrustedAgents(
          TrustLevel.unverified,
          maxResults: maxResults,
        );

        expect(trustedAgents.length, lessThanOrEqualTo(maxResults));
      });
    });

    group('Agent Reputation Verification', () {
      test('should verify reputation for existing agent', () async {
      final context = TrustContext(
          hasUserData: false,
        hasValidatedBehavior: true,
        hasCommunityEndorsement: true,
        hasRecentActivity: true,
          behaviorSignature: 'reputation-test-sig',
        activityLevel: 0.8,
        communityScore: 0.7,
      );
      
        await trustManager.establishTrust('reputation-agent', context);

        final reputation = await trustManager.verifyAgentReputation('reputation-agent');

        expect(reputation.agentId, equals('reputation-agent'));
        expect(reputation.overallScore, greaterThan(0.0));
        expect(reputation.reputationLevel, isNot(equals(ReputationLevel.unknown)));
        expect(reputation.verifiedInteractions, greaterThan(0));
        expect(reputation.trustNetworkSize, greaterThanOrEqualTo(0));
      });

      test('should return unknown reputation for non-existent agent', () async {
        final reputation = await trustManager.verifyAgentReputation('unknown-agent');

        expect(reputation.agentId, equals('unknown-agent'));
        expect(reputation.reputationLevel, equals(ReputationLevel.unknown));
        expect(reputation.verifiedInteractions, equals(0));
        expect(reputation.trustNetworkSize, equals(0));
        expect(reputation.overallScore, equals(0.5)); // Initial trust score
      });
    });

    group('Privacy and Security Validation', () {
      test('should never expose user-identifying information in trust data', () async {
        final context = TrustContext(
          hasUserData: false,
        hasValidatedBehavior: true,
        hasCommunityEndorsement: false,
        hasRecentActivity: true,
          behaviorSignature: 'privacy-test-signature',
        activityLevel: 0.6,
        communityScore: 0.5,
      );
      
        final relationship = await trustManager.establishTrust('privacy-agent', context);

        expect(relationship.agentId, isNot(contains('@')));
        expect(relationship.agentId, isNot(contains('user')));
        
        final factorsString = relationship.anonymousFactors.toString().toLowerCase();
        expect(factorsString, isNot(contains('email')));
        expect(factorsString, isNot(contains('phone')));
        expect(factorsString, isNot(contains('address')));
        expect(factorsString, isNot(contains('name')));
        expect(factorsString, isNot(contains('personal')));
      });
    });
  });

  group('Supporting Classes Validation', () {
    group('TrustContext', () {
      test('should create valid trust context', () {
        final context = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: true,
          hasCommunityEndorsement: false,
          hasRecentActivity: true,
          behaviorSignature: 'test-signature',
          activityLevel: 0.6,
          communityScore: 0.7,
        );

        expect(context.hasUserData, isFalse);
        expect(context.hasValidatedBehavior, isTrue);
        expect(context.behaviorSignature, equals('test-signature'));
        expect(context.activityLevel, equals(0.6));
        expect(context.communityScore, equals(0.7));
      });
    });

    group('Enum Validations', () {
      test('should have all required interaction types', () {
        final expectedTypes = [
          InteractionType.successfulRecommendation,
          InteractionType.helpfulCollaboration,
          InteractionType.accurateInformation,
          InteractionType.misleadingInformation,
          InteractionType.spamBehavior,
          InteractionType.trustViolation,
        ];

        for (final type in expectedTypes) {
          expect(InteractionType.values, contains(type));
        }
      });

      test('should have trust levels in correct progression', () {
        const levels = TrustLevel.values;
        for (int i = 0; i < levels.length - 1; i++) {
          expect(levels[i].index, lessThan(levels[i + 1].index));
        }
      });
    });
  });
}