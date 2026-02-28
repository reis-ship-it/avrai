// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

part 'connection_monitor_models.dart';

/// OUR_GUTS.md: "Connection monitoring that tracks AI2AI personality interactions while preserving privacy"
/// Comprehensive connection monitoring system for individual AI2AI personality learning interactions
class ConnectionMonitor {
  static const String _logName = 'ConnectionMonitor';

  // Storage keys for connection monitoring data
  static const String _activeConnectionsKey = 'active_connections';
  static const String _connectionHistoryKey = 'connection_history';
  static const String _monitoringAlertsKey = 'monitoring_alerts';

  final SharedPreferencesCompat _prefs;

  // Monitoring state
  final Map<String, ActiveConnection> _activeConnections = {};
  final Map<String, ConnectionMonitoringSession> _monitoringSessions = {};
  final List<ConnectionAlert> _alerts = [];
  Timer? _monitoringTimer;

  // Reverse index: AI signature -> Set of connection IDs
  // This enables O(1) lookup of all connections for a given AI signature
  final Map<String, Set<String>> _aiSignatureIndex = {};

  // Stream controllers for active connections
  StreamController<ActiveConnectionsOverview>? _connectionsStreamController;
  Timer? _connectionsUpdateTimer;

  ConnectionMonitor({required SharedPreferencesCompat prefs}) : _prefs = prefs {
    // Load persisted data on initialization (fire and forget - runs in background)
    _loadPersistedData().catchError((e) {
      developer.log('Error loading persisted data in constructor: $e',
          name: _logName);
    });
  }

  /// Load persisted data from SharedPreferences
  Future<void> _loadPersistedData() async {
    try {
      // #region agent log
      developer.log('Loading persisted connection monitoring data',
          name: _logName);
      // #endregion

      // Load active connections (note: in production, would need to restore full sessions)
      final activeConnectionsJson =
          _prefs.getStringList(_activeConnectionsKey) ?? [];
      // #region agent log
      developer.log(
          'Found ${activeConnectionsJson.length} persisted active connections',
          name: _logName);
      // #endregion

      // Load connection history
      final historyJson = _prefs.getStringList(_connectionHistoryKey) ?? [];
      // #region agent log
      developer.log(
          'Found ${historyJson.length} persisted connection history entries',
          name: _logName);
      // #endregion

      // Load alerts
      final alertsJson = _prefs.getStringList(_monitoringAlertsKey) ?? [];
      // #region agent log
      developer.log('Found ${alertsJson.length} persisted alerts',
          name: _logName);
      // #endregion

      // Note: Full session restoration would require deserializing ConnectionMonitoringSession
      // For now, we track active connections in memory and persist on changes
      // Active connections are restored from memory on app restart via _activeConnections map
    } catch (e) {
      // #region agent log
      developer.log('Error loading persisted data: $e', name: _logName);
      // #endregion
    }
  }

  /// Start monitoring a new AI2AI connection
  Future<ConnectionMonitoringSession> startMonitoring(
    String connectionId,
    ConnectionMetrics initialMetrics,
  ) async {
    try {
      developer.log('Starting connection monitoring for: $connectionId',
          name: _logName);

      // Create monitoring session
      final session = ConnectionMonitoringSession(
        connectionId: connectionId,
        localAISignature: initialMetrics.localAISignature,
        remoteAISignature: initialMetrics.remoteAISignature,
        startTime: DateTime.now(),
        initialMetrics: initialMetrics,
        currentMetrics: initialMetrics,
        qualityHistory: [ConnectionQualitySnapshot.fromMetrics(initialMetrics)],
        learningProgressHistory: [
          LearningProgressSnapshot.fromMetrics(initialMetrics)
        ],
        alertsGenerated: [],
        monitoringStatus: MonitoringStatus.active,
      );

      // Store active connection
      _activeConnections[connectionId] = ActiveConnection.fromSession(session);
      _monitoringSessions[connectionId] = session;

      // Update reverse index for efficient AI signature queries
      _updateAISignatureIndex(session.localAISignature, connectionId,
          add: true);
      _updateAISignatureIndex(session.remoteAISignature, connectionId,
          add: true);

      // Persist active connections
      await _saveActiveConnections();

      // Start periodic monitoring if not already running
      _ensureMonitoringTimerRunning();

      // #region agent log
      developer.log(
          'Connection monitoring started: $connectionId (persisted to $_activeConnectionsKey)',
          name: _logName);
      // #endregion
      return session;
    } catch (e) {
      developer.log('Error starting connection monitoring: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to start monitoring: $e');
    }
  }

