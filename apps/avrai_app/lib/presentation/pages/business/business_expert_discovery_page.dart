import 'package:flutter/material.dart';
import 'package:avrai_runtime_os/services/business/business_expert_outreach_service.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/business/business_expert_chat_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

/// Business Expert Discovery Page
///
/// Allows businesses to discover and reach out to experts based on vibe compatibility.
class BusinessExpertDiscoveryPage extends StatefulWidget {
  final String businessId;

  const BusinessExpertDiscoveryPage({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessExpertDiscoveryPage> createState() =>
      _BusinessExpertDiscoveryPageState();
}

class _BusinessExpertDiscoveryPageState
    extends State<BusinessExpertDiscoveryPage> {
  final _outreachService = GetIt.instance<BusinessExpertOutreachService>();

  List<ExpertMatch> _recommendedExperts = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _minCompatibilityScore = 0.7;

  @override
  void initState() {
    super.initState();
    _loadRecommendedExperts();
  }

  Future<void> _loadRecommendedExperts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final experts = await _outreachService.getRecommendedExperts(
        businessId: widget.businessId,
        minCompatibilityScore: _minCompatibilityScore,
        limit: 20,
      );

      setState(() {
        _recommendedExperts = experts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading experts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOutreach(ExpertMatch expert) async {
    final messageController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reach out to ${expert.expertName ?? "Expert"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expert.compatibilityScore != null) ...[
              Row(
                children: [
                  const Icon(Icons.favorite,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Compatibility: ${(expert.compatibilityScore! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText:
                    'Introduce yourself and explain why you\'d like to connect...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result == true && messageController.text.trim().isNotEmpty) {
      final success = await _outreachService.sendOutreach(
        businessId: widget.businessId,
        expertId: expert.expertId,
        message: messageController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outreach sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessExpertChatPage(
              businessId: widget.businessId,
              expertId: expert.expertId,
              expertName: expert.expertName,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending outreach'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Discover Experts',
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // TODO: Show filter dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Filter options coming soon'),
              ),
            );
          },
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRecommendedExperts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _recommendedExperts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No experts found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your compatibility threshold',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _minCompatibilityScore = 0.5;
                              });
                              _loadRecommendedExperts();
                            },
                            child: const Text('Lower Threshold'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendedExperts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recommendedExperts.length,
                        itemBuilder: (context, index) {
                          final expert = _recommendedExperts[index];
                          return _buildExpertCard(expert);
                        },
                      ),
                    ),
    );
  }

  Widget _buildExpertCard(ExpertMatch expert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _sendOutreach(expert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expert.expertName ?? 'Expert',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (expert.metadata?['expertise'] != null)
                          Text(
                            expert.metadata!['expertise'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (expert.compatibilityScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getCompatibilityColor(expert.compatibilityScore!)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: _getCompatibilityColor(
                                expert.compatibilityScore!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(expert.compatibilityScore! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _getCompatibilityColor(
                                  expert.compatibilityScore!),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _sendOutreach(expert),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Reach Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }
}
