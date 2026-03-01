import 'dart:developer' as developer;
import 'package:avrai_core/models/user/unified_user.dart';

/// Multidimensional behavior assessment for age-appropriate learning
/// Based on research: behaviors exist on a spectrum, not binary good/bad
///
/// CORE PHILOSOPHY: Meaningful Connections (after "Opening Doors")
///
/// The entire purpose of SPOTS is to open doors for meaningful connections.
/// Everything being done is to ensure that meaningful connections exist and that
/// people can find meaningful connections more easily and truthfully.
///
/// The AI2AI system reflects the influence we have on each other in the real world.
/// Our AIs are hyper-focused on what we could do in the real world that would give
/// us more meaning, fulfillment, and happiness. That is what the door opens to -
/// that is why SPOTS is the skeleton key.
///
/// Key Principles:
/// 1. Meaningful connections - the core purpose, what doors open to
/// 2. Opening doors - not badges, but authentic opportunities for connection
/// 3. Individual trajectory potential - what leads to THIS user's positive growth
/// 4. Real-world influence - AI2AI reflects how we influence each other
/// 5. Meaning, fulfillment, happiness - what AIs are hyper-focused on
/// 6. User-specific - what makes THIS user thrive
/// 7. Context matters - comfortability, setting, people determine connection depth
/// 8. Developmental appropriateness - changes with age
/// 9. Probabilistic outcomes - likelihood, not certainty
/// 10. Multidimensional - behaviors have multiple aspects
/// 11. Dynamic - can learn and adapt based on what works for THIS user
class BehaviorAssessmentService {
  static const String _logName = 'BehaviorAssessmentService';

  /// Assess behavior on multiple dimensions
  /// Returns a BehaviorProfile with scores across different dimensions
  ///
  /// NEW: Now considers venue characteristics (quality, sophistication, ambiance)
  /// Example: Bemelmans (sophisticated bar) vs dive bar have different assessments
  BehaviorProfile assessBehavior(
    String behaviorType,
    Map<String, dynamic>? context,
    int? learnerAge,
  ) {
    // Extract context information
    final socialContext = context?['socialContext']
        as String?; // 'solo', 'family', 'friends', 'supervised'
    final purpose = context?['purpose']
        as String?; // 'education', 'entertainment', 'social', 'work'

    // NEW: Assess venue characteristics (quality, sophistication, ambiance)
    final venueQuality = _assessVenueQuality(context);

    // Assess on multiple dimensions (base scores)
    var developmentalAppropriateness = _assessDevelopmentalAppropriateness(
      behaviorType,
      learnerAge,
      socialContext,
      purpose,
    );

    var educationalValue =
        _assessEducationalValue(behaviorType, purpose, context);
    var socialValue = _assessSocialValue(behaviorType, socialContext, context);
    var riskLevel = _assessRiskLevel(behaviorType, learnerAge, context);
    var culturalValue = _assessCulturalValue(behaviorType, context);
    final physicalActivityValue =
        _assessPhysicalActivityValue(behaviorType, context);

    // NEW: Adjust dimensions based on venue quality
    // Sophisticated venues (like Bemelmans) have higher cultural/educational value
    // Lower-quality venues (dive bars) have higher risk, lower cultural value
    final adjustments =
        _calculateVenueQualityAdjustments(behaviorType, venueQuality);

    // Apply venue quality adjustments
    developmentalAppropriateness =
        (developmentalAppropriateness + adjustments.developmental)
            .clamp(0.0, 1.0);
    educationalValue =
        (educationalValue + adjustments.educational).clamp(0.0, 1.0);
    socialValue = (socialValue + adjustments.social).clamp(0.0, 1.0);
    riskLevel = (riskLevel + adjustments.risk).clamp(0.0, 1.0);
    culturalValue = (culturalValue + adjustments.cultural).clamp(0.0, 1.0);

    return BehaviorProfile(
      behaviorType: behaviorType,
      developmentalAppropriateness: developmentalAppropriateness,
      educationalValue: educationalValue,
      socialValue: socialValue,
      riskLevel: riskLevel,
      culturalValue: culturalValue,
      physicalActivityValue: physicalActivityValue,
      context: context ?? {},
      assessedAt: DateTime.now(),
    );
  }