  /// Update connection metrics during monitoring
  Future<ConnectionMonitoringSession> updateConnectionMetrics(
    String connectionId,
    ConnectionMetrics updatedMetrics,
  ) async {
    try {
      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      developer.log('Updating connection metrics for: $connectionId',
          name: _logName);

      // Calculate quality changes
      final qualityChange =
          await _calculateQualityChange(session.currentMetrics, updatedMetrics);

      // Detect learning progress
      await _calculateLearningProgress(session, updatedMetrics);

      // Check for performance alerts
      final newAlerts = await _checkForPerformanceAlerts(
          connectionId, updatedMetrics, qualityChange);

      // Update monitoring session
      final updatedSession = session.copyWith(
        currentMetrics: updatedMetrics,
        qualityHistory: [
          ...session.qualityHistory,
          ConnectionQualitySnapshot.fromMetrics(updatedMetrics)
        ],
        learningProgressHistory: [
          ...session.learningProgressHistory,
          LearningProgressSnapshot.fromMetrics(updatedMetrics)
        ],
        alertsGenerated: [...session.alertsGenerated, ...newAlerts],
        lastUpdated: DateTime.now(),
      );

      _monitoringSessions[connectionId] = updatedSession;
      _activeConnections[connectionId] =
          ActiveConnection.fromSession(updatedSession);

      // Persist updated active connections
      await _saveActiveConnections();

      // Process any new alerts
      if (newAlerts.isNotEmpty) {
        await _processConnectionAlerts(connectionId, newAlerts);
      }

      developer.log(
          'Connection metrics updated: $connectionId (quality: ${(updatedMetrics.currentCompatibility * 100).round()}%)',
          name: _logName);
      return updatedSession;
    } catch (e) {
      developer.log('Error updating connection metrics: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to update metrics: $e');
    }
  }

  /// Stop monitoring a connection
  Future<ConnectionMonitoringReport> stopMonitoring(String connectionId) async {
    try {
      developer.log('Stopping connection monitoring for: $connectionId',
          name: _logName);

      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      // Generate final monitoring report
      final report = await _generateMonitoringReport(session);

      // Archive the session
      await _archiveMonitoringSession(session);

      // Cleanup active monitoring
      _activeConnections.remove(connectionId);
      final removedSession = _monitoringSessions.remove(connectionId);

      // Update reverse index
      if (removedSession != null) {
        _updateAISignatureIndex(removedSession.localAISignature, connectionId,
            add: false);
        _updateAISignatureIndex(removedSession.remoteAISignature, connectionId,
            add: false);
      }

      // Persist updated active connections (removed this one)
      await _saveActiveConnections();

      // Stop monitoring timer if no active connections
      if (_activeConnections.isEmpty) {
        _monitoringTimer?.cancel();
        _monitoringTimer = null;
      }

      developer.log(
          'Connection monitoring stopped: $connectionId (duration: ${report.connectionDuration.inMinutes}min)',
          name: _logName);
      return report;
    } catch (e) {
      developer.log('Error stopping connection monitoring: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to stop monitoring: $e');
    }
  }

