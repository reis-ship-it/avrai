import 'package:avrai/core/services/admin/admin_auth_service.dart';
import 'package:avrai/core/services/admin/admin_communication_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/expertise/expertise_service.dart';
import 'package:avrai/core/services/community/club_service.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/ml/predictive_analytics.dart';
import 'package:avrai/core/models/expertise/expertise_progress.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/monitoring/network_analytics.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/p2p/federated_learning.dart' as federated;
import 'package:avrai/core/services/admin/permissions/admin_permission_checker.dart';
import 'package:avrai/core/services/admin/permissions/admin_access_control.dart';
import 'package:avrai/core/services/admin/user/admin_user_management_service.dart';
import 'package:avrai/core/services/admin/analytics/admin_analytics_service.dart';
import 'package:avrai/core/services/admin/monitoring/admin_system_monitoring_service.dart';
import 'package:avrai/core/services/admin/export/admin_data_export_service.dart';

/// Runtime Governance Admin Service (Orchestrator)
/// Provides comprehensive real-time access to all system data
/// Requires admin runtime governance authentication
/// Phase 1.6: Refactored to use orchestrator pattern with modular services
class AdminRuntimeGovernanceService {
  final AdminAuthService _authService;
  final AdminCommunicationService _communicationService;
  final BusinessAccountService _businessService;
  final ClubService _clubService;
  // ignore: unused_field
  final CommunityService _communityService; // Reserved for future use
  final PredictiveAnalytics _predictiveAnalytics;
  final ConnectionMonitor _connectionMonitor;
  final AI2AIChatAnalyzer? _chatAnalyzer;
  final SupabaseService _supabaseService;
  // ignore: unused_field
  final ExpertiseService _expertiseService; // Reserved for future use
  final federated.FederatedLearningSystem? _federatedLearningSystem;
  final NetworkAnalytics? _networkAnalytics;

  // Phase 1.6: Service modules
  late final AdminPermissionChecker _permissionChecker;
  late final AdminAccessControl _accessControl;
  late final AdminUserManagementService _userManagementService;
  late final AdminAnalyticsService _analyticsService;
  late final AdminSystemMonitoringService _monitoringService;
  late final AdminDataExportService _dataExportService;

