import 'package:flutter/material.dart';
import 'package:avrai/core/models/user/dimension_question.dart';

/// Provides the 12 dimension questions used during onboarding.
///
/// Each step (5-8) contains 3 questions, covering all 12 avrai dimensions.
/// Questions are designed to directly measure dimensions through user choices.
class OnboardingQuestionBank {
  OnboardingQuestionBank._();

  // ============================================================
  // STEP 5: DISCOVERY STYLE
  // Dimensions: exploration_eagerness, novelty_seeking, location_adventurousness
  // ============================================================

  static const discoveryQuestions = [
    // Question 5.1: exploration_eagerness
    DimensionQuestion(
      id: 'discovery_5_1',
      prompt: 'When looking for a new place to go...',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'exploration_eagerness', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'hidden_gems',
          label: 'I love finding hidden gems nobody knows about',
          dimensionValues: {'exploration_eagerness': 0.85},
          icon: Icons.explore,
        ),
        QuestionOption(
          id: 'mix_both',
          label: 'I like a mix of new discoveries and popular spots',
          dimensionValues: {'exploration_eagerness': 0.55},
          icon: Icons.shuffle,
        ),
        QuestionOption(
          id: 'popular_spots',
          label: 'I prefer popular spots that are tried and tested',
          dimensionValues: {'exploration_eagerness': 0.25},
          icon: Icons.star,
        ),
      ],
    ),

    // Question 5.2: novelty_seeking
    DimensionQuestion(
      id: 'discovery_5_2',
      prompt: 'When you have a free evening...',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'novelty_seeking', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'always_new',
          label: 'I want to try somewhere completely new',
          dimensionValues: {'novelty_seeking': 0.9},
          icon: Icons.new_releases,
        ),
        QuestionOption(
          id: 'mostly_new',
          label: 'Usually somewhere new, occasionally an old favorite',
          dimensionValues: {'novelty_seeking': 0.7},
          icon: Icons.autorenew,
        ),
        QuestionOption(
          id: 'balance',
          label: 'A good balance of new and familiar',
          dimensionValues: {'novelty_seeking': 0.5},
          icon: Icons.balance,
        ),
        QuestionOption(
          id: 'favorites',
          label: 'I have my favorite spots and stick to them',
          dimensionValues: {'novelty_seeking': 0.2},
          icon: Icons.favorite,
        ),
      ],
    ),

    // Question 5.3: location_adventurousness
    DimensionQuestion(
      id: 'discovery_5_3',
      prompt: 'How far would you travel for a great spot?',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'location_adventurousness', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'walking',
          label: 'Walking distance (5-10 min)',
          dimensionValues: {'location_adventurousness': 0.15},
          icon: Icons.directions_walk,
        ),
        QuestionOption(
          id: 'short_drive',
          label: 'Short drive/transit (15-20 min)',
          dimensionValues: {'location_adventurousness': 0.35},
          icon: Icons.directions_car,
        ),
        QuestionOption(
          id: 'medium_drive',
          label: 'Worth a trip (30-45 min)',
          dimensionValues: {'location_adventurousness': 0.6},
          icon: Icons.local_taxi,
        ),
        QuestionOption(
          id: 'long_drive',
          label: "I'd travel an hour for the right place",
          dimensionValues: {'location_adventurousness': 0.8},
          icon: Icons.flight,
        ),
        QuestionOption(
          id: 'anywhere',
          label: "Distance doesn't matter for great experiences",
          dimensionValues: {'location_adventurousness': 0.95},
          icon: Icons.public,
        ),
      ],
    ),
  ];

  // ============================================================
  // STEP 6: SOCIAL VIBE
  // Dimensions: community_orientation, trust_network_reliance, social_discovery_style
  // ============================================================

  static const socialQuestions = [
    // Question 6.1: community_orientation (slider)
    DimensionQuestion(
      id: 'social_6_1',
      prompt: 'Your ideal outing involves...',
      type: QuestionType.slider,
      impacts: [
        DimensionImpact(dimension: 'community_orientation', weight: 1.0),
      ],
      sliderConfig: SliderConfig(
        lowLabel: 'Just me, enjoying my own company',
        highLabel: 'The more people, the better',
        defaultValue: 0.5,
        lowIcon: Icons.person,
        highIcon: Icons.groups,
        stops: [
          SliderStop(value: 0.0, label: 'Solo'),
          SliderStop(value: 0.33, label: '1-2 friends'),
          SliderStop(value: 0.66, label: 'Small group'),
          SliderStop(value: 1.0, label: 'Big group'),
        ],
      ),
    ),

    // Question 6.2: trust_network_reliance (slider)
    DimensionQuestion(
      id: 'social_6_2',
      prompt: 'When deciding where to go...',
      type: QuestionType.slider,
      impacts: [
        DimensionImpact(dimension: 'trust_network_reliance', weight: 1.0),
      ],
      sliderConfig: SliderConfig(
        lowLabel: 'I trust my own instincts',
        highLabel: 'I rely on friend recommendations',
        defaultValue: 0.5,
        lowIcon: Icons.psychology,
        highIcon: Icons.recommend,
      ),
    ),

    // Question 6.3: social_discovery_style (multi-select)
    DimensionQuestion(
      id: 'social_6_3',
      prompt: 'How do you usually find new places?',
      subtitle: 'Pick your top 2',
      type: QuestionType.multiChoice,
      maxSelections: 2,
      impacts: [
        DimensionImpact(dimension: 'social_discovery_style', weight: 0.8),
      ],
      options: [
        QuestionOption(
          id: 'walking_around',
          label: 'Just walking around and stumbling upon them',
          dimensionValues: {
            'social_discovery_style': 0.2,
            'exploration_eagerness': 0.1,
          },
          icon: Icons.directions_walk,
        ),
        QuestionOption(
          id: 'apps_reviews',
          label: 'Apps and online reviews',
          dimensionValues: {'social_discovery_style': 0.4},
          icon: Icons.phone_android,
        ),
        QuestionOption(
          id: 'friends_recs',
          label: 'Friend recommendations',
          dimensionValues: {
            'social_discovery_style': 0.7,
            'trust_network_reliance': 0.1,
          },
          icon: Icons.people,
        ),
        QuestionOption(
          id: 'social_media',
          label: 'Social media and influencers',
          dimensionValues: {'social_discovery_style': 0.85},
          icon: Icons.tag,
        ),
        QuestionOption(
          id: 'events',
          label: 'Events and community gatherings',
          dimensionValues: {
            'social_discovery_style': 0.9,
            'community_orientation': 0.1,
          },
          icon: Icons.event,
        ),
      ],
    ),
  ];

  // ============================================================
  // STEP 7: ENERGY & ATMOSPHERE
  // Dimensions: energy_preference, crowd_tolerance, temporal_flexibility
  // ============================================================

  static const energyQuestions = [
    // Question 7.1: energy_preference (slider)
    DimensionQuestion(
      id: 'energy_7_1',
      prompt: "What's your ideal energy level for a night out?",
      type: QuestionType.slider,
      impacts: [
        DimensionImpact(dimension: 'energy_preference', weight: 1.0),
      ],
      sliderConfig: SliderConfig(
        lowLabel: 'Chill vibes, low-key',
        highLabel: 'High energy, dancing and action',
        defaultValue: 0.5,
        lowIcon: Icons.nights_stay,
        highIcon: Icons.celebration,
      ),
    ),

    // Question 7.2: crowd_tolerance
    DimensionQuestion(
      id: 'energy_7_2',
      prompt: 'Your ideal atmosphere?',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'crowd_tolerance', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'empty',
          label: 'Nearly empty - just a few people',
          dimensionValues: {'crowd_tolerance': 0.1},
          icon: Icons.person,
        ),
        QuestionOption(
          id: 'quiet',
          label: 'Quiet - small groups, conversations',
          dimensionValues: {'crowd_tolerance': 0.35},
          icon: Icons.people,
        ),
        QuestionOption(
          id: 'lively',
          label: "Lively - good buzz, some energy",
          dimensionValues: {'crowd_tolerance': 0.65},
          icon: Icons.groups,
        ),
        QuestionOption(
          id: 'packed',
          label: "Packed - buzzing, everyone's there",
          dimensionValues: {'crowd_tolerance': 0.9},
          icon: Icons.celebration,
        ),
      ],
    ),

    // Question 7.3: temporal_flexibility (slider)
    DimensionQuestion(
      id: 'energy_7_3',
      prompt: 'For your weekends...',
      type: QuestionType.slider,
      impacts: [
        DimensionImpact(dimension: 'temporal_flexibility', weight: 1.0),
      ],
      sliderConfig: SliderConfig(
        lowLabel: 'I plan everything in advance',
        highLabel: 'Totally spontaneous, decide in the moment',
        defaultValue: 0.5,
        lowIcon: Icons.calendar_month,
        highIcon: Icons.bolt,
      ),
    ),
  ];

  // ============================================================
  // STEP 8: VALUES & SHARING
  // Dimensions: value_orientation, authenticity_preference, curation_tendency
  // ============================================================

  static const valuesQuestions = [
    // Question 8.1: value_orientation (slider)
    DimensionQuestion(
      id: 'values_8_1',
      prompt: 'When it comes to spending on experiences...',
      type: QuestionType.slider,
      impacts: [
        DimensionImpact(dimension: 'value_orientation', weight: 1.0),
      ],
      sliderConfig: SliderConfig(
        lowLabel: 'I love a good deal',
        highLabel: 'Worth splurging for quality',
        defaultValue: 0.5,
        lowIcon: Icons.savings,
        highIcon: Icons.diamond,
        stops: [
          SliderStop(value: 0.0, label: 'Budget'),
          SliderStop(value: 0.5, label: 'Balanced'),
          SliderStop(value: 1.0, label: 'Premium'),
        ],
      ),
    ),

    // Question 8.2: authenticity_preference
    DimensionQuestion(
      id: 'values_8_2',
      prompt: 'What matters more to you?',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'authenticity_preference', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'local_authentic',
          label: 'Local, authentic, off-the-beaten-path',
          dimensionValues: {'authenticity_preference': 0.9},
          icon: Icons.storefront,
        ),
        QuestionOption(
          id: 'mostly_authentic',
          label: 'Mostly local spots, occasionally trendy places',
          dimensionValues: {'authenticity_preference': 0.7},
          icon: Icons.local_cafe,
        ),
        QuestionOption(
          id: 'balance',
          label: 'A good mix of both',
          dimensionValues: {'authenticity_preference': 0.5},
          icon: Icons.balance,
        ),
        QuestionOption(
          id: 'trendy',
          label: 'I enjoy trendy, Instagram-worthy spots',
          dimensionValues: {'authenticity_preference': 0.3},
          icon: Icons.camera_alt,
        ),
      ],
    ),

    // Question 8.3: curation_tendency
    DimensionQuestion(
      id: 'values_8_3',
      prompt: 'When you find an amazing spot...',
      type: QuestionType.choice,
      impacts: [
        DimensionImpact(dimension: 'curation_tendency', weight: 1.0),
      ],
      options: [
        QuestionOption(
          id: 'share_everyone',
          label: 'I share it with everyone - social media, friends, everyone!',
          dimensionValues: {'curation_tendency': 0.95},
          icon: Icons.share,
        ),
        QuestionOption(
          id: 'share_close',
          label: "I share with close friends who'd appreciate it",
          dimensionValues: {'curation_tendency': 0.7},
          icon: Icons.group,
        ),
        QuestionOption(
          id: 'share_asked',
          label: "I'll share if someone asks",
          dimensionValues: {'curation_tendency': 0.4},
          icon: Icons.question_answer,
        ),
        QuestionOption(
          id: 'keep_secret',
          label: 'I keep my best spots secret!',
          dimensionValues: {'curation_tendency': 0.1},
          icon: Icons.lock,
        ),
      ],
    ),
  ];

  // ============================================================
  // HELPERS
  // ============================================================

  /// Get all questions for a specific step
  static List<DimensionQuestion> getQuestionsForStep(int step) {
    switch (step) {
      case 5:
        return discoveryQuestions;
      case 6:
        return socialQuestions;
      case 7:
        return energyQuestions;
      case 8:
        return valuesQuestions;
      default:
        return [];
    }
  }

  /// Get all 12 questions
  static List<DimensionQuestion> get allQuestions => [
        ...discoveryQuestions,
        ...socialQuestions,
        ...energyQuestions,
        ...valuesQuestions,
      ];

  /// Get the dimension(s) measured by a step
  static List<String> getDimensionsForStep(int step) {
    switch (step) {
      case 5:
        return [
          'exploration_eagerness',
          'novelty_seeking',
          'location_adventurousness',
        ];
      case 6:
        return [
          'community_orientation',
          'trust_network_reliance',
          'social_discovery_style',
        ];
      case 7:
        return [
          'energy_preference',
          'crowd_tolerance',
          'temporal_flexibility',
        ];
      case 8:
        return [
          'value_orientation',
          'authenticity_preference',
          'curation_tendency',
        ];
      default:
        return [];
    }
  }
}
