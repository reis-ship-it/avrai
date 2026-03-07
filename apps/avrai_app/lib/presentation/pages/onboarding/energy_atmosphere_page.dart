import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/energy_atmosphere_page_schema.dart';

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
    return AppSchemaPage(
      schema: buildEnergyAtmospherePageSchema(
        progressSection: _buildProgressSection(context),
        questionSection: _buildQuestionSection(),
        navigationSection: _buildNavigationSection(),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              '${_answers.length}/${_questions.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
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
                      ? AppColors.textPrimary
                      : AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuestionSection() {
    return SizedBox(
      height: 420,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          return SingleChildScrollView(
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
    );
  }

  Widget _buildNavigationSection() {
    return Row(
      children: [
        if (_currentQuestionIndex > 0)
          AppButtonSecondary(
            onPressed: _goToPreviousQuestion,
            child: const Text('Back'),
          )
        else
          const SizedBox(width: 88),
        const Spacer(),
        if (_currentQuestionIndex < _questions.length - 1)
          AppButtonPrimary(
            onPressed: _isCurrentQuestionAnswered() ? _goToNextQuestion : null,
            child: const Text('Next'),
          ),
      ],
    );
  }
}
