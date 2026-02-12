import 'package:flutter/material.dart';
import 'package:avrai/core/services/business/business_business_outreach_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Send Proposal'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partnership proposal sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh the list
        _loadRecommendedBusinesses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending partnership proposal'),
            backgroundColor: AppColors.error,
          ),
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
                          onPressed: _loadRecommendedBusinesses,
                          child: const Text('Retry'),
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
                          const Text(
                            'No businesses found',
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
                              _loadRecommendedBusinesses();
                            },
                            child: const Text('Lower Threshold'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendedBusinesses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _sendPartnershipOutreach(business),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (business.metadata?['business_type'] != null)
                          Text(
                            business.metadata!['business_type'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (business.metadata?['location'] != null)
                          Text(
                            business.metadata!['location'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (business.compatibilityScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getCompatibilityColor(business.compatibilityScore!)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
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
                            style: TextStyle(
                              color: _getCompatibilityColor(
                                  business.compatibilityScore!),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                  style: const TextStyle(
                    fontSize: 14,
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
                    label: const Text('Propose Partnership'),
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
