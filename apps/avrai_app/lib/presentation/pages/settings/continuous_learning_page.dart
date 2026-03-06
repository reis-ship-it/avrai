import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_error_state.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_loading_state.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_controls_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_data_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/continuous_learning_status_widget.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';

class ContinuousLearningPage extends StatefulWidget {
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
    } catch (_) {}
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

      _learningSystem =
          widget.learningSystem ?? _resolveLearningSystemOrCreate();
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
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Continuous Learning',
      constrainBody: false,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const AppLoadingState(label: 'Loading continuous learning');
          }

          final userId = authState.user.id;

          if (_isInitializing) {
            return const AppLoadingState(label: 'Loading continuous learning');
          }

          if (_errorMessage != null) {
            return AppErrorState(
              title: 'Unable to load continuous learning',
              body: _errorMessage!,
              onRetry: _initializeService,
            );
          }

          if (_learningSystem == null) {
            return const AppLoadingState(label: 'Loading continuous learning');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSurface(
                child: const AppPageHeader(
                  title: 'Continuous Learning',
                  subtitle:
                      'Monitor how your AI learns across status, progress, data collection, and controls.',
                  leadingIcon: Icons.auto_awesome_outlined,
                  showDivider: false,
                ),
              ),
              const SizedBox(height: 24),
              _DashboardSection(
                title: 'Learning Status Overview',
                subtitle: 'Current learning status and system metrics.',
                child: ContinuousLearningStatusWidget(
                  userId: userId,
                  learningSystem: _learningSystem!,
                ),
              ),
              const SizedBox(height: 24),
              _DashboardSection(
                title: 'Learning Progress by Dimension',
                subtitle: 'Track progress across all learning dimensions.',
                child: ContinuousLearningProgressWidget(
                  userId: userId,
                  learningSystem: _learningSystem!,
                ),
              ),
              const SizedBox(height: 24),
              _DashboardSection(
                title: 'Data Collection Status',
                subtitle: 'Monitor collection from each enabled source.',
                child: ContinuousLearningDataWidget(
                  userId: userId,
                  learningSystem: _learningSystem!,
                ),
              ),
              const SizedBox(height: 24),
              _DashboardSection(
                title: 'Learning Controls',
                subtitle: 'Start, stop, and configure continuous learning.',
                child: ContinuousLearningControlsWidget(
                  userId: userId,
                  learningSystem: _learningSystem!,
                ),
              ),
              const SizedBox(height: 24),
              const AppInfoBanner(
                title: 'Learn more',
                body:
                    'Continuous learning uses local activity and configured signals to improve recommendations while preserving user control.',
                icon: Icons.info_outline,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DashboardSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSection(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}
