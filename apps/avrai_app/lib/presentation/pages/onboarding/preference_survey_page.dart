import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/widgets/common/app_filter_chip.dart';
import 'package:avrai/presentation/schemas/pages/preference_survey_page_schema.dart';

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
    return AppSchemaPage(
      schema: buildPreferenceSurveyPageSchema(
        summarySection: _buildSummarySection(context),
        searchSection: _buildSearchSection(),
        categoriesSection: _buildCategoriesSection(),
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getSelectedCount()} of 15 selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              '${_getSelectedCount()}/15',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _getSelectedCount() / 15.0,
          backgroundColor: AppColors.borderSubtle,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '${_getSelectedCount()} preferences selected',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return TextField(
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
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildCategoriesSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories.keys.elementAt(index);
        final options = _categories[category]!;
        final filteredOptions = _searchQuery.isEmpty
            ? options
            : options
                .where((option) => option.toLowerCase().contains(_searchQuery))
                .toList();

        if (_searchQuery.isNotEmpty && filteredOptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildCategorySection(category, filteredOptions);
      },
    );
  }

  Widget _buildCategorySection(String category, List<String> options) {
    final selectedOptions = _preferences[category] ?? [];
    final isExpanded = _openSection == category;

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 16),
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
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (selectedOptions.isNotEmpty)
              AppSurface(
                radius: 12,
                color: AppColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${selectedOptions.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selectedOptions.contains(option);
                return AppFilterChip(
                  label: option,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      if (!isSelected) {
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
