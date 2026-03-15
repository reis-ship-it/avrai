import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSource(String relativePath) {
  final candidates = <String>[
    relativePath,
    'runtime/avrai_runtime_os/$relativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  throw FileSystemException(
    'Cannot open source file. Tried ${candidates.join(', ')}',
    relativePath,
  );
}

Iterable<String> _importLines(String source) sync* {
  for (final line in source.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('import ')) {
      yield trimmed;
    }
  }
}

Iterable<File> _kernelFiles() sync* {
  final candidates = <String>[
    'lib/kernel',
    'runtime/avrai_runtime_os/lib/kernel',
  ];
  for (final candidate in candidates) {
    final root = Directory(candidate);
    if (root.existsSync()) {
      yield* root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      return;
    }
  }
  throw FileSystemException(
    'Cannot open kernel directory. Tried ${candidates.join(', ')}',
  );
}

Iterable<File> _runtimeFiles() sync* {
  final candidates = <String>[
    'lib',
    'runtime/avrai_runtime_os/lib',
  ];
  for (final candidate in candidates) {
    final root = Directory(candidate);
    if (root.existsSync()) {
      yield* root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      return;
    }
  }
  throw FileSystemException(
    'Cannot open runtime lib directory. Tried ${candidates.join(', ')}',
  );
}

