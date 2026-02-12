import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/services/social_media/social_media_connection_service.dart';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

/// Social Media Data Collection Controller
/// 
/// Orchestrates the collection of social media data from all connected platforms.
/// Handles multi-platform complexity, merges data consistently, and provides
/// graceful error handling that continues on failure per platform.
/// 
/// **Responsibilities:**
/// - Fetch profile data from all connected platforms
/// - Fetch follows/connections from all platforms
/// - Fetch platform-specific data (Google Places, reviews, photos, etc.)
/// - Merge and structure data consistently
/// - Handle errors per platform (continue on failure)
/// - Return unified data structure
/// 
/// **Dependencies:**
/// - `SocialMediaConnectionService` - Fetch data from platforms
/// 
/// **Usage:**
/// ```dart
/// final controller = SocialMediaDataCollectionController();
/// final result = await controller.collectAllData(
///   userId: userId,
/// );
/// 
/// if (result.isSuccess) {
///   final profileData = result.profileData!;
///   final follows = result.follows!;
///   final primaryPlatform = result.primaryPlatform;
/// } else {
///   // Handle error
///   final error = result.error;
/// }
/// ```
class SocialMediaDataCollectionController implements WorkflowController<String, SocialMediaDataResult> {
  static const String _logName = 'SocialMediaDataCollectionController';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final SocialMediaConnectionService _socialMediaService;
  
  SocialMediaDataCollectionController({
    SocialMediaConnectionService? socialMediaService,
  }) : _socialMediaService = socialMediaService ?? GetIt.instance<SocialMediaConnectionService>();
  
  @override
  Future<SocialMediaDataResult> execute(String input) async {
    // This method is a convenience wrapper - actual implementation in collectAllData
    return await collectAllData(userId: input);
  }
  
