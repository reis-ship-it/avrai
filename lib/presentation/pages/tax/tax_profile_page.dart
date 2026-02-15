import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/payment/tax_profile.dart';
import 'package:avrai/core/services/payment/tax_compliance_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Tax Profile Page
///
/// Agent 2: Phase 5, Week 18-19 - Tax UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - W-9 form
/// - Tax classification selection
/// - SSN/EIN input (encrypted)
/// - Business name (if applicable)
/// - Submit button
class TaxProfilePage extends StatefulWidget {
  const TaxProfilePage({super.key});

  @override
  State<TaxProfilePage> createState() => _TaxProfilePageState();
}

class _TaxProfilePageState extends State<TaxProfilePage> {
  final TaxComplianceService _taxService = TaxComplianceService(
    paymentService: GetIt.instance<PaymentService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _ssnController = TextEditingController();
  final _einController = TextEditingController();
  final _businessNameController = TextEditingController();

  TaxClassification? _selectedClassification;
  TaxProfile? _existingProfile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ssnController.dispose();
    _einController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to view tax profile');
      }

      final profile = await _taxService.getTaxProfile(authState.user.id);
      setState(() {
        _existingProfile = profile;
        _selectedClassification = profile.classification;
        if (profile.ssnLast4 != null) {
          _ssnController.text =
              '****-**-${profile.ssnLast4!.substring(profile.ssnLast4!.length - 4)}';
        }
        if (profile.einMasked != null) {
          _einController.text = profile.einMasked!;
        }
        if (profile.businessName != null) {
          _businessNameController.text = profile.businessName!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitW9() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassification == null) {
      context.showError('Please select a tax classification');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to submit W-9');
      }

      // Get SSN (if not already submitted)
      String? ssn;
      if (_existingProfile == null || !_existingProfile!.w9Submitted) {
        // Extract SSN from masked format or get new input
        if (_ssnController.text.contains('****')) {
          throw Exception('Please enter your full SSN');
        }
        ssn = _ssnController.text.replaceAll(RegExp(r'[^\d]'), '');
        if (ssn.length != 9) {
          throw Exception('SSN must be 9 digits');
        }
      }

      // Get EIN if business classification
      String? ein;
      if (_needsEIN(_selectedClassification!)) {
        if (_einController.text.isEmpty) {
          throw Exception('EIN is required for business classifications');
        }
        ein = _einController.text.replaceAll(RegExp(r'[^\d]'), '');
      }

      await _taxService.submitW9(
        userId: authState.user.id,
        ssn: ssn ?? '',
        classification: _selectedClassification!,
        ein: ein,
        businessName: _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
      );

      if (mounted) {
        context.showSuccess('W-9 submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  bool _needsEIN(TaxClassification classification) {
    return classification == TaxClassification.partnership ||
        classification == TaxClassification.corporation ||
        classification == TaxClassification.llc;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Tax Profile',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      _buildInfoCard(),
                      SizedBox(height: context.spacing.xl),

                      // Tax Classification
                      _buildClassificationSelection(),
                      SizedBox(height: context.spacing.xl),

                      // SSN Input
                      if (!_needsEIN(_selectedClassification ??
                          TaxClassification.individual))
                        _buildSSNInput(),
                      if (!_needsEIN(_selectedClassification ??
                          TaxClassification.individual))
                        SizedBox(height: context.spacing.xl),

                      // EIN Input (for businesses)
                      if (_selectedClassification != null &&
                          _needsEIN(_selectedClassification!)) ...[
                        _buildEINInput(),
                        SizedBox(height: context.spacing.xl),
                        _buildBusinessNameInput(),
                        SizedBox(height: context.spacing.xl),
                      ],

                      // Existing Profile Info
                      if (_existingProfile?.w9Submitted ?? false) ...[
                        _buildSubmittedInfo(),
                        SizedBox(height: context.spacing.xl),
                      ],

                      // Error Display
                      if (_error != null) ...[
                        PortalSurface(
                          padding: EdgeInsets.all(context.spacing.md),
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderColor: AppColors.error.withValues(alpha: 0.3),
                          radius: context.radius.sm,
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error),
                              SizedBox(width: context.spacing.sm),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.spacing.xl),
                      ],

                      // Submit Button
                      if (!(_existingProfile?.w9Submitted ?? false))
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitW9,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white),
                                  ),
                                )
                              : Text('Submit W-9'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'avrai Tax Service - Free & Easy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            'If you earn \$600 or more in a calendar year, avrai will automatically handle your tax reporting. We\'ll generate your 1099-K form and file it with the IRS—all free, all easy.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.sm),
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.sm),
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
            radius: context.spacing.sm / 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.electricGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Why choose SPOTS tax service?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.xs),
                _buildBenefitPoint('✓ Free - No accountant fees'),
                _buildBenefitPoint('✓ Automatic - We handle everything'),
                _buildBenefitPoint('✓ Secure - Your info is encrypted'),
                _buildBenefitPoint('✓ Simple - Just submit once'),
              ],
            ),
          ),
          SizedBox(height: context.spacing.sm),
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.sm),
            color: AppColors.warning.withValues(alpha: 0.1),
            borderColor: AppColors.warning.withValues(alpha: 0.3),
            radius: context.spacing.sm / 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Important: IRS Reporting Requirement',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'SPOTS is legally required to report all earnings over \$600 to the IRS, even if you don\'t submit a W-9. If you don\'t submit a W-9, the IRS will contact you directly to obtain your tax information. Submitting your W-9 now makes everything easier and ensures accurate reporting.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xxs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildClassificationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Classification *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        RadioGroup<TaxClassification>(
          groupValue: _selectedClassification,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedClassification = val;
                // Clear EIN/business name if switching to individual
                if (val == TaxClassification.individual) {
                  _einController.clear();
                  _businessNameController.clear();
                }
              });
            }
          },
          child: Column(
            children: TaxClassification.values.map((classification) {
              return RadioListTile<TaxClassification>(
                title: Text(
                  _getClassificationDisplayName(classification),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  _getClassificationDescription(classification),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                value: classification,
                activeColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSSNInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Security Number (SSN) *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _ssnController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
            _SSNFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'XXX-XX-XXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: const Icon(Icons.lock, color: AppColors.textSecondary),
          ),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'SSN is required';
            }
            final digits = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length != 9) {
              return 'SSN must be 9 digits';
            }
            return null;
          },
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Your SSN is encrypted and stored securely. Only the last 4 digits will be displayed after submission.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildEINInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employer Identification Number (EIN) *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _einController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
            _EINFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'XX-XXXXXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'EIN is required for business classifications';
            }
            final digits = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length != 9) {
              return 'EIN must be 9 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusinessNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Name (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _businessNameController,
          decoration: InputDecoration(
            hintText: 'Enter business name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSubmittedInfo() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
      radius: context.radius.sm,
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.electricGreen),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'W-9 Submitted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.electricGreen,
                      ),
                ),
                if (_existingProfile?.w9SubmittedAt != null) ...[
                  SizedBox(height: context.spacing.xxs),
                  Text(
                    'Submitted on ${_formatDate(_existingProfile!.w9SubmittedAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClassificationDisplayName(TaxClassification classification) {
    switch (classification) {
      case TaxClassification.individual:
        return 'Individual';
      case TaxClassification.soleProprietor:
        return 'Sole Proprietor';
      case TaxClassification.partnership:
        return 'Partnership';
      case TaxClassification.corporation:
        return 'Corporation';
      case TaxClassification.llc:
        return 'LLC';
    }
  }

  String _getClassificationDescription(TaxClassification classification) {
    switch (classification) {
      case TaxClassification.individual:
        return 'Personal tax identification';
      case TaxClassification.soleProprietor:
        return 'Single-owner business';
      case TaxClassification.partnership:
        return 'Business partnership (EIN required)';
      case TaxClassification.corporation:
        return 'Corporation (EIN required)';
      case TaxClassification.llc:
        return 'Limited Liability Company (EIN required)';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// SSN Formatter - Formats as XXX-XX-XXXX
class _SSNFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isEmpty) return newValue;

    String formatted = '';
    if (text.isNotEmpty) {
      formatted = text.substring(0, text.length > 3 ? 3 : text.length);
    }
    if (text.length > 3) {
      formatted += '-${text.substring(3, text.length > 5 ? 5 : text.length)}';
    }
    if (text.length > 5) {
      formatted += '-${text.substring(5, text.length > 9 ? 9 : text.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// EIN Formatter - Formats as XX-XXXXXXX
class _EINFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isEmpty) return newValue;

    String formatted = '';
    if (text.isNotEmpty) {
      formatted = text.substring(0, text.length > 2 ? 2 : text.length);
    }
    if (text.length > 2) {
      formatted += '-${text.substring(2, text.length > 9 ? 9 : text.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
