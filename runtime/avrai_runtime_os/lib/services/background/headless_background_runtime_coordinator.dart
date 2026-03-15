import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_runtime_signal_lane.dart';
import 'package:avrai_runtime_os/services/background/ai2ai_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_platform_wake_bridge.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/background/mesh_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/passive_kernel_signal_intake_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_lifecycle_runtime_lane.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HeadlessBackgroundRuntimeExecutionResult {
  const HeadlessBackgroundRuntimeExecutionResult({
    required this.capabilitySnapshot,
    required this.meshResult,
    required this.ai2aiResult,
    required this.passiveResult,
    required this.segmentRefreshCount,
    required this.bootstrapReady,
  });

  final BackgroundCapabilitySnapshot capabilitySnapshot;
  final MeshBackgroundExecutionResult meshResult;
  final Ai2AiBackgroundExecutionResult ai2aiResult;
  final PassiveKernelSignalIntakeResult passiveResult;
  final int segmentRefreshCount;
  final bool bootstrapReady;
}

class HeadlessBackgroundRuntimeCoordinator {
  HeadlessBackgroundRuntimeCoordinator({
    required HeadlessAvraiOsBootstrapService bootstrapService,
    required MeshBackgroundExecutionLane meshLane,
    required Ai2AiBackgroundExecutionLane ai2aiLane,
    required PassiveKernelSignalIntakeLane passiveLane,
    required MeshSegmentLifecycleRuntimeLane segmentLifecycleLane,
    FeatureFlagService? featureFlagService,
    BackgroundPlatformWakePort? platformWakePort,
    BackgroundWakeExecutionRunRecordStore? runRecordStore,
    AmbientSocialRealityLearningService? ambientSocialLearningService,
    Connectivity? connectivity,
    Ai2AiRendezvousRuntimeSignalLane? foregroundRuntimeSignalLane,
    String privacyMode = 'private_mesh',
    Duration backgroundTaskInterval = const Duration(minutes: 30),
    DateTime Function()? nowUtc,
  })  : _bootstrapService = bootstrapService,
        _meshLane = meshLane,
        _ai2aiLane = ai2aiLane,
        _passiveLane = passiveLane,
        _segmentLifecycleLane = segmentLifecycleLane,
        _featureFlagService = featureFlagService,
        _platformWakePort = platformWakePort,
        _runRecordStore = runRecordStore,
        _ambientSocialLearningService = ambientSocialLearningService,
        _connectivity = connectivity,
        _foregroundRuntimeSignalLane = foregroundRuntimeSignalLane,
        _privacyMode = privacyMode,
        _backgroundTaskInterval = backgroundTaskInterval,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final HeadlessAvraiOsBootstrapService _bootstrapService;
  final MeshBackgroundExecutionLane _meshLane;
  final Ai2AiBackgroundExecutionLane _ai2aiLane;
  final PassiveKernelSignalIntakeLane _passiveLane;
  final MeshSegmentLifecycleRuntimeLane _segmentLifecycleLane;
  final FeatureFlagService? _featureFlagService;
  final BackgroundPlatformWakePort? _platformWakePort;
  final BackgroundWakeExecutionRunRecordStore? _runRecordStore;
  final AmbientSocialRealityLearningService? _ambientSocialLearningService;
  final Connectivity? _connectivity;
  final Ai2AiRendezvousRuntimeSignalLane? _foregroundRuntimeSignalLane;
  final String _privacyMode;
  final Duration _backgroundTaskInterval;
  final DateTime Function() _nowUtc;

  bool _started = false;

  Future<HeadlessBackgroundRuntimeExecutionResult>
      startForegroundRuntimeEnvelope() async {
    await startHeadlessRuntimeEnvelope();
    if (_foregroundRuntimeSignalLane != null) {
      await _foregroundRuntimeSignalLane.start();
    }
    var result = await handleWake(reason: BackgroundWakeReason.bootCompleted);
    final platformWakePort = _platformWakePort;
    if (platformWakePort != null) {
      await platformWakePort.scheduleBackgroundTaskWindow(
        interval: _backgroundTaskInterval,
      );
      await platformWakePort.notifyForegroundReady();
      final pendingWakeInvocations =
          await platformWakePort.consumePendingWakeInvocations();
      for (final payload in pendingWakeInvocations) {
        result = await handleInvocation(payload);
      }
    }
    return result;
  }

