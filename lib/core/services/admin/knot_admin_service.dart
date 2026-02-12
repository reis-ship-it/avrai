// Knot Admin Service
// 
// Provides admin-side knot analysis and visualization data
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_distribution_data.dart';
import 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';
import 'package:avrai_knot/models/knot/knot_personality_correlations.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_data_api_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai/core/services/admin/admin_auth_service.dart';

/// Admin service for knot visualization and analysis
/// 
/// **Access:** Requires admin authentication
/// **Purpose:** System monitoring, research insights, debugging
class KnotAdminService {
  static const String _logName = 'KnotAdminService';

  final KnotStorageService _knotStorageService;
  final KnotDataAPI _knotDataAPI;
  final PersonalityKnotService _knotService;
  final AdminAuthService _adminAuthService;

  KnotAdminService({
    required KnotStorageService knotStorageService,
    required KnotDataAPI knotDataAPI,
    required PersonalityKnotService knotService,
    required AdminAuthService adminAuthService,
  })  : _knotStorageService = knotStorageService,
        _knotDataAPI = knotDataAPI,
        _knotService = knotService,
        _adminAuthService = adminAuthService;

  /// Check if admin is authorized
  bool get isAuthorized {
    return _adminAuthService.isAuthenticated();
  }

  /// Get knot distribution data for admin visualization
  /// 
  /// **Requires:** Admin authentication
  Future<KnotDistributionData> getKnotDistributionData({
    String? location,
    String? category,
    DateTime? timeRange,
  }) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting knot distribution data for admin',
      name: _logName,
    );

    return await _knotDataAPI.getKnotDistributions(
      location: location,
      category: category,
      timeRange: timeRange,
    );
  }

  /// Get knot pattern analysis for admin visualization
  /// 
  /// **Requires:** Admin authentication
  Future<KnotPatternAnalysis> getKnotPatternAnalysis({
    required AnalysisType type,
  }) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting knot pattern analysis for admin: type=$type',
      name: _logName,
    );

    return await _knotDataAPI.getKnotPatterns(type: type);
  }

  /// Get knot-personality correlations for admin visualization
  /// 
  /// **Requires:** Admin authentication
  Future<KnotPersonalityCorrelations> getKnotPersonalityCorrelations() async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting knot-personality correlations for admin',
      name: _logName,
    );

    return await _knotDataAPI.getCorrelations();
  }

  /// Get knot for specific user (admin only)
  /// 
  /// **Requires:** Admin authentication
  Future<PersonalityKnot?> getUserKnot(String agentId) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    final displayId = agentId.length >= 10 ? '${agentId.substring(0, 10)}...' : agentId;
    developer.log(
      'Getting knot for user: $displayId',
      name: _logName,
    );

    return await _knotStorageService.loadKnot(agentId);
  }

  /// Test knot generation from profile (admin debug tool)
  /// 
  /// **Requires:** Admin authentication
  Future<PersonalityKnot> testKnotGeneration({
    required Map<String, double> dimensions,
  }) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Testing knot generation for admin',
      name: _logName,
    );

    // Create a test profile for knot generation
    // In production, this would use PersonalityProfile
    // For now, create a minimal test knot from dimensions
    // TODO: Use PersonalityProfile when available
    final testAgentId = 'admin_test_${DateTime.now().millisecondsSinceEpoch}';
    final testKnot = await _knotService.generateKnot(
      PersonalityProfile.initial(testAgentId),
    );

    return testKnot;
  }

  /// Validate knot structure (admin debug tool)
  /// 
  /// **Requires:** Admin authentication
  Future<bool> validateKnot(PersonalityKnot knot) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Validating knot structure for admin',
      name: _logName,
    );

    // Basic validation checks
    if (knot.braidData.isEmpty) {
      return false;
    }

    if (knot.invariants.crossingNumber < 0) {
      return false;
    }

    if (knot.invariants.jonesPolynomial.isEmpty &&
        knot.invariants.alexanderPolynomial.isEmpty) {
      return false;
    }

    return true;
  }

  /// Get system-wide knot statistics
  /// 
  /// **Requires:** Admin authentication
  Future<Map<String, dynamic>> getSystemKnotStatistics() async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting system-wide knot statistics for admin',
      name: _logName,
    );

    // TODO: Calculate actual statistics from knot storage
    // For now, return placeholder structure
    return {
      'totalKnots': 0,
      'averageCrossingNumber': 0.0,
      'averageWrithe': 0.0,
      'knotTypes': <String, int>{},
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Get matching insights for admin visualization
  /// 
  /// **Requires:** Admin authentication
  /// **Returns:** Matching statistics and insights
  Future<Map<String, dynamic>> getMatchingInsights() async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting matching insights for admin',
      name: _logName,
    );

    // TODO: Calculate actual matching insights from braided knots and connections
    // For now, return placeholder structure
    return {
      'totalMatches': 0,
      'averageMatchingScore': 0.0,
      'knotCompatibilityAverage': 0.0,
      'quantumCompatibilityAverage': 0.0,
      'integratedCompatibilityAverage': 0.0,
      'successRateByKnotType': <String, double>{},
      'topMatchingPatterns': <Map<String, dynamic>>[],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Get evolution tracking data
  /// 
  /// **Requires:** Admin authentication
  /// **Parameters:**
  /// - `agentId`: Optional agent ID to track specific user
  /// - `timeRange`: Optional time range filter
  /// **Returns:** Evolution data including timeline of changes
  Future<Map<String, dynamic>> getEvolutionTracking({
    String? agentId,
    DateTime? timeRange,
  }) async {
    if (!isAuthorized) {
      throw Exception('Admin authentication required');
    }

    developer.log(
      'Getting evolution tracking for admin: agentId=${agentId?.substring(0, 10) ?? "all"}, timeRange=$timeRange',
      name: _logName,
    );

    try {
      if (agentId != null) {
        // Get evolution history for specific agent
        final history = await _knotStorageService.loadEvolutionHistory(agentId);
        
        // Filter by time range if provided
        final filteredHistory = timeRange != null
            ? history.where((snapshot) => snapshot.timestamp.isAfter(timeRange)).toList()
            : history;

        return {
          'agentId': agentId,
          'snapshots': filteredHistory.map((s) => {
            'timestamp': s.timestamp.toIso8601String(),
            'crossingNumber': s.knot.invariants.crossingNumber,
            'writhe': s.knot.invariants.writhe,
            'complexity': s.knot.invariants.crossingNumber * s.knot.invariants.writhe.abs(),
          }).toList(),
          'totalSnapshots': filteredHistory.length,
          'timeRange': timeRange?.toIso8601String(),
        };
      } else {
        // TODO: Get aggregate evolution data across all users
        // For now, return placeholder structure
        return {
          'totalUsersTracked': 0,
          'averageSnapshotsPerUser': 0.0,
          'evolutionTrends': <Map<String, dynamic>>[],
          'timeRange': timeRange?.toIso8601String(),
        };
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get evolution tracking: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
}
