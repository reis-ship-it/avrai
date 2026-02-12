import 'package:avrai/core/services/ledgers/ledger_event_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_signature_v0.dart';

/// A v0 ledger event optionally paired with its server-minted signature.
///
/// Backed by the view `public.ledger_receipts_v0` (ledger row + optional signature columns).
class LedgerReceiptV0 {
  final LedgerEventV0 event;
  final LedgerReceiptSignatureV0? signature;

  const LedgerReceiptV0({
    required this.event,
    required this.signature,
  });

  bool get isSigned => signature != null;

  /// Parse from a row returned by `ledger_receipts_v0`.
  ///
  /// The row contains both ledger columns and (when signed) receipt columns.
  factory LedgerReceiptV0.fromSupabaseRow(Map<String, dynamic> row) {
    final event = LedgerEventV0.fromSupabaseRow(row);

    final keyId = row['key_id'] as String?;
    final sigB64 = row['signature_b64'] as String?;
    final sha = row['sha256'] as String?;
    final canonicalJson = row['canonical_json'] as String?;
    final signedAt = row['signed_at'] as String?;

    LedgerReceiptSignatureV0? signature;
    if (keyId != null &&
        keyId.isNotEmpty &&
        sigB64 != null &&
        sigB64.isNotEmpty &&
        sha != null &&
        sha.isNotEmpty &&
        canonicalJson != null &&
        canonicalJson.isNotEmpty &&
        signedAt != null &&
        signedAt.isNotEmpty) {
      signature = LedgerReceiptSignatureV0(
        ledgerRowId: event.id ?? (row['id'] as String),
        schemaVersion: (row['receipt_schema_version'] as num?)?.toInt() ?? 0,
        canonAlgo: (row['canon_algo'] as String?) ?? 'v0_sorted_keys_json',
        canonicalJson: canonicalJson,
        sha256: sha,
        signatureB64: sigB64,
        keyId: keyId,
        signedAt: DateTime.parse(signedAt),
      );
    }

    return LedgerReceiptV0(event: event, signature: signature);
  }
}

