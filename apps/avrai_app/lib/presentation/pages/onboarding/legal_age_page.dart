import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/legal_age_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Step 1: Legal and age verification page.
class LegalAgePage extends StatefulWidget {
  final DateTime? initialBirthday;
  final bool initialTosAccepted;
  final bool initialPrivacyAccepted;
  final ValueChanged<DateTime?> onBirthdayChanged;
  final ValueChanged<bool> onTosAcceptedChanged;
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
    const url = 'https://avrai.org/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://avrai.org/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      padding: const EdgeInsets.all(24),
      schema: buildLegalAgePageSchema(
        birthdayField: _buildBirthdayField(context),
        agreements: _buildAgreementSection(context),
        ageValidationMessage: _selectedBirthday == null || _isAgeValid
            ? null
            : _buildAgeError(context),
      ),
    );
  }

  Widget _buildBirthdayField(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;

    return AppSurface(
      padding: EdgeInsets.zero,
      borderColor: _selectedBirthday != null
          ? (_isAgeValid ? AppColors.success : AppColors.error)
          : AppColors.borderSubtle,
      child: InkWell(
        onTap: _selectBirthday,
        borderRadius: BorderRadius.circular(radius.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Icon(
                Icons.cake_outlined,
                color: _selectedBirthday != null
                    ? (_isAgeValid ? AppColors.success : AppColors.error)
                    : AppColors.textSecondary,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBirthday != null
                          ? _formatDate(_selectedBirthday!)
                          : 'Select your birthday',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _selectedBirthday != null
                                ? null
                                : AppColors.textSecondary,
                          ),
                    ),
                    if (_calculatedAge != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$_calculatedAge years old',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isAgeValid
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementSection(BuildContext context) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildAgreementTile(
            context: context,
            title: 'Terms of Service',
            subtitle: 'Rules for using AVRAI',
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
          _buildAgreementTile(
            context: context,
            title: 'Privacy Policy',
            subtitle: 'How AVRAI handles your data',
            isAccepted: _privacyAccepted,
            onTap: () {
              setState(() {
                _privacyAccepted = !_privacyAccepted;
              });
              widget.onPrivacyAcceptedChanged(_privacyAccepted);
            },
            onReadMore: _openPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeError(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'You must be at least 18 years old to use AVRAI.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ),
      ],
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

    return AppSurface(
      padding: EdgeInsets.zero,
      borderColor: isAccepted ? AppColors.success : AppColors.borderSubtle,
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
