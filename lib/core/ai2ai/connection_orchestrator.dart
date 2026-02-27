import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai/core/ai2ai/discovery/event_mode_candidate.dart';
import 'package:avrai/core/ai2ai/discovery/discovered_node_registry.dart';
import 'package:avrai/core/ai2ai/discovery/discovery_postprocess_lane.dart';
import 'package:avrai/core/ai2ai/discovery/ai2ai_discovery_execution_lane.dart';
import 'package:avrai/core/ai2ai/discovery/deterministic_test_vibe_builder_lane.dart';
import 'package:avrai/core/ai2ai/routing/connection_routing_policy.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_broadcast_flags_lane.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_initiator_policy.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_target_selector.dart';
import 'package:avrai/core/ai2ai/routing/event_mode_scan_window_lane.dart';
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
import 'package:avrai/core/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai/core/ai2ai/trust/payload_anonymization_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_lifecycle_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_startup_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_lifecycle_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_renewal_lane.dart';
import 'package:avrai/core/ai2ai/resilience/inactive_session_cleanup_lane.dart';
import 'package:avrai/core/ai2ai/resilience/session_expiry_lane.dart';
import 'package:avrai/core/ai2ai/resilience/connection_establishment_lane.dart';
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
import 'package:avrai/core/ai2ai/resilience/connection_worthiness_validation_lane.dart';
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

