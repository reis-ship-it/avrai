/// Welcome Page
///
/// First screen in onboarding flow. Simple centered greeting.
/// Tap anywhere to proceed to the next step.
library;

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;

  const WelcomePage({
    super.key,
    this.onContinue,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onContinue,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              AppColors.grey50.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 16,
                child: onSkip == null
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Hi, tell me\nabout yourself',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
