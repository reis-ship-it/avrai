import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/device_link/numeric_code_service.dart';

/// Device Link Enter Code Page
///
/// Allows entering a pairing code on a new device.
///
/// Phase 26: Multi-Device Sync - Pairing Code Entry
class DeviceLinkEnterCodePage extends StatefulWidget {
  const DeviceLinkEnterCodePage({super.key});

  @override
  State<DeviceLinkEnterCodePage> createState() =>
      _DeviceLinkEnterCodePageState();
}

class _DeviceLinkEnterCodePageState extends State<DeviceLinkEnterCodePage> {
  final NumericCodeService _codeService = GetIt.I<NumericCodeService>();
  final List<TextEditingController> _controllers =
      List.generate(9, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(9, (_) => FocusNode());

  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Enter Pairing Code',
      constrainBody: false,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pin,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter the 9-digit code from your other device',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildCodeInput(),
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
                onPressed:
                    _code.length == 9 && !_isVerifying ? _verifyCode : null,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Verify Code'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _pasteCode,
              child: const Text('Paste from Clipboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 9; i++) ...[
          if (i == 3 || i == 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          SizedBox(
            width: 36,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) {
                if (value.isNotEmpty && i < 8) {
                  _focusNodes[i + 1].requestFocus();
                }
                setState(() => _error = null);
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final request = await _codeService.verifyCode(_code);

      if (request == null) {
        setState(() {
          _error = 'Invalid or expired code';
          _isVerifying = false;
        });
        return;
      }

      // Complete pairing
      final secret = await _codeService.completePairing(request);

      if (secret != null && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/device-link/transfer',
          arguments: secret,
        );
      } else {
        setState(() {
          _error = 'Pairing failed. Please try again.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isVerifying = false;
      });
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final digits = data!.text!.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < digits.length && i < 9; i++) {
        _controllers[i].text = digits[i];
      }
      setState(() {});
    }
  }
}
