import 'package:flutter/material.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/pages/chat/agent_chat_view.dart';
import 'package:avrai/presentation/services/metro_experience_service.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class WorldModelAiPage extends StatefulWidget {
  const WorldModelAiPage({super.key});

  @override
  State<WorldModelAiPage> createState() => _WorldModelAiPageState();
}

class _WorldModelAiPageState extends State<WorldModelAiPage> {
  late final MetroExperienceService _metroExperienceService =
      MetroExperienceService(
    geoHierarchyService: di.sl<GeoHierarchyService>(),
    prefs: di.sl<SharedPreferencesCompat>(),
  );

  MetroExperienceContext? _metroContext;
  String? _draftPrompt;

  @override
  void initState() {
    super.initState();
    _loadMetroContext();
  }

  Future<void> _loadMetroContext() async {
    final metroContext = await _metroExperienceService.resolveBestEffort();
    if (!mounted) {
      return;
    }

    setState(() {
      _metroContext = metroContext;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metroContext = _metroContext;
    final prompts = metroContext?.promptSuggestions ??
        const [
          'What fits me nearby right now?',
          'Why is this a match for me?',
          'What community would suit me?',
          'Remember this about me',
        ];

    return AdaptivePlatformPageScaffold(
      title: 'AI',
      constrainBody: false,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.grey200,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talk with your world model',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  metroContext?.hasMetroProfile == true
                      ? 'Use chat to understand what fits you in ${metroContext!.displayName}, why something matches your city rhythm, and what your agent should learn from how you actually move through the city.'
                      : 'Use chat to understand what fits you nearby, why something is a match, and what your agent should learn from your real behavior.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best for',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick guidance, fit explanations, and teaching your agent what matters to you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Not for hidden app actions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This page is for conversation and learning, not silent background commands.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (metroContext != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${metroContext.displayName}: ${metroContext.summary}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: prompts
                      .map(
                        (prompt) => _PromptChip(
                          label: prompt,
                          onTap: () {
                            setState(() {
                              _draftPrompt = prompt;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chat helps your AI learn faster, but the app should still improve from your real-world behavior, not chat alone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AgentChatView(
              draftMessage: _draftPrompt,
              onDraftConsumed: () {
                if (mounted && _draftPrompt != null) {
                  setState(() {
                    _draftPrompt = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
