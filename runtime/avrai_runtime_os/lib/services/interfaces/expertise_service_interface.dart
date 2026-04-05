import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_core/models/expertise/expertise_pin.dart';
import 'package:avrai_core/models/expertise/expertise_progress.dart';
import 'package:avrai_core/models/user/unified_user.dart';

/// Expertise Service Interface
///
/// Defines the contract for expertise calculation and management.
/// This interface allows for easier testing and potential future implementation swapping.
///
/// **Usage:**
/// Services should depend on `IExpertiseService` instead of `ExpertiseService`
/// for better testability and reduced coupling.
abstract class IExpertiseService {
  /// Calculate expertise level based on contributions
  ///
  /// OUR_GUTS.md: Based on real contributions, trusted feedback, and curation quality
  ExpertiseLevel calculateExpertiseLevel({
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required int spotsReviewedCount,
    required double communityTrustScore,
    String? location,
  });

  /// Get expertise pins from user's expertise map
  List<ExpertisePin> getUserPins(UnifiedUser user);

  /// Calculate progress toward next expertise level
  ExpertiseProgress calculateProgress({
    required String category,
    required String? location,
    required ExpertiseLevel currentLevel,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required int spotsReviewedCount,
    required double communityTrustScore,
  });

  /// Check if user can earn pin for category
  bool canEarnPin({
    required String category,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required double communityTrustScore,
  });

  /// Get expertise story/narrative
  String getExpertiseStory({
    required String category,
    required ExpertiseLevel level,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    String? location,
  });

  /// Check if pin unlocks feature
  bool unlocksFeature(ExpertisePin pin, String feature);

  /// Get unlocked features for level
  List<String> getUnlockedFeatures(ExpertiseLevel level);
}
