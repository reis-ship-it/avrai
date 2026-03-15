import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class UrkGovernedRuntimeBinding {
  const UrkGovernedRuntimeBinding({
    required this.runtimeId,
    required this.stratum,
    required this.userId,
    required this.aiSignature,
    required this.agentId,
    required this.source,
    required this.updatedAt,
  });

  final String runtimeId;
  final GovernanceStratum? stratum;
  final String? userId;
  final String? aiSignature;
  final String? agentId;
  final String source;
  final AtomicTimestamp updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'runtime_id': runtimeId,
      'stratum': stratum?.name,
      'user_id': userId,
      'ai_signature': aiSignature,
      'agent_id': agentId,
      'source': source,
      'updated_at': updatedAt.toJson(),
    };
  }

  factory UrkGovernedRuntimeBinding.fromJson(Map<String, dynamic> json) {
    final rawStratum = json['stratum'] as String?;
    GovernanceStratum? stratum;
    if (rawStratum != null) {
      for (final value in GovernanceStratum.values) {
        if (value.name == rawStratum) {
          stratum = value;
          break;
        }
      }
    }
    return UrkGovernedRuntimeBinding(
      runtimeId: json['runtime_id'] as String? ?? '',
      stratum: stratum,
      userId: json['user_id'] as String?,
      aiSignature: json['ai_signature'] as String?,
      agentId: json['agent_id'] as String?,
      source: json['source'] as String? ?? 'unknown',
      updatedAt: AtomicTimestamp.fromJson(
        json['updated_at'] as Map<String, dynamic>,
      ),
    );
  }
}

class UrkGovernedRuntimeRegistryService {
  UrkGovernedRuntimeRegistryService({
    SharedPreferencesCompat? prefs,
  }) : _prefs = prefs;

  static const String _bindingsKey = 'urk_governed_runtime_registry_v1';
  static const int _maxBindings = 1000;

  final SharedPreferencesCompat? _prefs;

  static List<String> canonicalPersonalRuntimeIds({
    required String userId,
    required String agentId,
    String? aiSignature,
  }) {
    final resolvedAiSignature =
        aiSignature ?? deterministicAISignatureForUser(userId);
    return <String>{
      userId,
      agentId,
      resolvedAiSignature,
      'personal_runtime_$agentId',
      'runtime_personal_$agentId',
      'personal:$agentId',
      'user_runtime_$userId',
      'world_runtime_$userId',
    }.toList(growable: false);
  }

  static List<String> canonicalLocalityRuntimeIds({
    required String userId,
    required String agentId,
    required String localityTokenId,
    String? cityCode,
    String? localityCode,
    String? topAlias,
  }) {
    return <String>{
      localityTokenId,
      'locality_runtime_$localityTokenId',
      'locality:user:$userId',
      'locality:agent:$agentId',
      if (cityCode != null && cityCode.isNotEmpty) 'locality:city:$cityCode',
      if (localityCode != null && localityCode.isNotEmpty)
        'locality:code:$localityCode',
      if (topAlias != null && topAlias.isNotEmpty) 'locality:alias:$topAlias',
    }.toList(growable: false);
  }

  static List<String> canonicalTopLayerRuntimeIds({
    required GovernanceStratum stratum,
    required String layer,
  }) {
    final normalizedLayer = layer.trim().toLowerCase();
    final primaryRuntimeId = switch (stratum) {
      GovernanceStratum.world => 'world_model_primary',
      GovernanceStratum.universal => 'universal_model_primary',
      _ => '${stratum.name}_model_primary',
    };
    return <String>{
      primaryRuntimeId,
      '${stratum.name}_runtime_primary',
      '${stratum.name}:primary',
      '$normalizedLayer:primary',
      '${normalizedLayer}_runtime_primary',
    }.toList(growable: false);
  }

  static String deterministicAISignatureForUser(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16);
    return 'ai_$hash';
  }

  Future<void> upsertBinding(UrkGovernedRuntimeBinding binding) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return;
    }
    final bindings = await _readBindings(prefs);
    bindings.removeWhere((item) => item.runtimeId == binding.runtimeId);
    bindings.add(binding);
    bindings.sort(
      (a, b) => b.updatedAt.serverTime.compareTo(a.updatedAt.serverTime),
    );
    final capped = bindings.length <= _maxBindings
        ? bindings
        : bindings.sublist(0, _maxBindings);
    await prefs.setString(
      _bindingsKey,
      jsonEncode(capped.map((item) => item.toJson()).toList()),
    );
  }

  Future<UrkGovernedRuntimeBinding?> getBinding(String runtimeId) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return null;
    }
    final bindings = await _readBindings(prefs);
    for (final binding in bindings) {
      if (binding.runtimeId == runtimeId) {
        return binding;
      }
    }
    return null;
  }

  Future<List<UrkGovernedRuntimeBinding>> listBindings({
    int limit = 25,
    GovernanceStratum? stratum,
  }) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return <UrkGovernedRuntimeBinding>[];
    }
    final bindings = await _readBindings(prefs);
    final filtered = bindings.where((binding) {
      if (stratum != null && binding.stratum != stratum) {
        return false;
      }
      return true;
    }).toList()
      ..sort(
          (a, b) => b.updatedAt.serverTime.compareTo(a.updatedAt.serverTime));
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.sublist(0, limit);
  }

  Future<List<UrkGovernedRuntimeBinding>> _readBindings(
    SharedPreferencesCompat prefs,
  ) async {
    final raw = prefs.getString(_bindingsKey);
    if (raw == null || raw.isEmpty) {
      return <UrkGovernedRuntimeBinding>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return <UrkGovernedRuntimeBinding>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(UrkGovernedRuntimeBinding.fromJson)
          .where((binding) => binding.runtimeId.isNotEmpty)
          .toList();
    } catch (_) {
      return <UrkGovernedRuntimeBinding>[];
    }
  }

  Future<SharedPreferencesCompat?> _resolvePrefs() async {
    if (_prefs != null) {
      return _prefs;
    }
    try {
      return await SharedPreferencesCompat.getInstance();
    } catch (_) {
      return null;
    }
  }
}
