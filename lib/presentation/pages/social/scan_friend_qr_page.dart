// Scan Friend QR Page
//
// Camera view for scanning friend QR codes
// Parses scanned QR code and allows sending friend request

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:avrai/core/services/chat/friend_qr_service.dart';
import 'package:avrai/core/services/social_media/social_media_discovery_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/gradient_scrim.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Scan Friend QR Page
///
/// Displays camera view for scanning friend QR codes.
/// Parses scanned QR code and allows sending friend request.
class ScanFriendQRPage extends StatefulWidget {
  const ScanFriendQRPage({super.key});

  @override
  State<ScanFriendQRPage> createState() => _ScanFriendQRPageState();
}

class _ScanFriendQRPageState extends State<ScanFriendQRPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final SocialMediaDiscoveryService _discoveryService =
      di.sl<SocialMediaDiscoveryService>();
  final AgentIdService _agentIdService = di.sl<AgentIdService>();

  bool _isProcessing = false;
  FriendQRData? _scannedData;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    final qrData = barcode.rawValue!;
    developer.log(
      'Scanned QR code: ${qrData.length > 50 ? qrData.substring(0, 50) : qrData}...',
      name: 'ScanFriendQRPage',
    );

    // Parse QR code data
    final friendData = FriendQRService.parseFriendQRCodeData(qrData);
    if (friendData == null) {
      if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Invalid QR code. Please scan a friend QR code.',
          kind: FeedbackKind.error,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    // Check if QR code is expired
    if (friendData.isExpired) {
      if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message:
              'QR code has expired. Please ask your friend to generate a new one.',
          kind: FeedbackKind.warning,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    // Stop scanning and show preview
    setState(() {
      _isProcessing = true;
      _scannedData = friendData;
      _hasScanned = true;
    });

    _scannerController.stop();
  }

  Future<void> _sendFriendRequest() async {
    if (_scannedData == null) return;

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Check if trying to add self
      if (agentId == _scannedData!.agentId) {
        if (mounted) {
          context.showWarning('You cannot add yourself as a friend.');
        }
        return;
      }

      final success = await _discoveryService.sendFriendConnectionRequest(
        agentId: agentId,
        friendAgentId: _scannedData!.agentId,
        userId: userId,
      );

      if (mounted) {
        if (success) {
          context.showSuccess('Friend request sent!');
          // Navigate back after short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          context.showError('Failed to send friend request. Please try again.');
        }
      }
    } catch (e) {
      developer.log(
        'Error sending friend request: $e',
        name: 'ScanFriendQRPage',
      );
      if (mounted) {
        context.showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetScan() {
    setState(() {
      _scannedData = null;
      _hasScanned = false;
      _isProcessing = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Scan Friend QR Code',
      appBarBackgroundColor: AppColors.primary,
      appBarForegroundColor: AppColors.white,
      actions: [
        if (_hasScanned)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScan,
            tooltip: 'Scan again',
          ),
      ],
      constrainBody: false,
      body: _hasScanned && _scannedData != null
          ? _buildFriendPreview()
          : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        // Overlay with instructions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GradientScrim(
            padding: const EdgeInsets.all(kSpaceMd),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
            child: Text(
              'Position the QR code within the frame',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Scanning frame overlay
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: PortalSurface(
              padding: EdgeInsets.zero,
              color: Colors.transparent,
              borderColor: AppColors.electricGreen,
              radius: 12,
              elevation: 0,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
        // Bottom instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GradientScrim(
            padding: const EdgeInsets.all(kSpaceLg),
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan your friend\'s QR code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure the QR code is clearly visible',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'QR Code Scanned!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agent ID: ${_scannedData!.agentId.length > 20 ? _scannedData!.agentId.substring(0, 20) : _scannedData!.agentId}...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          PortalSurface(
            padding: const EdgeInsets.all(kSpaceMdWide),
            color: AppColors.grey100,
            borderColor: AppColors.grey300,
            radius: 12,
            child: Column(
              children: [
                Text(
                  'Send Friend Request?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will send a friend request to this user.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _sendFriendRequest,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isProcessing ? 'Sending...' : 'Send Friend Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetScan,
            child: Text('Scan Another QR Code'),
          ),
        ],
      ),
    );
  }
}
