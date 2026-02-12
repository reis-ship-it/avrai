/// Action models for AI action execution system
/// Part of Phase 5: Action Execution System
library;

/// Base class for all action intents
abstract class ActionIntent {
  final String type;
  final double confidence;
  final Map<String, dynamic> metadata;
  
  const ActionIntent({
    required this.type,
    required this.confidence,
    this.metadata = const {},
  });
}

/// Intent to create a new spot
class CreateSpotIntent extends ActionIntent {
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final String? address;
  final List<String> tags;
  final String userId;
  
  const CreateSpotIntent({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.userId,
    this.address,
    this.tags = const [],
    required super.confidence,
    super.metadata = const {},
  }) : super(type: 'create_spot');
}

/// Intent to create a new list
class CreateListIntent extends ActionIntent {
  final String title;
  final String description;
  final String? category;
  final bool isPublic;
  final List<String> tags;
  final String userId;
  
  const CreateListIntent({
    required this.title,
    required this.description,
    required this.userId,
    this.category,
    this.isPublic = true,
    this.tags = const [],
    required super.confidence,
    super.metadata = const {},
  }) : super(type: 'create_list');
}

/// Intent to add a spot to a list
class AddSpotToListIntent extends ActionIntent {
  final String spotId;
  final String listId;
  final String userId;
  
  const AddSpotToListIntent({
    required this.spotId,
    required this.listId,
    required this.userId,
    required super.confidence,
    super.metadata = const {},
  }) : super(type: 'add_spot_to_list');
}

/// Intent to search for spots
class SearchSpotsIntent extends ActionIntent {
  final String query;
  final String? category;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  
  const SearchSpotsIntent({
    required this.query,
    this.category,
    this.latitude,
    this.longitude,
    this.radiusKm,
    required super.confidence,
    super.metadata = const {},
  }) : super(type: 'search_spots');
}

/// Intent to create an event
/// OUR_GUTS.md: "The key opens doors to events"
/// Easy Event Hosting - Phase 5: AI Assistant
/// Example: "Create a coffee tour next Saturday at 10am"
class CreateEventIntent extends ActionIntent {
  final String userId;
  final String? templateId; // e.g., "coffee_tasting_tour"
  final String? title;
  final String? description;
  final DateTime? startTime;
  final int? maxAttendees;
  final double? price;
  final String? category;
  
  const CreateEventIntent({
    required this.userId,
    this.templateId,
    this.title,
    this.description,
    this.startTime,
    this.maxAttendees,
    this.price,
    this.category,
    required super.confidence,
    super.metadata = const {},
  }) : super(type: 'create_event');
}

/// Result of an action execution
class ActionResult {
  final bool success;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> data;
  final ActionIntent? intent;
  
  const ActionResult({
    required this.success,
    this.errorMessage,
    this.successMessage,
    this.data = const {},
    this.intent,
  });
  
  factory ActionResult.success({
    String? message,
    Map<String, dynamic>? data,
    ActionIntent? intent,
  }) {
    return ActionResult(
      success: true,
      successMessage: message,
      data: data ?? const {},
      intent: intent,
    );
  }
  
  factory ActionResult.failure({
    required String error,
    ActionIntent? intent,
  }) {
    return ActionResult(
      success: false,
      errorMessage: error,
      intent: intent,
    );
  }
}

