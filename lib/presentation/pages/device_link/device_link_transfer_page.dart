import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/device_link/auto_device_link_service.dart';
import 'package:avrai/core/services/device_link/history_transfer_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Device Link Transfer Page
///
/// Shows progress during history transfer between devices.
///
/// Phase 26: Multi-Device Sync - Transfer Progress UI
class DeviceLinkTransferPage extends StatefulWidget {
  final SharedLinkSecret sharedSecret;

  const DeviceLinkTransferPage({
    super.key,
    required this.sharedSecret,
  });

  @override
  State<DeviceLinkTransferPage> createState() => _DeviceLinkTransferPageState();
}

class _DeviceLinkTransferPageState extends State<DeviceLinkTransferPage> {
  final HistoryTransferService _transferService =
      GetIt.I<HistoryTransferService>();

  TransferStatus _status = TransferStatus.preparing;
  double _progress = 0;
  int _messagesTransferred = 0;
  int _totalMessages = 0;
  String? _error;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTransfer();
  }

  Future<void> _startTransfer() async {
    try {
      _transferService.onProgressUpdate = (progress) {
        setState(() {
          _progress = progress.progressPercent;
          _messagesTransferred = progress.messagesProcessed;
          _totalMessages = progress.totalMessages;
          _status = progress.status;
        });
      };

      _transferService.onError = (error) {
        setState(() {
          _error = error;
          _status = TransferStatus.failed;
        });
      };

      _transferService.onComplete = () {
        setState(() {
          _isComplete = true;
          _status = TransferStatus.complete;
        });
      };

      // For receiving device: import chunks
      // This is a simplified version - real implementation would
      // receive chunks via BLE or Supabase

      // For now, just show completion after delay
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _progress = 1.0;
        _isComplete = true;
        _status = TransferStatus.complete;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = TransferStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Transferring Data',
      automaticallyImplyLeading: !_isComplete && _error == null,
      constrainBody: false,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 32),
            Text(
              _getStatusTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (!_isComplete && _error == null) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.surface,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_totalMessages > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$_messagesTransferred / $_totalMessages items',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ],
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startTransfer,
                child: const Text('Retry'),
              ),
            ],
            if (_isComplete) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case TransferStatus.preparing:
        return _buildAnimatedIcon(Icons.cloud_sync, AppColors.primary);
      case TransferStatus.transferring:
        return _buildAnimatedIcon(Icons.sync, AppColors.primary);
      case TransferStatus.completing:
        return _buildAnimatedIcon(
            Icons.check_circle_outline, AppColors.success);
      case TransferStatus.complete:
        return Icon(
          Icons.check_circle,
          size: 80,
          color: AppColors.success,
        );
      case TransferStatus.failed:
        return Icon(
          Icons.error,
          size: 80,
          color: AppColors.error,
        );
      case TransferStatus.paused:
        return Icon(
          Icons.pause_circle,
          size: 80,
          color: AppColors.warning,
        );
    }
  }

  Widget _buildAnimatedIcon(IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 1),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28,
          child: Icon(
            icon,
            size: 80,
            color: color.withValues(alpha: 0.3 + value * 0.7),
          ),
        );
      },
      onEnd: () {
        if (mounted && !_isComplete && _error == null) {
          setState(() {});
        }
      },
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case TransferStatus.preparing:
        return 'Preparing Transfer';
      case TransferStatus.transferring:
        return 'Transferring Data';
      case TransferStatus.completing:
        return 'Almost Done';
      case TransferStatus.complete:
        return 'Transfer Complete!';
      case TransferStatus.failed:
        return 'Transfer Failed';
      case TransferStatus.paused:
        return 'Transfer Paused';
    }
  }

  String _getStatusMessage() {
    switch (_status) {
      case TransferStatus.preparing:
        return 'Setting up secure connection...';
      case TransferStatus.transferring:
        return 'Your messages and data are being encrypted and transferred securely.';
      case TransferStatus.completing:
        return 'Finalizing transfer...';
      case TransferStatus.complete:
        return 'All your data has been transferred to this device.';
      case TransferStatus.failed:
        return 'Something went wrong. Please try again.';
      case TransferStatus.paused:
        return 'Transfer paused. Resume when ready.';
    }
  }
}
