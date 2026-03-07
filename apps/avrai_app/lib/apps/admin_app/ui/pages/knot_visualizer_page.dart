// Knot Visualizer Page
//
// Admin page for knot visualization and analysis
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer/knot_distribution_tab.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer/knot_pattern_analysis_tab.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer/knot_matching_tab.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer/knot_evolution_tab.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer/knot_debug_tab.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

/// Admin Knot Visualizer Page
///
/// Comprehensive knot visualization and analysis tools for admins
class KnotVisualizerPage extends StatefulWidget {
  const KnotVisualizerPage({super.key});

  @override
  State<KnotVisualizerPage> createState() => _KnotVisualizerPageState();
}

class _KnotVisualizerPageState extends State<KnotVisualizerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminAuthService? _authService;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _authService = GetIt.instance<AdminAuthService>();

      if (_authService != null) {
        setState(() {
          _isAuthorized = _authService!.isAuthenticated();
        });

        if (!_isAuthorized) {
          // Navigate to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      developer.log('Error initializing services: $e',
          name: 'KnotVisualizerPage');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const AppFlowScaffold(
        title: '',
        showNavigationBar: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppFlowScaffold(
      title: 'Knot Visualizer',
      materialBottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Distribution'),
          Tab(text: 'Patterns'),
          Tab(text: 'Matching'),
          Tab(text: 'Evolution'),
          Tab(text: 'Debug'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          KnotDistributionTab(),
          KnotPatternAnalysisTab(),
          KnotMatchingTab(),
          KnotEvolutionTab(),
          KnotDebugTab(),
        ],
      ),
    );
  }
}
