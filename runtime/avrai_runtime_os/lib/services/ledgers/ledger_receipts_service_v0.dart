import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_receipt_signature_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_receipt_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_receipt_verifier_v0.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Reads and verifies v0 ledger receipts.
///
/// Data source:
/// - `public.ledger_receipts_v0` view for listing/detail (includes signature columns when present)
///
/// Signing:
/// - Uses edge function `ledger-receipts-v0` to mint signatures (`sign_existing`).
class LedgerReceiptsServiceV0 {
  static const String _logName = 'LedgerReceiptsServiceV0';
  static const String _receiptsView = 'ledger_receipts_v0';
  static const String _edgeFn = 'ledger-receipts-v0';

  final SupabaseService _supabaseService;
  final LedgerReceiptVerifierV0 _verifier;
  final AppLogger _logger;

  LedgerReceiptsServiceV0({
    required SupabaseService supabaseService,
    LedgerReceiptVerifierV0? verifier,
    AppLogger? logger,
  })  : _supabaseService = supabaseService,
        _verifier = verifier ?? LedgerReceiptVerifierV0(),
        _logger = logger ??
            const AppLogger(
                defaultTag: 'Ledgers', minimumLevel: LogLevel.debug);

  LedgerReceiptVerifierV0 get verifier => _verifier;

  Future<List<LedgerReceiptV0>> listReceipts({
    LedgerDomainV0? domain,
    String? eventType,
    DateTime? since,
    int limit = 100,
  }) async {
    if (_supabaseService.currentUser == null) {
      throw StateError('Not authenticated');
    }
    if (!_supabaseService.isAvailable) {
      return const [];
    }

    try {
      // NOTE: `SupabaseClient.from()` can return a builder where `select()` resolves to
      // `PostgrestTransformBuilder.select()` (used for insert/update return=representation),
      // which does not support filter methods like `eq/gte`.
      //
      // Using `client.rest.from()` guarantees a PostgrestQueryBuilder → select() returns
      // a PostgrestFilterBuilder with `eq/gte/...` available (and matches other call sites).
      var query = _supabaseService.client.rest.from(_receiptsView).select('*');

      if (domain != null) {
        query = query.eq('domain', domain.wireName);
      }
      if (eventType != null && eventType.isNotEmpty) {
        query = query.eq('event_type', eventType);
      }
      if (since != null) {
        query = query.gte('occurred_at', since.toUtc().toIso8601String());
      }

      final rowsDynamic =
          await query.order('occurred_at', ascending: false).limit(limit);
      final rows = (rowsDynamic as List).cast<Map<String, dynamic>>();
      return rows
          .map((r) => LedgerReceiptV0.fromSupabaseRow(r))
          .toList(growable: false);
    } catch (e, st) {
      developer.log('Failed listing receipts',
          error: e, stackTrace: st, name: _logName);
      return const [];
    }
  }

  Future<LedgerReceiptV0?> getReceiptByLedgerRowId(String ledgerRowId) async {
    if (_supabaseService.currentUser == null) {
      throw StateError('Not authenticated');
    }
    if (!_supabaseService.isAvailable) {
      return null;
    }
    try {
      final row = await _supabaseService.client.rest
          .from(_receiptsView)
          .select('*')
          .eq('id', ledgerRowId)
          .maybeSingle();
      if (row == null) return null;
      return LedgerReceiptV0.fromSupabaseRow(
          (row as Map).cast<String, dynamic>());
    } catch (e, st) {
      developer.log('Failed reading receipt',
          error: e, stackTrace: st, name: _logName);
      return null;
    }
  }

  Future<LedgerReceiptSignatureV0> signExisting({
    required String ledgerRowId,
  }) async {
    if (_supabaseService.currentUser == null) {
      throw StateError('Not authenticated');
    }
    if (!_supabaseService.isAvailable) {
      throw StateError('Supabase not available');
    }

    final response = await _supabaseService.client.functions.invoke(
      _edgeFn,
      body: jsonEncode(<String, Object?>{
        'action': 'sign_existing',
        'ledger_row_id': ledgerRowId,
      }),
    );
    if (response.status != 200) {
      throw Exception(
          'sign_existing failed: ${response.status} ${response.data}');
    }
    final data = (response.data is String)
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map) {
      throw Exception('Invalid sign_existing response');
    }
    final sigRow = data['signature_row'];
    if (sigRow is! Map) {
      throw Exception('Missing signature_row');
    }
    return LedgerReceiptSignatureV0.fromSupabaseRow(
      sigRow.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<bool> verifyReceipt(LedgerReceiptV0 receipt) async {
    try {
      return await _verifier.verify(receipt);
    } catch (e, st) {
      _logger.warn('Receipt verification failed: $e', tag: _logName);
      developer.log('Receipt verification failed',
          error: e, stackTrace: st, name: _logName);
      return false;
    }
  }
}
