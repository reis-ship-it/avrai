import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/security/countermeasure_propagation_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../../support/fake_kernel_governance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late SharedPreferencesCompat prefs;
  late GovernanceKernelService governanceKernel;

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
    storageRoot =
        await Directory.systemTemp.createTemp('security_propagation_');
    await GetStorage('security_propagation', storageRoot.path).initStorage;
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
    final storage = GetStorage('security_propagation');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    governanceKernel = buildTestGovernanceKernelService();
  });

  test('runs shadow rollout, activation, and rollback with receipts', () async {
    final ledger = ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final service = CountermeasurePropagationService(
      governanceKernelService: governanceKernel,
      immuneMemoryLedger: ledger,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final targetScope = const TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'security_learning',
      familyId: 'federated_update_poisoning',
    );
    final candidate = CountermeasureBundleCandidate(
      candidateId: 'candidate-1',
      status: CountermeasureBundleCandidateStatus.candidate,
      bundle: SecurityCountermeasureBundle(
        bundleId: 'bundle-1',
        targetScope: targetScope,
        allowedStrata: const <GovernanceStratum>[
          GovernanceStratum.locality,
        ],
        tenantScope: TruthTenantScope.avraiNative,
        evidenceEnvelopeTraceIds: const <String>['trace-1'],
        requiredApprovals: const <String>['security_lead'],
        signature: 'signed-bundle',
        signedBy: 'security_lead',
        signedAt: DateTime.utc(2026, 3, 14, 11),
      ),
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      sourceFindingIds: const <String>['finding-1'],
      shadowValidationEvidenceTraceIds: const <String>['trace-1'],
      approvalActors: const <String>['security_lead'],
    );
    final evidence = TruthEvidenceEnvelope(
      scope: targetScope,
      traceId: 'trace-1',
      evidenceClass: 'sandbox_redteam',
      privacyLadderTag: 'redacted',
      approvals: const <String>['security_lead'],
    );

    final shadowReceipts = await service.propagateCandidate(
      candidate: candidate,
      evidenceEnvelope: evidence,
    );
    expect(shadowReceipts, hasLength(1));
    expect(shadowReceipts.first.activationStage, 'shadow');

    final staged = await service.acknowledgeReceipt(
      receiptId: shadowReceipts.first.receiptId,
      actorAlias: 'mesh-locality-1',
    );
    expect(staged.activationStage, 'staged');

    final activeReceipts = await service.activateBundle('bundle-1');
    expect(activeReceipts.single.activationStage, 'active');
    expect(activeReceipts.single.activatedAt, isNotNull);

    final rolledBack = await service.rollbackBundle(
      bundleId: 'bundle-1',
      reason: 'false_positive_review',
    );
    expect(rolledBack.single.activationStage, 'rolledBack');
    expect(rolledBack.single.rolledBack, isTrue);
    expect(rolledBack.single.rollbackReason, 'false_positive_review');
  });

  test('rejects unsigned bundles before propagation', () async {
    final ledger = ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final service = CountermeasurePropagationService(
      governanceKernelService: governanceKernel,
      immuneMemoryLedger: ledger,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    const targetScope = TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'security_learning',
      familyId: 'federated_update_poisoning',
    );
    final candidate = CountermeasureBundleCandidate(
      candidateId: 'candidate-2',
      status: CountermeasureBundleCandidateStatus.candidate,
      bundle: SecurityCountermeasureBundle(
        bundleId: 'bundle-2',
        targetScope: targetScope,
        allowedStrata: const <GovernanceStratum>[
          GovernanceStratum.locality,
        ],
        tenantScope: TruthTenantScope.avraiNative,
        evidenceEnvelopeTraceIds: const <String>['trace-2'],
        requiredApprovals: const <String>['security_lead'],
      ),
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      sourceFindingIds: const <String>['finding-2'],
      shadowValidationEvidenceTraceIds: const <String>['trace-2'],
      approvalActors: const <String>['security_lead'],
    );
    final evidence = TruthEvidenceEnvelope(
      scope: targetScope,
      traceId: 'trace-2',
      evidenceClass: 'sandbox_redteam',
      privacyLadderTag: 'redacted',
      approvals: const <String>['security_lead'],
    );

    await expectLater(
      () => service.propagateCandidate(
        candidate: candidate,
        evidenceEnvelope: evidence,
      ),
      throwsStateError,
    );
  });

  test('stale receipts force rollback instead of remaining shadow-only',
      () async {
    var currentTime = DateTime.utc(2026, 3, 14, 12);
    final ledger = ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => currentTime,
    );
    final service = CountermeasurePropagationService(
      governanceKernelService: governanceKernel,
      immuneMemoryLedger: ledger,
      nowProvider: () => currentTime,
    );
    const targetScope = TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'security_autonomy',
      familyId: 'autonomy_hijack',
    );
    final candidate = CountermeasureBundleCandidate(
      candidateId: 'candidate-3',
      status: CountermeasureBundleCandidateStatus.candidate,
      bundle: SecurityCountermeasureBundle(
        bundleId: 'bundle-3',
        targetScope: targetScope,
        allowedStrata: const <GovernanceStratum>[
          GovernanceStratum.locality,
        ],
        tenantScope: TruthTenantScope.avraiNative,
        evidenceEnvelopeTraceIds: const <String>['trace-3'],
        requiredApprovals: const <String>['security_lead'],
        minimumAcknowledgements: 2,
        signature: 'signed-bundle',
        signedBy: 'security_lead',
        signedAt: DateTime.utc(2026, 3, 14, 11),
      ),
      createdAt: DateTime.utc(2026, 3, 14, 12),
      updatedAt: DateTime.utc(2026, 3, 14, 12),
      sourceFindingIds: const <String>['finding-3'],
      shadowValidationEvidenceTraceIds: const <String>['trace-3'],
      approvalActors: const <String>['security_lead'],
    );
    final evidence = TruthEvidenceEnvelope(
      scope: targetScope,
      traceId: 'trace-3',
      evidenceClass: 'sandbox_redteam',
      privacyLadderTag: 'redacted',
      approvals: const <String>['security_lead'],
    );

    final shadowReceipts = await service.propagateCandidate(
      candidate: candidate,
      evidenceEnvelope: evidence,
    );
    expect(shadowReceipts, hasLength(1));

    currentTime = DateTime.utc(2026, 3, 14, 20);
    final rolledBack = await service.markStaleReceipts(bundleId: 'bundle-3');

    expect(rolledBack, hasLength(1));
    expect(rolledBack.single.rolledBack, isTrue);
    expect(rolledBack.single.staleNode, isTrue);
    expect(rolledBack.single.activationStage, 'rolledBack');
    expect(rolledBack.single.rollbackReason, 'stale_node_threshold_exceeded');
  });
}
