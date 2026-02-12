import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingCompletionService {
  static const String _logName = 'OnboardingCompletionService';
  static const String _completionKeyPrefix = 'onboarding_completed_';
  static const AppLogger _logger =
      AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  static final GetStorage _box = GetStorage('onboarding_completion');

  // In-memory cache to prevent race conditions (especially on web)
  static final Map<String, bool> _completionCache = {};

  /// Get the completion key for a specific user
  static String _getCompletionKey(String userId) =>
      '$_completionKeyPrefix$userId';

  /// Check if onboarding has been completed for a specific user
  static Future<bool> isOnboardingCompleted([String? userId]) async {
    try {
      // If no userId provided, return false (new user needs onboarding)
      if (userId == null || userId.isEmpty) {
        _logger.debug(
            '🔍 [CHECK] No userId provided, assuming onboarding not completed',
            tag: _logName);
        return false;
      }

      // Check cache first (for recently completed onboarding)
      if (_completionCache.containsKey(userId)) {
        final cached = _completionCache[userId]!;
        _logger.debug(
            '🔍 [CHECK_CACHE] Onboarding completion status from cache for user $userId: $cached',
            tag: _logName);
        return cached;
      }

      _logger.debug(
          '🔍 [CHECK_DB] Cache miss, checking storage for user $userId...',
          tag: _logName);
      final completionKey = _getCompletionKey(userId);
      final record = _box.read<Map<String, dynamic>>(completionKey);

      if (record != null) {
        final isCompleted = record['completed'] as bool? ?? false;
        final completedAt = record['completed_at'] as String?;
        // Update cache
        _completionCache[userId] = isCompleted;
        _logger.info(
            '🔍 [CHECK_DB] Onboarding completion status for user $userId: $isCompleted (completed_at: $completedAt)',
            tag: _logName);
        return isCompleted;
      }

      // Update cache with false
      _completionCache[userId] = false;
      _logger.info(
          '🔍 [CHECK_DB] No onboarding completion record found for user $userId',
          tag: _logName);
      return false;
    } catch (e) {
      _logger.error(
          '❌ [CHECK_ERROR] Error checking onboarding completion for user $userId',
          tag: _logName,
          error: e);
      // Return cached value if available, otherwise false
      final cachedValue = _completionCache[userId] ?? false;
      _logger.debug('🔍 [CHECK_ERROR] Returning cached value: $cachedValue',
          tag: _logName);
      return cachedValue;
    }
  }

  /// Mark onboarding as completed for a specific user
  /// Returns true if successfully marked and verified, false otherwise
  static Future<bool> markOnboardingCompleted(String userId) async {
    final startTime = DateTime.now();
    try {
      if (userId.isEmpty) {
        _logger.warn('Cannot mark onboarding completed: userId is empty',
            tag: _logName);
        return false;
      }

      _logger.info(
          '🚀 [MARK_START] Starting markOnboardingCompleted for user $userId',
          tag: _logName);

      final completionKey = _getCompletionKey(userId);

      // Step 1: Update cache immediately (before storage write)
      _completionCache[userId] = true;
      _logger.debug('✅ [MARK_STEP1] Cache set to true for user $userId',
          tag: _logName);

      // Step 2: Write the completion record
      _logger.debug('📝 [MARK_STEP2] Writing to storage for user $userId...',
          tag: _logName);
      await _box.write(completionKey, {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'user_id': userId,
      });
      _logger.debug('✅ [MARK_STEP2] Storage write completed for user $userId',
          tag: _logName);

      // Step 3: Verify write by reading back
      _logger.debug(
          '🔄 [MARK_STEP3] Verifying write for user $userId...',
          tag: _logName);
      bool writeVerified = false;
      final verifyRecord = _box.read<Map<String, dynamic>>(completionKey);
      if (verifyRecord == null) {
        _logger.warn(
            '⚠️ [MARK_STEP3] Write verification failed - record not found for user $userId',
            tag: _logName);
        writeVerified = false;
      } else {
        final isCompleted = verifyRecord['completed'] as bool? ?? false;
        _logger.debug(
            '✅ [MARK_STEP3] Write verified for user $userId: completed=$isCompleted',
            tag: _logName);
        writeVerified = isCompleted;
      }

      if (!writeVerified) {
        _logger.error(
            '❌ [MARK_STEP3] Write verification failed for user $userId',
            tag: _logName);
        // Keep cache as true - write might still be in progress
        _completionCache[userId] = true;
        return false;
      }

      // Step 4: Additional verification with multiple strategies
      _logger.debug(
          '🔄 [MARK_STEP4] Starting multi-strategy verification for user $userId...',
          tag: _logName);

      // Strategy 1: Immediate check (should hit cache)
      bool verified1 = await isOnboardingCompleted(userId);
      _logger.debug(
          '🔍 [MARK_STEP4_STRAT1] Immediate check result: $verified1 (should be true from cache)',
          tag: _logName);

      // Strategy 2: Check after short delay (for web IndexedDB)
      await Future.delayed(const Duration(milliseconds: 100));
      bool verified2 = await isOnboardingCompleted(userId);
      _logger.debug(
          '🔍 [MARK_STEP4_STRAT2] Delayed check (100ms) result: $verified2',
          tag: _logName);

      // Strategy 3: Direct storage read (bypass cache)
      bool verified3 = false;
      try {
        final directRecord = _box.read<Map<String, dynamic>>(completionKey);
        if (directRecord != null) {
          verified3 = directRecord['completed'] as bool? ?? false;
        }
        _logger.debug(
            '🔍 [MARK_STEP4_STRAT3] Direct storage read result: $verified3',
            tag: _logName);
      } catch (e) {
        _logger.warn('⚠️ [MARK_STEP4_STRAT3] Direct storage read failed: $e',
            tag: _logName);
      }

      // Strategy 4: Final check after longer delay (for slow IndexedDB)
      await Future.delayed(const Duration(milliseconds: 200));
      bool verified4 = await isOnboardingCompleted(userId);
      _logger.debug(
          '🔍 [MARK_STEP4_STRAT4] Final delayed check (300ms total) result: $verified4',
          tag: _logName);

      // All strategies should pass
      final allVerified = verified1 && verified2 && verified3 && verified4;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      if (allVerified) {
        _logger.info(
            '✅ [MARK_SUCCESS] Onboarding marked as completed and fully verified for user $userId (took ${elapsed}ms)',
            tag: _logName);
        return true;
      } else {
        _logger.error(
            '❌ [MARK_PARTIAL] Onboarding marked but verification incomplete for user $userId. Results: cache=$verified1, delayed=$verified2, direct=$verified3, final=$verified4 (took ${elapsed}ms)',
            tag: _logName);
        // Keep cache as true even if verification fails (write might still be in progress)
        _completionCache[userId] = true;
        return false;
      }
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.error(
          '❌ [MARK_ERROR] Error marking onboarding completed for user $userId (took ${elapsed}ms)',
          tag: _logName,
          error: e);
      _logger.debug('Stack trace: $stackTrace', tag: _logName);
      // Keep cache as true on error
      _completionCache[userId] = true;
      rethrow; // Re-throw to let caller know it failed
    }
  }

  /// Reset onboarding completion status for a specific user (for testing)
  static Future<void> resetOnboardingCompletion(String userId) async {
    try {
      // Clear cache first
      _completionCache.remove(userId);
      _logger.info('🗑️ [RESET] Cache cleared for user $userId', tag: _logName);

      final completionKey = _getCompletionKey(userId);

      // Delete the record
      await _box.remove(completionKey);
      _logger.info(
          '🗑️ [RESET] Storage record deleted for user $userId',
          tag: _logName);

      // Verify deletion
      final record = _box.read<Map<String, dynamic>>(completionKey);
      if (record == null) {
        _logger.info(
            '✅ [RESET] Onboarding completion status reset for user $userId (verified)',
            tag: _logName);
      } else {
        _logger.warn(
            '⚠️ [RESET] Record still exists after deletion for user $userId',
            tag: _logName);
      }
    } catch (e, stackTrace) {
      _logger.error('❌ [RESET] Error resetting onboarding completion',
          tag: _logName, error: e);
      _logger.debug('Stack trace: $stackTrace', tag: _logName);
    }
  }

  /// Clear the cache for a specific user (useful for testing)
  static void clearCache(String userId) {
    _completionCache.remove(userId);
    _logger.info('🗑️ [CACHE] Cache cleared for user $userId', tag: _logName);
  }

  /// Clear all cache (useful for testing)
  static void clearAllCache() {
    _completionCache.clear();
    _logger.info('🗑️ [CACHE] All cache cleared', tag: _logName);
  }
}
