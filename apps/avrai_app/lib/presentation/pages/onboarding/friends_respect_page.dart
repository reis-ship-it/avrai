import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_suggestion_event_store.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai_runtime_os/services/locality_agents/onboarding_locality_lists.dart';

class FriendsRespectPage extends StatefulWidget {
  final List<String> respectedLists;
  final Function(List<String>) onRespectedListsChanged;
  final String? userId;
  final String? selectedHomebase;

  const FriendsRespectPage({
    super.key,
    required this.respectedLists,
    required this.onRespectedListsChanged,
    this.userId,
    this.selectedHomebase,
  });

  @override
  State<FriendsRespectPage> createState() => _FriendsRespectPageState();
}

class _FriendsRespectPageState extends State<FriendsRespectPage> {
  static const String _logName = 'FriendsRespectPage';

  List<String> _selectedLists = [];
  final Map<String, int> _respectCounts = {};
  late final OnboardingSuggestionEventStore _eventStore;
  late final List<Map<String, dynamic>> _localPublicLists;

  @override
  void initState() {
    super.initState();
    _selectedLists = List.from(widget.respectedLists);

    final cityKey =
        OnboardingLocalityLists.resolveCity(widget.selectedHomebase);
    final cityLists = OnboardingLocalityLists.getListsForCity(cityKey);
    _localPublicLists = cityLists.isNotEmpty
        ? cityLists
        : OnboardingLocalityLists.getDefaultLists();

    _eventStore = GetIt.instance.isRegistered<OnboardingSuggestionEventStore>()
        ? GetIt.instance<OnboardingSuggestionEventStore>()
        : OnboardingSuggestionEventStore();

    for (var list in _localPublicLists) {
      _respectCounts[list['name'] as String] = list['respects'] as int;
    }

    // Best-effort: log the suggestions shown on this onboarding surface.
    unawaited(_logSuggestionsShown());
  }

  Future<void> _logSuggestionsShown() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final items = _localPublicLists
          .map((l) => l['name'] as String)
          .take(20)
          .map((name) => OnboardingSuggestionItem(id: name, label: name))
          .toList();

      await _eventStore.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'friends_respect',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: 'friends_respect_local_public_lists',
          suggestions: items,
          userAction: const OnboardingSuggestionUserAction(
            type: OnboardingSuggestionActionType.shown,
          ),
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to log suggestions shown: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _logSuggestionAction({
    required OnboardingSuggestionActionType type,
    required String promptCategory,
    String? itemLabel,
  }) async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final items = _localPublicLists
          .map((l) => l['name'] as String)
          .take(20)
          .map((name) => OnboardingSuggestionItem(id: name, label: name))
          .toList();

      await _eventStore.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'friends_respect',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: promptCategory,
          suggestions: items,
          userAction: OnboardingSuggestionUserAction(
            type: type,
            item: itemLabel == null
                ? null
                : OnboardingSuggestionItem(id: itemLabel, label: itemLabel),
          ),
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to log suggestion action: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Connect & Discover',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Curated lists for your area. Add any that interest you and they\'ll appear in your spots page.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const SizedBox(height: 24),

          // Local lists section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local Public Lists',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_selectedLists.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedLists.clear();
                          });
                          widget.onRespectedListsChanged(_selectedLists);
                          unawaited(_logSuggestionAction(
                            type: OnboardingSuggestionActionType.deselect,
                            promptCategory: 'friends_respect_clear_all',
                          ));
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Curated by avrai for your area',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
                const SizedBox(height: 16),

                // Lists
                Expanded(
                  child: ListView.builder(
                    itemCount: _localPublicLists.length,
                    itemBuilder: (context, index) {
                      final list = _localPublicLists[index];
                      final listName = list['name'] as String;
                      final isSelected = _selectedLists.contains(listName);

                      return AppSurface(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            // Main list tile - for viewing details
                            ListTile(
                              onTap: () => _showListDetails(list),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  _getCategoryIcon(list['category'] as String),
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                listName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  // User profile info
                                  _buildUserProfileInfo(list),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: AppColors.grey500,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          list['location'] as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${list['spots']} spots',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Respect button
                                  GestureDetector(
                                    onTap: () {
                                      final selecting = !isSelected;
                                      setState(() {
                                        if (isSelected) {
                                          _selectedLists.remove(listName);
                                        } else {
                                          _selectedLists.add(listName);
                                        }
                                      });
                                      widget.onRespectedListsChanged(
                                          _selectedLists);
                                      unawaited(_logSuggestionAction(
                                        type: selecting
                                            ? OnboardingSuggestionActionType
                                                .select
                                            : OnboardingSuggestionActionType
                                                .deselect,
                                        promptCategory:
                                            'friends_respect_local_public_lists',
                                        itemLabel: listName,
                                      ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppColors.grey200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.add,
                                        size: 14,
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.grey700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // View details arrow
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppColors.grey400,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileInfo(Map<String, dynamic> list) {
    final userProfile = list['userProfile'] as Map<String, dynamic>;
    final expertise = userProfile['expertise'] as String;
    final locations = userProfile['locations'] as List<String>;
    final hostedEventsCount = userProfile['hostedEventsCount'] as int;
    final differentSpotsCount = userProfile['differentSpotsCount'] as int;

    return AppSurface(
      padding: const EdgeInsets.all(6),
      color: AppColors.grey50,
      borderColor: AppColors.grey200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$expertise in ${locations.join(', ')}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          Text(
            'Hosted $hostedEventsCount events at $differentSpotsCount spots',
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.grey500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showListDetails(Map<String, dynamic> list) {
    List<Map<String, dynamic>> spots = _getSpotsForList(list);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      _getCategoryIcon(list['category'] as String),
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by ${list['creator']} • ${list['spots']} spots • ${list['respects']} respects',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Spots list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: spots.length,
                itemBuilder: (context, index) {
                  final spot = spots[index];
                  return AppSurface(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          _getSpotIcon(spot['category'] as String),
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        spot['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        spot['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.grey400,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSpotsForList(Map<String, dynamic> list) {
    final spotsList = list['spotsList'] as List<Map<String, String>>?;
    if (spotsList == null) return [];
    final category = list['category'] as String? ?? 'Activities';
    return spotsList
        .map((s) => {
              'name': s['name'] ?? '',
              'description': s['location'] ?? '',
              'category': category,
            })
        .toList();
  }

  IconData _getSpotIcon(String category) {
    switch (category) {
      case 'Food & Drink':
        return Icons.restaurant;
      case 'Activities':
        return Icons.sports_soccer;
      case 'Outdoor & Nature':
        return Icons.nature;
      case 'Culture & Arts':
        return Icons.museum;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.place;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return Icons.restaurant;
      case 'culture & arts':
        return Icons.palette;
      case 'outdoor & nature':
        return Icons.nature;
      case 'activities':
        return Icons.sports_esports;
      case 'entertainment':
        return Icons.music_note;
      default:
        return Icons.place;
    }
  }
}
