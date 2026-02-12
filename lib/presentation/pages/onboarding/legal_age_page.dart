import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

import 'package:url_launcher/url_launcher.dart';

/// Step 1: Legal & Age verification page.
///
/// Collects:
/// - Birthday (validates 18+)
/// - Terms of Service acceptance
/// - Privacy Policy acceptance
class LegalAgePage extends StatefulWidget {
  /// Currently selected birthday (if any)
  final DateTime? initialBirthday;

  /// Whether ToS is already accepted
  final bool initialTosAccepted;

  /// Whether Privacy Policy is already accepted
  final bool initialPrivacyAccepted;

  /// Callback when birthday changes
  final ValueChanged<DateTime?> onBirthdayChanged;

  /// Callback when ToS acceptance changes
  final ValueChanged<bool> onTosAcceptedChanged;

  /// Callback when Privacy acceptance changes
  final ValueChanged<bool> onPrivacyAcceptedChanged;

  const LegalAgePage({
    super.key,
    this.initialBirthday,
    this.initialTosAccepted = false,
    this.initialPrivacyAccepted = false,
    required this.onBirthdayChanged,
    required this.onTosAcceptedChanged,
    required this.onPrivacyAcceptedChanged,
  });

  @override
  State<LegalAgePage> createState() => _LegalAgePageState();
}

class _LegalAgePageState extends State<LegalAgePage> {
  late DateTime? _selectedBirthday;
  late bool _tosAccepted;
  late bool _privacyAccepted;

  bool get _isAgeValid {
    if (_selectedBirthday == null) return false;
    final now = DateTime.now();
    final age = now.year - _selectedBirthday!.year;
    final birthdayThisYear = DateTime(
      now.year,
      _selectedBirthday!.month,
      _selectedBirthday!.day,
    );
    return age > 18 || (age == 18 && !birthdayThisYear.isAfter(now));
  }

  int? get _calculatedAge {
    if (_selectedBirthday == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedBirthday!.year;
    final birthdayThisYear = DateTime(
      now.year,
      _selectedBirthday!.month,
      _selectedBirthday!.day,
    );
    if (birthdayThisYear.isAfter(now)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _selectedBirthday = widget.initialBirthday;
    _tosAccepted = widget.initialTosAccepted;
    _privacyAccepted = widget.initialPrivacyAccepted;
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? eighteenYearsAgo,
      firstDate: hundredYearsAgo,
      lastDate: now,
      helpText: 'Select your birthday',
      fieldLabelText: 'Birthday',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthday = picked;
      });
      widget.onBirthdayChanged(picked);
    }
  }

  Future<void> _openTermsOfService() async {
    const url = 'https://avrai.com/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://avrai.com/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Welcome to avrai',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's get you set up. First, we need to verify a few things.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Birthday Section
          Text(
            'Your Birthday',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You must be 18 or older to use avrai.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Birthday Picker Button
          InkWell(
            onTap: _selectBirthday,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedBirthday != null
                      ? (_isAgeValid ? AppColors.success : AppColors.error)
                      : AppColors.grey300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    color: _selectedBirthday != null
                        ? (_isAgeValid ? AppColors.success : AppColors.error)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBirthday != null
                              ? _formatDate(_selectedBirthday!)
                              : 'Select your birthday',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedBirthday != null
                                ? null
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (_calculatedAge != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$_calculatedAge years old',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _isAgeValid
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Age validation message
          if (_selectedBirthday != null && !_isAgeValid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You must be at least 18 years old to use avrai.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),

          // Legal Agreements Section
          Text(
            'Legal Agreements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review and accept our terms to continue.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Terms of Service
          _buildAgreementTile(
            context: context,
            title: 'Terms of Service',
            subtitle: 'Rules for using avrai',
            isAccepted: _tosAccepted,
            onTap: () {
              setState(() {
                _tosAccepted = !_tosAccepted;
              });
              widget.onTosAcceptedChanged(_tosAccepted);
            },
            onReadMore: _openTermsOfService,
          ),

          const SizedBox(height: 12),

          // Privacy Policy
          _buildAgreementTile(
            context: context,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            isAccepted: _privacyAccepted,
            onTap: () {
              setState(() {
                _privacyAccepted = !_privacyAccepted;
              });
              widget.onPrivacyAcceptedChanged(_privacyAccepted);
            },
            onReadMore: _openPrivacyPolicy,
          ),

          const SizedBox(height: 32),

          // Privacy info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Privacy Matters',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'avrai uses on-device AI to personalize your experience. '
                        'Your data stays on your device and is never shared without your consent.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isAccepted,
    required VoidCallback onTap,
    required VoidCallback onReadMore,
  }) {
    final theme = Theme.of(context);

    return PortalSurface(
      padding: EdgeInsets.zero,
      borderColor: isAccepted ? AppColors.success : AppColors.grey300,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: isAccepted,
          onChanged: (_) => onTap(),
          activeColor: AppColors.success,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: TextButton(
          onPressed: onReadMore,
          child: const Text('Read'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
