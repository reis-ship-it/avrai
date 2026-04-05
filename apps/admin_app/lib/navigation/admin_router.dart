import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_runtime_os/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_admin_app/auth/auth_bloc.dart';
import 'package:avrai_admin_app/ui/pages/ai2ai_admin_dashboard.dart';
import 'package:avrai_admin_app/ui/pages/admin_command_center_page.dart';
import 'package:avrai_admin_app/ui/pages/beta_feedback_viewer_page.dart';
import 'package:avrai_admin_app/ui/pages/clubs_communities_viewer_page.dart';
import 'package:avrai_admin_app/ui/pages/communications_viewer_page.dart';
import 'package:avrai_admin_app/ui/pages/connection_communication_detail_page.dart';
import 'package:avrai_admin_app/ui/pages/governance_audit_page.dart';
import 'package:avrai_admin_app/ui/pages/launch_safety_page.dart';
import 'package:avrai_admin_app/ui/pages/kernel_graph_run_detail_page.dart';
import 'package:avrai_admin_app/ui/pages/moderation_operations_page.dart';
import 'package:avrai_admin_app/ui/pages/research_center_page.dart';
import 'package:avrai_admin_app/ui/pages/reality_system_oversight_page.dart';
import 'package:avrai_admin_app/ui/pages/security_immune_system_page.dart';
import 'package:avrai_admin_app/ui/pages/signature_source_health_page.dart';
import 'package:avrai_admin_app/ui/pages/world_simulation_lab_page.dart';
import 'package:avrai_admin_app/ui/pages/world_model_ai_page.dart';
import 'package:avrai_admin_app/ui/pages/club_detail_page.dart';
import 'package:avrai_admin_app/ui/pages/urk_kernel_console_page.dart';
import 'package:avrai_admin_app/ui/pages/user_detail_page.dart';
import 'package:avrai_admin_app/ui/widgets/admin_navigation_shell.dart';
import 'package:avrai_admin_app/ui/pages/auth/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class AdminRouter {
  static const String login = AdminRoutePaths.login;
  static const String commandCenter = AdminRoutePaths.commandCenter;
  static const String governanceAudit = AdminRoutePaths.governanceAudit;
  static const String urkKernels = AdminRoutePaths.urkKernels;
  static const String ai2ai = AdminRoutePaths.ai2ai;
  static const String securityImmuneSystem =
      AdminRoutePaths.securityImmuneSystem;
  static const String signatureHealth = AdminRoutePaths.signatureHealth;
  static const String researchCenter = AdminRoutePaths.researchCenter;
  static const String worldSimulationLab = AdminRoutePaths.worldSimulationLab;
  static const String realitySystemReality =
      AdminRoutePaths.realitySystemReality;
  static const String realitySystemUniverse =
      AdminRoutePaths.realitySystemUniverse;
  static const String realitySystemWorld = AdminRoutePaths.realitySystemWorld;

  static GoRouter build({required AuthBloc authBloc}) {
    return GoRouter(
      initialLocation: commandCenter,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) async {
        final authState = authBloc.state;
        final isLogin = state.matchedLocation == login;

        if (authState is! Authenticated) {
          return isLogin ? null : login;
        }

        if (authState.user.role != UserRole.admin) {
          return login;
        }

        final prefs = await SharedPreferencesCompat.getInstance();
        final agreementService = AdminInternalUseAgreementService(
          prefs: prefs,
          supabaseService: SupabaseService(),
        );
        final verified = await agreementService.verifyCurrentSessionAgreement();
        if (!verified) {
          return isLogin ? null : login;
        }

        if (!await _isApprovedAdminDevice()) {
          return isLogin ? null : login;
        }

        if (isLogin) {
          return commandCenter;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginPage(
            postAuthRoute: commandCenter,
            requireInternalUseAgreement: true,
            internalUseAgreementText:
                'I agree this admin application is for internal use only and restricted to authorized operators.',
          ),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AdminNavigationShell(
              currentLocation: state.matchedLocation,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: commandCenter,
              builder: (context, state) => const AdminCommandCenterPage(),
            ),
            GoRoute(
              path: governanceAudit,
              builder: (context, state) => GovernanceAuditPage(
                initialRuntimeId: state.uri.queryParameters['runtimeId'],
                initialStratum: state.uri.queryParameters['stratum'],
                initialArtifactType: state.uri.queryParameters['artifact'],
              ),
            ),
            GoRoute(
              path: urkKernels,
              builder: (context, state) => UrkKernelConsolePage(
                initialDecisionId: state.uri.queryParameters['decisionId'],
                initialView: state.uri.queryParameters['view'],
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: ai2ai,
              builder: (context, state) => AI2AIAdminDashboard(
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: AdminRoutePaths.communications,
              builder: (context, state) => const CommunicationsViewerPage(),
            ),
            GoRoute(
              path: AdminRoutePaths.moderation,
              builder: (context, state) => const ModerationOperationsPage(),
            ),
            GoRoute(
              path: AdminRoutePaths.explorer,
              builder: (context, state) => const ClubsCommunitiesViewerPage(),
            ),
            GoRoute(
              path: AdminRoutePaths.betaFeedback,
              builder: (context, state) => const BetaFeedbackViewerPage(),
            ),
            GoRoute(
              path: AdminRoutePaths.launchSafety,
              builder: (context, state) => LaunchSafetyPage(
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: securityImmuneSystem,
              builder: (context, state) => const SecurityImmuneSystemPage(),
            ),
            GoRoute(
              path: signatureHealth,
              builder: (context, state) => SignatureSourceHealthPage(
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: AdminRoutePaths.kernelGraphRunDetailPattern,
              builder: (context, state) => KernelGraphRunDetailPage(
                runId: state.pathParameters['id'] ?? 'unknown_run',
              ),
            ),
            GoRoute(
              path: researchCenter,
              builder: (context, state) => ResearchCenterPage(
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: worldSimulationLab,
              builder: (context, state) => WorldSimulationLabPage(
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: AdminRoutePaths.worldModel,
              builder: (context, state) => const WorldModelAiPage(),
            ),
            GoRoute(
              path: realitySystemReality,
              builder: (context, state) => RealitySystemOversightPage(
                layer: OversightLayer.reality,
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: realitySystemUniverse,
              builder: (context, state) => RealitySystemOversightPage(
                layer: OversightLayer.universe,
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: realitySystemWorld,
              builder: (context, state) => RealitySystemOversightPage(
                layer: OversightLayer.world,
                initialFocus: state.uri.queryParameters['focus'],
                initialAttention: state.uri.queryParameters['attention'],
              ),
            ),
            GoRoute(
              path: '/admin/user/:id',
              builder: (context, state) => UserDetailPage(
                userId: state.pathParameters['id'] ?? 'unknown_user',
              ),
            ),
            GoRoute(
              path: '/admin/communication/:id',
              builder: (context, state) => ConnectionCommunicationDetailPage(
                connectionId:
                    state.pathParameters['id'] ?? 'unknown_connection',
              ),
            ),
            GoRoute(
              path: '/admin/club/:id',
              builder: (context, state) => ClubDetailPage(
                clubCommunityId: state.pathParameters['id'] ?? 'unknown_club',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Future<bool> _isApprovedAdminDevice() async {
    final service = DeviceCapabilityService();
    final caps = await service.getCapabilities();
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => caps.platform,
    };
    if (platform != 'macos' && platform != 'windows' && platform != 'linux') {
      return false;
    }
    if (caps.isLowPowerMode) {
      return false;
    }
    if (caps.totalRamMb != null && caps.totalRamMb! < 4096) {
      return false;
    }
    return true;
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
