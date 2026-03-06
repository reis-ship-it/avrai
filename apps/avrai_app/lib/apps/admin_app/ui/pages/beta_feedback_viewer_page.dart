import 'package:flutter/material.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class BetaFeedbackViewerPage extends StatefulWidget {
  const BetaFeedbackViewerPage({super.key});

  @override
  State<BetaFeedbackViewerPage> createState() => _BetaFeedbackViewerPageState();
}

class _BetaFeedbackViewerPageState extends State<BetaFeedbackViewerPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('beta_feedback')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _feedbackList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e, st) {
      developer.log('Failed to load feedback', error: e, stackTrace: st, name: 'BetaFeedbackViewerPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load feedback: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('beta_feedback')
          .update({'status': newStatus})
          .eq('id', id);
      
      await _loadFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppColors.success),
        );
      }
    } catch (e, st) {
      developer.log('Failed to update status', error: e, stackTrace: st, name: 'BetaFeedbackViewerPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedbackList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: AppColors.grey500),
            const SizedBox(height: 16),
            Text('No beta feedback yet', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbackList.length,
        itemBuilder: (context, index) {
          final item = _feedbackList[index];
          final createdAt = DateTime.tryParse(item['created_at'] ?? '');
          final formattedDate = createdAt != null ? DateFormat.yMMMd().add_jm().format(createdAt) : 'Unknown';
          
          Color statusColor;
          switch (item['status']) {
            case 'reviewed':
              statusColor = AppColors.electricGreen;
              break;
            case 'actioned':
              statusColor = AppColors.success;
              break;
            case 'new':
            default:
              statusColor = AppColors.warning;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          (item['type'] ?? 'unknown').toString().toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['status'] ?? 'new',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (val) => _updateStatus(item['id'], val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'new', child: Text('Mark as New')),
                              const PopupMenuItem(value: 'reviewed', child: Text('Mark as Reviewed')),
                              const PopupMenuItem(value: 'actioned', child: Text('Mark as Actioned')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['content'] ?? 'No content',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User: ${(item['user_id'] ?? '').toString().substring(0, 8)}...',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
