import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/misc/world_plane_view_state.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:get_it/get_it.dart';

class WorldPlaneOrchestrationAdapter {
  static const String _logName = 'WorldPlaneOrchestrationAdapter';

  final KnotWorldsheetService? _worldsheetService;
  final KnotStorageService? _knotStorageService;
  final PersonalityKnotService? _personalityKnotService;
  final PersonalityLearning? _personalityLearning;

  WorldPlaneOrchestrationAdapter({
    KnotWorldsheetService? worldsheetService,
    KnotStorageService? knotStorageService,
    PersonalityKnotService? personalityKnotService,
    PersonalityLearning? personalityLearning,
  })  : _worldsheetService =
            worldsheetService ?? _tryGet<KnotWorldsheetService>(),
        _knotStorageService =
            knotStorageService ?? _tryGet<KnotStorageService>(),
        _personalityKnotService =
            personalityKnotService ?? _tryGet<PersonalityKnotService>(),
        _personalityLearning =
            personalityLearning ?? _tryGet<PersonalityLearning>();

  static T? _tryGet<T extends Object>() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<T>()) return null;
    return sl<T>();
  }

  Future<WorldPlaneViewState> loadForUser({
    required String userId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_worldsheetService == null ||
        _knotStorageService == null ||
        _personalityKnotService == null ||
        _personalityLearning == null) {
      return WorldPlaneViewState.unavailable(
        reason: 'World-plane services are not ready on this device yet.',
      );
    }

    try {
      final profileFuture = _personalityLearning.getCurrentPersonality(userId);
      final profile = await profileFuture.timeout(timeout);
      if (profile == null) {
        return WorldPlaneViewState.unavailable(
          reason:
              'No personality profile available yet. Keep exploring to unlock world planes.',
        );
      }

      var knot = await _knotStorageService.loadKnot(profile.agentId);
      knot ??= await _personalityKnotService.generateKnot(profile);

      await _knotStorageService.saveKnot(profile.agentId, knot);

      final userIds = <String>{userId, profile.agentId}.toList(growable: false);
      final worldsheet = await _worldsheetService
          .createWorldsheet(
            groupId: 'world_plane_$userId',
            userIds: userIds,
            startTime: DateTime.now().subtract(const Duration(days: 7)),
            endTime: DateTime.now(),
          )
          .timeout(timeout);

      if (worldsheet == null) {
        return WorldPlaneViewState.unavailable(
          reason:
              'World plane is not generated yet. We need a little more evolution data.',
        );
      }

      final sortedSnapshots = List<FabricSnapshot>.from(worldsheet.snapshots)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final rangeStart = sortedSnapshots.isEmpty
          ? worldsheet.createdAt
          : sortedSnapshots.first.timestamp;
      final rangeEnd = sortedSnapshots.isEmpty
          ? worldsheet.lastUpdated
          : sortedSnapshots.last.timestamp;

      final confidence = _computeConfidence(
          worldsheet.snapshots.length, worldsheet.userStrings.length);
      final isStale = DateTime.now().difference(worldsheet.lastUpdated) >
          const Duration(hours: 12);

      return WorldPlaneViewState(
        isAvailable: true,
        worldsheet: worldsheet,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        confidence: confidence,
        isStale: isStale,
        fallbackReason: null,
        generatedAt: DateTime.now(),
      );
    } on TimeoutException {
      return WorldPlaneViewState.unavailable(
        reason: 'World plane timed out. Falling back to ambient portal mode.',
      );
    } catch (e, st) {
      developer.log(
        'Failed to load world plane for userId=$userId: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return WorldPlaneViewState.unavailable(
        reason:
            'World plane failed to load. You can keep using the app normally.',
      );
    }
  }

  double _computeConfidence(int snapshotCount, int strandCount) {
    final snapshotSignal = (snapshotCount / 24).clamp(0.0, 1.0);
    final strandSignal = (strandCount / 2).clamp(0.0, 1.0);
    return ((snapshotSignal * 0.7) + (strandSignal * 0.3)).clamp(0.0, 1.0);
  }
}