  /// Assess developmental appropriateness (0.0 to 1.0)
  /// Higher = more appropriate for the age group
  /// Considers: age, supervision, purpose, context
  double _assessDevelopmentalAppropriateness(
    String behaviorType,
    int? age,
    String? socialContext,
    String? purpose,
  ) {
    if (age == null) return 0.5; // Neutral if age unknown

    final type = behaviorType.toLowerCase();

    // Age-appropriate thresholds (not hard blocks, but probability curves)
    // Younger ages have lower thresholds for certain activities

    // Educational/cultural activities - high appropriateness across ages
    if (_isEducationalOrCultural(type, purpose)) {
      // Even better with supervision for younger ages
      if (socialContext == 'family' || socialContext == 'supervised') {
        return 1.0; // Fully appropriate
      }
      return 0.9; // Highly appropriate
    }

    // Physical activities - generally appropriate, age-dependent
    if (_isPhysicalActivity(type)) {
      if (age >= 13) return 0.9;
      if (age >= 8) return 0.8;
      return 0.7; // Younger kids need more supervision
    }

    // Social activities - context-dependent
    if (_isSocialActivity(type)) {
      if (age >= 16) return 0.8;
      if (age >= 13 && socialContext == 'supervised') return 0.7;
      if (age >= 13) return 0.5; // Moderate appropriateness
      return 0.3; // Lower for younger
    }

    // Adult-oriented activities - age-dependent probability
    if (_isAdultOriented(type)) {
      // Not binary - probability increases with age
      if (age >= 21) return 0.8; // Appropriate for adults
      if (age >= 18 && socialContext == 'supervised') {
        return 0.4; // Moderate with supervision
      }
      if (age >= 18) return 0.2; // Low appropriateness
      if (age >= 16 && purpose == 'education' && socialContext == 'supervised') {
        return 0.3; // Educational context
      }
      return 0.0; // Very low for < 16
    }

    // Neutral activities - moderate appropriateness
    return 0.5;
  }

  /// Assess educational value (0.0 to 1.0)
  /// Higher = more educational/enriching
  double _assessEducationalValue(
    String behaviorType,
    String? purpose,
    Map<String, dynamic>? context,
  ) {
    final type = behaviorType.toLowerCase();

    // Explicitly educational
    if (purpose == 'education' ||
        type.contains('museum') ||
        type.contains('library') ||
        type.contains('school') ||
        type.contains('class') ||
        type.contains('workshop')) {
      return 0.9;
    }

    // Culturally enriching
    if (type.contains('orchestra') ||
        type.contains('symphony') ||
        type.contains('theater') ||
        type.contains('gallery') ||
        type.contains('art') ||
        type.contains('music') ||
        type.contains('cultural') ||
        type.contains('exhibition')) {
      return 0.8;
    }

    // Social learning
    if (type.contains('community') ||
        type.contains('volunteer') ||
        type.contains('service')) {
      return 0.7;
    }

    // Some adult activities can be educational in context
    if (_isAdultOriented(type) && purpose == 'education') {
      return 0.4; // Moderate educational value
    }

    // Minimal educational value
    return 0.2;
  }

  /// Assess social value (0.0 to 1.0)
  /// Higher = better for social development
  double _assessSocialValue(
    String behaviorType,
    String? socialContext,
    Map<String, dynamic>? context,
  ) {
    final type = behaviorType.toLowerCase();

    // Highly social activities
    if (type.contains('community') ||
        type.contains('volunteer') ||
        type.contains('team') ||
        type.contains('group') ||
        type.contains('club') ||
        type.contains('social')) {
      return 0.9;
    }

    // Social venues (context-dependent)
    if (type.contains('bar') ||
        type.contains('pub') ||
        type.contains('cafe') ||
        type.contains('restaurant') ||
        type.contains('lounge')) {
      // Social value depends on context
      if (socialContext == 'friends' || socialContext == 'family') {
        return 0.7; // Good for social connection
      }
      return 0.4; // Moderate social value
    }

    // Solo activities have lower social value
    if (type.contains('solo') || type.contains('alone')) {
      return 0.2;
    }

    return 0.5; // Neutral
  }