void main() {
  group('Kernel truth authority guardrails', () {
    test('no truth-owning chat kernel exists', () {
      for (final file in _kernelFiles()) {
        final source = file.readAsStringSync();
        expect(source.contains('class ChatKernel'), isFalse,
            reason: 'Unexpected ChatKernel in ${file.path}');
        expect(source.contains('abstract class ChatKernel'), isFalse,
            reason: 'Unexpected abstract ChatKernel in ${file.path}');
      }
    });

    test('human chat surfaces do not import legacy AI2AI protocols', () {
      final friendSource = _readSource(
        'lib/services/chat/friend_chat_service.dart',
      );
      final communitySource = _readSource(
        'lib/services/community/community_chat_service.dart',
      );
      final businessExpertSource = _readSource(
        'lib/services/business/business_expert_chat_service_ai2ai.dart',
      );
      final businessBusinessSource = _readSource(
        'lib/services/business/business_business_chat_service_ai2ai.dart',
      );
      final personalitySource = _readSource(
        'lib/services/user/personality_agent_chat_service.dart',
      );
      final outreachSource = _readSource(
        'lib/services/predictive_outreach/ai2ai_outreach_communication_service.dart',
      );
      final callingSource = _readSource(
        'lib/services/quantum/real_time_user_calling_service.dart',
      );
      final thirdPartyPrivacySource = _readSource(
        'lib/services/quantum/third_party_data_privacy_service.dart',
      );

      for (final source in <String>[
        friendSource,
        communitySource,
        businessExpertSource,
        businessBusinessSource,
        personalitySource,
        outreachSource,
        callingSource,
        thirdPartyPrivacySource,
      ]) {
        expect(source, isNot(contains('AnonymousCommunicationProtocol')));
        expect(source, isNot(contains('AI2AIProtocol')));
      }
    });

    test(
        'only private legacy adapters import legacy protocol classes in runtime',
        () {
      for (final file in _runtimeFiles()) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (!normalizedPath.contains('runtime/avrai_runtime_os/lib/') &&
            !normalizedPath.startsWith('lib/')) {
          continue;
        }
        if (normalizedPath.contains('/test/') ||
            normalizedPath.contains('runtime/avrai_runtime_os/test/')) {
          continue;
        }
        if (normalizedPath.contains('/services/transport/legacy/') ||
            normalizedPath.contains('services/transport/legacy/')) {
          continue;
        }

        final source = file.readAsStringSync();
        final importLines = _importLines(source).toList();
        expect(
          importLines,
          isNot(contains('anonymous_communication.dart')),
          reason: 'Legacy anonymous transport leaked into ${file.path}',
        );
        expect(
          importLines.where((line) => line.contains('ai2ai_protocol.dart')),
          isEmpty,
          reason: 'Legacy AI2AI protocol import leaked into ${file.path}',
        );
      }
    });

    test('app and admin root DI do not expose legacy anonymous transport', () {
      final appRootSource = _readSource(
        '../../apps/avrai_app/lib/injection_container.dart',
      );
      final adminRootSource = _readSource(
        '../../apps/admin_app/lib/injection_container.dart',
      );
      final appServiceRegistrar = _readSource(
        '../../apps/avrai_app/lib/di/registrars/app_service_registrar.dart',
      );
      final adminServiceRegistrar = _readSource(
        '../../apps/admin_app/lib/di/registrars/app_service_registrar.dart',
      );
      final appQuantumRegistrar = _readSource(
        '../../apps/avrai_app/lib/di/registrars/injection_container_quantum.dart',
      );
      final adminQuantumRegistrar = _readSource(
        '../../apps/admin_app/lib/di/registrars/injection_container_quantum.dart',
      );

      expect(appRootSource, isNot(contains('ai2aiProtocol:')));
      expect(adminRootSource, isNot(contains('ai2aiProtocol:')));
      expect(appServiceRegistrar, isNot(contains('ai2aiProtocol:')));
      expect(adminServiceRegistrar, isNot(contains('ai2aiProtocol:')));
      expect(appQuantumRegistrar, isNot(contains('ai2aiProtocol:')));
      expect(adminQuantumRegistrar, isNot(contains('ai2aiProtocol:')));
    });

    test(
        'AI2AI chat intake uses exchange APIs and does not synthesize receipts',
        () {
      final source = _readSource(
        'lib/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart',
      );

      expect(source, contains('planExchange('));
      expect(source, contains('commitExchange('));
      expect(source, contains('observeExchange('));
      expect(source, isNot(contains('TransportRouteReceipt(')));
    });

    test(
        'ambient social learning uses named what and vibe ingress paths instead of direct kernel writes',
        () {
      final source = _readSource(
        'lib/services/passive_collection/passive_dwell_reality_learning_service.dart',
      );

      expect(source, contains('WhatRuntimeIngestionService'));
      expect(source, contains('ingestAmbientSocialObservation('));
      expect(source, contains('HierarchicalLocalityVibeProjector'));
      expect(source, contains('ingestEcosystemObservation('));
      expect(source, isNot(contains('WhatKernelContract')));
      expect(source, isNot(contains('observeWhat(')));
    });

    test(
        'ambient social runtime seams stay behind explicit ingestion services instead of direct what kernel writes',
        () {
      final passiveLearningSource = _readSource(
        'lib/services/passive_collection/passive_dwell_reality_learning_service.dart',
      );
      final dwellAdapterSource = _readSource(
        'lib/services/passive_collection/dwell_event_intake_adapter.dart',
      );
      final peerOutcomeSource = _readSource(
        'lib/ai2ai/peer_interaction_outcome_learning_service.dart',
      );

      expect(passiveLearningSource, contains('WhatRuntimeIngestionService'));
      expect(dwellAdapterSource, contains('WhatRuntimeIngestionService'));
      expect(peerOutcomeSource, contains('AmbientSocialRealityLearningService'));
      expect(passiveLearningSource, isNot(contains('WhatKernelContract')));
      expect(dwellAdapterSource, isNot(contains('WhatKernelContract')));
      expect(peerOutcomeSource, isNot(contains('WhatKernelContract')));
      expect(passiveLearningSource, isNot(contains('observeWhat(')));
      expect(dwellAdapterSource, isNot(contains('observeWhat(')));
      expect(peerOutcomeSource, isNot(contains('observeWhat(')));
    });

    test(
        'AI2AI runtime seams keep exchange truth behind the kernel contract or submission seam',
        () {
      final submissionLane = _readSource(
        'lib/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart',
      );
      final intakeSource = _readSource(
        'lib/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart',
      );
      final rendezvousSource = _readSource(
        'lib/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart',
      );

      expect(submissionLane, contains('Ai2AiKernelContract'));
      expect(submissionLane, contains('planExchange('));
      expect(submissionLane, contains('commitExchange('));
      expect(submissionLane, contains('observeExchange('));
      expect(intakeSource, contains('Ai2AiKernelContract'));
      expect(intakeSource, contains('observeExchange('));
      expect(rendezvousSource, contains('Ai2AiExchangeSubmissionLane'));
      expect(rendezvousSource, isNot(contains('Ai2AiKernelContract')));
      expect(rendezvousSource, isNot(contains('Ai2AiExchangeObservation(')));
    });

    test(
        'mesh runtime seams keep replay and governed forwarding on the approved transport path',
        () {
      final backgroundSource = _readSource(
        'lib/services/background/mesh_background_execution_lane.dart',
      );
      final governanceSource = _readSource(
        'lib/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart',
      );
      final replaySource = _readSource(
        'lib/services/transport/mesh/mesh_custody_replay_lane.dart',
      );

      expect(backgroundSource, contains('MeshCustodyReplayLane.replayDueEntries'));
      expect(backgroundSource, contains('MeshCustodyReplayLane.replayForRecoveredReachability'));
      expect(backgroundSource, isNot(contains('TransportRouteReceipt(')));
      expect(governanceSource, contains('planTransport('));
      expect(governanceSource, contains('observeTransport('));
      expect(replaySource, contains('MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan('));
      expect(replaySource, contains('MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome('));
      expect(replaySource, isNot(contains('TransportRouteReceipt(')));
    });

    test('conversation and exchange seams do not resolve transport via GetIt',
        () {
      final conversationLane = _readSource(
        'lib/services/chat/conversation_orchestration_lane.dart',
      );
      final exchangeLane = _readSource(
        'lib/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart',
      );

      expect(conversationLane, isNot(contains('GetIt')));
      expect(exchangeLane, isNot(contains('GetIt')));
    });

    test('connection orchestrator no longer owns a direct protocol field', () {
      final source = _readSource(
        'lib/ai2ai/connection_orchestrator.dart',
      );

      expect(source, isNot(contains('final AI2AIProtocol')));
      expect(source, isNot(contains('AI2AIProtocol? _protocol')));
      expect(source, isNot(contains('AI2AIProtocol _protocol')));
    });

    test(
        'canonical transport and exchange receipts are only constructed by approved authorities',
        () {
      for (final file in _runtimeFiles()) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (!normalizedPath.contains('runtime/avrai_runtime_os/lib/') &&
            !normalizedPath.startsWith('lib/')) {
          continue;
        }
        if (normalizedPath.contains('/test/') ||
            normalizedPath.contains('runtime/avrai_runtime_os/test/')) {
          continue;
        }

        final mayConstructTransportReceipt = normalizedPath
                .startsWith('lib/kernel/') ||
            normalizedPath.contains('/lib/kernel/') ||
            normalizedPath.contains('runtime/avrai_runtime_os/lib/kernel/') ||
            normalizedPath.contains(
                '/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart');
        final mayConstructExchangeReceipt =
            normalizedPath.startsWith('lib/kernel/ai2ai/') ||
                normalizedPath.contains('/lib/kernel/ai2ai/') ||
                normalizedPath
                    .contains('runtime/avrai_runtime_os/lib/kernel/ai2ai/');

        final source = file.readAsStringSync();
        if (!mayConstructTransportReceipt) {
          expect(
            source,
            isNot(contains('TransportRouteReceipt(')),
            reason:
                'TransportRouteReceipt construction leaked into ${file.path}',
          );
        }
        if (!mayConstructExchangeReceipt) {
          expect(
            source,
            isNot(contains('Ai2AiExchangeReceipt(')),
            reason:
                'Ai2AiExchangeReceipt construction leaked into ${file.path}',
          );
        }
      }
    });
  });
}
