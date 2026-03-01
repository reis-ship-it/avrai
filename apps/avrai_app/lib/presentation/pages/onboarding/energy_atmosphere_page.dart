import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:avrai_core/models/user/dimension_question.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_question_bank.dart';
import 'package:avrai/presentation/widgets/onboarding/dimension_question_widget.dart';

/// Step 7: Energy & Atmosphere page.
///
/// Measures dimensions:
/// - energy_preference
/// - crowd_tolerance
/// - temporal_flexibility
class EnergyAtmospherePage extends StatefulWidget {
  /// Initial answers (if returning to this page)
  final List<QuestionAnswer> initialAnswers;

  /// Callback when answers change
  final ValueChanged<List<QuestionAnswer>> onAnswersChanged;

  const EnergyAtmospherePage({
    super.key,
    this.initialAnswers = const [],
    required this.onAnswersChanged,
  });

  @override
  State<EnergyAtmospherePage> createState() => _EnergyAtmospherePageState();
}

class _EnergyAtmospherePageState extends State<EnergyAtmospherePage> {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};
  final Map<String, DateTime> _answerTimes = {};

  List<DimensionQuestion> get _questions =>
      OnboardingQuestionBank.energyQuestions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Energy & Atmosphere',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "What's your ideal vibe?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(_questions.length, (index) {
              final isCompleted = _answers.containsKey(_questions[index].id);
              final isCurrent = index == _currentQuestionIndex;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                      right: index < _questions.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentQuestionIndex = index),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                TextButton.icon(
                  onPressed: _goToPreviousQuestion,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                )
              else
                const SizedBox(width: 100),
              const Spacer(),
              if (_currentQuestionIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed:
                      _isCurrentQuestionAnswered() ? _goToNextQuestion : null,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 18),
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
