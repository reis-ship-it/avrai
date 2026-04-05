import 'package:avrai_core/avra_core.dart';

class SecurityCampaignRegistry {
  const SecurityCampaignRegistry();

  List<SecurityCampaignDefinition> definitions() {
    return const <SecurityCampaignDefinition>[
      SecurityCampaignDefinition(
        id: 'rt-001-auth-session',
        laneId: 'RT-001',
        name: 'Auth Session Takeover',
        description:
            'Replay/rotation bypass simulation against session validation paths.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.world,
          sphereId: 'security_auth',
          familyId: 'auth_session_takeover',
        ),
        cadence: SecurityCampaignCadence.weekly,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.codeChange,
          SecurityCampaignTrigger.policyPromotion,
        ],
        environment: GovernedRunEnvironment.canary,
        releaseBlocking: true,
        ownerAlias: 'security_identity',
        ownershipArea: 'identity_and_session',
        pathPrefixes: <String>[
          'apps/admin_app/lib/ui/pages/auth/',
          'runtime/avrai_runtime_os/services/infrastructure/auth/',
          'runtime/avrai_runtime_os/services/security/',
        ],
        promotionSelectors: <String>[
          'auth',
          'session',
          'login',
        ],
        incidentTags: <String>[
          'auth',
          'session',
          'takeover',
        ],
        mappedScenarioIds: <String>[
          'directNearbyDeliveryWithReadReceipt',
          'deferredExchangePeerTruthAfterRelease',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.governanceBoundary,
          SecurityProofKind.transportConformance,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-002-backend-authorization',
        laneId: 'RT-002',
        name: 'Backend Authorization Fuzzing',
        description: 'Cross-tenant and privilege-escalation policy fuzzing.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.world,
          sphereId: 'security_backend',
          familyId: 'authorization_fuzzing',
        ),
        cadence: SecurityCampaignCadence.weekly,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.codeChange,
          SecurityCampaignTrigger.policyPromotion,
        ],
        environment: GovernedRunEnvironment.sandbox,
        releaseBlocking: true,
        ownerAlias: 'security_backend',
        ownershipArea: 'authorization_and_tenant_boundaries',
        pathPrefixes: <String>[
          'runtime/avrai_runtime_os/services/admin/',
          'runtime/avrai_runtime_os/services/business/',
          'runtime/avrai_runtime_os/services/infrastructure/oauth/',
        ],
        promotionSelectors: <String>[
          'authorization',
          'admin',
          'permission',
          'tenant',
        ],
        incidentTags: <String>[
          'authorization',
          'privilege',
          'tenant',
        ],
        mappedScenarioIds: <String>[
          'untrustedAnnounceRejected',
          'deferredRendezvousBlockedByTrustedRouteUnavailable',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.governanceBoundary,
          SecurityProofKind.announceTrust,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-003-secrets-ci',
        laneId: 'RT-003',
        name: 'Secrets and CI Compromise',
        description: 'Artifact provenance and credential replay validation.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.universal,
          sphereId: 'security_supply_chain',
          familyId: 'secrets_ci_compromise',
        ),
        cadence: SecurityCampaignCadence.releaseBlocking,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.codeChange,
          SecurityCampaignTrigger.policyPromotion,
        ],
        environment: GovernedRunEnvironment.shadow,
        releaseBlocking: true,
        ownerAlias: 'security_supply_chain',
        ownershipArea: 'artifact_and_secret_provenance',
        pathPrefixes: <String>[
          'work/scripts/',
          'work/supabase/',
          'runtime/avrai_network/native/',
        ],
        promotionSelectors: <String>[
          'ci',
          'secret',
          'provenance',
          'artifact',
        ],
        incidentTags: <String>[
          'ci',
          'secret',
          'supply_chain',
        ],
        mappedScenarioIds: <String>[
          'trustedRelayRefreshRoutable',
          'trustedHeardForwardRoutable',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.governanceBoundary,
          SecurityProofKind.rolloutLifecycle,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-004-federated-updates',
        laneId: 'RT-004',
        name: 'Federated Update Poisoning',
        description:
            'Adversarial update injection, replay, and learning-path hijack simulation.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.world,
          sphereId: 'security_learning',
          familyId: 'federated_update_poisoning',
        ),
        cadence: SecurityCampaignCadence.weekly,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.modelPromotion,
          SecurityCampaignTrigger.replayedIncident,
        ],
        environment: GovernedRunEnvironment.replay,
        releaseBlocking: true,
        ownerAlias: 'security_learning',
        ownershipArea: 'learning_and_model_integrity',
        pathPrefixes: <String>[
          'runtime/avrai_runtime_os/p2p/',
          'runtime/avrai_runtime_os/services/ai_infrastructure/',
          'runtime/avrai_runtime_os/services/prediction/',
        ],
        promotionSelectors: <String>[
          'learning',
          'federated',
          'model',
          'outcome',
          'calling_score',
        ],
        incidentTags: <String>[
          'federated',
          'poison',
          'learning',
        ],
        mappedScenarioIds: <String>[
          'learningAppliedAfterGovernedIntake',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.learningPath,
          SecurityProofKind.governanceBoundary,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-006-signal-lifecycle',
        laneId: 'RT-006',
        name: 'Signal Lifecycle Downgrade',
        description:
            'Downgrade and replay attempts on trust and announce paths.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.world,
          sphereId: 'security_transport',
          familyId: 'signal_lifecycle_downgrade',
        ),
        cadence: SecurityCampaignCadence.weekly,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.codeChange,
          SecurityCampaignTrigger.replayedIncident,
        ],
        environment: GovernedRunEnvironment.replay,
        releaseBlocking: true,
        ownerAlias: 'security_transport',
        ownershipArea: 'mesh_and_signal_lifecycle',
        pathPrefixes: <String>[
          'runtime/avrai_runtime_os/services/transport/mesh/',
          'runtime/avrai_network/',
        ],
        promotionSelectors: <String>[
          'mesh',
          'announce',
          'route',
          'signal',
        ],
        incidentTags: <String>[
          'announce',
          'mesh',
          'downgrade',
        ],
        mappedScenarioIds: <String>[
          'untrustedAnnounceRejected',
          'trustedDirectAnnounceRecovery',
          'trustedCloudAnnounceAccepted',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.announceTrust,
          SecurityProofKind.transportConformance,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-008-exports-reidentification',
        laneId: 'RT-008',
        name: 'Export Re-identification',
        description:
            'Aggregate-data joining and re-identification attack simulation.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.universal,
          sphereId: 'security_exports',
          familyId: 'reidentification_simulation',
        ),
        cadence: SecurityCampaignCadence.releaseBlocking,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.policyPromotion,
          SecurityCampaignTrigger.replayedIncident,
        ],
        environment: GovernedRunEnvironment.shadow,
        releaseBlocking: true,
        ownerAlias: 'security_exports',
        ownershipArea: 'export_privacy_and_buyer_contracts',
        pathPrefixes: <String>[
          'runtime/avrai_runtime_os/services/admin/export/',
          'runtime/avrai_runtime_os/services/admin/',
          'runtime/avrai_runtime_os/services/prediction/',
        ],
        promotionSelectors: <String>[
          'export',
          'insight',
          'outside_buyer',
          'aggregate',
        ],
        incidentTags: <String>[
          'export',
          'reidentification',
          'privacy',
        ],
        mappedScenarioIds: <String>[
          'ambientDuplicateEvidenceMerged',
          'ambientUntrustedInteractionNotPromoted',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.exportPrivacy,
          SecurityProofKind.ambientPromotion,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-009-autonomy-hijack',
        laneId: 'RT-009',
        name: 'Autonomy Lifecycle Hijack',
        description:
            'Bypass attempts against staged rollout and rollback governance.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.universal,
          sphereId: 'security_autonomy',
          familyId: 'autonomy_hijack',
        ),
        cadence: SecurityCampaignCadence.releaseBlocking,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.modelPromotion,
          SecurityCampaignTrigger.policyPromotion,
        ],
        environment: GovernedRunEnvironment.canary,
        releaseBlocking: true,
        ownerAlias: 'security_autonomy',
        ownershipArea: 'autonomy_rollout_and_runtime_governance',
        pathPrefixes: <String>[
          'runtime/avrai_runtime_os/services/ai_infrastructure/',
          'runtime/avrai_runtime_os/services/security/',
          'shared/avrai_core/lib/models/security/',
        ],
        promotionSelectors: <String>[
          'rollout',
          'promotion',
          'autonomy',
          'kernel',
        ],
        incidentTags: <String>[
          'autonomy',
          'rollout',
          'hijack',
        ],
        mappedScenarioIds: <String>[
          'deferredExchangePeerTruthAfterRelease',
          'learningAppliedAfterGovernedIntake',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.rolloutLifecycle,
          SecurityProofKind.learningPath,
        ],
      ),
      SecurityCampaignDefinition(
        id: 'rt-012-admin-operator',
        laneId: 'RT-012',
        name: 'Admin Operator Abuse',
        description: 'Privilege misuse and break-glass abuse drills.',
        truthScope: TruthScopeDescriptor.defaultSecurity(
          governanceStratum: GovernanceStratum.universal,
          sphereId: 'security_admin',
          familyId: 'admin_operator_abuse',
        ),
        cadence: SecurityCampaignCadence.weekly,
        triggers: <SecurityCampaignTrigger>[
          SecurityCampaignTrigger.schedule,
          SecurityCampaignTrigger.codeChange,
          SecurityCampaignTrigger.policyPromotion,
        ],
        environment: GovernedRunEnvironment.shadow,
        releaseBlocking: true,
        ownerAlias: 'security_admin',
        ownershipArea: 'operator_controls_and_break_glass',
        pathPrefixes: <String>[
          'apps/admin_app/lib/ui/pages/',
          'runtime/avrai_runtime_os/services/admin/',
          'runtime/avrai_runtime_os/kernel/service_contracts/',
        ],
        promotionSelectors: <String>[
          'admin',
          'break_glass',
          'governance',
          'operator',
        ],
        incidentTags: <String>[
          'admin',
          'operator',
          'break_glass',
        ],
        mappedScenarioIds: <String>[
          'deferredRendezvousBlockedByTrustedRouteUnavailable',
          'untrustedAnnounceRejected',
        ],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.adminAbuse,
          SecurityProofKind.governanceBoundary,
        ],
      ),
    ];
  }

  SecurityCampaignDefinition? definitionById(String id) {
    for (final definition in definitions()) {
      if (definition.id == id || definition.laneId == id) {
        return definition;
      }
    }
    return null;
  }

  List<SecurityCampaignDefinition> releaseBlockingDefinitions() {
    return definitions()
        .where((entry) => entry.releaseBlocking)
        .toList(growable: false);
  }
}
