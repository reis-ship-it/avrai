import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late SharedPreferencesCompat prefs;

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
    storageRoot = await Directory.systemTemp.createTemp('security_trigger_');
    await GetStorage('security_trigger', storageRoot.path).initStorage;
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
    final storage = GetStorage('security_trigger');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
  });

  test('queues only code-change campaigns whose path prefixes match', () async {
    final service = SecurityTriggerIngressService(
      campaignRegistry: const SecurityCampaignRegistry(),
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );

    await service.notifyCodeChange(
      changedPaths: const <String>[
        'runtime/avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart',
      ],
      commitRef: 'abc123',
    );

    final pending = await service.flushPendingTriggers();
    expect(pending, isNotEmpty);
    expect(
      pending.any((entry) => entry.campaignId == 'rt-006-signal-lifecycle'),
      isTrue,
    );
    expect(
      pending.any((entry) => entry.campaignId == 'rt-004-federated-updates'),
      isFalse,
    );
  });

  test('queues model and policy promotions by selector and scope', () async {
    final service = SecurityTriggerIngressService(
      campaignRegistry: const SecurityCampaignRegistry(),
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );

    await service.notifyModelPromotion(
      surfaceId: 'calling_score',
      version: 'v2-security-rollout',
    );
    await service.notifyPolicyPromotion(
      policyId: 'admin_break_glass_policy',
      scope: const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.universal,
        sphereId: 'security_admin',
        familyId: 'admin_operator_abuse',
      ),
    );

    final pending = await service.flushPendingTriggers();
    expect(
      pending.any((entry) => entry.campaignId == 'rt-004-federated-updates'),
      isTrue,
    );
    expect(
      pending.any((entry) => entry.campaignId == 'rt-012-admin-operator'),
      isTrue,
    );
  });

  test('queues incident replay campaigns by incident tag and scope', () async {
    final service = SecurityTriggerIngressService(
      campaignRegistry: const SecurityCampaignRegistry(),
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );

    await service.notifyReplayedIncident(
      incidentId: 'incident-1',
      tags: const <String>['privacy', 'reidentification'],
      truthScope: const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.universal,
        sphereId: 'security_exports',
        familyId: 'reidentification_simulation',
      ),
    );

    final pending = await service.flushPendingTriggers();
    expect(
      pending.any(
        (entry) => entry.campaignId == 'rt-008-exports-reidentification',
      ),
      isTrue,
    );
  });
}
