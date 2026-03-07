/// AI2AI Connection View Widget
///
/// Displays active AI-to-AI connections with compatibility scores and explanations.
/// Shows live connection status, compatibility signals, and optional handoff actions.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:get_it/get_it.dart';

/// Widget displaying AI2AI connections with compatibility information
class AI2AIConnectionViewWidget extends StatefulWidget {
  final bool showHumanConnectionButton;
  final Function(ConnectionMetrics)? onEnableHumanConnection;

  /// Optional override for tests/debug: provide a fixed list of connections.
  final List<ConnectionMetrics>? connections;

  /// Optional override for tests/debug: provide an orchestrator instance directly.
  final VibeConnectionOrchestrator? orchestrator;

  const AI2AIConnectionViewWidget({
    super.key,
    this.showHumanConnectionButton = true,
    this.onEnableHumanConnection,
    this.connections,
    this.orchestrator,
  });

  @override
  State<AI2AIConnectionViewWidget> createState() =>
      _AI2AIConnectionViewWidgetState();
}

class _AI2AIConnectionViewWidgetState extends State<AI2AIConnectionViewWidget> {
  VibeConnectionOrchestrator? _orchestrator;
  List<ConnectionMetrics> _activeConnections = [];
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _loadError;
  String? _loadGuidance;

  @override
  void initState() {
    super.initState();
    // If tests/debug provided connections explicitly, render without DI/timers.
    if (widget.connections != null) {
      _activeConnections = widget.connections!;
      _isLoading = false;
      return;
    }

    _initializeOrchestrator();
  }

