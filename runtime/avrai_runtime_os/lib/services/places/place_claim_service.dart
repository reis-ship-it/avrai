import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai_core/models/spots/claimed_place.dart';
import 'package:avrai_runtime_os/services/business/business_auth_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Service for business place claims.
///
/// **Flow:**
/// - Claim: business claims a place by google_place_id (verify → insert claimed_places).
/// - Unclaim: business releases a claim.
/// - ListClaimedPlaces(businessId): list all places claimed by a business.
/// - GetClaimingBusiness(googlePlaceId): returns business ID if place is claimed.
///
/// On success, callers may seed device-first knot/string for (businessId, google_place_id);
/// this service does not perform knot seeding.
class PlaceClaimService {
  static const String _logName = 'PlaceClaimService';
  static const String _functionName = 'place-claims-v1';

  final SupabaseService _supabaseService;
  final BusinessAuthService? _businessAuthService;

  PlaceClaimService({
    SupabaseService? supabaseService,
    BusinessAuthService? businessAuthService,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _businessAuthService = businessAuthService;

  BusinessSession _requireBusinessSession({String? businessId}) {
    final session = _businessAuthService?.getCurrentSession();
    if (session == null) {
      throw StateError('Business session required. Please sign in again.');
    }
    if (businessId != null && session.businessId != businessId) {
      throw StateError('Business session mismatch. Please sign in again.');
    }
    if (session.sessionId == null || session.sessionId!.isEmpty) {
      throw StateError(
        'Business session is missing a server token. Please sign in again.',
      );
    }
    return session;
  }

  Future<Map<String, dynamic>> _invokeAction({
    required String action,
    required Map<String, dynamic> body,
  }) async {
    if (!_supabaseService.isAvailable) {
      throw StateError('Supabase is not initialized');
    }

    final response = await _supabaseService.client.functions.invoke(
      _functionName,
      body: body,
    );

    final rawData = response.data;
    final Map<String, dynamic> data;
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.isNotEmpty) {
      final decoded = jsonDecode(rawData);
      data = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } else {
      data = <String, dynamic>{};
    }

    if (response.status < 200 || response.status >= 300) {
      final message = data['error'] as String? ??
          'Place claim request failed (${response.status})';
      throw Exception(message);
    }

    final ok = data['ok'];
    if (ok is bool && !ok) {
      throw Exception(
        data['error'] as String? ?? 'Place claim request failed.',
      );
    }

    developer.log('Edge action succeeded: $action', name: _logName);
    return data;
  }

  /// Claim a place for a business.
  ///
  /// [verificationMethod] optional, e.g. 'email_pin', 'google_business_profile'.
  /// Throws if place is already claimed by another business.
  /// Returns the created [ClaimedPlace].
  Future<ClaimedPlace> claim({
    required String businessId,
    required String googlePlaceId,
    String? verificationMethod,
  }) async {
    final session = _requireBusinessSession(businessId: businessId);
    try {
      final data = await _invokeAction(
        action: 'claim',
        body: {
          'action': 'claim',
          'sessionId': session.sessionId,
          'requestedBusinessId': businessId,
          'googlePlaceId': googlePlaceId,
          'verificationMethod': verificationMethod,
        },
      );
      final res = Map<String, dynamic>.from(data['claim'] as Map);
      final claimed = ClaimedPlace.fromJson(Map<String, dynamic>.from(res));
      developer.log(
        'Claimed place $googlePlaceId for business $businessId',
        name: _logName,
      );
      return claimed;
    } catch (e, st) {
      developer.log(
        'Claim failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Unclaim a place for a business (removes the claim if owned by this business).
  ///
  /// Returns true if a row was deleted, false if no matching claim.
  Future<bool> unclaim({
    required String businessId,
    required String googlePlaceId,
  }) async {
    final session = _requireBusinessSession(businessId: businessId);
    try {
      final data = await _invokeAction(
        action: 'unclaim',
        body: {
          'action': 'unclaim',
          'sessionId': session.sessionId,
          'requestedBusinessId': businessId,
          'googlePlaceId': googlePlaceId,
        },
      );
      final deleted = data['deleted'] == true;
      if (deleted) {
        developer.log(
          'Unclaimed place $googlePlaceId for business $businessId',
          name: _logName,
        );
      }
      return deleted;
    } catch (e, st) {
      developer.log(
        'Unclaim failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// List all places claimed by [businessId].
  Future<List<ClaimedPlace>> listClaimedPlaces(String businessId) async {
    final session = _requireBusinessSession(businessId: businessId);
    try {
      final data = await _invokeAction(
        action: 'list_claimed_places',
        body: {
          'action': 'list_claimed_places',
          'sessionId': session.sessionId,
          'requestedBusinessId': businessId,
        },
      );
      final list = (data['claims'] as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((e) => ClaimedPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      developer.log(
        'ListClaimedPlaces failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get the business ID that has claimed [googlePlaceId], or null if unclaimed.
  Future<String?> getClaimingBusiness(String googlePlaceId) async {
    final session = _requireBusinessSession();
    try {
      final data = await _invokeAction(
        action: 'get_claiming_business',
        body: {
          'action': 'get_claiming_business',
          'sessionId': session.sessionId,
          'googlePlaceId': googlePlaceId,
        },
      );
      return data['businessId'] as String?;
    } catch (e, st) {
      developer.log(
        'GetClaimingBusiness failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Update attraction override for a claimed place.
  ///
  /// Pass null to clear override (use business default).
  Future<ClaimedPlace> updateAttractionOverride({
    required String businessId,
    required String googlePlaceId,
    Map<String, double>? attractionOverride,
  }) async {
    final session = _requireBusinessSession(businessId: businessId);
    try {
      final data = await _invokeAction(
        action: 'update_attraction_override',
        body: {
          'action': 'update_attraction_override',
          'sessionId': session.sessionId,
          'requestedBusinessId': businessId,
          'googlePlaceId': googlePlaceId,
          'attractionOverride': attractionOverride,
        },
      );
      return ClaimedPlace.fromJson(
        Map<String, dynamic>.from(data['claim'] as Map),
      );
    } catch (e, st) {
      developer.log(
        'UpdateAttractionOverride failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get the claim record for [googlePlaceId], or null if unclaimed.
  Future<ClaimedPlace?> getClaimByPlaceId(String googlePlaceId) async {
    final session = _requireBusinessSession();
    try {
      final data = await _invokeAction(
        action: 'get_claim_by_place_id',
        body: {
          'action': 'get_claim_by_place_id',
          'sessionId': session.sessionId,
          'googlePlaceId': googlePlaceId,
        },
      );
      final claim = data['claim'];
      if (claim == null) return null;
      return ClaimedPlace.fromJson(Map<String, dynamic>.from(claim as Map));
    } catch (e, st) {
      developer.log(
        'GetClaimByPlaceId failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
