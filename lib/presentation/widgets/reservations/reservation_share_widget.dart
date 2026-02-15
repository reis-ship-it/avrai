// Reservation Share Widget
//
// Phase 10.4: Reservation Sharing & Transfer
// Widget for sharing reservations with other users
//
// Allows users to share reservations with read-only or full access

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/misc/reservation.dart';
import 'package:avrai/core/services/reservation/reservation_sharing_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/presentation_spacing.dart';

/// Reservation Share Widget
///
/// **Purpose:** Allow users to share reservations with other users
///
/// **Features:**
/// - User search/selection
/// - Permission level selection (read-only or full access)
/// - Share action
/// - Loading states
/// - Error handling
/// - Success feedback
///
/// **Phase 10.4:** Reservation sharing with full AVRAI system integration
class ReservationShareWidget extends StatefulWidget {
  final Reservation reservation;
  final VoidCallback? onShareComplete;
  final VoidCallback? onCancel;

  const ReservationShareWidget({
    super.key,
    required this.reservation,
    this.onShareComplete,
    this.onCancel,
  });

  @override
  State<ReservationShareWidget> createState() => _ReservationShareWidgetState();
}

class _ReservationShareWidgetState extends State<ReservationShareWidget> {
  static const String _logName = 'ReservationShareWidget';

  late final ReservationSharingService _sharingService;

  final TextEditingController _userSearchController = TextEditingController();
  String? _selectedUserId;
  String? _selectedUserName;
  SharingPermission _permission = SharingPermission.readOnly;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sharingService = di.sl<ReservationSharingService>();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  /// Share reservation with selected user
  Future<void> _shareReservation() async {
    if (_selectedUserId == null) {
      setState(() {
        _error = 'Please select a user to share with';
      });
      return;
    }

    // TODO(Phase 10.4): Get current user ID from auth context
    final ownerUserId = 'user_placeholder'; // Replace with actual userId

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _sharingService.shareReservation(
        reservationId: widget.reservation.id,
        ownerUserId: ownerUserId,
        sharedWithUserId: _selectedUserId!,
        permission: _permission,
      );

      if (mounted) {
        if (result.success) {
          context.showSuccess(
            'Reservation shared with $_selectedUserName successfully',
          );

          // Notify parent
          widget.onShareComplete?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Failed to share reservation';
          });

          context.showError(result.error ?? 'Failed to share reservation');
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error sharing reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to share: ${e.toString()}';
        });

        context.showError('Failed to share: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show user search dialog
  Future<void> _showUserSearch() async {
    // TODO(Phase 10.4): Implement user search functionality
    // For now, show a simple dialog with text input
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                labelText: 'User ID or Email',
                hintText: 'Enter user ID or email',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, {
                    'userId': value,
                    'userName': value,
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Full user search coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Will be handled by onSubmitted
            },
            child: Text('Select'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedUserId = result['userId'];
        _selectedUserName = result['userName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.share,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Share Reservation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reservation Info
          Container(
            padding: const EdgeInsets.all(kSpaceMd),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation Details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${widget.reservation.type.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Time: ${widget.reservation.reservationTime.toLocal().toString().split('.')[0]}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Party Size: ${widget.reservation.partySize}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Selection
          Text(
            'Share With',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showUserSearch,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Select User',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                suffixIcon: Icon(Icons.search),
              ),
              child: Text(
                _selectedUserName ?? 'Tap to search for user',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedUserName != null
                          ? AppColors.black
                          : AppColors.textSecondary,
                    ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Permission Level Selection
          Text(
            'Permission Level',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SharingPermission>(
            segments: [
              ButtonSegment(
                value: SharingPermission.readOnly,
                label: Text('Read Only'),
                icon: const Icon(Icons.visibility),
              ),
              ButtonSegment(
                value: SharingPermission.fullAccess,
                label: Text('Full Access'),
                icon: const Icon(Icons.edit),
              ),
            ],
            selected: {_permission},
            onSelectionChanged: (Set<SharingPermission> newSelection) {
              setState(() {
                _permission = newSelection.first;
              });
            },
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(kSpaceSm),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _permission == SharingPermission.readOnly
                      ? Icons.info_outline
                      : Icons.warning_amber_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _permission == SharingPermission.readOnly
                        ? 'User can view reservation details but cannot modify or cancel'
                        : 'User can view, modify, and cancel this reservation',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(kSpaceSm),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _shareReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text('Share Reservation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
