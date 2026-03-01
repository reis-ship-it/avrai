import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_vibe_analyzer.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_insight_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Public Profile Analysis Service
///
/// Analyzes public social media profiles from user-provided handles.
/// Only analyzes with explicit user consent.
///
/// **Privacy:** All analysis is opt-in and user-controlled.
/// **Consent:** Users must explicitly consent before any analysis.
/// **Platforms:** Instagram, TikTok, Twitter (public profiles only)
class PublicProfileAnalysisService {
  static const String _logName = 'PublicProfileAnalysisService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaVibeAnalyzer _vibeAnalyzer;
  final SocialMediaInsightService _insightService;
  final AtomicClockService _atomicClock;

  // Storage keys
  static const String _handlesKeyPrefix = 'public_handles_';
  static const String _consentKeyPrefix = 'handle_consent_';
  static const String _analysisKeyPrefix = 'handle_analysis_';

  PublicProfileAnalysisService({
    required StorageService storageService,
    required SocialMediaVibeAnalyzer vibeAnalyzer,
    required SocialMediaInsightService insightService,
    required AtomicClockService atomicClock,
  })  : _storageService = storageService,
        _vibeAnalyzer = vibeAnalyzer,
        _insightService = insightService,
        _atomicClock = atomicClock;

  /// Store user-provided handles (with consent)
  ///
  /// **Flow:**
  /// 1. User provides handles
  /// 2. User consents to analysis
  /// 3. Store handles and consent
  /// 4. Analyze public profiles
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `handles`: Map of platform → handle (e.g., {'instagram': 'username', 'tiktok': '@username'})
  /// - `consentGiven`: User's explicit consent
  ///
  /// **Returns:**
  /// True if handles stored successfully
  Future<bool> storeHandlesWithConsent({
    required String agentId,
    required Map<String, String> handles,
    required bool consentGiven,
  }) async {
    try {
      _logger.info(
          '💾 Storing public handles for agent: ${agentId.substring(0, 10)}...',
          tag: _logName);

      if (!consentGiven) {
        throw Exception('Consent required to store and analyze handles');
      }

      // Store handles
      final handlesKey = '$_handlesKeyPrefix$agentId';
      await _storageService.setObject(handlesKey, {
        'handles': handles,
        'storedAt': DateTime.now().toIso8601String(),
      });

      // Store consent
      final consentKey = '$_consentKeyPrefix$agentId';
      await _storageService.setObject(consentKey, {
        'consentGiven': consentGiven,
        'consentedAt': DateTime.now().toIso8601String(),
        'platforms': handles.keys.toList(),
      });

      // Analyze public profiles (if consent given)
      if (consentGiven) {
        await _analyzePublicProfiles(agentId, handles);
      }

      _logger.info('✅ Stored ${handles.length} handle(s) with consent',
          tag: _logName);
      return true;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to store handles',
          error: e, stackTrace: stackTrace, tag: _logName);
      return false;
    }
  }

  /// Get stored handles for an agent
  Future<Map<String, String>> getStoredHandles(String agentId) async {
    try {
      final key = '$_handlesKeyPrefix$agentId';
      final data = _storageService.getObject<Map<String, dynamic>>(key);
      if (data == null) return {};
      return Map<String, String>.from(data['handles'] as Map? ?? {});
    } catch (e) {
      _logger.warn('Failed to get stored handles: $e', tag: _logName);
      return {};
    }
  }

  /// Check if user has given consent
  Future<bool> hasConsent(String agentId) async {
    try {
      final key = '$_consentKeyPrefix$agentId';
      final data = _storageService.getObject<Map<String, dynamic>>(key);
      if (data == null) return false;
      return data['consentGiven'] as bool? ?? false;
    } catch (e) {
      _logger.warn('Failed to check consent: $e', tag: _logName);
      return false;
    }
  }

  /// Revoke consent and delete handles
  Future<bool> revokeConsent(String agentId) async {
    try {
      _logger.info(
          '🔒 Revoking consent for agent: ${agentId.substring(0, 10)}...',
          tag: _logName);

      // Remove handles
      final handlesKey = '$_handlesKeyPrefix$agentId';
      await _storageService.remove(handlesKey);

      // Remove consent
      final consentKey = '$_consentKeyPrefix$agentId';
      await _storageService.remove(consentKey);

      // Remove analysis results
      final analysisKey = '$_analysisKeyPrefix$agentId';
      await _storageService.remove(analysisKey);

      _logger.info('✅ Consent revoked and handles deleted', tag: _logName);
      return true;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to revoke consent',
          error: e, stackTrace: stackTrace, tag: _logName);
      return false;
    }
  }

  /// Analyze public profiles from handles
  Future<void> _analyzePublicProfiles(
    String agentId,
    Map<String, String> handles,
  ) async {
    try {
      _logger.info('🔍 Analyzing public profiles from handles', tag: _logName);

      final allInsights = <String, double>{};
      final allInterests = <String>{};
      final allCommunities = <String>{};

      // Analyze each platform
      for (final entry in handles.entries) {
        final platform = entry.key;
        final handle = entry.value;

        try {
          final profileData = await _fetchPublicProfile(platform, handle);
          if (profileData.isEmpty) continue;

          // Analyze for vibe insights
          final insights = await _vibeAnalyzer.analyzeProfileForVibe(
            profileData: profileData,
            follows:
                profileData['follows'] as List<Map<String, dynamic>>? ?? [],
            connections: [],
            platform: platform,
          );

          // Aggregate insights
          insights.forEach((dimension, value) {
            allInsights[dimension] = (allInsights[dimension] ?? 0.0) + value;
          });

          // Extract interests and communities
          final interests = profileData['interests'] as List<dynamic>? ?? [];
          final communities =
              profileData['communities'] as List<dynamic>? ?? [];

          allInterests.addAll(interests.cast<String>());
          allCommunities.addAll(communities.cast<String>());
        } catch (e) {
          _logger.warn('Failed to analyze $platform handle $handle: $e',
              tag: _logName);
          // Continue with other platforms
        }
      }

      // Normalize insights (average across platforms)
      if (allInsights.isNotEmpty) {
        final platformCount = handles.length;
        allInsights.forEach((key, value) {
          allInsights[key] = (value / platformCount).clamp(0.0, 1.0);
        });
      }

      // Store analysis results
      final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
      final analysisKey = '$_analysisKeyPrefix$agentId';
      await _storageService.setObject(analysisKey, {
        'insights': allInsights,
        'interests': allInterests.toList(),
        'communities': allCommunities.toList(),
        'analyzedAt': atomicTimestamp.serverTime.toIso8601String(),
        'platforms': handles.keys.toList(),
      });

      // Update personality insights (if consent still valid)
      final hasConsent = await this.hasConsent(agentId);
      if (hasConsent && allInsights.isNotEmpty) {
        // Get existing insights
        final existingInsights = await _insightService.getInsights(agentId);
        if (existingInsights != null) {
          // Merge handle-based insights with existing insights
          final mergedInsights = <String, double>{};
          existingInsights.dimensionUpdates.forEach((dimension, value) {
            final handleValue = allInsights[dimension] ?? 0.0;
            // Blend: 60% existing, 40% handle-based
            mergedInsights[dimension] =
                (value * 0.6 + handleValue * 0.4).clamp(0.0, 1.0);
          });

          // Update insights
          // Note: This would require a method to update insights directly
          // For now, we'll store the handle-based insights separately
        }
      }

      _logger.info('✅ Analyzed ${handles.length} public profile(s)',
          tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to analyze public profiles',
          error: e, stackTrace: stackTrace, tag: _logName);
    }
  }

  /// Fetch public profile from platform (no OAuth required)
  Future<Map<String, dynamic>> _fetchPublicProfile(
      String platform, String handle) async {
    try {
      // Remove @ symbol if present
      final cleanHandle = handle.startsWith('@') ? handle.substring(1) : handle;

      switch (platform.toLowerCase()) {
        case 'instagram':
          return await _fetchInstagramPublicProfile(cleanHandle);
        case 'tiktok':
          return await _fetchTikTokPublicProfile(cleanHandle);
        case 'twitter':
          return await _fetchTwitterPublicProfile(cleanHandle);
        default:
          _logger.warn('Public profile fetching not supported for $platform',
              tag: _logName);
          return {};
      }
    } catch (e) {
      _logger.error('Error fetching public profile for $platform/$handle: $e',
          tag: _logName);
      return {};
    }
  }

  /// Fetch Instagram public profile (no OAuth)
  Future<Map<String, dynamic>> _fetchInstagramPublicProfile(
      String username) async {
    try {
      // Note: Instagram's public API is limited
      // This would typically require web scraping or a third-party service
      // For now, return placeholder structure
      _logger.warn(
          'Instagram public profile fetching requires web scraping or third-party service',
          tag: _logName);
      return {
        'profile': {
          'username': username,
        },
        'follows': [],
        'posts': [],
        'interests': [],
        'communities': [],
      };
    } catch (e) {
      _logger.error('Error fetching Instagram public profile: $e',
          tag: _logName);
      return {};
    }
  }

  /// Fetch TikTok public profile (no OAuth)
  Future<Map<String, dynamic>> _fetchTikTokPublicProfile(
      String username) async {
    try {
      // Note: TikTok's public API is limited
      // This would typically require web scraping or a third-party service
      _logger.warn(
          'TikTok public profile fetching requires web scraping or third-party service',
          tag: _logName);
      return {
        'profile': {
          'username': username,
        },
        'follows': [],
        'videos': [],
        'interests': [],
        'communities': [],
      };
    } catch (e) {
      _logger.error('Error fetching TikTok public profile: $e', tag: _logName);
      return {};
    }
  }

  /// Fetch Twitter public profile (no OAuth)
  Future<Map<String, dynamic>> _fetchTwitterPublicProfile(
      String username) async {
    try {
      // Note: Twitter's public API requires authentication even for public profiles
      // This would typically require a Twitter API key or web scraping
      _logger.warn(
          'Twitter public profile fetching requires API key or web scraping',
          tag: _logName);
      return {
        'profile': {
          'username': username,
        },
        'follows': [],
        'tweets': [],
        'interests': [],
        'communities': [],
      };
    } catch (e) {
      _logger.error('Error fetching Twitter public profile: $e', tag: _logName);
      return {};
    }
  }

  /// Get analysis results for an agent
  Future<Map<String, dynamic>?> getAnalysisResults(String agentId) async {
    try {
      final key = '$_analysisKeyPrefix$agentId';
      return _storageService.getObject<Map<String, dynamic>>(key);
    } catch (e) {
      _logger.warn('Failed to get analysis results: $e', tag: _logName);
      return null;
    }
  }
}