  AdminRuntimeGovernanceService({
    required AdminAuthService authService,
    required AdminCommunicationService communicationService,
    required BusinessAccountService businessService,
    ClubService? clubService,
    CommunityService? communityService,
    required PredictiveAnalytics predictiveAnalytics,
    required ConnectionMonitor connectionMonitor,
    AI2AIChatAnalyzer? chatAnalyzer,
    SupabaseService? supabaseService,
    ExpertiseService? expertiseService,
    NetworkAnalytics? networkAnalytics,
    federated.FederatedLearningSystem? federatedLearningSystem,
  })  : _authService = authService,
        _communicationService = communicationService,
        _businessService = businessService,
        _clubService = clubService ?? ClubService(),
        _communityService = communityService ?? CommunityService(),
        _predictiveAnalytics = predictiveAnalytics,
        _connectionMonitor = connectionMonitor,
        _chatAnalyzer = chatAnalyzer,
        _supabaseService = supabaseService ?? SupabaseService(),
        _expertiseService = expertiseService ?? ExpertiseService(),
        _networkAnalytics = networkAnalytics,
        _federatedLearningSystem = federatedLearningSystem {
    // Phase 1.6: Initialize service modules
    _permissionChecker = AdminPermissionChecker(authService: _authService);
    _accessControl = AdminAccessControl(permissionChecker: _permissionChecker);
    _userManagementService = AdminUserManagementService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      predictiveAnalytics: _predictiveAnalytics,
    );
    _analyticsService = AdminAnalyticsService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      connectionMonitor: _connectionMonitor,
      networkAnalytics: _networkAnalytics,
      chatAnalyzer: _chatAnalyzer,
      federatedLearningSystem: _federatedLearningSystem,
    );
    _monitoringService = AdminSystemMonitoringService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      predictiveAnalytics: _predictiveAnalytics,
    );
    _dataExportService = AdminDataExportService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      businessService: _businessService,
      clubService: _clubService,
      communityService: _communityService,
      communicationService: _communicationService,
      connectionMonitor: _connectionMonitor,
    );
  }

  /// Check if runtime governance access is authorized
  bool get isAuthorized => _permissionChecker.isAuthorized;

  /// Get real-time user data stream
  Stream<UserDataSnapshot> watchUserData(String userId) {
    return _userManagementService.watchUserData(userId);
  }

  /// Get real-time AI data stream
  Stream<AIDataSnapshot> watchAIData(String aiSignature) {
    return _monitoringService.watchAIData(aiSignature);
  }

  /// Get real-time communications stream
  Stream<CommunicationsSnapshot> watchCommunications({
    String? userId,
    String? connectionId,
  }) {
    return _dataExportService.watchCommunications(
      userId: userId,
      connectionId: connectionId,
    );
  }

  /// Get user progress data
  /// Privacy-preserving: Only returns progress metrics, NO personal data
  Future<UserProgressData> getUserProgress(String userId) async {
    return _userManagementService.getUserProgress(userId);
  }

  /// Get user predictions
  /// Privacy-preserving: Only returns AI predictions, NO personal data
  Future<UserPredictionsData> getUserPredictions(String userId) async {
    return _userManagementService.getUserPredictions(userId);
  }

  /// Get all business accounts
  Future<List<BusinessAccountData>> getAllBusinessAccounts() async {
    return _dataExportService.getAllBusinessAccounts();
  }

  /// Get all clubs and communities
  /// Privacy-preserving: Returns club/community data with member AI agent information
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ClubCommunityData>> getAllClubsAndCommunities() async {
    return _dataExportService.getAllClubsAndCommunities();
  }

  /// Get club/community by ID with member AI agents
  /// Privacy-preserving: Returns AI agent data only, no personal info
  Future<ClubCommunityData?> getClubOrCommunityById(String id) async {
    return _dataExportService.getClubOrCommunityById(id);
  }

  /// Get all active AI agents with location and predictions
  /// Privacy-preserving: Returns AI agent data with location and predicted actions
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ActiveAIAgentData>> getAllActiveAIAgents() async {
    return _monitoringService.getAllActiveAIAgents();
  }

  /// Get follower count for a user
  /// Returns number of users following this user
  Future<int> getFollowerCount(String userId) async {
    return _userManagementService.getFollowerCount(userId);
  }

  /// Get users who have a following (follower count >= threshold)
  /// Returns list of user IDs with their follower counts
  Future<Map<String, int>> getUsersWithFollowing({int minFollowers = 1}) async {
    return _userManagementService.getUsersWithFollowing(
        minFollowers: minFollowers);
  }

  /// Search users by AI signature or user ID only
  /// Privacy-preserving: No personal data (name, email, phone, address) is returned
  Future<List<UserSearchResult>> searchUsers({
    String? query, // Search by user ID or AI signature only
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    return _userManagementService.searchUsers(
      query: query,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
    );
  }

  /// Get aggregate privacy metrics (mean privacy score across all users)
  /// Returns the average privacy metrics for all users in the system
  Future<AggregatePrivacyMetrics> getAggregatePrivacyMetrics() async {
    return _analyticsService.getAggregatePrivacyMetrics();
  }

  /// Get comprehensive dashboard data
  Future<GodModeDashboardData> getDashboardData() async {
    return _analyticsService.getDashboardData();
  }

  /// Get all federated learning rounds with participant details
  /// Shows active and completed rounds across the entire network
  Future<List<GodModeFederatedRoundInfo>> getAllFederatedLearningRounds({
    bool? includeCompleted,
  }) async {
    return _analyticsService.getAllFederatedLearningRounds(
      includeCompleted: includeCompleted,
    );
  }

  /// Get collaborative activity metrics
  /// Phase 7 Week 40: Privacy-safe aggregate metrics on collaborative patterns
  Future<CollaborativeActivityMetrics> getCollaborativeActivityMetrics() async {
    return _analyticsService.getCollaborativeActivityMetrics();
  }

  /// Dispose and cleanup
  /// Phase 1.6: Simplified - services handle their own cleanup
  void dispose() {
    // Services handle their own cleanup internally
    // No shared state to clean up after refactoring
  }
}

// Data models for runtime governance admin

/// User data snapshot for admin viewing
/// Privacy-preserving: Contains AI-related data and location data (vibe indicators)
/// Excludes: name, email, phone, home address
class UserDataSnapshot {
  final String userId; // User's unique ID only
  final bool isOnline;
  final DateTime lastActive;
  final Map<String, dynamic>
      data; // AI-related and location data, NO personal info

  UserDataSnapshot({
    required this.userId,
    required this.isOnline,
    required this.lastActive,
    required this.data, // Must not contain: name, email, phone, home_address
    // Location data IS allowed (core vibe indicator)
  });

