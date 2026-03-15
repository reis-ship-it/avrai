import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late SharedPreferencesCompat prefs;
  late AdminControlPlaneGateway gateway;

  AdminControlPlaneSessionRequest buildRequest({
    String operatorAlias = 'admin_operator',
    String oidcAssertion = 'oidc-assertion',
    String mfaProof = '123456',
    bool managedDevice = true,
    bool signedDesktopBinary = true,
    String meshIdentity = 'mesh-node-1',
    String clientCertificateFingerprint = 'cert-fingerprint',
  }) {
    return AdminControlPlaneSessionRequest(
      operatorAlias: operatorAlias,
      oidcAssertion: oidcAssertion,
      mfaProof: mfaProof,
      deviceAttestation: AdminControlPlaneDeviceAttestation(
        deviceId: 'device-1',
        platform: 'macos',
        privateMeshProvider: 'headscale_tailscale',
        meshIdentity: meshIdentity,
        clientCertificateFingerprint: clientCertificateFingerprint,
        signedDesktopBinary: signedDesktopBinary,
        managedDevice: managedDevice,
        diskEncryptionEnabled: true,
        osPatchBaselineSatisfied: true,
      ),
      allowedGroups: const <String>['admin_operator'],
    );
  }

  AdminControlPlaneStepUpProof buildStepUpProof() {
    return AdminControlPlaneStepUpProof(
      proof: 'step-up-proof',
      issuedAt: DateTime.now().toUtc(),
    );
  }

  AdminControlPlaneSecondOperatorApproval buildSecondApproval() {
    return AdminControlPlaneSecondOperatorApproval(
      actorAlias: 'admin_operator_2',
      proof: 'second-operator-proof',
      approvedAt: DateTime.now().toUtc(),
    );
  }

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
    storageRoot = await Directory.systemTemp.createTemp(
      'admin_control_plane_gateway_',
    );
    await GetStorage('admin_control_plane_gateway', storageRoot.path)
        .initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore temp cleanup failures.
    }
  });

  setUp(() async {
    final storage = GetStorage('admin_control_plane_gateway');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    gateway = AdminControlPlaneGatewayFactory.createForTesting(prefs: prefs);
  });

  test('createSession denies missing MFA proof', () async {
    await expectLater(
      gateway.createSession(
        request: buildRequest(mfaProof: ''),
      ),
      throwsA(isA<AdminControlPlaneAuthException>()),
    );
  });

  test('createSession denies unmanaged device posture', () async {
    await expectLater(
      gateway.createSession(
        request: buildRequest(managedDevice: false),
      ),
      throwsA(isA<AdminControlPlaneAuthException>()),
    );
  });

  test('stopRun requires step-up proof', () async {
    await gateway.createSession(request: buildRequest());
    final runningRun = (await gateway.listResearchRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.running,
    );

    expect(
      () => gateway.stopRun(
        runId: runningRun.id,
        actorAlias: 'admin_operator',
        rationale: 'Testing policy gate',
      ),
      throwsA(isA<GovernedAutoresearchActionBlockedException>()),
    );
  });

  test('approveOpenWeb requires dual approval', () async {
    await gateway.createSession(request: buildRequest());
    final runningRun = (await gateway.listResearchRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.running,
    );

    await gateway.requestOpenWebApproval(
      runId: runningRun.id,
      actorAlias: 'admin_operator',
      ttl: const Duration(hours: 4),
      rationale: 'Internal evidence exhausted.',
      stepUpProof: buildStepUpProof(),
    );

    expect(
      () => gateway.approveOpenWeb(
        runId: runningRun.id,
        actorAlias: 'admin_operator',
        ttl: const Duration(hours: 4),
        rationale: 'Attempt without second operator.',
        stepUpProof: buildStepUpProof(),
        secondOperatorApproval: AdminControlPlaneSecondOperatorApproval(
          actorAlias: 'admin_operator',
          proof: 'same-operator-proof',
          approvedAt: DateTime.now().toUtc(),
        ),
      ),
      throwsA(isA<GovernedAutoresearchActionBlockedException>()),
    );
  });

  test('approved brokered open-web fetch remains quarantined and redacted',
      () async {
    await gateway.createSession(request: buildRequest());
    final runningRun = (await gateway.listResearchRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.running,
    );

    await gateway.requestOpenWebApproval(
      runId: runningRun.id,
      actorAlias: 'admin_operator',
      ttl: const Duration(hours: 4),
      rationale: 'Internal evidence exhausted.',
      stepUpProof: buildStepUpProof(),
    );
    await gateway.approveOpenWeb(
      runId: runningRun.id,
      actorAlias: 'admin_operator',
      ttl: const Duration(hours: 4),
      rationale: 'Approved for brokered fetch.',
      stepUpProof: buildStepUpProof(),
      secondOperatorApproval: buildSecondApproval(),
    );

    final artifact = await gateway.fetchEvidence(
      runId: runningRun.id,
      actorAlias: 'reality_worker_a',
      sourceUri: Uri.parse('https://example.com/research'),
    );

    expect(artifact.kind, ResearchArtifactKind.evidenceBundle);
    expect(artifact.storageKey, startsWith('broker://quarantine/'));
    expect(artifact.isRedacted, isTrue);
  });

  test('downloadEvidencePack returns signed redacted artifact', () async {
    await gateway.createSession(request: buildRequest());
    final runningRun = (await gateway.listResearchRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.running,
    );
    final artifact = await gateway.downloadEvidencePack(
      runId: runningRun.id,
      actorAlias: 'admin_operator',
      artifactIds: const <String>['artifact-a', 'artifact-b'],
      stepUpProof: buildStepUpProof(),
    );

    expect(artifact.kind, ResearchArtifactKind.signedEvidencePack);
    expect(artifact.isRedacted, isTrue);
    expect(artifact.storageKey, startsWith('evidence-pack://'));
    expect(artifact.checksum, isNotNull);
  });
}
