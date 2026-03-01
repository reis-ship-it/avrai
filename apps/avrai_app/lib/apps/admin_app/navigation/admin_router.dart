import 'dart:async';

import 'package:avrai/apps/admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_runtime_os/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/apps/admin_app/ui/pages/ai2ai_admin_dashboard.dart';
import 'package:avrai/apps/admin_app/ui/pages/admin_command_center_page.dart';
import 'package:avrai/apps/admin_app/ui/pages/research_center_page.dart';
import 'package:avrai/apps/admin_app/ui/pages/reality_system_oversight_page.dart';
import 'package:avrai/apps/admin_app/ui/pages/urk_kernel_console_page.dart';
import 'package:avrai/apps/admin_app/ui/widgets/admin_navigation_shell.dart';
import 'package:avrai/presentation/pages/auth/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class AdminRouter {
  static const String login = AdminRoutePaths.login;
  static const String commandCenter = AdminRoutePaths.commandCenter;
  static const String urkKernels = AdminRoutePaths.urkKernels;
  static const String ai2ai = AdminRoutePaths.ai2ai;
  static const String researchCenter = AdminRoutePaths.researchCenter;
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
            signupRoute: login,
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
              path: urkKernels,
              builder: (context, state) => UrkKernelConsolePage(
                initialDecisionId: state.uri.queryParameters['decisionId'],
                initialView: state.uri.queryParameters['view'],
              ),
            ),
            GoRoute(
              path: ai2ai,
              builder: (context, state) => const AI2AIAdminDashboard(),
            ),
            GoRoute(
              path: researchCenter,
              builder: (context, state) => const ResearchCenterPage(),
            ),
            GoRoute(
              path: realitySystemReality,
              builder: (context, state) => const RealitySystemOversightPage(
                layer: OversightLayer.reality,
              ),
            ),
            GoRoute(
              path: realitySystemUniverse,
              builder: (context, state) => const RealitySystemOversightPage(
                layer: OversightLayer.universe,
              ),
            ),
            GoRoute(
              path: realitySystemWorld,
              builder: (context, state) => const RealitySystemOversightPage(
                layer: OversightLayer.world,
              ),
            ),
          ],
        ),
      ],
    );
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
