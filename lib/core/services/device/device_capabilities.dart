/// Device capability snapshot used to gate heavy on-device AI features.
///
/// This is intentionally small and platform-agnostic so it can be:
/// - shown in Settings UI
/// - used by scheduling/gating policies
/// - unit-tested via fakes
class DeviceCapabilities {
  final String platform; // "android" | "ios" | "web" | "unknown"
  final String deviceModel;
  final int? osVersion; // Android SDK int, iOS major, etc.

  final int? totalRamMb;
  final int? freeDiskMb;
  final int? totalDiskMb;
  final int cpuCores;
  final bool isLowPowerMode;

  const DeviceCapabilities({
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.totalRamMb,
    required this.freeDiskMb,
    required this.totalDiskMb,
    required this.cpuCores,
    required this.isLowPowerMode,
  });

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v is num ? v.toInt() : null;
    bool asBool(dynamic v) => v == true;

    return DeviceCapabilities(
      platform: (json['platform'] as String?) ?? 'unknown',
      deviceModel: (json['deviceModel'] as String?) ?? '',
      osVersion: asInt(json['osVersion']),
      totalRamMb: asInt(json['totalRamMb']),
      freeDiskMb: asInt(json['freeDiskMb']),
      totalDiskMb: asInt(json['totalDiskMb']),
      cpuCores: asInt(json['cpuCores']) ?? 0,
      isLowPowerMode: asBool(json['isLowPowerMode']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'platform': platform,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'totalRamMb': totalRamMb,
        'freeDiskMb': freeDiskMb,
        'totalDiskMb': totalDiskMb,
        'cpuCores': cpuCores,
        'isLowPowerMode': isLowPowerMode,
      };
}

