import 'dart:convert';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import '../models/spatial/swarm_map_environment.dart';

/// Radioactive payload containing raw POI/location data.
/// This must not be accessed outside the Air Gap pipeline.
class RawCityEventPayload extends RawDataPayload {
  final PointOfInterest poi;

  const RawCityEventPayload({
    required super.capturedAt,
    required this.poi,
  }) : super(sourceId: 'locality_historical_ingestion');

  @override
  String get rawContent => jsonEncode({
        'id': poi.id,
        'name': poi.name,
        'category': poi.category.name,
        'lat': poi.location.latitude,
        'lng': poi.location.longitude,
        'cost': poi.cost,
        'quality': poi.baseQuality,
      });
}
