import 'dart:math' as math;

import 'package:avrai_network/avra_network.dart';

enum MeshInterfaceKind {
  ble,
  wifiDirect,
  webrtc,
  websocket,
  federatedCloud,
  unknown,
}

enum MeshInterfaceReachabilityScope { local, regional, global }

enum MeshInterfaceCostClass { low, medium, high }

enum MeshInterfaceEnergyCostClass { low, medium, high }

enum MeshInterfaceTrustClass { localTrusted, federatedTrusted, untrusted }

class MeshTransportPrivacyMode {
  const MeshTransportPrivacyMode._();

  static const String localSovereign = 'local_sovereign';
  static const String privateMesh = 'private_mesh';
  static const String federatedCloud = 'federated_cloud';
  static const String multiMode = 'multi_mode';

  static String normalize(String? rawValue) {
    switch (rawValue) {
      case localSovereign:
      case 'localSovereign':
      case 'local':
        return localSovereign;
      case federatedCloud:
      case 'federatedCloud':
      case 'federated':
        return federatedCloud;
      case multiMode:
      case 'multiMode':
        return multiMode;
      case privateMesh:
      case 'privateMesh':
      case 'private':
      default:
        return privateMesh;
    }
  }
}

class MeshInterfaceProfile {
  const MeshInterfaceProfile({
    required this.interfaceId,
    required this.kind,
    required this.enabled,
    required this.supportsDiscovery,
    required this.supportsCustody,
    required this.reachabilityScope,
    required this.costClass,
    required this.energyCostClass,
    required this.trustClass,
    required this.allowedPrivacyModes,
    required this.defaultAnnounceTtl,
    required this.maxHopCount,
  });

  final String interfaceId;
  final MeshInterfaceKind kind;
  final bool enabled;
  final bool supportsDiscovery;
  final bool supportsCustody;
  final MeshInterfaceReachabilityScope reachabilityScope;
  final MeshInterfaceCostClass costClass;
  final MeshInterfaceEnergyCostClass energyCostClass;
  final MeshInterfaceTrustClass trustClass;
  final Set<String> allowedPrivacyModes;
  final Duration defaultAnnounceTtl;
  final int maxHopCount;

  bool allowsPrivacyMode(String privacyMode) {
    final normalized = MeshTransportPrivacyMode.normalize(privacyMode);
    if (!enabled) {
      return false;
    }
    if (normalized == MeshTransportPrivacyMode.multiMode) {
      return allowedPrivacyModes.isNotEmpty;
    }
    return allowedPrivacyModes.contains(normalized);
  }

  double get policyScore {
    final costScore = switch (costClass) {
      MeshInterfaceCostClass.low => 1.0,
      MeshInterfaceCostClass.medium => 0.8,
      MeshInterfaceCostClass.high => 0.6,
    };
    final energyScore = switch (energyCostClass) {
      MeshInterfaceEnergyCostClass.low => 1.0,
      MeshInterfaceEnergyCostClass.medium => 0.82,
      MeshInterfaceEnergyCostClass.high => 0.64,
    };
    final trustScore = switch (trustClass) {
      MeshInterfaceTrustClass.localTrusted => 1.0,
      MeshInterfaceTrustClass.federatedTrusted => 0.88,
      MeshInterfaceTrustClass.untrusted => 0.42,
    };
    return ((costScore * 0.34) + (energyScore * 0.22) + (trustScore * 0.44))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'interface_id': interfaceId,
        'kind': kind.name,
        'enabled': enabled,
        'supports_discovery': supportsDiscovery,
        'supports_custody': supportsCustody,
        'reachability_scope': reachabilityScope.name,
        'cost_class': costClass.name,
        'energy_cost_class': energyCostClass.name,
        'trust_class': trustClass.name,
        'allowed_privacy_modes': allowedPrivacyModes.toList()..sort(),
        'default_announce_ttl_ms': defaultAnnounceTtl.inMilliseconds,
        'max_hop_count': maxHopCount,
      };
}

class MeshInterfaceRegistry {
  MeshInterfaceRegistry({
    this.cloudInterfaceAvailable = false,
  });

  final bool cloudInterfaceAvailable;

  MeshInterfaceProfile resolveForDevice(
    DiscoveredDevice? device, {
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
  }) {
    final kind = _kindForDevice(device);
    return _profileForKind(kind, privacyMode: privacyMode);
  }