  /// Validate that no personal data is included
  /// Location data is allowed, but home address is forbidden
  bool get isValid {
    final forbiddenKeys = [
      'name',
      'email',
      'phone',
      'home_address',
      'homeaddress',
      'personal'
    ];
    final forbiddenLocationKeys = [
      'home_address',
      'homeaddress',
      'residential_address'
    ];

    for (final key in data.keys) {
      final lowerKey = key.toLowerCase();

      // Check for forbidden home address
      if (forbiddenLocationKeys
          .any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }

      // Check for other forbidden personal data
      if (forbiddenKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
    }

    return true;
  }
}

class AIDataSnapshot {
  final String aiSignature;
  final bool isActive;
  final int connections;
  final Map<String, dynamic> data;

  AIDataSnapshot({
    required this.aiSignature,
    required this.isActive,
    required this.connections,
    required this.data,
  });
}

class CommunicationsSnapshot {
  final int totalMessages;
  final List<dynamic> recentMessages;
  final int activeConnections;
  final DateTime lastUpdated;

  CommunicationsSnapshot({
    required this.totalMessages,
    required this.recentMessages,
    required this.activeConnections,
    required this.lastUpdated,
  });
}

class UserProgressData {
  final String userId;
  final List<ExpertiseProgress> expertiseProgress;
  final int totalContributions;
  final int pinsEarned;
  final int listsCreated;
  final int spotsAdded;
  final DateTime lastUpdated;

  UserProgressData({
    required this.userId,
    required this.expertiseProgress,
    required this.totalContributions,
    required this.pinsEarned,
    required this.listsCreated,
    required this.spotsAdded,
    required this.lastUpdated,
  });
}

class UserPredictionsData {
  final String userId;
  final String currentStage;
  final List<PredictionAction> predictedActions;
  final List<JourneyStep> journeyPath;
  final double confidence;
  final Duration timeframe;
  final DateTime lastUpdated;

  UserPredictionsData({
    required this.userId,
    required this.currentStage,
    required this.predictedActions,
    required this.journeyPath,
    required this.confidence,
    required this.timeframe,
    required this.lastUpdated,
  });
}

class PredictionAction {
  final String action;
  final double probability;
  final String category;

  PredictionAction({
    required this.action,
    required this.probability,
    required this.category,
  });
}

class JourneyStep {
  final String description;
  final Duration estimatedTime;
  final double likelihood;

  JourneyStep({
    required this.description,
    required this.estimatedTime,
    required this.likelihood,
  });
}

class BusinessAccountData {
  final BusinessAccount account;
  final bool isVerified;
  final int connectedExperts;
  final DateTime lastActivity;

  BusinessAccountData({
    required this.account,
    required this.isVerified,
    required this.connectedExperts,
    required this.lastActivity,
  });
}

class UserSearchResult {
  final String userId;
  final String aiSignature; // Only AI signature, no personal data
  final DateTime createdAt;
  final bool isActive;

  UserSearchResult({
    required this.userId,
    required this.aiSignature,
    required this.createdAt,
    required this.isActive,
  });
}

class GodModeDashboardData {
  final int totalUsers;
  final int activeUsers;
  final int totalBusinessAccounts;
  final int activeConnections;
  final int totalCommunications;
  final double systemHealth;
  final AggregatePrivacyMetrics aggregatePrivacyMetrics;
  final DateTime lastUpdated;

  GodModeDashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBusinessAccounts,
    required this.activeConnections,
    required this.totalCommunications,
    required this.systemHealth,
    required this.aggregatePrivacyMetrics,
    required this.lastUpdated,
  });
}

/// Aggregate privacy metrics showing mean privacy scores across all users
class AggregatePrivacyMetrics {
  /// Mean overall privacy score (0.0-1.0) across all users
  final double meanOverallPrivacyScore;

  /// Mean anonymization level across all users
  final double meanAnonymizationLevel;

  /// Mean data security score across all users
  final double meanDataSecurityScore;

  /// Mean encryption strength across all users
  final double meanEncryptionStrength;

  /// Mean compliance rate across all users
  final double meanComplianceRate;

  /// Total privacy violations across all users
  final int totalPrivacyViolations;

  /// Number of users included in this aggregate
  final int userCount;

  /// When this aggregate was calculated
  final DateTime lastUpdated;

  AggregatePrivacyMetrics({
    required this.meanOverallPrivacyScore,
    required this.meanAnonymizationLevel,
    required this.meanDataSecurityScore,
    required this.meanEncryptionStrength,
    required this.meanComplianceRate,
    required this.totalPrivacyViolations,
    required this.userCount,
    required this.lastUpdated,
  });

