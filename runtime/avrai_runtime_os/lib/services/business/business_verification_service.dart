import 'dart:developer' as developer;
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_verification.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

/// Business Verification Service
/// Handles business verification and proof of legitimacy
class BusinessVerificationService {
  static const String _logName = 'BusinessVerificationService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final BusinessAccountService _businessAccountService;

  BusinessVerificationService({
    BusinessAccountService? businessAccountService,
  }) : _businessAccountService =
            businessAccountService ?? BusinessAccountService();

  /// Submit business for verification
  Future<BusinessVerification> submitVerification({
    required BusinessAccount business,
    required String legalBusinessName,
    String? taxId,
    String? businessAddress,
    String? phoneNumber,
    String? websiteUrl,
    String? businessLicenseUrl,
    String? taxIdDocumentUrl,
    String? proofOfAddressUrl,
    String? websiteVerificationUrl,
    String? socialMediaVerificationUrl,
  }) async {
    try {
      _logger.info('Submitting verification for business: ${business.id}',
          tag: _logName);

      final now = DateTime.now();
      final verification = BusinessVerification(
        id: _generateVerificationId(business.id),
        businessAccountId: business.id,
        status: VerificationStatus.pending,
        method: _determineVerificationMethod(
          businessLicenseUrl,
          taxIdDocumentUrl,
          proofOfAddressUrl,
          websiteUrl,
        ),
        legalBusinessName: legalBusinessName,
        taxId: taxId,
        businessAddress: businessAddress,
        phoneNumber: phoneNumber,
        websiteUrl: websiteUrl,
        businessLicenseUrl: businessLicenseUrl,
        taxIdDocumentUrl: taxIdDocumentUrl,
        proofOfAddressUrl: proofOfAddressUrl,
        websiteVerificationUrl: websiteVerificationUrl,
        socialMediaVerificationUrl: socialMediaVerificationUrl,
        submittedAt: now,
        updatedAt: now,
      );

      // In production, save to database
      await _saveVerification(verification);

      // Update business account with verification
      await _updateBusinessVerification(business, verification);

      _logger.info('Verification submitted: ${verification.id}', tag: _logName);
      return verification;
    } catch (e) {
      _logger.error('Error submitting verification', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Verify business automatically (based on website, social media, etc.)
  Future<BusinessVerification> verifyAutomatically(
      BusinessAccount business) async {
    try {
      _logger.info('Attempting automatic verification for: ${business.id}',
          tag: _logName);

      // Check if business has website
      if (business.website != null && business.website!.isNotEmpty) {
        final isValidWebsite = await _verifyWebsite(business.website!);
        if (isValidWebsite) {
          final verification = BusinessVerification(
            id: _generateVerificationId(business.id),
            businessAccountId: business.id,
            status: VerificationStatus.verified,
            method: VerificationMethod.automatic,
            websiteUrl: business.website,
            websiteVerificationUrl:
                business.website, // In production, would verify ownership
            submittedAt: DateTime.now(),
            updatedAt: DateTime.now(),
            verifiedAt: DateTime.now(),
          );

          await _saveVerification(verification);
          await _updateBusinessVerification(business, verification);

          _logger.info('Automatic verification successful', tag: _logName);
          return verification;
        }
      }

      // If automatic verification fails, require manual verification
      throw Exception(
          'Automatic verification failed. Please submit documents for manual review.');
    } catch (e) {
      _logger.error('Error in automatic verification', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Approve verification (admin action)
  Future<BusinessVerification> approveVerification(
      BusinessVerification verification, String verifiedBy,
      {String? notes}) async {
    try {
      _logger.info('Approving verification: ${verification.id}', tag: _logName);

      final updated = verification.copyWith(
        status: VerificationStatus.verified,
        verifiedBy: verifiedBy,
        verifiedAt: DateTime.now(),
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _saveVerification(updated);

      // Update business account
      final business =
          await _getBusinessAccount(verification.businessAccountId);
      if (business != null) {
        await _updateBusinessVerification(business, updated);
      }

      _logger.info('Verification approved', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error approving verification', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Reject verification (admin action)
  Future<BusinessVerification> rejectVerification(
    BusinessVerification verification,
    String rejectedBy,
    String reason,
  ) async {
    try {
      _logger.info('Rejecting verification: ${verification.id}', tag: _logName);

      final updated = verification.copyWith(
        status: VerificationStatus.rejected,
        verifiedBy: rejectedBy,
        rejectionReason: reason,
        rejectedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveVerification(updated);
      _logger.info('Verification rejected', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error rejecting verification', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get verification status for a business
  Future<BusinessVerification?> getVerification(
      String businessAccountId) async {
    try {
      // In production, query database
      final business = await _getBusinessAccount(businessAccountId);
      return business?.verification;
    } catch (e) {
      _logger.error('Error getting verification', error: e, tag: _logName);
      return null;
    }
  }

  /// Check if business is verified
  Future<bool> isBusinessVerified(String businessAccountId) async {
    try {
      final verification = await getVerification(businessAccountId);
      return verification?.isComplete ?? false;
    } catch (e) {
      _logger.error('Error checking verification status',
          error: e, tag: _logName);
      return false;
    }
  }

  // Private helper methods

  String _generateVerificationId(String businessId) {
    return 'verification_${businessId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  VerificationMethod _determineVerificationMethod(
    String? businessLicense,
    String? taxIdDoc,
    String? proofOfAddress,
    String? website,
  ) {
    if (businessLicense != null || taxIdDoc != null || proofOfAddress != null) {
      return VerificationMethod.document;
    }
    if (website != null && website.isNotEmpty) {
      return VerificationMethod.automatic;
    }
    return VerificationMethod.manual;
  }

  Future<bool> _verifyWebsite(String websiteUrl) async {
    // In production, would:
    // 1. Check if website exists and is accessible
    // 2. Verify domain ownership (DNS, meta tag, etc.)
    // 3. Check for business information on website
    // For now, just check if URL is valid format
    try {
      final uri = Uri.parse(websiteUrl);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveVerification(BusinessVerification verification) async {
    // In production, save to database
    developer.log('Saving verification: ${verification.id}', name: _logName);
  }

  Future<void> _updateBusinessVerification(
    BusinessAccount business,
    BusinessVerification verification,
  ) async {
    try {
      // Update business account with verification
      // Note: BusinessAccountService.updateBusinessAccount may not accept verification/isVerified parameters
      // This is a placeholder - actual implementation depends on BusinessAccount model
      await _businessAccountService.updateBusinessAccount(business);
      developer.log('Updated business verification: ${business.id}',
          name: _logName);
    } catch (e) {
      developer.log('Error updating business verification: $e', name: _logName);
      // Don't throw - verification is saved separately
    }
  }

  Future<BusinessAccount?> _getBusinessAccount(String id) async {
    return await _businessAccountService.getBusinessAccount(id);
  }
}
