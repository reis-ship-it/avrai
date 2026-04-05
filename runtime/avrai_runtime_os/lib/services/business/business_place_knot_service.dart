import 'dart:developer' as developer;

import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/matching/attraction_12d_resolver.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';

/// Seeds device-first knot for a claimed business place.
///
/// After a business claims a place, this service generates and stores a knot
/// using the business's attraction 12D, so the place's compatibility profile
/// is active for user-place matching.
class BusinessPlaceKnotService {
  static const String _logName = 'BusinessPlaceKnotService';

  final BusinessAccountService _businessAccountService;
  final Attraction12DResolver _attractionResolver;
  final EntityKnotService _entityKnotService;
  final KnotStorageService _knotStorage;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'avrai',
    minimumLevel: LogLevel.debug,
  );

  BusinessPlaceKnotService({
    required BusinessAccountService businessAccountService,
    required Attraction12DResolver attractionResolver,
    required EntityKnotService entityKnotService,
    required KnotStorageService knotStorage,
  })  : _businessAccountService = businessAccountService,
        _attractionResolver = attractionResolver,
        _entityKnotService = entityKnotService,
        _knotStorage = knotStorage;

  /// Seed device-first knot for a claimed place.
  ///
  /// Fetches business attraction 12D, generates knot via EntityKnotService,
  /// and stores it with key `business_place_knot:{businessId}:{googlePlaceId}`.
  /// Fails gracefully (logs and returns) if any step fails.
  Future<void> seedKnotForClaimedPlace(
    String businessId,
    String googlePlaceId,
  ) async {
    try {
      final business =
          await _businessAccountService.getBusinessAccount(businessId);
      if (business == null) {
        _logger.warning('Business not found: $businessId', tag: _logName);
        return;
      }

      final attraction12D = _attractionResolver.resolveForBusiness(business);

      final spot = Spot(
        id: googlePlaceId,
        name: 'Claimed place',
        description: '',
        latitude: 0,
        longitude: 0,
        category: 'place',
        rating: 0,
        createdBy: businessId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        googlePlaceId: googlePlaceId,
      );

      final entityKnot = await _entityKnotService.generateKnotForEntity(
        entityType: EntityType.place,
        entity: spot,
        dimensions12D: attraction12D,
      );

      await _knotStorage.saveBusinessPlaceKnot(
        businessId,
        googlePlaceId,
        entityKnot.knot,
      );

      _logger.info(
        'Seeded knot for claimed place: $businessId / $googlePlaceId',
        tag: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to seed knot for claimed place: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
