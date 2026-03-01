import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/apps/admin_app/navigation/admin_router.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/portal/avrai_portal_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
      child: Builder(
        builder: (innerContext) {
          final authBloc = BlocProvider.of<AuthBloc>(innerContext);
          return MaterialApp.router(
            title: 'AVRAI Admin',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const PortalScrollBehavior(),
            builder: (context, child) {
              final routeChild = child ?? const SizedBox.shrink();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return AvraiPortalLayout(
                isDark: isDark,
                child: ColoredBox(
                  color: AppColors.transparent,
                  child: routeChild,
                ),
              );
            },
            routerConfig: AdminRouter.build(authBloc: authBloc),
          );
        },
      ),
    );
  }
}
