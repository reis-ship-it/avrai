// Add Friend QR Page
//
// Displays user's QR code for friending
// Other users can scan this QR code to send a friend request

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/services/chat/friend_qr_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Add Friend QR Page
///
/// Displays a QR code containing the user's agentId.
/// Other users can scan this QR code to send a friend request.
class AddFriendQRPage extends StatefulWidget {
  const AddFriendQRPage({super.key});

  @override
  State<AddFriendQRPage> createState() => _AddFriendQRPageState();
}

class _AddFriendQRPageState extends State<AddFriendQRPage> {
  final AgentIdService _agentIdService = di.sl<AgentIdService>();
  String? _agentId;
  String? _qrCodeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentId();
  }

  Future<void> _loadAgentId() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);
      final qrCodeData = FriendQRService.generateFriendQRCodeData(agentId);

      if (mounted) {
        setState(() {
          _agentId = agentId;
          _qrCodeData = qrCodeData;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error loading agent ID: $e',
        name: 'AddFriendQRPage',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        context.showError('Error loading QR code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Add Friend',
      appBarBackgroundColor: AppColors.primary,
      appBarForegroundColor: AppColors.white,
      constrainBody: false,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _qrCodeData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to generate QR code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAgentId,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(kSpaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Let your friend scan this QR code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'They can scan this code to send you a friend request',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // QR Code Display
                      PortalSurface(
                        padding: const EdgeInsets.all(kSpaceLg),
                        color: AppColors.white,
                        borderColor: AppColors.grey300,
                        radius: 16,
                        child: QrImageView(
                          data: _qrCodeData!,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: AppColors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.textPrimary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Agent ID Display (for manual entry fallback)
                      PortalSurface(
                        padding: const EdgeInsets.all(kSpaceMd),
                        color: AppColors.grey100,
                        borderColor: AppColors.grey300,
                        radius: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Or share your Agent ID manually',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _agentId ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                // Copy to clipboard
                                if (_agentId != null) {
                                  Clipboard.setData(
                                      ClipboardData(text: _agentId!));
                                  FeedbackPresenter.showSnack(
                                    context,
                                    message: 'Agent ID copied to clipboard',
                                    kind: FeedbackKind.success,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: Text('Copy Agent ID'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Instructions
                      PortalSurface(
                        padding: const EdgeInsets.all(kSpaceMd),
                        color: AppColors.electricGreen.withValues(alpha: 0.1),
                        borderColor:
                            AppColors.electricGreen.withValues(alpha: 0.3),
                        radius: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: AppColors.electricGreen,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'How it works',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '1. Show this QR code to your friend\n'
                              '2. They scan it with their phone\n'
                              '3. They send you a friend request\n'
                              '4. You accept to become friends',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
