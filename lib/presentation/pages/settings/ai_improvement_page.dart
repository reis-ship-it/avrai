import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// AI Improvement Page
///
/// Phase 7, Week 37: AI Self-Improvement Visibility - Integration & Polish
///
/// Combines all 4 AI improvement widgets into a single comprehensive page:
/// 1. AIImprovementSection (main metrics)
/// 2. AIImprovementProgressWidget (progress charts)
/// 3. AIImprovementTimelineWidget (history timeline)
/// 4. AIImprovementImpactWidget (impact explanation)
class AIImprovementPage extends StatefulWidget {
  const AIImprovementPage({super.key});

  @override
  State<AIImprovementPage> createState() => _AIImprovementPageState();
}

class _AIImprovementPageState extends State<AIImprovementPage> {
  AIImprovementTrackingService? _trackingService;
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

      // Use dependency injection instead of direct instantiation
      final service = GetIt.instance<AIImprovementTrackingService>();
      await service.initialize();

      if (mounted) {
        setState(() {
          _trackingService = service;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize AI improvement tracking: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _trackingService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'AI Improvement',
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

          if (_trackingService == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            key: const Key('ai_improvement_page_list'),
            padding: EdgeInsets.all(spacing.md),
            children: [
              // Header
              _buildHeader(context),
              SizedBox(height: spacing.lg),

              // Section 1: Main Metrics
              _buildSectionHeader(context, 'AI Improvement Metrics'),
              SizedBox(height: spacing.xs),
              Text(
                'See how your AI is improving over time',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AIImprovementSection(
                userId: userId,
                trackingService: _trackingService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 2: Progress Charts
              _buildSectionHeader(context, 'Improvement Progress'),
              SizedBox(height: spacing.xs),
              Text(
                'Track improvement trends over time',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AIImprovementProgressWidget(
                userId: userId,
                trackingService: _trackingService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 3: Timeline
              _buildSectionHeader(context, 'Improvement History'),
              SizedBox(height: spacing.xs),
              Text(
                'Timeline of AI improvements and milestones',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AIImprovementTimelineWidget(
                userId: userId,
                trackingService: _trackingService!,
              ),
              SizedBox(height: spacing.xl),

              // Section 4: Impact
              _buildSectionHeader(context, 'Impact & Benefits'),
              SizedBox(height: spacing.xs),
              Text(
                'How AI improvements benefit your experience',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              AIImprovementImpactWidget(
                userId: userId,
                trackingService: _trackingService!,
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
              Icons.trending_up,
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
                  'AI Self-Improvement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  'Watch your AI learn and improve over time',
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
            'Your AI continuously learns and improves from your interactions. '
            'This page shows you how your AI is evolving, including improvements '
            'in recommendation accuracy, understanding your preferences, and '
            'adapting to your unique style. All learning happens on your device '
            'to protect your privacy.',
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
