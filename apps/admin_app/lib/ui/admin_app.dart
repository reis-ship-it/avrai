import 'package:avrai_admin_app/auth/auth_bloc.dart';
import 'package:avrai_admin_app/navigation/admin_router.dart';
import 'package:avrai_admin_app/theme/app_theme.dart';
import 'package:avrai_admin_app/ui/widgets/common/immersive_scroll_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc.fromGetIt()..add(AuthCheckRequested()),
      child: Builder(
        builder: (innerContext) {
          final authBloc = BlocProvider.of<AuthBloc>(innerContext);
          return MaterialApp.router(
            title: 'AVRAI Admin',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const ImmersiveScrollBehavior(),
            routerConfig: AdminRouter.build(authBloc: authBloc),
          );
        },
      ),
    );
  }
}
