// Knot Community Model Tests
// 
// Tests for KnotCommunity model
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/knot/knot_community.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai_core/models/personality_knot.dart';

void main() {
  group('KnotCommunity Tests', () {
    late Community mockCommunity;
    late PersonalityKnot mockAverageKnot;

    setUp(() {
      mockCommunity = Community(
        id: 'community-1',
        name: 'Test Community',
        description: 'A test community',
        category: 'Technology',
        originatingEventId: 'event-1',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'founder-1',
        originalLocality: 'Test Locality',
        memberCount: 10,
        memberIds: const ['user1', 'user2', 'user3'],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      mockAverageKnot = PersonalityKnot(
        agentId: 'avg-agent',
        invariants: KnotInvariants(
          jonesPolynomial: [1.0, 2.0],
          alexanderPolynomial: [1.0],
          crossingNumber: 5,
          writhe: 2,
          signature: 0,
          bridgeNumber: 2,
          braidIndex: 2,
          determinant: 1,
        ),
        physics: KnotPhysics(energy: 0.5, stability: 0.7, length: 0.3),
        braidData: [8.0, 0.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );
    });

    test('should create KnotCommunity with all required fields', () {
      final knotCommunity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        averageKnot: mockAverageKnot,
        memberCount: 10,
        membersWithKnots: 8,
      );

      expect(knotCommunity.community, equals(mockCommunity));
      expect(knotCommunity.knotSimilarity, equals(0.85));
      expect(knotCommunity.averageKnot, equals(mockAverageKnot));
      expect(knotCommunity.memberCount, equals(10));
      expect(knotCommunity.membersWithKnots, equals(8));
    });

    test('should create KnotCommunity without averageKnot', () {
      final knotCommunity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.75,
        memberCount: 10,
        membersWithKnots: 5,
      );

      expect(knotCommunity.community, equals(mockCommunity));
      expect(knotCommunity.knotSimilarity, equals(0.75));
      expect(knotCommunity.averageKnot, isNull);
      expect(knotCommunity.memberCount, equals(10));
      expect(knotCommunity.membersWithKnots, equals(5));
    });

    test('should create from Community using fromCommunity factory', () {
      final knotCommunity = KnotCommunity.fromCommunity(
        community: mockCommunity,
        knotSimilarity: 0.9,
        averageKnot: mockAverageKnot,
        membersWithKnots: 7,
      );

      expect(knotCommunity.community, equals(mockCommunity));
      expect(knotCommunity.knotSimilarity, equals(0.9));
      expect(knotCommunity.averageKnot, equals(mockAverageKnot));
      expect(knotCommunity.memberCount, equals(mockCommunity.memberCount));
      expect(knotCommunity.membersWithKnots, equals(7));
    });

    test('should identify knot tribe when similarity is above threshold', () {
      final knotCommunity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      expect(knotCommunity.isKnotTribe(threshold: 0.7), isTrue);
      expect(knotCommunity.isKnotTribe(threshold: 0.9), isFalse);
    });

    test('should identify knot tribe with default threshold', () {
      final highSimilarity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.75,
        memberCount: 10,
      );

      final lowSimilarity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.6,
        memberCount: 10,
      );

      expect(highSimilarity.isKnotTribe(), isTrue);
      expect(lowSimilarity.isKnotTribe(), isFalse);
    });

    test('should have correct string representation', () {
      final knotCommunity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      final str = knotCommunity.toString();
      expect(str, contains('Test Community'));
      expect(str, contains('0.85'));
      expect(str, contains('10'));
    });

    test('should support equality comparison', () {
      final knotCommunity1 = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      final knotCommunity2 = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      final knotCommunity3 = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.75,
        memberCount: 10,
      );

      expect(knotCommunity1, equals(knotCommunity2));
      expect(knotCommunity1, isNot(equals(knotCommunity3)));
    });

    test('should have consistent hashCode for equal objects', () {
      final knotCommunity1 = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      final knotCommunity2 = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.85,
        memberCount: 10,
      );

      expect(knotCommunity1.hashCode, equals(knotCommunity2.hashCode));
    });

    test('should handle edge case similarity values', () {
      final zeroSimilarity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 0.0,
        memberCount: 10,
      );

      final maxSimilarity = KnotCommunity(
        community: mockCommunity,
        knotSimilarity: 1.0,
        memberCount: 10,
      );

      expect(zeroSimilarity.isKnotTribe(threshold: 0.0), isTrue);
      expect(zeroSimilarity.isKnotTribe(threshold: 0.1), isFalse);
      expect(maxSimilarity.isKnotTribe(threshold: 1.0), isTrue);
    });

    test('should handle empty community', () {
      final emptyCommunity = Community(
        id: 'empty',
        name: 'Empty Community',
        category: 'Test',
        originatingEventId: 'event-empty',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'founder-empty',
        originalLocality: 'Empty Locality',
        memberCount: 0,
        memberIds: const [],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final knotCommunity = KnotCommunity(
        community: emptyCommunity,
        knotSimilarity: 0.5,
        memberCount: 0,
        membersWithKnots: 0,
      );

      expect(knotCommunity.memberCount, equals(0));
      expect(knotCommunity.membersWithKnots, equals(0));
    });
  });
}
