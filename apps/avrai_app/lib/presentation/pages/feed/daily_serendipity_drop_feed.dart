import 'dart:ui';
import 'package:flutter/material.dart' hide Colors;
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/models/daily_serendipity_drop.dart';
import 'package:avrai/presentation/widgets/encounter/progressive_confidence_widget.dart';

/// The core Feed UI for the Trojan Horse UX (Spike 6).
/// Displays the LLM's nightly contextual insight and exactly 4 curated items.
class DailySerendipityDropFeed extends StatelessWidget {
  final DailySerendipityDrop drop;

  const DailySerendipityDropFeed({
    super.key,
    required this.drop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Daily Drop',
                      style: TextStyle(
                        color: AppColors.electricGreen,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Derived from your physical encounters yesterday.',
                      style: TextStyle(
                        color: AppColors.grey400,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // The LLM's generated insight connecting the math to human reality
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppColors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.electricGreen, size: 24.0),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Text(
                              drop.llmContextualInsight,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16.0,
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

            // The 4 Items
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('An Event to Attend'),
                  _buildItemCard(drop.event, Icons.calendar_today_rounded),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('A Spot to Check Out'),
                  _buildItemCard(drop.spot, Icons.location_on_rounded),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('A Community to Join'),
                  _buildItemCard(drop.community, Icons.people_outline_rounded),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('A Club to Look Into'),
                  _buildItemCard(drop.club, Icons.shield_outlined),
                  const SizedBox(height: 48.0), // Bottom padding
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItemCard(DropItem item, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.electricGreen.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Background Glow based on Archetype Affinity
          Positioned(
            right: -20,
            top: -20,
            child: ProgressiveConfidenceWidget(
              confidence: item.archetypeAffinity,
              size: 100.0,
              primaryColor: AppColors.electricGreen.withOpacity(0.2),
            ),
          ),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.electricGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(icon, color: AppColors.electricGreen, size: 24.0),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: AppColors.grey400,
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Specific details based on type
                    if (item is DropEvent) ...[
                      _buildDetailRow(Icons.access_time, _formatTime(item.time)),
                      _buildDetailRow(Icons.place_outlined, item.locationName),
                    ] else if (item is DropSpot) ...[
                      _buildDetailRow(Icons.category_outlined, item.category),
                      _buildDetailRow(Icons.directions_walk, '${item.distanceMiles.toStringAsFixed(1)} miles away'),
                    ] else if (item is DropCommunity) ...[
                      _buildDetailRow(Icons.group, '${item.memberCount} members'),
                      _buildDetailRow(Icons.favorite_border, item.commonInterests.join(', ')),
                    ] else if (item is DropClub) ...[
                      _buildDetailRow(Icons.assignment_ind_outlined, 'Status: ${item.applicationStatus}'),
                      _buildDetailRow(Icons.waves, item.vibe),
                    ],
                    
                    const SizedBox(height: 16.0),
                    
                    // The "Why"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppColors.electricGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timeline, color: AppColors.electricGreen, size: 14.0),
                          const SizedBox(width: 6.0),
                          Text(
                            '${(item.archetypeAffinity * 100).toInt()}% Match with your resonance pattern',
                            style: TextStyle(
                              color: AppColors.electricGreen,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey500, size: 16.0),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: TextStyle(
              color: AppColors.grey300,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
