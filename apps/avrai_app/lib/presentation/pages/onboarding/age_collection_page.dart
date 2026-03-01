import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:intl/intl.dart';

class AgeCollectionPage extends StatefulWidget {
  final DateTime? selectedBirthday;
  final Function(DateTime?) onBirthdayChanged;

  const AgeCollectionPage({
    super.key,
    this.selectedBirthday,
    required this.onBirthdayChanged,
  });

  @override
  State<AgeCollectionPage> createState() => _AgeCollectionPageState();
}

class _AgeCollectionPageState extends State<AgeCollectionPage> {
  DateTime? _selectedBirthday;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBirthday = widget.selectedBirthday;
    if (_selectedBirthday != null) {
      _dateController.text =
          DateFormat('MM/dd/yyyy').format(_selectedBirthday!);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  String _getAgeGroup(int age) {
    if (age < 13) return 'Under 13';
    if (age < 18) return 'Teen (13-17)';
    if (age < 26) return 'Young Adult (18-25)';
    if (age < 65) return 'Adult (26-64)';
    return 'Senior (65+)';
  }

  Future<void> _selectDate(BuildContext context) async {
    // Default to 30 years old (1995) for better UX - most users won't need to scroll
    final defaultDate = DateTime.now().subtract(const Duration(days: 365 * 30));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? defaultDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      widget.onBirthdayChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_selectedBirthday);
    final ageGroup = age != null ? _getAgeGroup(age) : null;
    final spacing = context.spacing;
    final radius = context.radius;

    return AdaptivePageScaffold(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Age Verification',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need your age to provide age-appropriate content and ensure legal compliance.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          SizedBox(height: spacing.xl),

          // Birthday Input
          PortalSurface(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(radius.md),
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birthday',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.grey600,
                                ),
                          ),
                          SizedBox(height: spacing.xxs),
                          Text(
                            _selectedBirthday != null
                                ? DateFormat('MMMM dd, yyyy')
                                    .format(_selectedBirthday!)
                                : 'Tap to select your birthday',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedBirthday != null) ...[
            SizedBox(height: spacing.lg),
            // Age Display
            PortalSurface(
              padding: EdgeInsets.all(spacing.md),
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age: $age years old',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                        SizedBox(height: spacing.xxs),
                        Text(
                          'Age Group: $ageGroup',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: spacing.lg),

          // Privacy Notice
          PortalSurface(
            padding: EdgeInsets.all(spacing.md),
            color: AppColors.grey50,
            borderColor: AppColors.grey200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.grey600,
                  size: 20,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Your age is stored securely and used only to provide age-appropriate content. We respect your privacy per OUR_GUTS.md principles.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey700,
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
}
