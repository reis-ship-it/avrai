import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  AdminControlPlaneSessionRequest buildRequest() {
    return const AdminControlPlaneSessionRequest(
      operatorAlias: 'admin_operator',
      oidcAssertion: 'oidc-assertion',
      mfaProof: '654321',
      deviceAttestation: AdminControlPlaneDeviceAttestation(
        deviceId: 'device-1',
        platform: 'macos',
        privateMeshProvider: 'headscale_tailscale',
        meshIdentity: 'mesh-node-1',
        clientCertificateFingerprint: 'cert-fingerprint',
        signedDesktopBinary: true,
        managedDevice: true,
        diskEncryptionEnabled: true,
        osPatchBaselineSatisfied: true,
      ),
      allowedGroups: <String>['admin_operator'],
    );
  }

  ResearchRunState buildRunState() {
    final now = DateTime.utc(2026, 3, 14, 12);
    return ResearchRunState(
      id: 'gar_beta_reality_01',
      title: 'Reality replay prior tuning',
      hypothesis: 'Replay prior ranking improves.',
      layer: ResearchLayer.reality,
      ownerAgentAlias: 'reality_worker_a',
      lifecycleState: ResearchRunLifecycleState.running,
      humanAccess: ResearchHumanAccess.adminOnly,
      visibilityScope: ResearchVisibilityScope.runtimeInternalProjection,
      lane: ResearchRunLane.sandboxReplay,
      charter: ResearchCharter(
        id: 'charter_01',
        title: 'Reality replay prior tuning',
        objective: 'Improve replay ranking in sandbox only.',
        hypothesis: 'Approved examples stabilize ranking.',
        allowedExperimentSurfaces: const <String>['replay_priors'],
        successMetrics: const <String>['promotionReadiness >= 0.8'],
        stopConditions: const <String>['contradiction_detected'],
        hardBans: const <String>['production_mutation'],
        createdAt: now,
        updatedAt: now,
        approvedBy: 'admin_operator',
        approvedAt: now,
      ),
      egressMode: ResearchEgressMode.internalOnly,
      requiresAdminApproval: true,
      sandboxOnly: true,
      modelVersion: 'beta-reality-model-2026.03',
      policyVersion: 'opa-gar-beta-v1',
      metrics: const <String, double>{
        'promotionReadiness': 0.78,
      },
      tags: const <String>['reality'],
      controlActions: const <ResearchControlAction>[],
      checkpoints: const <ResearchCheckpoint>[],
      approvals: const <ResearchApproval>[],
      artifacts: const <ResearchArtifactRef>[],
      alerts: const <ResearchAlert>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  test(
      'createSession stores active session from private control-plane response',
      () async {
    final gateway = HttpAdminControlPlaneGateway(
      baseUri: Uri.parse('http://127.0.0.1:7443/'),
      httpClient: MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/sessions');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['operatorAlias'], 'admin_operator');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'sessionToken': 'session-token',
            'sessionTokenId': 'cp_session_1',
            'actorAlias': 'admin_operator',
            'role': 'adminOperator',
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 30))
                .toIso8601String(),
            'issuedBy': 'private_admin_control_plane_gateway',
            'policyVersion': 'opa-gar-beta-v1',
            'deviceId': 'device-1',
            'meshIdentity': 'mesh-node-1',
            'clientCertificateFingerprint': 'cert-fingerprint',
            'requiresPrivateControlPlane': true,
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }),
    );

    final grant = await gateway.createSession(request: buildRequest());

    expect(grant.sessionToken, 'session-token');
    expect(gateway.hasActiveSession, isTrue);
    expect(gateway.activeSession?.actorAlias, 'admin_operator');
  });

  test('listResearchRuns uses bearer session and decodes run payload',
      () async {
    final run = buildRunState();
    var callCount = 0;
    final gateway = HttpAdminControlPlaneGateway(
      baseUri: Uri.parse('http://127.0.0.1:7443/'),
      httpClient: MockClient((http.Request request) async {
        callCount += 1;
        if (request.url.path == '/v1/sessions') {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'sessionToken': 'session-token',
              'sessionTokenId': 'cp_session_2',
              'actorAlias': 'admin_operator',
              'role': 'adminOperator',
              'expiresAt': DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 30))
                  .toIso8601String(),
              'issuedBy': 'private_admin_control_plane_gateway',
              'policyVersion': 'opa-gar-beta-v1',
              'deviceId': 'device-1',
              'meshIdentity': 'mesh-node-1',
              'clientCertificateFingerprint': 'cert-fingerprint',
              'requiresPrivateControlPlane': true,
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/research/runs');
        expect(request.headers['authorization'], 'Bearer session-token');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'runs': <Map<String, dynamic>>[run.toJson()],
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }),
    );

    await gateway.createSession(request: buildRequest());
    final runs = await gateway.listResearchRuns();

    expect(callCount, 2);
    expect(runs, hasLength(1));
    expect(runs.first.id, run.id);
    expect(runs.first.lifecycleState, ResearchRunLifecycleState.running);
  });
}
