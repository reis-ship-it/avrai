import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/baseline_lists_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai_core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_suggestion_event_store.dart';

class BaselineListsPage extends StatefulWidget {
  final List<String> baselineLists;
  final Function(List<String>) onBaselineListsChanged;
  final String? userId;
  final String? userName;
  final Map<String, List<String>>? userPreferences;
  final List<String>? userFavoritePlaces;

  const BaselineListsPage({
    super.key,
    required this.baselineLists,
    required this.onBaselineListsChanged,
    this.userId,
    this.userName,
    this.userPreferences,
    this.userFavoritePlaces,
  });

  @override
  State<BaselineListsPage> createState() => _BaselineListsPageState();
}

class _BaselineListsPageState extends State<BaselineListsPage>
    with TickerProviderStateMixin {
  List<String> _generatedLists = [];
  final Set<String> _selectedLists = <String>{};
  bool _isLoading = true;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Show immediate suggestions and let background agent handle AI optimization
    _startLoading();
  }

  void _startLoading() async {
    _loadingController.repeat();

    // Quick loading for immediate feedback
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadingController.stop();
      _generateQuickSuggestions();
    }
  }

  void _generateQuickSuggestions() {
    final homebaseList = widget.userPreferences?['homebase'];
    final homebase = (homebaseList != null && homebaseList.isNotEmpty)
        ? homebaseList.first
        : null;
    final favoritePlaces = widget.userFavoritePlaces ?? [];
    final preferences = widget.userPreferences ?? {};

    // Generate quick, smart suggestions based on available data
    final suggestions = <String>[];

    // Add location-aware suggestions if homebase is available
    if (homebase != null && homebase.isNotEmpty) {
      suggestions.addAll([
        'Hidden Gems in $homebase',
        'Local Favorites in $homebase',
        'Weekend Adventures in $homebase',
      ]);
    } else {
      suggestions.addAll([
        'Hidden Gems',
        'Local Favorites',
        'Weekend Adventures',
      ]);
    }

    // Add preference-based suggestions
    if (preferences.containsKey('Food & Drink')) {
      suggestions.add('Coffee & Tea Spots');
      suggestions.add('Best Restaurants');
    }

    if (preferences.containsKey('Activities')) {
      suggestions.add('Entertainment Hotspots');
      suggestions.add('Activity Centers');
    }

    if (preferences.containsKey('Outdoor & Nature')) {
      suggestions.add('Outdoor Adventures');
      suggestions.add('Nature Escapes');
    }

    // Add AI-enhanced suggestions (background agent will optimize these)
    suggestions.addAll([
      'AI-Curated Local Gems',
      'Community-Recommended Spots',
      'Trending in Your Area',
    ]);

    // Add personality-based suggestions
    if (favoritePlaces.isNotEmpty) {
      suggestions.add('Places Like Your Favorites');
    }

    // Remove duplicates and limit to top suggestions
    final uniqueSuggestions = suggestions.toSet().take(8).toList();

    setState(() {
      _generatedLists = uniqueSuggestions;
      _selectedLists
        ..clear()
        ..addAll(uniqueSuggestions);
    });

    // Emit selected lists (users can deselect below).
    widget.onBaselineListsChanged(_selectedLists.toList());

    // Record “shown” event for later bootstrap (best-effort).
    final userId = widget.userId;
    if (userId != null &&
        userId.isNotEmpty &&
        GetIt.instance.isRegistered<OnboardingSuggestionEventStore>()) {
      final store = GetIt.instance<OnboardingSuggestionEventStore>();
      final items = uniqueSuggestions
          .map((s) => OnboardingSuggestionItem(id: s, label: s))
          .toList();
      store.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'baseline_lists',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: 'baseline_lists_quick_suggestions',
          suggestions: items,
          userAction: const OnboardingSuggestionUserAction(
            type: OnboardingSuggestionActionType.shown,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildBaselineListsPageSchema(
        isLoading: _isLoading,
        loadingSection: _buildLoadingSection(),
        introSection: _buildIntroSection(),
        listSection: _buildListSection(),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, child) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.psychology,
                color: AppColors.white,
                size: 40,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Creating your starter lists...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We are creating a few useful lists based on your preferences.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.grey600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You can edit these recommendations after onboarding.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    return AppSurface(
      color: AppColors.surfaceMuted,
      borderColor: AppColors.borderSubtle,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Lists',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These are suggested starting points. You can edit, remove, or add new lists at any time.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _generatedLists.length,
      itemBuilder: (context, index) {
        final listName = _generatedLists[index];
        final isSelected = _selectedLists.contains(listName);
        return AppSurface(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: ListTile(
            onTap: () => _toggleSelected(listName),
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceMuted,
              child: Icon(
                _getListIcon(listName),
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            title: Text(
              listName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _getListDescription(listName),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.textPrimary : AppColors.grey500,
              size: 24,
            ),
            tileColor:
                isSelected ? AppColors.surfaceMuted : AppColors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  void _toggleSelected(String listName) {
    setState(() {
      if (_selectedLists.contains(listName)) {
        _selectedLists.remove(listName);
      } else {
        _selectedLists.add(listName);
      }
    });

    widget.onBaselineListsChanged(_selectedLists.toList());

    final userId = widget.userId;
    if (userId != null &&
        userId.isNotEmpty &&
        GetIt.instance.isRegistered<OnboardingSuggestionEventStore>()) {
      final store = GetIt.instance<OnboardingSuggestionEventStore>();
      final wasSelected = _selectedLists.contains(listName);
      store.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'baseline_lists',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: 'baseline_lists_quick_suggestions',
          suggestions: _generatedLists
              .map((s) => OnboardingSuggestionItem(id: s, label: s))
              .toList(),
          userAction: OnboardingSuggestionUserAction(
            type: wasSelected
                ? OnboardingSuggestionActionType.select
                : OnboardingSuggestionActionType.deselect,
            item: OnboardingSuggestionItem(id: listName, label: listName),
          ),
        ),
      );
    }
  }

  IconData _getListIcon(String listName) {
    final lowerName = listName.toLowerCase();

    if (lowerName.contains('coffee') || lowerName.contains('cafe')) {
      return Icons.coffee;
    } else if (lowerName.contains('bar') ||
        lowerName.contains('pub') ||
        lowerName.contains('beer')) {
      return Icons.local_bar;
    } else if (lowerName.contains('restaurant') ||
        lowerName.contains('dining') ||
        lowerName.contains('food')) {
      return Icons.restaurant;
    } else if (lowerName.contains('music') || lowerName.contains('jazz')) {
      return Icons.music_note;
    } else if (lowerName.contains('theater') ||
        lowerName.contains('cultural')) {
      return Icons.theater_comedy;
    } else if (lowerName.contains('fitness') ||
        lowerName.contains('gym') ||
        lowerName.contains('sports')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('shopping') ||
        lowerName.contains('boutique')) {
      return Icons.shopping_bag;
    } else if (lowerName.contains('bookstore') ||
        lowerName.contains('reading')) {
      return Icons.book;
    } else if (lowerName.contains('hiking') ||
        lowerName.contains('outdoor') ||
        lowerName.contains('adventure')) {
      return Icons.hiking;
    } else if (lowerName.contains('beach') ||
        lowerName.contains('waterfront')) {
      return Icons.beach_access;
    } else if (lowerName.contains('park') || lowerName.contains('green')) {
      return Icons.park;
    } else if (lowerName.contains('ai') || lowerName.contains('curated')) {
      return Icons.psychology;
    } else if (lowerName.contains('community') ||
        lowerName.contains('trending')) {
      return Icons.people;
    } else if (lowerName.contains('hidden') || lowerName.contains('secret')) {
      return Icons.explore;
    } else if (lowerName.contains('local') || lowerName.contains('favorite')) {
      return Icons.favorite;
    } else if (lowerName.contains('chill')) {
      return Icons.coffee;
    } else if (lowerName.contains('fun')) {
      return Icons.sports_soccer;
    } else if (lowerName.contains('recommended')) {
      return Icons.star;
    } else {
      return Icons.list;
    }
  }

  String _getListDescription(String listName) {
    final lowerName = listName.toLowerCase();

    if (lowerName.contains('coffee') || lowerName.contains('cafe')) {
      return 'Perfect coffee spots and cozy cafes';
    } else if (lowerName.contains('bar') ||
        lowerName.contains('pub') ||
        lowerName.contains('beer')) {
      return 'Best bars and craft beer destinations';
    } else if (lowerName.contains('restaurant') ||
        lowerName.contains('dining')) {
      return 'Top-rated restaurants and dining experiences';
    } else if (lowerName.contains('music') || lowerName.contains('jazz')) {
      return 'Live music venues and entertainment spots';
    } else if (lowerName.contains('theater') ||
        lowerName.contains('cultural')) {
      return 'Cultural venues and performance spaces';
    } else if (lowerName.contains('fitness') || lowerName.contains('gym')) {
      return 'Fitness centers and sports facilities';
    } else if (lowerName.contains('shopping') ||
        lowerName.contains('boutique')) {
      return 'Shopping districts and unique boutiques';
    } else if (lowerName.contains('bookstore') ||
        lowerName.contains('reading')) {
      return 'Independent bookstores and reading spots';
    } else if (lowerName.contains('hiking') || lowerName.contains('outdoor')) {
      return 'Hiking trails and outdoor adventures';
    } else if (lowerName.contains('beach') ||
        lowerName.contains('waterfront')) {
      return 'Beach spots and waterfront locations';
    } else if (lowerName.contains('park') || lowerName.contains('green')) {
      return 'Parks and green spaces';
    } else if (lowerName.contains('ai') || lowerName.contains('curated')) {
      return 'AI-curated local gems and hidden treasures';
    } else if (lowerName.contains('community') ||
        lowerName.contains('trending')) {
      return 'Community-recommended and trending spots';
    } else if (lowerName.contains('hidden') || lowerName.contains('secret')) {
      return 'Hidden gems and insider secrets';
    } else if (lowerName.contains('local') || lowerName.contains('favorite')) {
      return 'Local favorites and must-visit spots';
    } else if (lowerName.contains('chill')) {
      return 'Relaxing and chill spots';
    } else if (lowerName.contains('fun')) {
      return 'Fun and exciting places';
    } else if (lowerName.contains('recommended')) {
      return 'Highly recommended spots';
    } else {
      return 'Personalized for you';
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }
}
