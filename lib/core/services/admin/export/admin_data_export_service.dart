import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:avrai/core/services/admin/permissions/admin_access_control.dart';
import 'package:avrai/core/services/admin/admin_privacy_filter.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/community/club_service.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/services/admin/admin_communication_service.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/community/club.dart';
import 'package:avrai/core/services/admin/admin_god_mode_service.dart' as admin_models
    show
        BusinessAccountData,
        ClubCommunityData,
        CommunicationsSnapshot;

/// Admin Data Export Service
/// Handles data export and retrieval operations
/// Phase 1.6: Extracted from AdminGodModeService
class AdminDataExportService {
  static const String _logName = 'AdminDataExportService';

  final AdminAccessControl _accessControl;
  final SupabaseService _supabaseService;
  final BusinessAccountService _businessService;
  final ClubService _clubService;
  // ignore: unused_field
  final CommunityService _communityService; // Reserved for future use
  final AdminCommunicationService _communicationService;
  final ConnectionMonitor _connectionMonitor;

  AdminDataExportService({
    required AdminAccessControl accessControl,
    required SupabaseService supabaseService,
    required BusinessAccountService businessService,
    required ClubService clubService,
    CommunityService? communityService,
    required AdminCommunicationService communicationService,
    required ConnectionMonitor connectionMonitor,
  })  : _accessControl = accessControl,
        _supabaseService = supabaseService,
        _businessService = businessService,
        _clubService = clubService,
        _communityService = communityService ?? CommunityService(),
        _communicationService = communicationService,
        _connectionMonitor = connectionMonitor;

  /// Safely get Supabase client, returns null if not available
  dynamic _getSupabaseClient() {
    if (!_supabaseService.isAvailable) {
      developer.log('Supabase not available', name: _logName);
      return null;
    }
    try {
      return _supabaseService.tryGetClient();
    } catch (e) {
      developer.log('Error getting Supabase client: $e', name: _logName);
      return null;
    }
  }

