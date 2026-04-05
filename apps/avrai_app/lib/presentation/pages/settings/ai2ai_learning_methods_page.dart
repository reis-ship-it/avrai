import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_error_state.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_loading_state.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/ai2ai_learning_methods_page_schema.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:avrai/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_learning_service.dart';

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
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return AppSchemaPage(
            schema: buildAI2AILearningMethodsPageSchema(
              content: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userId = authState.user.id;

        if (_isInitializing) {
          return AppSchemaPage(
            schema: buildAI2AILearningMethodsPageSchema(
              content: const AppLoadingState(label: 'Loading AI2AI learning'),
            ),
          );
        }

        if (_errorMessage != null) {
          return AppSchemaPage(
            schema: buildAI2AILearningMethodsPageSchema(
              content: AppErrorState(
                title: 'Unable to load AI2AI learning',
                body: _errorMessage!,
                onRetry: _initializeService,
              ),
            ),
          );
        }

        if (_learningService == null) {
          return AppSchemaPage(
            schema: buildAI2AILearningMethodsPageSchema(
              content: const AppLoadingState(label: 'Loading AI2AI learning'),
            ),
          );
        }

        return AppSchemaPage(
          schema: buildAI2AILearningMethodsPageSchema(
            content: _buildContent(userId),
          ),
          bodyScrollKey: const Key('ai2ai_learning_methods_page_scroll'),
        );
      },
    );
  }

  Widget _buildContent(String userId) {
    return Padding(
      key: const Key('ai2ai_learning_methods_page_content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardSection(
          title: 'Learning Methods Overview',
          subtitle: 'See how your AI learns from other AIs.',
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: _learningService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Learning Effectiveness Metrics',
          subtitle: 'Track how effectively your AI is learning.',
          child: AI2AILearningEffectivenessWidget(
            userId: userId,
            learningService: _learningService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Active Learning Insights',
          subtitle: 'Recent insights from AI2AI interactions.',
          child: AI2AILearningInsightsWidget(
            userId: userId,
            learningService: _learningService!,
          ),
        ),
        const SizedBox(height: 24),
        _DashboardSection(
          title: 'Learning Recommendations',
          subtitle: 'Suggested partners and development areas.',
          child: AI2AILearningRecommendationsWidget(
            userId: userId,
            learningService: _learningService!,
          ),
        ),
        const SizedBox(height: 24),
        const AppInfoBanner(
          title: 'Learn more',
          body:
              'AI2AI learning uses secure, anonymized exchanges to strengthen recommendations without sharing raw personal content.',
          icon: Icons.info_outline,
        ),
      ],
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
