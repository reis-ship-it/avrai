import 'package:flutter/material.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai_runtime_os/controllers/profile_update_controller.dart';
import 'package:avrai_core/models/user/user.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:get_it/get_it.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isUpdating = false;
  String? _error;

  late ProfileUpdateController _profileUpdateController;

  @override
  void initState() {
    super.initState();
    _profileUpdateController = GetIt.instance<ProfileUpdateController>();
    _displayNameController.text = widget.user.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _isUpdating) return;

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      final data = ProfileUpdateData(
        displayName: _displayNameController.text.trim(),
      );

      final result = await _profileUpdateController.updateProfile(
        userId: widget.user.id,
        data: data,
      );

      if (!result.success) {
        setState(() {
          _error = result.error ?? 'Failed to update profile';
          _isUpdating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = context.radius;

    return AppFlowScaffold(
      title: 'Edit Profile',
      scrollable: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name cannot be empty';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.lg),
            if (_error != null) ...[
              AppSurface(
                padding: EdgeInsets.all(spacing.sm),
                radius: radius.sm,
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderColor: AppTheme.errorColor.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    SizedBox(width: spacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateProfile,
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
