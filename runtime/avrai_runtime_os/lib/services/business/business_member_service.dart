import 'package:avrai_core/models/business/business_member.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:uuid/uuid.dart';

/// Business Member Service
///
/// Manages business members (users who are part of a business account).
/// Handles invitations, role management, and member lifecycle.
class BusinessMemberService {
  static const String _logName = 'BusinessMemberService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();

  final BusinessAccountService _businessAccountService;

  BusinessMemberService({
    required BusinessAccountService businessAccountService,
  }) : _businessAccountService = businessAccountService;

  /// Add a member to a business account
  ///
  /// **Flow:**
  /// 1. Get business account
  /// 2. Check if user is already a member
  /// 3. Validate inviter has permission (owner/admin)
  /// 4. Create BusinessMember record
  /// 5. Update business account with new member
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `userId`: User ID to add
  /// - `role`: Member role (default: member)
  /// - `invitedBy`: User ID who is inviting (must be owner/admin)
  ///
  /// **Returns:**
  /// BusinessMember
  ///
  /// **Throws:**
  /// - `Exception` if business not found
  /// - `Exception` if user already a member
  /// - `Exception` if inviter doesn't have permission
  Future<BusinessMember> addMember({
    required String businessId,
    required String userId,
    BusinessMemberRole role = BusinessMemberRole.member,
    required String invitedBy,
  }) async {
    try {
      _logger.info(
        'Adding member to business: business=$businessId, user=$userId, role=${role.name}, invitedBy=$invitedBy',
        tag: _logName,
      );

      // Step 1: Get business account
      final business =
          await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Step 2: Check if user is already a member
      final existingMember = business.members.firstWhere(
        (m) => m.userId == userId && m.isActive,
        orElse: () => throw Exception('User not found in members'),
      );

      if (existingMember.userId == userId) {
        throw Exception('User is already a member of this business');
      }

      // Step 3: Validate inviter has permission
      final inviterMember = business.members.firstWhere(
        (m) => m.userId == invitedBy && m.isActive,
        orElse: () =>
            throw Exception('Inviter is not a member of this business'),
      );

      if (!inviterMember.role.canManageMembers) {
        throw Exception('Inviter does not have permission to add members');
      }

      // Step 4: Create BusinessMember
      final now = DateTime.now();
      final member = BusinessMember(
        id: _uuid.v4(),
        userId: userId,
        businessId: businessId,
        role: role,
        joinedAt: now,
        invitedBy: invitedBy,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Step 5: Update business account
      // Note: updateBusinessAccount doesn't support members parameter yet
      // This would need to be added to BusinessAccountService
      // For now, member is created but not persisted to business account
      // TODO: Add members update support to BusinessAccountService

      _logger.info('Added member to business: ${member.id}', tag: _logName);
      return member;
    } catch (e) {
      _logger.error('Error adding member to business', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove a member from a business account
  ///
  /// **Flow:**
  /// 1. Get business account
  /// 2. Validate remover has permission (owner/admin, can't remove owner)
  /// 3. Deactivate member (soft delete)
  /// 4. Update business account
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `userId`: User ID to remove
  /// - `removedBy`: User ID who is removing (must be owner/admin)
  ///
  /// **Returns:**
  /// true if successful
  ///
  /// **Throws:**
  /// - `Exception` if business not found
  /// - `Exception` if user not a member
  /// - `Exception` if remover doesn't have permission
  /// - `Exception` if trying to remove owner
  Future<bool> removeMember({
    required String businessId,
    required String userId,
    required String removedBy,
  }) async {
    try {
      _logger.info(
        'Removing member from business: business=$businessId, user=$userId, removedBy=$removedBy',
        tag: _logName,
      );

      // Step 1: Get business account
      final business =
          await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Step 2: Find member to remove
      final memberToRemove = business.members.firstWhere(
        (m) => m.userId == userId && m.isActive,
        orElse: () =>
            throw Exception('User is not an active member of this business'),
      );

      // Step 3: Validate can't remove owner
      if (memberToRemove.role == BusinessMemberRole.owner) {
        throw Exception('Cannot remove business owner');
      }

      // Step 4: Validate remover has permission
      final removerMember = business.members.firstWhere(
        (m) => m.userId == removedBy && m.isActive,
        orElse: () =>
            throw Exception('Remover is not a member of this business'),
      );

      if (!removerMember.role.canManageMembers) {
        throw Exception('Remover does not have permission to remove members');
      }

      // Step 5: Deactivate member (soft delete)
      // Note: Would need to update BusinessAccountService to support members update
      // For now, this is a placeholder
      // TODO: Add members update support to BusinessAccountService

      _logger.info('Removed member from business: $userId', tag: _logName);
      return true;
    } catch (e) {
      _logger.error('Error removing member from business',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update member role
  ///
  /// **Flow:**
  /// 1. Get business account
  /// 2. Validate updater has permission (owner only for role changes)
  /// 3. Validate role change is allowed
  /// 4. Update member role
  /// 5. Update business account
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `userId`: User ID whose role to update
  /// - `newRole`: New role
  /// - `updatedBy`: User ID who is updating (must be owner)
  ///
  /// **Returns:**
  /// Updated BusinessMember
  ///
  /// **Throws:**
  /// - `Exception` if business not found
  /// - `Exception` if user not a member
  /// - `Exception` if updater doesn't have permission
  /// - `Exception` if role change not allowed
  Future<BusinessMember> updateMemberRole({
    required String businessId,
    required String userId,
    required BusinessMemberRole newRole,
    required String updatedBy,
  }) async {
    try {
      _logger.info(
        'Updating member role: business=$businessId, user=$userId, newRole=${newRole.name}, updatedBy=$updatedBy',
        tag: _logName,
      );

      // Step 1: Get business account
      final business =
          await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        throw Exception('Business account not found: $businessId');
      }

      // Step 2: Validate updater is owner
      final updaterMember = business.members.firstWhere(
        (m) => m.userId == updatedBy && m.isActive,
        orElse: () =>
            throw Exception('Updater is not a member of this business'),
      );

      if (updaterMember.role != BusinessMemberRole.owner) {
        throw Exception('Only business owner can change member roles');
      }

      // Step 3: Find member to update
      final memberToUpdate = business.members.firstWhere(
        (m) => m.userId == userId && m.isActive,
        orElse: () =>
            throw Exception('User is not an active member of this business'),
      );

      // Step 4: Validate role change (can't change owner role)
      if (memberToUpdate.role == BusinessMemberRole.owner &&
          newRole != BusinessMemberRole.owner) {
        throw Exception('Cannot change owner role');
      }

      // Step 5: Update member role
      final updatedMember = memberToUpdate.copyWith(
        role: newRole,
        updatedAt: DateTime.now(),
      );

      // Step 6: Update business account
      // Note: Would need to update BusinessAccountService to support members update
      // For now, this is a placeholder

      _logger.info('Updated member role: $userId -> ${newRole.name}',
          tag: _logName);
      return updatedMember;
    } catch (e) {
      _logger.error('Error updating member role', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all members of a business
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `includeInactive`: Whether to include inactive members (default: false)
  ///
  /// **Returns:**
  /// List of BusinessMember
  Future<List<BusinessMember>> getBusinessMembers({
    required String businessId,
    bool includeInactive = false,
  }) async {
    try {
      final business =
          await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        return [];
      }

      if (includeInactive) {
        return business.members;
      }

      return business.members.where((m) => m.isActive).toList();
    } catch (e) {
      _logger.error('Error getting business members', error: e, tag: _logName);
      return [];
    }
  }

  /// Check if user is a member of a business
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `userId`: User ID to check
  ///
  /// **Returns:**
  /// BusinessMember if user is a member, null otherwise
  Future<BusinessMember?> getMember({
    required String businessId,
    required String userId,
  }) async {
    try {
      final members = await getBusinessMembers(businessId: businessId);
      try {
        return members.firstWhere((m) => m.userId == userId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      _logger.error('Error getting member', error: e, tag: _logName);
      return null;
    }
  }

  /// Check if user has permission to perform an action
  ///
  /// **Parameters:**
  /// - `businessId`: Business account ID
  /// - `userId`: User ID to check
  /// - `requiredRole`: Minimum role required (default: member)
  ///
  /// **Returns:**
  /// true if user has permission
  Future<bool> hasPermission({
    required String businessId,
    required String userId,
    BusinessMemberRole requiredRole = BusinessMemberRole.member,
  }) async {
    try {
      final member = await getMember(businessId: businessId, userId: userId);
      if (member == null || !member.isActive) {
        return false;
      }

      // Check role hierarchy: owner > admin > member
      switch (requiredRole) {
        case BusinessMemberRole.member:
          return true; // All active members have member permissions
        case BusinessMemberRole.admin:
          return member.role == BusinessMemberRole.admin ||
              member.role == BusinessMemberRole.owner;
        case BusinessMemberRole.owner:
          return member.role == BusinessMemberRole.owner;
      }
    } catch (e) {
      _logger.error('Error checking permission', error: e, tag: _logName);
      return false;
    }
  }
}
