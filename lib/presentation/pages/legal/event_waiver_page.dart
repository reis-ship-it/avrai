import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/legal/event_waiver.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Event Waiver Page
///
/// Agent 2: Phase 5, Week 18-19 - Legal Document UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Event-specific waiver
/// - Acknowledgment checkboxes
/// - Accept button
class EventWaiverPage extends StatefulWidget {
  final ExpertiseEvent event;
  final bool requireAcceptance;

  const EventWaiverPage({
    super.key,
    required this.event,
    this.requireAcceptance = true,
  });

  @override
  State<EventWaiverPage> createState() => _EventWaiverPageState();
}

class _EventWaiverPageState extends State<EventWaiverPage> {
  final LegalDocumentService _legalService =
      GetIt.instance<LegalDocumentService>();

  bool _acknowledgeRisks = false;
  bool _acknowledgeRelease = false;
  bool _acknowledgeAge = false;
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
        final accepted = await _legalService.hasAcceptedEventWaiver(
          authState.user.id,
          widget.event.id,
        );
        setState(() {
          _hasAccepted = accepted;
          if (accepted) {
            _acknowledgeRisks = true;
            _acknowledgeRelease = true;
            _acknowledgeAge = true;
          }
        });
      }
    } catch (e) {
      // Ignore errors, assume not accepted
    }
  }

  Future<void> _acceptWaiver() async {
    if (!_acknowledgeRisks || !_acknowledgeRelease || !_acknowledgeAge) {
      context.showWarning('Please acknowledge all statements');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to accept the event waiver');
      }

      await _legalService.acceptEventWaiver(
        userId: authState.user.id,
        eventId: widget.event.id,
        ipAddress: null, // In production, get from request
        userAgent: null, // In production, get from request
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        context.showSuccess('Event waiver accepted');
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
    final requiresFull = EventWaiver.requiresFullWaiver(widget.event);
    final waiverText = requiresFull
        ? EventWaiver.generateWaiver(widget.event)
        : EventWaiver.generateSimplifiedWaiver(widget.event);

    return AdaptivePlatformPageScaffold(
      title: 'Event Waiver',
      backgroundColor: AppColors.background,
      constrainBody: false,
      body: Column(
        children: [
          // Event Info Header
          PortalSurface(
            padding: const EdgeInsets.all(kSpaceMdWide),
            color: AppColors.surface,
            radius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? 'Location TBD'}',
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

          // Waiver Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kSpaceMdWide),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waiverText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Acknowledgment Checkboxes
                  if (requiresFull && !_hasAccepted) ...[
                    const Divider(color: AppColors.grey300),
                    const SizedBox(height: 16),
                    Text(
                      'Acknowledgment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        'I understand and acknowledge the risks of participation',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeRisks,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeRisks = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text(
                        'I release avrai and all parties from liability',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeRelease,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeRelease = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text(
                        'I am of legal age to enter into this agreement (or have guardian consent)',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      value: _acknowledgeAge,
                      onChanged: (value) {
                        setState(() {
                          _acknowledgeAge = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Accept Button
          if (widget.requireAcceptance && !_hasAccepted) ...[
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
                    onPressed: _isSubmitting ? null : _acceptWaiver,
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
                        : Text('I Agree'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