  /// Assess risk level (0.0 to 1.0)
  /// Higher = higher risk (inverse of safety)
  /// Lower = safer
  double _assessRiskLevel(
    String behaviorType,
    int? age,
    Map<String, dynamic>? context,
  ) {
    if (age == null) return 0.5; // Neutral if age unknown

    final type = behaviorType.toLowerCase();
    final socialContext = context?['socialContext'] as String?;

    // High-risk activities
    if (type.contains('casino') ||
        type.contains('gambling') ||
        type.contains('extreme') ||
        type.contains('dangerous')) {
      return 0.9; // High risk
    }

    // Alcohol-related (risk increases for younger ages)
    if (type.contains('bar') ||
        type.contains('pub') ||
        type.contains('alcohol') ||
        type.contains('drinking') ||
        type.contains('brewery') ||
        type.contains('wine')) {
      if (age < 18) return 0.8; // High risk for minors
      if (age < 21) return 0.6; // Moderate risk for 18-20
      if (socialContext == 'supervised' || context?['purpose'] == 'education') {
        return 0.3; // Lower risk with supervision/education
      }
      return 0.5; // Moderate risk for adults
    }

    // Nightlife (risk increases for younger)
    if (type.contains('nightclub') ||
        type.contains('nightlife') ||
        type.contains('club')) {
      if (age < 18) return 0.9; // Very high risk
      if (age < 21) return 0.7; // High risk
      return 0.5; // Moderate risk for adults
    }

    // Low-risk activities
    if (type.contains('museum') ||
        type.contains('library') ||
        type.contains('park') ||
        type.contains('educational') ||
        type.contains('cultural')) {
      return 0.1; // Very low risk
    }

    return 0.4; // Moderate risk
  }

  /// Assess cultural value (0.0 to 1.0)
  /// Higher = more culturally enriching
  double _assessCulturalValue(
      String behaviorType, Map<String, dynamic>? context) {
    final type = behaviorType.toLowerCase();

    if (type.contains('museum') ||
        type.contains('gallery') ||
        type.contains('art') ||
        type.contains('orchestra') ||
        type.contains('symphony') ||
        type.contains('theater') ||
        type.contains('cultural') ||
        type.contains('heritage') ||
        type.contains('history')) {
      return 0.9;
    }

    if (type.contains('music') ||
        type.contains('dance') ||
        type.contains('performance') ||
        type.contains('festival') ||
        type.contains('exhibition')) {
      return 0.7;
    }

    return 0.3; // Lower cultural value
  }

  /// Assess physical activity value (0.0 to 1.0)
  /// Higher = more physically active
  double _assessPhysicalActivityValue(
      String behaviorType, Map<String, dynamic>? context) {
    final type = behaviorType.toLowerCase();

    if (type.contains('sport') ||
        type.contains('fitness') ||
        type.contains('exercise') ||
        type.contains('gym') ||
        type.contains('hiking') ||
        type.contains('running') ||
        type.contains('swimming') ||
        type.contains('cycling') ||
        type.contains('outdoor')) {
      return 0.9;
    }

    if (type.contains('walking') ||
        type.contains('park') ||
        type.contains('outdoor')) {
      return 0.6;
    }

    return 0.2; // Low physical activity
  }

  // Helper methods for categorization

  bool _isEducationalOrCultural(String type, String? purpose) {
    return type.contains('museum') ||
        type.contains('library') ||
        type.contains('school') ||
        type.contains('orchestra') ||
        type.contains('symphony') ||
        type.contains('theater') ||
        type.contains('gallery') ||
        type.contains('art') ||
        type.contains('cultural') ||
        type.contains('education') ||
        type.contains('class') ||
        type.contains('workshop') ||
        purpose == 'education';
  }

  bool _isPhysicalActivity(String type) {
    return type.contains('sport') ||
        type.contains('fitness') ||
        type.contains('exercise') ||
        type.contains('gym') ||
        type.contains('hiking') ||
        type.contains('outdoor') ||
        type.contains('park') ||
        type.contains('swimming') ||
        type.contains('cycling');
  }

  bool _isSocialActivity(String type) {
    return type.contains('social') ||
        type.contains('community') ||
        type.contains('group') ||
        type.contains('team') ||
        type.contains('club') ||
        type.contains('event');
  }

  bool _isAdultOriented(String type) {
    return type.contains('bar') ||
        type.contains('pub') ||
        type.contains('nightclub') ||
        type.contains('lounge') ||
        type.contains('alcohol') ||
        type.contains('drinking') ||
        type.contains('brewery') ||
        type.contains('wine') ||
        type.contains('casino') ||
        type.contains('adult') ||
        type.contains('nightlife');
  }

