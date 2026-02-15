import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/services/business/business_business_outreach_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Business Partnership Discovery Page
///
/// Allows businesses to discover and reach out to other businesses for partnerships.
class BusinessPartnershipDiscoveryPage extends StatefulWidget {
  final String businessId;

  const BusinessPartnershipDiscoveryPage({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessPartnershipDiscoveryPage> createState() =>
      _BusinessPartnershipDiscoveryPageState();
}

class _BusinessPartnershipDiscoveryPageState
    extends State<BusinessPartnershipDiscoveryPage> {
  final _outreachService = GetIt.instance<BusinessBusinessOutreachService>();

  List<BusinessMatch> _recommendedBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _minCompatibilityScore = 0.7;

  @override
  void initState() {
    super.initState();
    _loadRecommendedBusinesses();
  }

  Future<void> _loadRecommendedBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final businesses = await _outreachService.getRecommendedBusinesses(
        businessId: widget.businessId,
        minCompatibilityScore: _minCompatibilityScore,
        limit: 20,
      );

      setState(() {
        _recommendedBusinesses = businesses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading businesses: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPartnershipOutreach(BusinessMatch business) async {
    final messageController = TextEditingController();
    final partnershipTypeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Propose Partnership to ${business.businessName ?? "Business"}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (business.compatibilityScore != null) ...[
                Row(
                  children: [
                    const Icon(Icons.handshake,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Compatibility: ${(business.compatibilityScore! * 100).toStringAsFixed(0)}%',
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
                controller: partnershipTypeController,
                decoration: const InputDecoration(
                  labelText: 'Partnership Type (optional)',
                  hintText: 'e.g., Event Partnership, Collaboration',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Explain your partnership proposal...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                autofocus: true,
              ),
            ],
          ),
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
            child: Text('Send Proposal'),
          ),
        ],
      ),
    );

    if (result == true && messageController.text.trim().isNotEmpty) {
      final success = await _outreachService.sendPartnershipOutreach(
        senderBusinessId: widget.businessId,
        recipientBusinessId: business.businessId,
        message: messageController.text.trim(),
        partnershipType: partnershipTypeController.text.trim().isNotEmpty
            ? partnershipTypeController.text.trim()
            : null,
      );

      if (success && mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Partnership proposal sent successfully!',
          kind: FeedbackKind.success,
        );

        // Refresh the list
        _loadRecommendedBusinesses();
      } else if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Error sending partnership proposal',
          kind: FeedbackKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Discover Partners',
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
                          onPressed: _loadRecommendedBusinesses,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _recommendedBusinesses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_center,
                              size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No businesses found',
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
                              _loadRecommendedBusinesses();
                            },
                            child: Text('Lower Threshold'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendedBusinesses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(kSpaceMd),
                        itemCount: _recommendedBusinesses.length,
                        itemBuilder: (context, index) {
                          final business = _recommendedBusinesses[index];
                          return _buildBusinessCard(business);
                        },
                      ),
                    ),
    );
  }

  Widget _buildBusinessCard(BusinessMatch business) {
    return PortalSurface(
      margin: const EdgeInsets.only(bottom: kSpaceSm),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _sendPartnershipOutreach(business),
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
                      Icons.business,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.businessName ?? 'Business',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (business.metadata?['business_type'] != null)
                          Text(
                            business.metadata!['business_type'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        if (business.metadata?['location'] != null)
                          Text(
                            business.metadata!['location'] as String,
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
                  if (business.compatibilityScore != null)
                    Chip(
                      side: BorderSide.none,
                      backgroundColor:
                          _getCompatibilityColor(business.compatibilityScore!)
                              .withValues(alpha: 0.1),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.handshake,
                            size: 16,
                            color: _getCompatibilityColor(
                                business.compatibilityScore!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(business.compatibilityScore! * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _getCompatibilityColor(
                                      business.compatibilityScore!),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (business.metadata?['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  business.metadata!['description'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _sendPartnershipOutreach(business),
                    icon: const Icon(Icons.handshake, size: 16),
                    label: Text('Propose Partnership'),
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