  MeshInterfaceProfile resolveByInterfaceId(
    String interfaceId, {
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
  }) {
    final normalizedId = interfaceId.trim().toLowerCase();
    final kind = switch (normalizedId) {
      'ble' => MeshInterfaceKind.ble,
      'wifi_direct' => MeshInterfaceKind.wifiDirect,
      'webrtc' => MeshInterfaceKind.webrtc,
      'websocket' => MeshInterfaceKind.websocket,
      'federated_cloud' => MeshInterfaceKind.federatedCloud,
      _ => MeshInterfaceKind.unknown,
    };
    return _profileForKind(kind, privacyMode: privacyMode);
  }

  List<MeshInterfaceProfile> allProfiles({
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
  }) {
    return MeshInterfaceKind.values
        .map((kind) => _profileForKind(kind, privacyMode: privacyMode))
        .toList()
      ..sort((left, right) => left.interfaceId.compareTo(right.interfaceId));
  }

  MeshInterfaceProfile cloudProfile({
    String privacyMode = MeshTransportPrivacyMode.federatedCloud,
  }) {
    return _profileForKind(
      MeshInterfaceKind.federatedCloud,
      privacyMode: privacyMode,
    );
  }

  String interfaceIdForDevice(DiscoveredDevice? device) =>
      _kindForDevice(device).name == 'wifiDirect'
          ? 'wifi_direct'
          : _kindForDevice(device).name;

  MeshInterfaceKind _kindForDevice(DiscoveredDevice? device) {
    if (device == null) {
      return MeshInterfaceKind.unknown;
    }

    final transport = device.metadata['scan_transport']?.toString().trim();
    final normalizedTransport = transport?.toLowerCase();
    switch (normalizedTransport) {
      case 'ble':
      case 'bluetooth':
        return MeshInterfaceKind.ble;
      case 'wifi_direct':
      case 'wifi-direct':
      case 'wifidirect':
      case 'multipeer':
      case 'multipeer_connectivity':
        return MeshInterfaceKind.wifiDirect;
      case 'webrtc':
        return MeshInterfaceKind.webrtc;
      case 'websocket':
      case 'ws':
      case 'wifi':
        return MeshInterfaceKind.websocket;
      case 'federated_cloud':
      case 'cloud':
        return MeshInterfaceKind.federatedCloud;
    }

    return switch (device.type) {
      DeviceType.bluetooth => MeshInterfaceKind.ble,
      DeviceType.wifiDirect => MeshInterfaceKind.wifiDirect,
      DeviceType.multpeerConnectivity => MeshInterfaceKind.wifiDirect,
      DeviceType.webrtc => MeshInterfaceKind.webrtc,
      DeviceType.wifi => MeshInterfaceKind.websocket,
    };
  }

