import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/brand/brand_analytics_page.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Brand Exposure Widget
///
/// Displays brand exposure metrics from sponsorships.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class BrandExposureWidget extends StatelessWidget {
  final BrandAnalytics analytics;

  const BrandExposureWidget({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exposure = analytics.exposureMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Exposure Metrics',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Total Reach
            _buildExposureRow(
              context,
              Icons.people,
              'Total Reach',
              _formatNumber(exposure.totalReach),
              'Total audience reached',
            ),
            const SizedBox(height: 12),

            // Impressions
            _buildExposureRow(
              context,
              Icons.visibility,
              'Impressions',
              _formatNumber(exposure.totalImpressions),
              'Total impressions',
            ),
            const SizedBox(height: 12),

            // Product Sampling
            _buildExposureRow(
              context,
              Icons.shopping_bag,
              'Product Sampling',
              exposure.productSampling.toString(),
              'People who sampled products',
            ),
            const SizedBox(height: 12),

            // Email Signups
            _buildExposureRow(
              context,
              Icons.email,
              'Email Signups',
              exposure.emailSignups.toString(),
              'New email subscribers',
            ),
            const SizedBox(height: 12),

            // Website Visits
            _buildExposureRow(
              context,
              Icons.language,
              'Website Visits',
              exposure.websiteVisits.toString(),
              'Website traffic from events',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExposureRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String description,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// BrandAnalytics, BrandExposureMetrics are imported from brand_analytics_page.dart
