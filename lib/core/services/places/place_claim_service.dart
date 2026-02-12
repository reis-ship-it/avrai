import 'dart:developer' as developer;
import 'package:avrai/core/models/spots/claimed_place.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

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
  static const String _table = 'claimed_places';

  final SupabaseService _supabaseService;

  PlaceClaimService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

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
    if (!_supabaseService.isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    final client = _supabaseService.client;
    try {
      final res = await client
          .from(_table)
          .insert({
            'business_id': businessId,
            'google_place_id': googlePlaceId,
            'verification_method': verificationMethod,
          })
          .select()
          .single();
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
    if (!_supabaseService.isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    final client = _supabaseService.client;
    try {
      final res = await client
          .from(_table)
          .delete()
          .eq('business_id', businessId)
          .eq('google_place_id', googlePlaceId)
          .select('id');
      final list = res as List<dynamic>;
      final deleted = list.isNotEmpty;
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
    if (!_supabaseService.isAvailable) {
      return [];
    }
    final client = _supabaseService.client;
    try {
      final res = await client
          .from(_table)
          .select()
          .eq('business_id', businessId)
          .order('claimed_at', ascending: false);
      final list = res as List<dynamic>;
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
    if (!_supabaseService.isAvailable) {
      return null;
    }
    final client = _supabaseService.client;
    try {
      final res = await client
          .from(_table)
          .select('business_id')
          .eq('google_place_id', googlePlaceId)
          .maybeSingle();
      if (res == null) return null;
      return res['business_id'] as String?;
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
    if (!_supabaseService.isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    final client = _supabaseService.client;
    try {
      final overrideJson = attractionOverride?.map((k, v) => MapEntry(k, v));
      final res = await client
          .from(_table)
          .update({'attraction_override': overrideJson})
          .eq('business_id', businessId)
          .eq('google_place_id', googlePlaceId)
          .select()
          .single();
      return ClaimedPlace.fromJson(Map<String, dynamic>.from(res));
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
    if (!_supabaseService.isAvailable) {
      return null;
    }
    final client = _supabaseService.client;
    try {
      final res = await client
          .from(_table)
          .select()
          .eq('google_place_id', googlePlaceId)
          .maybeSingle();
      if (res == null) return null;
      return ClaimedPlace.fromJson(Map<String, dynamic>.from(res));
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
