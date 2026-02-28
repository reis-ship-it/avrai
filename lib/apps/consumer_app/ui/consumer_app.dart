import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/routes/app_router.dart';
import 'package:avrai/presentation/pages/bootloader_page.dart';
import 'package:avrai/presentation/widgets/portal/avrai_portal_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_scroll_physics.dart';
import 'package:avrai/injection_container.dart' as di;

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
            scrollBehavior: const PortalScrollBehavior(),
            builder: (context, child) {
              final routeChild = child ?? const SizedBox.shrink();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return BootloaderPage(
                child: AvraiPortalLayout(
                  isDark: isDark,
                  child: ColoredBox(
                    color: AppColors.transparent,
                    child: routeChild,
                  ),
                ),
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