  /// Assess connection potential from venue characteristics
  /// CORE PHILOSOPHY: Potential for meaningful life connections
  /// Not about venue "sophistication" but about likelihood of meeting people
  /// who could positively impact the user's life (big or small)
  ///
  /// Bemelmans vs dive bar: Different connection potential, not "better" vs "worse"
  /// - Bemelmans: Higher probability of meaningful conversations, life-changing encounters
  /// - Dive bar: Different connection potential, different types of meaningful relationships
  VenueQualityProfile _assessVenueQuality(Map<String, dynamic>? context) {
    if (context == null) {
      return VenueQualityProfile.neutral();
    }

    // Extract venue characteristics from context
    // These could come from spot metadata, tags, rating, price level, description
    final rating = context['rating'] as double?;
    final priceLevel = context['priceLevel']
        as String?; // 'low', 'moderate', 'high', 'premium'
    final tags = context['tags'] as List<dynamic>?;
    final description = context['description'] as String? ?? '';
    final name = context['name'] as String? ?? '';
    final metadata = context['metadata'] as Map<String, dynamic>?;

    // Assess sophistication (0.0 to 1.0)
    final sophistication = _assessSophistication(
        rating, priceLevel, tags, description, name, metadata);

    // Assess ambiance (0.0 to 1.0)
    final ambiance = _assessAmbiance(tags, description, name, metadata);

    // Assess cultural sophistication (0.0 to 1.0)
    final culturalSophistication =
        _assessCulturalSophistication(tags, description, name, metadata);

    // Assess safety/risk factors (0.0 to 1.0, higher = safer)
    final safetyLevel = _assessSafetyLevel(rating, tags, description, metadata);

    return VenueQualityProfile(
      sophistication: sophistication,
      ambiance: ambiance,
      culturalSophistication: culturalSophistication,
      safetyLevel: safetyLevel,
    );
  }

  /// Assess connection potential (0.0 to 1.0)
  /// Higher = higher potential for meaningful life connections
  /// Not about "sophistication" but about likelihood of life-changing encounters
  /// Bemelmans: Higher probability of meaningful conversations that could change someone's life
  /// Dive bar: Different connection potential, different types of meaningful relationships
  double _assessSophistication(
    double? rating,
    String? priceLevel,
    List<dynamic>? tags,
    String description,
    String name,
    Map<String, dynamic>? metadata,
  ) {
    double score = 0.5; // Start neutral

    // Higher rating = more likely to have meaningful connections
    // (People rate places highly when they have good experiences/connections)
    if (rating != null) {
      score += (rating / 5.0) * 0.2; // Up to 0.2 boost
    }

    // Price level can indicate connection potential
    // Higher price venues often attract people seeking meaningful experiences
    if (priceLevel != null) {
      switch (priceLevel.toLowerCase()) {
        case 'premium':
        case 'high':
          score +=
              0.2; // Slight boost (not "better", just different connection potential)
          break;
        case 'moderate':
          score += 0.0; // Neutral
          break;
        case 'low':
          score += 0.0; // Neutral (not worse, just different)
          break;
      }
    }

    // Tags indicate connection potential
    if (tags != null) {
      final tagStrings = tags.map((t) => t.toString().toLowerCase()).toList();

      // Connection potential indicators (places where meaningful conversations happen)
      if (tagStrings.any((t) =>
          t.contains('art') ||
          t.contains('cultural') ||
          t.contains('literary') ||
          t.contains('intellectual') ||
          t.contains('community') ||
          t.contains('welcoming') ||
          t.contains('conversation') ||
          t.contains('networking'))) {
        score += 0.4; // Higher connection potential
      }

      // Lower connection potential indicators (but not "bad")
      if (tagStrings.any((t) =>
          t.contains('dive') ||
          t.contains('grungy') ||
          t.contains('seedy') ||
          t.contains('sketchy') ||
          t.contains('rough'))) {
        score -=
            0.2; // Lower connection potential (different type of connections)
      }
    }

    // Description/name analysis - look for connection potential indicators
    final combinedText = '$name $description'.toLowerCase();
    if (combinedText.contains('art') ||
        combinedText.contains('gallery') ||
        combinedText.contains('cultural') ||
        combinedText.contains('literary') ||
        combinedText.contains('intellectual') ||
        combinedText.contains('conversation') ||
        combinedText.contains('community') ||
        combinedText.contains('welcoming')) {
      score += 0.3; // Higher connection potential
    }

    if (combinedText.contains('dive') ||
        combinedText.contains('grungy') ||
        combinedText.contains('seedy') ||
        combinedText.contains('sketchy')) {
      score -= 0.2; // Lower connection potential (different type)
    }

    return score.clamp(0.0, 1.0);
  }

