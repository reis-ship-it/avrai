import 'dart:async';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Optional UX: small chip showing that the private AI2AI network is active.
///
/// Shows "AI network active" when the connection orchestrator has at least one
/// active connection. Uses AppColors/AppTheme per design token requirements.
class AINetworkStatusChip extends StatefulWidget {
  /// Refresh interval for active connection count.
  final Duration refreshInterval;

  const AINetworkStatusChip({
    super.key,
    this.refreshInterval = const Duration(seconds: 10),
  });

  @override
  State<AINetworkStatusChip> createState() => _AINetworkStatusChipState();
}

class _AINetworkStatusChipState extends State<AINetworkStatusChip> {
  Timer? _timer;
  int _activeCount = 0;
  bool _orchestratorAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkOrchestrator();
    _timer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted) _updateCount();
    });
  }

  void _checkOrchestrator() {
    if (!GetIt.instance.isRegistered<VibeConnectionOrchestrator>()) {
      _orchestratorAvailable = false;
      return;
    }
    _orchestratorAvailable = true;
    if (mounted) _updateCount();
  }

  void _updateCount() {
    if (!_orchestratorAvailable) {
      _checkOrchestrator();
      return;
    }
    try {
      final orchestrator = GetIt.instance.get<VibeConnectionOrchestrator>();
      final count = orchestrator.getActiveConnectionCount();
      if (mounted && count != _activeCount) {
        setState(() => _activeCount = count);
      }
    } catch (_) {
      if (mounted && _activeCount != 0) setState(() => _activeCount = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceXxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpaceSmTight, vertical: kSpaceXsTight),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI network active',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
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
