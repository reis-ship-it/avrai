import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/user.dart' as app_user;
import 'package:avrai_runtime_os/services/recommendations/explore_discovery_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';

enum _ExploreViewMode {
  list,
  map,
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ExploreDiscoveryService _discoveryService = ExploreDiscoveryService();
  final SavedDiscoveryService _savedDiscoveryService = SavedDiscoveryService();
  final RecommendationFeedbackService _feedbackService =
      RecommendationFeedbackService();

  ExploreDiscoveryResult? _result;
  bool _isLoading = true;
  String? _error;
  DiscoveryEntityType _selectedType = DiscoveryEntityType.spot;
  _ExploreViewMode _viewMode = _ExploreViewMode.list;
  final Set<String> _dismissedKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to explore Birmingham recommendations.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _discoveryService.load(
        user: _toUnifiedUser(authState.user),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load Explore: $error';
      });
    }
  }

  List<ExploreDiscoveryItem> get _selectedItems {
    final items =
        (_result?.itemsFor(_selectedType) ?? const <ExploreDiscoveryItem>[])
            .where((item) => !_dismissedKeys.contains(_itemKey(item)))
            .toList();
    final saved = items.where((item) => item.isSaved).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final recommended = items.where((item) => !item.isSaved).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return <ExploreDiscoveryItem>[...saved, ...recommended];
  }

  List<ExploreDiscoveryItem> get _mappableItems {
    return _selectedItems.where((item) => item.canRenderOnMap).toList();
  }

  Future<void> _toggleSaved(ExploreDiscoveryItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }

    final userId = authState.user.id;
    if (item.isSaved) {
      await _savedDiscoveryService.unsave(
        userId: userId,
        entity: item.entity,
      );
    } else {
      await _savedDiscoveryService.save(
        userId: userId,
        entity: item.entity,
        sourceSurface: 'explore',
        attribution: item.attribution,
      );
      await _feedbackService.submitFeedback(
        userId: userId,
        entity: item.entity,
        action: RecommendationFeedbackAction.save,
        sourceSurface: 'explore',
        attribution: item.attribution,
      );
      await _askBack(userId: userId, item: item);
    }
    await _load();
  }

  Future<void> _dismiss(ExploreDiscoveryItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    await _feedbackService.submitFeedback(
      userId: authState.user.id,
      entity: item.entity,
      action: RecommendationFeedbackAction.dismiss,
      sourceSurface: 'explore',
      attribution: item.attribution,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _dismissedKeys.add(_itemKey(item));
    });
    await _askBack(userId: authState.user.id, item: item);
  }

  Future<void> _sendFeedback(
    ExploreDiscoveryItem item,
    RecommendationFeedbackAction action,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    await _feedbackService.submitFeedback(
      userId: authState.user.id,
      entity: item.entity,
      action: action,
      sourceSurface: 'explore',
      attribution: item.attribution,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_feedbackMessage(action))),
    );
  }

  Future<void> _openItem(ExploreDiscoveryItem item) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      await _feedbackService.submitFeedback(
        userId: authState.user.id,
        entity: item.entity,
        action: RecommendationFeedbackAction.opened,
        sourceSurface: 'explore',
        attribution: item.attribution,
      );
    }

    if (!mounted) {
      return;
    }
    final routePath = item.entity.routePath;
    if (routePath == null || routePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item has no route yet.')),
      );
      return;
    }
    context.go(routePath);
    if (authState is Authenticated) {
      await _askBack(userId: authState.user.id, item: item);
    }
  }

  Future<void> _askBack({
    required String userId,
    required ExploreDiscoveryItem item,
  }) async {
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
                Text(
                  'Was this actually useful?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wave 4 records explicit meaningful and fun feedback instead of implying it.',
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
                            entity: item.entity,
                            action: RecommendationFeedbackAction.meaningful,
                            sourceSurface: 'explore_ask_back',
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
                            entity: item.entity,
                            action: RecommendationFeedbackAction.fun,
                            sourceSurface: 'explore_ask_back',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          const Text(
            'Explore Birmingham',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'One discovery surface for spots, lists, events, clubs, and communities.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildCategorySelector(),
          const SizedBox(height: 12),
          _buildViewModeSelector(),
          const SizedBox(height: 20),
          if (_viewMode == _ExploreViewMode.map)
            _buildMapMode()
          else
            _buildListMode(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DiscoveryEntityType.values.map((type) {
        return ChoiceChip(
          label: Text(_typeLabel(type)),
          selected: _selectedType == type,
          onSelected: (_) {
            setState(() {
              _selectedType = type;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildViewModeSelector() {
    return Wrap(
      spacing: 8,
      children: _ExploreViewMode.values.map((mode) {
        return ChoiceChip(
          label: Text(mode == _ExploreViewMode.list ? 'List' : 'Map'),
          selected: _viewMode == mode,
          onSelected: (_) {
            setState(() {
              _viewMode = mode;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMapMode() {
    if (_selectedType == DiscoveryEntityType.list && _mappableItems.isEmpty) {
      return const AppSurface(
        child: Text(
          'These lists do not have a stable spatial centroid yet, so they stay in list mode until member spots provide one.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    if (_mappableItems.isEmpty) {
      return const AppSurface(
        child: Text(
          'No mappable items are available for this category right now.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final center = LatLng(
      _mappableItems.first.entity.latitude ?? 33.5186,
      _mappableItems.first.entity.longitude ?? -86.8104,
    );

    return SizedBox(
      height: 420,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 11.5,
            onTap: (_, __) {},
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.avrai.app',
            ),
            MarkerLayer(
              markers: _mappableItems.map((item) {
                return Marker(
                  point: LatLng(
                    item.entity.latitude!,
                    item.entity.longitude!,
                  ),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showMapItem(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _typeColor(item.entity.type),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(
                        _typeIcon(item.entity.type),
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListMode() {
    if (_selectedItems.isEmpty) {
      return AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No ${_typeLabel(_selectedType).toLowerCase()}s are ready right now.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wave 4 keeps empty states explicit and routes them into creation instead of dead ends.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(_createRouteFor(_selectedType)),
              child: Text('Create ${_typeLabel(_selectedType)}'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _selectedItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildItemCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildItemCard(ExploreDiscoveryItem item) {
    return AppSurface(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(item.entity.type).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _typeIcon(item.entity.type),
                  color: _typeColor(item.entity.type),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (item.secondaryMeta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.secondaryMeta!,
                        style: const TextStyle(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.scoreLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.isSaved)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Saved',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
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
              _pill(
                  '${item.attribution.projectedEnjoyabilityPercent}% enjoyability'),
              _pill(item.attribution.recommendationSource),
              if (item.isLiveNow) _pill('Live now'),
            ],
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
                  item.entity.routePath?.contains('/create') == true
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

  Future<void> _showMapItem(ExploreDiscoveryItem item) async {
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
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.attribution.why,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openItem(item);
                    },
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
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

  String _itemKey(ExploreDiscoveryItem item) {
    return '${item.entity.type.name}:${item.entity.id}';
  }

  String _typeLabel(DiscoveryEntityType type) {
    return switch (type) {
      DiscoveryEntityType.spot => 'Spot',
      DiscoveryEntityType.list => 'List',
      DiscoveryEntityType.event => 'Event',
      DiscoveryEntityType.club => 'Club',
      DiscoveryEntityType.community => 'Community',
    };
  }

  IconData _typeIcon(DiscoveryEntityType type) {
    return switch (type) {
      DiscoveryEntityType.spot => Icons.place_outlined,
      DiscoveryEntityType.list => Icons.format_list_bulleted_rounded,
      DiscoveryEntityType.event => Icons.event_outlined,
      DiscoveryEntityType.club => Icons.shield_outlined,
      DiscoveryEntityType.community => Icons.groups_outlined,
    };
  }

  Color _typeColor(DiscoveryEntityType type) {
    return switch (type) {
      DiscoveryEntityType.spot => AppColors.primary,
      DiscoveryEntityType.list => AppColors.grey500,
      DiscoveryEntityType.event => AppTheme.warningColor,
      DiscoveryEntityType.club => AppColors.success,
      DiscoveryEntityType.community => AppColors.grey500,
    };
  }

  String _createRouteFor(DiscoveryEntityType type) {
    return switch (type) {
      DiscoveryEntityType.spot => '/spot/create',
      DiscoveryEntityType.list => '/list/create',
      DiscoveryEntityType.event => '/event/create',
      DiscoveryEntityType.club => '/club/create',
      DiscoveryEntityType.community => '/community/create',
    };
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

  UnifiedUser _toUnifiedUser(app_user.User user) {
    return UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      photoUrl: null,
      location: null,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: user.curatedLists,
      collaboratedLists: user.collaboratedLists,
      followedLists: user.followedLists,
      primaryRole: UserRole.follower,
      isAgeVerified: false,
      ageVerificationDate: null,
    );
  }
}
