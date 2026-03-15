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
  late GovernedAutoresearchSupervisor service;

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
      'governed_autoresearch_',
    );
    await GetStorage('governed_autoresearch', storageRoot.path).initStorage;
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
    final storage = GetStorage('governed_autoresearch');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
    service = GovernedAutoresearchSupervisorFactory.createForTesting(
      prefs: prefs,
    ).service;
  });

  test('beta factory fails closed when private backend is unavailable',
      () async {
    await expectLater(
      GovernedAutoresearchSupervisorFactory.createDefault(prefs: prefs),
      throwsA(isA<GovernedAutoresearchUnavailableException>()),
    );
  });

  test('fixture runs remain admin-only and sandbox-only', () async {
    final runs = await service.listRuns();

    expect(runs, isNotEmpty);
    expect(
      runs.every(
        (ResearchRunState run) =>
            run.humanAccess == ResearchHumanAccess.adminOnly &&
            run.visibilityScope ==
                ResearchVisibilityScope.runtimeInternalProjection &&
            run.sandboxOnly,
      ),
      isTrue,
    );
  });

  test('draft runs cannot be queued before charter approval', () async {
    final draftRun = (await service.listRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.draft,
    );

    await expectLater(
      service.queueRun(
        runId: draftRun.id,
        actorAlias: 'admin_operator',
      ),
      throwsA(isA<GovernedAutoresearchActionBlockedException>()),
    );
  });

  test('open-web fetch stays blocked until admin approves brokered access',
      () async {
    final runningRun = (await service.listRuns()).firstWhere(
      (ResearchRunState run) =>
          run.lifecycleState == ResearchRunLifecycleState.running,
    );

    await expectLater(
      service.fetchEvidence(
        runId: runningRun.id,
        actorAlias: 'reality_worker_a',
        sourceUri: Uri.parse('https://example.com/research'),
      ),
      throwsA(isA<GovernedAutoresearchActionBlockedException>()),
    );

    await service.requestOpenWebAccess(
      runId: runningRun.id,
      actorAlias: 'reality_worker_a',
      ttl: const Duration(hours: 4),
      rationale: 'Internal evidence exhausted.',
    );
    await service.reviewCandidate(
      runId: runningRun.id,
      actorAlias: 'admin_operator',
      approved: true,
      rationale: 'Brokered egress approved for this run.',
    );

    final artifact = await service.fetchEvidence(
      runId: runningRun.id,
      actorAlias: 'reality_worker_a',
      sourceUri: Uri.parse('https://example.com/research'),
    );

    expect(artifact.kind, ResearchArtifactKind.evidenceBundle);
    expect(artifact.storageKey, startsWith('broker://quarantine/'));
    expect(artifact.isRedacted, isTrue);
  });
}
