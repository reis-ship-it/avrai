// Network Cross-Pollination Service
// 
// Service for discovering entities through indirect paths in the network
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';

/// Represents a discovery path through the network
class DiscoveryPath {
  /// Starting entity
  final EntityKnot startEntity;
  
  /// Target entity type
  final EntityType targetType;
  
  /// Path of entities (start → intermediate → ... → target)
  final List<EntityKnot> path;
  
  /// Total compatibility score for the path
  final double pathCompatibility;
  
  /// Depth of the path (number of hops)
  final int depth;

  DiscoveryPath({
    required this.startEntity,
    required this.targetType,
    required this.path,
    required this.pathCompatibility,
    required this.depth,
  });

  /// Get the target entity (last in path)
  EntityKnot? get targetEntity => path.isNotEmpty ? path.last : null;

  @override
  String toString() {
    return 'DiscoveryPath(depth: $depth, compatibility: $pathCompatibility, '
           'path: ${path.map((e) => e.entityId).join(' → ')})';
  }
}

/// Service for network cross-pollination discovery
/// 
/// **Purpose:**
/// Discover entities of different types through indirect network paths,
/// enabling cross-pollination between people, events, places, and companies.
/// 
/// **Example:**
/// Person A → List → Event → Place → Company
/// 
/// This allows Person A to discover companies they might like based on:
/// - Events they're interested in
/// - Places they visit
/// - Indirect connections through the network
class NetworkCrossPollinationService {
  static const String _logName = 'NetworkCrossPollinationService';
  
  final CrossEntityCompatibilityService _compatibilityService;
  
  // Minimum compatibility threshold for path inclusion
  static const double _minPathCompatibility = 0.3;
  
  // Maximum path depth to explore
  static const int _maxDepth = 4;

  NetworkCrossPollinationService({
    CrossEntityCompatibilityService? compatibilityService,
  }) : _compatibilityService = compatibilityService ?? CrossEntityCompatibilityService();

  /// Find cross-entity discovery paths
  /// 
  /// **Algorithm:**
  /// - Start from startEntity
  /// - Traverse network through compatible entities
  /// - Find paths to targetType entities
  /// - Return paths sorted by compatibility
  /// 
  /// **Example:**
  /// ```dart
  /// final paths = await service.findCrossEntityDiscoveryPaths(
  ///   startEntity: personKnot,
  ///   targetType: EntityType.company,
  ///   maxDepth: 3,
  /// );
  /// // Returns: Person → Event → Company paths
  /// ```
  Future<List<DiscoveryPath>> findCrossEntityDiscoveryPaths({
    required EntityKnot startEntity,
    required EntityType targetType,
    int maxDepth = 3,
  }) async {
    developer.log(
      'Finding discovery paths from ${startEntity.entityType} to $targetType (maxDepth: $maxDepth)',
      name: _logName,
    );

    if (maxDepth > _maxDepth) {
      developer.log(
        '⚠️  maxDepth ($maxDepth) exceeds maximum ($_maxDepth), clamping',
        name: _logName,
      );
      maxDepth = _maxDepth;
    }

    try {
      // TODO: Integrate with actual network data sources
      // For now, this is a placeholder implementation
      // In production, this would:
      // 1. Query network connections (lists, events, places, companies)
      // 2. Filter by compatibility thresholds
      // 3. Build paths through the network
      // 4. Return sorted by path compatibility
      
      developer.log(
        '⚠️  Network traversal not yet implemented - requires network data sources',
        name: _logName,
      );
      
      // Placeholder: Return empty list
      // This will be implemented when network data sources are available
      return [];
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to find discovery paths: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Find entities of target type through network paths
  /// 
  /// **Returns:** List of discovered entities sorted by path compatibility
  Future<List<EntityKnot>> discoverEntitiesThroughNetwork({
    required EntityKnot startEntity,
    required EntityType targetType,
    int maxDepth = 3,
    int maxResults = 10,
  }) async {
    developer.log(
      'Discovering $targetType entities through network from ${startEntity.entityType}',
      name: _logName,
    );

    try {
      final paths = await findCrossEntityDiscoveryPaths(
        startEntity: startEntity,
        targetType: targetType,
        maxDepth: maxDepth,
      );
      
      // Extract target entities from paths
      final discoveredEntities = paths
          .map((path) => path.targetEntity)
          .whereType<EntityKnot>()
          .toSet() // Remove duplicates
          .toList();
      
      // Sort by path compatibility (highest first)
      // Filter by minimum compatibility threshold
      final filteredPaths = paths.where((p) => p.pathCompatibility >= _minPathCompatibility).toList();
      discoveredEntities.sort((a, b) {
        final pathA = filteredPaths.firstWhere((p) => p.targetEntity == a);
        final pathB = filteredPaths.firstWhere((p) => p.targetEntity == b);
        return pathB.pathCompatibility.compareTo(pathA.pathCompatibility);
      });
      
      // Return top results
      return discoveredEntities.take(maxResults).toList();
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to discover entities: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate path compatibility for a given path
  /// 
  /// **Formula:**
  /// Path compatibility = geometric mean of pairwise compatibilities
  /// 
  /// **Note:** This method is used internally when building discovery paths.
  /// It will be called when network traversal is implemented.
  Future<double> calculatePathCompatibility(List<EntityKnot> path) async {
    if (path.length < 2) return 1.0;
    
    double product = 1.0;
    for (int i = 0; i < path.length - 1; i++) {
      final compatibility = await _compatibilityService.calculateIntegratedCompatibility(
        entityA: path[i],
        entityB: path[i + 1],
      );
      product *= compatibility;
    }
    
    // Geometric mean: (product)^(1/n)
    return product.pow(1.0 / (path.length - 1));
  }
}

// Extension for double exponentiation
extension DoublePow on double {
  double pow(double exponent) {
    if (this <= 0.0) return 0.0;
    // Use math.pow for accurate calculation
    return math.pow(this, exponent).toDouble();
  }
}
