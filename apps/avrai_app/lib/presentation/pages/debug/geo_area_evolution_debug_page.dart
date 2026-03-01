import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Debug-only page to inspect `stable_key -> area_id` mapping and dual-city fields.
class GeoAreaEvolutionDebugPage extends StatefulWidget {
  const GeoAreaEvolutionDebugPage({super.key});

  @override
  State<GeoAreaEvolutionDebugPage> createState() =>
      _GeoAreaEvolutionDebugPageState();
}

class _GeoAreaEvolutionDebugPageState extends State<GeoAreaEvolutionDebugPage> {
  static const String _logName = 'GeoAreaEvolutionDebugPage';

  final _stableKeyController = TextEditingController();

  Map<String, dynamic>? _row;
  String? _error;
  bool _isBusy = false;

  @override
  void dispose() {
    _stableKeyController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _error = null;
      _row = null;
      _isBusy = true;
    });

    try {
      final stableKey = _stableKeyController.text.trim();
      if (stableKey.isEmpty) {
        setState(() {
          _isBusy = false;
          _error = 'Enter a stable_key like gh7:dr5regw';
        });
        return;
      }

      final sl = GetIt.instance;
      final supabase = sl<SupabaseService>();
      final client = supabase.tryGetClient();
      if (client == null) {
        setState(() {
          _isBusy = false;
          _error = 'Supabase unavailable (offline).';
        });
        return;
      }

      final res = await client
          .from('geo_area_cluster_memberships_v1')
          .select(
            'stable_key, area_id, component_hash, mapping_version, city_code, reported_city_code, inferred_city_code, primary_city_code, updated_at',
          )
          .eq('stable_key', stableKey)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isBusy = false;
        _row = res == null ? null : Map<String, dynamic>.from(res);
        if (res == null) {
          _error = 'No membership row found for that stable_key.';
        }
      });
    } catch (e, st) {
      developer.log('Lookup failed', name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = e.toString();
      });
    }
  }

  Widget _kv(String k, Object? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (v ?? '').toString(),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const AdaptivePlatformPageScaffold(
        title: 'Geo Area Evolution Debug',
        showNavigationBar: false,
        constrainBody: false,
        body: Center(
          child: Text('Geo area debug is available in debug builds only.'),
        ),
      );
    }

    return AdaptivePlatformPageScaffold(
      title: 'Geo Area Evolution Debug',
      appBarBackgroundColor: AppColors.background,
      backgroundColor: AppColors.background,
      constrainBody: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Inspect stable_key → area_id mapping and dual city tracking fields.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stableKeyController,
              decoration: const InputDecoration(
                labelText: 'stable_key',
                hintText: 'gh7:dr5regw',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isBusy ? null : _lookup,
              child: Text(_isBusy ? 'Looking up…' : 'Lookup membership'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (_row != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              _kv('stable_key', _row!['stable_key']),
              _kv('area_id', _row!['area_id']),
              _kv('component_hash', _row!['component_hash']),
              _kv('mapping_version', _row!['mapping_version']),
              const Divider(),
              _kv('city_code (legacy)', _row!['city_code']),
              _kv('reported_city_code', _row!['reported_city_code']),
              _kv('inferred_city_code', _row!['inferred_city_code']),
              _kv('primary_city_code', _row!['primary_city_code']),
              const Divider(),
              _kv('updated_at', _row!['updated_at']),
            ],
          ],
        ),
      ),
    );
  }
}