  /// Get color indicator for privacy score
  String get scoreLabel {
    if (meanOverallPrivacyScore >= 0.95) return 'Excellent';
    if (meanOverallPrivacyScore >= 0.85) return 'Good';
    if (meanOverallPrivacyScore >= 0.75) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Active AI Agent data for map display
/// Privacy-preserving: Contains AI agent data with location and predictions, NO personal information
class ActiveAIAgentData {
  final String userId;
  final String aiSignature;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final DateTime lastActive;
  final int aiConnections;
  final String aiStatus;
  final List<PredictionAction> predictedActions;
  final String currentStage;
  final double confidence;

  ActiveAIAgentData({
    required this.userId,
    required this.aiSignature,
    required this.latitude,
    required this.longitude,
    required this.isOnline,
    required this.lastActive,
    required this.aiConnections,
    required this.aiStatus,
    required this.predictedActions,
    required this.currentStage,
    required this.confidence,
  });

  /// Get top predicted action
  PredictionAction? get topPredictedAction {
    if (predictedActions.isEmpty) return null;
    return predictedActions
        .reduce((a, b) => a.probability > b.probability ? a : b);
  }
}

/// Club/Community data for admin viewing
/// Privacy-preserving: Contains AI agent data for members, NO personal information
class ClubCommunityData {
  final String id;
  final String name;
  final String? description;
  final String category;
  final bool isClub;
  final int memberCount;
  final int eventCount;
  final String founderId;
  final List<String>? leaders; // Only for clubs
  final List<String>? adminTeam; // Only for clubs
  final DateTime createdAt;
  final DateTime? lastEventAt;
  final Map<String, Map<String, dynamic>>
      memberAIAgents; // AI agent data per member (privacy-filtered)

  ClubCommunityData({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.isClub,
    required this.memberCount,
    required this.eventCount,
    required this.founderId,
    this.leaders,
    this.adminTeam,
    required this.createdAt,
    this.lastEventAt,
    required this.memberAIAgents,
  });
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// God-mode view of a federated learning round with enriched participant data
class GodModeFederatedRoundInfo {
  /// The base federated learning round
  final federated.FederatedLearningRound round;

  /// List of participants with user and AI personality information
  final List<RoundParticipant> participants;

  /// Performance metrics for this round
  final RoundPerformanceMetrics performanceMetrics;

  /// Detailed explanation of why this learning round exists
  final String learningRationale;

  GodModeFederatedRoundInfo({
    required this.round,
    required this.participants,
    required this.performanceMetrics,
    required this.learningRationale,
  });

  /// Get formatted duration
  String get durationString {
    final duration = DateTime.now().difference(round.createdAt);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  /// Check if round is active
  bool get isActive =>
      round.status == federated.RoundStatus.training ||
      round.status == federated.RoundStatus.aggregating;
}

/// Participant information for a federated learning round
class RoundParticipant {
  /// The node ID participating in the round
  final String nodeId;

  /// The user ID associated with this node
  final String userId;

  /// The AI personality name/archetype for this participant
  final String aiPersonalityName;

  /// Number of contributions (model updates) made
  final int contributionCount;

  /// When this participant joined the round
  final DateTime joinedAt;

  /// Whether the participant is currently active
  final bool isActive;

  RoundParticipant({
    required this.nodeId,
    required this.userId,
    required this.aiPersonalityName,
    required this.contributionCount,
    required this.joinedAt,
    required this.isActive,
  });

  /// Get formatted join time
  String get joinedTimeAgo {
    final duration = DateTime.now().difference(joinedAt);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    return '${duration.inMinutes}m ago';
  }
}

/// Performance metrics for a federated learning round
class RoundPerformanceMetrics {
  /// Percentage of invited participants who are actively participating
  final double participationRate;

  /// Average model accuracy across all participants
  final double averageAccuracy;

  /// Privacy compliance score (0.0-1.0)
  final double privacyComplianceScore;

  /// Progress towards convergence (0.0-1.0)
  final double convergenceProgress;

  RoundPerformanceMetrics({
    required this.participationRate,
    required this.averageAccuracy,
    required this.privacyComplianceScore,
    required this.convergenceProgress,
  });

  /// Get overall health score
  double get overallHealth =>
      (participationRate +
          averageAccuracy +
          privacyComplianceScore +
          convergenceProgress) /
      4.0;
}
