import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai2ai_learning_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// AI2AI Learning Methods Page
///
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
///
/// Combines all 4 AI2AI learning widgets into a single comprehensive page:
/// 1. Learning Methods Overview (active methods, status, effectiveness)
/// 2. Learning Effectiveness Metrics (metrics, insights count, acquisition rate)
/// 3. Active Learning Insights (recent insights, cross-personality, patterns)
/// 4. Learning Recommendations (optimal partners, topics, development areas)
class AI2AILearningMethodsPage extends StatefulWidget {
  const AI2AILearningMethodsPage({super.key});

  @override
  State<AI2AILearningMethodsPage> createState() =>
      _AI2AILearningMethodsPageState();
}

class _AI2AILearningMethodsPageState extends State<AI2AILearningMethodsPage> {
  AI2AILearning? _learningService;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Get service from dependency injection
      final service = di.sl<AI2AILearning>();

      if (mounted) {
        setState(() {
          _learningService = service;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize AI2AI learning: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'AI2AI Learning Methods',
      constrainBody: false,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userId = authState.user.id;

          if (_isInitializing) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    SizedBox(height: spacing.md),
                    Text(
                      'Error',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    ElevatedButton(
                      onPressed: _initializeService,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_learningService == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            key: const Key('ai2ai_learning_methods_page_list'),
            padding: EdgeInsets.all(spacing.md),
            children: [
              // Header
              _buildHeader(context),
              SizedBox(height: spacing.lg),

              // Section 1: Learning Methods Overview
              _buildSectionHeader(context, 'Learning Methods Overview'),
              SizedBox(height: spacing.xs),
              Text(
                'See how your AI learns from other AIs',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AI2AILearningMethodsWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 2: Learning Effectiveness
              _buildSectionHeader(context, 'Learning Effectiveness Metrics'),
              SizedBox(height: spacing.xs),
              Text(
                'Track how effectively your AI is learning',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AI2AILearningEffectivenessWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 3: Learning Insights
              _buildSectionHeader(context, 'Active Learning Insights'),
              SizedBox(height: spacing.xs),
              Text(
                'Recent insights from AI2AI interactions',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AI2AILearningInsightsWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 4: Learning Recommendations
              _buildSectionHeader(context, 'Learning Recommendations'),
              SizedBox(height: spacing.xs),
              Text(
                'Optimal learning partners and development areas',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AI2AILearningRecommendationsWidget(
                userId: userId,
                learningService: _learningService!,
              ),
              SizedBox(height: spacing.lg),

              // Footer
              _buildFooter(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PortalSurface(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderColor: AppColors.primary.withValues(alpha: 0.24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(
              Icons.psychology,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI2AI Learning Methods',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  'See how your AI learns from other AIs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: spacing.xs),
              Text(
                'Learn More',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            'AI2AI learning enables your AI to learn from interactions with other AIs '
            'through secure, privacy-preserving connections. Your AI discovers new '
            'personality insights, learns from cross-personality patterns, and evolves '
            'through collective intelligence. All learning happens on your device to '
            'protect your privacy.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.success,
                size: 16,
              ),
              SizedBox(width: spacing.xxs),
              Text(
                'Your data stays on your device',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