/// OUR_GUTS.md: "AI2AI vibe-based connections that enable cross-personality learning while preserving privacy"
/// Comprehensive connection orchestrator that manages AI2AI personality matching and learning
/// Enhanced with Supabase Realtime for live AI2AI communication
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
  /// Previous quality scores per agent ID (for detecting quality changes)
  final Map<String, double> _previousQualityScores = {};

  /// Quality change threshold for triggering key rotation (AI2AI-specific)
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

  /// Snapshot of currently known nearby AI nodes (for tests/debug tooling).
  @visibleForTesting
  List<AIPersonalityNode> debugDiscoveredNodesSnapshot() {
    return _discoveredNodes.values.toList();
  }

  /// Deterministic, no-BLE simulation of the walk-by hot path.
  ///
  /// This bypasses platform BLE and uses `device.personalityData` only.
  /// Intended for unit tests / CI validation when hardware isn’t available.
  @visibleForTesting
  Future<void> debugSimulateWalkByHotPath({
    required String userId,
    required PersonalityProfile personality,
    required List<DiscoveredDevice> devices,
  }) async {
    _currentUserId = userId;
    _currentPersonality = personality;

    final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    final localVibe = DeterministicTestVibeBuilderLane.build(
      userId: userId,
      personality: personality,
    );

    for (final device in devices) {
      if (device.type != DeviceType.bluetooth) continue;
      final rssi = device.signalStrength;
      if (rssi == null || rssi < _hotRssiThresholdDbm) continue;
      final personalityData = device.personalityData;
      if (personalityData == null) continue;

      final vibe = AnonymizedVibeMapper.toUserVibe(personalityData);
      final node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: device.proximityScore,
      );

      final compatibility =
          await _vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
      if (!_isConnectionWorthy(compatibility)) continue;

      _updateDiscoveredNodes(<AIPersonalityNode>[node]);
    }
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

  /// Inject or update the realtime service after construction to avoid DI cycles
  void setRealtimeService(AI2AIBroadcastService service) {
    _realtimeService = service;
  }

  /// Update personality advertising when personality evolves
  /// Call this after personality profile is updated
  /// This method is automatically called via PersonalityLearning callback
  Future<void> updatePersonalityAdvertising(
    String userId,
    PersonalityProfile updatedPersonality,
  ) async {
    if (_advertisingService == null) {
      return;
    }

    // Respect the user-controlled discovery switch.
    final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    // Keep a current reference for fast-path compatibility checks.
    _currentPersonality = updatedPersonality;

    try {
      _logger.info(
          'Updating personality advertising after evolution (generation ${updatedPersonality.evolutionGeneration})',
          tag: _logName);

      final eventModeEnabled = _isEventModeEnabled();
      final vibe =
          await _vibeAnalyzer.compileUserVibe(userId, updatedPersonality);
      final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

      final success = await _advertisingService.updatePersonalityData(
        personalityData: anonymized,
        nodeId: _localBleNodeId,
        eventModeEnabled: eventModeEnabled,
        connectOk: _lastAdvertisedConnectOk,
        brownout: _lastAdvertisedBrownout,
      );

      if (success) {
        _logger.info('Personality advertising updated successfully',
            tag: _logName);
      } else {
        _logger.warn('Failed to update personality advertising', tag: _logName);
      }
    } catch (e) {
      _logger.error('Error updating personality advertising',
          error: e, tag: _logName);
    }
  }

  /// Set up automatic personality advertising updates
  /// Call this to enable automatic updates when personality evolves
  void setupAutomaticAdvertisingUpdates() {
    // This will be called from injection container after PersonalityLearning is created
    // The callback will be set up there to avoid circular dependencies
  }

  /// Initialize the AI2AI connection orchestration system
  Future<void> initializeOrchestration(
      String userId, PersonalityProfile personality) async {
    if (_isInitialized) {
      _logger.debug(
          'Orchestration already initialized; skipping reinitialization',
          tag: _logName);
      return;
    }
    try {
      _logger.info('Initializing orchestration for user: $userId',
          tag: _logName);

      // Respect the user-controlled discovery switch.
      // If disabled, do not start advertising, scanning, or background timers.
      final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
      if (!discoveryEnabled) {
        _logger.info(
          'AI2AI discovery is disabled by user setting; skipping orchestration init',
          tag: _logName,
        );
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_orchestration_init_skipped',
            occurredAt: DateTime.now(),
            entityType: 'user',
            entityId: userId,
            payload: <String, Object?>{
              'reason': 'discovery_disabled',
            },
          ));
        }
        return;
      }

      _currentUserId = userId;
      _currentPersonality = personality;

      // Ensure stable (rotating) offline BLE node id + load replay protection state.
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
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_started',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'allow_ble_side_effects': _allowBleSideEffects,
            'is_test_binding': _isTestBinding,
            'is_web': kIsWeb,
            'platform': defaultTargetPlatform.name,
            'ble_node_id': _localBleNodeId,
          },
        ));
      }

      // Android-only: keep BLE work alive in the background.
      // Note: Android requires a foreground service notification; cannot be truly "silent".
      if (_allowBleSideEffects &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final started = await BleForegroundService.startService();
        if (started) {
          _logger.info('Android BLE foreground service started', tag: _logName);
          if (LedgerAuditV0.isEnabled) {
            unawaited(LedgerAuditV0.tryAppend(
              domain: LedgerDomainV0.deviceCapability,
              eventType: 'ai2ai_ble_foreground_service_started',
              occurredAt: DateTime.now(),
              payload: const <String, Object?>{
                'platform': 'android',
              },
            ));
          }
        } else {
          _logger.warn('Android BLE foreground service failed to start',
              tag: _logName);
          if (LedgerAuditV0.isEnabled) {
            unawaited(LedgerAuditV0.tryAppend(
              domain: LedgerDomainV0.deviceCapability,
              eventType: 'ai2ai_ble_foreground_service_failed',
              occurredAt: DateTime.now(),
              payload: const <String, Object?>{
                'platform': 'android',
              },
            ));
          }
        }
      }

      // Publish Signal prekey payload for offline bootstrap (Mode 2).
      // This is best-effort: if Signal isn't initialized yet, advertising can still proceed.
      if (_allowBleSideEffects) {
        await PrekeyPayloadPublishLane.publishIfAvailable(
          signalKeyManager: _signalKeyManager,
          localBleNodeId: _localBleNodeId,
          logger: _logger,
          logName: _logName,
        );
      }

      // Initialize realtime service if available
      if (_realtimeService != null) {
        final realtimeInitialized = await _realtimeService!.initialize();
        if (realtimeInitialized) {
          _logger.info('Realtime Service initialized', tag: _logName);
          await _setupRealtimeListeners();
        } else {
          _logger.warn('Realtime Service failed to initialize', tag: _logName);
        }
      }

      // Start personality advertising (make this device discoverable).
      // BLE side-effects are disabled by default on iOS (simulator safety).
      if (_allowBleSideEffects && _advertisingService != null) {
        final eventModeEnabled = _isEventModeEnabled();
        final vibe = await _vibeAnalyzer.compileUserVibe(userId, personality);
        final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

        final advertisingStarted = await _advertisingService.startAdvertising(
          personalityData: anonymized,
          nodeId: _localBleNodeId,
          eventModeEnabled: eventModeEnabled,
          connectOk: false,
          brownout: false,
        );
        if (advertisingStarted) {
          _logger.info('Personality advertising started', tag: _logName);
        } else {
          _logger.warn('Personality advertising failed to start',
              tag: _logName);
        }
      }

      // Start device discovery (find other devices).
      // Performance optimization: Add throttling delays between BLE operations
      // to reduce context switching and improve battery life.
      if (_allowBleSideEffects && _deviceDiscovery != null) {
        // Continuous scanning: back-to-back scan windows (walk-by capture).
        _deviceDiscovery.onDevicesDiscovered(_onDevicesDiscoveredHotPath);
        await _deviceDiscovery.startDiscovery(
          scanInterval: Duration.zero,
          scanWindow: _hotScanWindow,
          deviceTimeout: _hotDeviceTimeout,
        );
        _logger.info('Device discovery started', tag: _logName);

        // Throttle: Add delay before starting battery scheduler to reduce context switching
        await Future.delayed(const Duration(milliseconds: 300));

        // Battery-adaptive scan scheduling (best-effort).
        _batteryScheduler?.stop();
        _batteryScheduler = BatteryAdaptiveBleScheduler(
          discovery: _deviceDiscovery,
          prefs: _prefs,
        );
        await _batteryScheduler!.start();

        // Throttle: Add delay before starting adaptive mesh service
        await Future.delayed(const Duration(milliseconds: 200));

        // Initialize adaptive mesh networking service
        _adaptiveMeshService?.stop();
        _adaptiveMeshService = AdaptiveMeshNetworkingService(
          batteryScheduler: _batteryScheduler!,
          discovery: _deviceDiscovery,
        );
        await _adaptiveMeshService!.start();
      }

      // Throttle: Add delay before starting AI2AI discovery to batch BLE operations
      if (_allowBleSideEffects) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _startAI2AIDiscovery(userId, personality);
      } else {
        _logger.info(
          'BLE side-effects disabled; skipping AI2AI discovery timers',
          tag: _logName,
        );
      }

      // Start processing incoming BLE inbox messages (silent background).
      // This is non-blocking, so no delay needed here.
      if (_allowBleSideEffects) {
        _startBleInboxProcessing();
      }

      // Start federated (hybrid) sync:
      // - Pattern 1: BLE gossip happens opportunistically via learningInsight messages
      // - Pattern 2: Optional cloud aggregation when online (edge function)
      // This is non-blocking, so no delay needed here.
      _startFederatedCloudSync();

      // Throttle: Add delay before connection maintenance to allow BLE operations to stabilize
      await Future.delayed(const Duration(milliseconds: 100));

      // Begin connection maintenance
      await _startConnectionMaintenance();

      _isInitialized = true;
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_completed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: const <String, Object?>{
            'ok': true,
          },
        ));
      }
      _logger.info('Orchestration initialized successfully', tag: _logName);
    } catch (e) {
      _logger.error('Error initializing AI2AI orchestration',
          error: e, tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'error': e.toString(),
          },
        ));
      }
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
    await EventModeScanWindowLane.handle(
      allowBleSideEffects: _allowBleSideEffects,
      currentUserId: _currentUserId,
      hasCurrentPersonality: _currentPersonality != null,
      lastAdvertisedEventModeEnabled: _lastAdvertisedEventModeEnabled,
      onEventModeReset: () {
        _eventModeDeepSyncCount = 0;
        _eventModeLastDeepSyncAtMsByNodeTag.clear();
        _eventModeLastEpochAttempted = -1;
        _eventModeCheckInRunning = false;
      },
      devices: devices,
      hotRssiThresholdDbm: _hotRssiThresholdDbm,
      familiarityByNodeTag: _eventModeFamiliarityByNodeTag,
      batteryScheduler: _batteryScheduler,
      roomCoherenceEngine: _roomCoherenceEngine,
      maybeUpdateEventModeBroadcastFlags: _maybeUpdateEventModeBroadcastFlags,
      eventModeMayInitiate: ({required int epoch}) {
        return EventModeInitiatorPolicy.mayInitiate(
          localBleNodeId: _localBleNodeId,
          epoch: epoch,
          eligibilityPercent: _eventInitiatorEligibilityPct,
        );
      },
      pickEventModeTarget: ({
        required List<EventModeCandidate> candidates,
        required int nowMs,
        required int epoch,
      }) {
        return EventModeTargetSelector.select(
          candidates: candidates,
          nowMs: nowMs,
          epoch: epoch,
          localNodeTagKey: _localNodeTagKey,
          lastDeepSyncAtMsByNodeTag: _eventModeLastDeepSyncAtMsByNodeTag,
          familiarityByNodeTag: _eventModeFamiliarityByNodeTag,
          perNodeDeepSyncCooldownMs: _eventPerNodeDeepSyncCooldownMs,
        );
      },
      eventEpochMs: _eventEpochMs,
      eventCheckInWindowMs: _eventCheckInWindowMs,
      eventMaxDeepSyncPerEvent: _eventMaxDeepSyncPerEvent,
      eventModeDeepSyncCount: _eventModeDeepSyncCount,
      eventModeLastEpochAttempted: _eventModeLastEpochAttempted,
      eventModeCheckInRunning: _eventModeCheckInRunning,
      setEventModeLastEpochAttempted: (epoch) {
        _eventModeLastEpochAttempted = epoch;
      },
      setEventModeCheckInRunning: (running) {
        _eventModeCheckInRunning = running;
      },
      incrementEventModeDeepSyncCount: () {
        _eventModeDeepSyncCount += 1;
      },
      eventModeLastDeepSyncAtMsByNodeTag: _eventModeLastDeepSyncAtMsByNodeTag,
      waitInitiatorJitter: ({required int epoch}) async {
        final jitterMs = EventModeInitiatorPolicy.jitterMs(
          localBleNodeId: _localBleNodeId,
          epoch: epoch,
        );
        if (jitterMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: jitterMs));
        }
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
      sendLearningInsightToPeer: _sendLearningInsightToPeer,
      logger: _logger,
      logName: _logName,
    );
  }

  Future<void> _sendLearningInsightToPeer({
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
  }

  /// Discover nearby AI personalities for potential connections
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
        // #region agent log
        _logger.info(
            'No connectivity available, proceeding with offline discovery',
            tag: _logName);
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _logger.warn('Error checking connectivity: $e, proceeding with discovery',
          tag: _logName);
      // #endregion
    }

    _isDiscovering = true;

    try {
      // #region agent log
      _logger.info('Discovering nearby AI personalities', tag: _logName);
      // #endregion

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
      // #region agent log
      _logger.error('Error discovering AI personalities',
          error: e, tag: _logName);
      // #endregion
      if (throwOnError) {
        throw AI2AIConnectionException('Discovery failed: $e');
      }
      return [];
    } finally {
      _isDiscovering = false;
    }
  }

  /// Establish AI2AI connection based on vibe compatibility
  Future<ConnectionMetrics?> establishAI2AIConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
  ) async {
    if (_isConnecting) {
      _logger.debug('Connection establishment already in progress',
          tag: _logName);
      return null;
    }

    // Check connection cooldown
    if (ConnectionRoutingPolicy.isInCooldown(
      cooldowns: _connectionCooldowns,
      nodeId: remoteNode.nodeId,
    )) {
      _logger.debug('Connection to ${remoteNode.nodeId} is in cooldown period',
          tag: _logName);
      return null;
    }

    // Check active connection limits
    if (_activeConnections.length >= VibeConstants.maxSimultaneousConnections) {
      _logger.warn('Maximum simultaneous connections reached', tag: _logName);
      return null;
    }

    final shouldAttemptConnection =
        await ConnectionWorthinessValidationLane.validateOrCooldown(
      vibeAnalyzer: _vibeAnalyzer,
      localUserId: localUserId,
      localPersonality: localPersonality,
      remoteNode: remoteNode,
      isConnectionWorthy: _isConnectionWorthy,
      setCooldown: (nodeId) {
        ConnectionRoutingPolicy.setCooldown(
          cooldowns: _connectionCooldowns,
          nodeId: nodeId,
        );
      },
      logger: _logger,
      logName: _logName,
    );
    if (!shouldAttemptConnection) {
      return null;
    }

    _isConnecting = true;

    try {
      // #region agent log
      _logger.info('Establishing connection with node: ${remoteNode.nodeId}',
          tag: _logName);
      // #endregion

      final establishedConnection = await _connectionManager.establish(
        localUserId,
        localPersonality,
        remoteNode,
        (localVibe, remote, comp, metrics) =>
            ConnectionEstablishmentLane.establish(
          protocol: _protocol,
          signalKeyManager: _signalKeyManager,
          knotWeavingService: _knotWeavingService,
          knotStorageService: _knotStorageService,
          localVibe: localVibe,
          remoteNode: remote,
          compatibility: comp,
          initialMetrics: metrics,
          localAgentId: localPersonality.agentId,
          remoteAgentId: remoteNode.nodeId,
          logger: _logger,
          logName: _logName,
        ),
      );

      if (establishedConnection != null) {
        // Store active connection
        _activeConnections[establishedConnection.connectionId] =
            establishedConnection;

        // Schedule connection management
        _scheduleConnectionManagement(establishedConnection);

        // #region agent log
        _logger.info(
            'Connection established (ID: ${establishedConnection.connectionId})',
            tag: _logName);
        // #endregion
        return establishedConnection;
      } else {
        _logger.warn('Failed to establish connection', tag: _logName);
        ConnectionRoutingPolicy.setCooldown(
          cooldowns: _connectionCooldowns,
          nodeId: remoteNode.nodeId,
        );
        return null;
      }
    } catch (e) {
      // #region agent log
      _logger.error('Error establishing connection', error: e, tag: _logName);
      // #endregion
      ConnectionRoutingPolicy.setCooldown(
        cooldowns: _connectionCooldowns,
        nodeId: remoteNode.nodeId,
      );
      return null;
    } finally {
      _isConnecting = false;
    }
  }

  /// Manage active AI2AI connections for learning and quality
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

  /// Get count of active connections
  int getActiveConnectionCount() {
    return _activeConnections.length;
  }

  /// Calculate AI pleasure score for connection quality
  Future<double> calculateAIPleasureScore(ConnectionMetrics connection) async {
    return AIPleasureScoreLane.calculate(
      connection: connection,
      prefs: _prefs,
      logger: _logger,
      logName: _logName,
    );
  }

  /// Get active connection summaries for monitoring
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

  /// Get active connections for UI display
  /// Returns list of ConnectionMetrics for active connections
  List<ConnectionMetrics> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Cleanup and shutdown orchestration
  Future<void> shutdown() async {
    _logger.info('Shutting down orchestration', tag: _logName);
    _isInitialized = false;

    // Cancel timers
    _discoveryTimer?.cancel();
    _connectionMaintenanceTimer?.cancel();
    _bleInboxPoller?.cancel();
    _federatedCloudSyncTimer?.cancel();
    await _federatedCloudConnectivitySub?.cancel();
    _federatedCloudConnectivitySub = null;
    await _batteryScheduler?.stop();
    _batteryScheduler = null;
    await _adaptiveMeshService?.stop();
    _adaptiveMeshService = null;

    // Stop discovery + advertising (best-effort).
    try {
      _deviceDiscovery?.stopDiscovery();
    } catch (e) {
      _logger.debug('Error stopping device discovery: $e', tag: _logName);
    }
    try {
      await _advertisingService?.stopAdvertising();
    } catch (e) {
      _logger.debug('Error stopping personality advertising: $e',
          tag: _logName);
    }

    // Android-only: stop BLE foreground runtime if we started it.
    if (_allowBleSideEffects &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        await BleForegroundService.stopService();
      } catch (e) {
        _logger.debug('Error stopping Android BLE foreground service: $e',
            tag: _logName);
      }
    }

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

  /// Public API for [BackupSyncCoordinator] – flushes the federated cloud queue.
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

  /// Handle incoming user-to-user chat message routed through AI2AI mesh
  ///
  /// Routes user chat messages (business-expert or business-business) to the
  /// appropriate chat service for storage and UI display. The message type is
  /// determined from the unencrypted binary packet header (MessageType.userChat),
  /// allowing routing before decryption.
  Future<void> _handleIncomingUserChat(ProtocolMessage message) async {
    await IncomingUserChatProcessingLane.handle(
      message: message,
      handleIncomingBusinessExpertChat: _handleIncomingBusinessExpertChat,
      handleIncomingBusinessBusinessChat: _handleIncomingBusinessBusinessChat,
      logger: _logger,
      logName: _logName,
    );
  }

  /// Handle incoming business-expert chat message
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

  /// Handle incoming business-business chat message
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

  /// Manage Signal Protocol session lifecycle for AI2AI connections
  ///
  /// Implements AI2AI-specific session lifecycle management:
  /// - Session expiration based on connection quality
  /// - Automatic cleanup for inactive AI agents
  /// - Session renewal for frequent/active connections
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

  /// Manage prekey bundle rotation and refresh (Enhanced BLE distribution)
  ///
  /// Implements automatic prekey bundle management:
  /// - Cleanup expired prekey bundles
  /// - Proactive refresh of bundles expiring soon
  /// - Distribution of fresh bundles via BLE to active connections
  Future<void> _managePreKeyBundleRotation() async {
    await PrekeyBundleRotationLane.run(
      signalKeyManager: _signalKeyManager,
      activeConnections: _activeConnections.values,
      logger: _logger,
      logName: _logName,
    );
  }

  /// Expire sessions based on connection quality (AI2AI-specific)
  ///
  /// Uses SignalSessionManager's quality-based methods to expire sessions
  /// for connections with poor quality.
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

  /// Clean up inactive sessions (no activity for extended period)
  ///
  /// Sessions are cleaned up if they haven't been used for a certain period
  /// and don't have an active connection. High-quality connections are maintained
  /// even if temporarily inactive.
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

  /// Renew sessions for frequent/active connections
  ///
  /// Uses SignalSessionManager's quality-based methods to renew sessions
  /// for high-quality, active connections.
  Future<void> _renewActiveSessions(SignalSessionManager sessionManager) async {
    await SessionRenewalLane.run(
      sessionManager: sessionManager,
      activeConnections: _activeConnections.values,
      logger: _logger,
      logName: _logName,
    );
  }

  /// Rotate keys based on connection quality changes (AI2AI-specific)
  ///
  /// Implements automatic key rotation triggered by significant connection quality changes.
  /// Rotates keys when quality improves significantly (fresh keys for high-value connections)
  /// or degrades significantly (security rotation for compromised connections).
  ///
  /// **AI2AI-Specific:**
  /// - Rotation triggered by quality change threshold (30%)
  /// - Integrates with Signal Protocol re-keying
  /// - Prevents excessive rotation (cooldown period)
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

  /// Forward prekey bundle through mesh network (Phase 3.2: Mesh forwarding integration)
  ///
  /// Forwards prekey bundle to nearby devices for multi-hop key exchange.
  /// This enables key exchange even without direct connection.
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

  /// Prioritize discovered nodes based on compatibility and trust
  /// Note: DiscoveryManager already handles prioritization, this is reserved for future use
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

    // #region agent log
    _logger.debug(
        'Prioritized ${nodes.length} nodes to top ${prioritized.length} connections',
        tag: _logName);
    // #endregion

    return prioritized;
  }

  /// Determine if a connection is worthy based on compatibility thresholds
  bool _isConnectionWorthy(VibeCompatibilityResult compatibility) {
    final result = ConnectionRoutingPolicy.evaluateWorthiness(compatibility);

    // #region agent log
    if (!result.isWorthy) {
      _logger.debug(
          'Connection not worthy: ${result.reason}; opportunities=${compatibility.learningOpportunities.length}',
          tag: _logName);
    }
    // #endregion

    return result.isWorthy;
  }

  /// Get current battery level (for rate limiting integration)
  ///
  /// Returns battery level (0-100) or null if battery scheduler not available.
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

  /// Get current network density (for rate limiting integration)
  ///
  /// Returns network density or null if adaptive mesh service not available.
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

  /// Get current user vibe for AI2AI matching (stub; can be wired to cache)
  UserVibe? getCurrentVibe() {
    return null;
  }

  /// Convert UnifiedUser to AnonymousUser for AI2AI transmission
  ///
  /// **CRITICAL:** This method ensures no personal data is transmitted in AI2AI network.
  /// All user data must be converted to AnonymousUser before transmission.
  ///
  /// **Throws:**
  /// - Exception if anonymizationService is not available
  /// - Exception if conversion fails
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

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  ///
  /// This is a safety check to prevent accidental personal data leaks.
  /// All user data must be converted to AnonymousUser before transmission.
  void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    PayloadAnonymizationLane.validateNoUnifiedUserInPayload(payload);
  }

  /// Set up realtime listeners for AI2AI communication (safe no-op if unavailable)
  Future<void> _setupRealtimeListeners() async {
    await RealtimeListenerCallbacksLane.setup(
      coordinator: _realtimeCoordinator,
      validateNoUnifiedUserInPayload: validateNoUnifiedUserInPayload,
      logger: _logger,
      logName: _logName,
    );
  }

  /// Forward an organic spot discovery signal through the AI2AI mesh.
  ///
  /// When this user's AI detects an unregistered location pattern
  /// (e.g., repeatedly visiting a park that's not in Google Places),
  /// share an anonymized signal so other nearby AIs can boost their
  /// confidence for the same location.
  ///
  /// Privacy: Only shares geohash + visit count. Never raw GPS or user ID.
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

  /// NEW: Forward locality agent update through mesh network
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

  /// NEW: Handle incoming locality agent update from mesh
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

  /// Handle incoming organic spot discovery signal from mesh.
  ///
  /// When another user's AI detects an unregistered location that people
  /// keep visiting (parks, garages, hidden gems), it shares an anonymized
  /// signal via the mesh. This boosts our confidence that the location is
  /// meaningful and may surface it to our user as a "discovered spot."
  ///
  /// Privacy: Only receives geohash + visit count. Never raw GPS or user ID.
  Future<void> _handleIncomingOrganicSpotDiscovery(
      ProtocolMessage message) async {
    await IncomingMeshSignalHandlersLane.handleOrganicSpotDiscovery(
      message: message,
      currentUserId: _currentUserId,
      logger: _logger,
      logName: _logName,
    );
  }

  /// NEW: Forward locality agent update gossip (similar to learning insight gossip)
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

  /// Get or create Bloom filter for geographic scope (AI2AI-specific)
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

