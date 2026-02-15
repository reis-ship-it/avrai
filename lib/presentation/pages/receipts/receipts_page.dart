import 'dart:developer' as developer;
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key});

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  LedgerReceiptsServiceV0? _service;
  late Future<List<LedgerReceiptV0>> _future;

  @override
  void initState() {
    super.initState();
    _service = _tryResolveService();
    _future = _load();
  }

  LedgerReceiptsServiceV0? _tryResolveService() {
    try {
      return GetIt.instance<LedgerReceiptsServiceV0>();
    } catch (e, st) {
      developer.log(
        'LedgerReceiptsServiceV0 not registered',
        name: 'ReceiptsPage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<List<LedgerReceiptV0>> _load() async {
    final service = _service;
    if (service == null) return const [];
    return await service.listReceipts(limit: 200);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Receipts',
      constrainBody: false,
      body: FutureBuilder<List<LedgerReceiptV0>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final receipts = snapshot.data ?? const <LedgerReceiptV0>[];
          if (receipts.isEmpty) {
            return const Center(
              child: Text('No receipts yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, idx) {
                final r = receipts[idx];
                final id = r.event.id ?? '';
                final subtitle =
                    '${r.event.domain.wireName} • ${r.event.occurredAt.toLocal()}';
                return PortalSurface(
                  margin: const EdgeInsets.symmetric(
                      horizontal: kSpaceSm, vertical: kSpaceXsTight),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      r.isSigned ? Icons.verified : Icons.pending_actions,
                      color: r.isSigned
                          ? AppColors.success
                          : AppTheme.primaryColor,
                    ),
                    title: Text(r.event.eventType),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: id.isEmpty
                        ? null
                        : () => context.go('/profile/receipts/$id'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
