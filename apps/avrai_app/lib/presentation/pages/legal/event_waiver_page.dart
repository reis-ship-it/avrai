import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/event_waiver_page_schema.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/legal/event_waiver.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';
import 'package:avrai/theme/app_theme.dart';

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
    } catch (_) {}
  }

  Future<void> _acceptWaiver() async {
    if (!_acknowledgeRisks || !_acknowledgeRelease || !_acknowledgeAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge all statements'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
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
        ipAddress: null,
        userAgent: null,
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event waiver accepted')),
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
    final requiresFull = EventWaiver.requiresFullWaiver(widget.event);
    final waiverText = requiresFull
        ? EventWaiver.generateWaiver(widget.event)
        : EventWaiver.generateSimplifiedWaiver(widget.event);

    return AppSchemaPage(
      schema: buildEventWaiverPageSchema(
        eventTitle: widget.event.title,
        eventDetails:
            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? "Location TBD"}',
        paragraphs: splitWaiverContent(waiverText),
        requiresFull: requiresFull,
        acknowledgeRisks: _acknowledgeRisks,
        acknowledgeRelease: _acknowledgeRelease,
        acknowledgeAge: _acknowledgeAge,
        hasAccepted: _hasAccepted,
        requireAcceptance: widget.requireAcceptance,
        isSubmitting: _isSubmitting,
        error: _error,
        onAcknowledgeRisksChanged: (value) =>
            setState(() => _acknowledgeRisks = value),
        onAcknowledgeReleaseChanged: (value) =>
            setState(() => _acknowledgeRelease = value),
        onAcknowledgeAgeChanged: (value) =>
            setState(() => _acknowledgeAge = value),
        onAccept: _acceptWaiver,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
