import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/open_intake_page_schema.dart';

class OpenIntakePage extends StatefulWidget {
  final Map<String, String> openResponses;
  final Function(Map<String, String>) onResponsesChanged;

  const OpenIntakePage({
    super.key,
    required this.openResponses,
    required this.onResponsesChanged,
  });

  @override
  State<OpenIntakePage> createState() => _OpenIntakePageState();
}

class _OpenIntakePageState extends State<OpenIntakePage> {
  late final TextEditingController _coffeeController;
  late final TextEditingController _clearHeadController;
  late final TextEditingController _hobbyController;
  late final TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _coffeeController =
        TextEditingController(text: widget.openResponses['coffee'] ?? '');
    _clearHeadController =
        TextEditingController(text: widget.openResponses['clear_head'] ?? '');
    _hobbyController =
        TextEditingController(text: widget.openResponses['hobby'] ?? '');
    _aboutController =
        TextEditingController(text: widget.openResponses['about_me'] ?? '');

    _coffeeController.addListener(_updateResponses);
    _clearHeadController.addListener(_updateResponses);
    _hobbyController.addListener(_updateResponses);
    _aboutController.addListener(_updateResponses);
  }

  @override
  void dispose() {
    _coffeeController.removeListener(_updateResponses);
    _clearHeadController.removeListener(_updateResponses);
    _hobbyController.removeListener(_updateResponses);
    _aboutController.removeListener(_updateResponses);

    _coffeeController.dispose();
    _clearHeadController.dispose();
    _hobbyController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _updateResponses() {
    widget.onResponsesChanged({
      'coffee': _coffeeController.text.trim(),
      'clear_head': _clearHeadController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'about_me': _aboutController.text.trim(),
    });
  }

  Widget _buildQuestionField(
    String question,
    TextEditingController controller, {
    int maxLines = 2,
  }) {
    return AppSurface(
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Type here or skip',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildOpenIntakePageSchema(
        questionsSection: _buildQuestionsSection(),
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      children: [
        _buildQuestionField(
          "What's your favorite place to get coffee?",
          _coffeeController,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'Where do you go to clear your head?',
          _clearHeadController,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          "What's a hobby you wish you had more time for?",
          _hobbyController,
        ),
        const SizedBox(height: 16),
        _buildQuestionField(
          'Tell us a bit about you.',
          _aboutController,
          maxLines: 4,
        ),
      ],
    );
  }
}
