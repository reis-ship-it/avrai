import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/privacy_policy_page_schema.dart';
import 'package:avrai/presentation/schemas/pages/terms_of_service_page_schema.dart';
import 'package:avrai_runtime_os/legal/privacy_policy.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final bool requireAcceptance;

  const PrivacyPolicyPage({
    super.key,
    this.requireAcceptance = false,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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
            await _legalService.hasAcceptedPrivacyPolicy(authState.user.id);
        setState(() {
          _hasAccepted = accepted;
        });
      }
    } catch (_) {}
  }

  Future<void> _acceptPrivacyPolicy() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to accept Privacy Policy');
      }

      await _legalService.acceptPrivacyPolicy(
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
          const SnackBar(content: Text('Privacy Policy accepted')),
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
      schema: buildPrivacyPolicyPageSchema(
        version: PrivacyPolicy.version,
        effectiveDate: _formatDate(PrivacyPolicy.effectiveDate),
        paragraphs: splitLegalContent(PrivacyPolicy.content),
        hasAccepted: _hasAccepted,
        requireAcceptance: widget.requireAcceptance,
        isSubmitting: _isSubmitting,
        error: _error,
        onAccept: _acceptPrivacyPolicy,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
