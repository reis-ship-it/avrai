import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/theme/colors.dart';

import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_app_learning_insight_service.dart';
import 'package:avrai/presentation/widgets/settings/cross_app_learning_insights_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/injection_container.dart' as di;

/// Settings page for managing cross-app tracking consent
///
/// Allows users to enable/disable learning from:
/// - Calendar events
/// - Health & Fitness data
/// - Music/Media now playing
/// - App Usage (Android only)
///
/// Implements opt-out model per avrai privacy philosophy.
class CrossAppSettingsPage extends StatefulWidget {
  const CrossAppSettingsPage({super.key});

  @override
  State<CrossAppSettingsPage> createState() => _CrossAppSettingsPageState();
}

class _CrossAppSettingsPageState extends State<CrossAppSettingsPage> {
  late CrossAppConsentService _consentService;
  CrossAppLearningInsightService? _insightService;
  Map<CrossAppDataSource, bool> _consents = {};
  bool _isLoading = true;
  bool _isLearningPaused = false;

  @override
  void initState() {
    super.initState();
    _consentService = di.sl<CrossAppConsentService>();
    if (di.sl.isRegistered<CrossAppLearningInsightService>()) {
      _insightService = di.sl<CrossAppLearningInsightService>();
    }
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    final consents = await _consentService.getAllConsents();
    final isPaused = await _consentService.isLearningPaused();
    if (mounted) {
      setState(() {
        _consents = consents;
        _isLearningPaused = isPaused;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdaptivePlatformPageScaffold(
      title: 'AI Learning Sources',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header explanation
                  _buildHeader(isDark),
                  const SizedBox(height: 24),

                  // Data source toggles
                  _buildDataSourceSection(isDark),
                  const SizedBox(height: 24),

                  // Learning insights display
                  const CrossAppLearningInsightsWidget(),
                  const SizedBox(height: 24),

                  // Privacy note
                  _buildPrivacyNote(isDark),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(isDark),
                  const SizedBox(height: 24),

                  // Data management
                  _buildDataManagementSection(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildDataManagementSection(bool isDark) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Management',
          style: textTheme.titleMedium?.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Pause/Resume Learning Toggle
        PortalSurface(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          radius: 12,
          color: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.black.withValues(alpha: 0.04),
          borderColor: isDark
              ? AppColors.white.withValues(alpha: 0.12)
              : AppColors.black.withValues(alpha: 0.08),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLearningPaused
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isLearningPaused ? Icons.pause_circle : Icons.play_circle,
                color:
                    _isLearningPaused ? AppColors.warning : AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              _isLearningPaused ? 'Learning Paused' : 'Learning Active',
              style: textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _isLearningPaused
                  ? 'Tap to resume data collection'
                  : 'Temporarily pause without deleting data',
              style: textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Switch.adaptive(
              value: !_isLearningPaused,
              onChanged: (active) async {
                if (active) {
                  await _consentService.resumeLearning();
                  _insightService?.resumeLearning();
                } else {
                  await _consentService.pauseLearning();
                  _insightService?.pauseLearning();
                }
                setState(() {
                  _isLearningPaused = !active;
                });
              },
              activeTrackColor: AppColors.primary,
            ),
          ),
        ),

        // Clear Learning Data Button
        PortalSurface(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          radius: 12,
          color: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.black.withValues(alpha: 0.04),
          borderColor: AppColors.error.withValues(alpha: 0.2),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            title: Text(
              'Clear All Learning Data',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Delete all insights learned from your apps',
              style: textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
            onTap: () => _showClearDataDialog(isDark),
          ),
        ),

        // Clear Before Date Button
        PortalSurface(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          radius: 12,
          color: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.black.withValues(alpha: 0.04),
          borderColor: AppColors.warning.withValues(alpha: 0.2),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.date_range,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            title: Text(
              'Clear Before Date',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Delete insights learned before a specific date',
              style: textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.warning),
            onTap: () => _showClearBeforeDateDialog(isDark),
          ),
        ),
      ],
    );
  }

  Future<void> _showClearDataDialog(bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.grey800 : AppColors.white,
        title: Text(
          'Clear Learning Data?',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will delete all insights your AI has learned from calendar, health, music, and app usage data.\n\n'
          'Your spot recommendations may be less personalized until the AI learns your preferences again.',
          style: TextStyle(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _insightService?.clearAllInsights();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Learning data cleared'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showClearBeforeDateDialog(bool isDark) async {
    final textTheme = Theme.of(context).textTheme;
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 30));
    int previewCount =
        _insightService?.getInsightCountBeforeDate(selectedDate) ?? 0;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.grey800 : AppColors.white,
            title: Text(
              'Clear Data Before Date',
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete all insights learned before the selected date. Insights on or after this date will be kept.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Date selector
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: AppColors.white,
                              surface:
                                  isDark ? AppColors.grey800 : AppColors.white,
                              onSurface: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                        previewCount = _insightService
                                ?.getInsightCountBeforeDate(selectedDate) ??
                            0;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.1)
                          : AppColors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear before:',
                              style: textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.white.withValues(alpha: 0.54)
                                    : AppColors.grey600,
                              ),
                            ),
                            Text(
                              _formatDate(selectedDate),
                              style: textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.edit,
                          color: isDark
                              ? AppColors.white.withValues(alpha: 0.54)
                              : AppColors.grey600,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Preview count
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: previewCount > 0
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        previewCount > 0
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: previewCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          previewCount > 0
                              ? '$previewCount insight${previewCount == 1 ? '' : 's'} will be deleted'
                              : 'No insights to delete before this date',
                          style: textTheme.bodySmall?.copyWith(
                            color: previewCount > 0
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.6)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: previewCount > 0
                    ? () => Navigator.of(context).pop(selectedDate)
                    : null,
                style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                child: const Text('Clear Data'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final clearedCount =
          await _insightService?.clearInsightsBeforeDate(result) ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cleared $clearedCount insight${clearedCount == 1 ? '' : 's'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildHeader(bool isDark) {
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      padding: const EdgeInsets.all(16),
      radius: 12,
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
              const Icon(
                Icons.psychology_outlined,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Help Your AI Learn',
                style: textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI can learn from your daily activities to give you better spot suggestions. All data is processed locally on your device.',
            style: textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceSection(bool isDark) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Sources',
          style: textTheme.titleMedium?.copyWith(
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
          return _buildDataSourceTile(source, isDark);
        }),
      ],
    );
  }

  Widget _buildDataSourceTile(CrossAppDataSource source, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = _consents[source] ?? true;

    return PortalSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      radius: 12,
      color: isDark
          ? AppColors.white.withValues(alpha: 0.08)
          : AppColors.black.withValues(alpha: 0.04),
      borderColor: isEnabled
          ? AppColors.primary.withValues(alpha: 0.3)
          : (isDark
              ? AppColors.white.withValues(alpha: 0.12)
              : AppColors.black.withValues(alpha: 0.08)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.1)
                : (isDark ? AppColors.grey800 : AppColors.grey200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              source.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          source.displayName,
          style: textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          source.description,
          style: textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.6)
                : AppColors.textSecondary,
          ),
        ),
        trailing: Switch.adaptive(
          value: isEnabled,
          onChanged: (value) => _handleToggle(source, value),
          activeTrackColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPrivacyNote(bool isDark) {
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      padding: const EdgeInsets.all(16),
      radius: 12,
      color: isDark
          ? AppColors.electricBlue.withValues(alpha: 0.1)
          : AppColors.electricBlue.withValues(alpha: 0.05),
      borderColor: AppColors.electricBlue.withValues(alpha: 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.electricBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All data is processed locally on your device. We never send your calendar, health, music, or app usage data to our servers.',
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

  Widget _buildQuickActions(bool isDark) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _consentService.enableAll();
                  await _loadConsents();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Enable All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _consentService.disableAll();
                  await _loadConsents();
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Disable All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.white.withValues(alpha: 0.6)
                      : AppColors.textSecondary,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.3)
                        : AppColors.grey400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