// Supporting classes for AI2AI connection orchestration
// moved to core/ai2ai/aipersonality_node.dart

class PendingConnection {
  final String localUserId;
  final AIPersonalityNode remoteNode;
  final VibeCompatibilityResult compatibility;
  final DateTime requestedAt;

  PendingConnection({
    required this.localUserId,
    required this.remoteNode,
    required this.compatibility,
    required this.requestedAt,
  });

  bool get isExpired => DateTime.now().difference(requestedAt).inMinutes > 2;
}

class ConnectionSummary {
  final String connectionId;
  final Duration duration;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;
  final String qualityRating;
  final ConnectionStatus status;
  final int interactionCount;
  final int dimensionsEvolved;

  ConnectionSummary({
    required this.connectionId,
    required this.duration,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
    required this.qualityRating,
    required this.status,
    required this.interactionCount,
    required this.dimensionsEvolved,
  });

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId.substring(0, 8),
      'duration_seconds': duration.inSeconds,
      'compatibility': (compatibility * 100).round(),
      'learning_effectiveness': (learningEffectiveness * 100).round(),
      'ai_pleasure_score': (aiPleasureScore * 100).round(),
      'quality_rating': qualityRating,
      'status': status.toString().split('.').last,
      'interaction_count': interactionCount,
      'dimensions_evolved': dimensionsEvolved,
    };
  }
}

class AI2AIConnectionException implements Exception {
  final String message;

  AI2AIConnectionException(this.message);

  @override
  String toString() => 'AI2AIConnectionException: $message';
}
