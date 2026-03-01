/// Welcome Page
///
/// First screen in onboarding flow with welcoming animated text.
/// Displays "Hi, tell me about yourself" with bubbly floating letters.
///
/// Features:
/// - Full-screen centered layout
/// - Floating text animation
/// - Tap anywhere to continue
/// - Subtle gradient background
/// - Skip button for returning users
///
/// Design inspired by Apple onboarding vibe but with SPOTS minimalist aesthetic.
library;

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/onboarding/floating_text_widget.dart';

class WelcomePage extends StatefulWidget {
  /// Callback when user taps to continue
  final VoidCallback? onContinue;

  /// Callback when user taps skip
  final VoidCallback? onSkip;

  const WelcomePage({
    super.key,
    this.onContinue,
    this.onSkip,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _initFadeAnimation();
  }

  void _initFadeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _handleTapContinue() {
    if (_isExiting) return;

    setState(() {
      _isExiting = true;
    });

    // Fade out animation
    _fadeController.forward().then((_) {
      if (mounted) {
        widget.onContinue?.call();
      }
    });
  }

  void _handleSkip() {
    if (_isExiting) return;
    widget.onSkip?.call();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Welcome',
      showNavigationBar: false,
      constrainBody: false,
      backgroundColor: AppColors.transparent,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: _handleTapContinue,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                  AppColors.grey50.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: AdaptivePageScaffold(
              useSafeArea: false,
              child: Stack(
                children: [
                  Positioned(
                    top: spacing.sm,
                    right: spacing.sm,
                    child: Semantics(
                      button: true,
                      label: 'Skip welcome screen',
                      child: TextButton(
                        onPressed: _handleSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radius.md),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.md,
                            vertical: spacing.xs,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        Semantics(
                          header: true,
                          label: 'Hi, tell me about yourself',
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: spacing.xl),
                            child: const FloatingTextWidget(
                              text: 'Hi, tell me\nabout yourself',
                              textStyle: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.4,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        Semantics(
                          hint: 'Tap anywhere to continue',
                          child: Padding(
                            padding: EdgeInsets.only(bottom: spacing.xxl),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                ),
                                SizedBox(height: 8),
                                PulsingHintWidget(
                                  text: 'Tap to continue',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
