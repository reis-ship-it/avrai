import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

class PreferenceSurveyPage extends StatefulWidget {
  final Map<String, List<String>> preferences;
  final Function(Map<String, List<String>>) onPreferencesChanged;

  const PreferenceSurveyPage({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  State<PreferenceSurveyPage> createState() => _PreferenceSurveyPageState();
}

class _PreferenceSurveyPageState extends State<PreferenceSurveyPage> {
  Map<String, List<String>> _preferences = {};
  // Categories and their options - Reduced to popular/local + default
  final Map<String, List<String>> _categories = {
    'Food & Drink': [
      'Coffee & Tea',
      'Bars & Pubs',
      'Fine Dining',
      'Casual Restaurants',
      'Food Trucks',
      'Bakeries',
      'Ice Cream',
      'Wine Bars',
      'Craft Beer',
      'Cocktail Bars',
      'Vegan/Vegetarian',
      'Pizza',
      'Sushi',
      'BBQ',
      'Mexican',
      'Italian',
      'Thai',
      'Indian',
      'Mediterranean',
      'Korean',
    ],
    'Activities': [
      'Live Music',
      'Theaters',
      'Sports & Fitness',
      'Shopping',
      'Bookstores',
      'Libraries',
      'Cinemas',
      'Bowling',
      'Escape Rooms',
      'Arcades',
      'Spas & Wellness',
      'Yoga Studios',
      'Rock Climbing',
      'Dance Classes',
      'Art Classes',
      'Cooking Classes',
      'Photography',
      'Gaming',
      'Board Games',
      'Karaoke',
    ],
    'Outdoor & Nature': [
      'Hiking Trails',
      'Beaches',
      'Botanical Gardens',
      'National Parks',
      'City Parks',
      'Rivers & Lakes',
      'Mountains',
      'Bike Trails',
      'Camping',
      'Fishing',
      'Bird Watching',
      'Photography Spots',
      'Sunset Views',
      'Waterfalls',
      'Wildlife Areas',
      'Cloud Watching Spots',
      'Stargazing',
      'Rock Climbing',
      'Kayaking',
      'Surfing',
    ],
    'Professional & Career': [
      'Networking Events',
      'Professional Meetups',
      'Industry Conferences',
      'Business Lunches',
      'Career Development',
      'Professional Workshops',
      'Business Casual Spots',
      'Coworking Spaces',
      'Industry Mixers',
      'Professional Social Events',
      'Career Networking Venues',
      'School-Business Connections',
      'Campus Recruiting Events',
      'Industry-Specific Locations',
    ],
    'Culture & Arts': [
      'Art Galleries',
      'Historical Sites',
      'Architecture',
      'Street Art',
      'Cultural Centers',
      'Festivals',
      'Craft Workshops',
      'Poetry Readings',
      'Dance Studios',
      'Music Venues',
      'Film Festivals',
      'Literary Events',
      'Cultural Tours',
      'Local Markets',
      'Craft Fairs',
      'Doors',
      'Museums',
      'Theaters',
      'Opera',
      'Ballet',
    ],
    'Entertainment': [
      'Comedy Clubs',
      'Game Rooms',
      'Karaoke',
      'Dance Clubs',
      'Jazz Clubs',
      'Poker Rooms',
      'Mini Golf',
      'Go-Kart Racing',
      'Laser Tag',
      'Virtual Reality',
      'Board Game Cafes',
      'Trivia Nights',
      'Karaoke Bars',
      'Billiards',
      'Darts',
      'Casinos',
      'Racing',
      'Sports Betting',
      'Bingo',
      'Lottery',
      'Family Entertainment',
      'Kid-Friendly Activities',
      'Children\'s Museums',
      'Family Bowling',
      'Family Arcades',
      'Family Movie Theaters',
      'Family Restaurants',
      'Family Parks',
      'Family Zoos',
      'Family Aquariums',
      'Family Science Centers',
    ],
  };

  final TextEditingController _searchController = TextEditingController();
  String? _openSection;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _preferences = Map.from(widget.preferences);
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
            'What do you love?',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            'Select your preferences to help us find the perfect spots for you.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.grey600,
            ),
          ),
          SizedBox(height: spacing.lg),

          // Progress indicator with 15 goal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select 15 preferences (recommended)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_getSelectedCount()}/15',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.xs),
              LinearProgressIndicator(
                value: _getSelectedCount() / 15.0,
                backgroundColor: AppColors.grey300,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              SizedBox(height: spacing.xs),
              Text(
                '${_getSelectedCount()} preferences selected',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search preferences...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          SizedBox(height: spacing.lg),

          // Categories
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories.keys.elementAt(index);
                final options = _categories[category]!;

                // Filter options based on search
                final filteredOptions = _searchQuery.isEmpty
                    ? options
                    : options
                        .where((option) =>
                            option.toLowerCase().contains(_searchQuery))
                        .toList();

                if (_searchQuery.isNotEmpty && filteredOptions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _buildCategorySection(category, filteredOptions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<String> options) {
    final selectedOptions = _preferences[category] ?? [];
    final isExpanded = _openSection == category;
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _openSection = category;
            } else {
              _openSection = null;
            }
          });
        },
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              color: AppTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                category,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selectedOptions.isNotEmpty)
              Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                backgroundColor: AppTheme.primaryColor,
                side: BorderSide.none,
                label: Text(
                  '${selectedOptions.length}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Wrap(
              spacing: spacing.xs,
              runSpacing: spacing.xs,
              children: options.map((option) {
                final isSelected = selectedOptions.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!selectedOptions.contains(option)) {
                          selectedOptions.add(option);
                        }
                      } else {
                        selectedOptions.remove(option);
                      }
                      _preferences[category] = selectedOptions;
                      widget.onPreferencesChanged(_preferences);
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppTheme.primaryColor : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
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
        return Icons.category;
    }
  }

  int _getSelectedCount() {
    return _preferences.values.expand((options) => options).length;
  }
}
