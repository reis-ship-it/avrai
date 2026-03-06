import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class BetaFeedbackPage extends StatefulWidget {
  const BetaFeedbackPage({super.key});

  @override
  State<BetaFeedbackPage> createState() => _BetaFeedbackPageState();
}

class _BetaFeedbackPageState extends State<BetaFeedbackPage> {
  final _feedbackController = TextEditingController();
  String _selectedType = 'general';
  bool _isSubmitting = false;

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
      await Supabase.instance.client.from('beta_feedback').insert({
        'user_id': authState.user.id,
        'type': _selectedType,
        'content': text,
        'status': 'new',
      });

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
    return AdaptivePlatformPageScaffold(
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
