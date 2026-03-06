import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

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
    final newResponses = {
      'coffee': _coffeeController.text.trim(),
      'clear_head': _clearHeadController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'about_me': _aboutController.text.trim(),
    };
    widget.onResponsesChanged(newResponses);
  }

  Widget _buildQuestionField(String question, TextEditingController controller,
      {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type here or skip...',
              hintStyle: const TextStyle(color: AppColors.grey500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are you?',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We use these answers entirely locally to seed your AI\'s understanding of your personality. Nothing you type here leaves your device.',
            style:
                theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 24),
          AppSurface(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionField(
                      "What's your favorite place to get coffee?",
                      _coffeeController),
                  _buildQuestionField("Where do you go to clear your head?",
                      _clearHeadController),
                  _buildQuestionField(
                      "What's a hobby you wish you had more time for?",
                      _hobbyController),
                  _buildQuestionField(
                      "Tell us a bit about you.", _aboutController,
                      maxLines: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
