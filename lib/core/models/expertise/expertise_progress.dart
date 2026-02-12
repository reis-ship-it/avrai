import 'package:equatable/equatable.dart';
import 'expertise_level.dart';

/// Expertise Progress Model
/// Tracks progress toward next expertise level
/// OUR_GUTS.md: Progress visibility without gamification
class ExpertiseProgress extends Equatable {
  final String category;
  final String? location;
  final ExpertiseLevel currentLevel;
  final ExpertiseLevel? nextLevel;
  final double progressPercentage; // 0.0 to 100.0
  final List<String> nextSteps; // Clear next steps to progress
  final Map<String, int> contributionBreakdown; // Breakdown of contributions
  final int totalContributions;
  final int requiredContributions; // For next level
  final DateTime lastUpdated;

  const ExpertiseProgress({
    required this.category,
    this.location,
    required this.currentLevel,
    this.nextLevel,
    required this.progressPercentage,
    this.nextSteps = const [],
    this.contributionBreakdown = const {},
    this.totalContributions = 0,
    this.requiredContributions = 0,
    required this.lastUpdated,
  });

  /// Get progress description
  String getProgressDescription() {
    if (nextLevel == null) {
      return 'You\'ve reached the highest level of expertise!';
    }
    
    final remaining = requiredContributions - totalContributions;
    if (remaining <= 0) {
      return 'Ready to advance to ${nextLevel!.displayName} Level!';
    }
    
    return '$remaining more ${remaining == 1 ? 'contribution' : 'contributions'} to reach ${nextLevel!.displayName} Level';
  }

  /// Get formatted progress text
  String getFormattedProgress() {
    return '${progressPercentage.toStringAsFixed(0)}% to ${nextLevel?.displayName ?? 'highest'} Level';
  }

  /// Check if ready to advance
  bool get isReadyToAdvance {
    return nextLevel != null && progressPercentage >= 100.0;
  }

  /// Get contribution summary
  String getContributionSummary() {
    final parts = <String>[];
    
    if (contributionBreakdown.containsKey('lists')) {
      parts.add('${contributionBreakdown['lists']} ${contributionBreakdown['lists'] == 1 ? 'list' : 'lists'}');
    }
    
    if (contributionBreakdown.containsKey('reviews')) {
      parts.add('${contributionBreakdown['reviews']} ${contributionBreakdown['reviews'] == 1 ? 'review' : 'reviews'}');
    }
    
    if (contributionBreakdown.containsKey('spots')) {
      parts.add('${contributionBreakdown['spots']} ${contributionBreakdown['spots'] == 1 ? 'spot' : 'spots'}');
    }
    
    if (parts.isEmpty) {
      return 'No contributions yet';
    }
    
    return parts.join(', ');
  }

  /// Create empty progress
  factory ExpertiseProgress.empty({
    required String category,
    String? location,
  }) {
    return ExpertiseProgress(
      category: category,
      location: location,
      currentLevel: ExpertiseLevel.local,
      nextLevel: ExpertiseLevel.city,
      progressPercentage: 0.0,
      nextSteps: const [
        'Create your first list in this category',
        'Review spots thoughtfully',
        'Build community trust',
      ],
      contributionBreakdown: const {},
      totalContributions: 0,
      requiredContributions: 10, // Default requirement
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'location': location,
      'currentLevel': currentLevel.name,
      'nextLevel': nextLevel?.name,
      'progressPercentage': progressPercentage,
      'nextSteps': nextSteps,
      'contributionBreakdown': contributionBreakdown,
      'totalContributions': totalContributions,
      'requiredContributions': requiredContributions,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ExpertiseProgress.fromJson(Map<String, dynamic> json) {
    return ExpertiseProgress(
      category: json['category'] as String,
      location: json['location'] as String?,
      currentLevel: ExpertiseLevel.fromString(json['currentLevel'] as String?) ?? ExpertiseLevel.local,
      nextLevel: json['nextLevel'] != null 
          ? ExpertiseLevel.fromString(json['nextLevel'] as String)
          : null,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      nextSteps: List<String>.from(json['nextSteps'] as List? ?? []),
      contributionBreakdown: Map<String, int>.from(json['contributionBreakdown'] as Map? ?? {}),
      totalContributions: json['totalContributions'] as int? ?? 0,
      requiredContributions: json['requiredContributions'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Copy with method
  ExpertiseProgress copyWith({
    String? category,
    String? location,
    ExpertiseLevel? currentLevel,
    ExpertiseLevel? nextLevel,
    double? progressPercentage,
    List<String>? nextSteps,
    Map<String, int>? contributionBreakdown,
    int? totalContributions,
    int? requiredContributions,
    DateTime? lastUpdated,
  }) {
    return ExpertiseProgress(
      category: category ?? this.category,
      location: location ?? this.location,
      currentLevel: currentLevel ?? this.currentLevel,
      nextLevel: nextLevel ?? this.nextLevel,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      nextSteps: nextSteps ?? this.nextSteps,
      contributionBreakdown: contributionBreakdown ?? this.contributionBreakdown,
      totalContributions: totalContributions ?? this.totalContributions,
      requiredContributions: requiredContributions ?? this.requiredContributions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        category,
        location,
        currentLevel,
        nextLevel,
        progressPercentage,
        nextSteps,
        contributionBreakdown,
        totalContributions,
        requiredContributions,
        lastUpdated,
      ];
}

