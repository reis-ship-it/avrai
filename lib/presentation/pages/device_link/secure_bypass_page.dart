import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/device_link/secure_bypass_service.dart';
import 'package:avrai/core/crypto/signal/device_registration_service.dart';

/// Secure Bypass Page
///
/// Handles device linking when old device is unavailable
/// (lost, stolen, or broken).
///
/// Phase 26: Multi-Device Sync - Secure Bypass UI
class SecureBypassPage extends StatefulWidget {
  const SecureBypassPage({super.key});

  @override
  State<SecureBypassPage> createState() => _SecureBypassPageState();
}

class _SecureBypassPageState extends State<SecureBypassPage> {
  final SecureBypassService _bypassService = GetIt.I<SecureBypassService>();
  final DeviceRegistrationService _deviceService =
      GetIt.I<DeviceRegistrationService>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  BypassStep _currentStep = BypassStep.warning;
  BypassRequest? _bypassRequest;
  bool _isLoading = false;
  String? _error;
  bool _revokeDevices = true;
  bool _remoteWipe = false;
  int _deviceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceCount();
  }

  Future<void> _loadDeviceCount() async {
    final devices = _deviceService.getOtherDevices();
    setState(() => _deviceCount = devices.length);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Account Recovery',
      constrainBody: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.spacing.xl),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case BypassStep.warning:
        return _buildWarningStep();
      case BypassStep.password:
        return _buildPasswordStep();
      case BypassStep.verification:
        return _buildVerificationStep();
      case BypassStep.confirmation:
        return _buildConfirmationStep();
      case BypassStep.complete:
        return _buildCompleteStep();
    }
  }

  Widget _buildWarningStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalSurface(
          padding: EdgeInsets.all(context.spacing.lg),
          color: AppColors.error.withValues(alpha: 0.1),
          borderColor: AppColors.error.withValues(alpha: 0.3),
          radius: context.radius.md,
          child: Column(
            children: [
              const Icon(Icons.warning_amber, size: 48, color: AppColors.error),
              SizedBox(height: context.spacing.md),
              Text(
                'Lost Device Recovery',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                'Use this only if you cannot access your other devices. '
                'This is a high-security operation.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.xl),
        _buildInfoCard(
          icon: Icons.lock,
          title: 'What happens:',
          items: [
            'You\'ll need to verify your identity',
            'Other devices will be revoked',
            'New messages won\'t decrypt on old devices',
            'This device becomes your primary device',
          ],
        ),
        SizedBox(height: context.spacing.xl),
        if (_deviceCount > 0)
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.md),
            color: AppColors.surface,
            borderColor: AppColors.grey300,
            radius: context.radius.sm,
            child: Row(
              children: [
                const Icon(Icons.devices, size: 24),
                SizedBox(width: context.spacing.sm),
                Text(
                  '$_deviceCount device(s) will be revoked',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        SizedBox(height: context.spacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = BypassStep.password),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('I understand, continue'),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Identity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Enter your email and password to confirm.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.spacing.xxl),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        SizedBox(height: context.spacing.md),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: context.spacing.md),
          Text(
            _error!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ],
        SizedBox(height: context.spacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Verify'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Verification',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'We\'ve sent a verification code to your email.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.spacing.xxl),
        TextField(
          controller: _verificationCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            prefixIcon: Icon(Icons.pin),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: context.spacing.md),
          Text(
            _error!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ],
        SizedBox(height: context.spacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Verify Code'),
          ),
        ),
        SizedBox(height: context.spacing.md),
        Center(
          child: TextButton(
            onPressed: _resendCode,
            child: Text('Resend Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user, size: 48, color: AppColors.success),
        SizedBox(height: context.spacing.md),
        Text(
          'Identity Verified',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Confirm the actions to complete recovery.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.spacing.xxl),
        CheckboxListTile(
          value: _revokeDevices,
          onChanged: (value) => setState(() => _revokeDevices = value!),
          title: Text('Revoke all other devices'),
          subtitle: Text('They won\'t receive new messages'),
        ),
        CheckboxListTile(
          value: _remoteWipe,
          onChanged: _revokeDevices
              ? (value) => setState(() => _remoteWipe = value!)
              : null,
          title: Text('Remote wipe old devices'),
          subtitle: Text('Delete app data on revoked devices'),
        ),
        SizedBox(height: context.spacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completeBypass,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Complete Recovery'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: context.spacing.xxl),
        const Icon(Icons.check_circle, size: 80, color: AppColors.success),
        SizedBox(height: context.spacing.xl),
        Text(
          'Recovery Complete',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: context.spacing.md),
        Text(
          'This device is now your primary device.\n'
          'You can link other devices from Settings.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.spacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              SizedBox(width: context.spacing.xs),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: context.spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPassword() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initiate bypass
      final currentDevice = _deviceService.currentDevice;
      _bypassRequest = await _bypassService.initiateBypass(
        userId: currentDevice?.userId ?? '',
        reason: 'Lost device recovery',
      );

      // Verify password
      final success = await _bypassService.verifyPassword(
        email: _emailController.text,
        password: _passwordController.text,
        bypassRequestId: _bypassRequest!.requestId,
      );

      if (success) {
        // Send email verification
        await _bypassService.requestEmailVerification(_emailController.text);
        setState(() => _currentStep = BypassStep.verification);
      } else {
        setState(() => _error = 'Invalid email or password');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _bypassService.verifyEmailCode(
        email: _emailController.text,
        code: _verificationCodeController.text,
        bypassRequestId: _bypassRequest!.requestId,
      );

      if (success) {
        setState(() => _currentStep = BypassStep.confirmation);
      } else {
        setState(() => _error = 'Invalid verification code');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    await _bypassService.requestEmailVerification(_emailController.text);
    if (mounted) {
      context.showInfo('Verification code sent');
    }
  }

  Future<void> _completeBypass() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _bypassService.completeBypass(
        bypassRequestId: _bypassRequest!.requestId,
        revokeOtherDevices: _revokeDevices,
        triggerRemoteWipe: _remoteWipe,
      );

      if (result.success) {
        setState(() => _currentStep = BypassStep.complete);
      } else {
        setState(() => _error = result.error ?? 'Recovery failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

enum BypassStep {
  warning,
  password,
  verification,
  confirmation,
  complete,
}
