import 'dart:async';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/device_link/numeric_code_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Device Link Code Page
///
/// Displays a numeric pairing code for linking a new device.
/// Shows countdown timer and handles code usage.
///
/// Phase 26: Multi-Device Sync - Pairing Code Display
class DeviceLinkCodePage extends StatefulWidget {
  const DeviceLinkCodePage({super.key});

  @override
  State<DeviceLinkCodePage> createState() => _DeviceLinkCodePageState();
}

class _DeviceLinkCodePageState extends State<DeviceLinkCodePage> {
  final NumericCodeService _codeService = GetIt.I<NumericCodeService>();

  PairingCode? _pairingCode;
  bool _isGenerating = true;
  String? _error;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeService.cancelCode();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final code = await _codeService.generateCode();
      setState(() {
        _pairingCode = code;
        _remainingTime = code.remainingTime;
        _isGenerating = false;
      });

      _startCountdown();
      _waitForUsage();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _pairingCode?.remainingTime ?? Duration.zero;
      setState(() => _remainingTime = remaining);

      if (remaining <= Duration.zero) {
        timer.cancel();
        setState(() => _error = 'Code expired');
      }
    });
  }

  Future<void> _waitForUsage() async {
    final secret = await _codeService.waitForCodeUsage();
    if (secret != null && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/device-link/transfer',
        arguments: secret,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Link New Device',
      constrainBody: false,
      body: Padding(
        padding: const EdgeInsets.all(kSpaceLg),
        child: _isGenerating
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildCodeDisplay(),
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.devices_other,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Enter this code on your new device',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildCodeBox(),
        const SizedBox(height: 16),
        _buildCountdown(),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _copyCode,
          icon: const Icon(Icons.copy),
          label: Text('Copy Code'),
        ),
        const SizedBox(height: 48),
        Text(
          'Waiting for new device to enter code...',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _buildCodeBox() {
    final code = _pairingCode?.formattedCode ?? '---';
    final digits = code.replaceAll('-', '').split('');

    return PortalSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpaceLg, vertical: kSpaceMdWide),
      color: AppColors.surface,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      radius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < digits.length; i++) ...[
            if (i > 0 && i % 3 == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSpaceXs),
                child: Text(
                  '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            SizedBox(
              width: 36,
              height: 48,
              child: PortalSurface(
                color: AppColors.background,
                borderColor: AppColors.grey300.withValues(alpha: 0.5),
                radius: 8,
                child: Center(
                  child: Text(
                    digits[i],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final isLow = _remainingTime.inSeconds < 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.timer,
          size: 20,
          color: isLow ? AppColors.error : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          'Expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLow ? AppColors.error : AppColors.textSecondary,
                fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateCode,
            child: Text('Generate New Code'),
          ),
        ],
      ),
    );
  }

  void _copyCode() {
    if (_pairingCode != null) {
      Clipboard.setData(ClipboardData(text: _pairingCode!.code));
      context.showSuccess('Code copied to clipboard');
    }
  }
}
