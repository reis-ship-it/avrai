import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_op_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

class ReceiptDetailPage extends StatefulWidget {
  final String ledgerRowId;

  const ReceiptDetailPage({
    super.key,
    required this.ledgerRowId,
  });

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  LedgerReceiptsServiceV0? _service;
  LedgerReceiptV0? _receipt;
  bool _loading = true;
  bool _verifying = false;
  bool? _verified;

  @override
  void initState() {
    super.initState();
    _service = _tryResolveService();
    _load();
  }

  LedgerReceiptsServiceV0? _tryResolveService() {
    try {
      return GetIt.instance<LedgerReceiptsServiceV0>();
    } catch (e, st) {
      developer.log(
        'LedgerReceiptsServiceV0 not registered',
        name: 'ReceiptDetailPage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _verified = null;
    });
    final service = _service;
    if (service == null) {
      setState(() => _loading = false);
      return;
    }
    final receipt = await service.getReceiptByLedgerRowId(widget.ledgerRowId);
    if (!mounted) return;
    setState(() {
      _receipt = receipt;
      _loading = false;
    });
  }

  Future<void> _verify() async {
    final service = _service;
    final receipt = _receipt;
    if (service == null || receipt == null) return;
    setState(() {
      _verifying = true;
      _verified = null;
    });
    final ok = await service.verifyReceipt(receipt);
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _verified = ok;
    });
  }

  Future<void> _sign() async {
    final service = _service;
    if (service == null) return;
    try {
      await service.signExisting(ledgerRowId: widget.ledgerRowId);
      await _load();
    } catch (e, st) {
      developer.log('sign_existing failed',
          name: 'ReceiptDetailPage', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign: $e')),
      );
    }
  }

  Future<void> _share() async {
    final receipt = _receipt;
    if (receipt == null) return;

    final bundle = <String, Object?>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'ledger_row': <String, Object?>{
        'id': receipt.event.id,
        'domain': receipt.event.domain.wireName,
        'owner_user_id': receipt.event.ownerUserId,
        'owner_agent_id': receipt.event.ownerAgentId,
        'logical_id': receipt.event.logicalId,
        'revision': receipt.event.revision,
        'supersedes_id': receipt.event.supersedesId,
        'op': receipt.event.op.wireName,
        'event_type': receipt.event.eventType,
        'entity_type': receipt.event.entityType,
        'entity_id': receipt.event.entityId,
        'category': receipt.event.category,
        'city_code': receipt.event.cityCode,
        'locality_code': receipt.event.localityCode,
        'occurred_at': receipt.event.occurredAt.toUtc().toIso8601String(),
        'atomic_timestamp_id': receipt.event.atomicTimestampId,
        'payload': receipt.event.payload,
        'created_at': receipt.event.createdAt?.toUtc().toIso8601String(),
      },
      'signature_row': receipt.signature?.toJson(),
    };

    await SharePlus.instance.share(ShareParams(text: jsonEncode(bundle)));
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return AdaptivePlatformPageScaffold(
      title: 'Receipt',
      constrainBody: false,
      actions: [
        IconButton(
          onPressed: receipt == null ? null : _share,
          icon: const Icon(Icons.share),
          tooltip: 'Share receipt bundle (JSON)',
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : receipt == null
              ? const Center(child: Text('Receipt not found.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summaryCard(receipt),
                    const SizedBox(height: 12),
                    _verificationCard(receipt),
                    const SizedBox(height: 12),
                    _payloadCard(receipt),
                  ],
                ),
    );
  }

  Widget _summaryCard(LedgerReceiptV0 receipt) {
    return PortalSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receipt.event.eventType,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Domain: ${receipt.event.domain.wireName}'),
          Text(
              'Op: ${receipt.event.op.wireName} • Revision: ${receipt.event.revision}'),
          Text('Occurred: ${receipt.event.occurredAt.toLocal()}'),
          if (receipt.event.entityType != null ||
              receipt.event.entityId != null)
            Text(
                'Entity: ${receipt.event.entityType ?? ''}:${receipt.event.entityId ?? ''}'),
          if (receipt.event.category != null)
            Text('Category: ${receipt.event.category}'),
          if (receipt.event.cityCode != null ||
              receipt.event.localityCode != null)
            Text(
                'Geo: ${receipt.event.cityCode ?? '-'} / ${receipt.event.localityCode ?? '-'}'),
        ],
      ),
    );
  }

  Widget _verificationCard(LedgerReceiptV0 receipt) {
    final sig = receipt.signature;

    final statusText = sig == null
        ? 'Unsigned'
        : (_verified == null
            ? 'Signed'
            : (_verified! ? 'Verified' : 'Signature mismatch'));

    final statusColor = switch (statusText) {
      'Verified' => AppColors.success,
      'Signature mismatch' => AppColors.error,
      'Signed' => AppTheme.primaryColor,
      _ => AppColors.grey600,
    };

    return PortalSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusText,
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sig != null) ...[
            Text('key_id: ${sig.keyId}'),
            Text('sha256: ${sig.sha256}'),
            Text('signed_at: ${sig.signedAt.toLocal()}'),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: Text(_verifying ? 'Verifying…' : 'Verify'),
              ),
              const SizedBox(width: 12),
              if (sig == null)
                OutlinedButton(
                  onPressed: _sign,
                  child: const Text('Generate signature'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'To verify signatures, ship a public key with '
            '--dart-define=LEDGER_RECEIPTS_PUBLIC_KEY_B64_V1=...',
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _payloadCard(LedgerReceiptV0 receipt) {
    final payloadPretty =
        const JsonEncoder.withIndent('  ').convert(receipt.event.payload);
    return PortalSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payload',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SelectableText(payloadPretty),
        ],
      ),
    );
  }
}
