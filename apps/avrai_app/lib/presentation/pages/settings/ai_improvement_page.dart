import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_error_state.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_loading_state.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/ai_improvement_page_schema.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_improvement_tracking_service.dart';

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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return AppSchemaPage(
            schema: buildAIImprovementPageSchema(
              content: const AppLoadingState(label: 'Loading AI improvement'),
            ),
          );
        }

        final userId = authState.user.id;

        if (_isInitializing) {
          return AppSchemaPage(
            schema: buildAIImprovementPageSchema(
              content: const AppLoadingState(label: 'Loading AI improvement'),
            ),
          );
        }

        if (_errorMessage != null) {
          return AppSchemaPage(
            schema: buildAIImprovementPageSchema(
              content: AppErrorState(
                title: 'Unable to load AI improvement',
                body: _errorMessage!,
                onRetry: _initializeService,
              ),
            ),
          );
        }

        if (_trackingService == null) {
          return AppSchemaPage(
            schema: buildAIImprovementPageSchema(
              content: const AppLoadingState(label: 'Loading AI improvement'),
            ),
          );
        }

        return AppSchemaPage(
          schema: buildAIImprovementPageSchema(
            content: _buildContent(userId),
          ),
          scrollable: false,
        );
      },
    );
  }

  Widget _buildContent(String userId) {
    return ListView(
      key: const Key('ai_improvement_page_list'),
      padding: const EdgeInsets.all(16),
      children: [
        _DashboardSection(
          title: 'AI Improvement Metrics',
          subtitle: 'See how your AI is improving over time.',
          child: AIImprovementSection(
            userId: userId,
            trackingService: _trackingService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Improvement Progress',
          subtitle: 'Track improvement trends over time.',
          child: AIImprovementProgressWidget(
            userId: userId,
            trackingService: _trackingService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Improvement History',
          subtitle: 'Timeline of AI improvements and milestones.',
          child: AIImprovementTimelineWidget(
            userId: userId,
            trackingService: _trackingService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Impact & Benefits',
          subtitle: 'How ongoing improvements affect your experience.',
          child: AIImprovementImpactWidget(
            userId: userId,
            trackingService: _trackingService!,
          ),
        ),
        const SizedBox(height: 24),
        const AppInfoBanner(
          title: 'Learn more',
          body:
              'Improvements focus on recommendation quality, preference understanding, and adaptation while keeping learning local whenever possible.',
          icon: Icons.info_outline,
        ),
      ],
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
