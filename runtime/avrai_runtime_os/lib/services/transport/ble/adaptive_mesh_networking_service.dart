import 'dart:async';
import 'dart:developer' as developer;
import 'package:battery_plus/battery_plus.dart';
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy show AdaptiveMeshHopPolicy, MessagePriority, MessageType;
import 'package:avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_network/avra_network.dart';

/// Adaptive mesh networking service
///
/// Automatically adjusts mesh hop limits based on battery, network density,
/// and other conditions. Follows the same pattern as BatteryAdaptiveBleScheduler.
///
/// **Guarantee:** Always maintains at least direct connections (0 hops minimum)
class AdaptiveMeshNetworkingService {
  static const String _logName = 'AdaptiveMeshNetworkingService';

  final Battery _battery;

  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _adaptationTimer;
  int? _currentMaxHops;
  final mesh_policy.MessagePriority _defaultPriority =
      mesh_policy.MessagePriority.medium;
  final mesh_policy.MessageType _defaultMessageType =
      mesh_policy.MessageType.learningInsight;

  // Track network density manually (since DeviceDiscoveryService may not expose it directly)
  int _networkDensity = 0;

  AdaptiveMeshNetworkingService({
    BatteryAdaptiveBleScheduler? batteryScheduler,
    DeviceDiscoveryService? discovery,
    Battery? battery,
  }) : _battery = battery ?? Battery();

  /// Start adaptive mesh networking
  Future<void> start() async {
    // Apply initial policy
    await _adaptHopLimit();

    // Re-adapt periodically (every 2 minutes, same as battery scheduler)
    _adaptationTimer?.cancel();
    _adaptationTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _adaptHopLimit(),
    );

    // Re-adapt on battery state changes
    _batteryStateSub?.cancel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen(
      (_) => _adaptHopLimit(),
    );
  }

  /// Stop adaptive mesh networking
  Future<void> stop() async {
    await _batteryStateSub?.cancel();
    _batteryStateSub = null;
    _adaptationTimer?.cancel();
    _adaptationTimer = null;
    _currentMaxHops = null;
  }

  /// Adapt hop limit based on current conditions
  Future<void> _adaptHopLimit() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      bool isInBatterySaveMode = false;
      try {
        isInBatterySaveMode = await _battery.isInBatterySaveMode;
      } catch (_) {
        // Best-effort: some platforms may not support
        isInBatterySaveMode = false;
      }

      final isCharging = batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      // Use tracked network density
      final networkDensity = _networkDensity;

      // Calculate adaptive hop limit
      final maxHops = mesh_policy.AdaptiveMeshHopPolicy.calculateMaxHops(
        batteryLevel: batteryLevel,
        batteryState: batteryState,
        isInBatterySaveMode: isInBatterySaveMode,
        networkDensity: networkDensity,
        priority: _defaultPriority,
        messageType: _defaultMessageType,
        isCharging: isCharging,
      );

      final previousHops = _currentMaxHops;
      _currentMaxHops = maxHops;

      // Log if changed
      if (previousHops != maxHops) {
        developer.log(
          'Adaptive mesh hops updated: $previousHops → $maxHops '
          '(battery=$batteryLevel% charging=$isCharging density=$networkDensity)',
          name: _logName,
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to adapt mesh hop limit',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get current max hops (can be null for unlimited)
  int? get currentMaxHops => _currentMaxHops;

  /// Check if message should be forwarded based on adaptive policy
  bool shouldForwardMessage({
    required int currentHop,
    mesh_policy.MessagePriority? priority,
    mesh_policy.MessageType? messageType,
    ExpertiseLevel? senderExpertise, // NEW: Sender's expertise level
    ExpertiseLevel? recipientExpertise, // NEW: Recipient's expertise level
    String?
        geographicScope, // NEW: "locality", "city", "region", "country", "global"
  }) {
    // Always allow direct connections (0 hops)
    if (currentHop == 0) return true;

    // NEW: If sender is expert, allow more hops
    if (senderExpertise != null &&
        senderExpertise.index >= ExpertiseLevel.city.index) {
      final maxHops = _getEffectiveMaxHops(
        priority: priority ?? _defaultPriority,
        messageType: messageType ?? _defaultMessageType,
        geographicScope: geographicScope,
      );

      // City+ experts can propagate further
      final expertBonus = senderExpertise.index * 2;
      final effectiveMaxHops = maxHops != null ? maxHops + expertBonus : null;

      if (effectiveMaxHops != null) {
        return currentHop < effectiveMaxHops;
      }
      return true; // Unlimited
    }

    // Get effective max hops for this message
    final effectiveMaxHops = _getEffectiveMaxHops(
      priority: priority ?? _defaultPriority,
      messageType: messageType ?? _defaultMessageType,
      geographicScope: geographicScope,
    );

    // Check adaptive limit
    if (effectiveMaxHops != null) {
      return currentHop < effectiveMaxHops;
    }

    // Unlimited hops: check other limits (TTL, quality, loops)
    // These would be checked elsewhere (in the message handler)
    return true;
  }

  /// Get effective max hops for a specific message
  int? _getEffectiveMaxHops({
    required mesh_policy.MessagePriority priority,
    required mesh_policy.MessageType messageType,
    String?
        geographicScope, // NEW: "locality", "city", "region", "country", "global"
  }) {
    final baseLimit = _currentMaxHops;

    // NEW: Geographic scope affects hop limits
    if (geographicScope != null) {
      int scopeBonus = 0;
      switch (geographicScope) {
        case 'locality':
          scopeBonus = 0; // Base hops
          break;
        case 'city':
          scopeBonus = 2; // +2 hops for city scope
          break;
        case 'region':
          scopeBonus = 5; // +5 hops for regional scope
          break;
        case 'country':
          scopeBonus = 10; // +10 hops for country scope
          break;
        case 'global':
          return null; // Unlimited hops for global scope
      }

      if (baseLimit != null) {
        final scopedLimit = baseLimit + scopeBonus;

        // High priority messages can exceed scoped limit
        if (priority == mesh_policy.MessagePriority.critical) {
          return scopedLimit + 10; // Critical messages get extra hops
        }

        return scopedLimit;
      }
    }

    // If base is unlimited, check if this message should also be unlimited
    if (baseLimit == null) {
      return null; // Unlimited
    }

    // High priority messages can exceed base limit
    if (priority == mesh_policy.MessagePriority.critical) {
      return baseLimit + 10; // Critical messages get extra hops
    }

    return baseLimit;
  }

  /// Update network density (call this when devices are discovered/lost)
  void updateNetworkDensity(int density) {
    if (_networkDensity != density) {
      _networkDensity = density;
      // Trigger re-adaptation if density changed significantly
      unawaited(_adaptHopLimit());
    }
  }

  /// Get current network density
  int get networkDensity => _networkDensity;
}
