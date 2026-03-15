import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/common/headless_os_status_banner.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class BetaFeedbackPage extends StatefulWidget {
  const BetaFeedbackPage({
    super.key,
    this.headlessOsAvailabilityService,
    this.feedbackSubmitter,
  });

  final HeadlessAvraiOsAvailabilityService? headlessOsAvailabilityService;
  final Future<void> Function(Map<String, dynamic> payload)? feedbackSubmitter;

  @override
  State<BetaFeedbackPage> createState() => _BetaFeedbackPageState();
}

class _BetaFeedbackPageState extends State<BetaFeedbackPage> {
  final _feedbackController = TextEditingController();
  String _selectedType = 'general';
  bool _isSubmitting = false;
  HeadlessAvraiOsAvailabilitySnapshot? _osAvailability;

  final List<Map<String, String>> _feedbackTypes = [
    {'value': 'general', 'label': 'General Feedback'},
    {'value': 'idea', 'label': 'Idea / Feature Request'},
    {'value': 'bug', 'label': 'Report a Bug'},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOsAvailability();
  }

  Future<void> _loadOsAvailability() async {
    final service =
        widget.headlessOsAvailabilityService ?? _resolveAvailabilityService();
    if (service == null) {
      return;
    }
    final availability = await service.currentAvailability();
    if (!mounted) {
      return;
    }
    setState(() {
      _osAvailability = availability;
    });
  }

  HeadlessAvraiOsAvailabilityService? _resolveAvailabilityService() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<HeadlessAvraiOsAvailabilityService>()) {
      return null;
    }
    return getIt<HeadlessAvraiOsAvailabilityService>();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some feedback first')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = <String, dynamic>{
        'user_id': authState.user.id,
        'type': _selectedType,
        'content': text,
        'status': 'new',
      };
      final submitter = widget.feedbackSubmitter;
      if (submitter != null) {
        await submitter(payload);
      } else {
        await Supabase.instance.client.from('beta_feedback').insert(payload);
      }
      developer.log(
        'Submitted beta feedback with OS context',
        name: 'BetaFeedback',
        error: null,
        stackTrace: null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Thank you! Your feedback has been sent directly to the team.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (e, st) {
      developer.log('Failed to submit feedback: $e',
          name: 'BetaFeedback', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppFlowScaffold(
      title: 'Beta Feedback',
      scrollable: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us improve AVRAI',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'As a Beta Pioneer, your voice directly shapes the future of the platform. Tell us what you love, what feels off, or any bugs you encountered.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.grey700),
            ),
            const SizedBox(height: 24),
            const AppSurface(
              color: AppColors.grey100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined,
                      color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy note: feedback is tied to your account for follow-up. Do not include passwords, payment details, or other sensitive personal data.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HeadlessOsStatusBanner(
              service: widget.headlessOsAvailabilityService,
            ),
            if (_osAvailability != null) ...[
              const SizedBox(height: 16),
              AppSurface(
                key: const Key('beta_feedback_os_context_card'),
                color: AppColors.grey100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.memory,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _osAvailability!.summary,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _osAvailability!.localityContainedInWhere
                                  ? 'Feedback will be reviewed alongside AVRAI OS context with locality contained in where.'
                                  : 'Feedback is available before AVRAI OS is fully live.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppSurface(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback Type',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: _feedbackTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Thoughts',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'How does the app feel? Any ideas or bugs?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Semantics(
                label: 'Send beta feedback',
                hint: 'Submits feedback to the AVRAI team',
                button: true,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Send to Team'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
