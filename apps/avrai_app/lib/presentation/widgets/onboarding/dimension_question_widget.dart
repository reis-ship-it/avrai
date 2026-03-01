import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:avrai_core/models/user/dimension_question.dart';

/// Reusable widget for displaying a single dimension question.
///
/// Supports slider, choice, and multi-choice question types.
class DimensionQuestionWidget extends StatefulWidget {
  /// The question to display
  final DimensionQuestion question;

  /// Current answer value (null if not answered)
  final dynamic currentValue;

  /// Callback when answer changes
  final ValueChanged<dynamic> onAnswerChanged;

  /// Question number (for display)
  final int questionNumber;

  /// Total questions in this step
  final int totalQuestions;

  const DimensionQuestionWidget({
    super.key,
    required this.question,
    required this.currentValue,
    required this.onAnswerChanged,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  State<DimensionQuestionWidget> createState() =>
      _DimensionQuestionWidgetState();
}

class _DimensionQuestionWidgetState extends State<DimensionQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number indicator
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Question ${widget.questionNumber} of ${widget.totalQuestions}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question prompt
        Text(
          widget.question.prompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        if (widget.question.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.question.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Question content based on type
        _buildQuestionContent(context),
      ],
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    switch (widget.question.type) {
      case QuestionType.slider:
        return _buildSliderQuestion(context);
      case QuestionType.choice:
        return _buildChoiceQuestion(context);
      case QuestionType.multiChoice:
        return _buildMultiChoiceQuestion(context);
    }
  }

  Widget _buildSliderQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final config = widget.question.sliderConfig!;
    final currentValue =
        (widget.currentValue as double?) ?? config.defaultValue;

    return Column(
      children: [
        // Slider with labels
        Row(
          children: [
            if (config.lowIcon != null)
              Icon(IconData(config.lowIcon!, fontFamily: 'MaterialIcons'),
                  color: AppColors.textSecondary),
            Expanded(
              child: Slider(
                value: currentValue,
                onChanged: (value) {
                  widget.onAnswerChanged(value);
                },
                min: 0.0,
                max: 1.0,
                divisions: 100,
              ),
            ),
            if (config.highIcon != null)
              Icon(IconData(config.highIcon!, fontFamily: 'MaterialIcons'),
                  color: AppColors.textSecondary),
          ],
        ),

        // Low/High labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  config.lowLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: currentValue < 0.4
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: currentValue < 0.4
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Text(
                  config.highLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: currentValue > 0.6
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: currentValue > 0.6
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Stops (if defined)
        if (config.stops != null && config.stops!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: config.stops!.map((stop) {
              final isSelected = (currentValue - stop.value).abs() < 0.1;
              return GestureDetector(
                onTap: () => widget.onAnswerChanged(stop.value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey300,
                    ),
                  ),
                  child: Text(
                    stop.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildChoiceQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = widget.currentValue as String?;

    return RadioGroup<String>(
      groupValue: selectedId ?? '',
      onChanged: (value) => widget.onAnswerChanged(value),
      child: Column(
        children: widget.question.options!.map((option) {
          final isSelected = option.id == selectedId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => widget.onAnswerChanged(option.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.grey300.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconData(option.icon!, fontFamily: 'MaterialIcons'),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              // Explicit color so text stays readable even if the
                              // app theme is dark while the option background is light.
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (option.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              option.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: option.id,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultiChoiceQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds = (widget.currentValue as List<String>?) ?? [];
    final maxSelections = widget.question.maxSelections;

    return Column(
      children: widget.question.options!.map((option) {
        final isSelected = selectedIds.contains(option.id);
        final isMaxReached = selectedIds.length >= maxSelections && !isSelected;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: isMaxReached
                ? null
                : () {
                    final newSelection = List<String>.from(selectedIds);
                    if (isSelected) {
                      newSelection.remove(option.id);
                    } else {
                      newSelection.add(option.id);
                    }
                    widget.onAnswerChanged(newSelection);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: isMaxReached ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.grey300.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconData(option.icon!, fontFamily: 'MaterialIcons'),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        option.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: isMaxReached
                          ? null
                          : (value) {
                              final newSelection =
                                  List<String>.from(selectedIds);
                              if (value == true) {
                                newSelection.add(option.id);
                              } else {
                                newSelection.remove(option.id);
                              }
                              widget.onAnswerChanged(newSelection);
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
