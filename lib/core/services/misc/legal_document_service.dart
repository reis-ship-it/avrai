import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
import 'package:uuid/uuid.dart';

import 'package:avrai/core/legal/event_waiver.dart';
import 'package:avrai/core/legal/privacy_policy.dart';
import 'package:avrai/core/legal/terms_of_service.dart';
import 'package:avrai/core/models/user/user_agreement.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Legal Document Service
/// 
/// Handles legal document tracking, agreement acceptance, and version management.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables transparent agreement tracking
/// - Supports version management
/// - Creates pathways for legal protection
/// 
/// **Responsibilities:**
/// - Track user agreements (Terms of Service, Privacy Policy)
/// - Generate event waivers
/// - Require agreement acceptance
/// - Manage agreement versions
/// - Check if user has accepted required agreements
/// 
/// **Usage:**
/// ```dart
/// final legalService = LegalDocumentService(eventService);
/// 
/// // Check if user has accepted Terms of Service
/// final hasAccepted = await legalService.hasAcceptedTerms('user-123');
/// 
/// // Accept Terms of Service
/// final agreement = await legalService.acceptTermsOfService(
///   userId: 'user-123',
///   ipAddress: '192.168.1.1',
/// );
/// ```
class LegalDocumentService {
  static const String _logName = 'LegalDocumentService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService? _eventService;
  final SupabaseService _supabaseService;

  /// Local cache of agreements so “accepted” survives app restart and works offline.
  ///
  /// Source of truth for auditability is the v0 ledger (append-only), but we keep
  /// a local mirror for UX.
  final StorageService _storage;

  /// Best-effort ledger writer for audit receipts. If missing or user mismatch,
  /// acceptance still succeeds (but won’t be server-auditable).
  final LedgerRecorderServiceV0? _ledger;

  /// Optional remote reader, used to rehydrate agreements on new devices.
  final LedgerReceiptsServiceV0? _receipts;

  static const String _agreementsKeyPrefix = 'legal_agreements_v1';
  static const String _lastSyncMsKeyPrefix = 'legal_agreements_last_sync_ms_v1';
  static const Duration _syncTtl = Duration(hours: 6);
  
  LegalDocumentService({
    ExpertiseEventService? eventService,
    SupabaseService? supabaseService,
    StorageService? storage,
    LedgerRecorderServiceV0? ledger,
    LedgerReceiptsServiceV0? receipts,
  })  : _eventService = eventService,
        _supabaseService = supabaseService ?? SupabaseService(),
        _storage = storage ?? StorageService.instance,
        _ledger = ledger,
        _receipts = receipts;
  
