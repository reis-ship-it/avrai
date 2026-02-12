import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_data_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_controls_widget.dart';
import 'package:avrai/core/theme/colors.dart';
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
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
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),

              // Section 1: Learning Status Overview
              _buildSectionHeader(context, 'Learning Status Overview'),
              const SizedBox(height: 8),
              const Text(
                'Current learning status and system metrics',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningStatusWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),

              // Section 2: Learning Progress by Dimension
              _buildSectionHeader(context, 'Learning Progress by Dimension'),
              const SizedBox(height: 8),
              const Text(
                'Track progress across all 10 learning dimensions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningProgressWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),

              // Section 3: Data Collection Status
              _buildSectionHeader(context, 'Data Collection Status'),
              const SizedBox(height: 8),
              const Text(
                'Monitor data collection from all 10 sources',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningDataWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 32),

              // Section 4: Learning Controls
              _buildSectionHeader(context, 'Learning Controls'),
              const SizedBox(height: 8),
              const Text(
                'Start, stop, and configure continuous learning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ContinuousLearningControlsWidget(
                userId: userId,
                learningSystem: _learningSystem!,
              ),
              const SizedBox(height: 24),

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continuous Learning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'See how your AI continuously learns',
                  style: TextStyle(
                    fontSize: 14,
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return const PortalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Learn More',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Continuous learning enables your AI to learn from everything and improve itself '
            'every second. Your AI learns from your actions, location data, weather conditions, '
            'time patterns, social connections, and more. All learning happens on your device '
            'to protect your privacy.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.shield,
                color: AppColors.success,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Your data stays on your device',
                style: TextStyle(
                  fontSize: 13,
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
