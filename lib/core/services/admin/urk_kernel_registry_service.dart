// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class UrkKernelRegistryService {
  const UrkKernelRegistryService();

  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    final raw =
        await rootBundle.loadString('configs/runtime/kernel_registry.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final kernelsRaw = (decoded['kernels'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    final kernels = kernelsRaw.map(UrkKernelRecord.fromJson).toList()
      ..sort((a, b) => a.kernelId.compareTo(b.kernelId));

    final byProng = <String, int>{};
    final byMode = <String, int>{};
    final byImpact = <String, int>{};
    for (final kernel in kernels) {
      byProng[kernel.prongScope] = (byProng[kernel.prongScope] ?? 0) + 1;
      byMode[kernel.privacyModes.join('|')] =
          (byMode[kernel.privacyModes.join('|')] ?? 0) + 1;
      byImpact[kernel.impactTier] = (byImpact[kernel.impactTier] ?? 0) + 1;
    }

    return UrkKernelRegistrySnapshot(
      version: decoded['version'] as String? ?? 'unknown',
      updatedAt: decoded['updated_at'] as String? ?? 'unknown',
      kernels: kernels,
      byProng: byProng,
      byMode: byMode,
      byImpactTier: byImpact,
    );
  }
}

class UrkKernelRegistrySnapshot {
  final String version;
  final String updatedAt;
  final List<UrkKernelRecord> kernels;
  final Map<String, int> byProng;
  final Map<String, int> byMode;
  final Map<String, int> byImpactTier;

  const UrkKernelRegistrySnapshot({
    required this.version,
    required this.updatedAt,
    required this.kernels,
    required this.byProng,
    required this.byMode,
    required this.byImpactTier,
  });
}

class UrkKernelRecord {
  final String kernelId;
  final String title;
  final String purpose;
  final List<String> runtimeScope;
  final String prongScope;
  final List<String> privacyModes;
  final String impactTier;
  final List<String> localityScope;
  final List<String> activationTriggers;
  final String authorityMode;
  final List<String> dependencies;
  final String lifecycleState;
  final String owner;
  final String approver;
  final String milestoneId;
  final String status;

  const UrkKernelRecord({
    required this.kernelId,
    required this.title,
    required this.purpose,
    required this.runtimeScope,
    required this.prongScope,
    required this.privacyModes,
    required this.impactTier,
    required this.localityScope,
    required this.activationTriggers,
    required this.authorityMode,
    required this.dependencies,
    required this.lifecycleState,
    required this.owner,
    required this.approver,
    required this.milestoneId,
    required this.status,
  });

  factory UrkKernelRecord.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) {
      return (json[key] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList();
    }

    return UrkKernelRecord(
      kernelId: json['kernel_id'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Untitled',
      purpose: json['purpose'] as String? ?? 'No purpose provided',
      runtimeScope: stringList('runtime_scope'),
      prongScope: json['prong_scope'] as String? ?? 'unknown',
      privacyModes: stringList('privacy_modes'),
      impactTier: json['impact_tier'] as String? ?? 'unknown',
      localityScope: stringList('locality_scope'),
      activationTriggers: stringList('activation_triggers'),
      authorityMode: json['authority_mode'] as String? ?? 'unknown',
      dependencies: stringList('dependencies'),
      lifecycleState: json['lifecycle_state'] as String? ?? 'unknown',
      owner: json['owner'] as String? ?? 'unknown',
      approver: json['approver'] as String? ?? 'unknown',
      milestoneId: json['milestone_id'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
    );
  }
}
