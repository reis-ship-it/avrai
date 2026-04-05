import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';

class BhamWalkthroughPage extends StatelessWidget {
  const BhamWalkthroughPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: '',
      showNavigationBar: false,
      constrainBody: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'AVRAI works best when you live your life, not when you stay on your phone.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              _WalkthroughCard(
                title: 'Daily Drop',
                body:
                    'Each day, AVRAI gives you a small set of strong doors to explore.',
              ),
              const SizedBox(height: 16),
              _WalkthroughCard(
                title: 'Explore',
                body:
                    'Browse Birmingham through spots, lists, events, clubs, and communities.',
              ),
              const SizedBox(height: 16),
              _WalkthroughCard(
                title: 'AI2AI',
                body:
                    'Nearby AVRAI agents can learn from each other without needing the internet.',
              ),
              const SizedBox(height: 16),
              _WalkthroughCard(
                title: 'Your agent',
                body:
                    'Your personal agent keeps learning from your real behavior and helps you find what fits.',
              ),
              const SizedBox(height: 16),
              _WalkthroughCard(
                title: 'Privacy',
                body:
                    'Your private human identity stays protected. Admin sees agent-level learning, not your direct personal identity by default.',
              ),
              const Spacer(),
              AppButtonPrimary(
                onPressed: () => context.go('/home'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Open your Birmingham Daily Drop'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkthroughCard extends StatelessWidget {
  final String title;
  final String body;

  const _WalkthroughCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
