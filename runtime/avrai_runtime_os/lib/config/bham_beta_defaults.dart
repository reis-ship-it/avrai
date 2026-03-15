import 'package:avrai_runtime_os/services/device/device_capabilities.dart';

class BhamBetaStorageBudgets {
  final int onboardingPayloadBytes;
  final int bootstrapSnapshotBytes;
  final int firstDropPayloadBytes;
  final int birminghamSeedAssetsBytes;

  const BhamBetaStorageBudgets({
    required this.onboardingPayloadBytes,
    required this.bootstrapSnapshotBytes,
    required this.firstDropPayloadBytes,
    required this.birminghamSeedAssetsBytes,
  });
}

class BhamBetaRelayDefaults {
  final Duration ttl;
  final int queueCap;
  final int trimTo;
  final int maxQueueBytes;
  final int quarantineAfterFailures;

  const BhamBetaRelayDefaults({
    required this.ttl,
    required this.queueCap,
    required this.trimTo,
    required this.maxQueueBytes,
    required this.quarantineAfterFailures,
  });
}

class BhamNotificationDefaults {
  final int cappedSuggestionsPerDay;
  final int quietHoursStartHour;
  final int quietHoursEndHour;

  const BhamNotificationDefaults({
    required this.cappedSuggestionsPerDay,
    required this.quietHoursStartHour,
    required this.quietHoursEndHour,
  });
}

class BhamChatRetentionDefaults {
  final Duration personalAi;
  final Duration admin;
  final Duration directMatched;
  final Duration group;

  const BhamChatRetentionDefaults({
    required this.personalAi,
    required this.admin,
    required this.directMatched,
    required this.group,
  });
}

class BhamApprovedDeviceEvaluation {
  final bool approved;
  final List<String> reasons;

  const BhamApprovedDeviceEvaluation({
    required this.approved,
    required this.reasons,
  });
}

class BhamBetaDefaults {
  static const String betaProgram = 'bham_beta';
  static const String firstSliceId = 'bham_first_user_slice';
  static const String questionnaireVersion = 'bham_questionnaire_v1';
  static const String betaConsentVersion = 'bham_beta_consent_v1';
  static const String minimumUsablePermissionsVersion = 'bham_permissions_v1';
  static const String defaultHomebase = 'Birmingham, Alabama';
  static const bool enablePartnershipSurfaces = bool.fromEnvironment(
    'ENABLE_BHAM_PARTNERSHIP_SURFACES',
    defaultValue: false,
  );
  static const String partnershipSurfacesDeferReason =
      'Partnership proposal, management, and profile surfaces stay disconnected during the Birmingham beta launch.';
  static const bool enableBusinessAccountSurfaces = bool.fromEnvironment(
    'ENABLE_BHAM_BUSINESS_ACCOUNT_SURFACES',
    defaultValue: false,
  );
  static const String businessAccountSurfacesDeferReason =
      'Business account signup, login, dashboard, and analytics surfaces stay disconnected during the Birmingham beta launch.';
  static const bool enableEventPlanningAssist = bool.fromEnvironment(
    'ENABLE_BHAM_EVENT_PLANNING_ASSIST',
    defaultValue: true,
  );
  static const String eventPlanningAssistReason =
      'Event truth stays inside the app, but all planning inputs must cross the air gap before persistence or learning.';

  static const List<String> mandatoryQuestionKeys = <String>[
    'more_of',
    'less_of',
    'values',
    'interests',
    'fun',
    'favorite_places',
    'goals',
    'transportation',
    'spending',
    'social_energy',
    'bio',
  ];

  static const BhamBetaRelayDefaults relay = BhamBetaRelayDefaults(
    ttl: Duration(hours: 24),
    queueCap: 256,
    trimTo: 200,
    maxQueueBytes: 16 * 1024 * 1024,
    quarantineAfterFailures: 5,
  );

  static const BhamNotificationDefaults notificationDefaults =
      BhamNotificationDefaults(
    cappedSuggestionsPerDay: 3,
    quietHoursStartHour: 22,
    quietHoursEndHour: 6,
  );

  static const BhamChatRetentionDefaults chatRetention =
      BhamChatRetentionDefaults(
    personalAi: Duration(days: 28),
    admin: Duration(days: 14),
    directMatched: Duration(days: 28),
    group: Duration(days: 28),
  );

  static const BhamBetaStorageBudgets storageBudgets = BhamBetaStorageBudgets(
    onboardingPayloadBytes: 96 * 1024,
    bootstrapSnapshotBytes: 256 * 1024,
    firstDropPayloadBytes: 64 * 1024,
    birminghamSeedAssetsBytes: 8 * 1024 * 1024,
  );

  static const Map<String, Object> deferredDefaults = <String, Object>{
    'admin_auth_audit': 'explicit_default_locked_for_wave_2',
    'contradiction_weighting': 'explicit_default_locked_for_wave_2',
    'launch_metrics': 'explicit_default_locked_for_wave_3',
  };

  static BhamApprovedDeviceEvaluation evaluateApprovedDevice(
    DeviceCapabilities caps,
  ) {
    final reasons = <String>[];
    final platform = caps.platform.toLowerCase();
    final supportedPlatform =
        platform == 'ios' || platform == 'android' || platform == 'macos';

    if (!supportedPlatform) {
      reasons.add(
        'The Birmingham beta is only approved on iOS, Android, and macOS for the first slice.',
      );
    }

    if (platform == 'ios' && caps.osVersion != null && caps.osVersion! < 16) {
      reasons.add('iOS 16 or newer is required for the Birmingham beta.');
    }
    if (platform == 'android' &&
        caps.osVersion != null &&
        caps.osVersion! < 29) {
      reasons.add(
        'Android 10 (API 29) or newer is required for the Birmingham beta.',
      );
    }

    if (caps.totalRamMb != null && caps.totalRamMb! < 4 * 1024) {
      reasons.add('At least 4GB RAM is required for the Birmingham beta.');
    }
    if (caps.freeDiskMb != null && caps.freeDiskMb! < 2 * 1024) {
      reasons.add(
        'At least 2GB of free storage is required for the Birmingham beta.',
      );
    }
    if (caps.cpuCores > 0 && caps.cpuCores < 4) {
      reasons.add(
        'At least 4 CPU cores are required for the Birmingham beta first slice.',
      );
    }
    if (caps.isLowPowerMode) {
      reasons.add(
        'Disable Low Power Mode before joining the Birmingham beta.',
      );
    }

    return BhamApprovedDeviceEvaluation(
      approved: supportedPlatform && reasons.isEmpty,
      reasons: reasons,
    );
  }
}