  Future<void> startHeadlessRuntimeEnvelope() async {
    if (_started) {
      return;
    }
    await _bootstrapService.tryInitialize();
    await _ai2aiLane.start();
    await _segmentLifecycleLane.start();
    await _passiveLane.start();
    _started = true;
  }

  Future<HeadlessBackgroundRuntimeExecutionResult> handleInvocation(
    BackgroundWakeInvocationPayload payload,
  ) {
    return handleWake(
      reason: payload.reason,
      isWifiAvailable: payload.isWifiAvailable,
      isIdle: payload.isIdle,
      platformSource: payload.platformSource,
    );
  }

  Future<HeadlessBackgroundRuntimeExecutionResult> handleWake({
    required BackgroundWakeReason reason,
    bool? isWifiAvailable,
    bool? isIdle,
    String? platformSource,
  }) async {
    final startedAtUtc = _nowUtc();
    final capabilitySnapshot = await _buildCapabilitySnapshot(
      reason: reason,
      isWifiAvailableOverride: isWifiAvailable,
      isIdleOverride: isIdle,
    );
    final ambientBefore = _ambientSocialLearningService?.snapshot(
      capturedAtUtc: startedAtUtc,
    );
    final bootstrapSnapshot = await _bootstrapService.tryInitialize();

    try {
      final meshResult = await _meshLane.handleWake(
        reason: reason,
        capabilities: capabilitySnapshot,
      );
      final ai2aiResult = await _ai2aiLane.handleWake(
        reason: reason,
        capabilities: capabilitySnapshot,
      );
      final passiveResult = await _passiveLane.handleWake(
        reason: reason,
        capabilities: capabilitySnapshot,
      );

      var segmentRefreshCount = 0;
      if (reason == BackgroundWakeReason.bootCompleted ||
          reason == BackgroundWakeReason.backgroundTaskWindow ||
          reason == BackgroundWakeReason.segmentRefreshWindow) {
        segmentRefreshCount = await _segmentLifecycleLane.runRefreshCycle();
      }

      final result = HeadlessBackgroundRuntimeExecutionResult(
        capabilitySnapshot: capabilitySnapshot,
        meshResult: meshResult,
        ai2aiResult: ai2aiResult,
        passiveResult: passiveResult,
        segmentRefreshCount: segmentRefreshCount,
        bootstrapReady: bootstrapSnapshot != null,
      );
      await _recordWakeRun(
        reason: reason,
        capabilitySnapshot: capabilitySnapshot,
        startedAtUtc: startedAtUtc,
        result: result,
        ambientBefore: ambientBefore,
        platformSource:
            platformSource ?? 'coordinator:${capabilitySnapshot.wakeReason.wireName}',
      );
      return result;
    } catch (error) {
      await _recordWakeFailure(
        reason: reason,
        capabilitySnapshot: capabilitySnapshot,
        startedAtUtc: startedAtUtc,
        bootstrapReady: bootstrapSnapshot != null,
        ambientBefore: ambientBefore,
        failureSummary: error.toString(),
        platformSource:
            platformSource ?? 'coordinator:${capabilitySnapshot.wakeReason.wireName}',
      );
      rethrow;
    }
  }

  Future<BackgroundCapabilitySnapshot> _buildCapabilitySnapshot({
    required BackgroundWakeReason reason,
    bool? isWifiAvailableOverride,
    bool? isIdleOverride,
  }) async {
    final connectivity = _connectivity;
    final connectivityResults = isWifiAvailableOverride != null
        ? <ConnectivityResult>[
            if (isWifiAvailableOverride) ConnectivityResult.wifi,
          ]
        : connectivity == null
            ? const <ConnectivityResult>[]
            : await connectivity.checkConnectivity();
    final reticulumEnabled = await _isFlagEnabled(
      GovernanceFeatureFlags.reticulumMeshTransportControlPlaneV1,
    );
    final trustedAnnounceEnabled = reticulumEnabled &&
        await _isFlagEnabled(
          GovernanceFeatureFlags.trustedMeshAnnounceEnforcementV1,
        );
    return BackgroundCapabilitySnapshot(
      observedAtUtc: _nowUtc(),
      wakeReason: reason,
      privacyMode: _privacyMode,
      isWifiAvailable: connectivityResults.contains(ConnectivityResult.wifi),
      isIdle: isIdleOverride ?? _foregroundRuntimeSignalLane?.isIdle ?? true,
      reticulumTransportControlPlaneEnabled: reticulumEnabled,
      trustedMeshAnnounceEnforcementEnabled: trustedAnnounceEnabled,
    );
  }

