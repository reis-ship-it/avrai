/// Category Taxonomy
///
/// Maps place categories from Apple Maps, Google Places, and other sources
/// to a unified avrai category system.
///
/// Phase 4.2: Map Apple Maps and Google Places categories to avrai categories
/// Purpose: Normalize external place categories to internal taxonomy
library;

/// Category taxonomy class for mapping place categories
class CategoryTaxonomy {
  /// avrai internal categories
  static const List<String> spotsCategories = [
    'restaurants',
    'cafes',
    'bars',
    'nightlife',
    'entertainment',
    'museums',
    'parks',
    'shopping',
    'wellness',
    'outdoors',
    'cultural',
    'sports',
    'services',
    'adult_entertainment', // 18+ only
  ];

  /// Apple Maps category to avrai category mapping
  static const Map<String, String> appleMapsMapping = {
    // Food & Drink
    'restaurant': 'restaurants',
    'food': 'restaurants',
    'bakery': 'cafes',
    'cafe': 'cafes',
    'coffee_shop': 'cafes',
    'bar': 'bars',
    'pub': 'bars',
    'wine_bar': 'bars',
    'brewery': 'bars',
    'nightclub': 'nightlife',
    'lounge': 'nightlife',

    // Entertainment
    'movie_theater': 'entertainment',
    'theater': 'entertainment',
    'bowling_alley': 'entertainment',
    'arcade': 'entertainment',
    'amusement_park': 'entertainment',
    'casino': 'entertainment',

    // Culture
    'museum': 'museums',
    'art_gallery': 'museums',
    'library': 'cultural',
    'landmark': 'cultural',

    // Nature
    'park': 'parks',
    'garden': 'parks',
    'beach': 'outdoors',
    'hiking_trail': 'outdoors',
    'campground': 'outdoors',

    // Shopping
    'shopping_mall': 'shopping',
    'clothing_store': 'shopping',
    'electronics_store': 'shopping',
    'department_store': 'shopping',
    'bookstore': 'shopping',
    'grocery_store': 'shopping',

    // Wellness
    'gym': 'wellness',
    'spa': 'wellness',
    'yoga_studio': 'wellness',
    'massage': 'wellness',

    // Sports
    'stadium': 'sports',
    'sports_complex': 'sports',
    'golf_course': 'sports',
    'tennis_court': 'sports',

    // Services
    'bank': 'services',
    'atm': 'services',
    'gas_station': 'services',
    'car_wash': 'services',
    'post_office': 'services',
  };

  /// Google Places category to avrai category mapping
  static const Map<String, String> googlePlacesMapping = {
    // Food & Drink
    'restaurant': 'restaurants',
    'meal_delivery': 'restaurants',
    'meal_takeaway': 'restaurants',
    'bakery': 'cafes',
    'cafe': 'cafes',
    'bar': 'bars',
    'liquor_store': 'bars',
    'night_club': 'nightlife',

    // Entertainment
    'movie_theater': 'entertainment',
    'bowling_alley': 'entertainment',
    'amusement_park': 'entertainment',
    'casino': 'entertainment',
    'aquarium': 'entertainment',
    'zoo': 'entertainment',

    // Culture
    'museum': 'museums',
    'art_gallery': 'museums',
    'library': 'cultural',
    'church': 'cultural',
    'hindu_temple': 'cultural',
    'mosque': 'cultural',
    'synagogue': 'cultural',

    // Nature
    'park': 'parks',
    'campground': 'outdoors',

    // Shopping
    'shopping_mall': 'shopping',
    'clothing_store': 'shopping',
    'electronics_store': 'shopping',
    'department_store': 'shopping',
    'book_store': 'shopping',
    'convenience_store': 'shopping',
    'supermarket': 'shopping',
    'jewelry_store': 'shopping',

    // Wellness
    'gym': 'wellness',
    'spa': 'wellness',
    'hair_care': 'wellness',
    'beauty_salon': 'wellness',

    // Sports
    'stadium': 'sports',

    // Services
    'bank': 'services',
    'atm': 'services',
    'gas_station': 'services',
    'car_wash': 'services',
    'post_office': 'services',
    'laundry': 'services',
    'locksmith': 'services',
  };

  /// Sensitive categories that require explicit opt-in (18+)
  static const Set<String> sensitiveCategories = {
    'adult_entertainment',
    'sex_shops',
    'kink_venues',
    'cannabis_dispensaries',
    'hookah_lounges',
    'vape_shops',
  };

  /// Map an Apple Maps category to avrai category
  static String mapAppleMapsCategory(String appleCategory) {
    final normalized = appleCategory.toLowerCase().replaceAll(' ', '_');
    return appleMapsMapping[normalized] ?? 'services';
  }

  /// Map a Google Places category to avrai category
  static String mapGooglePlacesCategory(String googleCategory) {
    final normalized = googleCategory.toLowerCase().replaceAll(' ', '_');
    return googlePlacesMapping[normalized] ?? 'services';
  }

  /// Map any external category to avrai category (auto-detect source)
  static String mapCategory(String category, {String? source}) {
    final normalized = category.toLowerCase().replaceAll(' ', '_');

    // Check source-specific mappings
    if (source == 'apple_maps') {
      return mapAppleMapsCategory(category);
    } else if (source == 'google_places') {
      return mapGooglePlacesCategory(category);
    }

    // Try both mappings, prefer Google Places (more common)
    if (googlePlacesMapping.containsKey(normalized)) {
      return googlePlacesMapping[normalized]!;
    }
    if (appleMapsMapping.containsKey(normalized)) {
      return appleMapsMapping[normalized]!;
    }

    // Fallback to fuzzy matching
    return _fuzzyMatchCategory(normalized);
  }

  /// Fuzzy match a category by keyword
  static String _fuzzyMatchCategory(String category) {
    if (category.contains('restaurant') ||
        category.contains('food') ||
        category.contains('diner')) {
      return 'restaurants';
    }
    if (category.contains('cafe') ||
        category.contains('coffee') ||
        category.contains('bakery')) {
      return 'cafes';
    }
    if (category.contains('bar') ||
        category.contains('pub') ||
        category.contains('brewery')) {
      return 'bars';
    }
    if (category.contains('club') ||
        category.contains('lounge') ||
        category.contains('disco')) {
      return 'nightlife';
    }
    if (category.contains('museum') ||
        category.contains('gallery') ||
        category.contains('exhibit')) {
      return 'museums';
    }
    if (category.contains('park') || category.contains('garden')) {
      return 'parks';
    }
    if (category.contains('shop') ||
        category.contains('store') ||
        category.contains('mall')) {
      return 'shopping';
    }
    if (category.contains('gym') ||
        category.contains('spa') ||
        category.contains('wellness') ||
        category.contains('yoga')) {
      return 'wellness';
    }
    if (category.contains('theater') ||
        category.contains('cinema') ||
        category.contains('movie')) {
      return 'entertainment';
    }
    if (category.contains('stadium') ||
        category.contains('sport') ||
        category.contains('arena')) {
      return 'sports';
    }
    if (category.contains('trail') ||
        category.contains('hike') ||
        category.contains('beach') ||
        category.contains('outdoor')) {
      return 'outdoors';
    }

    // Default fallback
    return 'services';
  }

  /// Check if a category is sensitive (requires explicit opt-in)
  static bool isSensitiveCategory(String category) {
    final normalized = category.toLowerCase().replaceAll(' ', '_');
    return sensitiveCategories.contains(normalized);
  }

  /// Get human-readable label for a category
  static String getCategoryLabel(String category) {
    return category
        .split('_')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
