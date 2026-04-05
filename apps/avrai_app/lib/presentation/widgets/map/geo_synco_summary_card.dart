import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:avrai_runtime_os/services/geographic/geo_locality_pack_service.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';

/// Offline-first “synco” summary card for a geo entity (v1).
///
/// Reads `summaries.json` from an installed city pack.
class GeoSyncoSummaryCard extends StatefulWidget {
  final String cityCode;
  final String geoId;
  final GeoLocalityPackService? packService;

  const GeoSyncoSummaryCard({
    super.key,
    required this.cityCode,
    required this.geoId,
    this.packService,
  });

  @override
  State<GeoSyncoSummaryCard> createState() => _GeoSyncoSummaryCardState();
}

class _GeoSyncoSummaryCardState extends State<GeoSyncoSummaryCard> {
  static const String _logName = 'GeoSyncoSummaryCard';

  late final GeoLocalityPackService _packs =
      widget.packService ?? GeoLocalityPackService();

  bool _loading = false;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    // ignore: unawaited_futures
    _load();
  }

  @override
  void didUpdateWidget(covariant GeoSyncoSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityCode != widget.cityCode ||
        oldWidget.geoId != widget.geoId) {
      // ignore: unawaited_futures
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _summary = null;
    });

    try {
      final s = await _packs.getGeneralSyncoSummary(
        cityCode: widget.cityCode,
        geoId: widget.geoId,
      );
      if (!mounted) return;
      setState(() {
        _summary = s;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load offline synco summary: $e',
        name: _logName,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oneLiner = (_summary?['one_liner'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Place insights (offline-first)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                if (_loading)
                  Text(
                    'Loading cached city pack…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else if (oneLiner.isNotEmpty)
                  Text(
                    oneLiner,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    'No offline summary yet for this locality. It will appear after the city pack downloads.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
