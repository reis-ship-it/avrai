// Braided Knot Storage Tests
// 
// Tests for braided knot storage methods in KnotStorageService
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('Braided Knot Storage Tests', () {
    late KnotStorageService service;
    late MockStorageService mockStorageService;
    late BraidedKnot braidedKnot;

    setUp(() {
      mockStorageService = MockStorageService();
      service = KnotStorageService(storageService: mockStorageService);

      final knotA = PersonalityKnot(
        agentId: 'agent-a',
        invariants: KnotInvariants(
          jonesPolynomial: [1.0, 2.0],
          alexanderPolynomial: [1.0],
          crossingNumber: 3,
          writhe: 1,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
        ),
        braidData: [8.0, 0.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final knotB = PersonalityKnot(
        agentId: 'agent-b',
        invariants: KnotInvariants(
          jonesPolynomial: [2.0, 3.0],
          alexanderPolynomial: [2.0],
          crossingNumber: 4,
          writhe: 2,
          signature: 0,
          bridgeNumber: 2,
          braidIndex: 1,
          determinant: 2,
        ),
        braidData: [8.0, 1.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      braidedKnot = BraidedKnot(
        id: 'braid-1',
        knotA: knotA,
        knotB: knotB,
        braidSequence: [16.0, 0.0, 1.0, 1.0, 1.0],
        complexity: 0.5,
        stability: 0.7,
        harmonyScore: 0.8,
        relationshipType: RelationshipType.friendship,
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('should save braided knot for connection', () async {
      when(() => mockStorageService.setObject(any(), any()))
          .thenAnswer((_) async => true);

      await service.saveBraidedKnot(
        connectionId: 'connection-1',
        braidedKnot: braidedKnot,
      );

      verify(() => mockStorageService.setObject(
            'braided_knot:connection-1',
            any(),
          )).called(1);
    });

    test('should get braided knot for connection', () async {
      final json = braidedKnot.toJson();
      when(() => mockStorageService.getObject<Map<String, dynamic>>(any()))
          .thenReturn(json);

      final result = await service.getBraidedKnot('connection-1');

      expect(result, isNotNull);
      expect(result?.id, equals(braidedKnot.id));
      expect(result?.complexity, equals(braidedKnot.complexity));
      expect(result?.stability, equals(braidedKnot.stability));
      expect(result?.harmonyScore, equals(braidedKnot.harmonyScore));
      expect(result?.relationshipType, equals(braidedKnot.relationshipType));

      verify(() => mockStorageService.getObject<Map<String, dynamic>>(
            'braided_knot:connection-1',
          )).called(1);
    });

    test('should return null when braided knot not found', () async {
      when(() => mockStorageService.getObject<Map<String, dynamic>>(any()))
          .thenReturn(null);

      final result = await service.getBraidedKnot('connection-nonexistent');

      expect(result, isNull);
    });

    test('should delete braided knot for connection', () async {
      when(() => mockStorageService.remove(any())).thenAnswer((_) async => true);

      await service.deleteBraidedKnot('connection-1');

      verify(() => mockStorageService.remove('braided_knot:connection-1'))
          .called(1);
    });

    test('should get empty list for braided knots when not implemented', () async {
      // getBraidedKnotsForAgent currently returns empty list
      // (requires StorageService to support key listing)
      final result = await service.getBraidedKnotsForAgent('agent-1');

      expect(result, isEmpty);
    });
  });
}
