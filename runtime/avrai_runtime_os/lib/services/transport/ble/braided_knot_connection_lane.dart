// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';

class BraidedKnotConnectionLane {
  const BraidedKnotConnectionLane._();

  static Future<BraidedKnot?> maybeCreate({
    required KnotWeavingService? knotWeavingService,
    required KnotStorageService? knotStorageService,
    required String localAgentId,
    required String remoteAgentId,
    required String connectionId,
    required AppLogger logger,
    required String logName,
  }) async {
    if (knotWeavingService == null || knotStorageService == null) return null;

    try {
      final localKnot = await knotStorageService.loadKnot(localAgentId);
      final remoteKnot = await knotStorageService.loadKnot(remoteAgentId);

      if (localKnot == null || remoteKnot == null) {
        logger.debug(
          'Knots not available for braiding (local: ${localKnot != null}, remote: ${remoteKnot != null})',
          tag: logName,
        );
        return null;
      }

      final braidedKnot = await knotWeavingService.weaveKnots(
        knotA: localKnot,
        knotB: remoteKnot,
        relationshipType: RelationshipType.friendship,
      );

      await knotStorageService.saveBraidedKnot(
        connectionId: connectionId,
        braidedKnot: braidedKnot,
      );

      logger.info(
        'Braided knot created for connection: $connectionId',
        tag: logName,
      );
      return braidedKnot;
    } catch (e) {
      logger.warn(
        'Error creating braided knot: $e, continuing without braided knot',
        tag: logName,
      );
      return null;
    }
  }
}
