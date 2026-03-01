import 'dart:developer' as developer;

import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/monitoring/hierarchical_ai_monitoring_models.dart';
import 'package:avrai_runtime_os/monitoring/network_flow.dart';

/// Phase 20.2–20.4: Hierarchical AI monitoring (user → area → region → universal).
///
/// Aggregates metrics from [ConnectionMonitor] by agentId; area/region/universal
/// use optional resolver. Privacy: agentId only, no PII.
class HierarchicalAIMonitoring {
  static const String _logName = 'HierarchicalAIMonitoring';

  final ConnectionMonitor _connectionMonitor;

  /// Optional: maps agentId → areaId (e.g. locality_code). If null, all agents go to 'default'.
  final String Function(String agentId)? areaResolver;

  /// Optional: maps areaId → regionId. If null, all areas go to 'default'.
  final String Function(String areaId)? regionResolver;

  HierarchicalAIMonitoring({
    required ConnectionMonitor connectionMonitor,
    this.areaResolver,
    this.regionResolver,
  }) : _connectionMonitor = connectionMonitor;

  /// Aggregate metrics per user AI (agentId) from active sessions.
  Future<List<UserAIMetrics>> getUserAIMetrics() async {
    try {
      final sessions = _connectionMonitor.getAllMonitoringSessions();
      final byAgent = <String, List<ConnectionMonitoringSession>>{};
      for (final s in sessions) {
        byAgent.putIfAbsent(s.localAISignature, () => []).add(s);
      }
      final now = DateTime.now();
      return byAgent.entries.map((e) {
        final list = e.value;
        final compat = list
                .map((s) => s.currentMetrics.currentCompatibility)
                .reduce((a, b) => a + b) /
            list.length;
        final learning = list
                .map((s) => s.currentMetrics.learningEffectiveness)
                .reduce((a, b) => a + b) /
            list.length;
        final pleasure = list
                .map((s) => s.currentMetrics.aiPleasureScore)
                .reduce((a, b) => a + b) /
            list.length;
        return UserAIMetrics(
          agentId: e.key,
          connectionCount: list.length,
          averageCompatibility: compat,
          averageLearningEffectiveness: learning,
          averagePleasureScore: pleasure.clamp(0.0, 1.0),
          evolutionRate: 0.0,
          aggregatedAt: now,
        );
      }).toList();
    } catch (e, st) {
      developer.log('getUserAIMetrics failed',
          name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Aggregate metrics per area (locality/city). Uses [areaResolver] to group user AIs.
  Future<List<AreaAIMetrics>> getAreaAIMetrics() async {
    try {
      final userMetrics = await getUserAIMetrics();
      final byArea = <String, List<UserAIMetrics>>{};
      for (final u in userMetrics) {
        final areaId = areaResolver?.call(u.agentId) ?? 'default';
        byArea.putIfAbsent(areaId, () => []).add(u);
      }
      final now = DateTime.now();
      return byArea.entries.map((e) {
        final list = e.value;
        final n = list.length;
        final compat =
            list.map((u) => u.averageCompatibility).reduce((a, b) => a + b) / n;
        final learning = list
                .map((u) => u.averageLearningEffectiveness)
                .reduce((a, b) => a + b) /
            n;
        final pleasure =
            list.map((u) => u.averagePleasureScore).reduce((a, b) => a + b) / n;
        final dist = <String, double>{};
        for (final u in list) {
          dist[u.agentId] = u.averagePleasureScore;
        }
        return AreaAIMetrics(
          areaId: e.key,
          userAICount: n,
          averageCompatibility: compat,
          averageLearningEffectiveness: learning,
          averagePleasureScore: pleasure.clamp(0.0, 1.0),
          pleasureDistribution: dist,
          aggregatedAt: now,
        );
      }).toList();
    } catch (e, st) {
      developer.log('getAreaAIMetrics failed',
          name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Aggregate metrics per region. Uses [regionResolver] to group areas.
  Future<List<RegionalAIMetrics>> getRegionalAIMetrics() async {
    try {
      final areaMetrics = await getAreaAIMetrics();
      final byRegion = <String, List<AreaAIMetrics>>{};
      for (final a in areaMetrics) {
        final regionId = regionResolver?.call(a.areaId) ?? 'default';
        byRegion.putIfAbsent(regionId, () => []).add(a);
      }
      final now = DateTime.now();
      return byRegion.entries.map((e) {
        final list = e.value;
        final n = list.length;
        final compat =
            list.map((a) => a.averageCompatibility).reduce((a, b) => a + b) / n;
        final learning = list
                .map((a) => a.averageLearningEffectiveness)
                .reduce((a, b) => a + b) /
            n;
        final pleasure =
            list.map((a) => a.averagePleasureScore).reduce((a, b) => a + b) / n;
        final health =
            (compat * 0.35 + learning * 0.35 + pleasure * 0.30).clamp(0.0, 1.0);
        return RegionalAIMetrics(
          regionId: e.key,
          areaCount: n,
          averageCompatibility: compat,
          averageLearningEffectiveness: learning,
          averagePleasureScore: pleasure.clamp(0.0, 1.0),
          networkHealthScore: health,
          aggregatedAt: now,
        );
      }).toList();
    } catch (e, st) {
      developer.log('getRegionalAIMetrics failed',
          name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Aggregate metrics at universal (global) level.
  Future<UniversalAIMetrics?> getUniversalAIMetrics() async {
    try {
      final regional = await getRegionalAIMetrics();
      if (regional.isEmpty) return null;
      final n = regional.length;
      final compat =
          regional.map((r) => r.averageCompatibility).reduce((a, b) => a + b) /
              n;
      final learning = regional
              .map((r) => r.averageLearningEffectiveness)
              .reduce((a, b) => a + b) /
          n;
      final pleasure =
          regional.map((r) => r.averagePleasureScore).reduce((a, b) => a + b) /
              n;
      final health =
          regional.map((r) => r.networkHealthScore).reduce((a, b) => a + b) / n;
      return UniversalAIMetrics(
        regionCount: n,
        averageCompatibility: compat,
        averageLearningEffectiveness: learning,
        averagePleasureScore: pleasure.clamp(0.0, 1.0),
        globalNetworkHealthScore: health.clamp(0.0, 1.0),
        aggregatedAt: DateTime.now(),
      );
    } catch (e, st) {
      developer.log('getUniversalAIMetrics failed',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  /// Identify patterns across hierarchy levels (e.g. correlation, anomaly).
  Future<List<CrossLevelPattern>> analyzeCrossLevelPatterns() async {
    try {
      final userMetrics = await getUserAIMetrics();
      final areaMetrics = await getAreaAIMetrics();
      final regionalMetrics = await getRegionalAIMetrics();
      final patterns = <CrossLevelPattern>[];
      final now = DateTime.now();

      if (userMetrics.length >= 2 && areaMetrics.isNotEmpty) {
        final avgPleasureUser = userMetrics
                .map((u) => u.averagePleasureScore)
                .reduce((a, b) => a + b) /
            userMetrics.length;
        final avgPleasureArea = areaMetrics
                .map((a) => a.averagePleasureScore)
                .reduce((a, b) => a + b) /
            areaMetrics.length;
        final correlation =
            (avgPleasureUser - avgPleasureArea).abs() < 0.2 ? 0.8 : 0.5;
        patterns.add(CrossLevelPattern(
          patternType: 'pleasure_alignment',
          levelIds: ['user', 'area'],
          correlationScore: correlation,
          description: 'User and area pleasure alignment',
          detectedAt: now,
        ));
      }

      if (regionalMetrics.length >= 2) {
        final scores =
            regionalMetrics.map((r) => r.networkHealthScore).toList();
        final maxS = scores.reduce((a, b) => a > b ? a : b);
        final minS = scores.reduce((a, b) => a < b ? a : b);
        if (maxS - minS > 0.3) {
          patterns.add(CrossLevelPattern(
            patternType: 'regional_variance',
            levelIds: regionalMetrics.map((r) => r.regionId).toList(),
            correlationScore: 0.0,
            description: 'High variance in regional health scores',
            detectedAt: now,
          ));
        }
      }

      return patterns;
    } catch (e, st) {
      developer.log('analyzeCrossLevelPatterns failed',
          name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Build full hierarchical view.
  Future<HierarchicalNetworkView> getHierarchicalNetworkView() async {
    final userMetrics = await getUserAIMetrics();
    final areaMetrics = await getAreaAIMetrics();
    final regionalMetrics = await getRegionalAIMetrics();
    final universalMetrics = await getUniversalAIMetrics();
    final crossLevelPatterns = await analyzeCrossLevelPatterns();
    return HierarchicalNetworkView(
      userMetrics: userMetrics,
      areaMetrics: areaMetrics,
      regionalMetrics: regionalMetrics,
      universalMetrics: universalMetrics,
      crossLevelPatterns: crossLevelPatterns,
      generatedAt: DateTime.now(),
    );
  }

  /// Compute network flow (user → area → region → universal) and flow metrics.
  Future<NetworkFlow> visualizeNetworkFlow() async {
    try {
      final view = await getHierarchicalNetworkView();
      return NetworkFlow.fromHierarchicalView(view);
    } catch (e, st) {
      developer.log('visualizeNetworkFlow failed',
          name: _logName, error: e, stackTrace: st);
      return NetworkFlow.empty();
    }
  }
}
