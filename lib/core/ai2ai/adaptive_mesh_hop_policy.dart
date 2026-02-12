import 'dart:math' as math;
import 'package:battery_plus/battery_plus.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';

/// Message priority levels for adaptive mesh routing
enum MessagePriority {
  /// Highest priority - can exceed base limits
  critical,
  
  /// High priority - gets bonus hops
  high,
  
  /// Normal priority - uses base limits
  medium,
  
  /// Low priority - reduced hops
  low,
}

/// Message types for adaptive routing
enum MessageType {
  /// Learning insights can propagate far
  learningInsight,
  
  /// Discovery is time-sensitive
  personalityDiscovery,
  
  /// Compatibility is immediate
  compatibilityCheck,
  
  /// Network maintenance
  networkCoordination,
  
  /// Locality agent updates (geographic learning)
  localityAgentUpdate,
  
  /// Locality personality updates (community character)
  localityPersonalityUpdate,
}

/// Adaptive mesh hop policy calculator
/// 
/// Follows the same pattern as BatteryScanPolicy - pure policy logic
/// that can be tested without device dependencies.
/// 
/// **Guarantee:** Always returns at least 0 (direct connections always work)
/// **Scale:** Can go up to unlimited (null) when conditions are optimal
class AdaptiveMeshHopPolicy {
  /// Calculate adaptive hop limit based on current conditions
  /// 
  /// Returns:
  /// - `null` = unlimited hops (only TTL/quality limits apply)
  /// - `0` = direct connections only (minimum functionality)
  /// - `> 0` = specific hop limit
  /// 
  /// **Guarantee:** Always returns at least 0 (direct connections always work)
  static int? calculateMaxHops({
    required int batteryLevel,
    required BatteryState batteryState,
    required bool isInBatterySaveMode,
    required int networkDensity,  // Number of nearby devices
    required MessagePriority priority,
    required MessageType messageType,
    required bool isCharging,
    ExpertiseLevel? userExpertiseLevel,  // NEW: User's expertise level
    ExpertiseLevel? targetExpertiseLevel, // NEW: Target's expertise level (for learning)
  }) {
    // PRIORITY 1: Never lose core functionality
    // Always allow at least direct connections (0 hops = direct only)
    const int minimumHops = 0;
    
    // PRIORITY 2: OS power saver - scale back significantly
    if (isInBatterySaveMode) {
      // Still allow direct + 1 hop for critical learning
      return priority == MessagePriority.critical ? 1 : minimumHops;
    }
    
    // PRIORITY 3: Battery-based scaling
    final int baseHops = _calculateBatteryBasedHops(
      batteryLevel: batteryLevel,
      batteryState: batteryState,
      isCharging: isCharging,
    );
    
    // PRIORITY 4: Network density bonus
    final int densityBonus = _calculateDensityBonus(networkDensity);
    
    // PRIORITY 5: Message type and priority adjustments
    final int priorityBonus = _calculatePriorityBonus(
      priority,
      messageType,
      userExpertiseLevel,
    );
    
    // PRIORITY 6: Expertise-based bonus (higher expertise = more hops)
    final int expertiseBonus = _calculateExpertiseBonus(
      userExpertiseLevel: userExpertiseLevel,
      targetExpertiseLevel: targetExpertiseLevel,
    );
    
    // Calculate total
    final int totalHops = baseHops + densityBonus + priorityBonus + expertiseBonus;
    
    // PRIORITY 7: Unlimited hops when conditions are perfect
    if (_shouldAllowUnlimitedHops(
      batteryLevel: batteryLevel,
      batteryState: batteryState,
      networkDensity: networkDensity,
      isCharging: isCharging,
      userExpertiseLevel: userExpertiseLevel,
    )) {
      return null;  // null = unlimited hops
    }
    
    // Ensure we never go below minimum
    return math.max(minimumHops, totalHops);
  }
  
