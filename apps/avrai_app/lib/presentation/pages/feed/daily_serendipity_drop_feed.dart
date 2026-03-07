import 'package:flutter/material.dart' hide Colors;

import 'package:avrai/presentation/models/daily_serendipity_drop.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/common/app_status_pill.dart';
import 'package:avrai/theme/colors.dart';

/// The core feed UI for the nightly serendipity drop.
class DailySerendipityDropFeed extends StatelessWidget {
  final DailySerendipityDrop drop;

  const DailySerendipityDropFeed({
    super.key,
    required this.drop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppPageHeader(
                      title: 'Your Daily Drop',
                      subtitle:
                          'A calm summary of what deserves your attention today.',
                      leadingIcon: Icons.auto_awesome_outlined,
                      showDivider: false,
                    ),
                    const SizedBox(height: 16),
                    AppSurface(
                      color: AppColors.surfaceMuted,
                      borderColor: AppColors.borderSubtle,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              drop.llmContextualInsight,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('Event'),
                  _buildItemCard(drop.event, Icons.calendar_today_rounded),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Spot'),
                  _buildItemCard(drop.spot, Icons.location_on_outlined),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Community'),
                  _buildItemCard(drop.community, Icons.people_outline_rounded),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Club'),
                  _buildItemCard(drop.club, Icons.shield_outlined),
                  const SizedBox(height: 24),
                  if (drop.wildcard != null) ...[
                    _buildSectionHeader('Wildcard'),
                    _buildWildcardCard(drop.wildcard!),
                    const SizedBox(height: 24),
                  ],
                  if (drop.latentCommunity != null) ...[
                    _buildSectionHeader('Emerging Community'),
                    _buildLatentCommunityCard(drop.latentCommunity!),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildItemCard(DropItem item, IconData icon) {
    return AppSurface(
      color: AppColors.surface,
      borderColor: AppColors.borderSubtle,
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAffinityChip(item.archetypeAffinity),
            ],
          ),
          const SizedBox(height: 16),
          if (item is DropEvent) ...[
            _buildDetailRow(Icons.access_time, _formatTime(item.time)),
            _buildDetailRow(Icons.place_outlined, item.locationName),
          ] else if (item is DropSpot) ...[
            _buildDetailRow(Icons.category_outlined, item.category),
            _buildDetailRow(
              Icons.directions_walk,
              '${item.distanceMiles.toStringAsFixed(1)} miles away',
            ),
          ] else if (item is DropCommunity) ...[
            _buildDetailRow(
                Icons.group_outlined, '${item.memberCount} members'),
            _buildDetailRow(
              Icons.favorite_border,
              item.commonInterests.join(', '),
            ),
          ] else if (item is DropClub) ...[
            _buildDetailRow(
              Icons.assignment_ind_outlined,
              'Status: ${item.applicationStatus}',
            ),
            _buildDetailRow(Icons.waves_outlined, item.vibe),
          ],
          const SizedBox(height: 16),
          AppSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.surfaceMuted,
            borderColor: AppColors.borderSubtle,
            radius: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timeline,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.signatureSummary?.trim().isNotEmpty == true
                        ? item.signatureSummary!
                        : '${(item.archetypeAffinity * 100).toInt()}% aligned with your recent pattern',
                    style: const TextStyle(
                      color: AppColors.grey200,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWildcardCard(DropWildcard item) {
    return AppSurface(
      color: AppColors.surface,
      borderColor: AppColors.borderSubtle,
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on, color: AppColors.error),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCallout(
            icon: Icons.psychology_alt_outlined,
            title: 'Worth a second look',
            titleColor: AppColors.textSecondary,
            body: item.doubtReasoning,
          ),
          const SizedBox(height: 12),
          _buildCallout(
            icon: Icons.hub_outlined,
            title: 'Why it still fits',
            titleColor: AppColors.textSecondary,
            body: item.latentVibeMatch,
          ),
        ],
      ),
    );
  }

  Widget _buildLatentCommunityCard(DropLatentCommunity item) {
    return AppSurface(
      color: AppColors.surface,
      borderColor: AppColors.borderSubtle,
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.blur_on_outlined,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.group_work_outlined,
            '${item.discoveredMemberCount} people already fit this signal',
          ),
          const SizedBox(height: 12),
          _buildCallout(
            icon: Icons.key_outlined,
            title: 'How to start it',
            titleColor: AppColors.textSecondary,
            body: item.founderPrompt,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.selection,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Start this community'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout({
    required IconData icon,
    required String title,
    required Color titleColor,
    required String body,
  }) {
    return AppSurface(
      padding: const EdgeInsets.all(12),
      color: AppColors.surfaceMuted,
      borderColor: AppColors.borderSubtle,
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.grey300,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffinityChip(double affinity) {
    return AppStatusPill(
      color: AppColors.textSecondary,
      label: '${(affinity * 100).toInt()}%',
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.grey400, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.grey300,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
