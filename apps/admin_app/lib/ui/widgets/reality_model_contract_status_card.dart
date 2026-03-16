import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class RealityModelContractStatusCard extends StatefulWidget {
  const RealityModelContractStatusCard({
    super.key,
    required this.surfaceLabel,
    this.service,
    this.refreshSeed = 0,
  });

  final String surfaceLabel;
  final RealityModelStatusService? service;
  final int refreshSeed;

  @override
  State<RealityModelContractStatusCard> createState() =>
      _RealityModelContractStatusCardState();
}

class _RealityModelContractStatusCardState
    extends State<RealityModelContractStatusCard> {
  late Future<RealityModelStatusSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant RealityModelContractStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _future = _load();
    }
  }

  Future<RealityModelStatusSnapshot> _load() {
    final service = widget.service ??
        (GetIt.instance.isRegistered<RealityModelStatusService>()
            ? GetIt.instance<RealityModelStatusService>()
            : RealityModelStatusService());
    return service.loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RealityModelStatusSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Loading active reality-model contract...'),
                  ),
                ],
              ),
            ),
          );
        }

        final status = snapshot.data ??
            RealityModelStatusSnapshot(
              loadedAtUtc: DateTime.now().toUtc(),
              available: false,
              summary: 'Reality-model contract unavailable.',
              errorMessage: snapshot.error?.toString(),
            );
        final iconColor = status.available
            ? (status.isKernelBacked
                ? AppColors.electricGreen
                : AppColors.warning)
            : AppColors.error;
        final contract = status.contract;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.model_training_outlined, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Reality Model Contract',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.surfaceLabel} is reading from the active reality-model boundary, not an ad hoc page-local contract.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  status.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('Mode', status.modeLabel),
                    _statusChip('Boundary', status.boundaryLabel),
                    _statusChip('Uncertainty', status.uncertaintyLabel),
                    if (contract != null)
                      _statusChip(
                          'Evidence cap', '${contract.maxEvidenceRefs}'),
                    if (contract != null)
                      _statusChip(
                        'Follow-up',
                        contract.followUpQuestionsAllowed ? 'Allowed' : 'Off',
                      ),
                  ],
                ),
                if (contract != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Contract: ${contract.contractId} (${contract.version})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported domains: ${status.supportedDomainLabels.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renderers: ${status.rendererLabels.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (status.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    status.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
