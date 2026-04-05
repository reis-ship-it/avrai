import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/locality_federated_exchange_service.dart';

void main() {
  group('LocalityFederatedExchangeService (Spike 5)', () {
    late LocalityFederatedExchangeService exchangeService;

    setUp(() {
      exchangeService = LocalityFederatedExchangeService();
    });

    test(
        'should encode precise latitude/longitude into a low-precision privacy geohash',
        () async {
      // Very precise location (like a specific house)
      const double exactLat = 37.7749295;
      const double exactLon = -122.4194155;

      // Ensure the Geohash service obfuscates it properly for the upload
      final privacyHash = GeohashService.encode(
        latitude: exactLat,
        longitude: exactLon,
        precision: 5, // 5km x 5km box
      );

      // The 5-character string is the only geographic identifier sent to the cloud
      expect(privacyHash.length, equals(5));
      expect(privacyHash, equals('9q8yy'));

      // Simulate a successful upload
      final gradients = [
        AnonymousGradient(
            category: 'spot_affinity', weightAdjustments: [0.1, 0.2])
      ];

      // This should not throw
      await exchangeService.uploadGradientsToLocality(
        latitude: exactLat,
        longitude: exactLon,
        gradients: gradients,
      );
    });

    test('should download global model updates for the local region', () async {
      final updates =
          await exchangeService.downloadGlobalModelUpdates(37.7749, -122.4194);

      expect(updates, isNotEmpty);
      expect(updates.first.category, equals('spot_affinity'));
      expect(updates.first.weightAdjustments, isNotEmpty);
    });
  });
}
