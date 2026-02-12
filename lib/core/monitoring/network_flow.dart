import 'package:avrai/core/monitoring/hierarchical_ai_monitoring_models.dart';

/// Phase 20.4: Network flow (user AI → area AI → region AI → universal AI).
///
/// Tracks data flow, learning propagation, and flow metrics.
class NetworkFlow {
  final int userAICount;
  final int areaCount;
  final int regionCount;
  final bool hasUniversal;
  final double learningPropagationRate;
  final double patternEmergenceRate;
  final double collectiveIntelligenceGrowth;
  final List<String> bottlenecks;
  final double propagationSpeed;
  final DateTime computedAt;

  const NetworkFlow({
    required this.userAICount,
    required this.areaCount,
    required this.regionCount,
    required this.hasUniversal,
    required this.learningPropagationRate,
    required this.patternEmergenceRate,
    required this.collectiveIntelligenceGrowth,
    required this.bottlenecks,
    required this.propagationSpeed,
    required this.computedAt,
  });

  /// Build flow from hierarchical view (flow metrics derived from aggregates).
  factory NetworkFlow.fromHierarchicalView(HierarchicalNetworkView view) {
    final userCount = view.userMetrics.length;
    final areaCount = view.areaMetrics.length;
    final regionCount = view.regionalMetrics.length;
    final hasUniversal = view.universalMetrics != null;

    double learningPropagation = 0.5;
    double patternEmergence = 0.5;
    double collectiveGrowth = 0.5;
    final bottlenecks = <String>[];
    double propagationSpeed = 0.5;

    if (userCount > 0 && areaCount > 0) {
      final avgPleasureUser = view.userMetrics.map((u) => u.averagePleasureScore).reduce((a, b) => a + b) / userCount;
      final avgPleasureArea = view.areaMetrics.map((a) => a.averagePleasureScore).reduce((a, b) => a + b) / areaCount;
      learningPropagation = (0.5 + (1.0 - (avgPleasureUser - avgPleasureArea).abs()) / 2).clamp(0.0, 1.0);
    }
    if (areaCount > 0 && regionCount > 0) {
      final avgLearningArea = view.areaMetrics.map((a) => a.averageLearningEffectiveness).reduce((a, b) => a + b) / areaCount;
      final avgLearningRegion = view.regionalMetrics.map((r) => r.averageLearningEffectiveness).reduce((a, b) => a + b) / regionCount;
      patternEmergence = (0.5 + (avgLearningArea + avgLearningRegion) / 4).clamp(0.0, 1.0);
    }
    if (view.universalMetrics != null) {
      collectiveGrowth = view.universalMetrics!.globalNetworkHealthScore;
    }
    if (areaCount == 0 && userCount > 0) {
      bottlenecks.add('no_area_aggregation');
    }
    if (regionCount == 0 && areaCount > 0) {
      bottlenecks.add('no_region_aggregation');
    }
    propagationSpeed = (learningPropagation + patternEmergence) / 2;

    return NetworkFlow(
      userAICount: userCount,
      areaCount: areaCount,
      regionCount: regionCount,
      hasUniversal: hasUniversal,
      learningPropagationRate: learningPropagation,
      patternEmergenceRate: patternEmergence,
      collectiveIntelligenceGrowth: collectiveGrowth,
      bottlenecks: bottlenecks,
      propagationSpeed: propagationSpeed,
      computedAt: view.generatedAt,
    );
  }

  static NetworkFlow empty() {
    final now = DateTime.now();
    return NetworkFlow(
      userAICount: 0,
      areaCount: 0,
      regionCount: 0,
      hasUniversal: false,
      learningPropagationRate: 0.0,
      patternEmergenceRate: 0.0,
      collectiveIntelligenceGrowth: 0.0,
      bottlenecks: [],
      propagationSpeed: 0.0,
      computedAt: now,
    );
  }
}
