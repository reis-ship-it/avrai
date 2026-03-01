import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Best-effort onboarding geo context resolver (v1)
///
/// This bridges onboarding (homebase selection) with the geo hierarchy + locality packs by:
/// - reading cached homebase coordinates (stored by `HomebaseSelectionPage`)
/// - resolving `(cityCode, localityCode, displayName)` via `GeoHierarchyService`
///
/// The result is designed to be attached to onboarding-generated list metadata so
/// downstream geo/geofence features can reason consistently about where lists were generated.
class OnboardingGeoContextService {
  static const String _logName = 'OnboardingGeoContextService';

  final GeoHierarchyService _geoHierarchyService;
  final SharedPreferencesCompat? _prefs;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'avrai', minimumLevel: LogLevel.debug);

  OnboardingGeoContextService({
    required GeoHierarchyService geoHierarchyService,
    required SharedPreferencesCompat? prefs,
  })  : _geoHierarchyService = geoHierarchyService,
        _prefs = prefs;

  /// Resolve cached homebase geo context (best-effort)
  ///
  /// This should never block onboarding; failures return an empty context.
  Future<OnboardingGeoContextV1> resolveHomebaseGeoContextBestEffort() async {
    final prefs = _prefs;
    if (prefs == null) return const OnboardingGeoContextV1.empty();

    final lat = prefs.getDouble('cached_lat');
    final lon = prefs.getDouble('cached_lng');
    if (lat == null || lon == null) return const OnboardingGeoContextV1.empty();

    try {
      final locality = await _geoHierarchyService.lookupLocalityByPoint(
        lat: lat,
        lon: lon,
      );
      return OnboardingGeoContextV1(
        latitude: lat,
        longitude: lon,
        cityCode: locality?.cityCode,
        localityCode: locality?.localityCode,
        displayName: locality?.displayName,
      );
    } catch (e) {
      // Best-effort: geo lookups are non-blocking during onboarding init.
      _logger.warn('⚠️ Geo hierarchy lookup failed: $e', tag: _logName);
      return OnboardingGeoContextV1(
        latitude: lat,
        longitude: lon,
      );
    }
  }
}

/// Resolved geo context for onboarding (v1)
class OnboardingGeoContextV1 {
  final double? latitude;
  final double? longitude;
  final String? cityCode;
  final String? localityCode;
  final String? displayName;

  const OnboardingGeoContextV1({
    this.latitude,
    this.longitude,
    this.cityCode,
    this.localityCode,
    this.displayName,
  });

  const OnboardingGeoContextV1.empty()
      : latitude = null,
        longitude = null,
        cityCode = null,
        localityCode = null,
        displayName = null;

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'homebaseLat': latitude,
        'homebaseLon': longitude,
        'cityCode': cityCode,
        'localityCode': localityCode,
        'displayName': displayName,
      };
}
