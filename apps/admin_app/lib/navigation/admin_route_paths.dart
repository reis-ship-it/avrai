class AdminRoutePaths {
  static const String login = '/login';
  static const String commandCenter = '/admin/command-center';
  static const String governanceAudit = '/admin/governance-audit';
  static const String urkKernels = '/admin/urk-kernels';
  static const String ai2ai = '/admin/ai2ai';
  static const String communications = '/admin/communications';
  static const String moderation = '/admin/moderation';
  static const String explorer = '/admin/explorer';
  static const String betaFeedback = '/admin/beta-feedback';
  static const String launchSafety = '/admin/launch-safety';
  static const String securityImmuneSystem = '/admin/security-immune-system';
  static const String signatureHealth = '/admin/signature-health';
  static const String researchCenter = '/admin/research-center';
  static const String worldModel = '/admin/world-model';
  static const String realitySystemReality = '/admin/reality-system/reality';
  static const String realitySystemUniverse = '/admin/reality-system/universe';
  static const String realitySystemWorld = '/admin/reality-system/world';

  static String urkKernelsDecisionLink(String decisionId) =>
      '$urkKernels?decisionId=$decisionId';

  static String governanceAuditRuntimeLink({
    required String runtimeId,
    String? stratum,
    String? artifactType,
  }) {
    final params = <String>[
      'runtimeId=${Uri.encodeQueryComponent(runtimeId)}',
      if (stratum != null && stratum.isNotEmpty)
        'stratum=${Uri.encodeQueryComponent(stratum)}',
      if (artifactType != null && artifactType.isNotEmpty)
        'artifact=${Uri.encodeQueryComponent(artifactType)}',
    ];
    return '$governanceAudit?${params.join('&')}';
  }

  static String communicationDetail(String connectionId) =>
      '/admin/communication/${Uri.encodeComponent(connectionId)}';

  static String userDetail(String userId) =>
      '/admin/user/${Uri.encodeComponent(userId)}';

  static String clubDetail(String clubId) =>
      '/admin/club/${Uri.encodeComponent(clubId)}';
}
