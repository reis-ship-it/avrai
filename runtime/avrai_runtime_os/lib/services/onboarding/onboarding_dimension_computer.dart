import 'dart:developer' as developer;

import 'package:avrai_core/models/user/dimension_question.dart';
import 'package:avrai_core/utils/vibe_constants.dart';

/// Computes personality dimensions from onboarding question answers.
///
/// This service takes all answered questions and computes the final values
/// for all 12 avrai personality dimensions, along with confidence scores.
class OnboardingDimensionComputer {
  static const String _logName = 'OnboardingDimensionComputer';

  /// Compute all 12 dimensions from the provided answers.
  ///
  /// Returns a [DimensionComputationResult] containing:
  /// - dimensions: Map of dimension name to value (0.0-1.0)
  /// - confidence: Map of dimension name to confidence (0.0-1.0)
  DimensionComputationResult computeDimensions(List<QuestionAnswer> answers) {
    final dimensions = <String, double>{};
    final weights = <String, double>{};
    final confidence = <String, double>{};
    final dimensionAnswerCounts = <String, int>{};

    // Initialize all dimensions with default value
    for (final dim in VibeConstants.coreDimensions) {
      dimensions[dim] = VibeConstants.defaultDimensionValue;
      weights[dim] = 0.0;
      confidence[dim] = 0.3; // Minimum confidence
      dimensionAnswerCounts[dim] = 0;
    }

    // Process each answer
    for (final answer in answers) {
      final dimensionValues = answer.dimensionValues;

      for (final impact in answer.question.impacts) {
        final dim = impact.dimension;
        final value = dimensionValues[dim];

        if (value == null) continue;

        final weight = impact.weight;
        final currentWeight = weights[dim]!;
        final newWeight = currentWeight + weight;

        // Weighted average calculation
        dimensions[dim] =
            (dimensions[dim]! * currentWeight + value * weight) / newWeight;
        weights[dim] = newWeight;
        dimensionAnswerCounts[dim] = dimensionAnswerCounts[dim]! + 1;

        // Update confidence based on answer
        _updateConfidence(
          confidence,
          dim,
          answer,
          dimensionAnswerCounts[dim]!,
        );
      }

      // Handle secondary dimension values (from multi-choice options)
      for (final entry in dimensionValues.entries) {
        final dim = entry.key;
        final value = entry.value;

        // Skip if already processed as primary impact
        if (answer.question.impacts.any((i) => i.dimension == dim)) continue;

        // Check if this is a valid dimension
        if (!VibeConstants.coreDimensions.contains(dim)) continue;

        final secondaryWeight = 0.3; // Lower weight for secondary dimensions
        final currentWeight = weights[dim]!;
        final newWeight = currentWeight + secondaryWeight;

        dimensions[dim] =
            (dimensions[dim]! * currentWeight + value * secondaryWeight) /
                newWeight;
        weights[dim] = newWeight;
      }
    }

    // Clamp all values to valid range
    dimensions.forEach((key, value) {
      dimensions[key] = value.clamp(0.0, 1.0);
    });

    // Log computation result
    _logResult(dimensions, confidence, answers.length);

    return DimensionComputationResult(
      dimensions: dimensions,
      confidence: confidence,
      sourceAnswers: answers,
      computedAt: DateTime.now(),
    );
  }

  /// Update confidence for a dimension based on an answer
  void _updateConfidence(
    Map<String, double> confidence,
    String dimension,
    QuestionAnswer answer,
    int questionCount,
  ) {
    // Base confidence boost per question
    final baseBoost = 0.15 *
        (answer.question.impacts
            .firstWhere(
              (i) => i.dimension == dimension,
              orElse: () => const DimensionImpact(dimension: '', weight: 0.5),
            )
            .weight);

    confidence[dimension] = confidence[dimension]! + baseBoost;

    // Bonus for clear answers (slider not in the middle)
    if (answer.question.type == QuestionType.slider) {
      final sliderValue = answer.value as double;
      final clarity =
          (sliderValue - 0.5).abs() * 2; // 0.0 at middle, 1.0 at extremes
      confidence[dimension] = confidence[dimension]! + (0.1 * clarity);
    }

    // Bonus for multiple questions measuring the same dimension
    if (questionCount > 1) {
      confidence[dimension] = confidence[dimension]! + 0.05;
    }

    // Clamp confidence
    confidence[dimension] = confidence[dimension]!.clamp(0.3, 0.95);
  }

  /// Validate that all 12 dimensions have been measured
  bool validateCompleteness(DimensionComputationResult result) {
    final missingDimensions = <String>[];

    for (final dim in VibeConstants.coreDimensions) {
      if (!result.dimensions.containsKey(dim)) {
        missingDimensions.add(dim);
      } else if (result.dimensions[dim] == 0.5 &&
          result.confidence[dim]! < 0.4) {
        // Default value with low confidence = not actually measured
        developer.log(
          'Dimension $dim has default value with low confidence',
          name: _logName,
        );
      }
    }

    if (missingDimensions.isNotEmpty) {
      developer.log(
        'Missing dimensions: $missingDimensions',
        name: _logName,
        level: 900, // Warning
      );
      return false;
    }

    return true;
  }

  /// Log the computation result for debugging
  void _logResult(
    Map<String, double> dimensions,
    Map<String, double> confidence,
    int answerCount,
  ) {
    developer.log(
      'Computed ${dimensions.length} dimensions from $answerCount answers',
      name: _logName,
    );

    // Log each dimension
    for (final dim in VibeConstants.coreDimensions) {
      final value = dimensions[dim] ?? 0.5;
      final conf = confidence[dim] ?? 0.3;
      final bar = _generateBar(value);
      developer.log(
        '  $dim: $bar ${value.toStringAsFixed(2)} (conf: ${conf.toStringAsFixed(2)})',
        name: _logName,
      );
    }
  }

  /// Generate a visual bar for dimension value
  String _generateBar(double value) {
    const width = 20;
    final filled = (value * width).round();
    final empty = width - filled;
    return '[${'+' * filled}${'-' * empty}]';
  }

  /// Compute dimensions from answers grouped by step
  DimensionComputationResult computeFromStepAnswers({
    required List<QuestionAnswer> discoveryAnswers,
    required List<QuestionAnswer> socialAnswers,
    required List<QuestionAnswer> energyAnswers,
    required List<QuestionAnswer> valuesAnswers,
  }) {
    final allAnswers = [
      ...discoveryAnswers,
      ...socialAnswers,
      ...energyAnswers,
      ...valuesAnswers,
    ];

    return computeDimensions(allAnswers);
  }

  /// Get dimensions that are still at default value (not measured)
  List<String> getUnmeasuredDimensions(DimensionComputationResult result) {
    return VibeConstants.coreDimensions.where((dim) {
      final value = result.dimensions[dim];
      final conf = result.confidence[dim] ?? 0.0;
      // Consider unmeasured if at default value with low confidence
      return value == 0.5 && conf < 0.4;
    }).toList();
  }
}
