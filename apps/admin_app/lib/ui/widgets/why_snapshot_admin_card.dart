import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:flutter/material.dart';

class WhySnapshotAdminCard extends StatelessWidget {
  const WhySnapshotAdminCard({
    super.key,
    required this.snapshot,
    this.title = 'Why Explanation',
  });

  final WhySnapshot snapshot;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _chip(
                'schema ${snapshot.schemaVersion}',
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.summary,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'root ${snapshot.rootCauseType.toWireValue()}',
                backgroundColor: AppColors.selection.withValues(alpha: 0.12),
                foregroundColor: AppColors.selection,
              ),
              _chip(
                'confidence ${_formatScore(snapshot.confidence)}',
                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                foregroundColor: AppColors.success,
              ),
              _chip(
                'ambiguity ${_formatScore(snapshot.ambiguity)}',
                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                foregroundColor: AppColors.warning,
              ),
              _chip(
                'query ${snapshot.queryKind.toWireValue()}',
                backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                foregroundColor: AppColors.textSecondary,
              ),
            ],
          ),
          if (snapshot.primaryHypothesis != null) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Primary Hypothesis'),
            const SizedBox(height: 4),
            Text(snapshot.primaryHypothesis!.label),
          ],
          if (snapshot.drivers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Drivers'),
            const SizedBox(height: 4),
            ...snapshot.drivers.map(_signalLine),
          ],
          if (snapshot.inhibitors.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Inhibitors'),
            const SizedBox(height: 4),
            ...snapshot.inhibitors.map(_signalLine),
          ],
          if (snapshot.conflicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Conflicts'),
            const SizedBox(height: 4),
            ...snapshot.conflicts.map(
              (conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${conflict.label}: ${conflict.message}'),
              ),
            ),
          ],
          if (snapshot.traceRefs.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Trace Refs'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.traceRefs
                  .map(
                    (trace) => _chip(
                      '${trace.kernel.toWireValue()}:${trace.eventId ?? trace.traceType}',
                      backgroundColor:
                          AppColors.surfaceMuted.withValues(alpha: 0.9),
                      foregroundColor: AppColors.textPrimary,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (snapshot.counterfactuals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Counterfactuals'),
            const SizedBox(height: 4),
            ...snapshot.counterfactuals.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.condition} -> ${entry.expectedEffect} (${_formatSignedScore(entry.confidenceDelta)})',
                ),
              ),
            ),
          ],
          if (snapshot.governanceEnvelope.policyRefs.isNotEmpty ||
              snapshot.governanceEnvelope.escalationThresholds.isNotEmpty ||
              snapshot.governanceEnvelope.redacted) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Governance Envelope'),
            const SizedBox(height: 4),
            if (snapshot.governanceEnvelope.redacted)
              Text(
                'Redacted: ${snapshot.governanceEnvelope.redactionReason ?? 'unknown'}',
              ),
            if (snapshot.governanceEnvelope.policyRefs.isNotEmpty)
              Text(
                'Policy refs: ${snapshot.governanceEnvelope.policyRefs.join(', ')}',
              ),
            if (snapshot.governanceEnvelope.escalationThresholds.isNotEmpty)
              Text(
                'Escalation thresholds: ${snapshot.governanceEnvelope.escalationThresholds.join(', ')}',
              ),
          ],
          if (snapshot.validationIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle(context, 'Validation'),
            const SizedBox(height: 4),
            ...snapshot.validationIssues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${issue.severity.toWireValue()}: ${issue.code} (${issue.message})',
                  style: textTheme.bodySmall?.copyWith(
                    color: issue.severity == WhyValidationSeverity.error
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String value) {
    return Text(
      value,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _signalLine(WhySignal signal) {
    final kernelLabel = signal.kernel?.toWireValue() ?? 'unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${signal.label} (${_formatScore(signal.weight)}) [$kernelLabel]',
      ),
    );
  }

  Widget _chip(
    String label, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: backgroundColor,
      side: BorderSide(color: foregroundColor.withValues(alpha: 0.24)),
      labelStyle: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatScore(double value) => value.toStringAsFixed(2);

  String _formatSignedScore(double value) {
    final normalized = value.toStringAsFixed(2);
    return value > 0 ? '+$normalized' : normalized;
  }
}
