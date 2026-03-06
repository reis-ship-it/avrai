import 'dart:async';

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/presentation/widgets/common/standard_error_widget.dart';
import 'package:avrai/presentation/widgets/common/standard_loading_widget.dart';
import 'package:avrai/presentation/widgets/common/source_indicator_widget.dart';
import 'package:avrai/presentation/widgets/reservations/spot_reservation_badge_widget.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

IconData _resolveSourceIcon(int codePoint) {
  final icon = <int, IconData>{
    Icons.verified.codePoint: Icons.verified,
    Icons.public.codePoint: Icons.public,
    Icons.group.codePoint: Icons.group,
    Icons.map.codePoint: Icons.map,
    Icons.location_on.codePoint: Icons.location_on,
  }[codePoint];
  return icon ?? Icons.info_outline;
}

class HybridSearchResults extends StatelessWidget {
  const HybridSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HybridSearchBloc, HybridSearchState>(
      builder: (context, state) {
        if (state is HybridSearchInitial) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Search for spots',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find community spots and external places',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is HybridSearchLoading) {
          return StandardLoadingWidget.fullScreen(
            message: 'Searching community and external sources...',
          );
        }

        if (state is HybridSearchError) {
          return StandardErrorWidget.fullScreen(
            message: state.message,
            onRetry: () {
              context.read<HybridSearchBloc>().add(ClearHybridSearch());
            },
            retryLabel: 'Try Again',
          );
        }

        if (state is HybridSearchLoaded) {
          if (state.spots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No spots found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try a different search term or location',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchStats(context, state),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Statistics Header
              _buildSearchStats(context, state),
              const SizedBox(height: 8),

              // Results List
              Expanded(
                child: ListView.builder(
                  itemCount: state.spots.length,
                  itemBuilder: (context, index) {
                    final spot = state.spots[index];
                    return _buildSpotCard(context, state, spot, index);
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchStats(BuildContext context, HybridSearchLoaded state) {
    return Card(
      color:
          state.isCommunityPrioritized ? AppColors.grey100 : AppColors.grey100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  state.isCommunityPrioritized
                      ? Icons.verified_user
                      : Icons.warning_amber,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isCommunityPrioritized
                            ? 'Community-First Results'
                            : 'External Data Heavy',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${state.totalCount} total • ${state.communityCount} community • ${state.externalCount} external',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(state.searchDuration.inMilliseconds)}ms',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (state.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: state.sources.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppColors.grey100,
                    side: const BorderSide(color: AppColors.grey300),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpotCard(
    BuildContext context,
    HybridSearchLoaded state,
    Spot spot,
    int index,
  ) {
    final indicator = spot.getSourceIndicator();
    final metadata =
        index < state.metadata.length ? state.metadata[index] : null;
    // Check if spot accepts reservations (community spots can, external spots can't)
    final isReservable = !spot.metadata.containsKey('is_external') ||
        spot.metadata['is_external'] != true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Color(indicator.badgeColor),
          child: Icon(
            _resolveSourceIcon(indicator.badgeIcon),
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                spot.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Use SourceIndicator for consistent source display
            SourceIndicatorWidget(
              indicator: indicator,
              compact: true,
              showWarning: false,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (metadata != null) ...[
              Text(
                metadata.matchReason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              spot.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (metadata != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      metadata.usedSignaturePrimary
                          ? 'Fit ${(metadata.relevanceScore * 100).round()}%'
                          : 'Fallback ${(metadata.relevanceScore * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (spot.rating > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 2),
                  Text(
                    '${spot.rating}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (metadata?.distance != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.near_me,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Text(
                    metadata!.distance! < 1000
                        ? '${metadata.distance!.round()}m'
                        : '${(metadata.distance! / 1000).toStringAsFixed(1)}km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (spot.address != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      spot.address!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            // Reservation badge
            if (isReservable) ...[
              const SizedBox(height: 8),
              SpotReservationBadgeWidget(
                isAvailable: true,
                compact: true,
                onTap: () {
                  _recordSpotReservationIntent(spot);
                  // Quick reservation action
                  context.push(
                    '/reservations/create',
                    extra: {
                      'type': ReservationType.spot,
                      'targetId': spot.id,
                      'targetTitle': spot.name,
                    },
                  );
                },
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reservation button (if reservable)
            if (isReservable)
              IconButton(
                icon: const Icon(Icons.event_available, size: 20),
                tooltip: 'Quick Reserve',
                onPressed: () {
                  _recordSpotReservationIntent(spot);
                  context.push(
                    '/reservations/create',
                    extra: {
                      'type': ReservationType.spot,
                      'targetId': spot.id,
                      'targetTitle': spot.name,
                    },
                  );
                },
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          _recordSpotSearchSelection(spot, state.searchQuery ?? '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpotDetailsPage(spot: spot),
            ),
          );
        },
      ),
    );
  }

  void _recordSpotSearchSelection(Spot spot, String query) {
    final userId = _currentUserId();
    if (userId == null || !di.sl.isRegistered<EntitySignatureService>()) {
      return;
    }

    unawaited(
      di.sl<EntitySignatureService>().recordSpotSearchSelectionSignal(
            userId: userId,
            spot: spot,
            query: query,
          ),
    );
  }

  void _recordSpotReservationIntent(Spot spot) {
    final userId = _currentUserId();
    if (userId == null || !di.sl.isRegistered<EntitySignatureService>()) {
      return;
    }

    unawaited(
      di.sl<EntitySignatureService>().recordSpotReservationIntentSignal(
            userId: userId,
            spot: spot,
          ),
    );
  }

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}