  /// Battery-based hop calculation
  static int _calculateBatteryBasedHops({
    required int batteryLevel,
    required BatteryState batteryState,
    required bool isCharging,
  }) {
    // Charging/Full: Aggressive (unlimited potential)
    if (batteryState == BatteryState.charging || 
        batteryState == BatteryState.full) {
      return 50;  // Very high base, can go unlimited
    }
    
    // Battery tiered (similar to BatteryAdaptiveBleScheduler pattern)
    if (batteryLevel >= 80) return 20;
    if (batteryLevel >= 60) return 15;
    if (batteryLevel >= 45) return 10;
    if (batteryLevel >= 30) return 5;
    if (batteryLevel >= 20) return 3;
    if (batteryLevel >= 10) return 1;
    
    // Critical battery: Direct only (but still works!)
    return 0;
  }
  
  /// Network density bonus (more devices = more reliable routing)
  static int _calculateDensityBonus(int networkDensity) {
    if (networkDensity >= 20) return 10;  // Very dense network
    if (networkDensity >= 10) return 5;   // Dense network
    if (networkDensity >= 5) return 2;    // Moderate network
    return 0;  // Sparse network
  }
  
  /// Priority and message type adjustments
  static int _calculatePriorityBonus(
    MessagePriority priority,
    MessageType messageType,
    ExpertiseLevel? senderExpertise,
  ) {
    int bonus = 0;
    
    // Learning insights can propagate further
    if (messageType == MessageType.learningInsight) {
      bonus += 10;
    }
    
    // High priority messages get extra hops
    switch (priority) {
      case MessagePriority.critical:
        bonus += 15;
      case MessagePriority.high:
        bonus += 5;
      case MessagePriority.medium:
        bonus += 0;
      case MessagePriority.low:
        bonus -= 2;  // Reduce hops for low priority
    }
    
    // NEW: Expertise-based priority boost
    if (senderExpertise != null) {
      // Higher expertise = higher priority
      bonus += senderExpertise.index; // Local=0, City=1, Regional=2, etc.
      
      // Critical messages from experts get extra boost
      if (priority == MessagePriority.critical) {
        bonus += senderExpertise.index * 2;
      }
    }
    
    return bonus;
  }
  
  /// Calculate expertise-based hop bonus
  /// 
  /// Higher expertise levels allow more hops:
  /// - Local: 0 bonus
  /// - City: +2 hops
  /// - Regional: +4 hops
  /// - National: +6 hops
  /// - Global: +8 hops
  /// - Universal: +10 hops
  /// 
  /// Additional bonus when learning from higher expertise
  static int _calculateExpertiseBonus({
    ExpertiseLevel? userExpertiseLevel,
    ExpertiseLevel? targetExpertiseLevel,
  }) {
    int bonus = 0;
    
    if (userExpertiseLevel != null) {
      // Higher expertise = more hops allowed
      // Local=0, City=2, Regional=4, National=6, Global=8, Universal=10
      bonus = userExpertiseLevel.index * 2;
    }
    
    // Bonus for learning from higher expertise
    if (targetExpertiseLevel != null && userExpertiseLevel != null) {
      if (targetExpertiseLevel.isHigherThan(userExpertiseLevel)) {
        bonus += 3; // Extra hops to learn from experts
      }
    }
    
    return bonus;
  }
  
  /// Determine if conditions allow unlimited hops
  static bool _shouldAllowUnlimitedHops({
    required int batteryLevel,
    required BatteryState batteryState,
    required int networkDensity,
    required bool isCharging,
    ExpertiseLevel? userExpertiseLevel,
  }) {
    // Allow unlimited when:
    // 1. Battery is charging/full AND
    // 2. Battery level >= 80% AND
    // 3. Network is dense (>= 10 devices) AND
    // 4. Not in power saver mode (checked earlier)
    // 5. NEW: Global+ experts can have unlimited even with lower battery/density
    
    final baseConditions = (batteryState == BatteryState.charging || 
            batteryState == BatteryState.full) &&
           batteryLevel >= 80 &&
           networkDensity >= 10;
    
    // Global+ experts can have unlimited with relaxed conditions
    if (userExpertiseLevel != null && 
        userExpertiseLevel.index >= ExpertiseLevel.global.index) {
      return baseConditions || 
             (batteryLevel >= 60 && networkDensity >= 5);
    }
    
    return baseConditions;
  }
}
