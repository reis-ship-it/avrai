import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/auth/login_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Simplified AuthWrapper - only triggers auth check and shows loading states
/// All navigation decisions are handled by the router redirect function
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading while checking auth state
        if (state is AuthInitial || state is AuthLoading) {
          return const AdaptivePlatformPageScaffold(
            title: 'Loading',
            showNavigationBar: false,
            constrainBody: false,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show login page for unauthenticated users
        // The router redirect will handle navigation to /login if needed
        if (state is Unauthenticated) {
          return const LoginPage();
        }

        // For authenticated users, show loading
        // The router redirect will handle navigation to /home or /onboarding
        if (state is Authenticated) {
          return const AdaptivePlatformPageScaffold(
            title: 'Loading',
            showNavigationBar: false,
            constrainBody: false,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error state - show login page
        if (state is AuthError) {
          return const LoginPage();
        }

        // Fallback
        return const AdaptivePlatformPageScaffold(
          title: 'Loading',
          showNavigationBar: false,
          constrainBody: false,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
