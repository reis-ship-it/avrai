import 'package:avrai_runtime_os/services/onboarding/initial_dna_synthesis_service.dart';
import 'package:avrai_runtime_os/services/user/aspirational_intent_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../support/fake_language_kernels.dart';

void main() {
  group('Kernel language dimension pipeline', () {
    test('synthesizes initial DNA from sanitized onboarding language',
        () async {
      final vibeKernel = VibeKernel();
      final service = InitialDNASynthesisService(
        languageKernelOrchestrator: buildDeterministicLanguageKernelOrchestrator(
          vibeKernel: vibeKernel,
        ),
        vibeKernel: vibeKernel,
      );

      const actorAgentId = 'agt_test_onboarding';
      final result = await service.synthesizeInitialDNA(
        <String, String>{
          'favorite_places':
              'I love quiet local coffee shops, hidden gems, and relaxed mornings with friends.',
          'goals':
              'I like exploring new neighborhoods and trying different places.',
        },
        actorAgentId: actorAgentId,
      );

      expect(
        result.baselineDimensions['authenticity_preference'],
        greaterThan(0.55),
      );
      expect(result.baselineDimensions['crowd_tolerance'], lessThan(0.5));
      expect(
        result.baselineDimensions['exploration_eagerness'],
        greaterThan(0.55),
      );
      expect(
        result.baselineDimensions['community_orientation'],
        greaterThan(0.5),
      );
      expect(result.mutationReceipts, isNotEmpty);
      expect(result.whySnapshot.queryKind.name, equals('modelUpdate'));
      expect(result.whySnapshot.drivers, isNotEmpty);
      expect(
        VibeKernel()
            .getUserSnapshot(actorAgentId)
            .coreDna
            .dimensions['energy_preference'],
        lessThan(0.5),
      );
    });

    test('parses aspirational shifts through the language kernel', () async {
      final parser = AspirationalIntentParser(
        languageKernelOrchestrator: buildDeterministicLanguageKernelOrchestrator(
          vibeKernel: VibeKernel(),
        ),
      );

      final shifts = await parser.parseIntent(
        'I want to be more adventurous and social. I want quieter, less crowded places and a more chill pace.',
        actorAgentId: 'agt_test_user',
      );

      expect(shifts['exploration_eagerness'], greaterThan(0.0));
      expect(shifts['community_orientation'], greaterThan(0.0));
      expect(shifts['crowd_tolerance'], lessThan(0.0));
      expect(shifts['energy_preference'], lessThan(0.0));
    });
  });
}