  /// Collect all social media data from connected platforms
  /// 
  /// Fetches profile data, follows, and platform-specific data from all
  /// active social media connections. Handles errors gracefully, continuing
  /// even if some platforms fail.
  /// 
  /// **Parameters:**
  /// - `userId`: Authenticated user ID
  /// 
  /// **Returns:**
  /// `SocialMediaDataResult` with collected data or error information
  Future<SocialMediaDataResult> collectAllData({
    required String userId,
  }) async {
    try {
      _logger.info('🎯 Starting social media data collection for user: $userId', tag: _logName);
      
      // STEP 1: Get active connections
      List<SocialMediaConnection> connections;
      try {
        connections = await _socialMediaService.getActiveConnections(userId);
        _logger.debug('📱 Found ${connections.length} active social media connections', tag: _logName);
      } catch (e) {
        _logger.error('❌ Failed to get active connections: $e', error: e, tag: _logName);
        return SocialMediaDataResult.failure(
          error: 'Failed to get active connections: $e',
          errorCode: 'CONNECTION_ERROR',
        );
      }
      
      // If no connections, return empty result (not an error)
      if (connections.isEmpty) {
        _logger.info('ℹ️ No active social media connections found', tag: _logName);
        return SocialMediaDataResult.success(
          profileData: const {},
          follows: const [],
          primaryPlatform: null,
        );
      }
      
      // STEP 2: Collect data from all platforms
      final allProfileData = <String, dynamic>{};
      final allFollows = <Map<String, dynamic>>[];
      String? primaryPlatform;
      final platformErrors = <String, String>{};
      
      for (final connection in connections) {
        try {
          _logger.debug('📥 Processing ${connection.platform} connection...', tag: _logName);
          
          // Fetch profile data
          try {
            final profile = await fetchPlatformProfile(connection);
            
            // Google-specific: Fetch places/reviews/photos and merge into profile
            if (connection.platform == 'google') {
              try {
                final placesData = await _socialMediaService.fetchGooglePlacesData(connection);
                profile['savedPlaces'] = placesData['places'] ?? [];
                profile['reviews'] = placesData['reviews'] ?? [];
                profile['photos'] = placesData['photos'] ?? [];
                _logger.debug('📍 Fetched Google Places data for ${connection.platform}', tag: _logName);
              } catch (e) {
                _logger.warn('⚠️ Could not fetch Google Places data for ${connection.platform}: $e', tag: _logName);
                // Continue without places data
              }
            }
            
            allProfileData[connection.platform] = profile;
            _logger.debug('✅ Fetched profile data from ${connection.platform}', tag: _logName);
          } catch (e) {
            _logger.warn('⚠️ Failed to fetch profile from ${connection.platform}: $e', tag: _logName);
            platformErrors[connection.platform] = 'Profile fetch failed: $e';
            // Continue with other platforms
          }
          
          // Fetch follows/connections
          try {
            final follows = await fetchPlatformFollows(connection);
            allFollows.addAll(follows);
            if (follows.isNotEmpty) {
              _logger.debug('✅ Fetched ${follows.length} follows from ${connection.platform}', tag: _logName);
            }
          } catch (e) {
            _logger.warn('⚠️ Failed to fetch follows from ${connection.platform}: $e', tag: _logName);
            // Continue without follows - not critical
            if (!platformErrors.containsKey(connection.platform)) {
              platformErrors[connection.platform] = 'Follows fetch failed: $e';
            }
          }
          
          // Set primary platform (first successful one)
          if (primaryPlatform == null && allProfileData.containsKey(connection.platform)) {
            primaryPlatform = connection.platform;
          }
        } catch (e) {
          _logger.warn('⚠️ Error processing ${connection.platform} connection: $e', tag: _logName);
          platformErrors[connection.platform] = 'Processing failed: $e';
          // Continue with other connections
        }
      }
      
      // STEP 3: Return result (success even if some platforms failed, as long as we got some data)
      if (allProfileData.isNotEmpty) {
        _logger.info(
          '✅ Social media data collection completed: ${allProfileData.length} platforms, ${allFollows.length} follows',
          tag: _logName,
        );
        return SocialMediaDataResult.success(
          profileData: allProfileData,
          follows: allFollows,
          primaryPlatform: primaryPlatform,
          platformErrors: platformErrors.isNotEmpty ? platformErrors : null,
        );
      } else {
        // All platforms failed
        _logger.warn('⚠️ All platforms failed to return data', tag: _logName);
        return SocialMediaDataResult.failure(
          error: 'All platforms failed to return data. Errors: ${platformErrors.values.join(", ")}',
          errorCode: 'ALL_PLATFORMS_FAILED',
          platformErrors: platformErrors,
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Unexpected error in social media data collection: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return SocialMediaDataResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
  
  /// Fetch profile data from a specific platform
  /// 
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection for the platform
  /// 
  /// **Returns:**
  /// Map with platform-specific profile data
  Future<Map<String, dynamic>> fetchPlatformProfile(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.debug('📥 Fetching profile from ${connection.platform}...', tag: _logName);
      return await _socialMediaService.fetchProfileData(connection);
    } catch (e) {
      _logger.error('❌ Failed to fetch profile from ${connection.platform}: $e', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Fetch follows/connections from a specific platform
  /// 
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection for the platform
  /// 
  /// **Returns:**
  /// List of follow/connection data
  Future<List<Map<String, dynamic>>> fetchPlatformFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.debug('📥 Fetching follows from ${connection.platform}...', tag: _logName);
      return await _socialMediaService.fetchFollows(connection);
    } catch (e) {
      _logger.error('❌ Failed to fetch follows from ${connection.platform}: $e', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Fetch platform-specific data (e.g., Google Places)
  /// 
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection for the platform
  /// 
  /// **Returns:**
  /// Map with platform-specific data (empty if not supported)
  Future<Map<String, dynamic>> fetchPlatformSpecificData(
    SocialMediaConnection connection,
  ) async {
    try {
      // Google-specific: fetch places, reviews, photos
      if (connection.platform == 'google') {
        _logger.debug('📥 Fetching Google Places data...', tag: _logName);
        return await _socialMediaService.fetchGooglePlacesData(connection);
      }
      
      // Other platforms can be added here as needed
      return {};
    } catch (e) {
      _logger.warn('⚠️ Failed to fetch platform-specific data from ${connection.platform}: $e', tag: _logName);
      return {};
    }
  }
  
  @override
  ValidationResult validate(String input) {
    // Simple validation: userId should not be empty
    if (input.trim().isEmpty) {
      return ValidationResult.invalid(
        generalErrors: const ['User ID cannot be empty'],
      );
    }
    return ValidationResult.valid();
  }
  
  @override
  Future<void> rollback(SocialMediaDataResult result) async {
    // Social media data collection is read-only (fetching data)
    // No state changes to rollback
    _logger.debug('Rollback called (no-op for data collection)', tag: _logName);
  }
}

/// Social Media Data Result
/// 
/// Result returned by SocialMediaDataCollectionController after collecting
/// data from all connected platforms.
class SocialMediaDataResult extends ControllerResult {
  /// Profile data by platform (key: platform name, value: platform-specific profile data)
  final Map<String, dynamic>? profileData;
  
  /// Combined list of follows/connections from all platforms
  final List<Map<String, dynamic>>? follows;
  
  /// Primary platform (first successful platform)
  final String? primaryPlatform;
  
  /// Errors per platform (platform name -> error message)
  final Map<String, String>? platformErrors;
  
  const SocialMediaDataResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.profileData,
    this.follows,
    this.primaryPlatform,
    this.platformErrors,
  });
  
  /// Create a successful result
  factory SocialMediaDataResult.success({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    String? primaryPlatform,
    Map<String, String>? platformErrors,
    Map<String, dynamic>? metadata,
  }) {
    return SocialMediaDataResult(
      success: true,
      profileData: profileData,
      follows: follows,
      primaryPlatform: primaryPlatform,
      platformErrors: platformErrors,
      metadata: metadata,
    );
  }
  
  /// Create a failed result
  factory SocialMediaDataResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
    Map<String, String>? platformErrors,
  }) {
    return SocialMediaDataResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
      platformErrors: platformErrors,
    );
  }
  
  /// Get structured data (for backward compatibility with AgentInitializationController)
  Map<String, dynamic>? get structuredData {
    if (profileData == null || profileData!.isEmpty) {
      return null;
    }
    
    return {
      'profile': profileData,
      'follows': follows ?? [],
      'platform': primaryPlatform ?? 'unknown',
    };
  }
  
  @override
  List<Object?> get props => [
    ...super.props,
    profileData,
    follows,
    primaryPlatform,
    platformErrors,
  ];
}

