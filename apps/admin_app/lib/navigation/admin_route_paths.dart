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
  static const String kernelGraphRunDetailPattern =
      '/admin/kernel-graph-run/:id';
  static const String researchCenter = '/admin/research-center';
  static const String worldModel = '/admin/world-model';
  static const String worldSimulationLab = '/admin/world-simulation-lab';
  static const String realitySystemReality = '/admin/reality-system/reality';
  static const String realitySystemUniverse = '/admin/reality-system/universe';
  static const String realitySystemWorld = '/admin/reality-system/world';

  static String urkKernelsDecisionLink(String decisionId) =>
      _withQuery(urkKernels, <String, String?>{'decisionId': decisionId});

  static String urkKernelsFocusLink({
    String? decisionId,
    String? view,
    String? focus,
    String? attention,
  }) =>
      _withQuery(urkKernels, <String, String?>{
        'decisionId': decisionId,
        'view': view,
        'focus': focus,
        'attention': attention,
      });

  static String ai2AiFocusLink({String? focus, String? attention}) =>
      _withQuery(ai2ai, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String signatureHealthFocusLink({
    String? focus,
    String? attention,
  }) =>
      _withQuery(signatureHealth, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String launchSafetyFocusLink({String? focus, String? attention}) =>
      _withQuery(launchSafety, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String researchCenterFocusLink({String? focus, String? attention}) =>
      _withQuery(researchCenter, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String worldSimulationLabFocusLink({
    String? focus,
    String? attention,
  }) =>
      _withQuery(worldSimulationLab, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String realitySystemRealityFocusLink({
    String? focus,
    String? attention,
  }) =>
      _withQuery(realitySystemReality, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String realitySystemUniverseFocusLink({
    String? focus,
    String? attention,
  }) =>
      _withQuery(realitySystemUniverse, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

  static String realitySystemWorldFocusLink({
    String? focus,
    String? attention,
  }) =>
      _withQuery(realitySystemWorld, <String, String?>{
        'focus': focus,
        'attention': attention,
      });

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

  static String kernelGraphRunDetail(String runId) =>
      '/admin/kernel-graph-run/${Uri.encodeComponent(runId)}';

  static String _withQuery(String basePath, Map<String, String?> query) {
    final encoded = query.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value!)}',
        )
        .join('&');
    if (encoded.isEmpty) {
      return basePath;
    }
    return '$basePath?$encoded';
  }
}
