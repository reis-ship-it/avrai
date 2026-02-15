import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/legal/terms_of_service.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Terms of Service Page
///
/// Agent 2: Phase 5, Week 18-19 - Legal Document UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Terms of Service display
/// - Version number
/// - Effective date
/// - Accept button
class TermsOfServicePage extends StatefulWidget {
  final bool requireAcceptance;

  const TermsOfServicePage({
    super.key,
    this.requireAcceptance = false,
  });

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  final LegalDocumentService _legalService =
      GetIt.instance<LegalDocumentService>();

  bool _hasAccepted = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAcceptanceStatus();
  }

  Future<void> _checkAcceptanceStatus() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final accepted =
            await _legalService.hasAcceptedTerms(authState.user.id);
        setState(() {
          _hasAccepted = accepted;
        });
      }
    } catch (e) {
      // Ignore errors, assume not accepted
    }
  }

  Future<void> _acceptTerms() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to accept Terms of Service');
      }

      await _legalService.acceptTermsOfService(
        userId: authState.user.id,
        ipAddress: null, // In production, get from request
        userAgent: null, // In production, get from request
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Terms of Service accepted',
          kind: FeedbackKind.success,
          duration: const Duration(seconds: 2),
        );
        if (widget.requireAcceptance) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Terms of Service',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Info
          PortalSurface(
            padding: const EdgeInsets.all(kSpaceMdWide),
            color: AppColors.surface,
            radius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version ${TermsOfService.version}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'Effective: ${_formatDate(TermsOfService.effectiveDate)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasAccepted)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                        backgroundColor: Color.fromRGBO(0, 255, 102, 0.1),
                        label: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.electricGreen),
                            SizedBox(width: 4),
                            Text(
                              'Accepted',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.electricGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Terms Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kSpaceMdWide),
              child: Text(
                TermsOfService.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
              ),
            ),
          ),

          // Accept Button (if required or not yet accepted)
          if (widget.requireAcceptance || !_hasAccepted) ...[
            PortalSurface(
              padding: const EdgeInsets.all(kSpaceMdWide),
              color: AppColors.surface,
              borderColor: AppColors.grey300,
              radius: 0,
              child: Column(
                children: [
                  if (_error != null) ...[
                    PortalSurface(
                      padding: const EdgeInsets.all(kSpaceSm),
                      margin: const EdgeInsets.only(bottom: kSpaceMd),
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderColor: AppColors.error.withValues(alpha: 0.3),
                      radius: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _acceptTerms,
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
                        : Text('I Accept the Terms of Service'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
