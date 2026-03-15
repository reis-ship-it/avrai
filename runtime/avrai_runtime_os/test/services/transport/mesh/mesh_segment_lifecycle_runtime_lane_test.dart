import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_lifecycle_runtime_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshSegmentLifecycleRuntimeLane', () {
    test('runs an immediate refresh cycle on start', () async {
      final now = DateTime.utc(2026, 3, 13, 12);
      final refreshService = MeshSegmentCredentialRefreshService(
        nowUtc: () => now,
      );
      refreshService.recordIssued(
        credential: MeshSegmentCredential(
          credentialId: 'cred-expiring',
          segmentProfileId: 'segment-1',
          principalId: 'peer-a',
          principalKind: SignatureEntityKind.user,
          issuedAtUtc: now.subtract(const Duration(minutes: 5)),
          expiresAtUtc: now.add(const Duration(minutes: 5)),
        ),
        attestation: MeshAnnounceAttestation(
          attestationId: 'attest-expiring',
          segmentProfileId: 'segment-1',
          credentialId: 'cred-expiring',
          signerEntityId: 'peer-a',
          signerEntityKind: SignatureEntityKind.user,
          signedAtUtc: now.subtract(const Duration(minutes: 5)),
          expiresAtUtc: now.add(const Duration(minutes: 5)),
        ),
      );

      final lane = MeshSegmentLifecycleRuntimeLane(
        refreshService: refreshService,
        refreshInterval: const Duration(hours: 1),
        nowUtc: () => now,
      );

      await lane.start();

      expect(lane.started, isTrue);
      expect(lane.lastRanAtUtc, isNotNull);
      expect(lane.lastRefreshedCount, 1);
      expect(refreshService.expiringSoonCredentialCount(nowUtc: now), 0);

      await lane.dispose();
      expect(lane.started, isFalse);
    });
  });
}
