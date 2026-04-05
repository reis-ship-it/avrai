import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/base/controller_result.dart';
import 'package:avrai_runtime_os/controllers/base/workflow_controller.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/quantum/matching_input.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';

class _DeterministicQuantumMatchingController
    implements WorkflowController<MatchingInput, QuantumMatchingResult> {
  final double compatibility;

  _DeterministicQuantumMatchingController(this.compatibility);

  @override
  Future<QuantumMatchingResult> execute(MatchingInput input) async {
    final tAtomic = AtomicTimestamp.now(precision: TimePrecision.millisecond);
    final result = MatchingResult.success(
      compatibility: compatibility,
      quantumCompatibility: compatibility,
      locationCompatibility: 0.5,
      timingCompatibility: 0.5,
      timestamp: tAtomic,
      entities: <QuantumEntityState>[
        QuantumEntityState(
          entityId: input.user.id,
          entityType: QuantumEntityType.user,
          personalityState: const {},
          quantumVibeAnalysis: const {},
          entityCharacteristics: const {'type': 'user'},
          tAtomic: tAtomic,
        ),
      ],
    );

    return QuantumMatchingResult.success(matchingResult: result);
  }

  @override
  Future<void> rollback(QuantumMatchingResult result) async {}

  @override
  ValidationResult validate(MatchingInput input) => ValidationResult.valid();
}

void main() {
  group('EventRecommendationService Phase 19 integration', () {
    test('knot compatibility blends in quantum entanglement score when wired',
        () async {
      final controller = _DeterministicQuantumMatchingController(0.9);
      final service = EventRecommendationService(
        // Leave knot/vibe services null so base path is neutral.
        quantumMatchingController: controller,
      );

      final user = UnifiedUser(
        id: 'user_1',
        email: 'u1@example.com',
        displayName: 'User One',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        primaryRole: UserRole.follower,
      );

      final host = UnifiedUser(
        id: 'host_1',
        email: 'h1@example.com',
        displayName: 'Host One',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        primaryRole: UserRole.curator,
      );

      final event = ExpertiseEvent(
        id: 'event_1',
        host: host,
        title: 'Test Event',
        description: 'Test',
        category: 'coffee',
        eventType: ExpertiseEventType.workshop,
        startTime: DateTime.fromMillisecondsSinceEpoch(0),
        endTime: DateTime.fromMillisecondsSinceEpoch(0),
        location: null,
        latitude: null,
        longitude: null,
        cityCode: null,
        localityCode: null,
        spots: const [],
        maxAttendees: 10,
        price: null,
        isPublic: true,
        status: EventStatus.upcoming,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        attendeeIds: const [],
      );

      final score = await service.calculateKnotCompatibilityForRecommendation(
        event: event,
        user: user,
      );

      // Base is neutral 0.5; entanglement is 0.9; blend is 0.7*0.5 + 0.3*0.9 = 0.62
      expect(score, closeTo(0.62, 0.0001));
    });
  });
}
