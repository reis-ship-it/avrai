import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/payment/tax_document.dart';
import 'package:avrai/core/models/payment/tax_profile.dart';
import 'package:avrai/core/services/payment/tax_compliance_service.dart';
import 'package:avrai/core/services/payment/tax_document_storage_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Tax Documents Page
///
/// Agent 2: Phase 5, Week 18-19 - Tax UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - List of tax documents
/// - Download 1099 forms
/// - Tax year selection
/// - Earnings summary
class TaxDocumentsPage extends StatefulWidget {
  const TaxDocumentsPage({super.key});

  @override
  State<TaxDocumentsPage> createState() => _TaxDocumentsPageState();
}

class _TaxDocumentsPageState extends State<TaxDocumentsPage> {
  final TaxComplianceService _taxService = TaxComplianceService(
    paymentService: GetIt.instance<PaymentService>(),
  );

  int _selectedYear = DateTime.now().year;
  List<TaxDocument> _documents = [];
  TaxProfile? _taxProfile;
  double _currentYearEarnings = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to view tax documents');
      }

      // Load tax profile
      final profile = await _taxService.getTaxProfile(authState.user.id);

      // Calculate current year earnings
      await _taxService.needsTaxDocuments(authState.user.id, _selectedYear);
      final earnings =
          await _calculateEarnings(authState.user.id, _selectedYear);

      // Load documents for selected year
      final documents = await _taxService.getTaxDocuments(
        authState.user.id,
        _selectedYear,
      );

      setState(() {
        _taxProfile = profile;
        _currentYearEarnings = earnings;
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<double> _calculateEarnings(String userId, int year) async {
    // In production, this would calculate from PaymentService
    // For now, return a placeholder
    return 0.0;
  }

  Future<void> _downloadDocument(TaxDocument document) async {
    if (document.documentUrl == null) {
      context.showWarning('Document not yet available');
      return;
    }

    try {
      final storage = GetIt.instance<TaxDocumentStorageService>();
      final uri = await storage.resolveLaunchUrl(document.documentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error opening document: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Tax Documents',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      SizedBox(height: context.spacing.md),
                      Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Earnings Summary
                        _buildEarningsSummary(),
                        SizedBox(height: context.spacing.xl),

                        // Tax Year Selector
                        _buildYearSelector(),
                        SizedBox(height: context.spacing.xl),

                        // Documents List
                        _buildDocumentsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEarningsSummary() {
    final needsDocs = _currentYearEarnings >= 600.0;

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedYear Earnings Summary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      '\$${_currentYearEarnings.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide.none,
                backgroundColor: needsDocs
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppColors.electricGreen.withValues(alpha: 0.1),
                label: Row(
                  children: [
                    Icon(
                      needsDocs ? Icons.info : Icons.check_circle,
                      size: 16,
                      color: needsDocs
                          ? AppTheme.primaryColor
                          : AppColors.electricGreen,
                    ),
                    SizedBox(width: context.spacing.xxs),
                    Text(
                      needsDocs ? 'Tax Docs Required' : 'Below Threshold',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: needsDocs
                                ? AppTheme.primaryColor
                                : AppColors.electricGreen,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (needsDocs && !(_taxProfile?.w9Submitted ?? false)) ...[
            SizedBox(height: context.spacing.md),
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.sm),
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderColor: AppTheme.warningColor.withValues(alpha: 0.3),
              radius: context.radius.sm,
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'W-9 form required to generate tax documents',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Year',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        PortalSurface(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
          color: AppColors.surface,
          borderColor: AppColors.grey300,
          radius: context.radius.sm,
          child: DropdownButton<int>(
            value: _selectedYear,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(5, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedYear = value;
                });
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(context.spacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.description,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: context.spacing.md),
            Text(
              'No tax documents for $_selectedYear',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              _currentYearEarnings < 600.0
                  ? 'Earnings are below the \$600 threshold. No tax documents required.'
                  : 'Tax documents will be generated after W-9 submission.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Documents',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        ..._documents.map((document) {
          return _buildDocumentCard(document);
        }),
      ],
    );
  }

  Widget _buildDocumentCard(TaxDocument document) {
    return PortalSurface(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFormTypeDisplayName(document.formType),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Tax Year ${document.taxYear}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(document.status),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '\$${document.totalEarnings.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (document.documentUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _downloadDocument(document),
                  icon: const Icon(Icons.download),
                  label: Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaxStatus status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case TaxStatus.notRequired:
        badgeColor = AppColors.grey400;
        badgeText = 'Not Required';
        break;
      case TaxStatus.pending:
        badgeColor = AppTheme.warningColor;
        badgeText = 'Pending';
        break;
      case TaxStatus.generated:
        badgeColor = AppTheme.primaryColor;
        badgeText = 'Generated';
        break;
      case TaxStatus.sent:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Sent';
        break;
      case TaxStatus.filed:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Filed';
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
      backgroundColor: badgeColor.withValues(alpha: 0.1),
      label: Text(
        badgeText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
      ),
    );
  }

  String _getFormTypeDisplayName(TaxFormType formType) {
    switch (formType) {
      case TaxFormType.form1099K:
        return 'Form 1099-K';
      case TaxFormType.form1099NEC:
        return 'Form 1099-NEC';
      case TaxFormType.formW9:
        return 'Form W-9';
    }
  }
}
