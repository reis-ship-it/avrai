import 'dart:convert';

/// A v0 signed receipt for a single ledger row.
///
/// Backed by `public.ledger_receipt_signatures_v0`.
class LedgerReceiptSignatureV0 {
  final String ledgerRowId;
  final int schemaVersion;
  final String canonAlgo;
  final String canonicalJson;
  final String sha256;
  final String signatureB64;
  final String keyId;
  final DateTime signedAt;

  const LedgerReceiptSignatureV0({
    required this.ledgerRowId,
    required this.schemaVersion,
    required this.canonAlgo,
    required this.canonicalJson,
    required this.sha256,
    required this.signatureB64,
    required this.keyId,
    required this.signedAt,
  });

  factory LedgerReceiptSignatureV0.fromSupabaseRow(Map<String, dynamic> row) {
    return LedgerReceiptSignatureV0(
      ledgerRowId: row['ledger_row_id'] as String,
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      canonAlgo: (row['canon_algo'] as String?) ?? 'v0_sorted_keys_json',
      canonicalJson: row['canonical_json'] as String,
      sha256: row['sha256'] as String,
      signatureB64: row['signature_b64'] as String,
      keyId: row['key_id'] as String,
      signedAt: DateTime.parse(row['signed_at'] as String),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'ledger_row_id': ledgerRowId,
        'schema_version': schemaVersion,
        'canon_algo': canonAlgo,
        'canonical_json': canonicalJson,
        'sha256': sha256,
        'signature_b64': signatureB64,
        'key_id': keyId,
        'signed_at': signedAt.toUtc().toIso8601String(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

