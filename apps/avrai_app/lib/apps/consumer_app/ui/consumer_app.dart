import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/routes/app_router.dart';
import 'package:avrai/presentation/widgets/shell/app_shell_host.dart';
import 'package:avrai/presentation/widgets/shell/immersive_scroll_behavior.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai_runtime_os/config/design_feature_flags.dart';

class SpotsApp extends StatelessWidget {
  const SpotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<SpotsBloc>(
          create: (context) => di.sl<SpotsBloc>(),
        ),
        BlocProvider<ListsBloc>(
          create: (context) => di.sl<ListsBloc>(),
        ),
      ],
      // Use a Builder to obtain a context that is below the BlocProviders
      child: Builder(
        builder: (innerContext) {
          // If DI failed to register AuthBloc (e.g., backend init failed),
          // lazily register a fallback AuthBloc to keep the app running.
          AuthBloc? authBloc;
          try {
            authBloc = BlocProvider.of<AuthBloc>(innerContext);
          } catch (_) {
            // no-op; will create a fallback below
          }
          if (authBloc == null) {
            try {
              authBloc = di.sl<AuthBloc>();
            } catch (_) {}
          }
          return MaterialApp.router(
            title: 'SPOTS',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            scrollBehavior: DesignFeatureFlags.enableImmersiveShell
                ? const ImmersiveScrollBehavior()
                : const MaterialScrollBehavior(),
            builder: (context, child) {
              final routeChild = child ?? const SizedBox.shrink();
              return AppShellHost(
                variant: DesignFeatureFlags.enableImmersiveShell
                    ? AppShellVariant.immersive
                    : AppShellVariant.standard,
                child: routeChild,
              );
            },
            routerConfig:
                AppRouter.build(authBloc: authBloc ?? di.sl<AuthBloc>()),
          );
        },
      ),
    );
  }
}