  Future<bool> _isFlagEnabled(String flag) async {
    final featureFlagService = _featureFlagService;
    if (featureFlagService == null) {
      return false;
    }
    return featureFlagService.isEnabled(flag, defaultValue: false);
  }

  Future<void> _recordWakeRun({
    required BackgroundWakeReason reason,
    required BackgroundCapabilitySnapshot capabilitySnapshot,
    required DateTime startedAtUtc,
    required HeadlessBackgroundRuntimeExecutionResult result,
    required AmbientSocialLearningDiagnosticsSnapshot? ambientBefore,
    required String platformSource,
  }) async {
    final store = _runRecordStore;
    if (store == null) {
      return;
    }
    final ambientAfter = _ambientSocialLearningService?.snapshot(
      capturedAtUtc: _nowUtc(),
    );
    await store.record(
      BackgroundWakeExecutionRunRecord(
        reason: reason,
        platformSource: platformSource,
        wakeTimestampUtc: capabilitySnapshot.observedAtUtc,
        startedAtUtc: startedAtUtc,
        completedAtUtc: _nowUtc(),
        bootstrapSuccess: result.bootstrapReady,
        meshDueReplayCount: result.meshResult.dueReplayCount,
        meshRecoveredReplayCount:
            result.meshResult.recoveredReachabilityReplayCount,
        meshDiscoveredPeerCount: result.meshResult.discoveredPeerCount,
        ai2aiReleasedCount: result.ai2aiResult.releasedCount,
        ai2aiBlockedCount: result.ai2aiResult.blockedCount,
        ai2aiTrustedRouteUnavailableBlockCount:
            result.ai2aiResult.trustedRouteUnavailableBlockCount,
        passiveIngestedDwellEventCount: result.passiveResult.ingestedDwellEventCount,
        ambientCandidateObservationDeltaCount:
            (ambientAfter?.candidateCoPresenceObservationCount ?? 0) -
                (ambientBefore?.candidateCoPresenceObservationCount ?? 0),
        ambientConfirmedPromotionDeltaCount:
            (ambientAfter?.confirmedInteractionPromotionCount ?? 0) -
                (ambientBefore?.confirmedInteractionPromotionCount ?? 0),
        segmentRefreshCount: result.segmentRefreshCount,
      ),
    );
  }

  Future<void> _recordWakeFailure({
    required BackgroundWakeReason reason,
    required BackgroundCapabilitySnapshot capabilitySnapshot,
    required DateTime startedAtUtc,
    required bool bootstrapReady,
    required AmbientSocialLearningDiagnosticsSnapshot? ambientBefore,
    required String failureSummary,
    required String platformSource,
  }) async {
    final store = _runRecordStore;
    if (store == null) {
      return;
    }
    final ambientAfter = _ambientSocialLearningService?.snapshot(
      capturedAtUtc: _nowUtc(),
    );
    await store.record(
      BackgroundWakeExecutionRunRecord(
        reason: reason,
        platformSource: platformSource,
        wakeTimestampUtc: capabilitySnapshot.observedAtUtc,
        startedAtUtc: startedAtUtc,
        completedAtUtc: _nowUtc(),
        bootstrapSuccess: bootstrapReady,
        meshDueReplayCount: 0,
        meshRecoveredReplayCount: 0,
        meshDiscoveredPeerCount: 0,
        ai2aiReleasedCount: 0,
        ai2aiBlockedCount: 0,
        ai2aiTrustedRouteUnavailableBlockCount: 0,
        passiveIngestedDwellEventCount: 0,
        ambientCandidateObservationDeltaCount:
            (ambientAfter?.candidateCoPresenceObservationCount ?? 0) -
                (ambientBefore?.candidateCoPresenceObservationCount ?? 0),
        ambientConfirmedPromotionDeltaCount:
            (ambientAfter?.confirmedInteractionPromotionCount ?? 0) -
                (ambientBefore?.confirmedInteractionPromotionCount ?? 0),
        segmentRefreshCount: 0,
        failureSummary: failureSummary,
      ),
    );
  }
}
