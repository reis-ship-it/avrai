import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/places/organic_spot_discovery_service.dart';
import 'package:get_it/get_it.dart';

class IncomingOrganicSpotDiscoveryProcessor {
  const IncomingOrganicSpotDiscoveryProcessor._();

  static Future<void> process({
    required Map<String, dynamic> payload,
    required String? currentUserId,
    required AppLogger logger,
    required String logName,
  }) async {
    final type = payload['type'] as String?;
    if (type != 'organic_spot_discovery') return;

    final geohash = payload['geohash'] as String?;
    final visitCount = (payload['visitCount'] as num?)?.toInt() ?? 0;
    final centroidLat = (payload['centroidLatitude'] as num?)?.toDouble();
    final centroidLon = (payload['centroidLongitude'] as num?)?.toDouble();

    if (geohash == null || centroidLat == null || centroidLon == null) return;
    if (visitCount < 2) return;

    final sl = GetIt.instance;
    if (!sl.isRegistered<OrganicSpotDiscoveryService>()) {
      return;
    }

    try {
      final discoveryService = sl<OrganicSpotDiscoveryService>();
      final userId = currentUserId;
      if (userId == null) return;

      await discoveryService.processMeshDiscoverySignal(
        userId: userId,
        geohash: geohash,
        reportedVisitCount: visitCount,
        centroidLatitude: centroidLat,
        centroidLongitude: centroidLon,
      );

      logger.debug(
        'Processed organic spot discovery signal: $geohash ($visitCount visits reported)',
        tag: logName,
      );
    } catch (e) {
      logger.debug(
        'Failed to process organic spot discovery signal: $e',
        tag: logName,
      );
    }
  }
}
