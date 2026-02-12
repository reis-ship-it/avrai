import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/ai2ai/personality_overview_card.dart';
import 'package:avrai/presentation/widgets/ai2ai/user_connections_display.dart';
import 'package:avrai/presentation/widgets/ai2ai/learning_insights_widget.dart';
import 'package:avrai/presentation/widgets/ai2ai/evolution_timeline_widget.dart';
import 'package:avrai/presentation/widgets/ai2ai/privacy_controls_widget.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;

/// User-facing AI Personality Status Page
/// Shows user's AI personality overview, connections, learning insights, evolution timeline, and privacy controls
class AIPersonalityStatusPage extends StatefulWidget {
  const AIPersonalityStatusPage({super.key});

  @override
  State<AIPersonalityStatusPage> createState() =>
      _AIPersonalityStatusPageState();
}

class _AIPersonalityStatusPageState extends State<AIPersonalityStatusPage> {
  PersonalityProfile? _personalityProfile;
  ActiveConnectionsOverview? _connectionsOverview;
  List<SharedInsight>? _recentInsights;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalityData();
  }

  Future<void> _loadPersonalityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userId = authState.user.id;

        // Try to get existing personality profile.
        // In a real implementation, we'd load from storage or get from a service.
        // Phase 8.3: Use agentId for privacy protection
        final agentId = 'agent_$userId';
        _personalityProfile =
            PersonalityProfile.initial(agentId, userId: userId);

        // Get connections overview - ConnectionMonitor expects SharedPreferencesCompat
        final sharedPrefs = GetIt.instance<SharedPreferencesCompat>();
        final connectionMonitor = ConnectionMonitor(prefs: sharedPrefs);
        _connectionsOverview =
            await connectionMonitor.getActiveConnectionsOverview();

        // Recent learning insights would come from chat history + AI2AIChatAnalyzer.
        // This page currently renders a placeholder until that data source is wired up.
        _recentInsights = [];
      }
    } catch (e) {
      developer.log('Error loading personality data',
          name: 'AIPersonalityStatusPage', error: e);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadPersonalityData();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return AdaptivePlatformPageScaffold(
      title: 'AI Personality Status',
      backgroundColor: AppTheme.primaryColor,
      actions: [
        IconButton(
          color: AppColors.white,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshData,
          tooltip: 'Refresh',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_personalityProfile != null)
                      PersonalityOverviewCard(profile: _personalityProfile!),
                    SizedBox(height: spacing.lg),
                    if (_connectionsOverview != null)
                      UserConnectionsDisplay(overview: _connectionsOverview!),
                    SizedBox(height: spacing.lg),
                    LearningInsightsWidget(insights: _recentInsights ?? []),
                    SizedBox(height: spacing.lg),
                    if (_personalityProfile != null)
                      EvolutionTimelineWidget(profile: _personalityProfile!),
                    SizedBox(height: spacing.lg),
                    const PrivacyControlsWidget(),
                  ],
                ),
              ),
            ),
    );
  }
}
