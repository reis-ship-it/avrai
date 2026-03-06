import 'dart:developer' as developer;

import 'package:avrai_core/models/misc/world_plane_view_state.dart';
import 'package:avrai_runtime_os/services/telemetry/design_journey_telemetry.dart';
import 'package:avrai_runtime_os/services/visualization/world_plane_orchestration_adapter.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/knot/worldsheet_4d_widget.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';

class WorldPlanesPage extends StatefulWidget {
  const WorldPlanesPage({super.key});

  @override
  State<WorldPlanesPage> createState() => _WorldPlanesPageState();
}

class _WorldPlanesPageState extends State<WorldPlanesPage> {
  final WorldPlaneOrchestrationAdapter _adapter =
      WorldPlaneOrchestrationAdapter();
  WorldPlaneViewState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _state = WorldPlaneViewState.unavailable(
          reason: 'Sign in to unlock your world plane.',
        );
        _loading = false;
      });
      return;
    }

    try {
      await DesignJourneyTelemetry.log('world_plane_enter');
      final state = await _adapter.loadForUser(userId: authState.user.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'World plane load failed: $e',
        name: 'WorldPlanesPage',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _state = WorldPlaneViewState.unavailable(
          reason: 'World plane is unavailable right now.',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'World Planes',
      scrollable: true,
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh world plane',
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See how your social world evolves across time.',
            style: textTheme.titleMedium,
          ),
          SizedBox(height: spacing.sm),
          Text(
            'This view translates your knot and evolution signals into an explorable surface.',
            style:
                textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: spacing.lg),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_state == null ||
              !_state!.isAvailable ||
              _state!.worldsheet == null)
            _buildUnavailable(context, _state)
          else
            _buildWorldsheet(context, _state!),
        ],
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context, WorldPlaneViewState? state) {
    final spacing = context.spacing;
    return AppSurface(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public_off, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Ambient mode active'),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            state?.fallbackReason ??
                'World plane is still being prepared from your evolving data.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.sm,
            children: [
              ElevatedButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorldsheet(BuildContext context, WorldPlaneViewState state) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isStale)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.radius.md),
              color: AppColors.warning.withValues(alpha: 0.15),
            ),
            child: const Text(
              'Showing earlier cached evolution. Data will refresh as new signals arrive.',
            ),
          ),
        SizedBox(height: spacing.md),
        SizedBox(
          height: 420,
          width: double.infinity,
          child: AppSurface(
            padding: EdgeInsets.all(spacing.sm),
            child: Worldsheet4DWidget(
              worldsheet: state.worldsheet!,
              showControls: true,
              useThreeJs: true,
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        Text(
          'Confidence: ${(state.confidence * 100).round()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (state.rangeStart != null && state.rangeEnd != null)
          Text(
            'Range: ${_fmt(state.rangeStart!)} to ${_fmt(state.rangeEnd!)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
