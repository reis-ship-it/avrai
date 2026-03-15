import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/theme/colors.dart';
import 'package:flutter/material.dart';

class AdminDesktopHandoffPage extends StatelessWidget {
  const AdminDesktopHandoffPage({
    super.key,
    this.requestedSurfaceTitle = 'Admin Console',
    this.requestedPath,
  });

  final String requestedSurfaceTitle;
  final String? requestedPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AppFlowScaffold(
      title: requestedSurfaceTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin surfaces now live in the standalone AVRAI Admin desktop app.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The consumer app no longer carries embedded admin UI. '
            'Use the desktop-only admin app on macOS, Windows, or Linux, '
            'then sign in with an authorized admin account.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _HandoffCard(
            title: 'What To Do',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _StepRow(
                  index: 1,
                  text: 'Open the standalone AVRAI Admin desktop app.',
                ),
                SizedBox(height: 12),
                _StepRow(
                  index: 2,
                  text: 'Authenticate with your internal admin account.',
                ),
                SizedBox(height: 12),
                _StepRow(
                  index: 3,
                  text: 'Navigate to the requested admin surface there.',
                ),
              ],
            ),
          ),
          if (requestedPath != null) ...[
            const SizedBox(height: 16),
            _HandoffCard(
              title: 'Requested Route',
              child: SelectableText(
                requestedPath!,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HandoffCard extends StatelessWidget {
  const _HandoffCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Text(
                '$index',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
