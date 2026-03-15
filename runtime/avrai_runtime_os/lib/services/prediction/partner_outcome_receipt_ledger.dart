import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class PartnerOutcomeReceiptLedger {
  PartnerOutcomeReceiptLedger({SharedPreferencesCompat? prefs})
      : _prefs = prefs {
    _hydrate();
  }

  static const String _storageKey = 'partner_outcome_receipts_v1';
  static const int _maxReceipts = 200;

  final SharedPreferencesCompat? _prefs;
  final Map<String, PartnerOutcomeReceipt> _receiptsByIdempotencyKey =
      <String, PartnerOutcomeReceipt>{};

  bool containsIdempotencyKey(String idempotencyKey) {
    return _receiptsByIdempotencyKey.containsKey(idempotencyKey);
  }

  Future<bool> recordReceipt(PartnerOutcomeReceipt receipt) async {
    if (containsIdempotencyKey(receipt.idempotencyKey)) {
      return false;
    }
    _receiptsByIdempotencyKey[receipt.idempotencyKey] = receipt;
    if (_receiptsByIdempotencyKey.length > _maxReceipts) {
      final sortedKeys = _receiptsByIdempotencyKey.entries.toList()
        ..sort(
          (left, right) =>
              left.value.resolvedAt.compareTo(right.value.resolvedAt),
        );
      final overflow = sortedKeys.length - _maxReceipts;
      for (var index = 0; index < overflow; index++) {
        _receiptsByIdempotencyKey.remove(sortedKeys[index].key);
      }
    }
    await _persist();
    return true;
  }

  List<PartnerOutcomeReceipt> receiptsForTenant(String tenantId) {
    return _receiptsByIdempotencyKey.values
        .where((receipt) => receipt.tenantId == tenantId)
        .toList(growable: false);
  }

  void _hydrate() {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final encoded = prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      return;
    }
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      final receipt = PartnerOutcomeReceipt.fromJson(
        Map<String, dynamic>.from(entry),
      );
      _receiptsByIdempotencyKey[receipt.idempotencyKey] = receipt;
    }
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final encoded = jsonEncode(
      _receiptsByIdempotencyKey.values
          .map((receipt) => receipt.toJson())
          .toList(growable: false),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
