import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/device_link/secure_bypass_service.dart';
import 'package:avrai_runtime_os/crypto/signal/device_registration_service.dart';

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
        padding: const EdgeInsets.all(24),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Lost Device Recovery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use this only if you cannot access your other devices. '
                'This is a high-security operation.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        if (_deviceCount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices, size: 24),
                const SizedBox(width: 12),
                Text(
                  '$_deviceCount device(s) will be revoked',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = BypassStep.password),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('I understand, continue'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email and password to confirm.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 32),
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
                : const Text('Verify'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a verification code to your email.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
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
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 32),
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
                : const Text('Verify Code'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resendCode,
            child: const Text('Resend Code'),
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
        const SizedBox(height: 16),
        const Text(
          'Identity Verified',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm the actions to complete recovery.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        CheckboxListTile(
          value: _revokeDevices,
          onChanged: (value) => setState(() => _revokeDevices = value!),
          title: const Text('Revoke all other devices'),
          subtitle: const Text('They won\'t receive new messages'),
        ),
        CheckboxListTile(
          value: _remoteWipe,
          onChanged: _revokeDevices
              ? (value) => setState(() => _remoteWipe = value!)
              : null,
          title: const Text('Remote wipe old devices'),
          subtitle: const Text('Delete app data on revoked devices'),
        ),
        const SizedBox(height: 32),
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
                : const Text('Complete Recovery'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.check_circle, size: 80, color: AppColors.success),
        const SizedBox(height: 24),
        const Text(
          'Recovery Complete',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This device is now your primary device.\n'
          'You can link other devices from Settings.',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Done'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: AppColors.textSecondary),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent')),
      );
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
