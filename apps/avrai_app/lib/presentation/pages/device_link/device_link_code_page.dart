import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/device_link/numeric_code_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

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
        padding: const EdgeInsets.all(24),
        child: _isGenerating
            ? const Center(child: CircularProgressIndicator())
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
        const Text(
          'Enter this code on your new device',
          style: TextStyle(fontSize: 18),
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
          label: const Text('Copy Code'),
        ),
        const SizedBox(height: 48),
        Text(
          'Waiting for new device to enter code...',
          style: TextStyle(color: AppColors.textSecondary),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < digits.length; i++) ...[
            if (i > 0 && i % 3 == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  digits[i],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
          style: TextStyle(
            fontSize: 16,
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
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateCode,
            child: const Text('Generate New Code'),
          ),
        ],
      ),
    );
  }

  void _copyCode() {
    if (_pairingCode != null) {
      Clipboard.setData(ClipboardData(text: _pairingCode!.code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied to clipboard')),
      );
    }
  }
}
