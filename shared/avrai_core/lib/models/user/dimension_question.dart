import 'package:equatable/equatable.dart';

/// Type of question UI to display
enum QuestionType {
  /// Slider with continuous value from 0.0 to 1.0
  slider,

  /// Single choice from multiple options
  choice,

  /// Multiple choices allowed (up to maxSelections)
  multiChoice,
}

/// A question designed to measure one or more personality dimensions
class DimensionQuestion extends Equatable {
  /// Unique identifier for this question
  final String id;

  /// The question prompt to display to the user
  final String prompt;

  /// Optional subtitle/description for additional context
  final String? subtitle;

  /// Type of question UI
  final QuestionType type;

  /// Which dimensions this question impacts and with what weight
  final List<DimensionImpact> impacts;

  /// Options for choice/multiChoice questions
  final List<QuestionOption>? options;

  /// Configuration for slider questions
  final SliderConfig? sliderConfig;

  /// Maximum selections allowed for multiChoice (defaults to 2)
  final int maxSelections;

  const DimensionQuestion({
    required this.id,
    required this.prompt,
    this.subtitle,
    required this.type,
    required this.impacts,
    this.options,
    this.sliderConfig,
    this.maxSelections = 2,
  });

  @override
  List<Object?> get props => [id, prompt, type, impacts, options, sliderConfig];
}

/// Defines how a question impacts a specific dimension
class DimensionImpact extends Equatable {
  /// The dimension name (e.g., 'exploration_eagerness')
  final String dimension;

  /// How much this question affects the dimension (0.0-1.0)
  /// Higher weight means this question is more authoritative for this dimension
  final double weight;

  const DimensionImpact({
    required this.dimension,
    this.weight = 1.0,
  });

  @override
  List<Object?> get props => [dimension, weight];
}

/// An option for choice/multiChoice questions
class QuestionOption extends Equatable {
  /// Unique identifier for this option
  final String id;

  /// Display label for the option
  final String label;

  /// Optional description shown below the label
  final String? description;

  /// Direct dimension values when this option is selected
  /// Key: dimension name, Value: dimension value (0.0-1.0)
  final Map<String, double> dimensionValues;

  /// Optional icon to display with the option
  final int? icon;

  const QuestionOption({
    required this.id,
    required this.label,
    this.description,
    required this.dimensionValues,
    this.icon,
  });

  @override
  List<Object?> get props => [id, label, dimensionValues];
}

/// Configuration for slider-type questions
class SliderConfig extends Equatable {
  /// Label shown at the low end (0.0) of the slider
  final String lowLabel;

  /// Label shown at the high end (1.0) of the slider
  final String highLabel;

  /// Default starting value (typically 0.5)
  final double defaultValue;

  /// Optional intermediate stops with labels
  final List<SliderStop>? stops;

  /// Optional icons for low and high ends
  final int? lowIcon;
  final int? highIcon;

  const SliderConfig({
    required this.lowLabel,
    required this.highLabel,
    this.defaultValue = 0.5,
    this.stops,
    this.lowIcon,
    this.highIcon,
  });

  @override
  List<Object?> get props => [lowLabel, highLabel, defaultValue, stops];
}

/// An intermediate stop on a slider with a label
class SliderStop extends Equatable {
  /// Position on the slider (0.0-1.0)
  final double value;

  /// Label to display at this position
  final String label;

  const SliderStop({
    required this.value,
    required this.label,
  });

  @override
  List<Object?> get props => [value, label];
}

/// A user's answer to a dimension question
class QuestionAnswer extends Equatable {
  /// The question that was answered
  final DimensionQuestion question;

  /// The answer value:
  /// - For slider: double (0.0-1.0)
  /// - For choice: String (option id)
  /// - For multiChoice: list of String (list of option ids)
  final dynamic value;

  /// When the answer was recorded
  final DateTime answeredAt;

  /// How long the user spent on this question (for confidence calculation)
  final Duration? thinkingTime;

  const QuestionAnswer({
    required this.question,
    required this.value,
    required this.answeredAt,
    this.thinkingTime,
  });

  /// Extract dimension values from this answer
  Map<String, double> get dimensionValues {
    switch (question.type) {
      case QuestionType.slider:
        // For slider, the value is directly the dimension value
        return {
          for (final impact in question.impacts)
            impact.dimension: value as double
        };

      case QuestionType.choice:
        // For choice, find the selected option and return its dimension values
        final selectedId = value as String;
        final option = question.options?.firstWhere(
          (o) => o.id == selectedId,
          orElse: () => throw StateError('Option not found: $selectedId'),
        );
        return option?.dimensionValues ?? {};

      case QuestionType.multiChoice:
        // For multi-choice, merge dimension values from all selected options
        final selectedIds = value as List<String>;
        final merged = <String, double>{};
        final counts = <String, int>{};

        for (final id in selectedIds) {
          final option = question.options?.firstWhere(
            (o) => o.id == id,
            orElse: () => throw StateError('Option not found: $id'),
          );
          if (option != null) {
            option.dimensionValues.forEach((dim, val) {
              merged[dim] = (merged[dim] ?? 0.0) + val;
              counts[dim] = (counts[dim] ?? 0) + 1;
            });
          }
        }

        // Average the values
        merged.forEach((dim, totalVal) {
          merged[dim] = totalVal / counts[dim]!;
        });

        return merged;
    }
  }

  /// Calculate confidence based on answer clarity
  /// Slider values near extremes = higher confidence
  /// Quick answers = potentially lower confidence
  double get answerConfidence {
    double confidence = 0.7; // Base confidence

    if (question.type == QuestionType.slider) {
      final sliderValue = value as double;
      // Values near extremes indicate clearer preference
      final clarity =
          (sliderValue - 0.5).abs() * 2; // 0.0 at middle, 1.0 at extremes
      confidence += clarity * 0.2;
    }

    // Very quick answers might indicate less thought
    if (thinkingTime != null && thinkingTime!.inSeconds < 2) {
      confidence -= 0.1;
    }

    return confidence.clamp(0.3, 0.95);
  }

  @override
  List<Object?> get props => [question.id, value, answeredAt];
}

/// Result of dimension computation from onboarding answers
class DimensionComputationResult extends Equatable {
  /// Computed dimension values (all 12 dimensions)
  final Map<String, double> dimensions;

  /// Confidence level per dimension
  final Map<String, double> confidence;

  /// Source answers used for computation
  final List<QuestionAnswer> sourceAnswers;

  /// When the computation was performed
  final DateTime computedAt;

  const DimensionComputationResult({
    required this.dimensions,
    required this.confidence,
    required this.sourceAnswers,
    required this.computedAt,
  });

  /// Check if all 12 dimensions have non-default values
  bool get isComplete {
    return dimensions.length >= 12 && dimensions.values.every((v) => v != 0.5);
  }

  /// Average confidence across all dimensions
  double get averageConfidence {
    if (confidence.isEmpty) return 0.0;
    return confidence.values.reduce((a, b) => a + b) / confidence.length;
  }

  @override
  List<Object?> get props => [dimensions, confidence, computedAt];
}
