import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:avrai/core/models/user/dimension_question.dart';
import 'package:avrai/core/services/onboarding/onboarding_question_bank.dart';
import 'package:avrai/presentation/widgets/onboarding/dimension_question_widget.dart';

/// Step 6: Social Vibe page.
///
/// Measures dimensions:
/// - community_orientation
/// - trust_network_reliance
/// - social_discovery_style
class SocialVibePage extends StatefulWidget {
  /// Initial answers (if returning to this page)
  final List<QuestionAnswer> initialAnswers;

  /// Callback when answers change
  final ValueChanged<List<QuestionAnswer>> onAnswersChanged;

  const SocialVibePage({
    super.key,
    this.initialAnswers = const [],
    required this.onAnswersChanged,
  });

  @override
  State<SocialVibePage> createState() => _SocialVibePageState();
}

class _SocialVibePageState extends State<SocialVibePage> {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};
  final Map<String, DateTime> _answerTimes = {};

  List<DimensionQuestion> get _questions =>
      OnboardingQuestionBank.socialQuestions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Restore initial answers
    for (final answer in widget.initialAnswers) {
      _answers[answer.question.id] = answer.value;
      _answerTimes[answer.question.id] = answer.answeredAt;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onAnswerChanged(DimensionQuestion question, dynamic value) {
    setState(() {
      _answers[question.id] = value;
      _answerTimes[question.id] = DateTime.now();
    });
    _emitAnswers();
  }

  void _emitAnswers() {
    final answers = <QuestionAnswer>[];
    for (final question in _questions) {
      final value = _answers[question.id];
      if (value != null) {
        answers.add(QuestionAnswer(
          question: question,
          value: value,
          answeredAt: _answerTimes[question.id] ?? DateTime.now(),
        ));
      }
    }
    widget.onAnswersChanged(answers);
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isCurrentQuestionAnswered() {
    final question = _questions[_currentQuestionIndex];
    final answer = _answers[question.id];
    if (answer == null) return false;
    if (question.type == QuestionType.multiChoice) {
      return (answer as List).isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.only(
              left: spacing.lg, right: spacing.lg, top: spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Social Vibe',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                'How do you like to connect with others?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.md),

        // Progress indicator
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Row(
            children: List.generate(_questions.length, (index) {
              final isCompleted = _answers.containsKey(_questions[index].id);
              final isCurrent = index == _currentQuestionIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right:
                        index < _questions.length - 1 ? spacing.xs : kSpaceNone,
                  ),
                  child: SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: ColoredBox(
                        color: isCompleted || isCurrent
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: spacing.lg),

        // Questions PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentQuestionIndex = index),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: DimensionQuestionWidget(
                  question: question,
                  currentValue: _answers[question.id],
                  onAnswerChanged: (value) => _onAnswerChanged(question, value),
                  questionNumber: index + 1,
                  totalQuestions: _questions.length,
                ),
              );
            },
          ),
        ),

        // Navigation
        Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                TextButton.icon(
                  onPressed: _goToPreviousQuestion,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                )
              else
                SizedBox(width: spacing.xxl + spacing.lg),
              const Spacer(),
              if (_currentQuestionIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed:
                      _isCurrentQuestionAnswered() ? _goToNextQuestion : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Next'),
                      SizedBox(width: spacing.xxs),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
