import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:flutter/material.dart';

class GovernanceAuditFeedCard extends StatelessWidget {
  const GovernanceAuditFeedCard({
    super.key,
    required this.inspections,
    required this.receipts,
    this.title = 'Governance Audit Feed',
    this.subtitle,
    this.emptyState = 'No governance artifacts recorded yet.',
    this.onOpenPressed,
    this.onInspectionTap,
    this.onBreakGlassTap,
  });

  final List<GovernanceInspectionResponse> inspections;
  final List<BreakGlassGovernanceReceipt> receipts;
  final String title;
  final String? subtitle;
  final String emptyState;
  final VoidCallback? onOpenPressed;
  final ValueChanged<GovernanceInspectionResponse>? onInspectionTap;
  final ValueChanged<BreakGlassGovernanceReceipt>? onBreakGlassTap;

  @override
  Widget build(BuildContext context) {
    final inspectionApprovals =
        inspections.where((item) => item.approved).length;
    final breakGlassApprovals = receipts.where((item) => item.approved).length;
    final hasArtifacts = inspections.isNotEmpty || receipts.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onOpenPressed != null)
                  TextButton.icon(
                    onPressed: onOpenPressed,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  label: 'Inspections',
                  value: '${inspections.length}',
                ),
                _MetricPill(
                  label: 'Inspection approvals',
                  value: '$inspectionApprovals',
                  accent: AppColors.electricGreen,
                ),
                _MetricPill(
                  label: 'Break-glass receipts',
                  value: '${receipts.length}',
                ),
                _MetricPill(
                  label: 'Break-glass approvals',
                  value: '$breakGlassApprovals',
                  accent: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasArtifacts)
              Text(
                emptyState,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else ...[
              _ArtifactSection(
                title: 'Recent inspections',
                icon: Icons.visibility_outlined,
                children: inspections.isEmpty
                    ? <Widget>[
                        const Text('No inspection events yet.'),
                      ]
                    : inspections
                        .map(
                          (item) => _ArtifactTile(
                            leadingIcon: item.approved
                                ? Icons.verified_outlined
                                : Icons.block_outlined,
                            accent: item.approved
                                ? AppColors.electricGreen
                                : AppColors.error,
                            title:
                                '${item.request.targetStratum.name} • ${item.request.targetRuntimeId}',
                            subtitle:
                                '${item.request.visibilityTier.name} • ${_formatLocal(item.respondedAt.serverTime)}',
                            detail: item.failureCodes.isEmpty
                                ? 'approved'
                                : item.failureCodes.join(', '),
                            onTap: onInspectionTap == null
                                ? null
                                : () => onInspectionTap!(item),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              _ArtifactSection(
                title: 'Recent break-glass',
                icon: Icons.gpp_maybe_outlined,
                children: receipts.isEmpty
                    ? <Widget>[
                        const Text('No break-glass directives yet.'),
                      ]
                    : receipts
                        .map(
                          (item) => _ArtifactTile(
                            leadingIcon: item.approved
                                ? Icons.task_alt_outlined
                                : Icons.report_gmailerrorred_outlined,
                            accent: item.approved
                                ? AppColors.warning
                                : AppColors.error,
                            title:
                                '${item.directive.actionType.name} • ${item.directive.targetRuntimeId}',
                            subtitle:
                                '${item.directive.targetStratum.name} • ${_formatLocal(item.evaluatedAt.serverTime)}',
                            detail: item.failureCodes.isEmpty
                                ? item.directive.reasonCode
                                : item.failureCodes.join(', '),
                            onTap: onBreakGlassTap == null
                                ? null
                                : () => onBreakGlassTap!(item),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final background = accent?.withValues(alpha: 0.12) ?? AppColors.grey100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _ArtifactSection extends StatelessWidget {
  const _ArtifactSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  const _ArtifactTile({
    required this.leadingIcon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.detail,
    this.onTap,
  });

  final IconData leadingIcon;
  final Color accent;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(leadingIcon, color: accent),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

String _formatLocal(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