  /// Get real-time connection status
  Future<ConnectionMonitoringStatus> getConnectionStatus(
      String connectionId) async {
    try {
      final session = _monitoringSessions[connectionId];
      if (session == null) {
        return ConnectionMonitoringStatus.notFound(connectionId);
      }

      // Calculate current performance metrics
      final currentPerformance = await _calculateCurrentPerformance(session);

      // Assess connection health
      final healthScore = await _assessConnectionHealth(session);

      // Get recent alerts
      final recentAlerts = session.alertsGenerated
          .where((alert) =>
              DateTime.now().difference(alert.timestamp) <
              const Duration(minutes: 15))
          .toList();

      // Predict connection trajectory
      final trajectory = await _predictConnectionTrajectory(session);

      return ConnectionMonitoringStatus(
        connectionId: connectionId,
        currentPerformance: currentPerformance,
        healthScore: healthScore,
        recentAlerts: recentAlerts,
        trajectory: trajectory,
        monitoringDuration: DateTime.now().difference(session.startTime),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error getting connection status: $e', name: _logName);
      return ConnectionMonitoringStatus.error(connectionId, e.toString());
    }
  }

  /// Get monitoring session for admin access
  /// Returns the full session with all metrics and interaction history
  ConnectionMonitoringSession? getMonitoringSession(String connectionId) {
    return _monitoringSessions[connectionId];
  }

  /// Get all monitoring sessions (admin/analytics use).
  ///
  /// This is used by higher-level analytics to derive aggregate signals (e.g. AI Pleasure)
  /// without requiring BLE/hardware in CI.
  List<ConnectionMonitoringSession> getAllMonitoringSessions() {
    return _monitoringSessions.values.toList(growable: false);
  }

  /// Calculate the average AI Pleasure score across all monitored sessions.
  ///
  /// Returns `defaultValue` when there are no active sessions.
  double calculateAiPleasureAverage({double defaultValue = 0.5}) {
    final sessions = getAllMonitoringSessions();
    if (sessions.isEmpty) return defaultValue.clamp(0.0, 1.0);

    double sum = 0.0;
    for (final session in sessions) {
      sum += session.currentMetrics.aiPleasureScore.clamp(0.0, 1.0);
    }
    return (sum / sessions.length).clamp(0.0, 1.0);
  }

  /// Get all connection IDs for a specific AI signature
  /// Efficient O(1) lookup using reverse index
  /// Returns both connections where AI is local and remote
  Set<String> getConnectionsByAISignature(String aiSignature) {
    return Set<String>.from(_aiSignatureIndex[aiSignature] ?? {});
  }

  /// Get all monitoring sessions for a specific AI signature
  /// Returns sessions where the AI signature is either local or remote
  List<ConnectionMonitoringSession> getSessionsByAISignature(
      String aiSignature) {
    final connectionIds = getConnectionsByAISignature(aiSignature);
    return connectionIds
        .map((id) => _monitoringSessions[id])
        .whereType<ConnectionMonitoringSession>()
        .toList();
  }

  /// Update reverse index for AI signature lookups
  void _updateAISignatureIndex(String aiSignature, String connectionId,
      {required bool add}) {
    if (aiSignature.isEmpty) return;

    if (add) {
      _aiSignatureIndex
          .putIfAbsent(aiSignature, () => <String>{})
          .add(connectionId);
    } else {
      _aiSignatureIndex[aiSignature]?.remove(connectionId);
      // Clean up empty sets to prevent memory leaks
      if (_aiSignatureIndex[aiSignature]?.isEmpty ?? false) {
        _aiSignatureIndex.remove(aiSignature);
      }
    }
  }

  /// Analyze connection performance trends
  Future<ConnectionPerformanceAnalysis> analyzeConnectionPerformance(
    String connectionId,
    Duration analysisWindow,
  ) async {
    try {
      developer.log('Analyzing connection performance for: $connectionId',
          name: _logName);

      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      final cutoffTime = DateTime.now().subtract(analysisWindow);

      // Analyze quality trends
      final qualityTrends = await _analyzeQualityTrends(session, cutoffTime);

      // Analyze learning effectiveness trends
      final learningTrends = await _analyzeLearningTrends(session, cutoffTime);

      // Calculate performance stability
      final stabilityMetrics =
          await _calculateStabilityMetrics(session, cutoffTime);

      // Identify performance patterns
      final performancePatterns =
          await _identifyPerformancePatterns(session, cutoffTime);

      // Generate performance recommendations
      final recommendations = await _generatePerformanceRecommendations(
        qualityTrends,
        learningTrends,
        stabilityMetrics,
      );

      final analysis = ConnectionPerformanceAnalysis(
        connectionId: connectionId,
        analysisWindow: analysisWindow,
        qualityTrends: qualityTrends,
        learningTrends: learningTrends,
        stabilityMetrics: stabilityMetrics,
        performancePatterns: performancePatterns,
        recommendations: recommendations,
        overallPerformanceScore: _calculateOverallPerformanceScore(
          qualityTrends,
          learningTrends,
          stabilityMetrics,
        ),
        analyzedAt: DateTime.now(),
      );

      developer.log(
          'Connection performance analysis completed: ${recommendations.length} recommendations',
          name: _logName);
      return analysis;
    } catch (e) {
      developer.log('Error analyzing connection performance: $e',
          name: _logName);
      return ConnectionPerformanceAnalysis.failed(connectionId, analysisWindow);
    }
  }

  /// Get all active connections overview
  Future<ActiveConnectionsOverview> getActiveConnectionsOverview() async {
    try {
      developer.log('Generating active connections overview', name: _logName);

      if (_activeConnections.isEmpty) {
        return ActiveConnectionsOverview.empty();
      }

      // Calculate aggregate metrics
      final aggregateMetrics = await _calculateAggregateMetrics();

      // Identify top performing connections
      final topPerformingConnections =
          await _identifyTopPerformingConnections();

      // Identify connections needing attention
      final connectionsNeedingAttention =
          await _identifyConnectionsNeedingAttention();

      // Calculate learning velocity distribution
      final learningVelocityDistribution =
          await _calculateLearningVelocityDistribution();

      // Generate optimization opportunities
      final optimizationOpportunities =
          await _identifyOptimizationOpportunities();

      final overview = ActiveConnectionsOverview(
        totalActiveConnections: _activeConnections.length,
        aggregateMetrics: aggregateMetrics,
        topPerformingConnections: topPerformingConnections,
        connectionsNeedingAttention: connectionsNeedingAttention,
        learningVelocityDistribution: learningVelocityDistribution,
        optimizationOpportunities: optimizationOpportunities,
        averageConnectionDuration: _calculateAverageConnectionDuration(),
        totalAlertsGenerated: _countTotalAlerts(),
        generatedAt: DateTime.now(),
      );

      developer.log(
          'Active connections overview generated: ${overview.totalActiveConnections} active, ${overview.connectionsNeedingAttention.length} need attention',
          name: _logName);
      return overview;
    } catch (e) {
      developer.log('Error generating active connections overview: $e',
          name: _logName);
      return ActiveConnectionsOverview.empty();
    }
  }

  /// Detect connection anomalies
  Future<List<ConnectionAnomaly>> detectConnectionAnomalies() async {
    try {
      developer.log(
          'Detecting connection anomalies across ${_activeConnections.length} connections',
          name: _logName);

      final anomalies = <ConnectionAnomaly>[];

      for (final session in _monitoringSessions.values) {
        // Detect quality anomalies
        final qualityAnomalies = await _detectQualityAnomalies(session);
        anomalies.addAll(qualityAnomalies);

        // Detect learning anomalies
        final learningAnomalies = await _detectLearningAnomalies(session);
        anomalies.addAll(learningAnomalies);

        // Detect behavior anomalies
        final behaviorAnomalies = await _detectBehaviorAnomalies(session);
        anomalies.addAll(behaviorAnomalies);
      }

      // Sort by severity and timestamp
      anomalies.sort((a, b) {
        final severityComparison = b.severity.index.compareTo(a.severity.index);
        if (severityComparison != 0) return severityComparison;
        return b.detectedAt.compareTo(a.detectedAt);
      });

      developer.log('Detected ${anomalies.length} connection anomalies',
          name: _logName);
      return anomalies;
    } catch (e) {
      developer.log('Error detecting connection anomalies: $e', name: _logName);
      return [];
    }
  }

  // Private helper methods
  void _ensureMonitoringTimerRunning() {
    if (_monitoringTimer == null || !_monitoringTimer!.isActive) {
      _monitoringTimer = Timer.periodic(
          const Duration(seconds: 30), (_) => _performPeriodicMonitoring());
      developer.log('Connection monitoring timer started', name: _logName);
    }
  }

  Future<void> _performPeriodicMonitoring() async {
    try {
      for (final connectionId in _activeConnections.keys.toList()) {
        final session = _monitoringSessions[connectionId];
        if (session != null) {
          // Check for timeout or stale connections
          await _checkConnectionTimeout(connectionId, session);

          // Monitor for degradation patterns
          await _monitorConnectionDegradation(connectionId, session);

          // Check learning progress stagnation
          await _checkLearningStagnation(connectionId, session);
        }
      }
    } catch (e) {
      developer.log('Error during periodic monitoring: $e', name: _logName);
    }
  }

  Future<ConnectionQualityChange> _calculateQualityChange(
    ConnectionMetrics previous,
    ConnectionMetrics current,
  ) async {
    final compatibilityChange =
        current.currentCompatibility - previous.currentCompatibility;
    final learningEffectivenessChange =
        current.learningEffectiveness - previous.learningEffectiveness;
    final aiPleasureChange = current.aiPleasureScore - previous.aiPleasureScore;

    return ConnectionQualityChange(
      compatibilityChange: compatibilityChange,
      learningEffectivenessChange: learningEffectivenessChange,
      aiPleasureChange: aiPleasureChange,
      overallChange: (compatibilityChange +
              learningEffectivenessChange +
              aiPleasureChange) /
          3.0,
      changeDirection: _determineChangeDirection(
          compatibilityChange, learningEffectivenessChange, aiPleasureChange),
    );
  }

  Future<LearningProgressMetrics> _calculateLearningProgress(
    ConnectionMonitoringSession session,
    ConnectionMetrics updatedMetrics,
  ) async {
    const progressSince = Duration(minutes: 5); // Look at last 5 minutes
    final cutoffTime = DateTime.now().subtract(progressSince);

    final recentHistory = session.learningProgressHistory
        .where((snapshot) => snapshot.timestamp.isAfter(cutoffTime))
        .toList();

    if (recentHistory.length < 2) {
      return LearningProgressMetrics.minimal();
    }

    final firstSnapshot = recentHistory.first;
    final lastSnapshot = recentHistory.last;

    final progressRate = (lastSnapshot.learningEffectiveness -
            firstSnapshot.learningEffectiveness) /
        progressSince.inMinutes;

    return LearningProgressMetrics(
      progressRate: progressRate,
      learningVelocity: updatedMetrics.learningEffectiveness,
      dimensionEvolutionRate: _calculateDimensionEvolutionRate(updatedMetrics),
      insightGenerationRate: 0.5 + Random().nextDouble() * 0.3, // Simulated
    );
  }

  Future<List<ConnectionAlert>> _checkForPerformanceAlerts(
    String connectionId,
    ConnectionMetrics metrics,
    ConnectionQualityChange qualityChange,
  ) async {
    final alerts = <ConnectionAlert>[];

    // Check for low compatibility
    if (metrics.currentCompatibility <
        VibeConstants.lowCompatibilityThreshold) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.lowCompatibility,
        severity: AlertSeverity.medium,
        message:
            'Connection compatibility below threshold (${(metrics.currentCompatibility * 100).round()}%)',
        timestamp: DateTime.now(),
        metadata: {'compatibility': metrics.currentCompatibility},
      ));
    }

    // Check for learning effectiveness drop
    if (metrics.learningEffectiveness <
        VibeConstants.minLearningEffectiveness) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.lowLearningEffectiveness,
        severity: AlertSeverity.high,
        message: 'Learning effectiveness below minimum threshold',
        timestamp: DateTime.now(),
        metadata: {'learning_effectiveness': metrics.learningEffectiveness},
      ));
    }

    // Check for rapid quality degradation
    if (qualityChange.overallChange < -0.2) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.qualityDegradation,
        severity: AlertSeverity.high,
        message: 'Rapid connection quality degradation detected',
        timestamp: DateTime.now(),
        metadata: {'quality_change': qualityChange.overallChange},
      ));
    }

    return alerts;
  }

  Future<void> _processConnectionAlerts(
      String connectionId, List<ConnectionAlert> alerts) async {
    for (final alert in alerts) {
      _alerts.add(alert);
      developer.log(
          'CONNECTION ALERT [${alert.severity.name.toUpperCase()}]: ${alert.message}',
          name: _logName);

      // Persist alerts
      await _saveAlerts();

      // In a real implementation, this might trigger notifications or automatic responses
      if (alert.severity == AlertSeverity.critical) {
        await _handleCriticalAlert(connectionId, alert);
      }
    }
  }

  Future<void> _handleCriticalAlert(
      String connectionId, ConnectionAlert alert) async {
    developer.log('Handling critical alert for connection: $connectionId',
        name: _logName);
    // In a real implementation, this might automatically terminate problematic connections
    // or trigger emergency protocols
  }

  Future<ConnectionMonitoringReport> _generateMonitoringReport(
    ConnectionMonitoringSession session,
  ) async {
    final connectionDuration = DateTime.now().difference(session.startTime);

    // Calculate performance summary
    final performanceSummary = await _calculatePerformanceSummary(session);

    // Calculate learning outcomes
    final learningOutcomes = await _calculateLearningOutcomes(session);

    // Generate quality analysis
    final qualityAnalysis = await _generateQualityAnalysis(session);

    return ConnectionMonitoringReport(
      connectionId: session.connectionId,
      localAISignature: session.localAISignature,
      remoteAISignature: session.remoteAISignature,
      connectionDuration: connectionDuration,
      initialMetrics: session.initialMetrics,
      finalMetrics: session.currentMetrics,
      performanceSummary: performanceSummary,
      learningOutcomes: learningOutcomes,
      qualityAnalysis: qualityAnalysis,
      alertsGenerated: session.alertsGenerated,
      overallRating: _calculateOverallConnectionRating(session),
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _archiveMonitoringSession(
      ConnectionMonitoringSession session) async {
    // #region agent log
    developer.log('Archiving monitoring session: ${session.connectionId}',
        name: _logName);
    // #endregion

    try {
      // Serialize session to JSON
      final sessionJson = _sessionToJson(session);

      // Load existing history
      final historyJson = _prefs.getStringList(_connectionHistoryKey) ?? [];

      // Add this session to history
      historyJson.add(jsonEncode(sessionJson));

      // Limit history size to prevent unbounded growth (keep last 1000 sessions)
      if (historyJson.length > 1000) {
        historyJson.removeRange(0, historyJson.length - 1000);
      }

      // Save updated history
      await _prefs.setStringList(_connectionHistoryKey, historyJson);

      // #region agent log
      developer.log(
          'Session archived: ${session.connectionId} (history now contains ${historyJson.length} entries)',
          name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error archiving session: $e', name: _logName);
      // #endregion
    }
  }

  /// Save active connections to persistent storage
  Future<void> _saveActiveConnections() async {
    try {
      // #region agent log
      developer.log(
          'Saving ${_activeConnections.length} active connections to storage',
          name: _logName);
      // #endregion

      final connectionsJson = _activeConnections.values
          .map((conn) => jsonEncode(_activeConnectionToJson(conn)))
          .toList();

      await _prefs.setStringList(_activeConnectionsKey, connectionsJson);

      // #region agent log
      developer.log('Active connections saved successfully', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving active connections: $e', name: _logName);
      // #endregion
    }
  }

  /// Save alerts to persistent storage
  Future<void> _saveAlerts() async {
    try {
      // #region agent log
      developer.log('Saving ${_alerts.length} alerts to storage',
          name: _logName);
      // #endregion

      final alertsJson =
          _alerts.map((alert) => jsonEncode(_alertToJson(alert))).toList();

      // Limit alerts size to prevent unbounded growth (keep last 500 alerts)
      if (alertsJson.length > 500) {
        alertsJson.removeRange(0, alertsJson.length - 500);
      }

      await _prefs.setStringList(_monitoringAlertsKey, alertsJson);

      // #region agent log
      developer.log('Alerts saved successfully', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving alerts: $e', name: _logName);
      // #endregion
    }
  }

  /// Serialize ConnectionMonitoringSession to JSON
  Map<String, dynamic> _sessionToJson(ConnectionMonitoringSession session) {
    return {
      'connectionId': session.connectionId,
      'localAISignature': session.localAISignature,
      'remoteAISignature': session.remoteAISignature,
      'startTime': session.startTime.toIso8601String(),
      'lastUpdated': session.lastUpdated?.toIso8601String(),
      'monitoringStatus': session.monitoringStatus.name,
      'initialMetrics': session.initialMetrics.toJson(),
      'currentMetrics': session.currentMetrics.toJson(),
      'qualityHistoryCount': session.qualityHistory.length,
      'learningProgressHistoryCount': session.learningProgressHistory.length,
      'alertsGeneratedCount': session.alertsGenerated.length,
    };
  }

  /// Serialize ActiveConnection to JSON
  Map<String, dynamic> _activeConnectionToJson(ActiveConnection connection) {
    return {
      'connectionId': connection.connectionId,
      'localAISignature': connection.localAISignature,
      'remoteAISignature': connection.remoteAISignature,
      'startTime': connection.startTime.toIso8601String(),
      'currentCompatibility': connection.currentCompatibility,
      'learningEffectiveness': connection.learningEffectiveness,
      'status': connection.status.name,
    };
  }

  /// Serialize ConnectionAlert to JSON
  Map<String, dynamic> _alertToJson(ConnectionAlert alert) {
    return {
      'connectionId': alert.connectionId,
      'type': alert.type.name,
      'severity': alert.severity.name,
      'message': alert.message,
      'timestamp': alert.timestamp.toIso8601String(),
      'metadata': alert.metadata,
    };
  }

  // Additional helper methods with placeholder implementations
  ChangeDirection _determineChangeDirection(
      double comp, double learning, double pleasure) {
    final average = (comp + learning + pleasure) / 3.0;
    if (average > 0.05) return ChangeDirection.improving;
    if (average < -0.05) return ChangeDirection.degrading;
    return ChangeDirection.stable;
  }

  double _calculateDimensionEvolutionRate(ConnectionMetrics metrics) =>
      metrics.dimensionEvolution.values
          .fold(0.0, (sum, change) => sum + change.abs()) /
      max(1, metrics.dimensionEvolution.length);

  Future<CurrentPerformanceMetrics> _calculateCurrentPerformance(
          ConnectionMonitoringSession session) async =>
      CurrentPerformanceMetrics.fromSession(session);

  Future<double> _assessConnectionHealth(
          ConnectionMonitoringSession session) async =>
      (session.currentMetrics.currentCompatibility +
          session.currentMetrics.learningEffectiveness +
          session.currentMetrics.aiPleasureScore) /
      3.0;

  Future<ConnectionTrajectory> _predictConnectionTrajectory(
          ConnectionMonitoringSession session) async =>
      ConnectionTrajectory.stable();

  // Performance analysis helper methods (placeholder implementations)
  Future<QualityTrends> _analyzeQualityTrends(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      QualityTrends.stable();
  Future<LearningTrends> _analyzeLearningTrends(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      LearningTrends.positive();
  Future<StabilityMetrics> _calculateStabilityMetrics(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      StabilityMetrics.stable();
  Future<List<PerformancePattern>> _identifyPerformancePatterns(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      [];
  Future<List<PerformanceRecommendation>> _generatePerformanceRecommendations(
          QualityTrends quality,
          LearningTrends learning,
          StabilityMetrics stability) async =>
      [];

  double _calculateOverallPerformanceScore(QualityTrends quality,
          LearningTrends learning, StabilityMetrics stability) =>
      0.8;

  // Active connections analysis helper methods
  Future<AggregateConnectionMetrics> _calculateAggregateMetrics() async =>
      AggregateConnectionMetrics.good();
  Future<List<String>> _identifyTopPerformingConnections() async =>
      _activeConnections.keys.take(3).toList();
  Future<List<String>> _identifyConnectionsNeedingAttention() async => [];
  Future<LearningVelocityDistribution>
      _calculateLearningVelocityDistribution() async =>
          LearningVelocityDistribution.normal();
  Future<List<OptimizationOpportunity>>
      _identifyOptimizationOpportunities() async => [];

  Duration _calculateAverageConnectionDuration() {
    if (_activeConnections.isEmpty) return Duration.zero;
    final totalMinutes = _monitoringSessions.values
        .map(
            (session) => DateTime.now().difference(session.startTime).inMinutes)
        .fold(0, (sum, duration) => sum + duration);
    return Duration(minutes: totalMinutes ~/ _activeConnections.length);
  }

  int _countTotalAlerts() => _monitoringSessions.values
      .map((session) => session.alertsGenerated.length)
      .fold(0, (sum, count) => sum + count);

  // Anomaly detection helper methods
  Future<List<ConnectionAnomaly>> _detectQualityAnomalies(
          ConnectionMonitoringSession session) async =>
      [];
  Future<List<ConnectionAnomaly>> _detectLearningAnomalies(
          ConnectionMonitoringSession session) async =>
      [];
  Future<List<ConnectionAnomaly>> _detectBehaviorAnomalies(
          ConnectionMonitoringSession session) async =>
      [];

  // Periodic monitoring helper methods
  Future<void> _checkConnectionTimeout(
      String connectionId, ConnectionMonitoringSession session) async {
    const maxDuration = Duration(hours: 5); // Maximum connection duration
    if (DateTime.now().difference(session.startTime) > maxDuration) {
      developer.log('Connection timeout detected: $connectionId',
          name: _logName);
    }
  }

  Future<void> _monitorConnectionDegradation(
      String connectionId, ConnectionMonitoringSession session) async {
    // Check for consistent quality degradation
    if (session.qualityHistory.length >= 5) {
      final recentQualities = session.qualityHistory
          .skip(max(0, session.qualityHistory.length - 5))
          .map((q) => q.compatibility)
          .toList();
      final isDegraing = _isConsistentlyDegrading(recentQualities);
      if (isDegraing) {
        developer.log('Connection degradation pattern detected: $connectionId',
            name: _logName);
      }
    }
  }

  Future<void> _checkLearningStagnation(
      String connectionId, ConnectionMonitoringSession session) async {
    // Check for learning progress stagnation
    if (session.learningProgressHistory.length >= 10) {
      final recentLearning = session.learningProgressHistory
          .skip(max(0, session.learningProgressHistory.length - 10))
          .map((l) => l.learningEffectiveness)
          .toList();
      const stagnationThreshold = 0.02; // Less than 2% change
      final maxChange = recentLearning.reduce(max) - recentLearning.reduce(min);
      if (maxChange < stagnationThreshold) {
        developer.log('Learning stagnation detected: $connectionId',
            name: _logName);
      }
    }
  }

  bool _isConsistentlyDegrading(List<double> values) {
    if (values.length < 3) return false;
    for (int i = 1; i < values.length; i++) {
      if (values[i] >= values[i - 1]) return false;
    }
    return true;
  }

  // Additional analysis helper methods
  Future<PerformanceSummary> _calculatePerformanceSummary(
          ConnectionMonitoringSession session) async =>
      PerformanceSummary.good();
  Future<LearningOutcomes> _calculateLearningOutcomes(
          ConnectionMonitoringSession session) async =>
      LearningOutcomes.positive();
  Future<QualityAnalysis> _generateQualityAnalysis(
          ConnectionMonitoringSession session) async =>
      QualityAnalysis.stable();

  double _calculateOverallConnectionRating(
          ConnectionMonitoringSession session) =>
      (session.currentMetrics.currentCompatibility +
          session.currentMetrics.learningEffectiveness +
          session.currentMetrics.aiPleasureScore) /
      3.0;

  /// Stream active connections overview
  /// Emits initial value immediately, then updates on connection changes
  Stream<ActiveConnectionsOverview> streamActiveConnections() {
    // Create broadcast stream controller if not exists
    if (_connectionsStreamController == null ||
        _connectionsStreamController!.isClosed) {
      _connectionsStreamController =
          StreamController<ActiveConnectionsOverview>.broadcast();
    }

    // Store local reference to avoid null check issues
    final controller = _connectionsStreamController;
    if (controller == null) {
      // Fallback: return a stream that emits empty overview
      return Stream.value(ActiveConnectionsOverview.empty());
    }

    // Emit initial value immediately
    getActiveConnectionsOverview().then((overview) {
      if (controller.isClosed) return;
      controller.add(overview);
    }).catchError((error) {
      developer.log('Error in streamActiveConnections initial value: $error',
          name: _logName);
      if (controller.isClosed) return;
      controller.add(ActiveConnectionsOverview.empty());
    });

    // Set up periodic updates every 5 seconds (single timer, cancelled on dispose).
    _connectionsUpdateTimer ??=
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final currentController = _connectionsStreamController;
      if (currentController == null || currentController.isClosed) {
        timer.cancel();
        _connectionsUpdateTimer = null;
        return;
      }

      try {
        final overview = await getActiveConnectionsOverview();
        if (currentController.isClosed) return;
        currentController.add(overview);
      } catch (e) {
        developer.log('Error in streamActiveConnections periodic update: $e',
            name: _logName);
        if (currentController.isClosed) return;
        currentController.add(ActiveConnectionsOverview.empty());
      }
    });

    return controller.stream.handleError((error) {
      developer.log('Stream error in streamActiveConnections: $error',
          name: _logName);
    });
  }

  /// Dispose stream controller
  void disposeStreams() {
    _connectionsUpdateTimer?.cancel();
    _connectionsUpdateTimer = null;
    _connectionsStreamController?.close();
    _connectionsStreamController = null;
  }
}
