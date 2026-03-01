import 'dart:developer' as developer;
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai_core/models/business/business_patron_preferences.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

/// Business Account Service
/// Manages business account creation and management
class BusinessAccountService {
  static const String _logName = 'BusinessAccountService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Create a new business account
  Future<BusinessAccount> createBusinessAccount({
    required UnifiedUser creator,
    required String name,
    required String email,
    required String businessType,
    String? description,
    String? website,
    String? location,
    String? phone,
    String? logoUrl,
    List<String>? categories,
    List<String>? requiredExpertise,
    List<String>? preferredCommunities,
    BusinessExpertPreferences? expertPreferences,
    BusinessPatronPreferences? patronPreferences,
    String? preferredLocation,
    int? minExpertLevel,
  }) async {
    try {
      _logger.info('Creating business account: $name', tag: _logName);

      final now = DateTime.now();
      final businessAccount = BusinessAccount(
        id: _generateBusinessId(name),
        name: name,
        email: email,
        description: description,
        website: website,
        location: location,
        phone: phone,
        logoUrl: logoUrl,
        businessType: businessType,
        categories: categories ?? [],
        requiredExpertise: requiredExpertise ?? [],
        preferredCommunities: preferredCommunities ?? [],
        expertPreferences: expertPreferences,
        patronPreferences: patronPreferences,
        preferredLocation: preferredLocation,
        minExpertLevel: minExpertLevel,
        createdAt: now,
        updatedAt: now,
        createdBy: creator.id,
      );

      // In production, save to database
      await _saveBusinessAccount(businessAccount);

      _logger.info('Created business account: ${businessAccount.id}',
          tag: _logName);
      return businessAccount;
    } catch (e) {
      _logger.error('Error creating business account', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update business account
  Future<BusinessAccount> updateBusinessAccount(
    BusinessAccount account, {
    String? name,
    String? description,
    String? website,
    String? location,
    String? phone,
    String? logoUrl,
    List<String>? categories,
    List<String>? requiredExpertise,
    List<String>? preferredCommunities,
    BusinessExpertPreferences? expertPreferences,
    BusinessPatronPreferences? patronPreferences,
    String? preferredLocation,
    int? minExpertLevel,
    bool? isVerified,
    bool? isActive,
    Map<String, double>? attractionDimensions,
  }) async {
    try {
      _logger.info('Updating business account: ${account.id}', tag: _logName);

      final updated = account.copyWith(
        name: name,
        description: description,
        website: website,
        location: location,
        phone: phone,
        logoUrl: logoUrl,
        categories: categories,
        requiredExpertise: requiredExpertise,
        preferredCommunities: preferredCommunities,
        expertPreferences: expertPreferences,
        patronPreferences: patronPreferences,
        preferredLocation: preferredLocation,
        minExpertLevel: minExpertLevel,
        isVerified: isVerified,
        isActive: isActive,
        attractionDimensions: attractionDimensions,
        updatedAt: DateTime.now(),
      );

      await _saveBusinessAccount(updated);
      _logger.info('Updated business account', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating business account', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get business account by ID
  Future<BusinessAccount?> getBusinessAccount(String id) async {
    try {
      // In production, query database
      final accounts = await _getAllBusinessAccounts();
      try {
        return accounts.firstWhere((a) => a.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      _logger.error('Error getting business account', error: e, tag: _logName);
      return null;
    }
  }

  /// Get business accounts created by a user
  Future<List<BusinessAccount>> getBusinessAccountsByUser(String userId) async {
    try {
      final accounts = await _getAllBusinessAccounts();
      return accounts.where((a) => a.createdBy == userId).toList();
    } catch (e) {
      _logger.error('Error getting business accounts by user',
          error: e, tag: _logName);
      return [];
    }
  }

  /// Add expert connection
  Future<BusinessAccount> addExpertConnection(
    BusinessAccount account,
    String expertId,
  ) async {
    try {
      if (account.connectedExpertIds.contains(expertId)) {
        return account; // Already connected
      }

      final updated = account.copyWith(
        connectedExpertIds: [...account.connectedExpertIds, expertId],
        pendingConnectionIds:
            account.pendingConnectionIds.where((id) => id != expertId).toList(),
        updatedAt: DateTime.now(),
      );

      await _saveBusinessAccount(updated);
      return updated;
    } catch (e) {
      _logger.error('Error adding expert connection', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Request expert connection (adds to pending)
  Future<BusinessAccount> requestExpertConnection(
    BusinessAccount account,
    String expertId,
  ) async {
    try {
      if (account.pendingConnectionIds.contains(expertId) ||
          account.connectedExpertIds.contains(expertId)) {
        return account; // Already requested or connected
      }

      final updated = account.copyWith(
        pendingConnectionIds: [...account.pendingConnectionIds, expertId],
        updatedAt: DateTime.now(),
      );

      await _saveBusinessAccount(updated);
      return updated;
    } catch (e) {
      _logger.error('Error requesting expert connection',
          error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods
  // In-memory storage for tests (in production, use database)
  final Map<String, BusinessAccount> _businessAccounts = {};

  String _generateBusinessId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameSlug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'business_${nameSlug}_$timestamp';
  }

  Future<void> _saveBusinessAccount(BusinessAccount account) async {
    // In production, save to database
    developer.log('Saving business account: ${account.id}', name: _logName);
    // Store in memory for tests
    _businessAccounts[account.id] = account;
  }

  Future<List<BusinessAccount>> _getAllBusinessAccounts() async {
    // In production, query database
    return _businessAccounts.values.toList();
  }
}
