import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/terms_of_service_page_schema.dart';
import 'package:avrai_runtime_os/legal/terms_of_service.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';

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
    } catch (_) {}
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
        ipAddress: null,
        userAgent: null,
      );

      setState(() {
        _hasAccepted = true;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terms of Service accepted')),
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
    return AppSchemaPage(
      schema: buildTermsOfServicePageSchema(
        version: TermsOfService.version,
        effectiveDate: _formatDate(TermsOfService.effectiveDate),
        paragraphs: splitLegalContent(TermsOfService.content),
        hasAccepted: _hasAccepted,
        requireAcceptance: widget.requireAcceptance,
        isSubmitting: _isSubmitting,
        error: _error,
        onAccept: _acceptTerms,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