  MeshInterfaceProfile _profileForKind(
    MeshInterfaceKind kind, {
    required String privacyMode,
  }) {
    final normalizedMode = MeshTransportPrivacyMode.normalize(privacyMode);
    final profile = switch (kind) {
      MeshInterfaceKind.ble => MeshInterfaceProfile(
          interfaceId: 'ble',
          kind: kind,
          enabled: true,
          supportsDiscovery: true,
          supportsCustody: true,
          reachabilityScope: MeshInterfaceReachabilityScope.local,
          costClass: MeshInterfaceCostClass.low,
          energyCostClass: MeshInterfaceEnergyCostClass.medium,
          trustClass: MeshInterfaceTrustClass.localTrusted,
          allowedPrivacyModes: const <String>{
            MeshTransportPrivacyMode.privateMesh,
            MeshTransportPrivacyMode.federatedCloud,
            MeshTransportPrivacyMode.multiMode,
          },
          defaultAnnounceTtl: const Duration(minutes: 5),
          maxHopCount: 4,
        ),
      MeshInterfaceKind.wifiDirect => MeshInterfaceProfile(
          interfaceId: 'wifi_direct',
          kind: kind,
          enabled: true,
          supportsDiscovery: true,
          supportsCustody: true,
          reachabilityScope: MeshInterfaceReachabilityScope.local,
          costClass: MeshInterfaceCostClass.low,
          energyCostClass: MeshInterfaceEnergyCostClass.high,
          trustClass: MeshInterfaceTrustClass.localTrusted,
          allowedPrivacyModes: const <String>{
            MeshTransportPrivacyMode.privateMesh,
            MeshTransportPrivacyMode.federatedCloud,
            MeshTransportPrivacyMode.multiMode,
          },
          defaultAnnounceTtl: const Duration(minutes: 5),
          maxHopCount: 4,
        ),
      MeshInterfaceKind.webrtc => MeshInterfaceProfile(
          interfaceId: 'webrtc',
          kind: kind,
          enabled: normalizedMode != MeshTransportPrivacyMode.localSovereign,
          supportsDiscovery: false,
          supportsCustody: true,
          reachabilityScope: MeshInterfaceReachabilityScope.global,
          costClass: MeshInterfaceCostClass.medium,
          energyCostClass: MeshInterfaceEnergyCostClass.medium,
          trustClass: MeshInterfaceTrustClass.federatedTrusted,
          allowedPrivacyModes: const <String>{
            MeshTransportPrivacyMode.federatedCloud,
            MeshTransportPrivacyMode.multiMode,
          },
          defaultAnnounceTtl: const Duration(minutes: 15),
          maxHopCount: 8,
        ),
      MeshInterfaceKind.websocket => MeshInterfaceProfile(
          interfaceId: 'websocket',
          kind: kind,
          enabled: normalizedMode != MeshTransportPrivacyMode.localSovereign,
          supportsDiscovery: false,
          supportsCustody: true,
          reachabilityScope: MeshInterfaceReachabilityScope.global,
          costClass: MeshInterfaceCostClass.medium,
          energyCostClass: MeshInterfaceEnergyCostClass.low,
          trustClass: MeshInterfaceTrustClass.federatedTrusted,
          allowedPrivacyModes: const <String>{
            MeshTransportPrivacyMode.federatedCloud,
            MeshTransportPrivacyMode.multiMode,
          },
          defaultAnnounceTtl: const Duration(minutes: 15),
          maxHopCount: 8,
        ),
      MeshInterfaceKind.federatedCloud => MeshInterfaceProfile(
          interfaceId: 'federated_cloud',
          kind: kind,
          enabled: cloudInterfaceAvailable &&
              normalizedMode != MeshTransportPrivacyMode.localSovereign,
          supportsDiscovery: false,
          supportsCustody: true,
          reachabilityScope: MeshInterfaceReachabilityScope.global,
          costClass: MeshInterfaceCostClass.high,
          energyCostClass: MeshInterfaceEnergyCostClass.low,
          trustClass: MeshInterfaceTrustClass.federatedTrusted,
          allowedPrivacyModes: const <String>{
            MeshTransportPrivacyMode.federatedCloud,
            MeshTransportPrivacyMode.multiMode,
          },
          defaultAnnounceTtl: const Duration(minutes: 15),
          maxHopCount: 12,
        ),
      MeshInterfaceKind.unknown => const MeshInterfaceProfile(
          interfaceId: 'unknown',
          kind: MeshInterfaceKind.unknown,
          enabled: false,
          supportsDiscovery: false,
          supportsCustody: false,
          reachabilityScope: MeshInterfaceReachabilityScope.local,
          costClass: MeshInterfaceCostClass.high,
          energyCostClass: MeshInterfaceEnergyCostClass.high,
          trustClass: MeshInterfaceTrustClass.untrusted,
          allowedPrivacyModes: <String>{},
          defaultAnnounceTtl: Duration.zero,
          maxHopCount: 1,
        ),
    };

    if (!profile.enabled) {
      return profile;
    }
    final enabledForPrivacyMode = profile.allowsPrivacyMode(normalizedMode);
    if (enabledForPrivacyMode) {
      return profile;
    }
    return MeshInterfaceProfile(
      interfaceId: profile.interfaceId,
      kind: profile.kind,
      enabled: false,
      supportsDiscovery: profile.supportsDiscovery,
      supportsCustody: profile.supportsCustody,
      reachabilityScope: profile.reachabilityScope,
      costClass: profile.costClass,
      energyCostClass: profile.energyCostClass,
      trustClass: profile.trustClass,
      allowedPrivacyModes: profile.allowedPrivacyModes,
      defaultAnnounceTtl: profile.defaultAnnounceTtl,
      maxHopCount: profile.maxHopCount,
    );
  }

  static double liveSignalScore(DiscoveredDevice? device) {
    final dbm = device?.signalStrength;
    if (dbm == null) {
      return device?.proximityScore ?? 0.38;
    }
    return (((dbm + 100) / 70.0)).clamp(0.0, 1.0).toDouble();
  }

  static double confidenceForDevice(DiscoveredDevice? device) {
    return math.max(device?.proximityScore ?? 0.42, liveSignalScore(device));
  }
}