  Future<void> _initializeOrchestrator() async {
    try {
      _orchestrator =
          widget.orchestrator ?? GetIt.instance<VibeConnectionOrchestrator>();
      await _refreshConnections();
      _startAutoRefresh();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = null;
          _loadGuidance = null;
        });
      }
    } catch (e) {
      developer.log('Error initializing orchestrator: $e',
          name: 'AI2AIConnectionViewWidget');
      final issue = _mapConnectionIssue(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = issue.$1;
          _loadGuidance = issue.$2;
        });
      }
    }
  }

  void _startAutoRefresh() {
    // Refresh connection list every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _refreshConnections();
      }
    });
  }

  Future<void> _refreshConnections() async {
    if (_orchestrator == null) return;

    try {
      final connections = _orchestrator!.getActiveConnections();
      if (mounted) {
        setState(() {
          _activeConnections = connections;
          _loadError = null;
          _loadGuidance = null;
        });
      }
    } catch (e, st) {
      developer.log(
        'Error refreshing AI2AI connections',
        name: 'AI2AIConnectionViewWidget',
        error: e,
        stackTrace: st,
      );
      final issue = _mapConnectionIssue(e);
      if (mounted) {
        setState(() {
          _loadError = issue.$1;
          _loadGuidance = issue.$2;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshConnections,
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_loadError != null) _buildTransportIssueBanner(),
          if (_activeConnections.isEmpty)
            _buildEmptyState()
          else
            ..._activeConnections.map(_buildConnectionCard),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_off,
              size: 64,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active AI Connections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your AI hasn\'t connected with other AIs yet.\n'
            'Enable device discovery to find compatible AIs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.electricGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.electricGreen,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI connections are fleeting and managed automatically by your AI personality',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportIssueBanner() {
    return Semantics(
      label: 'AI2AI connection status error',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connection status unavailable',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? 'Unable to load current AI2AI connection state.',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            if (_loadGuidance != null && _loadGuidance!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _loadGuidance!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: 'Retry loading AI2AI connections',
                child: TextButton.icon(
                  onPressed: _refreshConnections,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(ConnectionMetrics connection) {
    final compatibilityScore = (connection.currentCompatibility * 100).toInt();
    final compatibilityColor =
        _getCompatibilityColor(connection.currentCompatibility);
    final isFullyCompatible = compatibilityScore == 100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFullyCompatible
            ? BorderSide(
                color: AppColors.electricGreen.withValues(alpha: 0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionHeader(
                connection, compatibilityScore, compatibilityColor),
            const SizedBox(height: 16),
            _buildCompatibilityBar(
                connection.currentCompatibility, compatibilityColor),
            const SizedBox(height: 16),
            _buildLearningMetrics(connection),
            const SizedBox(height: 16),
            _buildCompatibilityExplanation(connection),
            if (isFullyCompatible && widget.showHumanConnectionButton) ...[
              const SizedBox(height: 16),
              _buildHumanConnectionButton(connection),
            ],
            const SizedBox(height: 12),
            _buildFleetingNotice(connection),
            const SizedBox(height: 8),
            _buildPrivacyIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionHeader(
    ConnectionMetrics connection,
    int compatibilityScore,
    Color compatibilityColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.electricGreen,
                AppColors.electricGreen.withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology,
            color: AppColors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Connection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connected ${_formatDuration(connection.connectionDuration)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: compatibilityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: compatibilityColor,
              width: 2,
            ),
          ),
          child: Text(
            '$compatibilityScore%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: compatibilityColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityBar(double vibeAlignment, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Compatibility Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _getCompatibilityLabel(vibeAlignment),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: vibeAlignment,
            minHeight: 10,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningMetrics(ConnectionMetrics connection) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            Icons.swap_horiz,
            '${connection.learningOutcomes['insights_gained'] ?? 0}',
            'Insights',
          ),
          _buildMetricItem(
            Icons.trending_up,
            '${connection.interactionHistory.length}',
            'Exchanges',
          ),
          _buildMetricItem(
            Icons.favorite,
            '${(connection.currentCompatibility * 100).toInt()}',
            'Vibe',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityExplanation(ConnectionMetrics connection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.electricGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Why They\'re Compatible',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _generateCompatibilityReason(connection),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumanConnectionButton(ConnectionMetrics connection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.celebration,
                color: AppColors.electricGreen,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perfect Match!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your AIs are 100% compatible. You can now enable human-to-human conversation.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Enable human to human conversation',
            hint:
                'Turns this AI compatibility into a direct human chat connection.',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _enableHumanConnection(connection),
                icon: const Icon(Icons.people),
                label: const Text('Enable Human Conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetingNotice(ConnectionMetrics connection) {
    return const Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Fleeting connection • Managed by AI • Will disconnect automatically',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyIndicator() {
    return const Row(
      children: [
        Icon(
          Icons.verified_user,
          size: 12,
          color: AppColors.success,
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            'Privacy protected • No personal information shared',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 0.9) return AppColors.electricGreen;
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _getCompatibilityLabel(double score) {
    if (score >= 0.9) return 'Perfect Match';
    if (score >= 0.7) return 'High Compatibility';
    if (score >= 0.5) return 'Moderate Match';
    return 'Low Compatibility';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _generateCompatibilityReason(ConnectionMetrics connection) {
    final score = connection.currentCompatibility;
    final insightsGained =
        connection.learningOutcomes['insights_gained'] as int? ?? 0;

    if (score >= 0.9) {
      return 'Your AIs share exceptional vibe alignment and complementary learning patterns. '
          'They\'ve exchanged $insightsGained insights with high mutual benefit, '
          'creating optimal conditions for cross-personality learning.';
    } else if (score >= 0.7) {
      return 'Your AIs have strong vibe compatibility and aligned interests. '
          'They\'ve shared $insightsGained insights, showing good potential '
          'for meaningful learning exchanges.';
    } else if (score >= 0.5) {
      return 'Your AIs found moderate compatibility through shared learning dimensions. '
          'They\'re exchanging insights to explore potential synergies.';
    } else {
      return 'Your AIs are exploring compatibility through initial exchanges. '
          'Early learning patterns suggest limited alignment, but discoveries are ongoing.';
    }
  }

  void _enableHumanConnection(ConnectionMetrics connection) {
    widget.onEnableHumanConnection?.call(connection);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Human connection enabled! You can now chat.'),
        backgroundColor: AppColors.electricGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  (String, String) _mapConnectionIssue(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission')) {
      return (
        'AI2AI permissions are incomplete.',
        'Grant required Nearby/Bluetooth/Location permissions, then refresh.'
      );
    }
    if (message.contains('offline') || message.contains('network')) {
      return (
        'Network appears offline for AI2AI updates.',
        'Reconnect to internet or nearby transport, then retry.'
      );
    }
    return (
      'Connection metrics failed to refresh.',
      'Retry now. If this keeps failing, reopen AI2AI settings and verify discovery services are enabled.'
    );
  }
}
