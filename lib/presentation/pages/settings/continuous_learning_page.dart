import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_data_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_controls_widget.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Continuous Learning Page
///
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
///
/// Combines all 4 continuous learning widgets into a single comprehensive page:
/// 1. Learning Status Overview (status, active processes, metrics)
/// 2. Learning Progress by Dimension (progress for all 10 dimensions)
/// 3. Data Collection Status (status of all 10 data sources)
/// 4. Learning Controls (start/stop, parameters, privacy settings)
class ContinuousLearningPage extends StatefulWidget {
  /// Optional learningSystem for testing. If not provided, uses GetIt instance.
  final ContinuousLearningSystem? learningSystem;

  const ContinuousLearningPage({
    super.key,
    this.learningSystem,
  });

  @override
  State<ContinuousLearningPage> createState() => _ContinuousLearningPageState();
}

class _ContinuousLearningPageState extends State<ContinuousLearningPage> {
  ContinuousLearningSystem? _learningSystem;
  bool _isInitializing = true;
  String? _errorMessage;

  static ContinuousLearningSystem _resolveLearningSystemOrCreate() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<ContinuousLearningSystem>()) {
        return sl<ContinuousLearningSystem>();
      }
    } catch (_) {
      // Fall through.
    }
    // Test/preview fallback: allow the page to render even when DI isn't set up.
    return ContinuousLearningSystem();
  }

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

      // Use injected instance (for testing) or get from DI (for production)
      // This ensures single instance across app, not per-page
      _learningSystem =
          widget.learningSystem ?? _resolveLearningSystemOrCreate();

      // Initialize if not already initialized (idempotent operation)
      await _learningSystem!.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize continuous learning system: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // DON'T stop learning here - service is shared across app
    // Service lifecycle is managed at app level, not page level
    // Other pages/widgets may be using the same instance
    // Only stop if explicitly needed (which should be rare)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'Continuous Learning',
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

          if (_learningSystem == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: EdgeInsets.all(spacing.md),
            children: [
              // Header
              _buildHeader(context),
              SizedBox(height: spacing.lg),

              // Section 1: Learning Status Overview
              _buildSectionHeader(context, 'Learning Status Overview'),
              SizedBox(height: spacing.xs),
              Text(
                'Current learning status and system metrics',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              ContinuousLearningStatusWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              SizedBox(height: spacing.xl),

              // Section 2: Learning Progress by Dimension
              _buildSectionHeader(context, 'Learning Progress by Dimension'),
              SizedBox(height: spacing.xs),
              Text(
                'Track progress across all 10 learning dimensions',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              ContinuousLearningProgressWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              SizedBox(height: spacing.xl),

              // Section 3: Data Collection Status
              _buildSectionHeader(context, 'Data Collection Status'),
              SizedBox(height: spacing.xs),
              Text(
                'Monitor data collection from all 10 sources',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              ContinuousLearningDataWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              SizedBox(height: spacing.xl),

              // Section 4: Learning Controls
              _buildSectionHeader(context, 'Learning Controls'),
              SizedBox(height: spacing.xs),
              Text(
                'Start, stop, and configure continuous learning',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              ContinuousLearningControlsWidget(
                userId: userId,
                learningSystem: _learningSystem!,
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
              Icons.auto_awesome,
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
                  'Continuous Learning',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  'See how your AI continuously learns',
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
            'Continuous learning enables your AI to learn from everything and improve itself '
            'every second. Your AI learns from your actions, location data, weather conditions, '
            'time patterns, social connections, and more. All learning happens on your device '
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
