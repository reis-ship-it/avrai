/// SPOTS VibeCompatibilityService Truthfulness Tests
/// Date: January 2, 2026
/// Purpose: Regression coverage for "truthful vibe score" behavior:
/// - When knot runtime is unavailable, we degrade gracefully to quantum-only
/// - The returned VibeScore reflects that truthfully (knot components = 0, combined = quantum)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';

final class _MockPersonalityLearning extends Mock implements PersonalityLearning {}
final class _MockPersonalityKnotService extends Mock
    implements PersonalityKnotService {}
final class _MockEntityKnotService extends Mock implements EntityKnotService {}

final class _FakePersonalityProfile extends Fake implements PersonalityProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePersonalityProfile());
    registerFallbackValue(EntityType.person);
  });

  test(
      'degrades gracefully to quantum-only when knot generation/compatibility is unavailable',
      () async {
    final personalityLearning = _MockPersonalityLearning();
    final personalityKnotService = _MockPersonalityKnotService();
    final entityKnotService = _MockEntityKnotService();

    final userProfile = PersonalityProfile.initial('user_1');

    when(() => personalityLearning.getCurrentPersonality('user_1'))
        .thenAnswer((_) async => userProfile);
    when(() => personalityLearning.initializePersonality(any()))
        .thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as String;
      return PersonalityProfile.initial(id);
    });

    // Simulate "knot runtime not available" (e.g., FRB/Rust not wired in tests).
    when(() => personalityKnotService.generateKnot(any()))
        .thenThrow(Exception('knot runtime unavailable'));
    when(
      () => entityKnotService.generateKnotForEntity(
        entityType: any(named: 'entityType'),
        entity: any(named: 'entity'),
      ),
    ).thenThrow(Exception('knot runtime unavailable'));

    final service = QuantumKnotVibeCompatibilityService(
      personalityLearning: personalityLearning,
      personalityKnotService: personalityKnotService,
      entityKnotService: entityKnotService,
    );

    final business = BusinessAccount(
      id: 'biz_1',
      name: 'Test Business',
      email: 'biz@example.com',
      businessType: 'Cafe',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      createdBy: 'user_1',
    );

    final score = await service.calculateUserBusinessVibe(
      userId: 'user_1',
      business: business,
    );

    // Truthfulness contract: if knot data is missing, we do not pretend.
    expect(score.knotTopological, equals(0.0));
    expect(score.knotWeave, equals(0.0));
    expect(score.combined, equals(score.quantum));
    expect(score.breakdown['mode'], equals(1.0));

    // Safety: always clamped to [0, 1].
    expect(score.combined, inInclusiveRange(0.0, 1.0));
    expect(score.quantum, inInclusiveRange(0.0, 1.0));
  });
}