  /// Check if user has accepted Terms of Service (current version)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted current version, `false` otherwise
  Future<bool> hasAcceptedTerms(String userId) async {
    try {
      var agreements = await getUserAgreements(userId);
      var termsAgreement = _latestActiveAgreement(
        agreements: agreements,
        documentType: 'terms_of_service',
      );
      if (termsAgreement == null && await _syncNowIfHelpful(userId)) {
        agreements = await getUserAgreements(userId);
        termsAgreement = _latestActiveAgreement(
          agreements: agreements,
          documentType: 'terms_of_service',
        );
      }
      if (termsAgreement == null) return false;
      return TermsOfService.isCurrentVersion(termsAgreement.version);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has accepted Privacy Policy (current version)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted current version, `false` otherwise
  Future<bool> hasAcceptedPrivacyPolicy(String userId) async {
    try {
      var agreements = await getUserAgreements(userId);
      var privacyAgreement = _latestActiveAgreement(
        agreements: agreements,
        documentType: 'privacy_policy',
      );
      if (privacyAgreement == null && await _syncNowIfHelpful(userId)) {
        agreements = await getUserAgreements(userId);
        privacyAgreement = _latestActiveAgreement(
          agreements: agreements,
          documentType: 'privacy_policy',
        );
      }
      if (privacyAgreement == null) return false;
      return PrivacyPolicy.isCurrentVersion(privacyAgreement.version);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has accepted event waiver
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted waiver, `false` otherwise
  Future<bool> hasAcceptedEventWaiver(String userId, String eventId) async {
    try {
      var agreements = await getUserAgreements(userId);
      var accepted = agreements.any(
        (a) => a.documentType == 'event_waiver' &&
            a.eventId == eventId &&
            a.isActive,
      );
      if (!accepted && await _syncNowIfHelpful(userId)) {
        agreements = await getUserAgreements(userId);
        accepted = agreements.any(
          (a) => a.documentType == 'event_waiver' &&
              a.eventId == eventId &&
              a.isActive,
        );
      }
      return accepted;
    } catch (e) {
      return false;
    }
  }
  
  /// Accept Terms of Service
  /// 
  /// **Flow:**
  /// 1. Create UserAgreement record
  /// 2. Save agreement
  /// 3. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement
  Future<UserAgreement> acceptTermsOfService({
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting Terms of Service: user=$userId', tag: _logName);
      
      // Revoke old agreements if any
      await _revokeOldAgreements(userId, 'terms_of_service');

      final contentHash = _sha256Hex(TermsOfService.content);
      
      // Create new agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'terms_of_service',
        version: TermsOfService.version,
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        isActive: true,
        updatedAt: DateTime.now(),
        metadata: <String, dynamic>{
          'effective_date': TermsOfService.effectiveDate.toIso8601String(),
          'content_sha256': contentHash,
        },
      );
      
      await _saveAgreement(agreement);

      // Best-effort: append an auditable receipt. Never blocks the UX flow.
      unawaited(_tryAppendLedgerAgreementAccepted(
        userId: userId,
        agreement: agreement,
        domain: LedgerDomainV0.identity,
        eventType: 'terms_of_service_accepted',
        entityType: 'user',
        entityId: userId,
        payload: <String, Object?>{
          'agreement_id': agreement.id,
          'document_type': agreement.documentType,
          'version': agreement.version,
          'effective_date': TermsOfService.effectiveDate.toIso8601String(),
          'content_sha256': contentHash,
          if (ipAddress != null) 'ip_address': ipAddress,
          if (userAgent != null) 'user_agent': userAgent,
        },
      ));
      
      _logger.info('Terms of Service accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting Terms of Service', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Accept Privacy Policy
  /// 
  /// **Flow:**
  /// 1. Create UserAgreement record
  /// 2. Save agreement
  /// 3. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement
  Future<UserAgreement> acceptPrivacyPolicy({
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting Privacy Policy: user=$userId', tag: _logName);
      
      // Revoke old agreements if any
      await _revokeOldAgreements(userId, 'privacy_policy');

      final contentHash = _sha256Hex(PrivacyPolicy.content);
      
      // Create new agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'privacy_policy',
        version: PrivacyPolicy.version,
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        isActive: true,
        updatedAt: DateTime.now(),
        metadata: <String, dynamic>{
          'effective_date': PrivacyPolicy.effectiveDate.toIso8601String(),
          'content_sha256': contentHash,
        },
      );
      
      await _saveAgreement(agreement);

      // Best-effort: append an auditable receipt. Never blocks the UX flow.
      unawaited(_tryAppendLedgerAgreementAccepted(
        userId: userId,
        agreement: agreement,
        domain: LedgerDomainV0.identity,
        eventType: 'privacy_policy_accepted',
        entityType: 'user',
        entityId: userId,
        payload: <String, Object?>{
          'agreement_id': agreement.id,
          'document_type': agreement.documentType,
          'version': agreement.version,
          'effective_date': PrivacyPolicy.effectiveDate.toIso8601String(),
          'content_sha256': contentHash,
          if (ipAddress != null) 'ip_address': ipAddress,
          if (userAgent != null) 'user_agent': userAgent,
        },
      ));
      
      _logger.info('Privacy Policy accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting Privacy Policy', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate and accept event waiver
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Generate waiver text
  /// 3. Create UserAgreement record
  /// 4. Save agreement
  /// 5. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement with waiver
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<UserAgreement> acceptEventWaiver({
    required String userId,
    required String eventId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting event waiver: user=$userId, event=$eventId', tag: _logName);
      
      if (_eventService == null) {
        throw Exception('EventService not available');
      }
      
      // Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Generate waiver (waiver text is generated by EventWaiver class)
      // The actual waiver text would be displayed to user before acceptance

      final waiverType = EventWaiver.getWaiverType(event);
      final waiverText = EventWaiver.requiresFullWaiver(event)
          ? EventWaiver.generateWaiver(event)
          : EventWaiver.generateSimplifiedWaiver(event);
      final waiverHash = _sha256Hex(waiverText);
      
      // Create agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'event_waiver',
        version: '1.0.0', // Waiver version (could be event-specific)
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        eventId: eventId,
        isActive: true,
        updatedAt: DateTime.now(),
        metadata: <String, dynamic>{
          'waiver_type': waiverType,
          'waiver_sha256': waiverHash,
        },
      );
      
      await _saveAgreement(agreement);

      unawaited(_tryAppendLedgerAgreementAccepted(
        userId: userId,
        agreement: agreement,
        domain: LedgerDomainV0.expertise,
        eventType: 'event_waiver_accepted',
        entityType: 'event',
        entityId: eventId,
        payload: <String, Object?>{
          'agreement_id': agreement.id,
          'document_type': agreement.documentType,
          'version': agreement.version,
          'event_id': eventId,
          'waiver_type': waiverType,
          'waiver_sha256': waiverHash,
          if (ipAddress != null) 'ip_address': ipAddress,
          if (userAgent != null) 'user_agent': userAgent,
        },
      ));
      
      _logger.info('Event waiver accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting event waiver', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate event waiver text
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// Waiver text for the event
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<String> generateEventWaiver(String eventId) async {
    try {
      if (_eventService == null) {
        throw Exception('EventService not available');
      }
      
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Use EventWaiver class to generate waiver
      if (EventWaiver.requiresFullWaiver(event)) {
        return EventWaiver.generateWaiver(event);
      } else {
        return EventWaiver.generateSimplifiedWaiver(event);
      }
    } catch (e) {
      _logger.error('Error generating event waiver', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Check if user needs to accept updated Terms of Service
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user needs to accept new version, `false` otherwise
  Future<bool> needsTermsUpdate(String userId) async {
    try {
      final hasAccepted = await hasAcceptedTerms(userId);
      if (!hasAccepted) {
        return true; // Never accepted
      }
      
      final agreements = await getUserAgreements(userId);
      final termsAgreement = agreements.firstWhere(
        (a) => a.documentType == 'terms_of_service' && a.isActive,
        orElse: () => throw StateError('No terms agreement'),
      );
      
      // Check if version is current
      return !TermsOfService.isCurrentVersion(termsAgreement.version);
    } catch (e) {
      return true; // If error, assume update needed
    }
  }
  
  /// Check if user needs to accept updated Privacy Policy
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user needs to accept new version, `false` otherwise
  Future<bool> needsPrivacyUpdate(String userId) async {
    try {
      final hasAccepted = await hasAcceptedPrivacyPolicy(userId);
      if (!hasAccepted) {
        return true; // Never accepted
      }
      
      final agreements = await getUserAgreements(userId);
      final privacyAgreement = agreements.firstWhere(
        (a) => a.documentType == 'privacy_policy' && a.isActive,
        orElse: () => throw StateError('No privacy agreement'),
      );
      
      // Check if version is current
      return !PrivacyPolicy.isCurrentVersion(privacyAgreement.version);
    } catch (e) {
      return true; // If error, assume update needed
    }
  }
  
  /// Get all agreements for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of UserAgreement records
  Future<List<UserAgreement>> getUserAgreements(String userId) async {
    try {
      // 1) local
      final local = _readLocalAgreements(userId);

      // 2) remote hydration (best-effort) for new devices / cleared cache.
      if (_receipts != null &&
          _shouldSyncFromServer(userId) &&
          _isAuthenticatedAs(userId)) {
        unawaited(_syncFromLedger(userId));
      }

      return local;
    } catch (e) {
      _logger.error('Error getting user agreements', error: e, tag: _logName);
      return [];
    }
  }
  
  Future<UserAgreement?> _getAgreementForUser({
    required String userId,
    required String agreementId,
  }) async {
    try {
      final agreements = await getUserAgreements(userId);
      for (final a in agreements) {
        if (a.id == agreementId) return a;
      }
      return null;
    } catch (e) {
      _logger.error('Error getting agreement', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Revoke an agreement
  /// 
  /// **Parameters:**
  /// - `agreementId`: Agreement ID
  /// - `reason`: Reason for revocation
  /// 
  /// **Returns:**
  /// Updated UserAgreement
  Future<UserAgreement> revokeAgreement({
    required String userId,
    required String agreementId,
    String? reason,
  }) async {
    try {
      final agreement = await _getAgreementForUser(
        userId: userId,
        agreementId: agreementId,
      );
      if (agreement == null) {
        throw Exception('Agreement not found: $agreementId');
      }
      
      final updated = agreement.copyWith(
        isActive: false,
        revokedAt: DateTime.now(),
        revocationReason: reason,
        updatedAt: DateTime.now(),
      );
      
      await _saveAgreement(updated);
      
      _logger.info('Agreement revoked: $agreementId', tag: _logName);
      
      return updated;
    } catch (e) {
      _logger.error('Error revoking agreement', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  Future<void> _saveAgreement(UserAgreement agreement) async {
    final agreements = _readLocalAgreements(agreement.userId).toList(growable: true);
    agreements.removeWhere((a) => a.id == agreement.id);
    agreements.add(agreement);
    await _writeLocalAgreements(agreement.userId, agreements);
  }
  
  Future<void> _revokeOldAgreements(String userId, String documentType) async {
    try {
      final agreements = await getUserAgreements(userId);
      for (final agreement in agreements) {
        if (agreement.documentType == documentType && agreement.isActive) {
          await revokeAgreement(
            userId: userId,
            agreementId: agreement.id,
            reason: 'New version accepted',
          );
        }
      }
    } catch (e) {
      _logger.error('Error revoking old agreements', error: e, tag: _logName);
    }
  }

  UserAgreement? _latestActiveAgreement({
    required List<UserAgreement> agreements,
    required String documentType,
    String? eventId,
  }) {
    final matches = agreements.where((a) {
      if (!a.isActive) return false;
      if (a.documentType != documentType) return false;
      if (eventId != null && a.eventId != eventId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.agreedAt.compareTo(a.agreedAt));
    return matches.isEmpty ? null : matches.first;
  }

  String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  String _agreementsKey(String userId) => '${_agreementsKeyPrefix}_$userId';
  String _lastSyncMsKey(String userId) => '${_lastSyncMsKeyPrefix}_$userId';

  bool _isAuthenticatedAs(String userId) {
    final currentUserId = _supabaseService.currentUser?.id;
    return currentUserId != null && currentUserId == userId;
  }

  bool _shouldSyncFromServer(String userId) {
    if (!_supabaseService.isAvailable) return false;
    final lastMs = _storage.userStorage.read(_lastSyncMsKey(userId));
    if (lastMs is int) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      return DateTime.now().difference(last) > _syncTtl;
    }
    return true;
  }

  Future<bool> _syncNowIfHelpful(String userId) async {
    if (_receipts == null) return false;
    if (!_isAuthenticatedAs(userId)) return false;
    if (!_supabaseService.isAvailable) return false;
    if (!_shouldSyncFromServer(userId)) return false;
    await _syncFromLedger(userId);
    return true;
  }

  List<UserAgreement> _readLocalAgreements(String userId) {
    final raw = _storage.userStorage.read(_agreementsKey(userId));
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => UserAgreement.fromJson(m.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> _writeLocalAgreements(String userId, List<UserAgreement> agreements) async {
    await _storage.userStorage.write(
      _agreementsKey(userId),
      agreements.map((a) => a.toJson()).toList(growable: false),
    );
  }

  Future<void> _syncFromLedger(String userId) async {
    final receipts = _receipts;
    if (receipts == null) return;

    try {
      final local = _readLocalAgreements(userId).toList(growable: true);
      final byId = <String, UserAgreement>{for (final a in local) a.id: a};

      Future<void> ingest({
        required LedgerDomainV0 domain,
        required String eventType,
      }) async {
        final rows = await receipts.listReceipts(
          domain: domain,
          eventType: eventType,
          limit: 200,
        );
        for (final r in rows) {
          final p = r.event.payload;
          final docType = (p['document_type'] as String?) ?? '';
          final version = (p['version'] as String?) ?? '';
          final agreementId = (p['agreement_id'] as String?) ?? '';
          if (agreementId.isEmpty || docType.isEmpty || version.isEmpty) {
            continue;
          }

          final agreedAt = r.event.occurredAt;
          final eventId = p['event_id'] as String?;

          final ua = UserAgreement(
            id: agreementId,
            userId: userId,
            documentType: docType,
            version: version,
            agreedAt: agreedAt,
            ipAddress: p['ip_address'] as String?,
            userAgent: p['user_agent'] as String?,
            eventId: eventId,
            isActive: true,
            updatedAt: agreedAt,
            metadata: Map<String, dynamic>.from(p),
          );
          byId[ua.id] = ua;
        }
      }

      await ingest(domain: LedgerDomainV0.identity, eventType: 'terms_of_service_accepted');
      await ingest(domain: LedgerDomainV0.identity, eventType: 'privacy_policy_accepted');
      await ingest(domain: LedgerDomainV0.expertise, eventType: 'event_waiver_accepted');

      final merged = byId.values.toList(growable: false);
      await _writeLocalAgreements(userId, merged);
      await _storage.userStorage.write(_lastSyncMsKey(userId), DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.warn('Agreement sync from ledger failed: $e', tag: _logName);
    }
  }

  Future<void> _tryAppendLedgerAgreementAccepted({
    required String userId,
    required UserAgreement agreement,
    required LedgerDomainV0 domain,
    required String eventType,
    required String entityType,
    required String entityId,
    required Map<String, Object?> payload,
  }) async {
    final ledger = _ledger;
    if (ledger == null) return;

    try {
      await ledger.append(
        domain: domain,
        eventType: eventType,
        occurredAt: agreement.agreedAt,
        payload: payload,
        entityType: entityType,
        entityId: entityId,
        correlationId: agreement.id,
        source: 'legal_documents',
      );
    } catch (e) {
      _logger.warn(
        'Ledger append skipped/failed for $eventType: ${e.toString()}',
        tag: _logName,
      );
    }
  }
}

