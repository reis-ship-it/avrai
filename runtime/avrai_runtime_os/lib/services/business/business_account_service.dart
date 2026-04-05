import 'dart:developer' as developer;
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai_core/models/business/business_patron_preferences.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:get_it/get_it.dart';

/// Business Account Service
/// Manages business account creation and management
class BusinessAccountService {
  static const String _logName = 'BusinessAccountService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final BusinessOperatorFollowUpPromptPlannerService?
      _businessFollowUpPlannerService;

  BusinessAccountService({
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    BusinessOperatorFollowUpPromptPlannerService?
        businessFollowUpPlannerService,
  })  : _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _businessFollowUpPlannerService = businessFollowUpPlannerService ??
            (GetIt.instance.isRegistered<
                    BusinessOperatorFollowUpPromptPlannerService>()
                ? GetIt.instance<BusinessOperatorFollowUpPromptPlannerService>()
                : null);

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
      await _stageBusinessOperatorInputBestEffort(
        account: businessAccount,
        action: 'create',
        changedFields: <String>[
          'businessType',
          if (description != null) 'description',
          if (website != null) 'website',
          if (location != null) 'location',
          if (phone != null) 'phone',
          if (logoUrl != null) 'logoUrl',
          if ((categories?.isNotEmpty ?? false)) 'categories',
          if ((requiredExpertise?.isNotEmpty ?? false)) 'requiredExpertise',
          if ((preferredCommunities?.isNotEmpty ?? false))
            'preferredCommunities',
          if (expertPreferences != null) 'expertPreferences',
          if (patronPreferences != null) 'patronPreferences',
          if (preferredLocation != null) 'preferredLocation',
          if (minExpertLevel != null) 'minExpertLevel',
        ],
      );
      await _createBusinessFollowUpPlanBestEffort(
        account: businessAccount,
        action: 'create',
        changedFields: <String>[
          'businessType',
          if (description != null) 'description',
          if (website != null) 'website',
          if (location != null) 'location',
          if (phone != null) 'phone',
          if (logoUrl != null) 'logoUrl',
          if ((categories?.isNotEmpty ?? false)) 'categories',
          if ((requiredExpertise?.isNotEmpty ?? false)) 'requiredExpertise',
          if ((preferredCommunities?.isNotEmpty ?? false))
            'preferredCommunities',
          if (expertPreferences != null) 'expertPreferences',
          if (patronPreferences != null) 'patronPreferences',
          if (preferredLocation != null) 'preferredLocation',
          if (minExpertLevel != null) 'minExpertLevel',
        ],
      );

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
      final changedFields = <String>[
        if (name != null) 'name',
        if (description != null) 'description',
        if (website != null) 'website',
        if (location != null) 'location',
        if (phone != null) 'phone',
        if (logoUrl != null) 'logoUrl',
        if (categories != null) 'categories',
        if (requiredExpertise != null) 'requiredExpertise',
        if (preferredCommunities != null) 'preferredCommunities',
        if (expertPreferences != null) 'expertPreferences',
        if (patronPreferences != null) 'patronPreferences',
        if (preferredLocation != null) 'preferredLocation',
        if (minExpertLevel != null) 'minExpertLevel',
        if (isVerified != null) 'isVerified',
        if (isActive != null) 'isActive',
        if (attractionDimensions != null) 'attractionDimensions',
      ];

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
      await _stageBusinessOperatorInputBestEffort(
        account: updated,
        action: 'update',
        changedFields: changedFields,
      );
      await _createBusinessFollowUpPlanBestEffort(
        account: updated,
        action: 'update',
        changedFields: changedFields,
      );
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

  Future<void> _stageBusinessOperatorInputBestEffort({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final occurredAtUtc = account.updatedAt.toUtc();
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'business_operator_input_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'business_operator_input_intake',
          'businessId': account.id,
          'action': action,
          'businessType': account.businessType,
          'changedFields': changedFields,
          if (account.location?.trim().isNotEmpty ?? false)
            'location': account.location!.trim(),
          'isVerified': account.isVerified,
        },
      );
      await service.stageBusinessOperatorInputIntake(
        account: account,
        action: action,
        occurredAtUtc: occurredAtUtc,
        airGapArtifact: airGapArtifact,
        changedFields: changedFields,
        operatorUserId: account.ownerId,
      );
    } catch (e) {
      _logger.warn(
        'Failed to stage business/operator upward learning for ${account.id}: $e',
        tag: _logName,
      );
    }
  }

  Future<void> _createBusinessFollowUpPlanBestEffort({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) async {
    final service = _businessFollowUpPlannerService;
    if (service == null) {
      return;
    }
    try {
      await service.createPlan(
        account: account,
        action: action,
        occurredAtUtc: account.updatedAt.toUtc(),
        changedFields: changedFields,
      );
    } catch (e) {
      _logger.warn(
        'Failed to create business/operator follow-up plan for ${account.id}: $e',
        tag: _logName,
      );
    }
  }
}
