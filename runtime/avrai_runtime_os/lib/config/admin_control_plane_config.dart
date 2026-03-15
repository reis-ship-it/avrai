class AdminControlPlaneConfig {
  static const String url = String.fromEnvironment(
    'ADMIN_CONTROL_PLANE_URL',
    defaultValue: '',
  );

  static const int pollIntervalSeconds = int.fromEnvironment(
    'ADMIN_CONTROL_PLANE_POLL_INTERVAL_SECONDS',
    defaultValue: 5,
  );

  static bool get isConfigured => url.trim().isNotEmpty;
}
