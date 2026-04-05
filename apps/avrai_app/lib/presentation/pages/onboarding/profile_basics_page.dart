import 'dart:io';

import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/profile_basics_page_schema.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';

/// Step 2: Profile Basics page.
class ProfileBasicsPage extends StatefulWidget {
  final String? initialDisplayName;
  final String? initialPhotoPath;
  final ValueChanged<String?> onDisplayNameChanged;
  final ValueChanged<String?> onPhotoChanged;

  const ProfileBasicsPage({
    super.key,
    this.initialDisplayName,
    this.initialPhotoPath,
    required this.onDisplayNameChanged,
    required this.onPhotoChanged,
  });

  @override
  State<ProfileBasicsPage> createState() => _ProfileBasicsPageState();
}

class _ProfileBasicsPageState extends State<ProfileBasicsPage> {
  late final TextEditingController _nameController;
  String? _photoPath;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
    _photoPath = widget.initialPhotoPath;

    _nameController.addListener(() {
      widget.onDisplayNameChanged(_nameController.text.trim());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, 'library'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'remove') {
      setState(() {
        _photoPath = null;
      });
      widget.onPhotoChanged(null);
      return;
    }

    await _pickPhoto(
      result == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPickingPhoto) return;

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;

      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        if (!result.isGranted) {
          if (mounted) {
            _showPermissionDeniedDialog(source);
          }
          return;
        }
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (pickedFile != null) {
        setState(() {
          _photoPath = pickedFile.path;
        });
        widget.onPhotoChanged(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog(ImageSource source) {
    final permissionName =
        source == ImageSource.camera ? 'Camera' : 'Photo Library';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Access Required'),
        content: Text(
          'To add a profile photo, please allow $permissionName access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      padding: const EdgeInsets.all(24),
      schema: buildProfileBasicsPageSchema(
        profilePhoto: _buildPhotoSection(context),
        displayNameField: _buildDisplayNameField(context),
        profileHint: _buildProfileHint(context),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.radius;

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceMuted,
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 2,
                      ),
                      image: _photoPath != null
                          ? DecorationImage(
                              image: FileImage(File(_photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoPath == null
                        ? const Icon(
                            Icons.person_outline,
                            size: 48,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _photoPath != null ? Icons.edit : Icons.add_a_photo,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (_isPickingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: radius.md),
          Text(
            'Tap to add or change your photo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayNameField(BuildContext context) {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Enter your name',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.surfaceMuted,
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: 50,
    );
  }

  Widget _buildProfileHint(BuildContext context) {
    return AppSurface(
      color: AppColors.surfaceMuted,
      borderColor: AppColors.borderSubtle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your profile helps other people recognize you in events and communities. You can change it anytime in Settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