  /// Assess connection environment (0.0 to 1.0)
  /// Higher = better environment for meaningful connections (welcoming, conducive to conversation)
  /// Lower = less conducive to meaningful connections (but not "bad")
  double _assessAmbiance(
    List<dynamic>? tags,
    String description,
    String name,
    Map<String, dynamic>? metadata,
  ) {
    double score = 0.5; // Start neutral

    final combinedText = '$name $description'.toLowerCase();
    final tagStrings =
        tags?.map((t) => t.toString().toLowerCase()).toList() ?? [];

    // Connection-conducive environment indicators
    // Places where meaningful conversations and connections are more likely
    if (combinedText.contains('welcoming') ||
        combinedText.contains('cozy') ||
        combinedText.contains('conversation') ||
        combinedText.contains('community') ||
        combinedText.contains('intimate') ||
        combinedText.contains('relaxed') ||
        tagStrings.any((t) =>
            t.contains('welcoming') ||
            t.contains('cozy') ||
            t.contains('conversation') ||
            t.contains('community'))) {
      score += 0.3; // Better environment for connections
    }

    // Less connection-conducive indicators (but not "bad")
    // Different types of connections happen in different environments
    if (combinedText.contains('grungy') ||
        combinedText.contains('seedy') ||
        combinedText.contains('rough') ||
        combinedText.contains('sketchy') ||
        combinedText.contains('dive') ||
        combinedText.contains('loud') ||
        tagStrings.any((t) =>
            t.contains('grungy') ||
            t.contains('seedy') ||
            t.contains('rough') ||
            t.contains('loud'))) {
      score -= 0.2; // Less conducive to meaningful connections (different type)
    }

    return score.clamp(0.0, 1.0);
  }

  /// Assess life-changing connection potential (0.0 to 1.0)
  /// Higher = higher potential for life-changing encounters
  /// Places with art, culture, intellectual activity = higher probability of meaningful connections
  /// that could change someone's life
  double _assessCulturalSophistication(
    List<dynamic>? tags,
    String description,
    String name,
    Map<String, dynamic>? metadata,
  ) {
    double score =
        0.3; // Start lower (most venues aren't culturally sophisticated)

    final combinedText = '$name $description'.toLowerCase();
    final tagStrings =
        tags?.map((t) => t.toString().toLowerCase()).toList() ?? [];

    // Life-changing connection potential indicators
    // Places where one good conversation could change someone's life
    if (combinedText.contains('art') ||
        combinedText.contains('gallery') ||
        combinedText.contains('music') ||
        combinedText.contains('jazz') ||
        combinedText.contains('orchestra') ||
        combinedText.contains('symphony') ||
        combinedText.contains('literary') ||
        combinedText.contains('book') ||
        combinedText.contains('cultural') ||
        combinedText.contains('heritage') ||
        combinedText.contains('intellectual') ||
        combinedText.contains('conversation') ||
        tagStrings.any((t) =>
            t.contains('art') ||
            t.contains('cultural') ||
            t.contains('music') ||
            t.contains('literary') ||
            t.contains('intellectual') ||
            t.contains('conversation'))) {
      score +=
          0.5; // Significant boost - higher probability of meaningful connections
    }

    // Bemelmans example: Art murals create conversation starters
    // Higher probability of meaningful conversations that could change someone's life
    if (name.toLowerCase().contains('bemelmans') ||
        combinedText.contains('bemelmans') ||
        combinedText.contains('murals') ||
        combinedText.contains('artwork')) {
      score += 0.3; // Extra boost - art creates connection opportunities
    }

    return score.clamp(0.0, 1.0);
  }

