import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated && state.isOffline) {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpaceXs, vertical: kSpaceXxs),
            decoration: BoxDecoration(
              color: AppTheme.offlineColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.offlineColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 14,
                  color: AppTheme.offlineColor,
                ),
                SizedBox(width: 4),
                Text(
                  'Offline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.offlineColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
