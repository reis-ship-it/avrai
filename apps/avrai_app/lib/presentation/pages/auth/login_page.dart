// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/pages/auth/forgot_password_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.postAuthRoute = AppRouter.home,
    this.signupRoute = AppRouter.signup,
    this.requireInternalUseAgreement = false,
    this.internalUseAgreementText =
        'I agree this admin application is for internal use only.',
  });

  final String postAuthRoute;
  final String signupRoute;
  final bool requireInternalUseAgreement;
  final String internalUseAgreementText;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _acceptedInternalUseAgreement = false;
  String? _errorMessage;

  bool get _supportsAppleSignIn =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null && mounted) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Sign In',
      showNavigationBar: false,
      constrainBody: false,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            final router = GoRouter.maybeOf(context);
            router?.go(widget.postAuthRoute);
          } else if (state is OAuthCancelledState) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _errorMessage = state.message;
              });
            }
          } else if (state is AuthError) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _errorMessage = state.message;
              });
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48)
                    .clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo/Title
                      const Icon(
                        Icons.location_on,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'avrai',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover meaningful places',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                      const SizedBox(height: 48),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isBusy =
                              state is AuthLoading || state is OAuthInProgress;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                key: const Key('google_sign_in_button'),
                                onPressed: isBusy ? null : _handleGoogleSignIn,
                                child: const Text('Continue with Google'),
                              ),
                              if (_supportsAppleSignIn) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  key: const Key('apple_sign_in_button'),
                                  onPressed: isBusy ? null : _handleAppleSignIn,
                                  child: const Text('Continue with Apple'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.grey300)),
                          Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'or continue with email',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.grey600),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.grey300)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      TextFormField(
                        key: const Key('email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        key: const Key('password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      if (widget.requireInternalUseAgreement) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedInternalUseAgreement,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedInternalUseAgreement =
                                      value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  widget.internalUseAgreementText,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Login Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state is AuthLoading || _isSubmitting;
                          final requiresAgreement =
                              widget.requireInternalUseAgreement &&
                                  !_acceptedInternalUseAgreement;
                          return ElevatedButton(
                            onPressed: (isLoading || requiresAgreement)
                                ? null
                                : _handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    ),
                                  )
                                : const Text('Sign In'),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              final router = GoRouter.maybeOf(context);
                              router?.go(widget.signupRoute);
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_isSubmitting) return;
    if (widget.requireInternalUseAgreement && !_acceptedInternalUseAgreement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept internal-use terms to continue.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      context.read<AuthBloc>().add(
            SignInRequested(
              _emailController.text.trim(),
              _passwordController.text,
              requireAdminInternalUseAgreement:
                  widget.requireInternalUseAgreement,
              adminInternalUseAgreementAccepted: _acceptedInternalUseAgreement,
              adminInternalUseAgreementText: widget.internalUseAgreementText,
            ),
          );
    }
  }

  void _handleGoogleSignIn() {
    if (_isSubmitting) return;
    setState(() {
      _errorMessage = null;
    });
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  void _handleAppleSignIn() {
    if (_isSubmitting) return;
    setState(() {
      _errorMessage = null;
    });
    context.read<AuthBloc>().add(AppleSignInRequested());
  }
}
