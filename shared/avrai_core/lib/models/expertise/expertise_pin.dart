import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'expertise_level.dart';

/// Expertise Pin Model
/// OUR_GUTS.md: "Pins, Not Badges" - Expertise recognition tied to subjects and areas
class ExpertisePin extends Equatable {
  // Sentinel value to distinguish "parameter not provided" from "explicit null".
  static const Object _unset = Object();
  final String id;
  final String userId;
  final String category; // e.g., "Coffee", "Thai Food", "Bookstores"
  final ExpertiseLevel level;
  final String? location; // e.g., "Brooklyn", "NYC", null for Global/Universal
  final DateTime earnedAt;
  final String earnedReason; // e.g., "Created 5 respected lists"
  final int contributionCount; // Number of contributions that earned this pin
  final double communityTrustScore; // 0.0 to 1.0, based on community respect
  final List<String> unlockedFeatures; // Features unlocked by this pin

  const ExpertisePin({
    required this.id,
    required this.userId,
    required this.category,
    required this.level,
    this.location,
    required this.earnedAt,
    required this.earnedReason,
    this.contributionCount = 0,
    this.communityTrustScore = 0.0,
    this.unlockedFeatures = const [],
  });

  /// Get pin color based on category
  /// Returns category-specific colors for visual distinction
  /// CRITICAL: Uses 0xFF000000(100% adherence required)
  int getPinColor() {
    // Category-specific color mapping using AppColors
    final categoryColors = {
      'Coffee': 0xFF4D4D4D, // grey700
      'Restaurants': 0xFFFF4D4D, // error
      'Bookstores': 0xFF00FF66, // electricGreen
      'Parks': 0xFF00FF66, // electricGreen
      'Museums': 0xFF6E6E6E, // grey600
      'Shopping': 0xFF8A8A8A, // grey500
      'Bars': 0xFFFFC107, // warning
      'Hotels': 0xFFB3B3B3, // grey400
      'Thai Food': 0xFFFFC107, // warning
      'Vintage': 0xFF6E6E6E, // grey600
    };

    return categoryColors[category] ?? 0xFF8A8A8A;
  }

  /// Get pin icon based on category
  int getPinIcon() {
    final categoryIcons = {
      'Coffee': 0xe38d, // Icons.local_cafe
      'Restaurants': 0xe532, // Icons.restaurant
      'Bookstores': 0xe3dd, // Icons.menu_book
      'Parks': 0xe478, // Icons.park
      'Museums': 0xe414, // Icons.museum
      'Shopping': 0xe59a, // Icons.shopping_bag
      'Bars': 0xe38c, // Icons.local_bar
      'Hotels': 0xe322, // Icons.hotel
      'Thai Food': 0xe506, // Icons.ramen_dining
      'Vintage': 0xe15d, // Icons.checkroom
    };

    return categoryIcons[category] ?? 0xe4c9; // Icons.place
  }

  /// Get display title for the pin
  String getDisplayTitle() {
    final locationText = location != null ? ' in $location' : '';
    return '$category Expert$locationText';
  }

  /// Get full description with level
  String getFullDescription() {
    return '${level.emoji} ${level.displayName} Level - $category${location != null ? ' ($location)' : ''}';
  }

  /// Check if pin unlocks event hosting (requires Local level or higher)
  bool unlocksEventHosting() {
    return level.index >= ExpertiseLevel.local.index;
  }

  /// Check if pin unlocks expert validation
  bool unlocksExpertValidation() {
    return level.index >= ExpertiseLevel.regional.index;
  }

  /// Create from expertise map entry
  factory ExpertisePin.fromMapEntry({
    required String userId,
    required String category,
    required String levelString,
    String? location,
    DateTime? earnedAt,
    String? earnedReason,
  }) {
    final level =
        ExpertiseLevel.fromString(levelString) ?? ExpertiseLevel.local;

    return ExpertisePin(
      id: '${userId}_${category}_${level.name}',
      userId: userId,
      category: category,
      level: level,
      location: location,
      earnedAt: earnedAt ?? DateTime.now(),
      earnedReason: earnedReason ?? 'Earned through community contributions',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'level': level.name,
      'location': location,
      'earnedAt': earnedAt.toIso8601String(),
      'earnedReason': earnedReason,
      'contributionCount': contributionCount,
      'communityTrustScore': communityTrustScore,
      'unlockedFeatures': unlockedFeatures,
    };
  }

  /// Create from JSON
  factory ExpertisePin.fromJson(Map<String, dynamic> json) {
    return ExpertisePin(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      level: ExpertiseLevel.fromString(json['level'] as String?) ??
          ExpertiseLevel.local,
      location: json['location'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      earnedReason: json['earnedReason'] as String,
      contributionCount: json['contributionCount'] as int? ?? 0,
      communityTrustScore:
          (json['communityTrustScore'] as num?)?.toDouble() ?? 0.0,
      unlockedFeatures:
          List<String>.from(json['unlockedFeatures'] as List? ?? []),
    );
  }

  /// Copy with method
  ExpertisePin copyWith({
    String? id,
    String? userId,
    String? category,
    ExpertiseLevel? level,
    Object? location = _unset,
    DateTime? earnedAt,
    String? earnedReason,
    int? contributionCount,
    double? communityTrustScore,
    List<String>? unlockedFeatures,
  }) {
    // #region agent log
    // Debug mode: prove whether location was explicitly cleared vs omitted.
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H6',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-expertise-pin',
        'hypothesisId': 'H6',
        'location':
            'lib/core/models/expertise/expertise_pin.dart:ExpertisePin.copyWith',
        'message': 'copyWith location param handling',
        'data': {
          'location_param_is_unset': identical(location, _unset),
          'location_param_is_null': location == null,
          'previous_location_is_null': this.location == null,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    return ExpertisePin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      level: level ?? this.level,
      location:
          identical(location, _unset) ? this.location : location as String?,
      earnedAt: earnedAt ?? this.earnedAt,
      earnedReason: earnedReason ?? this.earnedReason,
      contributionCount: contributionCount ?? this.contributionCount,
      communityTrustScore: communityTrustScore ?? this.communityTrustScore,
      unlockedFeatures: unlockedFeatures ?? this.unlockedFeatures,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        level,
        location,
        earnedAt,
        earnedReason,
        contributionCount,
        communityTrustScore,
        unlockedFeatures,
      ];
}
