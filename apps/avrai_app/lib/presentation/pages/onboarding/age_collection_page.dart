import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/age_collection_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedBirthday = widget.selectedBirthday;
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
              primary: AppColors.textPrimary,
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
      });
      widget.onBirthdayChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_selectedBirthday);
    final ageGroup = age != null ? _getAgeGroup(age) : null;

    return AppSchemaPage(
      padding: const EdgeInsets.all(24),
      schema: buildAgeCollectionPageSchema(
        birthdayField: _buildBirthdayField(context),
        ageSummary: age == null
            ? null
            : _buildAgeSummary(
                context,
                age: age,
                ageGroup: ageGroup!,
              ),
      ),
    );
  }

  Widget _buildBirthdayField(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;

    return AppSurface(
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
                color: AppColors.textPrimary,
                size: 24,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birthday',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(
                      _selectedBirthday != null
                          ? DateFormat('MMMM dd, yyyy')
                              .format(_selectedBirthday!)
                          : 'Tap to select your birthday',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    );
  }

  Widget _buildAgeSummary(
    BuildContext context, {
    required int age,
    required String ageGroup,
  }) {
    final spacing = context.spacing;

    return AppSurface(
      padding: EdgeInsets.all(spacing.md),
      color: AppColors.surfaceMuted,
      borderColor: AppColors.borderSubtle,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.textPrimary,
            size: 24,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age: $age years old',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  'Age Group: $ageGroup',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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
