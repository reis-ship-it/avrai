// Multi-Modal List Items
//
// Phase 5.1: Support different item types in lists
//
// Purpose: Enable lists with places, activities, and events

import 'package:avrai/core/models/spots/spot.dart';

/// Multi-Modal List Item
///
/// Base class for different types of items that can appear in a suggested list.
/// Supports places, activities, and events.
///
/// Part of Phase 5.1: Multi-Modal Lists

/// Type of list item
enum ListItemType {
  /// A physical place (restaurant, museum, etc.)
  place,

  /// An activity to do (hiking, painting, etc.)
  activity,

  /// A timed event (concert, festival, etc.)
  event,
}

/// Base interface for list items
abstract class ListItem {
  /// Unique identifier
  String get id;

  /// Display name
  String get name;

  /// Description
  String get description;

  /// Item type
  ListItemType get type;

  /// Category (for filtering)
  String get category;

  /// Compatibility score (0.0 to 1.0)
  double get compatibilityScore;

  /// Optional image URL
  String? get imageUrl;

  /// Convert to JSON
  Map<String, dynamic> toJson();
}

/// Place item - a physical location
class PlaceItem implements ListItem {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String category;

  @override
  final double compatibilityScore;

  @override
  final String? imageUrl;

  /// The underlying Spot model
  final Spot spot;

  /// Distance from user in kilometers
  final double? distanceKm;

  /// Price level (1-4)
  final int? priceLevel;

  /// Rating (0.0 to 5.0)
  final double? rating;

  /// Opening hours
  final String? openingHours;

  const PlaceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.compatibilityScore,
    required this.spot,
    this.imageUrl,
    this.distanceKm,
    this.priceLevel,
    this.rating,
    this.openingHours,
  });

  @override
  ListItemType get type => ListItemType.place;

  /// Create from a Spot
  factory PlaceItem.fromSpot(Spot spot, {double compatibilityScore = 0.0}) {
    return PlaceItem(
      id: spot.id,
      name: spot.name,
      description: spot.description,
      category: spot.category,
      compatibilityScore: compatibilityScore,
      spot: spot,
      imageUrl: spot.imageUrl,
      rating: spot.rating,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'place',
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'compatibilityScore': compatibilityScore,
        'imageUrl': imageUrl,
        'distanceKm': distanceKm,
        'priceLevel': priceLevel,
        'rating': rating,
        'openingHours': openingHours,
        'spotId': spot.id,
      };
}

/// Activity item - something to do (not tied to a specific place)
class ActivityItem implements ListItem {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String category;

  @override
  final double compatibilityScore;

  @override
  final String? imageUrl;

  /// Estimated duration in minutes
  final int? durationMinutes;

  /// Difficulty level (1-5)
  final int? difficultyLevel;

  /// Suggested places for this activity
  final List<String>? suggestedPlaceIds;

  /// Required equipment/materials
  final List<String>? requirements;

  const ActivityItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.compatibilityScore,
    this.imageUrl,
    this.durationMinutes,
    this.difficultyLevel,
    this.suggestedPlaceIds,
    this.requirements,
  });

  @override
  ListItemType get type => ListItemType.activity;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'activity',
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'compatibilityScore': compatibilityScore,
        'imageUrl': imageUrl,
        'durationMinutes': durationMinutes,
        'difficultyLevel': difficultyLevel,
        'suggestedPlaceIds': suggestedPlaceIds,
        'requirements': requirements,
      };
}

/// Event item - a timed occurrence (concert, festival, etc.)
class EventItem implements ListItem {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String category;

  @override
  final double compatibilityScore;

  @override
  final String? imageUrl;

  /// Event start time
  final DateTime startTime;

  /// Event end time
  final DateTime? endTime;

  /// Venue/location
  final String? venue;

  /// Venue address
  final String? address;

  /// Price (if applicable)
  final double? price;

  /// Ticket URL
  final String? ticketUrl;

  /// Whether tickets are still available
  final bool? ticketsAvailable;

  const EventItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.compatibilityScore,
    required this.startTime,
    this.imageUrl,
    this.endTime,
    this.venue,
    this.address,
    this.price,
    this.ticketUrl,
    this.ticketsAvailable,
  });

  @override
  ListItemType get type => ListItemType.event;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'event',
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'compatibilityScore': compatibilityScore,
        'imageUrl': imageUrl,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'venue': venue,
        'address': address,
        'price': price,
        'ticketUrl': ticketUrl,
        'ticketsAvailable': ticketsAvailable,
      };
}

/// Multi-modal suggested list
class MultiModalSuggestedList {
  final String id;
  final String title;
  final String description;
  final String theme;
  final DateTime generatedAt;
  final List<ListItem> items;
  final double qualityScore;
  final List<String> triggerReasons;
  final bool isPinned;

  const MultiModalSuggestedList({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.generatedAt,
    required this.items,
    this.qualityScore = 0.0,
    this.triggerReasons = const [],
    this.isPinned = false,
  });

  /// Get items by type
  List<T> getItemsByType<T extends ListItem>() {
    return items.whereType<T>().toList();
  }

  /// Get all place items
  List<PlaceItem> get places => getItemsByType<PlaceItem>();

  /// Get all activity items
  List<ActivityItem> get activities => getItemsByType<ActivityItem>();

  /// Get all event items
  List<EventItem> get events => getItemsByType<EventItem>();

  /// Total item count
  int get itemCount => items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'theme': theme,
        'generatedAt': generatedAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'qualityScore': qualityScore,
        'triggerReasons': triggerReasons,
        'isPinned': isPinned,
      };
}
