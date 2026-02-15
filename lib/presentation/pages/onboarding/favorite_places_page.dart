import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai/core/services/onboarding/onboarding_suggestion_event_store.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

class FavoritePlacesPage extends StatefulWidget {
  final List<String> favoritePlaces;
  final Function(List<String>) onPlacesChanged;
  final String? userId;
  final String? userHomebase; // Add user's homebase for smart suggestions
  final VoidCallback? onDismissSnackBars; // Callback to dismiss SnackBars

  const FavoritePlacesPage({
    super.key,
    required this.favoritePlaces,
    required this.onPlacesChanged,
    this.userId,
    this.userHomebase,
    this.onDismissSnackBars,
  });

  @override
  State<FavoritePlacesPage> createState() => _FavoritePlacesPageState();
}

class _FavoritePlacesPageState extends State<FavoritePlacesPage> {
  static const String _logName = 'FavoritePlacesPage';

  late final OnboardingSuggestionEventStore _eventStore;
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedPlaces = [];
  List<String> _suggestions = [];
  List<String> _allPlaces = [];
  String? _currentRegion;
  String? _currentCity;
  int _vibeSuggestionsShown = 0; // Track how many times we've shown suggestions

  // State for auto-expanding categories during search
  final Set<String> _expandedRegions = {};
  final Map<String, Set<String>> _expandedCities = {};

  // Method to dismiss any active SnackBars
  void dismissSnackBars() {
    if (mounted) {
      context.clearAllSnackBars();
    }
  }

