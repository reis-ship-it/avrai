import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/swarm_prior_loader.dart';

void main() {
  group('SwarmPriorLoader BHAM priors', () {
    test('returns Birmingham-specific priors for Birmingham aliases', () {
      final loader = SwarmPriorLoader();

      final birmingham = loader.getPriorForCity('Birmingham');
      final alias = loader.getPriorForCity('bham');
      final defaultPrior = loader.getPriorForCity('unknown');

      expect(
        birmingham[UserEngagementPhase.onboarding]
            ?[UserEngagementPhase.connecting],
        16,
      );
      expect(
        alias[UserEngagementPhase.embedding]?[UserEngagementPhase.embedding],
        77,
      );
      expect(
        birmingham[UserEngagementPhase.onboarding]
            ?[UserEngagementPhase.connecting],
        isNot(
          defaultPrior[UserEngagementPhase.onboarding]
              ?[UserEngagementPhase.connecting],
        ),
      );
    });
  });
}