  /// Assess safety level (0.0 to 1.0)
  /// Higher = safer venue
  /// Lower = less safe (higher risk)
  double _assessSafetyLevel(
    double? rating,
    List<dynamic>? tags,
    String description,
    Map<String, dynamic>? metadata,
  ) {
    double score = 0.6; // Start moderate

    // Higher rating generally indicates safer venue
    if (rating != null) {
      score += (rating / 5.0) * 0.2; // Up to 0.2 boost
    }

    final combinedText = description.toLowerCase();
    final tagStrings =
        tags?.map((t) => t.toString().toLowerCase()).toList() ?? [];

    // Safety indicators
    if (combinedText.contains('safe') ||
        combinedText.contains('welcoming') ||
        combinedText.contains('family') ||
        combinedText.contains('upscale') ||
        tagStrings.any((t) => t.contains('safe') || t.contains('welcoming'))) {
      score += 0.2;
    }

    // Risk indicators
    if (combinedText.contains('sketchy') ||
        combinedText.contains('rough') ||
        combinedText.contains('seedy') ||
        combinedText.contains('dive') ||
        combinedText.contains('grungy') ||
        combinedText.contains('dangerous') ||
        tagStrings.any((t) =>
            t.contains('sketchy') ||
            t.contains('rough') ||
            t.contains('seedy') ||
            t.contains('dangerous'))) {
      score -= 0.4;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate adjustments to dimension scores based on connection potential
  /// Venues with higher connection potential (like Bemelmans) boost learning value
  /// Not about "sophistication" but about likelihood of meaningful life connections
  VenueQualityAdjustments _calculateVenueQualityAdjustments(
    String behaviorType,
    VenueQualityProfile venueQuality,
  ) {
    final type = behaviorType.toLowerCase();

    // Only apply adjustments to adult-oriented venues (bars, lounges, etc.)
    // Educational/cultural venues already have high connection potential
    if (!_isAdultOriented(type)) {
      return VenueQualityAdjustments.zero();
    }

    // High connection potential venues (like Bemelmans)
    // Higher probability of meaningful conversations that could change someone's life
    if (venueQuality.sophistication >= 0.7) {
      return VenueQualityAdjustments(
        developmental: 0.1, // Slightly more appropriate
        educational: venueQuality.culturalSophistication *
            0.3, // Boost - meaningful connections are educational
        social: 0.1, // Better environment for connections
        risk: -(1.0 - venueQuality.safetyLevel) *
            0.2, // Reduce risk (negative = lower risk)
        cultural: venueQuality.culturalSophistication *
            0.4, // Significant boost - life-changing potential
      );
    }

    // Lower connection potential venues (dive bars)
    // Different types of connections, different potential for life-changing encounters
    if (venueQuality.sophistication <= 0.3) {
      return VenueQualityAdjustments(
        developmental: -0.05, // Slightly less appropriate (not "bad")
        educational:
            -0.1, // Lower educational value (different connection type)
        social: -0.05, // Different social environment
        risk: 0.15, // Slightly higher risk
        cultural: -0.2, // Lower cultural value (different connection potential)
      );
    }

    // Moderate venues - minimal adjustments
    return VenueQualityAdjustments.zero();
  }

  /// Calculate learning filter based on multidimensional assessment
  /// Returns 0.0 (block) to 1.0 (full learning)
  /// This is the probabilistic filter for the convergence formula
  ///
  /// CORE PHILOSOPHY: Vibe-based matching
  /// - The overall vibe of the spot (from business accounts) should match
  ///   the overall vibe of the user (from AI2AI system)
  /// - Not just individual behaviors, but overall vibe compatibility
  /// - Business accounts define spot vibe, users are "called" to matching spots
  /// - Better matches = happier everyone
  ///
  /// Individual trajectory potential:
  /// - What leads to positive trajectory for THIS unique individual child?
  /// - What makes THIS kid happy and healthy mentally?
  /// - Not universal "good" vs "bad" - user-specific potential
  double calculateLearningFilter(
    UnifiedUser learner,
    UnifiedUser influencer,
    String behaviorType,
    Map<String, dynamic>? behaviorContext, {
    Map<String, double>?
        learnerPersonality, // User's personality profile for individual matching
    List<String>?
        learnerPreferences, // User's preferences for trajectory matching
    Map<String, dynamic>?
        learnerHistory, // User's history of what works for them
  }) {
    final learnerAge = learner.age;
    final influencerAge = influencer.age;

    // If ages unknown, allow moderate learning
    if (learnerAge == null || influencerAge == null) {
      return 0.5;
    }

    // If learner is not younger, allow full learning
    if (learnerAge >= influencerAge) {
      return 1.0;
    }

    // Assess behavior on multiple dimensions (includes venue quality assessment)
    final profile = assessBehavior(behaviorType, behaviorContext, learnerAge);

    // Calculate learning filter based on multiple factors
    // CORE PHILOSOPHY: Individual trajectory potential for THIS unique child
    // Weight different dimensions based on what leads to positive growth for THIS user

    // Developmental appropriateness is most important (40% weight)
    // Ensures age-appropriate connections
    final developmentalScore = profile.developmentalAppropriateness;

    // Educational/life-changing value is important (25% weight)
    // Higher = more likely to have life-changing encounters
    final educationalScore = profile.educationalValue;

    // Risk level (inverse - lower risk = higher learning) (20% weight)
    // Safety matters for meaningful connections
    final riskScore = 1.0 - profile.riskLevel; // Invert risk

    // Social value (10% weight)
    // Connection potential - likelihood of meaningful social interactions
    final socialScore = profile.socialValue;

    // Cultural/life-changing potential (5% weight)
    // Higher = higher probability of life-changing connections
    final culturalScore = profile.culturalValue;

    // Base weighted combination
    var learningFilter = (developmentalScore * 0.40 +
            educationalScore * 0.25 +
            riskScore * 0.20 +
            socialScore * 0.10 +
            culturalScore * 0.05)
        .clamp(0.0, 1.0);

    // NEW: Apply user-specific trajectory adjustment
    // What works for THIS unique individual child?
    // Some kids thrive with dive bar influence, others with Bemelmans influence
    if (learnerPersonality != null ||
        learnerPreferences != null ||
        learnerHistory != null) {
      final trajectoryAdjustment = _calculateIndividualTrajectoryAdjustment(
        profile,
        learnerPersonality,
        learnerPreferences,
        learnerHistory,
        behaviorContext,
      );

      // Adjust learning filter based on individual trajectory potential
      // Positive adjustment = this behavior aligns with THIS user's positive trajectory
      // Negative adjustment = this behavior doesn't align with THIS user's trajectory
      learningFilter = (learningFilter + trajectoryAdjustment).clamp(0.0, 1.0);

      developer.log(
        'Individual trajectory adjustment: $trajectoryAdjustment, '
        'final learning filter: $learningFilter for user ${learner.id}',
        name: _logName,
      );
    }

    developer.log(
      'Learning filter for "$behaviorType" (learner age $learnerAge): '
      'developmental=${developmentalScore.toStringAsFixed(2)}, '
      'educational=${educationalScore.toStringAsFixed(2)}, '
      'risk=${profile.riskLevel.toStringAsFixed(2)}, '
      'final=${learningFilter.toStringAsFixed(2)}',
      name: _logName,
    );

    return learningFilter;
  }

  /// Calculate individual trajectory adjustment
  /// CORE PHILOSOPHY: What leads to positive trajectory for THIS unique individual child?
  /// - Some kids might thrive with dive bar influence (if it leads to their happiness)
  /// - Other kids might thrive with Bemelmans influence (if that's what works for them)
  /// - It's about individual potential future growth, not universal judgment
  double _calculateIndividualTrajectoryAdjustment(
    BehaviorProfile profile,
    Map<String, double>? learnerPersonality,
    List<String>? learnerPreferences,
    Map<String, dynamic>? learnerHistory,
    Map<String, dynamic>? behaviorContext,
  ) {
    double adjustment = 0.0; // Start neutral

    // If we don't have user-specific data, return neutral (no adjustment)
    if (learnerPersonality == null &&
        learnerPreferences == null &&
        learnerHistory == null) {
      return 0.0;
    }

    // Assess if this behavior aligns with user's personality and preferences
    // This determines if it would lead to positive trajectory for THIS user

    // Personality-based matching
    if (learnerPersonality != null) {
      // Check if behavior aligns with user's personality dimensions
      // Example: User with high exploration_eagerness might benefit from diverse influences
      // User with high authenticity_preference might benefit from genuine, unpretentious places

      final explorationEagerness =
          learnerPersonality['exploration_eagerness'] ?? 0.5;
      final authenticityPreference =
          learnerPersonality['authenticity_preference'] ?? 0.5;
      final communityOrientation =
          learnerPersonality['community_orientation'] ?? 0.5;

      // High exploration = more open to diverse influences (including dive bars)
      if (explorationEagerness > 0.7) {
        adjustment += 0.1; // More open to diverse connection types
      }

      // High authenticity = might prefer genuine, unpretentious places
      if (authenticityPreference > 0.7) {
        // Dive bars might have higher authenticity value for this user
        final venueType =
            behaviorContext?['name']?.toString().toLowerCase() ?? '';
        if (venueType.contains('dive') ||
            venueType.contains('authentic') ||
            venueType.contains('local')) {
          adjustment += 0.15; // Authentic places align with user's preference
        }
      }

      // High community orientation = might benefit from community-focused places
      if (communityOrientation > 0.7) {
        final venueType =
            behaviorContext?['name']?.toString().toLowerCase() ?? '';
        if (venueType.contains('community') ||
            venueType.contains('local') ||
            venueType.contains('neighborhood')) {
          adjustment += 0.1; // Community places align with user's preference
        }
      }
    }

    // Preference-based matching
    if (learnerPreferences != null) {
      final behaviorType =
          behaviorContext?['behaviorType']?.toString().toLowerCase() ?? '';
      final venueName =
          behaviorContext?['name']?.toString().toLowerCase() ?? '';
      final venueDescription =
          behaviorContext?['description']?.toString().toLowerCase() ?? '';
      final combinedText = '$behaviorType $venueName $venueDescription';

      // Check if behavior aligns with user's preferences
      for (final preference in learnerPreferences) {
        final prefLower = preference.toLowerCase();
        if (combinedText.contains(prefLower)) {
          adjustment += 0.2; // Significant boost if aligns with preferences
        }
      }
    }

    // History-based learning
    // If user has had positive experiences with similar venues/behaviors, boost
    if (learnerHistory != null) {
      final successfulConnections =
          learnerHistory['successful_connections'] as List<dynamic>?;
      final positiveExperiences =
          learnerHistory['positive_experiences'] as List<dynamic>?;

      if (successfulConnections != null || positiveExperiences != null) {
        final behaviorType =
            behaviorContext?['behaviorType']?.toString().toLowerCase() ?? '';
        final venueName =
            behaviorContext?['name']?.toString().toLowerCase() ?? '';

        // Check if similar behaviors/venues led to positive outcomes
        final allHistory = [
          ...?successfulConnections,
          ...?positiveExperiences,
        ];

        for (final experience in allHistory) {
          final expStr = experience.toString().toLowerCase();
          if (expStr.contains(behaviorType) ||
              (venueName.isNotEmpty && expStr.contains(venueName))) {
            adjustment += 0.15; // Boost if similar experiences were positive
            break; // Only count once
          }
        }
      }
    }

    // Clamp adjustment to reasonable range (-0.3 to +0.3)
    // This allows significant adjustment but doesn't completely override base assessment
    return adjustment.clamp(-0.3, 0.3);
  }
}

/// Multidimensional behavior profile
/// Represents a behavior assessed across multiple dimensions
class BehaviorProfile {
  final String behaviorType;
  final double developmentalAppropriateness; // 0.0 to 1.0
  final double educationalValue; // 0.0 to 1.0
  final double socialValue; // 0.0 to 1.0
  final double riskLevel; // 0.0 to 1.0 (higher = riskier)
  final double culturalValue; // 0.0 to 1.0
  final double physicalActivityValue; // 0.0 to 1.0
  final Map<String, dynamic> context;
  final DateTime assessedAt;

  BehaviorProfile({
    required this.behaviorType,
    required this.developmentalAppropriateness,
    required this.educationalValue,
    required this.socialValue,
    required this.riskLevel,
    required this.culturalValue,
    required this.physicalActivityValue,
    required this.context,
    required this.assessedAt,
  });

  /// Get overall appropriateness score (weighted combination)
  double get overallAppropriateness {
    return (developmentalAppropriateness * 0.40 +
            educationalValue * 0.25 +
            (1.0 - riskLevel) * 0.20 + // Invert risk
            socialValue * 0.10 +
            culturalValue * 0.05)
        .clamp(0.0, 1.0);
  }

  /// Check if behavior is generally appropriate (threshold-based, not binary)
  bool isAppropriate({double threshold = 0.5}) {
    return overallAppropriateness >= threshold;
  }
}

/// Connection potential profile - assesses likelihood of meaningful life connections
/// Distinguishes between venues with high connection potential (Bemelmans)
/// vs venues with different connection potential (dive bars)
///
/// CORE PHILOSOPHY: Not about "sophistication" but about potential for meaningful relationships
/// that could change someone's life (big or small)
class VenueQualityProfile {
  final double
      sophistication; // 0.0 to 1.0 (higher = higher connection potential)
  final double
      ambiance; // 0.0 to 1.0 (higher = better environment for connections)
  final double
      culturalSophistication; // 0.0 to 1.0 (higher = higher life-changing potential)
  final double
      safetyLevel; // 0.0 to 1.0 (higher = safer, more conducive to connections)

  VenueQualityProfile({
    required this.sophistication,
    required this.ambiance,
    required this.culturalSophistication,
    required this.safetyLevel,
  });

  factory VenueQualityProfile.neutral() {
    return VenueQualityProfile(
      sophistication: 0.5,
      ambiance: 0.5,
      culturalSophistication: 0.3,
      safetyLevel: 0.6,
    );
  }

  /// Get overall connection potential score
  /// Higher = higher probability of meaningful life connections
  double get overallQuality {
    return (sophistication * 0.30 + // Connection potential
            ambiance * 0.25 + // Connection environment
            culturalSophistication * 0.25 + // Life-changing potential
            safetyLevel * 0.20 // Safety for connections
        )
        .clamp(0.0, 1.0);
  }
}

/// Adjustments to dimension scores based on venue quality
class VenueQualityAdjustments {
  final double developmental; // Adjustment to developmental appropriateness
  final double educational; // Adjustment to educational value
  final double social; // Adjustment to social value
  final double risk; // Adjustment to risk level (positive = more risk)
  final double cultural; // Adjustment to cultural value

  VenueQualityAdjustments({
    required this.developmental,
    required this.educational,
    required this.social,
    required this.risk,
    required this.cultural,
  });

  factory VenueQualityAdjustments.zero() {
    return VenueQualityAdjustments(
      developmental: 0.0,
      educational: 0.0,
      social: 0.0,
      risk: 0.0,
      cultural: 0.0,
    );
  }
}