  /// Generate AI signature from user ID (deterministic but anonymized)
  String _generateAISignature(String userId) {
    // Create a deterministic hash from user ID
    // This ensures the same user always gets the same signature
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16); // Use first 16 chars
    return 'ai_$hash';
  }

  /// Get all business accounts
  Future<List<admin_models.BusinessAccountData>> getAllBusinessAccounts() async {
    _accessControl.requireAuthorization();

    try {
      // Try to fetch from Supabase first
      final client = _getSupabaseClient();
      if (client == null) {
        throw Exception('Supabase not available');
      }

      try {
        final response = await client
            .from('business_accounts')
            .select('*')
            .order('created_at', ascending: false);

        final accounts = (response as List).cast<Map<String, dynamic>>();

        return accounts.map((accountData) {
          try {
            final account = BusinessAccount.fromJson(accountData);
            return admin_models.BusinessAccountData(
              account: account,
              isVerified: account.isVerified,
              connectedExperts: account.connectedExpertIds.length,
              lastActivity: account.updatedAt,
            );
          } catch (e) {
            developer.log('Error parsing business account: $e', name: _logName);
            // Return minimal data if parsing fails
            return admin_models.BusinessAccountData(
              account: BusinessAccount(
                id: accountData['id'] as String? ?? '',
                name: accountData['name'] as String? ?? 'Unknown',
                email: accountData['email'] as String? ?? '',
                businessType:
                    accountData['business_type'] as String? ?? 'Unknown',
                createdAt: DateTime.parse(
                    accountData['created_at'] as String? ??
                        DateTime.now().toIso8601String()),
                updatedAt: DateTime.parse(
                    accountData['updated_at'] as String? ??
                        DateTime.now().toIso8601String()),
                createdBy: accountData['created_by'] as String? ?? '',
              ),
              isVerified: accountData['is_verified'] as bool? ?? false,
              connectedExperts: 0,
              lastActivity: DateTime.parse(
                  accountData['updated_at'] as String? ??
                      DateTime.now().toIso8601String()),
            );
          }
        }).toList();
      } catch (e) {
        // Table might not exist, try using BusinessAccountService
        developer.log('Business accounts table not found, trying service: $e',
            name: _logName);

        // Fallback to service if table doesn't exist
        final accounts = await _businessService
            .getBusinessAccountsByUser(''); // Empty string to get all
        return accounts
            .map((account) => admin_models.BusinessAccountData(
                  account: account,
                  isVerified: account.isVerified,
                  connectedExperts: account.connectedExpertIds.length,
                  lastActivity: account.updatedAt,
                ))
            .toList();
      }
    } catch (e) {
      developer.log('Error fetching business accounts: $e', name: _logName);
      return [];
    }
  }

  /// Get all clubs and communities
  /// Privacy-preserving: Returns club/community data with member AI agent information
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<admin_models.ClubCommunityData>>
      getAllClubsAndCommunities() async {
    _accessControl.requireAuthorization();

    try {
      developer.log('Fetching all clubs and communities', name: _logName);

      // Get all clubs - try common categories
      final allClubsSet = <String, Club>{};
      final categories = [
        'nightlife',
        'food',
        'music',
        'sports',
        'art',
        'tech',
        'outdoor',
        'community'
      ];
      for (final category in categories) {
        final clubs =
            await _clubService.getClubsByCategory(category, maxResults: 100);
        for (final club in clubs) {
          allClubsSet[club.id] = club;
        }
      }
      final clubs = allClubsSet.values.toList();

      final allData = <admin_models.ClubCommunityData>[];

      for (final club in clubs) {
        // Get member AI agents (privacy-filtered)
        final memberAIAgents = await _getMemberAIAgentsForClub(club);

        allData.add(admin_models.ClubCommunityData(
          id: club.id,
          name: club.name,
          description: club.description,
          category: club.category,
          isClub: true,
          memberCount: club.memberCount,
          eventCount: club.eventCount,
          founderId: club.founderId,
          leaders: club.leaders,
          adminTeam: club.adminTeam,
          createdAt: club.createdAt,
          lastEventAt: club.lastEventAt,
          memberAIAgents: memberAIAgents,
        ));
      }

      // TODO: Add communities when CommunityService has getAllCommunities method

      developer.log('Retrieved ${allData.length} clubs/communities',
          name: _logName);
      return allData;
    } catch (e) {
      developer.log('Error fetching clubs/communities: $e', name: _logName);
      return [];
    }
  }

  /// Get club/community by ID with member AI agents
  /// Privacy-preserving: Returns AI agent data only, no personal info
  Future<admin_models.ClubCommunityData?> getClubOrCommunityById(
      String id) async {
    _accessControl.requireAuthorization();

    try {
      // Try to get as club first
      final club = await _clubService.getClubById(id);
      if (club != null) {
        final memberAIAgents = await _getMemberAIAgentsForClub(club);
        return admin_models.ClubCommunityData(
          id: club.id,
          name: club.name,
          description: club.description,
          category: club.category,
          isClub: true,
          memberCount: club.memberCount,
          eventCount: club.eventCount,
          founderId: club.founderId,
          leaders: club.leaders,
          adminTeam: club.adminTeam,
          createdAt: club.createdAt,
          lastEventAt: club.lastEventAt,
          memberAIAgents: memberAIAgents,
        );
      }

      // TODO: Try to get as community when CommunityService has getCommunityById

      return null;
    } catch (e) {
      developer.log('Error fetching club/community by ID: $e', name: _logName);
      return null;
    }
  }

  /// Get member AI agents for a club (privacy-filtered)
  /// Returns AI-related data only, no personal information
  Future<Map<String, Map<String, dynamic>>> _getMemberAIAgentsForClub(
      Club club) async {
    final memberAIAgents = <String, Map<String, dynamic>>{};

    for (final memberId in club.memberIds) {
      // Generate AI signature from user ID (deterministic but anonymized)
      final aiSignature = _generateAISignature(memberId);

      // Build AI agent data (AI-related data only, no personal info)
      final aiAgentData = <String, dynamic>{
        'ai_signature': aiSignature,
        'user_id': memberId, // User ID is allowed (not personal data)
        'ai_connections': 0, // TODO: Get from connection monitor
        'ai_status': 'active', // TODO: Get actual status
        'ai_activity': 'active', // TODO: Get actual activity
        // Note: Personal data (name, email, phone, home address) is NOT included
      };

      // Filter through AdminPrivacyFilter to ensure compliance
      final filtered = AdminPrivacyFilter.filterPersonalData(aiAgentData);
      memberAIAgents[memberId] = filtered;
    }

    return memberAIAgents;
  }

  /// Get real-time communications stream
  Stream<admin_models.CommunicationsSnapshot> watchCommunications({
    String? userId,
    String? connectionId,
  }) {
    _accessControl.requireAuthorization();

    final controller =
        StreamController<admin_models.CommunicationsSnapshot>.broadcast();

    // Start periodic updates
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final snapshot =
            await _fetchCommunicationsSnapshot(userId, connectionId);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in communications stream: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Fetch communications snapshot
  Future<admin_models.CommunicationsSnapshot> _fetchCommunicationsSnapshot(
    String? userId,
    String? connectionId,
  ) async {
    try {
      // Use AdminCommunicationService to fetch communications
      int totalMessages = 0;
      List<dynamic> recentMessages = [];

      if (connectionId != null) {
        // Get specific connection log
        final log = await _communicationService.getConnectionLog(connectionId);
        totalMessages = log.chatEvents.length;
        recentMessages = log.chatEvents
            .take(10)
            .map((event) => {
                  'timestamp': event.timestamp.toIso8601String(),
                  'participants': event.participants,
                  'message_count': event.messages.length,
                  // Note: No personal data included - only metadata
                })
            .toList();
      } else {
        // Get all connection summaries
        final summaries =
            await _communicationService.getAllConnectionSummaries();
        totalMessages = summaries.fold(0, (sum, s) => sum + s.messageCount);

        // Collect recent messages from all connections
        for (final summary in summaries.take(10)) {
          final log =
              await _communicationService.getConnectionLog(summary.connectionId);
          recentMessages.addAll(log.chatEvents.take(5).map((event) => {
                'timestamp': event.timestamp.toIso8601String(),
                'participants': event.participants,
                'message_count': event.messages.length,
                // Note: No personal data included - only metadata
              }));
        }
        // Sort by timestamp
        recentMessages.sort((a, b) {
          final aTime = DateTime.parse((a as Map)['timestamp'] as String);
          final bTime = DateTime.parse((b as Map)['timestamp'] as String);
          return bTime.compareTo(aTime);
        });
        recentMessages = recentMessages.take(10).toList();
      }

      return admin_models.CommunicationsSnapshot(
        totalMessages: totalMessages,
        recentMessages: recentMessages,
        activeConnections: connectionId != null
            ? 1
            : (await _connectionMonitor.getActiveConnectionsOverview())
                .totalActiveConnections,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching communications snapshot: $e',
          name: _logName);
      // Return empty snapshot on error
      return admin_models.CommunicationsSnapshot(
        totalMessages: 0,
        recentMessages: [],
        activeConnections: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }
}
