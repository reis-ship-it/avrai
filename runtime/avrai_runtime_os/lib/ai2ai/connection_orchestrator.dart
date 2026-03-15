// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/pending_connection.dart';
import 'package:avrai_runtime_os/ai2ai/connection_summary.dart';
import 'package:avrai_runtime_os/ai2ai/connection_summary_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/ai2ai_connection_exception.dart';
import 'package:avrai_runtime_os/ai2ai/ai2ai_connection_governance_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_runtime_os/ai2ai/orchestrator_components.dart';
import 'package:avrai_runtime_os/ai2ai/peer_interaction_outcome_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/discovery_node_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/debug_hot_path_simulation_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/nearby_discovery_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/event_mode_broadcast_flags_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_public_forwarding_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/event_mode_hot_path_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/learning_insight_apply_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/locality/passive_ai2ai_learning_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/trust/payload_realtime_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/orchestration_startup_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/orchestration_shutdown_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/orchestration_init_flow_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/personality_advertising_start_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/ble_discovery_start_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/ble_seen_hashes_persistence_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/learning_insight_seen_ids_persistence_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/ai2ai_discovery_prekey_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/event_mode_buffered_learning_insight.dart';
import 'package:avrai_runtime_os/services/transport/ble/federated_cloud_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/prekey_payload_publish_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/runtime_services_startup_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_attempt_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/personality_advertising_update_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_completion_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_management_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_shutdown_cleanup_lane.dart';
import 'package:avrai_runtime_os/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai_runtime_os/ai2ai/telemetry/ai_pleasure_score_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/hot_path_orchestration_flow_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/hot_path_metrics_orchestration_lane.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/ai2ai/room_coherence_engine.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/anonymous_user.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/pheromone_mesh_routing_service.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:avrai_network/network/bloom_filter.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_protocol_codec_adapter.dart';

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
  final CanonicalPeerResolutionService _canonicalPeerResolutionService;
  final PeerInteractionOutcomeLearningService
      _peerInteractionOutcomeLearningService;
  final RealtimeCoordinator? _realtimeCoordinator;
  final DeviceDiscoveryService? _deviceDiscovery;
  final GovernedMeshPacketCodec? _meshPacketCodec;
  final MeshInboundDecodeLane? _meshInboundDecodeLane;
  final PersonalityAdvertisingService? _advertisingService;
  final UserAnonymizationService? _anonymizationService;
  final SignalKeyManager? _signalKeyManager;
  final Ai2AiMeshGovernanceBindingService? _ai2aiMeshGovernanceBindingService;
  final Ai2AiChatEventIntakeService? _ai2aiChatEventIntakeService;
  final FeatureFlagService? _featureFlagService;
  final SharedPreferencesCompat _prefs;
  final UrkRuntimeActivationReceiptDispatcher? _urkActivationDispatcher;
  final CanonicalVibeProjectionService _canonicalVibeProjectionService;
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
  final Map<String, String> _ai2aiPlanGovernanceRecordIdsByRemoteNodeId = {};
  final Map<String, String> _ai2aiOutcomeGovernanceRecordIdsBySubjectId = {};
  final Map<String, AIPersonalityNode> _remoteNodeByConnectionId = {};

  // Connection orchestration state
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  Timer? _discoveryTimer;
  Timer? _connectionMaintenanceTimer;
  Timer? _bleInboxPoller;
  Timer? _meshCustodyReplayPoller;
  bool _reticulumMeshTransportControlPlaneEnabled = false;
  bool _trustedMeshAnnounceEnforcementEnabled = false;
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

  // Pheromone Mesh Routing
  final PheromoneMeshRoutingService _pheromoneRoutingService;

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
  Map<String, String> debugAi2AiGovernancePlanRecordIds() {
    return Map<String, String>.from(
        _ai2aiPlanGovernanceRecordIdsByRemoteNodeId);
  }

  @visibleForTesting
  Map<String, String> debugAi2AiGovernanceOutcomeRecordIds() {
    return Map<String, String>.from(
        _ai2aiOutcomeGovernanceRecordIdsBySubjectId);
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
    LegacyProtocolCodecAdapter? legacyProtocolCodecAdapter,
    GovernedMeshPacketCodec? meshPacketCodec,
    MeshInboundDecodeLane? meshInboundDecodeLane,
    PersonalityAdvertisingService? advertisingService,
    UserAnonymizationService? anonymizationService,
    SignalKeyManager? signalKeyManager,
    Ai2AiMeshGovernanceBindingService? ai2aiMeshGovernanceBindingService,
    Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
    FeatureFlagService? featureFlagService,
    required SharedPreferencesCompat prefs,
    UrkRuntimeActivationReceiptDispatcher? urkActivationDispatcher,
    PersonalityLearning? personalityLearning, // NEW: For offline AI2AI learning
    PeerInteractionOutcomeLearningService? peerInteractionOutcomeLearningService,
    // Phase 2: Knot Weaving Integration
    KnotWeavingService? knotWeavingService,
    KnotStorageService? knotStorageService,
    GovernanceKernelService? governanceKernelService,
    CanonicalVibeProjectionService? canonicalVibeProjectionService,
  })  : _vibeAnalyzer = vibeAnalyzer,
        _connectivity = connectivity,
        _realtimeService = realtimeService,
        _deviceDiscovery = deviceDiscovery,
        _meshPacketCodec = meshPacketCodec,
        _meshInboundDecodeLane = meshInboundDecodeLane,
        _advertisingService = advertisingService,
        _anonymizationService = anonymizationService,
        _signalKeyManager = signalKeyManager,
        _ai2aiMeshGovernanceBindingService = ai2aiMeshGovernanceBindingService,
        _ai2aiChatEventIntakeService = ai2aiChatEventIntakeService,
        _featureFlagService = featureFlagService,
        _prefs = prefs,
        _urkActivationDispatcher = urkActivationDispatcher ??
            resolveDefaultUrkRuntimeActivationDispatcher(),
        _canonicalVibeProjectionService =
            canonicalVibeProjectionService ?? CanonicalVibeProjectionService(),
        _canonicalPeerResolutionService = CanonicalPeerResolutionService(),
        _peerInteractionOutcomeLearningService =
            peerInteractionOutcomeLearningService ??
                PeerInteractionOutcomeLearningService(),
        _knotWeavingService = knotWeavingService,
        _knotStorageService = knotStorageService,
        _discoveryManager = DiscoveryManager(
            connectivity: connectivity, vibeAnalyzer: vibeAnalyzer),
        _connectionManager = ConnectionManager(
          vibeAnalyzer: vibeAnalyzer,
          personalityLearning:
              personalityLearning, // NEW: Pass to ConnectionManager
          protocolCodecAdapter: legacyProtocolCodecAdapter,
        ),
        _realtimeCoordinator = realtimeService != null
            ? RealtimeCoordinator(realtimeService)
            : null,
        _pheromoneRoutingService = PheromoneMeshRoutingService(
          governanceKernel:
              governanceKernelService ?? GovernanceKernelService(),
        );

  void setRealtimeService(AI2AIBroadcastService service) {
    _realtimeService = service;
  }

  Future<void> updatePersonalityAdvertising(
    String userId,
    PersonalityProfile updatedPersonality,
  ) async {
    final canonicalPersonality =
        await _canonicalizePersonality(userId, updatedPersonality);
    await PersonalityAdvertisingUpdateLane.update(
      userId: userId,
      updatedPersonality: canonicalPersonality,
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

  void setupAutomaticAdvertisingUpdates() {}

  Future<void> initializeOrchestration(
      String userId, PersonalityProfile personality) async {
    try {
      final canonicalPersonality =
          await _canonicalizePersonality(userId, personality);
      await _refreshTransportFeatureFlags(userId);
      await OrchestrationInitFlowLane.runForOrchestrator(
        isInitialized: _isInitialized,
        userId: userId,
        personality: canonicalPersonality,
        prefs: _prefs,
        prefsKeyNodeId: _prefsKeyBleNodeId,
        prefsKeyNodeIdExpiresAtMs: _prefsKeyBleNodeIdExpiresAtMs,
        prefsKeySeenLearningInsightIds: _prefsKeySeenLearningInsightIds,
        seenLearningInsightIds: _seenLearningInsightIds,
        loadSeenBleHashes: _loadSeenBleHashes,
        setCurrentContext: (nextUserId, nextPersonality) {
          _currentUserId = nextUserId;
          _currentPersonality = nextPersonality;
        },
        setBleIdentity: (nodeId, nodeTagKey) {
          _localBleNodeId = nodeId;
          _localNodeTagKey = nodeTagKey;
        },
        allowBleSideEffects: _allowBleSideEffects,
        isTestBinding: _isTestBinding,
        isWeb: kIsWeb,
        platform: defaultTargetPlatform.name,
        isAndroid: defaultTargetPlatform == TargetPlatform.android,
        startBleForegroundService: BleForegroundService.startService,
        publishPrekeyPayload: _publishPrekeyPayload,
        initializeRealtime: _realtimeService?.initialize,
        setupRealtimeListeners: _setupRealtimeListeners,
        startAdvertising: () => _startAdvertising(userId, canonicalPersonality),
        startDiscovery: _startDiscovery,
        startAi2AiDiscovery: () async {
          _discoveryTimer = await OrchestrationStartupLane.startDiscovery(
            discoverNearby: () => discoverNearbyAIPersonalities(
              userId,
              canonicalPersonality,
              throwOnError: true,
            ),
            logger: _logger,
            logName: _logName,
          );
        },
        startBleInboxProcessing: _startBleInboxProcessing,
        startFederatedCloudSync: _startFederatedCloudSync,
        startConnectionMaintenance: () async {
          _connectionMaintenanceTimer = OrchestrationStartupLane
              .startConnectionMaintenanceForOrchestrator(
            manageActiveConnections: manageActiveConnections,
            activeConnectionsById: _activeConnections,
            discoveredNodes: _discoveredNodes.values,
            completeConnection: _completeConnection,
            previousQualityScores: _previousQualityScores,
            qualityChangeThreshold: _qualityChangeThreshold,
            signalKeyManager: _signalKeyManager,
            logger: _logger,
            logName: _logName,
          );
        },
        onAlreadyInitialized: () {
          _logger.debug(
            'Orchestration already initialized; skipping reinitialization',
            tag: _logName,
          );
        },
        onMarkInitialized: () {
          _isInitialized = true;
        },
        logger: _logger,
        logName: _logName,
      );
    } catch (e) {
      throw AI2AIConnectionException('Failed to initialize orchestration: $e');
    }
  }

  Future<void> _publishPrekeyPayload() {
    return PrekeyPayloadPublishLane.publishIfAvailable(
      signalKeyManager: _signalKeyManager,
      localBleNodeId: _localBleNodeId,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _startAdvertising(
    String userId,
    PersonalityProfile personality,
  ) {
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
  }

  Future<void> _startDiscovery() async {
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
  }

  void _onDevicesDiscoveredHotPath(List<DiscoveredDevice> devices) {
    EventModeHotPathOrchestrationLane.onDevicesDiscoveredHotPath(
      allowBleSideEffects: _allowBleSideEffects,
      prefs: _prefs,
      eventModeEnabled: _isEventModeEnabled(),
      lastAdvertisedEventModeEnabled: _lastAdvertisedEventModeEnabled,
      maybeUpdateEventModeBroadcastFlags: ({
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
      },
      devices: devices,
      hotRssiThresholdDbm: _hotRssiThresholdDbm,
      hotDeviceCooldown: _hotDeviceCooldown,
      lastHotProcessedAtMsByDeviceId: _lastHotProcessedAtMsByDeviceId,
      hotQueuedDeviceIds: _hotQueuedDeviceIds,
      hotQueue: _hotQueue,
      hotEnqueuedAtMsByDeviceId: _hotEnqueuedAtMsByDeviceId,
      currentUserId: _currentUserId,
      hasCurrentPersonality: _currentPersonality != null,
      familiarityByNodeTag: _eventModeFamiliarityByNodeTag,
      roomCoherenceEngine: _roomCoherenceEngine,
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
      setEventModeDeepSyncCount: (value) {
        _eventModeDeepSyncCount = value;
      },
      setEventModeLastEpochAttempted: (value) {
        _eventModeLastEpochAttempted = value;
      },
      setEventModeCheckInRunning: (value) {
        _eventModeCheckInRunning = value;
      },
      processHotDevice: _processHotDevice,
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

  Future<void> _runHotWorker() async {
    await HotPathOrchestrationFlowLane.runWorkerForOrchestratorWithMetrics(
      hotQueue: _hotQueue,
      hotQueuedDeviceIds: _hotQueuedDeviceIds,
      lastHotProcessedAtMsByDeviceId: _lastHotProcessedAtMsByDeviceId,
      hotEnqueuedAtMsByDeviceId: _hotEnqueuedAtMsByDeviceId,
      prefs: _prefs,
      onQueueWaitMs: _hotQueueWaitMs.add,
      processHotDevice: _processHotDevice,
      onWorkerStopped: () {
        _hotWorkerRunning = false;
      },
    );
  }

  Future<void> _processHotDevice(DiscoveredDevice device) async {
    await HotPathOrchestrationFlowLane.processHotDeviceForOrchestrator(
      device: device,
      currentUserId: _currentUserId,
      currentPersonality: _currentPersonality,
      vibeAnalyzer: _vibeAnalyzer,
      allowBleSideEffects: _allowBleSideEffects,
      deviceDiscovery: _deviceDiscovery,
      primeOfflineSignalPreKeyBundleInSession:
          _primeOfflineSignalPreKeyBundleInSession,
      resolveRemotePeerContext: ({
        required String localUserId,
        required PersonalityProfile localPersonality,
        required String remoteDeviceId,
      }) {
        return _connectionManager.resolveRemotePeerContextForDevice(
          localUserId: localUserId,
          localPersonality: localPersonality,
          remoteDeviceId: remoteDeviceId,
        );
      },
      isConnectionWorthy: _isConnectionWorthy,
      updateDiscoveredNodes: _updateDiscoveredNodes,
      maybeApplyPassiveAi2AiLearning: _maybeApplyPassiveAi2AiLearning,
      maybeSwapPheromones: _maybeSwapPheromones,
      hotSessionOpenMs: _hotSessionOpenMs,
      hotVibeReadMs: _hotVibeReadMs,
      hotCompatMs: _hotCompatMs,
      hotTotalMs: _hotTotalMs,
      hotQueueWaitMs: _hotQueueWaitMs,
      lastHotMetricsLogAtMs: _lastHotMetricsLogAtMs,
      hotMetricsLogInterval: _hotMetricsLogInterval,
      setLastHotMetricsLogAtMs: (value) {
        _lastHotMetricsLogAtMs = value;
      },
      logger: _logger,
      logName: _logName,
    );
  }

  @visibleForTesting
  Map<String, dynamic> debugHotPathLatencySummary() {
    return HotPathMetricsOrchestrationLane.summarySnapshotJson(
      queueWait: _hotQueueWaitMs,
      sessionOpen: _hotSessionOpenMs,
      vibeRead: _hotVibeReadMs,
      compatibility: _hotCompatMs,
      total: _hotTotalMs,
    );
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
    await PassiveAi2AiLearningOrchestrationLane.apply(
      prefs: _prefs,
      prefsKeyAi2AiLearningEnabled: _prefsKeyAi2AiLearningEnabled,
      personalityLearning: _connectionManager.personalityLearning,
      userId: userId,
      localPersonality: localPersonality,
      nodes: nodes,
      compatibilityByNodeId: compatibilityByNodeId,
      lastAi2AiLearningAtByPeerId: _lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: _applyInsightForPeer,
      allowBleSideEffects: _allowBleSideEffects,
      eventModeEnabled: _isEventModeEnabled(),
      packetCodec: _meshPacketCodec,
      deviceDiscovery: _deviceDiscovery,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      localBleNodeId: _localBleNodeId,
      enqueueFederatedDeltaForCloudFromInsightPayload:
          _enqueueFederatedDeltaForCloudFromInsightPayload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _maybeSwapPheromones({
    required DiscoveredDevice device,
    required BleGattSession? session,
    required VibeCompatibilityResult compatibility,
  }) async {
    // If we have a high-compatibility match and a valid BLE session, we try to swap vectors.
    // In a real implementation, we'd negotiate a characteristic write/read for the payload.
    // For this spike, we simulate the secure outbox queue draining.

    if (session == null) return;

    final vectorsToSend = _pheromoneRoutingService.getVectorsForSwapping();
    if (vectorsToSend.isEmpty) return;

    _logger.debug(
      'High compatibility match with ${device.deviceId}! Attempting to securely swap ${vectorsToSend.length} Pheromone Vectors via Epidemic Routing.',
      tag: _logName,
    );

    // Simulate sending vectors to remote device over GATT...
    // await session.writeStreamPayload(streamId: 2, payload: encodeVectors(vectorsToSend));

    // Simulate receiving vectors from remote device...
    // final incomingPayload = await session.readStreamPayload(streamId: 3);
    // final incomingVectors = decodeVectors(incomingPayload);
    // for (final v in incomingVectors) {
    //   _pheromoneRoutingService.receiveFromMesh(v);
    // }
  }

  Future<List<AIPersonalityNode>> discoverNearbyAIPersonalities(
      String userId, PersonalityProfile personality,
      {bool throwOnError = false}) async {
    final canonicalPersonality =
        await _canonicalizePersonality(userId, personality);
    return NearbyDiscoveryOrchestrationLane.runForOrchestrator(
      isDiscovering: _isDiscovering,
      setIsDiscovering: (value) => _isDiscovering = value,
      getCachedNodes: () => _discoveredNodes.values.toList(),
      checkConnectivity: _connectivity.checkConnectivity,
      performRawDiscovery: () => _discoveryManager.discover(
        userId,
        canonicalPersonality,
        (localVibe) => Ai2AiDiscoveryPrekeyOrchestrationLane.performDiscovery(
          deviceDiscovery: _deviceDiscovery,
          allowBleSideEffects: _allowBleSideEffects,
          primeOfflineSignalPreKeyBundleInSession:
              _primeOfflineSignalPreKeyBundleInSession,
          realtimeService: _realtimeService,
          logger: _logger,
          logName: _logName,
        ),
      ),
      userId: userId,
      personality: canonicalPersonality,
      vibeAnalyzer: _vibeAnalyzer,
      isConnectionWorthy: _isConnectionWorthy,
      updateDiscoveredNodes: _updateDiscoveredNodes,
      onWorthyNodes: (worthyNodes, compatibilityByNodeId) {
        unawaited(_maybeApplyPassiveAi2AiLearning(
          userId: userId,
          localPersonality: canonicalPersonality,
          nodes: worthyNodes,
          compatibilityByNodeId: compatibilityByNodeId,
        ));
      },
      throwOnError: throwOnError,
      buildDiscoveryException: (error) =>
          AI2AIConnectionException('Discovery failed: $error'),
      logger: _logger,
      logName: _logName,
    );
  }

  Future<ConnectionMetrics?> establishAI2AIConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
  ) async {
    final canonicalPersonality =
        await _canonicalizePersonality(localUserId, localPersonality);
    _currentUserId = localUserId;
    _currentPersonality = canonicalPersonality;

    await Ai2AiConnectionGovernanceOrchestrationLane.recordPlan(
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: localUserId,
      localAgentId: canonicalPersonality.agentId,
      remoteNode: remoteNode,
      canonicalPeerMetadata: _canonicalPeerMetadataForNode(
        localPersonality: canonicalPersonality,
        remoteNode: remoteNode,
      ),
      logger: _logger,
      logName: _logName,
      onRecorded: (subjectId, recordId) {
        _ai2aiPlanGovernanceRecordIdsByRemoteNodeId[subjectId] = recordId;
      },
    );

    final connection = await ConnectionAttemptOrchestrationLane.establish(
      isConnecting: _isConnecting,
      setIsConnecting: (value) => _isConnecting = value,
      connectionCooldowns: _connectionCooldowns,
      activeConnections: _activeConnections,
      localUserId: localUserId,
      localPersonality: canonicalPersonality,
      remoteNode: remoteNode,
      vibeAnalyzer: _vibeAnalyzer,
      connectionManager: _connectionManager,
      isConnectionWorthy: _isConnectionWorthy,
      packetCodec: _meshPacketCodec,
      signalKeyManager: _signalKeyManager,
      knotWeavingService: _knotWeavingService,
      knotStorageService: _knotStorageService,
      logger: _logger,
      logName: _logName,
    );

    await Ai2AiConnectionGovernanceOrchestrationLane.recordOutcome(
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: localUserId,
      localAgentId: canonicalPersonality.agentId,
      remoteNode: remoteNode,
      connection: connection,
      canonicalPeerMetadata: connection?.learningOutcomes ??
          _canonicalPeerMetadataForNode(
            localPersonality: canonicalPersonality,
            remoteNode: remoteNode,
          ),
      reason: connection == null ? 'connection_attempt_failed' : null,
      logger: _logger,
      logName: _logName,
      onRecorded: (subjectId, recordId) {
        _ai2aiOutcomeGovernanceRecordIdsBySubjectId[subjectId] = recordId;
      },
    );

    if (connection != null) {
      _remoteNodeByConnectionId[connection.connectionId] = remoteNode;
    }

    return connection;
  }

  Future<PersonalityProfile> _canonicalizePersonality(
    String userId,
    PersonalityProfile personality,
  ) {
    return _canonicalVibeProjectionService.canonicalizeUserProfile(
      userId: userId,
      profile: personality,
    );
  }

  Future<void> manageActiveConnections() async {
    await ConnectionManagementOrchestrationLane.runActiveManagement(
      activeConnections: _activeConnections,
      completeConnection: _completeConnection,
      calculateAIPleasureScore: calculateAIPleasureScore,
      logger: _logger,
      logName: _logName,
    );
  }

  int getActiveConnectionCount() => _activeConnections.length;

  Future<double> calculateAIPleasureScore(ConnectionMetrics connection) async {
    return AIPleasureScoreLane.calculate(
      connection: connection,
      prefs: _prefs,
      logger: _logger,
      logName: _logName,
    );
  }

  List<ConnectionSummary> getActiveConnectionSummaries() {
    return ConnectionSummaryOrchestrationLane.fromActiveConnections(
      _activeConnections.values,
    );
  }

  List<ConnectionMetrics> getActiveConnections() =>
      _activeConnections.values.toList();

  Future<void> shutdown() async {
    _logger.info('Shutting down orchestration', tag: _logName);
    _isInitialized = false;

    await OrchestrationShutdownLane.stopRuntime(
      discoveryTimer: _discoveryTimer,
      connectionMaintenanceTimer: _connectionMaintenanceTimer,
      bleInboxPoller: _bleInboxPoller,
      meshCustodyReplayPoller: _meshCustodyReplayPoller,
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
      onResetNetworkDensity: () =>
          _adaptiveMeshService?.updateNetworkDensity(0),
      onClearCurrentUser: () {
        _currentUserId = null;
      },
      logger: _logger,
      logName: _logName,
    );

    _ai2aiPlanGovernanceRecordIdsByRemoteNodeId.clear();
    _ai2aiOutcomeGovernanceRecordIdsBySubjectId.clear();
    _remoteNodeByConnectionId.clear();
  }

  void _startBleInboxProcessing() {
    final inboundDecodeLane = _meshInboundDecodeLane;
    if (inboundDecodeLane == null) {
      return;
    }
    _bleInboxPoller =
        RuntimeServicesStartupOrchestrationLane.startBleInboxProcessing(
      allowBleSideEffects: _allowBleSideEffects,
      existingPoller: _bleInboxPoller,
      inboundDecodeLane: inboundDecodeLane,
      seenBleMessageHashes: _seenBleMessageHashes,
      prefs: _prefs,
      prefsKeyAi2AiLearningEnabled: _prefsKeyAi2AiLearningEnabled,
      currentUserId: _currentUserId,
      currentAgentId: _currentPersonality?.agentId ?? _localBleNodeId,
      ai2aiChatEventIntakeService: _ai2aiChatEventIntakeService,
      personalityLearning: _connectionManager.personalityLearning,
      adaptiveMeshService: _adaptiveMeshService,
      seenLearningInsightIds: _seenLearningInsightIds,
      lastAi2AiLearningAtByPeerId: _lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: _applyInsightForPeer,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      localNodeId: _localBleNodeId,
      bloomFilters: _bloomFilters,
      discoveredNodes: _discoveredNodes,
      discovery: _deviceDiscovery,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      packetCodec: _meshPacketCodec,
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      trustedAnnounceEnforcementEnabled: _trustedMeshAnnounceEnforcementEnabled,
      persistSeenBleHashesIfNeeded: _persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded:
          _persistSeenLearningInsightIdsIfNeeded,
      logger: _logger,
      logName: _logName,
    );
    _meshCustodyReplayPoller =
        RuntimeServicesStartupOrchestrationLane.startMeshCustodyReplay(
      allowBleSideEffects: _allowBleSideEffects,
      existingPoller: _meshCustodyReplayPoller,
      discovery: _deviceDiscovery,
      packetCodec: _meshPacketCodec,
      discoveredNodes: _discoveredNodes,
      localNodeId: _localBleNodeId,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: _currentUserId,
      localAgentId: _currentPersonality?.agentId ?? _localBleNodeId,
      privacyMode: _meshPrivacyMode(),
      reticulumTransportControlPlaneEnabled:
          _reticulumMeshTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: _trustedMeshAnnounceEnforcementEnabled,
      logger: _logger,
      logName: _logName,
    );
  }

  String _meshPrivacyMode() {
    return _isFederatedLearningParticipationEnabled()
        ? MeshTransportPrivacyMode.federatedCloud
        : MeshTransportPrivacyMode.privateMesh;
  }

  Future<void> _refreshTransportFeatureFlags(String? userId) async {
    if (_featureFlagService == null) {
      _reticulumMeshTransportControlPlaneEnabled = false;
      _trustedMeshAnnounceEnforcementEnabled = false;
      return;
    }
    _reticulumMeshTransportControlPlaneEnabled =
        await _featureFlagService.isEnabled(
      GovernanceFeatureFlags.reticulumMeshTransportControlPlaneV1,
      userId: userId,
      defaultValue: false,
    );
    _trustedMeshAnnounceEnforcementEnabled =
        _reticulumMeshTransportControlPlaneEnabled &&
            await _featureFlagService.isEnabled(
              GovernanceFeatureFlags.trustedMeshAnnounceEnforcementV1,
              userId: userId,
              defaultValue: false,
            );
  }

  bool _isFederatedLearningParticipationEnabled() {
    return RuntimeServicesStartupOrchestrationLane
        .isFederatedLearningParticipationEnabled(
      prefs: _prefs,
      prefsKeyFederatedLearningParticipation:
          _prefsKeyFederatedLearningParticipation,
    );
  }

  void _startFederatedCloudSync() {
    unawaited(() async {
      final handles =
          await RuntimeServicesStartupOrchestrationLane.startFederatedCloudSync(
        isTestBinding: _isTestBinding,
        connectivity: _connectivity,
        syncFederatedCloudQueue: syncFederatedCloudQueue,
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
    await FederatedCloudOrchestrationLane.enqueueLearningInsightDelta(
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      prefs: _prefs,
      prefsKeyQueue: _prefsKeyFederatedCloudQueue,
      payload: payload,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> syncFederatedCloudQueue() async {
    _lastFederatedCloudSyncAttemptMs =
        await FederatedCloudOrchestrationLane.syncQueue(
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      lastFederatedCloudSyncAttemptMs: _lastFederatedCloudSyncAttemptMs,
      prefs: _prefs,
      prefsKeyQueue: _prefsKeyFederatedCloudQueue,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _persistSeenLearningInsightIdsIfNeeded() async {
    _lastSeenInsightsPersistMs =
        await LearningInsightSeenIdsPersistenceLane.persistIfNeeded(
      prefs: _prefs,
      prefsKey: _prefsKeySeenLearningInsightIds,
      seenLearningInsightIds: _seenLearningInsightIds,
      lastPersistMs: _lastSeenInsightsPersistMs,
    );
  }

  // Private helper methods
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
    return LearningInsightApplyOrchestrationLane.applyForPeer(
      eventModeEnabled: _isEventModeEnabled(),
      userId: userId,
      personalityLearning: personalityLearning,
      peerId: peerId,
      insight: insight,
      now: now,
      source: source,
      insightId: insightId,
      learningQuality: learningQuality,
      deltas: deltas,
      eventModeLearningBuffer: _eventModeLearningBuffer,
      lastAi2AiLearningAtByPeerId: _lastAi2AiLearningAtByPeerId,
      urkActivationDispatcher: _urkActivationDispatcher,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _primeOfflineSignalPreKeyBundleInSession({
    required DiscoveredDevice device,
    required BleGattSession session,
  }) async {
    await Ai2AiDiscoveryPrekeyOrchestrationLane
        .primeOfflineSignalPreKeyBundleInSessionForOrchestrator(
      allowBleSideEffects: _allowBleSideEffects,
      signalKeyManager: _signalKeyManager,
      packetCodec: _meshPacketCodec,
      device: device,
      session: session,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      federatedLearningParticipationEnabled: _adaptiveMeshService != null &&
          _isFederatedLearningParticipationEnabled(),
      localBleNodeId: _localBleNodeId,
      discovery: _deviceDiscovery,
      discoveredNodes: _discoveredNodes,
      adaptiveMeshService: _adaptiveMeshService,
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: _currentUserId,
      localAgentId: _currentPersonality?.agentId ?? _localBleNodeId,
      privacyMode: _meshPrivacyMode(),
      reticulumTransportControlPlaneEnabled:
          _reticulumMeshTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: _trustedMeshAnnounceEnforcementEnabled,
      logger: _logger,
      logName: _logName,
    );
  }

  void _updateDiscoveredNodes(List<AIPersonalityNode> nodes) {
    DiscoveryNodeOrchestrationLane.updateDiscoveredNodes(
      nodes: nodes,
      discoveredNodes: _discoveredNodes,
      nearbyVibes: _nearbyVibes,
      adaptiveMeshService: _adaptiveMeshService,
    );
  }

  bool _isConnectionWorthy(VibeCompatibilityResult compatibility) {
    return DiscoveryNodeOrchestrationLane.isConnectionWorthy(
      compatibility: compatibility,
      logger: _logger,
      logName: _logName,
    );
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

  int? getNetworkDensity() => _adaptiveMeshService?.networkDensity;

  Future<ConnectionMetrics?> _completeConnection(ConnectionMetrics connection,
      {String? reason}) async {
    var completedConnection = await ConnectionCompletionLane.complete(
      connection: connection,
      reason: reason,
      logger: _logger,
      logName: _logName,
    );

    final remoteNode = _remoteNodeByConnectionId[connection.connectionId];
    if (completedConnection != null &&
        remoteNode != null &&
        _currentUserId != null &&
        _currentPersonality != null) {
      final learningResult =
          await _peerInteractionOutcomeLearningService.recordCompletedInteraction(
        localUserId: _currentUserId!,
        localAgentId: _currentPersonality!.agentId,
        remoteNode: remoteNode,
        connection: completedConnection,
        completionReason: reason,
      );
      if (learningResult.applied) {
        completedConnection = completedConnection.updateDuringInteraction(
          additionalOutcomes: <String, dynamic>{
            'governed_peer_learning_mutations': learningResult.receipts.length,
          },
        );
      }
      await Ai2AiConnectionGovernanceOrchestrationLane.recordOutcome(
        governanceBindingService: _ai2aiMeshGovernanceBindingService,
        localUserId: _currentUserId!,
        localAgentId: _currentPersonality!.agentId,
        remoteNode: remoteNode,
        connection: completedConnection,
        canonicalPeerMetadata: completedConnection.learningOutcomes,
        reason: reason,
        logger: _logger,
        logName: _logName,
        onRecorded: (subjectId, recordId) {
          _ai2aiOutcomeGovernanceRecordIdsBySubjectId[subjectId] = recordId;
        },
      );
    }

    if (completedConnection != null || reason != null) {
      _remoteNodeByConnectionId.remove(connection.connectionId);
    }

    return completedConnection;
  }

  Map<String, dynamic>? _canonicalPeerMetadataForNode({
    required PersonalityProfile localPersonality,
    required AIPersonalityNode remoteNode,
  }) {
    final remoteContext = remoteNode.resolvedPeerContext;
    if (remoteContext == null) {
      return null;
    }
    final localPayload = _canonicalPeerResolutionService.buildLocalPayload(
      localPersonality: localPersonality,
    );
    final compatibility = _canonicalPeerResolutionService.computeCompatibility(
      localPayload: localPayload,
      remoteContext: remoteContext,
    );
    return <String, dynamic>{
      ..._canonicalPeerResolutionService.compatibilityMetadata(
        compatibility,
        remoteContext: remoteContext,
      ),
      'peer_why_summary': _canonicalPeerResolutionService
          .buildPeerCompatibilityWhySnapshot(
            localPayload: localPayload,
            remoteContext: remoteContext,
            result: compatibility,
          )
          .summary,
    };
  }

  UserVibe? getCurrentVibe() => null;

  Future<AnonymousUser> anonymizeUserForTransmission(
    UnifiedUser user,
    String agentId,
    PersonalityProfile? personalityProfile, {
    bool isAdmin = false,
  }) async {
    return PayloadRealtimeOrchestrationLane.anonymizeUserForTransmission(
      anonymizationService: _anonymizationService,
      user: user,
      agentId: agentId,
      personalityProfile: personalityProfile,
      isAdmin: isAdmin,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _setupRealtimeListeners() async {
    await PayloadRealtimeOrchestrationLane.setupRealtimeListeners(
      coordinator: _realtimeCoordinator,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> forwardOrganicSpotDiscovery(
    Map<String, dynamic> signal,
  ) async {
    await MeshPublicForwardingOrchestrationLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      packetCodec: _meshPacketCodec,
      discovery: _deviceDiscovery,
      discoveredNodes: _discoveredNodes,
      localNodeId: _localBleNodeId,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: _currentUserId,
      localAgentId: _currentPersonality?.agentId ?? _localBleNodeId,
      trustedAnnounceEnforcementEnabled: _trustedMeshAnnounceEnforcementEnabled,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> forwardLocalityAgentUpdate(Map<String, dynamic> message) async {
    await MeshPublicForwardingOrchestrationLane.forwardLocalityAgentUpdate(
      allowBleSideEffects: _allowBleSideEffects,
      federatedLearningParticipationEnabled:
          _isFederatedLearningParticipationEnabled(),
      localNodeId: _localBleNodeId,
      message: message,
      adaptiveMeshService: _adaptiveMeshService,
      bloomFilters: _bloomFilters,
      packetCodec: _meshPacketCodec,
      discovery: _deviceDiscovery,
      discoveredNodes: _discoveredNodes,
      peerNodeIdByDeviceId: _peerNodeIdByDeviceId,
      governanceBindingService: _ai2aiMeshGovernanceBindingService,
      localUserId: _currentUserId,
      localAgentId: _currentPersonality?.agentId ?? _localBleNodeId,
      privacyMode: _meshPrivacyMode(),
      reticulumTransportControlPlaneEnabled:
          _reticulumMeshTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: _trustedMeshAnnounceEnforcementEnabled,
      logger: _logger,
      logName: _logName,
    );
  }
}
