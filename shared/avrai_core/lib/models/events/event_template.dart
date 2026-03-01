import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';

/// OUR_GUTS.md: "The key opens doors to events"
/// Easy Event Hosting - Phase 1: Event Templates
/// Philosophy: Make hosting events incredibly easy (5-7 min → 30 sec)

/// Event Template
/// Pre-built event configurations that hosts can use as starting points
/// Philosophy: "One-tap event creation" - minimize decisions, maximize speed
class EventTemplate extends Equatable {
  final String id;
  final String name; // "Coffee Tasting Tour"
  final String category; // "Coffee"
  final ExpertiseEventType eventType; // tour, workshop, etc.
  final String descriptionTemplate; // Pre-written description with placeholders
  final Duration defaultDuration; // 2 hours, 3 hours, etc.
  final int defaultMaxAttendees; // 15, 20, 50, etc.
  final double? suggestedPrice; // null = free, or suggested price
  final List<String> suggestedSpotTypes; // ["coffee_shop", "roastery"]
  final int recommendedSpotCount; // 3 spots, 5 spots, etc.
  final String icon; // Emoji for visual display
  final List<String> tags; // ["beginner-friendly", "outdoor", etc.]
  final Map<String, dynamic> metadata; // Additional template data

  const EventTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.eventType,
    required this.descriptionTemplate,
    required this.defaultDuration,
    this.defaultMaxAttendees = 20,
    this.suggestedPrice,
    this.suggestedSpotTypes = const [],
    this.recommendedSpotCount = 3,
    this.icon = '📍',
    this.tags = const [],
    this.metadata = const {},
  });

  /// Check if template is free or paid
  bool get isFree => suggestedPrice == null || suggestedPrice == 0.0;

  /// Get formatted price string
  String getPriceDisplay() {
    if (isFree) return 'Free';
    return '\$${suggestedPrice!.toStringAsFixed(0)}';
  }

  /// Get estimated end time from start time
  DateTime getEstimatedEndTime(DateTime startTime) {
    return startTime.add(defaultDuration);
  }

  /// Generate title with host name
  String generateTitle(String hostName) {
    return descriptionTemplate.contains('{hostName}')
        ? name.replaceAll('{hostName}', hostName)
        : name;
  }

  /// Generate description with placeholders filled
  String generateDescription({
    required String hostName,
    String? location,
    int? spotCount,
  }) {
    var description = descriptionTemplate;

    description = description.replaceAll('{hostName}', hostName);
    if (location != null) {
      description = description.replaceAll('{location}', location);
    }
    if (spotCount != null) {
      description = description.replaceAll('{spotCount}', spotCount.toString());
    }

    return description;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'eventType': eventType.name,
        'descriptionTemplate': descriptionTemplate,
        'defaultDuration': defaultDuration.inMinutes,
        'defaultMaxAttendees': defaultMaxAttendees,
        'suggestedPrice': suggestedPrice,
        'suggestedSpotTypes': suggestedSpotTypes,
        'recommendedSpotCount': recommendedSpotCount,
        'icon': icon,
        'tags': tags,
        'metadata': metadata,
      };

  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      eventType: ExpertiseEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => ExpertiseEventType.meetup,
      ),
      descriptionTemplate: json['descriptionTemplate'] as String,
      defaultDuration: Duration(minutes: json['defaultDuration'] as int),
      defaultMaxAttendees: json['defaultMaxAttendees'] as int? ?? 20,
      suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble(),
      suggestedSpotTypes:
          List<String>.from(json['suggestedSpotTypes'] as List? ?? []),
      recommendedSpotCount: json['recommendedSpotCount'] as int? ?? 3,
      icon: json['icon'] as String? ?? '📍',
      tags: List<String>.from(json['tags'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Create a copy with modified fields
  EventTemplate copyWith({
    String? id,
    String? name,
    String? category,
    ExpertiseEventType? eventType,
    String? descriptionTemplate,
    Duration? defaultDuration,
    int? defaultMaxAttendees,
    double? suggestedPrice,
    List<String>? suggestedSpotTypes,
    int? recommendedSpotCount,
    String? icon,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return EventTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      descriptionTemplate: descriptionTemplate ?? this.descriptionTemplate,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      defaultMaxAttendees: defaultMaxAttendees ?? this.defaultMaxAttendees,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      suggestedSpotTypes: suggestedSpotTypes ?? this.suggestedSpotTypes,
      recommendedSpotCount: recommendedSpotCount ?? this.recommendedSpotCount,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        eventType,
        descriptionTemplate,
        defaultDuration,
        defaultMaxAttendees,
        suggestedPrice,
        suggestedSpotTypes,
        recommendedSpotCount,
        icon,
        tags,
        metadata,
      ];
}

/// Template Category
/// Groups templates by theme for easier browsing
class TemplateCategory {
  final String id;
  final String name;
  final String icon;
  final List<String> templateIds;

  const TemplateCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.templateIds,
  });
}
