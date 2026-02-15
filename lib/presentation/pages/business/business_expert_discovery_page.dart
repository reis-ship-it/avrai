import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/services/business/business_expert_outreach_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/business/business_expert_chat_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text('Send'),
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
        FeedbackPresenter.showSnack(
          context,
          message: 'Outreach sent successfully!',
          kind: FeedbackKind.success,
        );

        // Navigate to chat page
        AppNavigator.pushBuilder(
          context,
          builder: (context) => BusinessExpertChatPage(
            businessId: widget.businessId,
            expertId: expert.expertId,
            expertName: expert.expertName,
          ),
        );
      } else if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Error sending outreach',
          kind: FeedbackKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Discover Experts',
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // TODO: Show filter dialog
            FeedbackPresenter.showSnack(
              context,
              message: 'Filter options coming soon',
              kind: FeedbackKind.info,
            );
          },
        ),
      ],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(kSpaceLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRecommendedExperts,
                          child: Text('Retry'),
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
                          Text(
                            'No experts found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your compatibility threshold',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
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
                            child: Text('Lower Threshold'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendedExperts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(kSpaceMd),
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
    return PortalSurface(
      margin: const EdgeInsets.only(bottom: kSpaceSm),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _sendOutreach(expert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(kSpaceMd),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (expert.metadata?['expertise'] != null)
                          Text(
                            expert.metadata!['expertise'] as String,
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
                  if (expert.compatibilityScore != null)
                    Chip(
                      side: BorderSide.none,
                      backgroundColor:
                          _getCompatibilityColor(expert.compatibilityScore!)
                              .withValues(alpha: 0.1),
                      label: Row(
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _getCompatibilityColor(
                                      expert.compatibilityScore!),
                                  fontWeight: FontWeight.bold,
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
                    label: Text('Reach Out'),
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
