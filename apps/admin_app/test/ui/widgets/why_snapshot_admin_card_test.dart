import 'package:avrai_admin_app/ui/widgets/why_snapshot_admin_card.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders why snapshot sections for admin inspection',
      (WidgetTester tester) async {
    const snapshot = WhySnapshot(
      goal: 'inspect_governance_decision',
      queryKind: WhyQueryKind.policyAction,
      primaryHypothesis: WhyHypothesis(
        id: 'primary',
        label: 'policy driven attribution',
        rootCauseType: WhyRootCauseType.policyDriven,
        confidence: 0.88,
      ),
      drivers: <WhySignal>[
        WhySignal(
          label: 'mode enforce',
          weight: 0.82,
          kernel: WhyEvidenceSourceKernel.policy,
        ),
      ],
      inhibitors: <WhySignal>[
        WhySignal(
          label: 'governance reason: missing_model_type',
          weight: 0.91,
          kernel: WhyEvidenceSourceKernel.policy,
        ),
      ],
      counterfactuals: <WhyCounterfactual>[
        WhyCounterfactual(
          condition: 'Reduce missing_model_type',
          expectedEffect: 'Outcome is more likely to improve',
          confidenceDelta: 0.24,
        ),
      ],
      confidence: 0.86,
      ambiguity: 0.31,
      rootCauseType: WhyRootCauseType.policyDriven,
      summary: 'modelSwitch produced blocked due to policy signals.',
      traceRefs: <WhyTraceRef>[
        WhyTraceRef(
          traceType: 'evidence',
          kernel: WhyEvidenceSourceKernel.policy,
          eventId: 'decision_1',
        ),
      ],
      conflicts: <WhyConflict>[
        WhyConflict(
          label: 'dominant_tension',
          message: 'mode enforce is opposed by missing model type.',
        ),
      ],
      governanceEnvelope: WhyGovernanceEnvelope(
        policyRefs: <String>['v-policy'],
        escalationThresholds: <String>['missing_model_type'],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WhySnapshotAdminCard(snapshot: snapshot),
          ),
        ),
      ),
    );

    expect(find.text('Why Explanation'), findsOneWidget);
    expect(find.text('Primary Hypothesis'), findsOneWidget);
    expect(find.text('Drivers'), findsOneWidget);
    expect(find.text('Inhibitors'), findsOneWidget);
    expect(find.text('Governance Envelope'), findsOneWidget);
    expect(find.textContaining('v-policy'), findsOneWidget);
    expect(find.textContaining('missing_model_type'), findsWidgets);
  });
}
