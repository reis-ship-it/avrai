/// Integration tests for the new onboarding flow with dimension verification.
///
/// These tests verify that the onboarding flow correctly computes all 12
/// personality dimensions from user answers.
///
/// Test Coverage:
/// - Dimension question data models
/// - Question bank structure and completeness
/// - Dimension computer calculations
/// - Full dimension coverage from answers
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/dimension_question.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_question_bank.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_dimension_computer.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_dimension_mapper.dart';
import 'package:avrai_core/utils/vibe_constants.dart';

void main() {
  group('OnboardingQuestionBank', () {
    test('should provide 12 questions covering all 12 dimensions', () {
      final allQuestions = OnboardingQuestionBank.allQuestions;

      expect(allQuestions.length, equals(12));

      // Verify each step has 3 questions
      expect(OnboardingQuestionBank.discoveryQuestions.length, equals(3));
      expect(OnboardingQuestionBank.socialQuestions.length, equals(3));
      expect(OnboardingQuestionBank.energyQuestions.length, equals(3));
      expect(OnboardingQuestionBank.valuesQuestions.length, equals(3));
    });

    test('should cover all 12 avrai dimensions', () {
      final allQuestions = OnboardingQuestionBank.allQuestions;
      final coveredDimensions = <String>{};

      for (final question in allQuestions) {
        for (final impact in question.impacts) {
          coveredDimensions.add(impact.dimension);
        }
      }

      // Verify all 12 dimensions are covered
      for (final dim in VibeConstants.coreDimensions) {
        expect(
          coveredDimensions.contains(dim),
          isTrue,
          reason: 'Dimension $dim should be covered by at least one question',
        );
      }
    });

    test('should have unique question IDs', () {
      final allQuestions = OnboardingQuestionBank.allQuestions;
      final ids = allQuestions.map((q) => q.id).toSet();

      expect(ids.length, equals(allQuestions.length));
    });

    test('should have valid question types with required data', () {
      for (final question in OnboardingQuestionBank.allQuestions) {
        switch (question.type) {
          case QuestionType.slider:
            expect(
              question.sliderConfig,
              isNotNull,
              reason: 'Slider question ${question.id} must have sliderConfig',
            );
          case QuestionType.choice:
          case QuestionType.multiChoice:
            expect(
              question.options,
              isNotNull,
              reason: 'Choice question ${question.id} must have options',
            );
            expect(
              question.options!.length,
              greaterThanOrEqualTo(2),
              reason: 'Question ${question.id} must have at least 2 options',
            );
        }
      }
    });

    test('should have dimension values in valid range for all options', () {
      for (final question in OnboardingQuestionBank.allQuestions) {
        if (question.options != null) {
          for (final option in question.options!) {
            for (final entry in option.dimensionValues.entries) {
              expect(
                entry.value,
                inInclusiveRange(0.0, 1.0),
                reason: 'Option ${option.id} dimension ${entry.key} value '
                    '${entry.value} should be between 0.0 and 1.0',
              );
            }
          }
        }
      }
    });
  });

  group('OnboardingDimensionComputer', () {
    late OnboardingDimensionComputer computer;

    setUp(() {
      computer = OnboardingDimensionComputer();
    });

    test('should compute all 12 dimensions from complete answers', () {
      // Create answers for all 12 questions
      final answers = <QuestionAnswer>[];

      // Discovery answers (Step 5)
      final discoveryQuestions = OnboardingQuestionBank.discoveryQuestions;
      answers.add(QuestionAnswer(
        question: discoveryQuestions[0],
        value: 'hidden_gems', // exploration_eagerness
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: discoveryQuestions[1],
        value: 'always_new', // novelty_seeking
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: discoveryQuestions[2],
        value: 'medium_drive', // location_adventurousness
        answeredAt: DateTime.now(),
      ));

      // Social answers (Step 6)
      final socialQuestions = OnboardingQuestionBank.socialQuestions;
      answers.add(QuestionAnswer(
        question: socialQuestions[0],
        value: 0.7, // community_orientation (slider)
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: socialQuestions[1],
        value: 0.6, // trust_network_reliance (slider)
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: socialQuestions[2],
        value: ['friends_recs', 'events'], // social_discovery_style
        answeredAt: DateTime.now(),
      ));

      // Energy answers (Step 7)
      final energyQuestions = OnboardingQuestionBank.energyQuestions;
      answers.add(QuestionAnswer(
        question: energyQuestions[0],
        value: 0.8, // energy_preference (slider)
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: energyQuestions[1],
        value: 'lively', // crowd_tolerance
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: energyQuestions[2],
        value: 0.4, // temporal_flexibility (slider)
        answeredAt: DateTime.now(),
      ));

      // Values answers (Step 8)
      final valuesQuestions = OnboardingQuestionBank.valuesQuestions;
      answers.add(QuestionAnswer(
        question: valuesQuestions[0],
        value: 0.5, // value_orientation (slider)
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: valuesQuestions[1],
        value: 'local_authentic', // authenticity_preference
        answeredAt: DateTime.now(),
      ));
      answers.add(QuestionAnswer(
        question: valuesQuestions[2],
        value: 'share_close', // curation_tendency
        answeredAt: DateTime.now(),
      ));

      // Compute dimensions
      final result = computer.computeDimensions(answers);

      // Verify all 12 dimensions are present
      expect(result.dimensions.length, equals(12));

      for (final dim in VibeConstants.coreDimensions) {
        expect(
          result.dimensions.containsKey(dim),
          isTrue,
          reason: 'Result should contain dimension $dim',
        );
        expect(
          result.dimensions[dim],
          inInclusiveRange(0.0, 1.0),
          reason: 'Dimension $dim should be between 0.0 and 1.0',
        );
      }

      // Verify confidence values exist
      expect(result.confidence.length, equals(12));
    });

    test('should return default values for empty answers', () {
      final result = computer.computeDimensions([]);

      expect(result.dimensions.length, equals(12));
      for (final dim in VibeConstants.coreDimensions) {
        expect(
          result.dimensions[dim],
          equals(VibeConstants.defaultDimensionValue),
          reason: 'Dimension $dim should have default value with no answers',
        );
      }
    });

    test('should validate completeness correctly', () {
      final completeResult = computer.computeDimensions([
        // Add minimal answers to touch all dimensions
        QuestionAnswer(
          question: OnboardingQuestionBank.discoveryQuestions[0],
          value: 'hidden_gems',
          answeredAt: DateTime.now(),
        ),
      ]);

      // With only one answer, not all dimensions are measured with high confidence
      expect(computer.validateCompleteness(completeResult), isFalse);
    });
  });

  group('OnboardingDimensionMapper', () {
    late OnboardingDimensionMapper mapper;

    setUp(() {
      mapper = OnboardingDimensionMapper();
    });

    test('should compute dimensions from question answers', () {
      final answers = <QuestionAnswer>[];

      // Add a slider answer
      answers.add(QuestionAnswer(
        question:
            OnboardingQuestionBank.socialQuestions[0], // community_orientation
        value: 0.8,
        answeredAt: DateTime.now(),
      ));

      // Add a choice answer
      answers.add(QuestionAnswer(
        question: OnboardingQuestionBank
            .discoveryQuestions[0], // exploration_eagerness
        value: 'hidden_gems',
        answeredAt: DateTime.now(),
      ));

      final dimensions = mapper.computeDimensionsFromAnswers(answers);

      expect(dimensions['community_orientation'], equals(0.8));
      expect(dimensions['exploration_eagerness'], equals(0.85));
    });

    test('should compute confidence from answers', () {
      final answers = <QuestionAnswer>[];

      // Slider at extreme = high confidence
      answers.add(QuestionAnswer(
        question: OnboardingQuestionBank.socialQuestions[0],
        value: 0.9, // Near extreme
        answeredAt: DateTime.now(),
      ));

      final confidence = mapper.computeConfidenceFromAnswers(answers);

      expect(
        confidence['community_orientation'],
        greaterThan(0.3),
        reason:
            'Confidence should be higher than minimum for answered dimension',
      );
    });

    test('legacy mapping should still work', () {
      final onboardingData = {
        'age': 25,
        'homebase': 'San Francisco',
        'favoritePlaces': [
          'Place1',
          'Place2',
          'Place3',
          'Place4',
          'Place5',
          'Place6'
        ],
        'preferences': {
          'Food & Drink': ['Coffee', 'Wine'],
          'Activities': ['Hiking'],
        },
      };

      final dimensions = mapper.mapOnboardingToDimensions(onboardingData);

      // Should have some non-empty dimensions
      expect(dimensions.isNotEmpty, isTrue);

      // All values should be in valid range
      for (final value in dimensions.values) {
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('QuestionAnswer', () {
    test('should extract dimension values from choice answer', () {
      final question = OnboardingQuestionBank.discoveryQuestions[0];
      final answer = QuestionAnswer(
        question: question,
        value: 'hidden_gems',
        answeredAt: DateTime.now(),
      );

      final values = answer.dimensionValues;

      expect(values['exploration_eagerness'], equals(0.85));
    });

    test('should extract dimension values from slider answer', () {
      final question = OnboardingQuestionBank.socialQuestions[0];
      final answer = QuestionAnswer(
        question: question,
        value: 0.7,
        answeredAt: DateTime.now(),
      );

      final values = answer.dimensionValues;

      expect(values['community_orientation'], equals(0.7));
    });

    test('should extract dimension values from multi-choice answer', () {
      final question = OnboardingQuestionBank.socialQuestions[2];
      final answer = QuestionAnswer(
        question: question,
        value: ['friends_recs', 'events'],
        answeredAt: DateTime.now(),
      );

      final values = answer.dimensionValues;

      // Should have averaged values from both options
      expect(values.containsKey('social_discovery_style'), isTrue);
    });

    test('should calculate answer confidence', () {
      // Slider at extreme
      final extremeAnswer = QuestionAnswer(
        question: OnboardingQuestionBank.socialQuestions[0],
        value: 0.95,
        answeredAt: DateTime.now(),
      );

      // Slider in middle
      final middleAnswer = QuestionAnswer(
        question: OnboardingQuestionBank.socialQuestions[0],
        value: 0.5,
        answeredAt: DateTime.now(),
      );

      expect(
        extremeAnswer.answerConfidence,
        greaterThan(middleAnswer.answerConfidence),
        reason: 'Extreme slider values should indicate higher confidence',
      );
    });
  });

  group('DimensionComputationResult', () {
    test('should report completeness correctly', () {
      final incompleteResult = DimensionComputationResult(
        dimensions: {'exploration_eagerness': 0.5},
        confidence: {'exploration_eagerness': 0.3},
        sourceAnswers: [],
        computedAt: DateTime.now(),
      );

      expect(incompleteResult.isComplete, isFalse);
    });

    test('should calculate average confidence', () {
      final result = DimensionComputationResult(
        dimensions: {
          'exploration_eagerness': 0.8,
          'novelty_seeking': 0.6,
        },
        confidence: {
          'exploration_eagerness': 0.8,
          'novelty_seeking': 0.6,
        },
        sourceAnswers: [],
        computedAt: DateTime.now(),
      );

      expect(result.averageConfidence, equals(0.7));
    });
  });
}
