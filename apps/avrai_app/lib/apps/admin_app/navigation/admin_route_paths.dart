class AdminRoutePaths {
  static const String login = '/login';
  static const String commandCenter = '/admin/command-center';
  static const String urkKernels = '/admin/urk-kernels';
  static const String ai2ai = '/admin/ai2ai';
  static const String signatureHealth = '/admin/signature-health';
  static const String researchCenter = '/admin/research-center';
  static const String realitySystemReality = '/admin/reality-system/reality';
  static const String realitySystemUniverse = '/admin/reality-system/universe';
  static const String realitySystemWorld = '/admin/reality-system/world';

  static String urkKernelsDecisionLink(String decisionId) =>
      '$urkKernels?decisionId=$decisionId';
}
