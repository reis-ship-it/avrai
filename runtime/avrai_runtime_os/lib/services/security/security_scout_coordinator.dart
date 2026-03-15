import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class SecurityScoutCoordinator {
  SecurityScoutCoordinator({
    SharedPreferencesCompat? prefs,
    DateTime Function()? nowProvider,
  })  : _prefs = prefs,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  static const String _storageKey = 'security.scouts.v1';

  final SharedPreferencesCompat? _prefs;
  final DateTime Function() _nowProvider;

  List<SecurityScoutStatus> listScouts() {
    final prefs = _prefs;
    if (prefs == null) {
      return const <SecurityScoutStatus>[];
    }
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <SecurityScoutStatus>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <SecurityScoutStatus>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) => SecurityScoutStatus(
            scoutId: entry['scoutId']?.toString() ?? '',
            alias: entry['alias']?.toString() ?? '',
            truthScope: TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(
                entry['truthScope'] as Map? ?? const <String, dynamic>{},
              ),
            ),
            lastSeenAt: DateTime.tryParse(
                  entry['lastSeenAt']?.toString() ?? '',
                )?.toUtc() ??
                _nowProvider(),
            activeCampaignCount:
                (entry['activeCampaignCount'] as num?)?.toInt() ?? 0,
            probeOnly: entry['probeOnly'] as bool? ?? true,
            metadata: Map<String, dynamic>.from(
              entry['metadata'] as Map? ?? const <String, dynamic>{},
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> updateScoutHeartbeat({
    required String scoutId,
    required String alias,
    required TruthScopeDescriptor truthScope,
    required int activeCampaignCount,
    bool probeOnly = true,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final encoded = listScouts().map((entry) {
      return <String, dynamic>{
        'scoutId': entry.scoutId,
        'alias': entry.alias,
        'truthScope': entry.truthScope.toJson(),
        'lastSeenAt': entry.lastSeenAt.toUtc().toIso8601String(),
        'activeCampaignCount': entry.activeCampaignCount,
        'probeOnly': entry.probeOnly,
        'metadata': entry.metadata,
      };
    }).toList(growable: true);
    encoded.removeWhere((entry) => entry['scoutId'] == scoutId);
    encoded.insert(
      0,
      <String, dynamic>{
        'scoutId': scoutId,
        'alias': alias,
        'truthScope': truthScope.toJson(),
        'lastSeenAt': _nowProvider().toUtc().toIso8601String(),
        'activeCampaignCount': activeCampaignCount,
        'probeOnly': probeOnly,
        'metadata': metadata,
      },
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }
}
