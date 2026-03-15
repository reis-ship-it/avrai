import 'package:flutter/material.dart' hide Colors;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/models/daily_serendipity_drop.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_status_pill.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';

class DailySerendipityDropFeed extends StatefulWidget {
  final DailySerendipityDrop drop;

  const DailySerendipityDropFeed({
    super.key,
    required this.drop,
  });

  @override
  State<DailySerendipityDropFeed> createState() =>
      _DailySerendipityDropFeedState();
}

class _DailySerendipityDropFeedState extends State<DailySerendipityDropFeed> {
  final SavedDiscoveryService _savedDiscoveryService = SavedDiscoveryService();
  final RecommendationFeedbackService _feedbackService =
      RecommendationFeedbackService();
  final Set<String> _dismissedKeys = <String>{};
  late DailySerendipityDrop _drop;

  @override
  void initState() {
    super.initState();
    _drop = widget.drop;
  }

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, DropItem>>[
      MapEntry<String, DropItem>('Spot', _drop.spot),
      MapEntry<String, DropItem>('List', _drop.list),
      MapEntry<String, DropItem>('Event', _drop.event),
      MapEntry<String, DropItem>('Club', _drop.club),
      MapEntry<String, DropItem>('Community', _drop.community),
    ]
        .where((entry) => !_dismissedKeys.contains(_itemKey(entry.value)))
        .toList();

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
                      title: 'Your Birmingham Daily Drop',
                      subtitle:
                          'Five explicit recommendation doors for the BHAM beta loop.',
                      leadingIcon: Icons.auto_awesome_outlined,
                      showDivider: false,
                    ),
                    const SizedBox(height: 16),
                    AppSurface(
                      color: AppColors.surfaceMuted,
                      borderColor: AppColors.borderSubtle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                  _drop.llmContextualInsight,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _metaPill(
                                  'Generated ${_formatDateTime(_drop.generatedAtUtc)}'),
                              _metaPill(
                                  'Expires ${_formatDateTime(_drop.expiresAtUtc)}'),
                              _metaPill(
                                  _drop.refreshReason.replaceAll('_', ' ')),
                            ],
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
                  for (final entry in items) ...[
                    _buildSectionHeader(entry.key),
                    _buildItemCard(entry.value, _iconFor(entry.key)),
                    const SizedBox(height: 24),
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
          Text(
            item.attribution.why,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((item.attribution.whyDetails ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.attribution.whyDetails!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(
                '${item.attribution.projectedEnjoyabilityPercent}% enjoyability',
              ),
              _metaPill(item.attribution.recommendationSource),
              if (item.isSaved) _metaPill('Saved'),
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
          ] else if (item is DropList) ...[
            _buildDetailRow(
              Icons.format_list_numbered_rounded,
              '${item.itemCount} items',
            ),
            _buildDetailRow(Icons.edit_note_rounded, item.curatorNote),
          ] else if (item is DropCommunity) ...[
            _buildDetailRow(
              Icons.group_outlined,
              '${item.memberCount} members',
            ),
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
                const Icon(
                  Icons.timeline,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _itemSummary(item),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _toggleSaved(item),
                child: Text(item.isSaved ? 'Unsave' : 'Save'),
              ),
              FilledButton.tonal(
                onPressed: () => _dismiss(item),
                child: const Text('Dismiss'),
              ),
              FilledButton.tonal(
                onPressed: () => _sendFeedback(
                  item,
                  RecommendationFeedbackAction.moreLikeThis,
                ),
                child: const Text('More like this'),
              ),
              FilledButton.tonal(
                onPressed: () => _sendFeedback(
                  item,
                  RecommendationFeedbackAction.lessLikeThis,
                ),
                child: const Text('Less like this'),
              ),
              FilledButton.tonal(
                onPressed: () => _sendFeedback(
                  item,
                  RecommendationFeedbackAction.whyDidYouShowThis,
                ),
                child: const Text('Why this'),
              ),
              FilledButton(
                onPressed: () => _openItem(item),
                child: Text(
                  item.objectRef.routePath?.contains('/create') == true
                      ? 'Create'
                      : 'Open',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSaved(DropItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    if (item.isSaved) {
      await _savedDiscoveryService.unsave(
        userId: authState.user.id,
        entity: item.objectRef,
      );
    } else {
      await _savedDiscoveryService.save(
        userId: authState.user.id,
        entity: item.objectRef,
        sourceSurface: 'daily_drop',
        attribution: item.attribution,
      );
      await _feedbackService.submitFeedback(
        userId: authState.user.id,
        entity: item.objectRef,
        action: RecommendationFeedbackAction.save,
        sourceSurface: 'daily_drop',
        attribution: item.attribution,
      );
      await _askBack(authState.user.id, item);
    }
    await _reloadSavedState(authState.user.id);
  }

  Future<void> _dismiss(DropItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    await _feedbackService.submitFeedback(
      userId: authState.user.id,
      entity: item.objectRef,
      action: RecommendationFeedbackAction.dismiss,
      sourceSurface: 'daily_drop',
      attribution: item.attribution,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _dismissedKeys.add(_itemKey(item));
    });
    await _askBack(authState.user.id, item);
  }

  Future<void> _sendFeedback(
    DropItem item,
    RecommendationFeedbackAction action,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    await _feedbackService.submitFeedback(
      userId: authState.user.id,
      entity: item.objectRef,
      action: action,
      sourceSurface: 'daily_drop',
      attribution: item.attribution,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_feedbackMessage(action))),
    );
  }

  Future<void> _openItem(DropItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      await _feedbackService.submitFeedback(
        userId: authState.user.id,
        entity: item.objectRef,
        action: RecommendationFeedbackAction.opened,
        sourceSurface: 'daily_drop',
        attribution: item.attribution,
      );
    }

    final routePath = item.objectRef.routePath;
    if (!mounted) {
      return;
    }
    if (routePath == null || routePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This card has no route yet.')),
      );
      return;
    }
    context.go(routePath);
    if (authState is Authenticated) {
      await _askBack(authState.user.id, item);
    }
  }

  Future<void> _askBack(String userId, DropItem item) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Was this actually useful?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wave 4 records explicit meaningful and fun feedback instead of assuming it.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _feedbackService.submitFeedback(
                            userId: userId,
                            entity: item.objectRef,
                            action: RecommendationFeedbackAction.meaningful,
                            sourceSurface: 'daily_drop_ask_back',
                            attribution: item.attribution,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Meaningful'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await _feedbackService.submitFeedback(
                            userId: userId,
                            entity: item.objectRef,
                            action: RecommendationFeedbackAction.fun,
                            sourceSurface: 'daily_drop_ask_back',
                            attribution: item.attribution,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Fun'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reloadSavedState(String userId) async {
    Future<bool> isSaved(DropItem item) {
      return _savedDiscoveryService.isSaved(
        userId: userId,
        entity: item.objectRef,
      );
    }

    final nextSpot = DropSpot(
      id: _drop.spot.id,
      title: _drop.spot.title,
      subtitle: _drop.spot.subtitle,
      category: _drop.spot.category,
      distanceMiles: _drop.spot.distanceMiles,
      imageUrl: _drop.spot.imageUrl,
      signatureSummary: _drop.spot.signatureSummary,
      archetypeAffinity: _drop.spot.archetypeAffinity,
      objectRef: _drop.spot.objectRef,
      attribution: _drop.spot.attribution,
      isSaved: await isSaved(_drop.spot),
      isPlaceholder: _drop.spot.isPlaceholder,
      generatedByAi: _drop.spot.generatedByAi,
      placeholderReason: _drop.spot.placeholderReason,
    );

    final nextList = DropList(
      id: _drop.list.id,
      title: _drop.list.title,
      subtitle: _drop.list.subtitle,
      itemCount: _drop.list.itemCount,
      curatorNote: _drop.list.curatorNote,
      imageUrl: _drop.list.imageUrl,
      signatureSummary: _drop.list.signatureSummary,
      archetypeAffinity: _drop.list.archetypeAffinity,
      objectRef: _drop.list.objectRef,
      attribution: _drop.list.attribution,
      isSaved: await isSaved(_drop.list),
      isPlaceholder: _drop.list.isPlaceholder,
      generatedByAi: _drop.list.generatedByAi,
      placeholderReason: _drop.list.placeholderReason,
    );

    final nextEvent = DropEvent(
      id: _drop.event.id,
      title: _drop.event.title,
      subtitle: _drop.event.subtitle,
      time: _drop.event.time,
      locationName: _drop.event.locationName,
      imageUrl: _drop.event.imageUrl,
      signatureSummary: _drop.event.signatureSummary,
      archetypeAffinity: _drop.event.archetypeAffinity,
      objectRef: _drop.event.objectRef,
      attribution: _drop.event.attribution,
      isSaved: await isSaved(_drop.event),
      isPlaceholder: _drop.event.isPlaceholder,
      generatedByAi: _drop.event.generatedByAi,
      placeholderReason: _drop.event.placeholderReason,
    );

    final nextClub = DropClub(
      id: _drop.club.id,
      title: _drop.club.title,
      subtitle: _drop.club.subtitle,
      applicationStatus: _drop.club.applicationStatus,
      vibe: _drop.club.vibe,
      imageUrl: _drop.club.imageUrl,
      signatureSummary: _drop.club.signatureSummary,
      archetypeAffinity: _drop.club.archetypeAffinity,
      objectRef: _drop.club.objectRef,
      attribution: _drop.club.attribution,
      isSaved: await isSaved(_drop.club),
      isPlaceholder: _drop.club.isPlaceholder,
      generatedByAi: _drop.club.generatedByAi,
      placeholderReason: _drop.club.placeholderReason,
    );

    final nextCommunity = DropCommunity(
      id: _drop.community.id,
      title: _drop.community.title,
      subtitle: _drop.community.subtitle,
      memberCount: _drop.community.memberCount,
      commonInterests: _drop.community.commonInterests,
      imageUrl: _drop.community.imageUrl,
      signatureSummary: _drop.community.signatureSummary,
      archetypeAffinity: _drop.community.archetypeAffinity,
      objectRef: _drop.community.objectRef,
      attribution: _drop.community.attribution,
      isSaved: await isSaved(_drop.community),
      isPlaceholder: _drop.community.isPlaceholder,
      generatedByAi: _drop.community.generatedByAi,
      placeholderReason: _drop.community.placeholderReason,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _drop = DailySerendipityDrop(
        schemaVersion: _drop.schemaVersion,
        date: _drop.date,
        cityName: _drop.cityName,
        llmContextualInsight: _drop.llmContextualInsight,
        generatedAtUtc: _drop.generatedAtUtc,
        expiresAtUtc: _drop.expiresAtUtc,
        refreshReason: _drop.refreshReason,
        spot: nextSpot,
        list: nextList,
        event: nextEvent,
        club: nextClub,
        community: nextCommunity,
      );
    });
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

  Widget _metaPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _itemSummary(DropItem item) {
    final summary = item.signatureSummary?.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
    if (item.isPlaceholder) {
      return item.placeholderReason ??
          'This BHAM slot is explicit placeholder scaffolding.';
    }
    if (item.generatedByAi) {
      return 'This BHAM slot was generated to keep the 5-category contract intact.';
    }
    return '${(item.archetypeAffinity * 100).toInt()}% aligned with your recent pattern';
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'Spot' => Icons.location_on_outlined,
      'List' => Icons.format_list_bulleted_rounded,
      'Event' => Icons.calendar_today_rounded,
      'Club' => Icons.shield_outlined,
      _ => Icons.people_outline_rounded,
    };
  }

  String _itemKey(DropItem item) {
    return '${item.objectRef.type.name}:${item.objectRef.id}';
  }

  String _feedbackMessage(RecommendationFeedbackAction action) {
    return switch (action) {
      RecommendationFeedbackAction.moreLikeThis =>
        'We will bias toward more of this.',
      RecommendationFeedbackAction.lessLikeThis =>
        'We will pull back from this shape.',
      RecommendationFeedbackAction.whyDidYouShowThis =>
        'Recorded. This recommendation stays inspectable.',
      _ => 'Feedback recorded.',
    };
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${local.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day $hour:${local.minute.toString().padLeft(2, '0')} $period';
  }
}
