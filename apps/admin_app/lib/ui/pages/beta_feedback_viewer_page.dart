import 'dart:developer' as developer;

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/admin/admin_identity_redaction_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BetaFeedbackViewerPage extends StatefulWidget {
  const BetaFeedbackViewerPage({super.key});

  @override
  State<BetaFeedbackViewerPage> createState() => _BetaFeedbackViewerPageState();
}

class _BetaFeedbackViewerPageState extends State<BetaFeedbackViewerPage> {
  final AdminIdentityRedactionService _redactionService =
      GetIt.instance.isRegistered<AdminIdentityRedactionService>()
          ? GetIt.instance<AdminIdentityRedactionService>()
          : const AdminIdentityRedactionService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbackList = const <Map<String, dynamic>>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('beta_feedback')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _feedbackList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load feedback',
        error: e,
        stackTrace: st,
        name: 'BetaFeedbackViewerPage',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('beta_feedback')
          .update({'status': newStatus}).eq('id', id);
      await _loadFeedback();
    } catch (e, st) {
      developer.log(
        'Failed to update status',
        error: e,
        stackTrace: st,
        name: 'BetaFeedbackViewerPage',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Beta Feedback Inbox',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadFeedback,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadFeedback, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_feedbackList.isEmpty) {
      return const Center(child: Text('No beta feedback yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BHAM feedback triage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Feedback stays pseudonymous in admin by default. Use this inbox for launch issues, trust reports, and day-1 beta friction.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._feedbackList.map((item) => _buildFeedbackCard(context, item)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gpp_maybe_outlined),
              title: const Text('Escalate to Moderation'),
              subtitle: const Text(
                'Use moderation operations when feedback turns into a flagged safety or trust issue.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.moderation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, Map<String, dynamic> item) {
    final createdAt = DateTime.tryParse(item['created_at'] as String? ?? '');
    final formattedDate = createdAt == null
        ? 'Unknown'
        : DateFormat.yMMMd().add_jm().format(createdAt.toLocal());
    final user = _redactionService.redactActor(
      item['user_id'] as String? ?? 'anonymous_feedback',
    );
    final status = (item['status'] as String? ?? 'new').toLowerCase();
    final statusColor = switch (status) {
      'reviewed' => AppColors.electricGreen,
      'actioned' => AppColors.success,
      _ => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text((item['type'] ?? 'feedback').toString())),
                const SizedBox(width: 8),
                Chip(
                  label: Text(status),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _updateStatus(item['id'].toString(), value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'new', child: Text('Mark new')),
                    PopupMenuItem(
                        value: 'reviewed', child: Text('Mark reviewed')),
                    PopupMenuItem(
                        value: 'actioned', child: Text('Mark actioned')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _redactionService.redactText(item['content'] as String? ?? ''),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.displayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
