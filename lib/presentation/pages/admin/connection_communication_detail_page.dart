import 'package:flutter/material.dart';
import 'package:avrai/core/services/admin/admin_communication_service.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart'
    hide ChatMessage;
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Admin page showing detailed communication log between two AIs
class ConnectionCommunicationDetailPage extends StatefulWidget {
  final String connectionId;

  const ConnectionCommunicationDetailPage({
    super.key,
    required this.connectionId,
  });

  @override
  State<ConnectionCommunicationDetailPage> createState() =>
      _ConnectionCommunicationDetailPageState();
}

class _ConnectionCommunicationDetailPageState
    extends State<ConnectionCommunicationDetailPage> {
  AdminCommunicationService? _communicationService;
  ConnectionCommunicationLog? _log;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadCommunicationLog();
  }

  Future<void> _initializeService() async {
    try {
      final prefs = GetIt.instance<SharedPreferencesCompat>();
      final connectionMonitor = ConnectionMonitor(prefs: prefs);
      // Try to get AI2AIChatAnalyzer from GetIt if available
      AI2AIChatAnalyzer? chatAnalyzer;
      try {
        // Note: This assumes AI2AIChatAnalyzer is registered in GetIt
        // If not, it will be null and chat history won't be available
        chatAnalyzer = GetIt.instance<AI2AIChatAnalyzer>();
      } catch (e) {
        // Not registered, continue without chat analyzer
        chatAnalyzer = null;
      }

      _communicationService = AdminCommunicationService(
        connectionMonitor: connectionMonitor,
        chatAnalyzer: chatAnalyzer,
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommunicationLog() async {
    if (_communicationService == null) {
      await _initializeService();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final log =
          await _communicationService!.getConnectionLog(widget.connectionId);
      setState(() {
        _log = log;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load communication log: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title:
          'Connection: ${widget.connectionId.length > 12 ? widget.connectionId.substring(0, 12) : widget.connectionId}',
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadCommunicationLog,
          tooltip: 'Refresh',
        ),
      ],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      SizedBox(height: context.spacing.md),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      ElevatedButton(
                        onPressed: _loadCommunicationLog,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _log == null
                  ? Center(child: Text('No communication log found'))
                  : RefreshIndicator(
                      onRefresh: _loadCommunicationLog,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(context.spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConnectionHeader(context),
                            SizedBox(height: context.spacing.xl),
                            _buildMetricsSection(context),
                            SizedBox(height: context.spacing.xl),
                            _buildChatHistorySection(context),
                            SizedBox(height: context.spacing.xl),
                            _buildInteractionHistorySection(context),
                            SizedBox(height: context.spacing.xl),
                            _buildAlertsSection(context),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildConnectionHeader(BuildContext context) {
    if (_log == null) return const SizedBox.shrink();

    return PortalSurface(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: context.spacing.sm),
            _buildInfoRow('Local AI', _log!.localAISignature),
            _buildInfoRow('Remote AI', _log!.remoteAISignature),
            _buildInfoRow('Started',
                DateFormat('MMM d, y HH:mm:ss').format(_log!.startTime)),
            _buildInfoRow('Duration', _formatDuration(_log!.duration)),
            _buildInfoRow('Health Score',
                '${(_log!.healthScore * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context) {
    if (_log == null) return const SizedBox.shrink();

    return PortalSurface(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: context.spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                    'Messages', '${_log!.totalMessages}', Icons.message),
                _buildMetricCard('Interactions',
                    '${_log!.interactionHistory.length}', Icons.swap_horiz),
                _buildMetricCard('Chat Events', '${_log!.chatEvents.length}',
                    Icons.chat_bubble_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryColor),
        SizedBox(height: context.spacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildChatHistorySection(BuildContext context) {
    if (_log == null || _log!.chatEvents.isEmpty) {
      return PortalSurface(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: context.spacing.xs),
              Text(
                'No chat history available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: context.spacing.xxs),
              Text(
                'Chat conversations will appear here when AIs communicate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return PortalSurface(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text('${_log!.chatEvents.length} events'),
                  backgroundColor: AppColors.grey100,
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            ..._log!.chatEvents
                .map((event) => _buildChatEventCard(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatEventCard(BuildContext context, AI2AIChatEvent event) {
    return PortalSurface(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      color: AppColors.grey50,
      child: ExpansionTile(
        title: Text(
          'Chat Event: ${event.messageType.name}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${event.messages.length} messages • ${DateFormat('MMM d, HH:mm').format(event.timestamp)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Event ID', event.eventId),
                _buildInfoRow('Participants', event.participants.join(', ')),
                _buildInfoRow('Duration', _formatDuration(event.duration)),
                SizedBox(height: context.spacing.sm),
                const Divider(),
                SizedBox(height: context.spacing.xs),
                Text(
                  'Messages',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: context.spacing.xs),
                ...event.messages
                    .map((message) => _buildMessageBubble(context, message)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isLocal = message.senderId == _log!.localAISignature;

    return PortalSurface(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      padding: EdgeInsets.all(context.spacing.sm),
      color: isLocal
          ? AppTheme.primaryColor.withValues(alpha: 0.1)
          : AppColors.grey100,
      borderColor: (isLocal ? AppTheme.primaryColor : AppColors.grey300)
          .withValues(alpha: 0.25),
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLocal ? 'Local AI' : 'Remote AI',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLocal
                          ? AppTheme.primaryColor
                          : AppColors.textSecondary,
                    ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(message.timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (message.context.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs),
            Text(
              'Context: ${message.context.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionHistorySection(BuildContext context) {
    if (_log == null || _log!.interactionHistory.isEmpty) {
      return PortalSurface(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            children: [
              const Icon(Icons.swap_horiz,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: context.spacing.xs),
              Text(
                'No interaction history',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return PortalSurface(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interaction History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: context.spacing.sm),
            ..._log!.interactionHistory.map(
                (interaction) => _buildInteractionTile(context, interaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionTile(
      BuildContext context, InteractionEvent interaction) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: context.spacing.xxs),
      leading: Icon(
        _getInteractionIcon(interaction.type),
        color: AppTheme.primaryColor,
      ),
      title: Text(interaction.type.name),
      subtitle: Text(
        DateFormat('MMM d, HH:mm:ss').format(interaction.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: interaction.successful
          ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          : const Icon(Icons.error, color: AppColors.error, size: 20),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    if (_log == null || _log!.recentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return PortalSurface(
      elevation: 2,
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning),
                SizedBox(width: context.spacing.xs),
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            ..._log!.recentAlerts
                .map((alert) => _buildAlertTile(context, alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, ConnectionAlert alert) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: context.spacing.xxs),
      leading: Icon(
        _getAlertIcon(alert.severity),
        color: _getAlertColor(alert.severity),
      ),
      title: Text(alert.message),
      subtitle: Text(
        '${alert.type.name} • ${DateFormat('MMM d, HH:mm').format(alert.timestamp)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  IconData _getInteractionIcon(InteractionType type) {
    switch (type) {
      case InteractionType.vibeExchange:
        return Icons.swap_horiz;
      case InteractionType.personalitySharing:
        return Icons.person;
      case InteractionType.learningInsight:
        return Icons.lightbulb;
      case InteractionType.dimensionEvolution:
        return Icons.trending_up;
      case InteractionType.patternDiscovery:
        return Icons.auto_awesome;
      case InteractionType.trustBuilding:
        return Icons.handshake;
      case InteractionType.feedbackSharing:
        return Icons.feedback;
      default:
        return Icons.info;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.high:
        return Icons.warning;
      case AlertSeverity.medium:
        return Icons.info;
      case AlertSeverity.low:
        return Icons.info_outline;
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.high:
        return AppColors.warning;
      case AlertSeverity.medium:
        return AppColors.grey600;
      case AlertSeverity.low:
        return AppColors.textSecondary;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
