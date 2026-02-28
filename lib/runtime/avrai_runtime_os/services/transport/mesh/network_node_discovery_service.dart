import 'dart:async';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

/// Network Node Discovery Service
///
/// Discovers and manages available routing nodes in the AI2AI network.
/// Filters devices that can act as routing nodes and provides node selection
/// based on reliability, proximity, and capacity.
///
/// **Phase 2:** Secure Encrypted Private AI2AI Network Implementation
class NetworkNodeDiscoveryService {
  static const String _logName = 'NetworkNodeDiscoveryService';

  final DeviceDiscoveryService _deviceDiscovery;
  final AdaptiveMeshNetworkingService? _adaptiveMeshService;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'NetworkNodeDiscovery',
    minimumLevel: LogLevel.debug,
  );

  // Node cache with metadata
  final Map<String, RoutingNode> _nodeCache = {};
  final Map<String, DateTime> _nodeLastSeen = {};
  final Map<String, NodeReliabilityMetrics> _nodeReliability = {};

  // Discovery configuration
  static const Duration _nodeCacheTimeout = Duration(minutes: 5);
  static const int _minReliabilityScore = 50; // 0-100 scale

  // Node selection criteria
  static const double _proximityWeight = 0.3;
  static const double _reliabilityWeight = 0.4;
  static const double _capacityWeight = 0.2;
  static const double _batteryWeight = 0.1;

  StreamSubscription<List<DiscoveredDevice>>? _discoverySubscription;

  NetworkNodeDiscoveryService({
    required DeviceDiscoveryService deviceDiscovery,
    AdaptiveMeshNetworkingService? adaptiveMeshService,
  })  : _deviceDiscovery = deviceDiscovery,
        _adaptiveMeshService = adaptiveMeshService;

  /// Initialize node discovery service
  ///
  /// Starts listening to device discovery events and filters for routing-capable nodes.
  Future<void> initialize() async {
    try {
      _logger.debug('Initializing Network Node Discovery Service',
          tag: _logName);

      // Subscribe to device discovery events
      _deviceDiscovery.onDevicesDiscovered((devices) {
        _processDiscoveredDevices(devices);
      });

      // Start periodic cache cleanup
      _startCacheCleanup();

      _logger.info('✅ Network Node Discovery Service initialized',
          tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing Network Node Discovery Service: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Process discovered devices and filter for routing-capable nodes
  Future<void> _processDiscoveredDevices(List<DiscoveredDevice> devices) async {
    try {
      final now = DateTime.now();
      final routingNodes = <String, RoutingNode>{};

      for (final device in devices) {
        // Check if device can act as routing node
        if (!_canDeviceRoute(device)) {
          continue;
        }

        // Get or create routing node
        final nodeId = device.deviceId;
        final existingNode = _nodeCache[nodeId];

        if (existingNode != null) {
          // Update existing node
          final updatedNode = existingNode.copyWith(
            lastSeen: now,
            signalStrength: device.signalStrength,
            proximityScore: device.proximityScore,
          );
          routingNodes[nodeId] = updatedNode;
          _nodeLastSeen[nodeId] = now;
        } else {
          // Create new routing node
          final newNode = RoutingNode(
            nodeId: nodeId,
            deviceId: device.deviceId,
            deviceName: device.deviceName,
            deviceType: device.type,
            signalStrength: device.signalStrength,
            proximityScore: device.proximityScore,
            discoveredAt: now,
            lastSeen: now,
            reliabilityScore: _getInitialReliabilityScore(),
            routingCapability: _assessRoutingCapability(device),
            metadata: device.metadata,
          );
          routingNodes[nodeId] = newNode;
          _nodeLastSeen[nodeId] = now;
          _nodeReliability[nodeId] = NodeReliabilityMetrics.initial();
        }
      }

      // Update cache
      _nodeCache.addAll(routingNodes);

      if (routingNodes.isNotEmpty) {
        _logger.debug(
          'Discovered ${routingNodes.length} routing-capable nodes',
          tag: _logName,
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error processing discovered devices: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if device can act as routing node
  bool _canDeviceRoute(DiscoveredDevice device) {
    // Device must be avrai-enabled
    if (!device.isSpotsEnabled) {
      return false;
    }

    // Device must have personality data (indicates AI2AI capability)
    if (device.personalityData == null) {
      return false;
    }

    // Check if device supports routing (via metadata or capabilities)
    final supportsRouting =
        device.metadata['supports_routing'] as bool? ?? true;
    if (!supportsRouting) {
      return false;
    }

    // Check adaptive mesh service for routing capability
    if (_adaptiveMeshService != null) {
      // Use adaptive mesh service to check if device can route
      // This considers battery level, network density, etc.
      // For now, assume all discovered devices can route if they meet above criteria
    }

    return true;
  }

  /// Assess routing capability of a device
  RoutingCapability _assessRoutingCapability(DiscoveredDevice device) {
    // Base capability on device type and signal strength
    var capability = RoutingCapability.medium;

    // Strong signal indicates good connectivity
    if (device.signalStrength != null && device.signalStrength! > -70) {
      capability = RoutingCapability.high;
    } else if (device.signalStrength != null && device.signalStrength! < -90) {
      capability = RoutingCapability.low;
    }

    // WiFi devices generally have better routing capability than BLE
    if (device.type == DeviceType.wifi ||
        device.type == DeviceType.wifiDirect) {
      if (capability == RoutingCapability.medium) {
        capability = RoutingCapability.high;
      }
    }

    return capability;
  }

  /// Get initial reliability score for new node
  int _getInitialReliabilityScore() {
    // Start with moderate reliability for new nodes
    return 60;
  }

  /// Get available routing nodes
  ///
  /// Returns list of nodes that can be used for routing, filtered and sorted
  /// by reliability, proximity, and capacity.
  Future<List<RoutingNode>> getAvailableRoutingNodes({
    int? maxNodes,
    RoutingCapability? minCapability,
  }) async {
    try {
      // Clean up stale nodes
      _cleanupStaleNodes();

      // Filter nodes
      var availableNodes = _nodeCache.values.where((node) {
        // Check if node is still valid
        if (_isNodeStale(node)) {
          return false;
        }

        // Check minimum capability
        if (minCapability != null) {
          if (!_meetsCapabilityRequirement(
              node.routingCapability, minCapability)) {
            return false;
          }
        }

        // Check minimum reliability
        if (node.reliabilityScore < _minReliabilityScore) {
          return false;
        }

        return true;
      }).toList();

      // Sort by composite score (reliability + proximity + capacity)
      availableNodes.sort((a, b) {
        final scoreA = _calculateNodeScore(a);
        final scoreB = _calculateNodeScore(b);
        return scoreB.compareTo(scoreA); // Descending order
      });

      // Limit results
      if (maxNodes != null && availableNodes.length > maxNodes) {
        availableNodes = availableNodes.sublist(0, maxNodes);
      }

      return availableNodes;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting available routing nodes: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Calculate composite score for node selection
  double _calculateNodeScore(RoutingNode node) {
    // Normalize reliability (0-100 -> 0.0-1.0)
    final reliabilityNorm = node.reliabilityScore / 100.0;

    // Proximity score (already 0.0-1.0)
    final proximityNorm = node.proximityScore;

    // Capacity score based on capability
    final capacityNorm = _getCapabilityScore(node.routingCapability);

    // Battery score (if available in metadata)
    final batteryLevel = node.metadata['battery_level'] as int?;
    final batteryNorm = batteryLevel != null ? batteryLevel / 100.0 : 0.5;

    // Weighted composite score
    final score = (_reliabilityWeight * reliabilityNorm) +
        (_proximityWeight * proximityNorm) +
        (_capacityWeight * capacityNorm) +
        (_batteryWeight * batteryNorm);

    return score;
  }

  /// Get capability score (0.0-1.0)
  double _getCapabilityScore(RoutingCapability capability) {
    switch (capability) {
      case RoutingCapability.high:
        return 1.0;
      case RoutingCapability.medium:
        return 0.6;
      case RoutingCapability.low:
        return 0.3;
    }
  }

  /// Check if node meets capability requirement
  bool _meetsCapabilityRequirement(
    RoutingCapability nodeCapability,
    RoutingCapability minCapability,
  ) {
    final nodeLevel = _getCapabilityLevel(nodeCapability);
    final minLevel = _getCapabilityLevel(minCapability);
    return nodeLevel >= minLevel;
  }

  /// Get capability level (for comparison)
  int _getCapabilityLevel(RoutingCapability capability) {
    switch (capability) {
      case RoutingCapability.high:
        return 3;
      case RoutingCapability.medium:
        return 2;
      case RoutingCapability.low:
        return 1;
    }
  }

  /// Select optimal nodes for routing path
  ///
  /// Selects nodes based on reliability, proximity, capacity, and path diversity.
  Future<List<RoutingNode>> selectOptimalNodes({
    required int maxHops,
    RoutingCapability? minCapability,
    bool ensureDiversity = true,
  }) async {
    try {
      final availableNodes = await getAvailableRoutingNodes(
        maxNodes: maxHops * 2, // Get more candidates than needed
        minCapability: minCapability,
      );

      if (availableNodes.isEmpty) {
        return [];
      }

      // If diversity not required, just return top nodes
      if (!ensureDiversity) {
        return availableNodes.take(maxHops).toList();
      }

      // Select diverse nodes (avoid clustering)
      final selectedNodes = <RoutingNode>[];
      final usedDeviceTypes = <DeviceType>{};

      for (final node in availableNodes) {
        if (selectedNodes.length >= maxHops) {
          break;
        }

        // Prefer diversity in device types
        if (ensureDiversity && usedDeviceTypes.contains(node.deviceType)) {
          // Skip if we already have this device type (unless we need more)
          if (selectedNodes.length < maxHops / 2) {
            continue;
          }
        }

        selectedNodes.add(node);
        usedDeviceTypes.add(node.deviceType);
      }

      return selectedNodes;
    } catch (e, stackTrace) {
      _logger.error(
        'Error selecting optimal nodes: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Update node reliability metrics
  ///
  /// Called when a node successfully routes a message or fails.
  void updateNodeReliability(String nodeId, bool success) {
    try {
      final metrics =
          _nodeReliability[nodeId] ?? NodeReliabilityMetrics.initial();
      final updatedMetrics = metrics.recordAttempt(success);

      _nodeReliability[nodeId] = updatedMetrics;

      // Update node reliability score
      final node = _nodeCache[nodeId];
      if (node != null) {
        final newScore = updatedMetrics.calculateReliabilityScore();
        final updatedNode = node.copyWith(reliabilityScore: newScore);
        _nodeCache[nodeId] = updatedNode;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error updating node reliability: $e',
        tag: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if node is stale
  bool _isNodeStale(RoutingNode node) {
    final lastSeen = _nodeLastSeen[node.nodeId];
    if (lastSeen == null) {
      return true;
    }
    return DateTime.now().difference(lastSeen) > _nodeCacheTimeout;
  }

  /// Clean up stale nodes
  void _cleanupStaleNodes() {
    final now = DateTime.now();
    final staleNodeIds = <String>[];

    for (final entry in _nodeLastSeen.entries) {
      if (now.difference(entry.value) > _nodeCacheTimeout) {
        staleNodeIds.add(entry.key);
      }
    }

    for (final nodeId in staleNodeIds) {
      _nodeCache.remove(nodeId);
      _nodeLastSeen.remove(nodeId);
      _nodeReliability.remove(nodeId);
    }

    if (staleNodeIds.isNotEmpty) {
      _logger.debug(
        'Cleaned up ${staleNodeIds.length} stale routing nodes',
        tag: _logName,
      );
    }
  }

  /// Start periodic cache cleanup
  void _startCacheCleanup() {
    // Cleanup runs every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupStaleNodes();
    });
  }

  /// Dispose resources
  void dispose() {
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
    _nodeCache.clear();
    _nodeLastSeen.clear();
    _nodeReliability.clear();
  }
}

/// Routing node with metadata
class RoutingNode {
  final String nodeId;
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;
  final int? signalStrength;
  final double proximityScore;
  final DateTime discoveredAt;
  final DateTime lastSeen;
  final int reliabilityScore; // 0-100
  final RoutingCapability routingCapability;
  final Map<String, dynamic> metadata;

  const RoutingNode({
    required this.nodeId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.signalStrength,
    required this.proximityScore,
    required this.discoveredAt,
    required this.lastSeen,
    required this.reliabilityScore,
    required this.routingCapability,
    this.metadata = const {},
  });

  RoutingNode copyWith({
    String? nodeId,
    String? deviceId,
    String? deviceName,
    DeviceType? deviceType,
    int? signalStrength,
    double? proximityScore,
    DateTime? discoveredAt,
    DateTime? lastSeen,
    int? reliabilityScore,
    RoutingCapability? routingCapability,
    Map<String, dynamic>? metadata,
  }) {
    return RoutingNode(
      nodeId: nodeId ?? this.nodeId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      signalStrength: signalStrength ?? this.signalStrength,
      proximityScore: proximityScore ?? this.proximityScore,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastSeen: lastSeen ?? this.lastSeen,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      routingCapability: routingCapability ?? this.routingCapability,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Routing capability levels
enum RoutingCapability {
  high, // High capacity, strong signal, reliable
  medium, // Moderate capacity and reliability
  low, // Low capacity, weak signal, less reliable
}

/// Node reliability metrics
class NodeReliabilityMetrics {
  final int totalAttempts;
  final int successfulAttempts;
  final int failedAttempts;
  final DateTime windowStart;
  final List<bool> recentAttempts; // Last 100 attempts

  const NodeReliabilityMetrics({
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.failedAttempts,
    required this.windowStart,
    required this.recentAttempts,
  });

  factory NodeReliabilityMetrics.initial() {
    return NodeReliabilityMetrics(
      totalAttempts: 0,
      successfulAttempts: 0,
      failedAttempts: 0,
      windowStart: DateTime.now(),
      recentAttempts: [],
    );
  }

  /// Record a routing attempt
  NodeReliabilityMetrics recordAttempt(bool success) {
    final newTotal = totalAttempts + 1;
    final newSuccessful = success ? successfulAttempts + 1 : successfulAttempts;
    final newFailed = success ? failedAttempts : failedAttempts + 1;

    // Update recent attempts (keep last 100)
    final newRecent = List<bool>.from(recentAttempts);
    newRecent.add(success);
    if (newRecent.length > 100) {
      newRecent.removeAt(0);
    }

    return NodeReliabilityMetrics(
      totalAttempts: newTotal,
      successfulAttempts: newSuccessful,
      failedAttempts: newFailed,
      windowStart: windowStart,
      recentAttempts: newRecent,
    );
  }

  /// Calculate reliability score (0-100)
  int calculateReliabilityScore() {
    if (totalAttempts == 0) {
      return 60; // Default for new nodes
    }

    // Use recent attempts for more responsive score
    if (recentAttempts.isNotEmpty) {
      final recentSuccessRate =
          recentAttempts.where((s) => s).length / recentAttempts.length;
      return (recentSuccessRate * 100).round();
    }

    // Fallback to overall success rate
    final overallSuccessRate = successfulAttempts / totalAttempts;
    return (overallSuccessRate * 100).round();
  }
}
