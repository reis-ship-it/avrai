import 'dart:convert';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:get_it/get_it.dart';

class BoundedFollowUpSuppressionRecord {
  const BoundedFollowUpSuppressionRecord({
    required this.familyKey,
    required this.targetKey,
    required this.channelHint,
    required this.suppressedAtUtc,
    this.untilUtc,
    this.reason = 'dismissed_in_app_follow_up',
    this.permanent = false,
  });

  final String familyKey;
  final String targetKey;
  final String channelHint;
  final DateTime suppressedAtUtc;
  final DateTime? untilUtc;
  final String reason;
  final bool permanent;

  bool isActive(DateTime nowUtc) {
    if (permanent) {
      return true;
    }
    final until = untilUtc;
    if (until == null) {
      return false;
    }
    return !until.toUtc().isBefore(nowUtc.toUtc());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'familyKey': familyKey,
      'targetKey': targetKey,
      'channelHint': channelHint,
      'suppressedAtUtc': suppressedAtUtc.toUtc().toIso8601String(),
      'untilUtc': untilUtc?.toUtc().toIso8601String(),
      'reason': reason,
      'permanent': permanent,
    };
  }

  factory BoundedFollowUpSuppressionRecord.fromJson(Map<String, dynamic> json) {
    return BoundedFollowUpSuppressionRecord(
      familyKey: json['familyKey'] as String? ?? '',
      targetKey: json['targetKey'] as String? ?? '',
      channelHint: json['channelHint'] as String? ?? '',
      suppressedAtUtc:
          DateTime.tryParse(json['suppressedAtUtc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      untilUtc: DateTime.tryParse(json['untilUtc'] as String? ?? '')?.toUtc(),
      reason: json['reason'] as String? ?? 'dismissed_in_app_follow_up',
      permanent: json['permanent'] as bool? ?? false,
    );
  }
}

class BoundedFollowUpSuppressionMemoryService {
  static const String _storageKeyPrefix =
      'bham:bounded_follow_up_suppression_memory:v1:';

  BoundedFollowUpSuppressionMemoryService({
    SharedPreferencesCompat? prefs,
    BoundedFollowUpPromptPolicyService? promptPolicyService,
  })  : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _promptPolicyService =
            promptPolicyService ?? BoundedFollowUpPromptPolicyService();

  final SharedPreferencesCompat? _prefs;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;

  Future<BoundedFollowUpSuppressionRecord?> activeSuppression({
    required String ownerUserId,
    required String familyKey,
    required String targetKey,
    DateTime? nowUtc,
  }) async {
    final normalizedFamilyKey = familyKey.trim();
    final normalizedTargetKey = targetKey.trim();
    if (normalizedFamilyKey.isEmpty || normalizedTargetKey.isEmpty) {
      return null;
    }
    final current = (nowUtc ?? DateTime.now()).toUtc();
    final records = await _listRecords(ownerUserId);
    for (final record in records) {
      if (record.familyKey != normalizedFamilyKey ||
          record.targetKey != normalizedTargetKey) {
        continue;
      }
      if (record.isActive(current)) {
        return record;
      }
    }
    return null;
  }

  Future<void> suppressForDismissal({
    required String ownerUserId,
    required String familyKey,
    required String targetKey,
    required String channelHint,
    DateTime? suppressedAtUtc,
    bool permanent = false,
    String reason = 'dismissed_in_app_follow_up',
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final normalizedFamilyKey = familyKey.trim();
    final normalizedTargetKey = targetKey.trim();
    if (normalizedFamilyKey.isEmpty || normalizedTargetKey.isEmpty) {
      return;
    }
    final atUtc = (suppressedAtUtc ?? DateTime.now()).toUtc();
    final untilUtc = permanent
        ? null
        : atUtc.add(
            _promptPolicyService.suppressionDurationForChannelHint(channelHint),
          );
    final nextRecord = BoundedFollowUpSuppressionRecord(
      familyKey: normalizedFamilyKey,
      targetKey: normalizedTargetKey,
      channelHint: channelHint,
      suppressedAtUtc: atUtc,
      untilUtc: untilUtc,
      reason: reason,
      permanent: permanent,
    );
    final records = await _listRecords(ownerUserId);
    final updated = <BoundedFollowUpSuppressionRecord>[
      nextRecord,
      ...records.where(
        (record) => !(record.familyKey == normalizedFamilyKey &&
            record.targetKey == normalizedTargetKey),
      ),
    ];
    await _storeRecords(ownerUserId, updated);
  }

  Future<void> clearAll(String ownerUserId) async {
    await _prefs?.remove(_storageKey(ownerUserId));
  }

  Future<List<BoundedFollowUpSuppressionRecord>> _listRecords(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <BoundedFollowUpSuppressionRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <BoundedFollowUpSuppressionRecord>[];
      }
      final nowUtc = DateTime.now().toUtc();
      final records = decoded
          .whereType<Map>()
          .map(
            (item) => BoundedFollowUpSuppressionRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((record) => record.permanent || record.isActive(nowUtc))
          .toList(growable: false);
      await _storeRecords(ownerUserId, records);
      return records;
    } catch (_) {
      return const <BoundedFollowUpSuppressionRecord>[];
    }
  }

  Future<void> _storeRecords(
    String ownerUserId,
    List<BoundedFollowUpSuppressionRecord> records,
  ) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      _storageKey(ownerUserId),
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
}
