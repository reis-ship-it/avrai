import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Dedicated onboarding page for cross-app learning
///
/// Explains the value proposition of cross-app learning and
/// allows users to enable/disable data sources.
///
/// Features:
/// - Clear value proposition
/// - Visual examples of insights
/// - Per-source toggles with explanations
/// - Privacy reassurance
/// - Skip option (opt-out friendly)
class CrossAppLearningPage extends StatefulWidget {
  /// Callback when user proceeds
  final VoidCallback? onProceed;

  /// Callback when user skips
  final VoidCallback? onSkip;

  const CrossAppLearningPage({
    super.key,
    this.onProceed,
    this.onSkip,
  });

  @override
  State<CrossAppLearningPage> createState() => _CrossAppLearningPageState();
}

class _CrossAppLearningPageState extends State<CrossAppLearningPage> {
  late CrossAppConsentService _consentService;
  Map<CrossAppDataSource, bool> _consents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _consentService = di.sl<CrossAppConsentService>();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    final consents = await _consentService.getAllConsents();
    if (mounted) {
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggle(CrossAppDataSource source, bool enabled) async {
    setState(() {
      _consents[source] = enabled;
    });
    await _consentService.setEnabled(source, enabled);
  }

  Future<void> _enableAll() async {
    await _consentService.enableAll();
    await _loadConsents();
  }

  Future<void> _handleProceed() async {
    await _consentService.completeOnboarding();
    widget.onProceed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.spacing;

    return AdaptivePlatformPageScaffold(
      title: 'Cross-App Learning',
      backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
      actions: [
        TextButton(
          onPressed: () async {
            await _consentService.completeOnboarding();
            widget.onSkip?.call();
          },
          child: Text(
            'Skip',
            style: TextStyle(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.6)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: spacing.lg),

                        // Title
                        Text(
                          'Make Recommendations\nMore Relevant',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            color: isDark
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: spacing.md),

                        // Subtitle
                        Text(
                          'Choose which signals AVRAI can use to make suggestions feel more useful, timely, and under your control.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: spacing.xl),

                        // Example insights
                        _buildExampleInsights(isDark, textTheme),
                        SizedBox(height: spacing.xl),

                        // Data source toggles
                        _buildDataSourceToggles(isDark, textTheme),
                        SizedBox(height: spacing.lg),

                        // Privacy note
                        _buildPrivacyNote(isDark, textTheme),
                        SizedBox(height: spacing.xl),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    children: [
                      // Enable all & proceed
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _enableAll();
                            await _handleProceed();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: spacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(context.radius.md),
                            ),
                          ),
                          child: const Text(
                            'Enable Recommended Sources',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      // Proceed with current settings
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _handleProceed,
                          child: Text(
                            'Continue with current choices',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.white.withValues(alpha: 0.6)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExampleInsights(bool isDark, TextTheme textTheme) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      radius: 16,
      color: isDark
          ? AppColors.white.withValues(alpha: 0.08)
          : AppColors.black.withValues(alpha: 0.04),
      borderColor: isDark
          ? AppColors.white.withValues(alpha: 0.12)
          : AppColors.black.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How this helps',
                style: textTheme.titleSmall?.copyWith(
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildExampleItem(
            Icons.schedule_outlined,
            'If your schedule opens up, AVRAI can surface timely plans nearby.',
            isDark,
            textTheme,
          ),
          _buildExampleItem(
            Icons.favorite_border,
            'Activity patterns can help AVRAI suggest places that fit the moment.',
            isDark,
            textTheme,
          ),
          _buildExampleItem(
            Icons.music_note_outlined,
            'Preference signals help recommendations feel calmer and more personal.',
            isDark,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(
    IconData icon,
    String text,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceToggles(bool isDark, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose data sources',
          style: textTheme.titleSmall?.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...CrossAppDataSource.values.map((source) {
          // Skip app usage on iOS
          if (source == CrossAppDataSource.appUsage && !Platform.isAndroid) {
            return const SizedBox.shrink();
          }
          return _buildSourceToggle(source, isDark, textTheme);
        }),
      ],
    );
  }

  Widget _buildSourceToggle(
    CrossAppDataSource source,
    bool isDark,
    TextTheme textTheme,
  ) {
    final isEnabled = _consents[source] ?? true;

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 12,
      color: isDark
          ? AppColors.white.withValues(alpha: 0.08)
          : AppColors.black.withValues(alpha: 0.04),
      borderColor: isEnabled
          ? AppColors.primary.withValues(alpha: 0.3)
          : (isDark
              ? AppColors.white.withValues(alpha: 0.12)
              : AppColors.black.withValues(alpha: 0.08)),
      child: Row(
        children: [
          Text(source.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  source.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.54)
                        : AppColors.grey600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) => _handleToggle(source, value),
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote(bool isDark, TextTheme textTheme) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      radius: 12,
      color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.06),
      borderColor: AppColors.primary.withValues(alpha: 0.18),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 24,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by default',
                  style: textTheme.titleSmall?.copyWith(
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can change these sources any time, and AVRAI keeps the focus on local processing and user control.',
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.6)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
