import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../support/fake_language_kernels.dart';

void main() {
  group('LanguageKernelOrchestratorService', () {
    late LanguageKernelOrchestratorService service;
    late VibeKernel vibeKernel;

    setUp(() {
      VibeKernel.resetFallbackStateForTesting();
      TrajectoryKernel.resetFallbackStateForTesting();
      TrajectoryKernel().importJournalWindow(records: const []);
      vibeKernel = VibeKernel();
      service = buildDeterministicLanguageKernelOrchestrator(
        vibeKernel: vibeKernel,
      );
    });

    test('interprets and accepts grounded local learning text', () async {
      final turn = await service.processHumanText(
        actorAgentId: 'agt_user123456',
        rawText: 'I like quieter coffee shops and slower mornings.',
        consentScopes: const <String>{'user_runtime_learning'},
      );

      expect(turn.interpretation.intent, InterpretationIntent.prefer);
      expect(turn.boundary.accepted, isTrue);
      expect(turn.boundary.disposition, BoundaryDisposition.storeSanitized);
      expect(turn.boundary.learningAllowed, isTrue);
      expect(turn.boundary.egressAllowed, isFalse);
    });

    test(
      'blocks egress in local sovereign mode even when share is requested',
      () async {
        final turn = await service.processHumanText(
          actorAgentId: 'agt_user123456',
          rawText: 'Send this to my friend later.',
          consentScopes: const <String>{
            'user_runtime_learning',
            'ai2ai_learning',
          },
          shareRequested: true,
          privacyMode: BoundaryPrivacyMode.localSovereign,
        );

        expect(turn.boundary.accepted, isTrue);
        expect(turn.boundary.disposition, BoundaryDisposition.localOnly);
        expect(turn.boundary.egressAllowed, isFalse);
        expect(turn.boundary.airGapRequired, isFalse);
      },
    );

    test(
      'allows explicit direct-message egress in local sovereign mode',
      () async {
        final turn = await service.processHumanText(
          actorAgentId: 'agt_user123456',
          rawText: 'Send this exact note to Taylor.',
          consentScopes: const <String>{
            'user_runtime_learning',
            'ai2ai_learning',
          },
          shareRequested: true,
          privacyMode: BoundaryPrivacyMode.localSovereign,
          egressPurpose: BoundaryEgressPurpose.directMessage,
        );

        expect(turn.boundary.accepted, isTrue);
        expect(
          turn.boundary.disposition,
          BoundaryDisposition.userAuthorizedEgress,
        );
        expect(turn.boundary.transcriptStorageAllowed, isTrue);
        expect(turn.boundary.storageAllowed, isFalse);
        expect(turn.boundary.learningAllowed, isFalse);
        expect(turn.boundary.egressAllowed, isTrue);
        expect(turn.boundary.airGapRequired, isFalse);
        expect(
          turn.boundary.reasonCodes,
          contains('explicit_user_message_delivery'),
        );
      },
    );

    test('accepts governance-mode learning with governance consent', () async {
      final turn = await service.processHumanText(
        actorAgentId: 'agt_governance_world',
        rawText: 'Group low-coherence anomalies under transport drift.',
        consentScopes: const <String>{'governance_runtime_learning'},
        privacyMode: BoundaryPrivacyMode.governance,
        surface: 'admin_reality_system_check_in',
        channel: 'admin_console',
      );

      expect(turn.boundary.accepted, isTrue);
      expect(turn.boundary.learningAllowed, isTrue);
      expect(turn.boundary.disposition, BoundaryDisposition.storeSanitized);
      expect(
        turn.boundary.reasonCodes,
        contains('accepted_for_governance_learning'),
      );
    });

    test(
      'writes grounded vibe evidence into the canonical vibe kernel',
      () async {
        const actorAgentId = 'agt_vibe_kernel_language_test';
        final before = vibeKernel.getUserSnapshot(actorAgentId);

        final turn = await service.processHumanText(
          actorAgentId: actorAgentId,
          rawText: 'I like quieter coffee shops and slower mornings.',
          consentScopes: const <String>{'user_runtime_learning'},
        );

        final after = vibeKernel.getUserSnapshot(actorAgentId);

        expect(turn.boundary.vibeMutationDecision.stateWriteAllowed, isTrue);
        expect(turn.interpretation.vibeEvidence.identitySignals, isNotEmpty);
        expect(
          after.coreDna.dimensions['energy_preference']!,
          lessThan(before.coreDna.dimensions['energy_preference']!),
        );
        expect(
          after.coreDna.dimensionConfidence['energy_preference']!,
          greaterThan(before.coreDna.dimensionConfidence['energy_preference']!),
        );
      },
    );

    test('renders grounded output through expression kernel', () {
      final rendered = service.renderGroundedOutput(
        speechAct: ExpressionSpeechAct.explain,
        audience: ExpressionAudience.userSafe,
        surfaceShape: ExpressionSurfaceShape.card,
        subjectLabel: 'Daily Drop',
        allowedClaims: const <String>[
          'AVRAI surfaced this because it matches your quieter evening pattern.',
        ],
        evidenceRefs: const <String>['why:quiet_evenings'],
      );

      expect(rendered.text, contains('Daily Drop'));
      expect(rendered.assertedClaims, isNotEmpty);
    });
  });
}
