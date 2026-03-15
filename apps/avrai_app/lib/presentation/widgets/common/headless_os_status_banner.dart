import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';

class HeadlessOsStatusBanner extends StatefulWidget {
  const HeadlessOsStatusBanner({
    super.key,
    this.service,
  });

  final HeadlessAvraiOsAvailabilityService? service;

  @override
  State<HeadlessOsStatusBanner> createState() => _HeadlessOsStatusBannerState();
}

class _HeadlessOsStatusBannerState extends State<HeadlessOsStatusBanner> {
  Stream<HeadlessAvraiOsAvailabilitySnapshot>? _availabilityStream;

  @override
  void initState() {
    super.initState();
    final service = widget.service ?? _resolveService();
    if (service != null) {
      _availabilityStream = service.watchAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _availabilityStream;
    if (stream == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<HeadlessAvraiOsAvailabilitySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final availability = snapshot.data;
        if (availability == null) {
          return const SizedBox.shrink();
        }

        final color = availability.liveReady
            ? AppColors.success
            : availability.restoredReady
                ? AppTheme.primaryColor
                : AppColors.warning;
        final icon = availability.liveReady
            ? Icons.memory
            : availability.restoredReady
                ? Icons.restore
                : Icons.sync_problem;
        final detail = availability.available
            ? '${availability.kernelCount} kernels'
            : 'boot pending';

        return Container(
          key: const Key('headless_os_status_banner'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    availability.summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    availability.localityContainedInWhere
                        ? '$detail • locality in where'
                        : detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  HeadlessAvraiOsAvailabilityService? _resolveService() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<HeadlessAvraiOsAvailabilityService>()) {
      return null;
    }
    return getIt<HeadlessAvraiOsAvailabilityService>();
  }
}
