import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/pending_connection.dart';
import 'package:avrai/core/ai2ai/connection_summary.dart';
import 'package:avrai/core/ai2ai/ai2ai_connection_exception.dart';
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/ai2ai/discovery/discovered_node_registry.dart';
import 'package:avrai/core/ai2ai/discovery/discovery_postprocess_lane.dart';
import 'package:avrai/core/ai2ai/discovery/ai2ai_discovery_execution_lane.dart';
import 'package:avrai/core/ai2ai/discovery/debug_hot_path_simulation_lane.dart';
import 'package:avrai/core/ai2ai/routing/connection_routing_policy.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_broadcast_flags_lane.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_scan_window_orchestration_lane.dart';
import 'package:avrai/core/ai2ai/routing/mesh_forwarding_context.dart';
import 'package:avrai/core/ai2ai/routing/mesh_outbound_forwarding_lane.dart';
import 'package:avrai/core/ai2ai/chat/incoming_business_expert_chat_lane.dart';
import 'package:avrai/core/ai2ai/chat/incoming_business_business_chat_lane.dart';
import 'package:avrai/core/ai2ai/chat/incoming_user_chat_processing_lane.dart';
import 'package:avrai/core/ai2ai/locality/continuous_learning_mirror.dart';
import 'package:avrai/core/ai2ai/locality/learning_insight_application_lane.dart';
import 'package:avrai/core/ai2ai/locality/incoming_learning_insight_processing_lane.dart';
import 'package:avrai/core/ai2ai/locality/incoming_mesh_signal_handlers_lane.dart';
import 'package:avrai/core/ai2ai/locality/passive_ai2ai_learning_lane.dart';
import 'package:avrai/core/ai2ai/locality/learning_insight_peer_dispatch_lane.dart';
import 'package:avrai/core/ai2ai/trust/payload_anonymization_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_lifecycle_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_startup_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_shutdown_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_init_ledger_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_init_flow_lane.dart';
import 'package:avrai/core/ai2ai/resilience/personality_advertising_start_lane.dart';
import 'package:avrai/core/ai2ai/resilience/ble_discovery_start_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_lifecycle_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_renewal_lane.dart';
import 'package:avrai/core/ai2ai/resilience/inactive_session_cleanup_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_expiry_lane.dart';
import 'package:avrai/core/ai2ai/resilience/ble_node_identity.dart';
import 'package:avrai/core/ai2ai/resilience/learning_insight_seen_ids_persistence_lane.dart';
import 'package:avrai/core/ai2ai/resilience/ble_seen_hashes_persistence_lane.dart';
import 'package:avrai/core/ai2ai/resilience/prekey_bundle_rotation_lane.dart';
import 'package:avrai/core/ai2ai/resilience/quality_change_key_rotation_lane.dart';
import 'package:avrai/core/ai2ai/resilience/prekey_session_prime_lane.dart';
import 'package:avrai/core/ai2ai/resilience/prekey_mesh_forward_bridge_lane.dart';
import 'package:avrai/core/ai2ai/resilience/ble_inbox_processing_lane.dart';
import 'package:avrai/core/ai2ai/resilience/event_mode_buffered_learning_insight.dart';
import 'package:avrai/core/ai2ai/resilience/realtime_listener_callbacks_lane.dart';
import 'package:avrai/core/ai2ai/resilience/federated_cloud_sync_start_lane.dart';
import 'package:avrai/core/ai2ai/resilience/federated_cloud_queue_lane.dart';
import 'package:avrai/core/ai2ai/resilience/federated_cloud_sync_lane.dart';
import 'package:avrai/core/ai2ai/resilience/event_mode_learning_buffer_lane.dart';
import 'package:avrai/core/ai2ai/resilience/prekey_payload_publish_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_attempt_orchestration_lane.dart';
import 'package:avrai/core/ai2ai/resilience/personality_advertising_update_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_completion_lane.dart';
import 'package:avrai/core/ai2ai/resilience/active_connection_management_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_shutdown_cleanup_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_path_metrics_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/ai_pleasure_score_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_queue_worker_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_device_processing_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_discovery_enqueue_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_metrics_emit_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/ai2ai/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/user/anonymous_user.dart';
import 'package:avrai/core/services/user/user_anonymization_service.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class VibeConnectionOrchestrator {
  static const String _logName = 'VibeConnectionOrchestrator';
  static const bool _allowBleSideEffectsInTests = bool.fromEnvironment(
    'SPOTS_ALLOW_BLE_SIDE_EFFECTS_IN_TESTS',
    defaultValue: false,
  );
  static const bool _allowBleSideEffectsOnIos = bool.fromEnvironment(
    'SPOTS_ALLOW_IOS_BLE_SIDE_EFFECTS',
    defaultValue: false,
  );

  bool get _isTestBinding {
    // Avoid importing flutter_test into production code; detect by binding type name.
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return bindingType.contains('TestWidgetsFlutterBinding') ||
          bindingType.contains('AutomatedTestWidgetsFlutterBinding') ||
          bindingType.contains('IntegrationTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  bool get _allowBleSideEffects {
    // BLE side-effects (MethodChannels, Timer.periodic loops, BLE connects) can
    // make tests flaky/hang. Default: OFF in tests unless explicitly enabled.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !_allowBleSideEffectsOnIos) {
      // iOS simulator (and many dev runs) cannot safely support BLE peripheral
      // advertising. The CoreBluetooth stack can hard-crash if restoration is
      // configured without the right delegate hooks. Default: disable BLE
      // side-effects on iOS unless explicitly enabled.
      return false;
    }
    return !_isTestBinding || _allowBleSideEffectsInTests;
  }

  final UserVibeAnalyzer _vibeAnalyzer;
  final Connectivity _connectivity;
  AI2AIBroadcastService? _realtimeService;
  final DiscoveryManager _discoveryManager;
  final ConnectionManager _connectionManager;
  final RealtimeCoordinator? _realtimeCoordinator;
  final DeviceDiscoveryService? _deviceDiscovery;
  final AI2AIProtocol? _protocol;
  final PersonalityAdvertisingService? _advertisingService;
  final UserAnonymizationService? _anonymizationService;
  final SignalKeyManager? _signalKeyManager;
  final SharedPreferencesCompat _prefs;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'AI2AI', minimumLevel: LogLevel.debug);

  // Phase 2: Knot Weaving Integration
  final KnotWeavingService? _knotWeavingService;
  final KnotStorageService? _knotStorageService;

  // Connection state management
  final Map<String, ConnectionMetrics> _activeConnections = {};
  final Map<String, DateTime> _connectionCooldowns = {};
  final List<PendingConnection> _pendingConnections = [];

  // Connection discovery and matching
  final Map<String, UserVibe> _nearbyVibes = {};
  final Map<String, AIPersonalityNode> _discoveredNodes = {};

  // Connection orchestration state
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  Timer? _discoveryTimer;
  Timer? _connectionMaintenanceTimer;
  Timer? _bleInboxPoller;
  BatteryAdaptiveBleScheduler? _batteryScheduler;
  AdaptiveMeshNetworkingService? _adaptiveMeshService;

  // Quality-based key rotation tracking (AI2AI-specific)
  final Map<String, double> _previousQualityScores = {};

  static const double _qualityChangeThreshold = 0.3; // 30% quality change

  Timer? _federatedCloudSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _federatedCloudConnectivitySub;
  int _lastFederatedCloudSyncAttemptMs = 0;

  // Bloom filters for loop prevention (BitChat-inspired, AI2AI-enhanced)
  // Per-scope Bloom filters (complements AdaptiveMeshNetworkingService)
  final Map<String, OptimizedBloomFilter> _bloomFilters = {};

  // Stable node id used for offline BLE addressing + Signal session keys.
  // Rotates periodically (privacy), stable within a window (correctness).
  late String _localBleNodeId;

  // Map discovered deviceId -> peer node id (from BLE stream-1 prekey payload).
  final Map<String, String> _peerNodeIdByDeviceId = {};

  // Replay protection (best-effort): sha256(packet) -> expiresAtMs
  final Map<String, int> _seenBleMessageHashes = {};
  int _lastSeenHashesPersistMs = 0;

  // AI2AI learning throttling to avoid rapid drift from nearby noise.
  final Map<String, DateTime> _lastAi2AiLearningAtByPeerId = {};

  // ========================================================================
  // Event Mode (broadcast-first) state
  // ========================================================================
  static const String _prefsKeyEventModeEnabled = 'event_mode_enabled';
  static const int _eventEpochMs = 5 * 60 * 1000;
  static const int _eventCheckInWindowMs = 30 * 1000;
  static const int _eventInitiatorEligibilityPct = 20;
  static const int _eventMaxDeepSyncPerEvent = 8;
  static const int _eventPerNodeDeepSyncCooldownMs = 60 * 60 * 1000; // 60 min

  final RoomCoherenceEngine _roomCoherenceEngine = RoomCoherenceEngine();
  int _eventModeLastEpochAttempted = -1;
  bool _eventModeCheckInRunning = false;
  int _eventModeDeepSyncCount = 0;
  final Map<String, int> _eventModeLastDeepSyncAtMsByNodeTag = <String, int>{};
  final Map<String, int> _eventModeFamiliarityByNodeTag = <String, int>{};
  final List<EventModeBufferedLearningInsight> _eventModeLearningBuffer =
      <EventModeBufferedLearningInsight>[];
  bool _lastAdvertisedEventModeEnabled = false;
  bool _lastAdvertisedConnectOk = false;
  bool _lastAdvertisedBrownout = false;

  late String _localNodeTagKey;

  // Track current authenticated user for background learning application.
  String? _currentUserId;
  PersonalityProfile? _currentPersonality;

  // ========================================================================
  // Walk-by hot path (continuous scan)
  // ========================================================================
  static const int _hotRssiThresholdDbm = -75; // ~3m-ish in typical indoor BLE
  static const Duration _hotDeviceCooldown = Duration(seconds: 20);
  static const Duration _hotScanWindow = Duration(seconds: 4);
  static const Duration _hotDeviceTimeout = Duration(seconds: 30);

  final List<DiscoveredDevice> _hotQueue = <DiscoveredDevice>[];
  final Set<String> _hotQueuedDeviceIds = <String>{};
  bool _hotWorkerRunning = false;
  final Map<String, int> _lastHotProcessedAtMsByDeviceId = <String, int>{};
  final Map<String, int> _hotEnqueuedAtMsByDeviceId = <String, int>{};

  // Hot-path latency metrics (lightweight, in-memory ring buffers).
  static const int _hotMetricsWindowSize = 120;
  static const Duration _hotMetricsLogInterval = Duration(seconds: 30);
  final HotLatencyWindow _hotQueueWaitMs =
      HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final HotLatencyWindow _hotTotalMs =
      HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final HotLatencyWindow _hotSessionOpenMs =
      HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final HotLatencyWindow _hotVibeReadMs =
      HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final HotLatencyWindow _hotCompatMs =
      HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  int _lastHotMetricsLogAtMs = 0;

  // ------------------------------------------------------------------------
  // Testing hooks (no real BLE required)
  // ------------------------------------------------------------------------

  @visibleForTesting
  List<AIPersonalityNode> debugDiscoveredNodesSnapshot() {
    return _discoveredNodes.values.toList();
  }

  @visibleForTesting
  Future<void> debugSimulateWalkByHotPath({
    required String userId,
    required PersonalityProfile personality,
    required List<DiscoveredDevice> devices,
  }) async {
    _currentUserId = userId;
    _currentPersonality = personality;
    await DebugHotPathSimulationLane.run(
      userId: userId,
      personality: personality,
      devices: devices,
      prefs: _prefs,
      vibeAnalyzer: _vibeAnalyzer,
      hotRssiThresholdDbm: _hotRssiThresholdDbm,
      isConnectionWorthy: _isConnectionWorthy,
      updateDiscoveredNodes: _updateDiscoveredNodes,
    );
  }

  // Dedupe learning insights: insightId -> expiresAtMs
  final Map<String, int> _seenLearningInsightIds = {};
  int _lastSeenInsightsPersistMs = 0;

  static const _prefsKeyBleNodeId = 'ble_node_id_v1';
  static const _prefsKeyBleNodeIdExpiresAtMs = 'ble_node_id_expires_at_ms_v1';
  static const _prefsKeySeenBleHashes = 'ble_seen_hashes_v1';
  static const _prefsKeyAi2AiLearningEnabled = 'ai2ai_learning_enabled';
  static const _prefsKeySeenLearningInsightIds =
      'ai2ai_seen_learning_insights_v1';
  static const _prefsKeyFederatedLearningParticipation =
      'federated_learning_participation';
  static const _prefsKeyFederatedCloudQueue = 'ai2ai_federated_cloud_queue_v1';

  // Realtime event streams (managed by RealtimeCoordinator)
  // Note: Subscriptions are created and managed by _realtimeCoordinator.setup()
  // These fields are reserved for future direct stream access if needed
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _personalityDiscoverySubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _vibeLearningSubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _anonymousCommunicationSubscription;

  VibeConnectionOrchestrator({
    required UserVibeAnalyzer vibeAnalyzer,
    required Connectivity connectivity,
    AI2AIBroadcastService? realtimeService,
    DeviceDiscoveryService? deviceDiscovery,
    AI2AIProtocol? protocol,
    PersonalityAdvertisingService? advertisingService,
    UserAnonymizationService? anonymizationService,
    SignalKeyManager? signalKeyManager,
    required SharedPreferencesCompat prefs,
    PersonalityLearning? personalityLearning, // NEW: For offline AI2AI learning
    // Phase 2: Knot Weaving Integration
    KnotWeavingService? knotWeavingService,
    KnotStorageService? knotStorageService,
  })  : _vibeAnalyzer = vibeAnalyzer,
        _connectivity = connectivity,
        _realtimeService = realtimeService,
        _deviceDiscovery = deviceDiscovery,
        _protocol = protocol,
        _advertisingService = advertisingService,
        _anonymizationService = anonymizationService,
        _signalKeyManager = signalKeyManager,
        _prefs = prefs,
        _knotWeavingService = knotWeavingService,
        _knotStorageService = knotStorageService,
        _discoveryManager = DiscoveryManager(
            connectivity: connectivity, vibeAnalyzer: vibeAnalyzer),
        _connectionManager = ConnectionManager(
          vibeAnalyzer: vibeAnalyzer,
          personalityLearning:
              personalityLearning, // NEW: Pass to ConnectionManager
          ai2aiProtocol: protocol, // NEW: Pass to ConnectionManager
        ),
        _realtimeCoordinator = realtimeService != null
            ? RealtimeCoordinator(realtimeService)
            : null;

  void setRealtimeService(AI2AIBroadcastService service) {
    _realtimeService = service;
  }

  Future<void> updatePersonalityAdvertising(
    String userId,
    PersonalityProfile updatedPersonality,
  ) async {
    await PersonalityAdvertisingUpdateLane.update(
      userId: userId,
      updatedPersonality: updatedPersonality,
      advertisingService: _advertisingService,
      prefs: _prefs,
      vibeAnalyzer: _vibeAnalyzer,
      localBleNodeId: () => _localBleNodeId,
      eventModeEnabled: _isEventModeEnabled(),
      lastAdvertisedConnectOk: _lastAdvertisedConnectOk,
      lastAdvertisedBrownout: _lastAdvertisedBrownout,
      setCurrentPersonality: (profile) {
        _currentPersonality = profile;
      },
      logger: _logger,
      logName: _logName,
    );
  }

  void setupAutomaticAdvertisingUpdates() {
    // This will be called from injection container after PersonalityLearning is created
    // The callback will be set up there to avoid circular dependencies
  }

  Future<void> initializeOrchestration(
      String userId, PersonalityProfile personality) async {
    try {
      await OrchestrationInitFlowLane.run(
        isInitialized: _isInitialized,
        userId: userId,
        personality: personality,
        readDiscoveryEnabled: () =>
            _prefs.getBool('discovery_enabled') ?? false,
        onAlreadyInitialized: () {
          _logger.debug(
              'Orchestration already initialized; skipping reinitialization',
              tag: _logName);
        },
        onDiscoveryDisabled: () {
          OrchestrationInitLedgerLane.appendInitSkipped(userId);
        },
        setCurrentContext: (nextUserId, nextPersonality) {
          _currentUserId = nextUserId;
          _currentPersonality = nextPersonality;
        },
        prepareIdentityAndCaches: () async {
          final identity = await BleNodeIdentity.ensure(
            prefs: _prefs,
            prefsKeyNodeId: _prefsKeyBleNodeId,
            prefsKeyNodeIdExpiresAtMs: _prefsKeyBleNodeIdExpiresAtMs,
          );
          _localBleNodeId = identity.nodeId;
          _localNodeTagKey = identity.nodeTagKey;
          _loadSeenBleHashes();
          LearningInsightSeenIdsPersistenceLane.load(
            prefs: _prefs,
            prefsKey: _prefsKeySeenLearningInsightIds,
            seenLearningInsightIds: _seenLearningInsightIds,
          );
          return _localBleNodeId;
        },
        onInitStarted: (bleNodeId) {
          OrchestrationInitLedgerLane.appendInitStarted(
            userId: userId,
            bleNodeId: bleNodeId,
            allowBleSideEffects: _allowBleSideEffects,
            isTestBinding: _isTestBinding,
            isWeb: kIsWeb,
            platform: defaultTargetPlatform.name,
          );
        },
        allowBleSideEffects: _allowBleSideEffects,
        isWeb: kIsWeb,
        isAndroid: defaultTargetPlatform == TargetPlatform.android,
        startBleForegroundService: BleForegroundService.startService,
        onBleForegroundServiceStarted: () {
          OrchestrationInitLedgerLane.appendBleForegroundServiceStarted();
        },
        onBleForegroundServiceFailed: () {
          OrchestrationInitLedgerLane.appendBleForegroundServiceFailed();
        },
        publishPrekeyPayload: () {
          return PrekeyPayloadPublishLane.publishIfAvailable(
            signalKeyManager: _signalKeyManager,
            localBleNodeId: _localBleNodeId,
            logger: _logger,
            logName: _logName,
          );
        },
        initializeRealtime: _realtimeService?.initialize,
        setupRealtimeListeners: _setupRealtimeListeners,
        startAdvertising: () {
          return PersonalityAdvertisingStartLane.startIfAllowed(
            allowBleSideEffects: _allowBleSideEffects,
            advertisingService: _advertisingService,
            vibeAnalyzer: _vibeAnalyzer,
            userId: userId,
            personality: personality,
            localBleNodeId: _localBleNodeId,
            eventModeEnabled: _isEventModeEnabled(),
            logger: _logger,
            logName: _logName,
          );
        },
        startDiscovery: () async {
          final discoveryStart = await BleDiscoveryStartLane.startIfAllowed(
            allowBleSideEffects: _allowBleSideEffects,
            deviceDiscovery: _deviceDiscovery,
            prefs: _prefs,
            hotScanWindow: _hotScanWindow,
            hotDeviceTimeout: _hotDeviceTimeout,
            onDevicesDiscoveredHotPath: _onDevicesDiscoveredHotPath,
            existingBatteryScheduler: _batteryScheduler,
            existingAdaptiveMeshService: _adaptiveMeshService,
            logger: _logger,
            logName: _logName,
          );
          _batteryScheduler = discoveryStart.batteryScheduler;
          _adaptiveMeshService = discoveryStart.adaptiveMeshService;
        },
        startAi2AiDiscovery: () => _startAI2AIDiscovery(userId, personality),
        startBleInboxProcessing: _startBleInboxProcessing,
        startFederatedCloudSync: _startFederatedCloudSync,
        startConnectionMaintenance: _startConnectionMaintenance,
        onMarkInitialized: () {
          _isInitialized = true;
        },
        onInitCompleted: () {
          OrchestrationInitLedgerLane.appendInitCompleted(userId);
        },
        onInitFailed: (error) {
          OrchestrationInitLedgerLane.appendInitFailed(userId, error);
        },
        logger: _logger,
        logName: _logName,
      );
    } catch (e) {
      throw AI2AIConnectionException('Failed to initialize orchestration: $e');
    }
  }

  void _onDevicesDiscoveredHotPath(List<DiscoveredDevice> devices) {
    HotDiscoveryEnqueueLane.handle(
      allowBleSideEffects: _allowBleSideEffects,
      prefs: _prefs,
      eventModeEnabled: _isEventModeEnabled(),
      lastAdvertisedEventModeEnabled: _lastAdvertisedEventModeEnabled,
      maybeUpdateEventModeBroadcastFlags: _maybeUpdateEventModeBroadcastFlags,
      handleEventModeScanWindow: _handleEventModeScanWindow,
      devices: devices,
      hotRssiThresholdDbm: _hotRssiThresholdDbm,
      hotDeviceCooldown: _hotDeviceCooldown,
      lastHotProcessedAtMsByDeviceId: _lastHotProcessedAtMsByDeviceId,
      hotQueuedDeviceIds: _hotQueuedDeviceIds,
      hotQueue: _hotQueue,
      hotEnqueuedAtMsByDeviceId: _hotEnqueuedAtMsByDeviceId,
      batteryScheduler: _batteryScheduler,
      hotWorkerRunning: _hotWorkerRunning,
      startHotWorker: () {
        _hotWorkerRunning = true;
        unawaited(_runHotWorker());
      },
    );
  }

  bool _isEventModeEnabled() =>
      (_prefs.getBool(_prefsKeyEventModeEnabled) ?? false) == true;

  Future<void> _handleEventModeScanWindow(
      List<DiscoveredDevice> devices) async {
    await EventModeScanWindowOrchestrationLane.handle(
      allowBleSideEffects: _allowBleSideEffects,
      currentUserId: _currentUserId,
      hasCurrentPersonality: _currentPersonality != null,
      lastAdvertisedEventModeEnabled: _lastAdvertisedEventModeEnabled,
      devices: devices,
      hotRssiThresholdDbm: _hotRssiThresholdDbm,
      familiarityByNodeTag: _eventModeFamiliarityByNodeTag,
      batteryScheduler: _batteryScheduler,
      roomCoherenceEngine: _roomCoherenceEngine,
      maybeUpdateEventModeBroadcastFlags: _maybeUpdateEventModeBroadcastFlags,
      localBleNodeId: _localBleNodeId,
      eventInitiatorEligibilityPct: _eventInitiatorEligibilityPct,
      localNodeTagKey: _localNodeTagKey,
      eventModeLastDeepSyncAtMsByNodeTag: _eventModeLastDeepSyncAtMsByNodeTag,
      eventPerNodeDeepSyncCooldownMs: _eventPerNodeDeepSyncCooldownMs,
      eventEpochMs: _eventEpochMs,
      eventCheckInWindowMs: _eventCheckInWindowMs,
      eventMaxDeepSyncPerEvent: _eventMaxDeepSyncPerEvent,
      eventModeDeepSyncCount: _eventModeDeepSyncCount,
      eventModeLastEpochAttempted: _eventModeLastEpochAttempted,
      eventModeCheckInRunning: _eventModeCheckInRunning,
      onEventModeReset: () {
        _eventModeDeepSyncCount = 0;
        _eventModeLastDeepSyncAtMsByNodeTag.clear();
        _eventModeLastEpochAttempted = -1;
        _eventModeCheckInRunning = false;
      },
      setEventModeLastEpochAttempted: (epoch) {
        _eventModeLastEpochAttempted = epoch;
      },
      setEventModeCheckInRunning: (running) {
        _eventModeCheckInRunning = running;
      },
      incrementEventModeDeepSyncCount: () {
        _eventModeDeepSyncCount += 1;
      },
      processHotDevice: _processHotDevice,
    );
  }

  Future<void> _maybeUpdateEventModeBroadcastFlags({
    required bool eventModeEnabled,
    required bool connectOk,
    required bool brownout,
  }) async {
    final next = await EventModeBroadcastFlagsLane.maybeUpdate(
      hasRequiredContext: _currentUserId != null &&
          _currentPersonality != null &&
          _advertisingService != null,
      currentEventModeEnabled: _lastAdvertisedEventModeEnabled,
      currentConnectOk: _lastAdvertisedConnectOk,
      currentBrownout: _lastAdvertisedBrownout,
      nextEventModeEnabled: eventModeEnabled,
      nextConnectOk: connectOk,
      nextBrownout: brownout,
      updateServiceDataFrameV1Flags: ({
        required bool eventModeEnabled,
        required bool connectOk,
        required bool brownout,
      }) {
        return _advertisingService!.updateServiceDataFrameV1Flags(
          nodeId: _localBleNodeId,
          eventModeEnabled: eventModeEnabled,
          connectOk: connectOk,
          brownout: brownout,
        );
      },
    );

    _lastAdvertisedEventModeEnabled = next.eventModeEnabled;
    _lastAdvertisedConnectOk = next.connectOk;
    _lastAdvertisedBrownout = next.brownout;
  }

  Future<void> _runHotWorker() async {
    try {
      await HotQueueWorkerLane.run(
        hotQueue: _hotQueue,
        hotQueuedDeviceIds: _hotQueuedDeviceIds,
        lastHotProcessedAtMsByDeviceId: _lastHotProcessedAtMsByDeviceId,
        hotEnqueuedAtMsByDeviceId: _hotEnqueuedAtMsByDeviceId,
        onQueueWaitMs: _hotQueueWaitMs.add,
        prefs: _prefs,
        processHotDevice: _processHotDevice,
      );
    } finally {
      _hotWorkerRunning = false;
    }
  }

  Future<void> _processHotDevice(DiscoveredDevice device) async {
    await HotDeviceProcessingLane.process(
      device: device,
      currentUserId: _currentUserId,
      currentPersonality: _currentPersonality,
      vibeAnalyzer: _vibeAnalyzer,
      allowBleSideEffects: _allowBleSideEffects,
      deviceDiscovery: _deviceDiscovery,
      primeOfflineSignalPreKeyBundleInSession:
          _primeOfflineSignalPreKeyBundleInSession,
      isConnectionWorthy: _isConnectionWorthy,
      updateDiscoveredNodes: _updateDiscoveredNodes,
      maybeApplyPassiveAi2AiLearning: _maybeApplyPassiveAi2AiLearning,
      logger: _logger,
      logName: _logName,
      onSessionOpenMs: _hotSessionOpenMs.add,
      onVibeReadMs: _hotVibeReadMs.add,
      onCompatMs: _hotCompatMs.add,
      onTotalMs: _hotTotalMs.add,
      maybeLogHotMetrics: _maybeLogHotMetrics,
    );
  }

  void _maybeLogHotMetrics() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nextLogAtMs = HotMetricsEmitLane.emit(
      nowMs: nowMs,
      lastLogAtMs: _lastHotMetricsLogAtMs,
      minInterval: _hotMetricsLogInterval,
      queueWait: _hotQueueWaitMs,
      sessionOpen: _hotSessionOpenMs,
      vibeRead: _hotVibeReadMs,
      compatibility: _hotCompatMs,
      total: _hotTotalMs,
      onDebugLogLine: (line) => _logger.debug(line, tag: _logName),
      onLedgerAppend: LedgerAuditV0.isEnabled
          ? (payload) => LedgerAuditV0.tryAppend(
                domain: LedgerDomainV0.deviceCapability,
                eventType: 'ai2ai_hotpath_latency_summary',
                occurredAt: DateTime.now(),
                payload: payload,
              )
          : null,
    );
    _lastHotMetricsLogAtMs = nextLogAtMs;
  }

  @visibleForTesting
  Map<String, dynamic> debugHotPathLatencySummary() {
    final snapshot = HotPathMetricsLane.buildSnapshot(
      queueWait: _hotQueueWaitMs,
      sessionOpen: _hotSessionOpenMs,
      vibeRead: _hotVibeReadMs,
      compatibility: _hotCompatMs,
      total: _hotTotalMs,
    );
    return snapshot.toJson();
  }

  void _loadSeenBleHashes() {
    BleSeenHashesPersistenceLane.load(
      prefs: _prefs,
      prefsKey: _prefsKeySeenBleHashes,
      seenBleMessageHashes: _seenBleMessageHashes,
    );
  }

  Future<void> _persistSeenBleHashesIfNeeded() async {
    _lastSeenHashesPersistMs =
        await BleSeenHashesPersistenceLane.persistIfNeeded(
      prefs: _prefs,
      prefsKey: _prefsKeySeenBleHashes,
      seenBleMessageHashes: _seenBleMessageHashes,
      lastPersistMs: _lastSeenHashesPersistMs,
    );
  }

  Future<void> _maybeApplyPassiveAi2AiLearning({
    required String userId,
    required PersonalityProfile localPersonality,
    required List<AIPersonalityNode> nodes,
    required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
  }) async {
    await PassiveAi2AiLearningLane.apply(
      prefs: _prefs,
      prefsKeyAi2AiLearningEnabled: _prefsKeyAi2AiLearningEnabled,
      personalityLearning: _connectionManager.personalityLearning,
      userId: userId,
      localPersonality: localPersonality,
      nodes: nodes,
      compatibilityByNodeId: compatibilityByNodeId,
      lastAi2AiLearningAtByPeerId: _lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: _applyInsightForPeer,
      sendLearningInsightToPeer: ({
        required String peerId,
        required AI2AILearningInsight insight,
        required double learningQuality,
      }) async {
        await LearningInsightPeerDispatchLane.send(
          allowBleSideEffects: _allowBleSideEffects,
          eventModeEnabled: _isEventModeEnabled(),
          protocol: _protocol,
          deviceDiscovery: _deviceDiscovery,
          peerId: peerId,
          prefs: _prefs,
          prefsKeyAi2AiLearningEnabled: _prefsKeyAi2AiLearningEnabled,
          peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
          localBleNodeId: _localBleNodeId,
          insight: insight,
          learningQuality: learningQuality,
          enqueueFederatedDeltaForCloudFromInsightPayload:
              _enqueueFederatedDeltaForCloudFromInsightPayload,
          logger: _logger,
          logName: _logName,
        );
      },
      logger: _logger,
      logName: _logName,
    );
  }

  Future<List<AIPersonalityNode>> discoverNearbyAIPersonalities(
      String userId, PersonalityProfile personality,
      {bool throwOnError = false}) async {
    if (_isDiscovering) {
      _logger.debug('Discovery already in progress, returning cached results',
          tag: _logName);
      return _discoveredNodes.values.toList();
    }

    // Connectivity should NOT block offline-first physical discovery.
    // It only affects whether realtime/cloud discovery is viable.
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (!ConnectionRoutingPolicy.isConnected(connectivityResults)) {
        _logger.info(
            'No connectivity available, proceeding with offline discovery',
            tag: _logName);
      }
    } catch (e) {
      _logger.warn('Error checking connectivity: $e, proceeding with discovery',
          tag: _logName);
    }

    _isDiscovering = true;

    try {
      _logger.info('Discovering nearby AI personalities', tag: _logName);

      final nodes = await _discoveryManager.discover(
          userId, personality, _performAI2AIDiscovery);

      return DiscoveryPostprocessLane.process(
        nodes: nodes,
        userId: userId,
        personality: personality,
        vibeAnalyzer: _vibeAnalyzer,
        isConnectionWorthy: _isConnectionWorthy,
        updateDiscoveredNodes: _updateDiscoveredNodes,
        onWorthyNodes: (worthyNodes, compatibilityByNodeId) {
          // Passive, on-device AI2AI learning from nearby compatible peers.
          // Fire-and-forget: discovery should not block on learning updates.
          unawaited(_maybeApplyPassiveAi2AiLearning(
            userId: userId,
            localPersonality: personality,
            nodes: worthyNodes,
            compatibilityByNodeId: compatibilityByNodeId,
          ));
        },
        logger: _logger,
        logName: _logName,
      );
    } catch (e) {
      _logger.error('Error discovering AI personalities',
          error: e, tag: _logName);
      if (throwOnError) {
        throw AI2AIConnectionException('Discovery failed: $e');
      }
      return [];
    } finally {
      _isDiscovering = false;
    }
  }

  Future<ConnectionMetrics?> establishAI2AIConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
  ) async {
    return ConnectionAttemptOrchestrationLane.establish(
      isConnecting: _isConnecting,
      setIsConnecting: (value) => _isConnecting = value,
      connectionCooldowns: _connectionCooldowns,
      activeConnections: _activeConnections,
      localUserId: localUserId,
      localPersonality: localPersonality,
      remoteNode: remoteNode,
      vibeAnalyzer: _vibeAnalyzer,
      connectionManager: _connectionManager,
      isConnectionWorthy: _isConnectionWorthy,
      protocol: _protocol,
      signalKeyManager: _signalKeyManager,
      knotWeavingService: _knotWeavingService,
      knotStorageService: _knotStorageService,
      scheduleConnectionManagement: _scheduleConnectionManagement,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> manageActiveConnections() async {
    await ActiveConnectionManagementLane.run(
      activeConnections: _activeConnections,
      completeConnection: _completeConnection,
      updateConnectionLearning: _updateConnectionLearning,
      monitorConnectionHealth: _monitorConnectionHealth,
      logger: _logger,
      logName: _logName,
    );
  }

  int getActiveConnectionCount() {
    return _activeConnections.length;
  }

  Future<double> calculateAIPleasureScore(ConnectionMetrics connection) async {
    return AIPleasureScoreLane.calculate(
      connection: connection,
      prefs: _prefs,
      logger: _logger,
      logName: _logName,
    );
  }

  List<ConnectionSummary> getActiveConnectionSummaries() {
    return _activeConnections.values.map((connection) {
      return ConnectionSummary(
        connectionId: connection.connectionId,
        duration: connection.connectionDuration,
        compatibility: connection.currentCompatibility,
        learningEffectiveness: connection.learningEffectiveness,
        aiPleasureScore: connection.aiPleasureScore,
        qualityRating: connection.qualityRating,
        status: connection.status,
        interactionCount: connection.interactionHistory.length,
        dimensionsEvolved: connection.dimensionEvolution.keys.length,
      );
    }).toList();
  }

  List<ConnectionMetrics> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  Future<void> shutdown() async {
    _logger.info('Shutting down orchestration', tag: _logName);
    _isInitialized = false;

    await OrchestrationShutdownLane.stopRuntime(
      discoveryTimer: _discoveryTimer,
      connectionMaintenanceTimer: _connectionMaintenanceTimer,
      bleInboxPoller: _bleInboxPoller,
      federatedCloudSyncTimer: _federatedCloudSyncTimer,
      federatedCloudConnectivitySub: _federatedCloudConnectivitySub,
      batteryScheduler: _batteryScheduler,
      adaptiveMeshService: _adaptiveMeshService,
      deviceDiscovery: _deviceDiscovery,
      advertisingService: _advertisingService,
      allowBleSideEffects: _allowBleSideEffects,
      isWeb: kIsWeb,
      isAndroid: defaultTargetPlatform == TargetPlatform.android,
      stopBleForegroundService: BleForegroundService.stopService,
      logger: _logger,
      logName: _logName,
    );
    _federatedCloudConnectivitySub = null;
    _batteryScheduler = null;
    _adaptiveMeshService = null;

    await ConnectionShutdownCleanupLane.run(
      activeConnections: _activeConnections,
      connectionCooldowns: _connectionCooldowns,
      pendingConnections: _pendingConnections,
      nearbyVibes: _nearbyVibes,
      discoveredNodes: _discoveredNodes,
      completeConnection: _completeConnection,
      onResetNetworkDensity: () => _adaptiveMeshService?.updateNetworkDensity(0),
      onClearCurrentUser: () {
        _currentUserId = null;
      },
      logger: _logger,
      logName: _logName,
    );
  }

  void _startBleInboxProcessing() {
    if (!_allowBleSideEffects) return;
    _bleInboxPoller?.cancel();
    _bleInboxPoller = BleInboxProcessingLane.start(
      protocol: _protocol,
      seenBleMessageHashes: _seenBleMessageHashes,
      handleIncomingLocalityAgentUpdate: _handleIncomingLocalityAgentUpdate,
      handleIncomingOrganicSpotDiscovery: _handleIncomingOrganicSpotDiscovery,
      handleIncomingLearningInsight: _handleIncomingLearningInsight,
      handleIncomingUserChat: _handleIncomingUserChat,
      persistSeenBleHashesIfNeeded: _persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded: () async {
        _lastSeenInsightsPersistMs =
            await LearningInsightSeenIdsPersistenceLane.persistIfNeeded(
          prefs: _prefs,
          prefsKey: _prefsKeySeenLearningInsightIds,
          seenLearningInsightIds: _seenLearningInsightIds,
          lastPersistMs: _lastSeenInsightsPersistMs,
        );
      },
      logger: _logger,
      logName: _logName,
    );
  }

  bool _isFederatedLearningParticipationEnabled() {
    return _prefs.getBool(_prefsKeyFederatedLearningParticipation) ?? true;
  }

  void _startFederatedCloudSync() {
    unawaited(() async {
      final handles = await FederatedCloudSyncStartLane.start(
        isTestBinding: _isTestBinding,
        connectivity: _connectivity,
        syncFederatedCloudQueue: _syncFederatedCloudQueue,
        existingTimer: _federatedCloudSyncTimer,
        existingSubscription: _federatedCloudConnectivitySub,
        logger: _logger,
        logName: _logName,
      );
      _federatedCloudSyncTimer = handles.timer;
      _federatedCloudConnectivitySub = handles.subscription;
    }());
  }

  Future<void> _enqueueFederatedDeltaForCloudFromInsightPayload(
    Map<String, dynamic> payload,
  ) async {
    if (!_isFederatedLearningParticipationEnabled()) return;
    await FederatedCloudQueueLane.enqueueFromLearningInsightPayload(
      prefs: _prefs,
      prefsKeyQueue: _prefsKeyFederatedCloudQueue,
      payload: payload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> syncFederatedCloudQueue() => _syncFederatedCloudQueue();

  Future<void> _syncFederatedCloudQueue() async {
    _lastFederatedCloudSyncAttemptMs = await FederatedCloudSyncLane.run(
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      lastFederatedCloudSyncAttemptMs: _lastFederatedCloudSyncAttemptMs,
      prefs: _prefs,
      prefsKeyQueue: _prefsKeyFederatedCloudQueue,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingLearningInsight(ProtocolMessage message) async {
    await IncomingLearningInsightProcessingLane.handle(
      message: message,
      prefs: _prefs,
      prefsKeyAi2AiLearningEnabled: _prefsKeyAi2AiLearningEnabled,
      currentUserId: _currentUserId,
      personalityLearning: _connectionManager.personalityLearning,
      adaptiveMeshService: _adaptiveMeshService,
      seenLearningInsightIds: _seenLearningInsightIds,
      lastAi2AiLearningAtByPeerId: _lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: _applyInsightForPeer,
      maybeForwardLearningInsightGossip: _maybeForwardLearningInsightGossip,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingUserChat(ProtocolMessage message) async {
    await IncomingUserChatProcessingLane.handle(
      message: message,
      handleIncomingBusinessExpertChat: _handleIncomingBusinessExpertChat,
      handleIncomingBusinessBusinessChat: _handleIncomingBusinessBusinessChat,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingBusinessExpertChat(
    ProtocolMessage _,
    Map<String, dynamic> payload,
  ) async {
    await IncomingBusinessExpertChatLane.handle(
      payload: payload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingBusinessBusinessChat(
    ProtocolMessage _,
    Map<String, dynamic> payload,
  ) async {
    await IncomingBusinessBusinessChatLane.handle(
      payload: payload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _maybeForwardLearningInsightGossip({
    required Map<String, dynamic> payload,
    required String originId,
    required int hop,
    required String receivedFromDeviceId,
  }) async {
    await MeshOutboundForwardingLane.forwardLearningInsightGossip(
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      originId: originId,
      localNodeId: _localBleNodeId,
      payload: payload,
      hop: hop,
      receivedFromDeviceId: receivedFromDeviceId,
      adaptiveMeshService: _adaptiveMeshService,
      getOrCreateBloomFilter: _getOrCreateBloomFilter,
      logger: _logger,
      logName: _logName,
      discoveredNodeIds: _discoveredNodeIds,
      protocol: _protocol,
      discovery: _deviceDiscovery,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
    );
  }

  // Private helper methods
  Future<void> _startAI2AIDiscovery(
      String userId, PersonalityProfile personality) async {
    _discoveryTimer = await OrchestrationStartupLane.startDiscovery(
      discoverNearby: () => discoverNearbyAIPersonalities(
        userId,
        personality,
        throwOnError: true,
      ),
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _startConnectionMaintenance() async {
    _connectionMaintenanceTimer =
        OrchestrationStartupLane.startConnectionMaintenance(
      manageActiveConnections: manageActiveConnections,
      manageSessionLifecycle: _manageSessionLifecycle,
      managePreKeyBundleRotation: _managePreKeyBundleRotation,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<bool> _applyInsightForPeer({
    required String userId,
    required PersonalityLearning personalityLearning,
    required String peerId,
    required AI2AILearningInsight insight,
    required DateTime now,
    required String source,
    required String? insightId,
    required double learningQuality,
    required Map<String, double> deltas,
  }) async {
    return LearningInsightApplicationLane.apply(
      eventModeEnabled: _isEventModeEnabled(),
      evolveFromAi2AiLearning: () =>
          personalityLearning.evolveFromAI2AILearning(userId, insight),
      onEventModeBuffer: () {
        EventModeLearningBufferLane.buffer(
          buffer: _eventModeLearningBuffer,
          insight: EventModeBufferedLearningInsight(
            source: source,
            insightId: insightId,
            senderDeviceId: peerId,
            receivedAt: now,
            learningQuality: learningQuality,
            deltas: deltas,
          ),
        );
        _lastAi2AiLearningAtByPeerId[peerId] = now;
      },
      onApplied: () {
        _lastAi2AiLearningAtByPeerId[peerId] = now;
        ContinuousLearningMirror.mirrorInsight(
          userId: userId,
          insight: insight,
          peerId: peerId,
          logger: _logger,
          logTag: _logName,
        );
      },
    );
  }

  Future<void> _manageSessionLifecycle() async {
    await SessionLifecycleLane.run(
      logger: _logger,
      logName: _logName,
      expireSessionsBasedOnQuality: _expireSessionsBasedOnQuality,
      cleanupInactiveSessions: _cleanupInactiveSessions,
      renewActiveSessions: _renewActiveSessions,
      rotateKeysBasedOnQualityChanges: _rotateKeysBasedOnQualityChanges,
    );
  }

  Future<void> _managePreKeyBundleRotation() async {
    await PrekeyBundleRotationLane.run(
      signalKeyManager: _signalKeyManager,
      activeConnections: _activeConnections.values,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _expireSessionsBasedOnQuality(
      SignalSessionManager sessionManager) async {
    await SessionExpiryLane.run(
      sessionManager: sessionManager,
      activeConnectionsById: _activeConnections,
      completeConnection: _completeConnection,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _cleanupInactiveSessions(
      SignalSessionManager sessionManager) async {
    await InactiveSessionCleanupLane.run(
      sessionManager: sessionManager,
      activeConnections: _activeConnections.values,
      discoveredNodes: _discoveredNodes.values,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _renewActiveSessions(SignalSessionManager sessionManager) async {
    await SessionRenewalLane.run(
      sessionManager: sessionManager,
      activeConnections: _activeConnections.values,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _rotateKeysBasedOnQualityChanges(
    SignalSessionManager sessionManager,
  ) async {
    await QualityChangeKeyRotationLane.run(
      sessionManager: sessionManager,
      activeConnections: _activeConnections.values,
      previousQualityScores: _previousQualityScores,
      qualityChangeThreshold: _qualityChangeThreshold,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<List<AIPersonalityNode>> _performAI2AIDiscovery(
      AnonymizedVibeData localVibe) async {
    return AI2AIDiscoveryExecutionLane.discover(
      deviceDiscovery: _deviceDiscovery,
      allowBleSideEffects: _allowBleSideEffects,
      primeOfflineSignalPreKeyBundleInSession:
          _primeOfflineSignalPreKeyBundleInSession,
      realtimeService: _realtimeService,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _primeOfflineSignalPreKeyBundleInSession({
    required DiscoveredDevice device,
    required BleGattSession session,
  }) async {
    await PrekeySessionPrimeLane.run(
      allowBleSideEffects: _allowBleSideEffects,
      signalKeyManager: _signalKeyManager,
      protocol: _protocol,
      device: device,
      session: session,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      federatedLearningParticipationEnabled:
          _adaptiveMeshService != null &&
          _isFederatedLearningParticipationEnabled(),
      forwardPreKeyBundleThroughMesh: _forwardPreKeyBundleThroughMesh,
      localBleNodeId: _localBleNodeId,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _forwardPreKeyBundleThroughMesh({
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required DiscoveredDevice device,
  }) async {
    await PrekeyMeshForwardBridgeLane.forward(
      allowBleSideEffects: _allowBleSideEffects,
      tryCreateMeshForwardingContext: _tryCreateMeshForwardingContext,
      bundle: bundle,
      recipientId: recipientId,
      discoveredNodeIds: _discoveredNodeIds,
      localNodeId: _localBleNodeId,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      adaptiveMeshService: _adaptiveMeshService,
      logger: _logger,
      logName: _logName,
    );
  }

  void _updateDiscoveredNodes(List<AIPersonalityNode> nodes) {
    DiscoveredNodeRegistry.mergeAndPrune(
      incomingNodes: nodes,
      discoveredNodes: _discoveredNodes,
      nearbyVibes: _nearbyVibes,
      onDensityChanged: (density) {
        _adaptiveMeshService?.updateNetworkDensity(density);
      },
    );
  }

  // ignore: unused_element
  Future<List<AIPersonalityNode>> _prioritizeConnections(
    List<AIPersonalityNode> nodes,
    Map<String, VibeCompatibilityResult> compatibilityResults,
  ) async {
    final prioritized = DiscoveredNodeRegistry.prioritizeConnections(
      nodes: nodes,
      compatibilityResults: compatibilityResults,
      maxConnections: 5,
    );

    _logger.debug(
        'Prioritized ${nodes.length} nodes to top ${prioritized.length} connections',
        tag: _logName);

    return prioritized;
  }

  bool _isConnectionWorthy(VibeCompatibilityResult compatibility) {
    final result = ConnectionRoutingPolicy.evaluateWorthiness(compatibility);

    if (!result.isWorthy) {
      _logger.debug(
          'Connection not worthy: ${result.reason}; opportunities=${compatibility.learningOpportunities.length}',
          tag: _logName);
    }

    return result.isWorthy;
  }

  Future<int?> getBatteryLevel() async {
    if (_batteryScheduler != null) {
      try {
        return await _batteryScheduler!.getBatteryLevel();
      } catch (e) {
        _logger.debug(
          'Failed to get battery level: $e',
          tag: _logName,
        );
        return null;
      }
    }
    return null;
  }

  int? getNetworkDensity() {
    return _adaptiveMeshService?.networkDensity;
  }

  void _scheduleConnectionManagement(ConnectionMetrics connection) {
    // Connection-specific management would be handled by the main maintenance timer
    _logger.debug(
        'Scheduled management for connection: ${connection.connectionId}',
        tag: _logName);
  }

  Future<ConnectionMetrics?> _completeConnection(ConnectionMetrics connection,
      {String? reason}) async {
    return ConnectionCompletionLane.complete(
      connection: connection,
      reason: reason,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _updateConnectionLearning(ConnectionMetrics connection) async {
    _activeConnections[connection.connectionId] =
        ConnectionLifecycleLane.maybeApplyLearningUpdate(connection);
  }

  Future<void> _monitorConnectionHealth(ConnectionMetrics connection) async {
    // Monitor connection health and update AI pleasure score
    final currentPleasure = await calculateAIPleasureScore(connection);

    _activeConnections[connection.connectionId] =
        ConnectionLifecycleLane.applyHealthUpdate(
      connection: connection,
      aiPleasureScore: currentPleasure,
    );
  }

  UserVibe? getCurrentVibe() {
    return null;
  }

  Future<AnonymousUser> anonymizeUserForTransmission(
    UnifiedUser user,
    String agentId,
    PersonalityProfile? personalityProfile, {
    bool isAdmin = false,
  }) async {
    return PayloadAnonymizationLane.anonymizeUserForTransmission(
      anonymizationService: _anonymizationService,
      user: user,
      agentId: agentId,
      personalityProfile: personalityProfile,
      isAdmin: isAdmin,
      logger: _logger,
      logName: _logName,
    );
  }

  void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    PayloadAnonymizationLane.validateNoUnifiedUserInPayload(payload);
  }

  Future<void> _setupRealtimeListeners() async {
    await RealtimeListenerCallbacksLane.setup(
      coordinator: _realtimeCoordinator,
      validateNoUnifiedUserInPayload: validateNoUnifiedUserInPayload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> forwardOrganicSpotDiscovery(
    Map<String, dynamic> signal,
  ) async {
    await MeshOutboundForwardingLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      tryCreateMeshForwardingContext: _tryCreateMeshForwardingContext,
      discoveredNodeIds: _discoveredNodeIds,
      localNodeId: _localBleNodeId,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> forwardLocalityAgentUpdate(Map<String, dynamic> message) async {
    await MeshOutboundForwardingLane.forwardLocalityAgentUpdate(
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      localNodeId: _localBleNodeId,
      message: message,
      adaptiveMeshService: _adaptiveMeshService,
      getOrCreateBloomFilter: _getOrCreateBloomFilter,
      protocol: _protocol,
      discovery: _deviceDiscovery,
      discoveredNodeIds: _discoveredNodeIds,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingLocalityAgentUpdate(
      ProtocolMessage message) async {
    await IncomingMeshSignalHandlersLane.handleLocalityAgentUpdate(
      message: message,
      adaptiveMeshService: _adaptiveMeshService,
      maybeForwardLocalityAgentUpdateGossip:
          _maybeForwardLocalityAgentUpdateGossip,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _handleIncomingOrganicSpotDiscovery(
      ProtocolMessage message) async {
    await IncomingMeshSignalHandlersLane.handleOrganicSpotDiscovery(
      message: message,
      currentUserId: _currentUserId,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _maybeForwardLocalityAgentUpdateGossip({
    required Map<String, dynamic> payload,
    required String originId,
    required int hop,
    required String receivedFromDeviceId,
  }) async {
    await MeshOutboundForwardingLane.forwardLocalityAgentUpdateGossip(
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      originId: originId,
      localNodeId: _localBleNodeId,
      payload: payload,
      hop: hop,
      receivedFromDeviceId: receivedFromDeviceId,
      adaptiveMeshService: _adaptiveMeshService,
      getOrCreateBloomFilter: _getOrCreateBloomFilter,
      logger: _logger,
      logName: _logName,
      discoveredNodeIds: _discoveredNodeIds,
      protocol: _protocol,
      discovery: _deviceDiscovery,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
    );
  }

  OptimizedBloomFilter _getOrCreateBloomFilter(String scope) {
    return _bloomFilters.putIfAbsent(
      scope,
      () => OptimizedBloomFilter(geographicScope: scope),
    );
  }

  Iterable<String> get _discoveredNodeIds =>
      _discoveredNodes.values.map((n) => n.nodeId);

  MeshForwardingContext? _tryCreateMeshForwardingContext() {
    return MeshForwardingContext.tryCreate(
      protocol: _protocol,
      discovery: _deviceDiscovery,
    );
  }
}
