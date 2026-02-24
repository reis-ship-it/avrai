import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

class MinimalFeedbackSubmission {
  const MinimalFeedbackSubmission({
    required this.positive,
    this.rating,
    this.freeText,
  });

  final bool positive;
  final double? rating;
  final String? freeText;
}

/// Phase 1.4.3 minimal-friction feedback UI contract.
class MinimalFeedbackPrompt extends StatefulWidget {
  const MinimalFeedbackPrompt({
    super.key,
    this.promptText = 'Was this recommendation helpful?',
    required this.onQuickFeedback,
    this.onDetailedFeedback,
  });

  final String promptText;
  final ValueChanged<bool> onQuickFeedback;
  final ValueChanged<MinimalFeedbackSubmission>? onDetailedFeedback;

  @override
  State<MinimalFeedbackPrompt> createState() => _MinimalFeedbackPromptState();
}

class _MinimalFeedbackPromptState extends State<MinimalFeedbackPrompt> {
  bool _expanded = false;
  bool _lastQuickPositive = true;
  double _rating = 3.0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.promptText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('feedback_thumbs_up'),
                  onPressed: () {
                    _lastQuickPositive = true;
                    widget.onQuickFeedback(true);
                  },
                  icon: const Icon(
                    Icons.thumb_up_outlined,
                    color: AppColors.electricGreen,
                  ),
                  label: const Text('Helpful'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('feedback_thumbs_down'),
                  onPressed: () {
                    _lastQuickPositive = false;
                    widget.onQuickFeedback(false);
                  },
                  icon: const Icon(
                    Icons.thumb_down_outlined,
                    color: AppTheme.warningColor,
                  ),
                  label: const Text('Not Helpful'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('feedback_toggle_details'),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Text(_expanded ? 'Hide details' : 'Add details (optional)'),
          ),
          if (_expanded) ...[
            const SizedBox(height: 6),
            const Text(
              'How would you rate it?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              key: const Key('feedback_rating_slider'),
              min: 1,
              max: 5,
              divisions: 4,
              value: _rating,
              label: _rating.toStringAsFixed(0),
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            TextField(
              key: const Key('feedback_notes_field'),
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Optional notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('feedback_submit_detailed'),
                onPressed: widget.onDetailedFeedback == null
                    ? null
                    : () {
                        widget.onDetailedFeedback!(
                          MinimalFeedbackSubmission(
                            positive: _lastQuickPositive,
                            rating: _rating,
                            freeText: _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                          ),
                        );
                      },
                child: const Text('Send detailed feedback'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
