import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_context.g.dart';

@JsonSerializable()
class SocialContext extends Equatable {
  final SocialContextType type;
  final int participantCount;
  final List<String> participantIds;
  final Map<String, dynamic> metadata;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;
  
  const SocialContext({
    required this.type,
    this.participantCount = 1,
    this.participantIds = const [],
    this.metadata = const {},
    this.startTime,
    this.endTime,
    this.description,
  });
  
  // Predefined common contexts
  static const solo = SocialContext(
    type: SocialContextType.solo,
    participantCount: 1,
  );
  
  static const couple = SocialContext(
    type: SocialContextType.couple,
    participantCount: 2,
  );
  
  static const smallGroup = SocialContext(
    type: SocialContextType.group,
    participantCount: 4,
  );
  
  static const family = SocialContext(
    type: SocialContextType.family,
    participantCount: 3,
  );
  
  static const business = SocialContext(
    type: SocialContextType.business,
    participantCount: 2,
  );
  
  /// Create context for a specific group size
  factory SocialContext.forGroupSize(int size) {
    if (size == 1) return solo;
    if (size == 2) return couple;
    if (size <= 6) {
      return SocialContext(
        type: SocialContextType.group,
        participantCount: size,
      );
    }
    return SocialContext(
      type: SocialContextType.event,
      participantCount: size,
    );
  }
  
  /// Create context with specific participants
  factory SocialContext.withParticipants(
    SocialContextType type,
    List<String> participantIds, {
    String? description,
  }) {
    return SocialContext(
      type: type,
      participantCount: participantIds.length,
      participantIds: participantIds,
      startTime: DateTime.now(),
      description: description,
    );
  }
  
  /// Check if context is currently active
  bool get isActive {
    if (startTime == null) return true; // Assume active if no start time
    if (endTime != null && DateTime.now().isAfter(endTime!)) return false;
    return true;
  }
  
  /// Get duration of the social context
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }
  
  /// Check if user is participant
  bool hasParticipant(String userId) => participantIds.contains(userId);
  
  /// Add participant to context
  SocialContext addParticipant(String userId) {
    if (hasParticipant(userId)) return this;
    
    return copyWith(
      participantIds: [...participantIds, userId],
      participantCount: participantCount + 1,
    );
  }
  
  /// Remove participant from context
  SocialContext removeParticipant(String userId) {
    if (!hasParticipant(userId)) return this;
    
    final newParticipants = participantIds.where((id) => id != userId).toList();
    return copyWith(
      participantIds: newParticipants,
      participantCount: newParticipants.length,
    );
  }
  
  /// End the social context
  SocialContext end() {
    return copyWith(endTime: DateTime.now());
  }
  
  /// Get context size category
  SocialSizeCategory get sizeCategory {
    if (participantCount == 1) return SocialSizeCategory.solo;
    if (participantCount == 2) return SocialSizeCategory.couple;
    if (participantCount <= 6) return SocialSizeCategory.smallGroup;
    if (participantCount <= 20) return SocialSizeCategory.mediumGroup;
    return SocialSizeCategory.largeGroup;
  }
  
  /// Get privacy level based on context type
  PrivacyLevel get privacyLevel {
    switch (type) {
      case SocialContextType.solo:
        return PrivacyLevel.private;
      case SocialContextType.couple:
      case SocialContextType.family:
        return PrivacyLevel.intimate;
      case SocialContextType.group:
        return PrivacyLevel.social;
      case SocialContextType.business:
        return PrivacyLevel.professional;
      case SocialContextType.event:
        return PrivacyLevel.public;
    }
  }
  
  factory SocialContext.fromJson(Map<String, dynamic> json) => 
      _$SocialContextFromJson(json);
  Map<String, dynamic> toJson() => _$SocialContextToJson(this);
  
  SocialContext copyWith({
    SocialContextType? type,
    int? participantCount,
    List<String>? participantIds,
    Map<String, dynamic>? metadata,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
  }) {
    return SocialContext(
      type: type ?? this.type,
      participantCount: participantCount ?? this.participantCount,
      participantIds: participantIds ?? this.participantIds,
      metadata: metadata ?? this.metadata,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
    );
  }
  
  @override
  List<Object?> get props => [
    type, participantCount, participantIds, metadata,
    startTime, endTime, description,
  ];
}

enum SocialContextType {
  solo,
  couple,
  group,
  family,
  business,
  event,
}

enum SocialSizeCategory {
  solo,
  couple,
  smallGroup,
  mediumGroup,
  largeGroup,
}

enum PrivacyLevel {
  private,
  intimate,
  social,
  professional,
  public,
}

extension SocialContextTypeExtension on SocialContextType {
  String get displayName {
    switch (this) {
      case SocialContextType.solo:
        return 'Solo';
      case SocialContextType.couple:
        return 'Couple';
      case SocialContextType.group:
        return 'Group';
      case SocialContextType.family:
        return 'Family';
      case SocialContextType.business:
        return 'Business';
      case SocialContextType.event:
        return 'Event';
    }
  }
  
  String get description {
    switch (this) {
      case SocialContextType.solo:
        return 'Individual activity';
      case SocialContextType.couple:
        return 'Two people together';
      case SocialContextType.group:
        return 'Small group activity';
      case SocialContextType.family:
        return 'Family gathering';
      case SocialContextType.business:
        return 'Professional meeting';
      case SocialContextType.event:
        return 'Large group event';
    }
  }
  
  String get emoji {
    switch (this) {
      case SocialContextType.solo:
        return '🧑';
      case SocialContextType.couple:
        return '👫';
      case SocialContextType.group:
        return '👥';
      case SocialContextType.family:
        return '👪';
      case SocialContextType.business:
        return '💼';
      case SocialContextType.event:
        return '🎉';
    }
  }
}