  Future<void> _logSuggestionsShown({
    required String promptCategory,
    required List<String> suggestions,
  }) async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _eventStore.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'favorite_places',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: promptCategory,
          suggestions: suggestions
              .take(12)
              .map((s) => OnboardingSuggestionItem(id: s, label: s))
              .toList(),
          userAction: const OnboardingSuggestionUserAction(
            type: OnboardingSuggestionActionType.shown,
          ),
        ),
      );
    } catch (e, st) {
      developer.log('Failed to log suggestions shown: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> _logSuggestionAction({
    required OnboardingSuggestionActionType type,
    required String promptCategory,
    required String itemLabel,
  }) async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _eventStore.appendForUser(
        userId: userId,
        event: OnboardingSuggestionEvent(
          eventId: OnboardingSuggestionEvent.newEventId(),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          surface: 'favorite_places',
          provenance: OnboardingSuggestionProvenance.heuristic,
          promptCategory: promptCategory,
          suggestions: _suggestions
              .take(12)
              .map((s) => OnboardingSuggestionItem(id: s, label: s))
              .toList(),
          userAction: OnboardingSuggestionUserAction(
            type: type,
            item: OnboardingSuggestionItem(id: itemLabel, label: itemLabel),
          ),
        ),
      );
    } catch (e, st) {
      developer.log('Failed to log suggestion action: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  // Vibe-based categorization with progressive drill-down
  final Map<String, Map<String, List<String>>> _vibeCategories = {
    'New York Area': {
      'Brooklyn': [
        'Brooklyn',
        'Park Slope',
        'Williamsburg',
        'Bushwick',
        'Crown Heights',
        'Greenpoint',
        'DUMBO',
        'Prospect Heights',
        'Carroll Gardens'
      ],
      'Manhattan': [
        'Manhattan',
        'East Village',
        'West Village',
        'SoHo',
        'Lower East Side',
        'Chelsea',
        'Upper West Side',
        'Harlem',
        'Washington Heights'
      ],
      'Queens': [
        'Queens',
        'Astoria',
        'Long Island City',
        'Forest Hills',
        'Jackson Heights'
      ],
      'The Bronx': ['The Bronx', 'Riverdale', 'Mott Haven', 'Pelham Bay'],
      'Staten Island': ['Staten Island', 'St. George', 'Tottenville'],
    },
    'Los Angeles Area': {
      'Los Angeles': [
        'Los Angeles',
        'Venice Beach',
        'Marina del Rey',
        'Playa del Rey'
      ],
      'Silver Lake': ['Silver Lake', 'Echo Park', 'Los Feliz'],
      'Westside': ['Westside', 'Santa Monica', 'Brentwood', 'Westwood'],
      'Downtown': ['Downtown LA', 'Arts District', 'Little Tokyo', 'Chinatown'],
      'Hollywood': ['Hollywood', 'West Hollywood', 'Beverly Hills'],
    },
    'San Francisco Area': {
      'San Francisco': [
        'San Francisco',
        'Mission District',
        'Valencia Corridor',
        'Dolores Park'
      ],
      'North Beach': ['North Beach', 'Fisherman\'s Wharf', 'Telegraph Hill'],
      'Marina': ['Marina District', 'Cow Hollow', 'Pacific Heights'],
      'Haight-Ashbury': ['Haight-Ashbury', 'Cole Valley', 'Upper Haight'],
      'SOMA': ['SOMA', 'South Beach', 'Rincon Hill'],
    },
    'Chicago Area': {
      'Chicago': ['Chicago', 'Wicker Park', 'Lincoln Park', 'Lakeview'],
      'West Loop': ['West Loop', 'Fulton Market', 'Ukrainian Village'],
      'South Side': ['South Side', 'Hyde Park', 'Pilsen'],
      'North Side': ['North Side', 'Andersonville', 'Edgewater'],
    },
    'Miami Area': {
      'Miami': ['Miami', 'South Beach', 'Wynwood', 'Brickell'],
      'Miami Beach': ['Miami Beach', 'North Beach', 'Mid-Beach'],
      'Coral Gables': ['Coral Gables', 'Coconut Grove'],
    },
    'Austin Area': {
      'Austin': ['Austin', 'East Austin', 'South Congress', 'Downtown'],
      'West Austin': ['West Austin', 'Clarksville', 'Tarrytown'],
    },
    'Seattle Area': {
      'Seattle': ['Seattle', 'Capitol Hill', 'Fremont', 'Ballard'],
      'Downtown': ['Downtown Seattle', 'Belltown', 'Pioneer Square'],
    },
    'Portland Area': {
      'Portland': ['Portland', 'Pearl District', 'Alberta Arts', 'Hawthorne'],
      'East Portland': ['East Portland', 'Division', 'Woodstock'],
    },
    'Denver Area': {
      'Denver': ['Denver', 'RiNo', 'LoDo', 'Highland'],
      'Boulder': ['Boulder', 'Pearl Street', 'University Hill'],
    },
    'Nashville Area': {
      'Nashville': ['Nashville', 'East Nashville', 'Germantown', 'The Gulch'],
      'Downtown': ['Downtown Nashville', 'Broadway', 'SoBro'],
    },
    'Europe': {
      'Paris': [
        'Le Marais',
        'Montmartre',
        'Saint-Germain',
        'Canal Saint-Martin'
      ],
      'London': ['Shoreditch', 'Camden', 'Notting Hill', 'Soho'],
      'Barcelona': ['Gothic Quarter', 'El Born', 'Gracia', 'Barceloneta'],
      'Amsterdam': ['Jordaan', 'De Pijp', 'Oud-West', 'Centrum'],
    },
    'Asia': {
      'Tokyo': ['Shibuya', 'Harajuku', 'Shinjuku', 'Ginza'],
      'Seoul': ['Hongdae', 'Gangnam', 'Itaewon', 'Myeongdong'],
      'Bangkok': ['Sukhumvit', 'Silom', 'Chinatown', 'Thonglor'],
      'Singapore': ['Tiong Bahru', 'Kampong Glam', 'Chinatown', 'Little India'],
    },
  };

  // Smart suggestions based on user's homebase
  List<String> _getSmartSuggestions() {
    if (widget.userHomebase == null) {
      return _getDefaultSuggestions();
    }

    // Find vibe-similar places based on user's homebase
    List<String> suggestions = [];

    // Extract city/area from homebase
    String homebase = widget.userHomebase!.toLowerCase();

    if (homebase.contains('brooklyn') ||
        homebase.contains('manhattan') ||
        homebase.contains('nyc')) {
      suggestions.addAll(_vibeCategories['New York Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else if (homebase.contains('los angeles') || homebase.contains('la')) {
      suggestions.addAll(_vibeCategories['Los Angeles Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else if (homebase.contains('san francisco') || homebase.contains('sf')) {
      suggestions.addAll(_vibeCategories['San Francisco Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else {
      // Default to a mix of popular places
      suggestions.addAll(_getDefaultSuggestions());
    }

    return suggestions;
  }

  List<String> _getDefaultSuggestions() {
    return [
      'Park Slope, Brooklyn',
      'Williamsburg, Brooklyn',
      'East Village, Manhattan',
      'Mission District, San Francisco',
      'Venice Beach, Los Angeles',
      'Shoreditch, London',
      'Le Marais, Paris',
      'Shibuya, Tokyo',
      'Hongdae, Seoul',
      'Tiong Bahru, Singapore'
    ];
  }

  @override
  void initState() {
    super.initState();
    _eventStore = GetIt.instance.isRegistered<OnboardingSuggestionEventStore>()
        ? GetIt.instance<OnboardingSuggestionEventStore>()
        : OnboardingSuggestionEventStore();
    _selectedPlaces = List.from(widget.favoritePlaces);
    _suggestions = _getSmartSuggestions();
    _allPlaces = _vibeCategories.values
        .expand((cities) => cities.values)
        .expand((neighborhoods) => neighborhoods)
        .toList();

    // Best-effort: log initial suggestions shown.
    unawaited(_logSuggestionsShown(
      promptCategory: 'favorite_places_smart_suggestions',
      suggestions: _suggestions,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'What matches your vibe?',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            'Select places that match your aesthetic and lifestyle preferences.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.grey600,
            ),
          ),
          SizedBox(height: spacing.lg),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for places that match your vibe...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = _getSmartSuggestions();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          SizedBox(height: spacing.lg),

          // Selected places - Smaller and adaptive
          if (_selectedPlaces.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Selected (${_selectedPlaces.length}):',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlaces.clear();
                    });
                    widget.onPlacesChanged(_selectedPlaces);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Container(
              constraints: const BoxConstraints(maxHeight: 60),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedPlaces.length,
                itemBuilder: (context, index) {
                  final place = _selectedPlaces[index];
                  return Container(
                    margin: EdgeInsets.only(right: spacing.xs),
                    child: Chip(
                      label: Text(
                        place,
                        style: textTheme.labelSmall,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removePlace(place),
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      deleteIconColor: AppTheme.primaryColor,
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: spacing.md),
          ],

          // Search results and vibe categories
          Expanded(
            child: Column(
              children: [
                // Show search results if there's a search query.
                // Use Flexible instead of a fixed-height container to avoid RenderFlex overflow
                // on smaller screens / tighter viewports.
                if (_searchController.text.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Search Results',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _buildSearchResults(),
                  ),
                  SizedBox(height: spacing.md),
                ],

                // Always show vibe categories
                Expanded(child: _buildVibeCategories()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeCategories() {
    return ListView.builder(
      itemCount: _vibeCategories.length,
      itemBuilder: (context, index) {
        final region = _vibeCategories.keys.elementAt(index);
        final cities = _vibeCategories[region]!;
        final isRegionExpanded = _expandedRegions.contains(region);

        return PortalSurface(
          margin: EdgeInsets.only(bottom: context.spacing.md),
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            initiallyExpanded: isRegionExpanded,
            onExpansionChanged: (expanded) {
              if (!mounted) return;
              setState(() {
                if (expanded) {
                  _currentRegion = region;
                } else if (_currentRegion == region) {
                  _currentRegion = null;
                }
              });
            },
            title: Row(
              children: [
                Icon(
                  _getRegionIcon(region),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Text(
                    region,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (_getSelectedCountForRegion(region) > 0)
                  Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    side: BorderSide.none,
                    label: Text(
                      '${_getSelectedCountForRegion(region)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            children: cities.entries.map((cityEntry) {
              final city = cityEntry.key;
              final neighborhoods = cityEntry.value;
              final isCityExpanded =
                  _expandedCities[region]?.contains(city) ?? false;

              return ExpansionTile(
                initiallyExpanded: isCityExpanded,
                onExpansionChanged: (expanded) {
                  if (!mounted) return;
                  setState(() {
                    if (expanded) {
                      _currentCity = city;
                    } else if (_currentCity == city) {
                      _currentCity = null;
                    }
                  });
                },
                title: Text(city),
                children: neighborhoods.map((neighborhood) {
                  final fullName = '$neighborhood, $city';
                  final isSelected = _selectedPlaces.contains(fullName);

                  return ListTile(
                    title: Text(neighborhood),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.location_on_outlined,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppColors.grey600,
                      size: 20,
                    ),
                    onTap: () {
                      if (isSelected) {
                        unawaited(_logSuggestionAction(
                          type: OnboardingSuggestionActionType.deselect,
                          promptCategory: 'favorite_places_vibe_categories',
                          itemLabel: fullName,
                        ));
                        _removePlace(fullName);
                      } else {
                        unawaited(_logSuggestionAction(
                          type: OnboardingSuggestionActionType.select,
                          promptCategory: 'favorite_places_vibe_categories',
                          itemLabel: fullName,
                        ));
                        _addPlace(fullName);
                      }
                    },
                    tileColor: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : null,
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        final isSelected = _selectedPlaces.contains(place);

        return ListTile(
          leading: Icon(
            isSelected ? Icons.check_circle : Icons.location_on_outlined,
            color: isSelected ? AppTheme.primaryColor : AppColors.grey600,
          ),
          title: Text(place),
          trailing: isSelected
              ? const Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.errorColor,
                )
              : null,
          onTap: () {
            if (isSelected) {
              unawaited(_logSuggestionAction(
                type: OnboardingSuggestionActionType.deselect,
                promptCategory: 'favorite_places_search_suggestions',
                itemLabel: place,
              ));
              _removePlace(place);
            } else {
              unawaited(_logSuggestionAction(
                type: OnboardingSuggestionActionType.select,
                promptCategory: 'favorite_places_search_suggestions',
                itemLabel: place,
              ));
              _addPlace(place);
            }
          },
          tileColor:
              isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  IconData _getRegionIcon(String region) {
    switch (region) {
      case 'New York Area':
        return Icons.location_city;
      case 'Los Angeles Area':
        return Icons.wb_sunny;
      case 'San Francisco Area':
        return Icons.location_city;
      case 'Europe':
        return Icons.flight;
      case 'Asia':
        return Icons.temple_buddhist;
      default:
        return Icons.location_on;
    }
  }

  int _getSelectedCountForRegion(String region) {
    final cities = _vibeCategories[region]!;
    int count = 0;
    for (final city in cities.keys) {
      for (final neighborhood in cities[city]!) {
        final fullName = '$neighborhood, $city';
        if (_selectedPlaces.contains(fullName)) {
          count++;
        }
      }
    }
    return count;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _suggestions = _getSmartSuggestions();
        // Reset expanded categories when search is cleared
        _expandedRegions.clear();
        _expandedCities.clear();
      } else {
        // First, search within existing places
        List<String> existingMatches = _allPlaces
            .where((place) => place.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // If no exact matches, allow free text entry
        if (existingMatches.isEmpty && query.trim().isNotEmpty) {
          existingMatches = [query.trim()];
        }

        _suggestions = existingMatches;

        // Auto-expand categories that contain matching places
        _autoExpandMatchingCategories(query.toLowerCase());
      }
    });
  }

  void _autoExpandMatchingCategories(String query) {
    _expandedRegions.clear();
    _expandedCities.clear();

    // Search through all regions and cities for matches
    for (final region in _vibeCategories.keys) {
      final cities = _vibeCategories[region]!;
      bool regionHasMatch = false;

      for (final city in cities.keys) {
        final neighborhoods = cities[city]!;
        bool cityHasMatch = false;

        // Check if any neighborhood in this city matches the query
        for (final neighborhood in neighborhoods) {
          if (neighborhood.toLowerCase().contains(query) ||
              city.toLowerCase().contains(query) ||
              region.toLowerCase().contains(query)) {
            cityHasMatch = true;
            regionHasMatch = true;
            break;
          }
        }

        // If city has matches, expand it
        if (cityHasMatch) {
          _expandedCities[region] ??= {};
          _expandedCities[region]!.add(city);
        }
      }

      // If region has matches, expand it
      if (regionHasMatch) {
        _expandedRegions.add(region);
      }
    }
  }

  void _addPlace(String place) {
    if (!_selectedPlaces.contains(place)) {
      if (mounted) {
        setState(() {
          _selectedPlaces.add(place);
        });
        widget.onPlacesChanged(_selectedPlaces);

        // Show vibe-similar suggestions after adding a place
        _showVibeSuggestions(place);
      }
    }
  }

  void _removePlace(String place) {
    if (mounted) {
      setState(() {
        _selectedPlaces.remove(place);
      });
      widget.onPlacesChanged(_selectedPlaces);
    }
  }

  void _showVibeSuggestions(String selectedPlace) {
    // Only show suggestions for the first 2 selections to avoid being intrusive
    if (_vibeSuggestionsShown >= 2) {
      return;
    }

    // Get vibe-similar places based on the selected location
    List<String> vibeSuggestions = _getVibeSuggestions(selectedPlace);

    if (vibeSuggestions.isNotEmpty) {
      _vibeSuggestionsShown++;
      unawaited(_logSuggestionsShown(
        promptCategory: 'favorite_places_vibe_suggestions',
        suggestions: vibeSuggestions,
      ));

      // Show a snackbar with vibe suggestions - shorter duration and easier to dismiss
      context.showCustomSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Similar vibe places:',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      context.hideCurrentSnack();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.xs),
              Wrap(
                spacing: context.spacing.xs,
                children: vibeSuggestions
                    .map((suggestion) => ActionChip(
                          label: Text(suggestion),
                          onPressed: () {
                            unawaited(_logSuggestionAction(
                              type: OnboardingSuggestionActionType.select,
                              promptCategory:
                                  'favorite_places_vibe_suggestions',
                              itemLabel: suggestion,
                            ));
                            _addPlace(suggestion);
                            context.hideCurrentSnack();
                          },
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          labelStyle: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.primaryColor),
                        ))
                    .toList(),
              ),
            ],
          ),
          duration: const Duration(seconds: 3), // Shorter duration
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: AppTheme.primaryColor,
            onPressed: () {
              context.hideCurrentSnack();
            },
          ),
        ),
      );
    }
  }

  List<String> _getVibeSuggestions(String place) {
    // Vibe matching logic based on the selected place
    String placeLower = place.toLowerCase();
    List<String> suggestions = [];

    // European cities vibe matching
    if (placeLower.contains('paris') || placeLower.contains('france')) {
      suggestions.addAll([
        'Milan, Italy',
        'Barcelona, Spain',
        'Amsterdam, Netherlands',
        'Berlin, Germany',
        'Vienna, Austria',
        'Prague, Czech Republic',
        'Rome, Italy',
        'Florence, Italy',
        'Venice, Italy'
      ]);
    } else if (placeLower.contains('london') ||
        placeLower.contains('uk') ||
        placeLower.contains('england')) {
      suggestions.addAll([
        'Edinburgh, Scotland',
        'Dublin, Ireland',
        'Manchester, UK',
        'Bristol, UK',
        'Brighton, UK',
        'Oxford, UK'
      ]);
    } else if (placeLower.contains('barcelona') ||
        placeLower.contains('spain')) {
      suggestions.addAll([
        'Madrid, Spain',
        'Valencia, Spain',
        'Seville, Spain',
        'Lisbon, Portugal',
        'Porto, Portugal',
        'Milan, Italy'
      ]);
    } else if (placeLower.contains('amsterdam') ||
        placeLower.contains('netherlands')) {
      suggestions.addAll([
        'Rotterdam, Netherlands',
        'Utrecht, Netherlands',
        'The Hague, Netherlands',
        'Copenhagen, Denmark',
        'Stockholm, Sweden',
        'Oslo, Norway'
      ]);
    }
    // Asian cities vibe matching
    else if (placeLower.contains('tokyo') || placeLower.contains('japan')) {
      suggestions.addAll([
        'Kyoto, Japan',
        'Osaka, Japan',
        'Seoul, South Korea',
        'Busan, South Korea',
        'Taipei, Taiwan',
        'Hong Kong'
      ]);
    } else if (placeLower.contains('seoul') || placeLower.contains('korea')) {
      suggestions.addAll([
        'Busan, South Korea',
        'Tokyo, Japan',
        'Kyoto, Japan',
        'Taipei, Taiwan',
        'Hong Kong',
        'Singapore'
      ]);
    } else if (placeLower.contains('bangkok') ||
        placeLower.contains('thailand')) {
      suggestions.addAll([
        'Chiang Mai, Thailand',
        'Phuket, Thailand',
        'Ho Chi Minh City, Vietnam',
        'Hanoi, Vietnam',
        'Singapore',
        'Kuala Lumpur, Malaysia'
      ]);
    }
    // US cities vibe matching
    else if (placeLower.contains('new york') ||
        placeLower.contains('nyc') ||
        placeLower.contains('brooklyn') ||
        placeLower.contains('manhattan')) {
      suggestions.addAll([
        'Los Angeles, CA',
        'San Francisco, CA',
        'Chicago, IL',
        'Boston, MA',
        'Philadelphia, PA',
        'Washington, DC'
      ]);
    } else if (placeLower.contains('los angeles') ||
        placeLower.contains('la')) {
      suggestions.addAll([
        'San Francisco, CA',
        'San Diego, CA',
        'Palm Springs, CA',
        'Las Vegas, NV',
        'Phoenix, AZ',
        'Miami, FL'
      ]);
    } else if (placeLower.contains('san francisco') ||
        placeLower.contains('sf')) {
      suggestions.addAll([
        'Oakland, CA',
        'Berkeley, CA',
        'San Jose, CA',
        'Portland, OR',
        'Seattle, WA',
        'Austin, TX'
      ]);
    } else if (placeLower.contains('miami') || placeLower.contains('florida')) {
      suggestions.addAll([
        'Orlando, FL',
        'Tampa, FL',
        'Fort Lauderdale, FL',
        'Key West, FL',
        'New Orleans, LA',
        'Nashville, TN'
      ]);
    }
    // Add more vibe matching patterns as needed

    // Filter out places that are already selected
    suggestions = suggestions
        .where((suggestion) => !_selectedPlaces.contains(suggestion))
        .toList();

    // Limit to 6 suggestions
    if (suggestions.length > 6) {
      suggestions = suggestions.take(6).toList();
    }

    return suggestions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
