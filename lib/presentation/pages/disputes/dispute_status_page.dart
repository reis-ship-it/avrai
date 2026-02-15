import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/disputes/dispute.dart';
import 'package:avrai/core/models/disputes/dispute_status.dart';
import 'package:avrai/core/services/fraud/dispute_resolution_service.dart';
import 'package:avrai/core/services/disputes/dispute_evidence_storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Dispute Status Page
///
/// Agent 2: Phase 5, Week 16-17 - Dispute UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Dispute status display
/// - Timeline of dispute progress
/// - Messages/communication thread
/// - Resolution details (if resolved)
class DisputeStatusPage extends StatefulWidget {
  final String disputeId;

  const DisputeStatusPage({
    super.key,
    required this.disputeId,
  });

  @override
  State<DisputeStatusPage> createState() => _DisputeStatusPageState();
}

class _DisputeStatusPageState extends State<DisputeStatusPage> {
  final DisputeResolutionService _disputeService =
      GetIt.instance<DisputeResolutionService>();
  final DisputeEvidenceStorageService _evidenceStorage =
      GetIt.instance<DisputeEvidenceStorageService>();

  Dispute? _dispute;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dispute = await _disputeService.getDispute(widget.disputeId);
      setState(() {
        _dispute = dispute;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Dispute Status',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: context.spacing.md),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
            SizedBox(height: context.spacing.md),
            ElevatedButton(
              onPressed: _loadDispute,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dispute == null) {
      return const Center(
        child: Text('Dispute not found'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(),
            SizedBox(height: context.spacing.xl),

            // Dispute Details
            _buildDisputeDetails(),
            SizedBox(height: context.spacing.xl),

            // Timeline
            _buildTimeline(),
            SizedBox(height: context.spacing.xl),

            // Messages (if any)
            if (_dispute!.messages.isNotEmpty) ...[
              _buildMessages(),
              SizedBox(height: context.spacing.xl),
            ],

            // Resolution (if resolved)
            if (_dispute!.isResolved) ...[
              _buildResolution(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _dispute!.status;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case DisputeStatus.pending:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
        break;
      case DisputeStatus.inReview:
        statusColor = AppTheme.primaryColor;
        statusIcon = Icons.visibility;
        break;
      case DisputeStatus.waitingResponse:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case DisputeStatus.resolved:
        statusColor = AppColors.electricGreen;
        statusIcon = Icons.check_circle;
        break;
      case DisputeStatus.closed:
        statusColor = AppColors.grey400;
        statusIcon = Icons.close;
        break;
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: statusColor.withValues(alpha: 0.1),
      borderColor: statusColor.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${status.displayName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  _getStatusDescription(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildDisputeDetails() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispute Details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          _buildDetailRow('Type', _dispute!.type.displayName),
          _buildDetailRow('Event ID', _dispute!.eventId),
          _buildDetailRow('Created', _formatDateTime(_dispute!.createdAt)),
          if (_dispute!.assignedAdminId != null)
            _buildDetailRow('Assigned Admin', _dispute!.assignedAdminId!),
          SizedBox(height: context.spacing.md),
          Text(
            'Description',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            _dispute!.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          if (_dispute!.evidenceUrls.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            Text(
              'Evidence',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: context.spacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dispute!.evidenceUrls.map((url) {
                return _buildEvidenceThumb(url);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceThumb(String url) {
    return FutureBuilder<Uri>(
      future: _evidenceStorage.resolveSignedUrl(url),
      builder: (context, snapshot) {
        final resolved = snapshot.data;
        return GestureDetector(
          onTap: resolved == null
              ? null
              : () async {
                  // Open a larger preview (uses a short-lived signed URL).
                  if (!mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          child: Image.network(
                            resolved.toString(),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.grey200,
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(context.spacing.md),
                                child: Text(
                                  'Unable to load image',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
          child: SizedBox(
            width: 80,
            height: 80,
            child: PortalSurface(
              padding: EdgeInsets.zero,
              color: AppColors.grey200,
              borderColor: AppColors.grey300,
              radius: context.radius.sm,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: resolved == null
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Image.network(
                        resolved.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.grey200,
                            child: const Icon(Icons.image,
                                color: AppColors.textSecondary),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          _buildTimelineItem(
            'Dispute Submitted',
            _formatDateTime(_dispute!.createdAt),
            true,
          ),
          if (_dispute!.assignedAt != null)
            _buildTimelineItem(
              'Assigned to Admin',
              _formatDateTime(_dispute!.assignedAt!),
              true,
            ),
          if (_dispute!.resolvedAt != null)
            _buildTimelineItem(
              'Resolved',
              _formatDateTime(_dispute!.resolvedAt!),
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, bool isComplete) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.radius.md,
            backgroundColor:
                isComplete ? AppColors.electricGreen : AppColors.grey400,
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                : null,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildMessages() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          ..._dispute!.messages.map((message) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sm),
              child: PortalSurface(
                padding: EdgeInsets.all(context.spacing.sm),
                color: message.isAdminMessage
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppColors.background,
                borderColor: AppColors.grey300.withValues(alpha: 0.6),
                radius: context.radius.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (message.isAdminMessage)
                          const Icon(Icons.admin_panel_settings,
                              size: 16, color: AppTheme.primaryColor),
                        if (message.isAdminMessage)
                          SizedBox(width: context.spacing.xxs),
                        Text(
                          message.isAdminMessage ? 'Admin' : 'You',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(message.timestamp),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResolution() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.electricGreen),
              SizedBox(width: 8),
              Text(
                'Resolution',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricGreen,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          if (_dispute!.resolution != null) ...[
            Text(
              _dispute!.resolution!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: context.spacing.sm),
          ],
          if (_dispute!.refundAmount != null) ...[
            Text(
              'Refund Amount: \$${_dispute!.refundAmount!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.pending:
        return 'Your dispute has been submitted and is waiting to be reviewed';
      case DisputeStatus.inReview:
        return 'An admin is currently reviewing your dispute';
      case DisputeStatus.waitingResponse:
        return 'We are waiting for additional information';
      case DisputeStatus.resolved:
        return 'Your dispute has been resolved';
      case DisputeStatus.closed:
        return 'This dispute has been closed';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
