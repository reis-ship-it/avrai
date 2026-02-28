import 'dart:async';

import 'package:avrai/core/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/admin/ai2ai_admin_dashboard.dart';
import 'package:avrai/presentation/pages/admin/urk_kernel_console_page.dart';
import 'package:avrai/presentation/pages/auth/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class AdminRouter {
  static const String login = '/login';
  static const String urkKernels = '/admin/urk-kernels';
  static const String ai2ai = '/admin/ai2ai';

  static GoRouter build({required AuthBloc authBloc}) {
    return GoRouter(
      initialLocation: urkKernels,
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
          return urkKernels;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginPage(
            postAuthRoute: urkKernels,
            signupRoute: login,
            requireInternalUseAgreement: true,
            internalUseAgreementText:
                'I agree this admin application is for internal use only and restricted to authorized operators.',
          ),
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
